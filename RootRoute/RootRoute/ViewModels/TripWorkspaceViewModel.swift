//
//  TripWorkspaceViewModel.swift
//  RootRoute
//
//  Created by 고경표 on 10/10/25.
//

import Foundation
import Combine
import CoreLocation
internal import SwiftUI

/// 여행 워크스페이스 ViewModel
@MainActor
class TripWorkspaceViewModel: ObservableObject {
    @Published var trip: Trip
    @Published var selectedDayIndex: Int = 0
    @Published var isShowingPlaceSearch = false
    @Published var isCalculatingRoute = false
    @Published var errorMessage: String?
    @Published var isShowingRouteConfirmation = false
    @Published var pendingRouteIndex: Int?
    
    private let placesService = GooglePlacesService()
    private let directionsService = DirectionsService()
    
    var onTripUpdate: ((Trip) -> Void)?
    
    init(trip: Trip) {
        self.trip = trip
    }
    
    var selectedDay: DayPlan {
        get { trip.days[selectedDayIndex] }
        set { trip.days[selectedDayIndex] = newValue }
    }

    /// 외부에서 Trip이 갱신됐을 때 현재 워크스페이스 상태를 동기화
    func refreshTrip(_ trip: Trip) {
        self.trip = trip
        if trip.days.isEmpty {
            selectedDayIndex = 0
        } else {
            selectedDayIndex = min(selectedDayIndex, trip.days.count - 1)
        }
    }
    
    // MARK: - Place Management
    
    func deletePlace(at index: Int) async {
        guard index >= 0 && index < selectedDay.places.count else {
            print("⚠️ deletePlace 실패: 유효하지 않은 인덱스")
            return
        }
        
        let deletedPlace = selectedDay.places[index]
        print("🗑️ 장소 삭제: \(deletedPlace.name)")
        
        // 장소 삭제
        selectedDay.places.remove(at: index)
        
        // 시간 재계산 (삭제된 장소 이후부터)
        if !selectedDay.places.isEmpty {
            cascadeTimesFrom(index: max(0, index))
        }
        
        notifyUpdate()
    }
    
    func addPlace(_ placeDetail: PlaceDetail, stayDuration: TimeInterval = 3600) async {
        print("🏁 장소 추가: \(placeDetail.name)")
        
        var newPlace = PlaceItem(
            placeId: placeDetail.placeId,
            name: placeDetail.name,
            address: placeDetail.address,
            coordinate: placeDetail.coordinate,
            stayDuration: stayDuration
        )
        
        print("🏁 현재 장소 개수: \(selectedDay.places.count)")
        
        // 첫 번째 장소는 설정된 시작 시간으로 초기화
        if selectedDay.places.isEmpty {
            let arrivalTime = UserSettings.shared.startTime(for: selectedDay.date)
            newPlace.arrivalTime = arrivalTime
            newPlace.departureTime = arrivalTime.addingTimeInterval(stayDuration)
            print("🕐 첫 번째 장소 시간 설정: 도착 \(arrivalTime), 출발 \(newPlace.departureTime!)")
        }
        
        selectedDay.places.append(newPlace)
        print("🏁 추가 후 장소 개수: \(selectedDay.places.count)")
        
        // 이전 장소가 있으면 경로 계산
        if selectedDay.places.count > 1 {
            print("🏁 경로 계산 시작...")
            await updateRouteForLastPlace()
        } else {
            print("🏁 첫 번째 장소라 경로 계산 안 함")
        }
        
        notifyUpdate()
    }
    
    func removePlace(at index: Int) {
        print("🗑️ 장소 삭제: index=\(index), 현재 개수=\(selectedDay.places.count)")
        
        guard index >= 0 && index < selectedDay.places.count else {
            print("❌ 삭제 실패: 인덱스 범위 벗어남")
            return
        }
        
        let placeName = selectedDay.places[index].name
        print("🗑️ 삭제할 장소: \(placeName)")
        
        // 삭제 전에 이전 장소의 routeToNext를 needsUpdate로 표시 (있다면)
        if index > 0 {
            if selectedDay.places[index - 1].routeToNext != nil {
                selectedDay.places[index - 1].routeToNext?.needsUpdate = true
                print("⚠️ 이전 장소의 경로 재설정 필요 표시")
            }
        }
        
        // 장소 삭제
        selectedDay.places.remove(at: index)
        print("🗑️ 삭제 후 개수: \(selectedDay.places.count)")
        
        // 경로 재계산 (안전하게)
        Task {
            // 삭제 후에도 2개 이상의 장소가 있고, 이전 장소가 있으면
            if selectedDay.places.count >= 2 && index > 0 {
                // index - 1번째 장소가 마지막이 아니면 경로 재계산 (연쇄 업데이트!)
                let prevIndex = index - 1
                if prevIndex < selectedDay.places.count - 1 {
                    print("🗑️ 이전 장소 경로 재계산 (연쇄): index=\(prevIndex)")
                    // needsUpdate로 표시만 하고, 자동 계산은 하지 않음
                    selectedDay.places[prevIndex].routeToNext?.needsUpdate = true
                }
            }
        }
        
        notifyUpdate()
    }
    
    func duplicatePlace(at index: Int) async {
        print("📋 장소 복제: index=\(index), 현재 개수=\(selectedDay.places.count)")
        
        guard index >= 0 && index < selectedDay.places.count else {
            print("❌ 복제 실패: 인덱스 범위 벗어남")
            return
        }
        
        let originalPlace = selectedDay.places[index]
        print("📋 복제할 장소: \(originalPlace.name)")
        
        // 새 PlaceItem 생성 (ID는 자동 생성됨)
        var newPlace = PlaceItem(
            placeId: originalPlace.placeId,
            name: originalPlace.name,
            address: originalPlace.address,
            coordinate: originalPlace.coordinate,
            stayDuration: originalPlace.stayDuration
        )
        newPlace.memo = originalPlace.memo
        
        // 시간 설정: 원본의 출발 시간을 새 장소의 도착 시간으로
        if let originalDeparture = originalPlace.departureTime {
            newPlace.arrivalTime = originalDeparture
            newPlace.departureTime = originalDeparture.addingTimeInterval(newPlace.stayDuration)
            print("📋 복제 장소 시간: 도착 \(newPlace.arrivalTime!), 출발 \(newPlace.departureTime!)")
        }
        
        // 바로 다음 위치에 삽입
        selectedDay.places.insert(newPlace, at: index + 1)
        print("📋 복제 후 개수: \(selectedDay.places.count)")
        
        // 원본과 복제본 사이에 도보 0분 경로 추가
        let fromLocation = CLLocation(latitude: originalPlace.latitude, longitude: originalPlace.longitude)
        let toLocation = CLLocation(latitude: newPlace.latitude, longitude: newPlace.longitude)
        let distance = fromLocation.distance(from: toLocation)  // 같은 장소니까 0m
        
        var route = Route(
            fromPlaceId: originalPlace.placeId,
            toPlaceId: newPlace.placeId,
            travelMode: .walking,
            duration: 0,  // 0분
            distance: distance,
            encodedPolyline: "",
            displayMode: .walking
        )
        route.isManualDuration = true
        route.needsUpdate = false
        
        selectedDay.places[index].routeToNext = route
        print("📋 도보 0분 경로 추가 완료")
        
        // 복제본 이후의 시간 연쇄 업데이트
        cascadeTimesFrom(index: index + 2)
        
        notifyUpdate()
    }
    
    func movePlaces(from source: IndexSet, to destination: Int) {
        print("📦 장소 이동: from=\(source) to=\(destination)")
        
        guard !selectedDay.places.isEmpty else {
            print("❌ 이동 실패: 장소 없음")
            return
        }
        
        selectedDay.places.move(fromOffsets: source, toOffset: destination)
        
        // 영향받는 경로들 재계산
        Task {
            if selectedDay.places.count >= 2 {
                print("📦 경로 전체 재계산 시작")
                await recalculateAllRoutes()
            }
        }
        
        notifyUpdate()
    }
    
    func updatePlace(_ place: PlaceItem) {
        if let index = selectedDay.places.firstIndex(where: { $0.id == place.id }) {
            selectedDay.places[index] = place
            notifyUpdate()
        }
    }
    
    func updatePlaceDetails(at index: Int, arrivalTime: Date?, stayDuration: TimeInterval, memo: String) async {
        print("✏️ 장소 편집: index=\(index), 현재 개수=\(selectedDay.places.count)")
        
        guard index >= 0 && index < selectedDay.places.count else {
            print("⚠️ updatePlaceDetails 실패: 유효하지 않은 인덱스")
            return
        }
        
        selectedDay.places[index].arrivalTime = arrivalTime
        selectedDay.places[index].stayDuration = stayDuration
        selectedDay.places[index].memo = memo.isEmpty ? nil : memo
        
        // 출발 시간 자동 계산
        if let arrival = arrivalTime {
            selectedDay.places[index].departureTime = arrival.addingTimeInterval(stayDuration)
            print("✏️ 출발 시간 자동 계산: \(selectedDay.places[index].departureTime!)")
        }
        
        print("✏️ 장소 편집 완료")
        
        // 시간 연쇄 업데이트 (다음 장소들부터)
        cascadeTimesFrom(index: index + 1)
        
        notifyUpdate()
    }
    
    // MARK: - Route Management
    
    /// 경로 설정 시트 표시
    private func updateRouteForLastPlace() async {
        let places = selectedDay.places
        guard places.count >= 2 else {
            print("🏁 경로 계산 스킵: 장소 2개 미만")
            return
        }
        
        let fromIndex = places.count - 2
        print("🏁 경로 설정 시트 표시: fromIndex=\(fromIndex)")
        
        await MainActor.run {
            pendingRouteIndex = fromIndex
            isShowingRouteConfirmation = true
        }
    }
    
    /// 사용자가 시트에서 확인한 경로 저장 (신규 장소 추가 시)
    func confirmRouteFromSheet(mode: TravelMode, duration: TimeInterval, requiresReservation: Bool, reservationInfo: ReservationInfo?) async {
        guard let index = pendingRouteIndex else {
            print("⚠️ pendingRouteIndex 없음")
            return
        }
        
        let places = selectedDay.places
        guard index >= 0 && index < places.count - 1 else {
            print("⚠️ 인덱스 범위 벗어남")
            return
        }
        
        let from = places[index]
        let to = places[index + 1]
        
        print("✅ 사용자 경로 확정: \(from.name) → \(to.name), 모드: \(mode.displayName), 시간: \(Int(duration/60))분")
        
        // 직선거리 계산
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        let distance = fromLocation.distance(from: toLocation)
        
        // Route 생성 (polyline은 빈 문자열)
        var route = Route(
            fromPlaceId: from.placeId,
            toPlaceId: to.placeId,
            travelMode: mode,
            duration: duration,
            distance: distance,
            encodedPolyline: "",
            displayMode: mode == .transit ? .transit : .walking
        )
        route.isManualDuration = true
        route.requiresReservation = requiresReservation
        route.reservationInfo = reservationInfo
        route.needsUpdate = false  // 새로 설정했으므로 false
        
        selectedDay.places[index].routeToNext = route
        
        // 다음 장소의 도착/출발 시간 자동 계산
        if let departureTime = from.departureTime {
            let arrivalTime = departureTime.addingTimeInterval(duration)
            selectedDay.places[index + 1].arrivalTime = arrivalTime
            selectedDay.places[index + 1].departureTime = arrivalTime.addingTimeInterval(
                selectedDay.places[index + 1].stayDuration
            )
            print("🕐 다음 장소 시간 자동 계산: 도착 \(arrivalTime), 출발 \(selectedDay.places[index + 1].departureTime!)")
        }
        
        await MainActor.run {
            pendingRouteIndex = nil
        }
        
        notifyUpdate()
    }
    
    /// 경로 수동 편집 (기존 경로 수정 시)
    func updateRouteManually(at index: Int, mode: TravelMode, duration: TimeInterval, requiresReservation: Bool, reservationInfo: ReservationInfo?) async {
        guard index >= 0 && index < selectedDay.places.count - 1 else {
            print("⚠️ updateRouteManually 실패: 유효하지 않은 인덱스")
            return
        }
        
        let from = selectedDay.places[index]
        let to = selectedDay.places[index + 1]
        
        print("✏️ 경로 수동 편집: \(from.name) → \(to.name), 모드: \(mode.displayName), 시간: \(Int(duration/60))분")
        
        // 직선거리 계산
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        let distance = fromLocation.distance(from: toLocation)
        
        // Route 생성
        var route = Route(
            fromPlaceId: from.placeId,
            toPlaceId: to.placeId,
            travelMode: mode,
            duration: duration,
            distance: distance,
            encodedPolyline: "",
            displayMode: mode == .transit ? .transit : .walking
        )
        route.isManualDuration = true
        route.requiresReservation = requiresReservation
        route.reservationInfo = reservationInfo
        route.needsUpdate = false  // 재설정했으므로 false
        
        selectedDay.places[index].routeToNext = route
        
        // 시간 연쇄 업데이트
        cascadeTimesFrom(index: index + 1)
        notifyUpdate()
    }
    
    private func updateRoute(at index: Int, updateNextPlaces: Bool = true, allowAutoTransit: Bool = true) async {
        let places = selectedDay.places
        guard index >= 0 && index < places.count - 1 else {
            print("🛣️ 경로 업데이트 실패: 인덱스 범위 벗어남 (index: \(index), count: \(places.count))")
            return
        }
        
        let from = places[index]
        let to = places[index + 1]
        
        print("🛣️ 경로 계산 시작: \(from.name) → \(to.name)")
        isCalculatingRoute = true
        errorMessage = nil
        
        // 출발 시간 결정 (이전 장소의 출발 시간, 없으면 현재 시간)
        let departureTime = from.departureTime ?? Date()
        print("🕐 출발 시간: \(departureTime)")
        
        do {
            // 1단계: 항상 도보로 계산
            print("🚶 도보 경로 계산 중...")
            var route = try await directionsService.getWalkingRoute(
                from: from.coordinate,
                to: to.coordinate
            )
            
            route.fromPlaceId = from.placeId
            route.toPlaceId = to.placeId
            
            // 2단계: 20분 이상이면 대중교통 시도 (allowAutoTransit이 true일 때만)
            if allowAutoTransit && route.durationMinutes >= 20 {
                print("⚠️ 도보 \(route.durationMinutes)분 → 대중교통 경로 시도")
                
                do {
                    // 대중교통 API 시도
                    var transitRoute = try await directionsService.getTransitRoute(
                        from: from.coordinate,
                        to: to.coordinate,
                        departureTime: departureTime
                    )
                    
                    transitRoute.fromPlaceId = from.placeId
                    transitRoute.toPlaceId = to.placeId
                    
                    // 대중교통 성공: 대중교통 경로 사용
                    route = transitRoute
                    print("✅ 대중교통 경로 성공: \(route.durationMinutes)분")
                    
                } catch {
                    // 대중교통 실패 (일본 등): 도보 유지 + transit 모드 + 수동 입력
                    print("💡 대중교통 API 실패 (해당 지역 미지원 가능): \(error.localizedDescription)")
                    print("💡 Fallback: 도보 시간 유지, 사용자 수동 입력 모드")
                    route.displayMode = .transit
                    route.suggestTransit = true
                    // isManualDuration은 설정하지 않음 (도보 시간 유지)
                }
            }
            
            selectedDay.places[index].routeToNext = route
            print("✅ 경로 저장 완료: \(route.durationMinutes)분, 모드: \(route.displayMode == .transit ? "대중교통" : "도보")")
            
            // 다음 장소의 도착/출발 시간 자동 계산
            let arrivalTime = departureTime.addingTimeInterval(route.duration)
            selectedDay.places[index + 1].arrivalTime = arrivalTime
            selectedDay.places[index + 1].departureTime = arrivalTime.addingTimeInterval(
                selectedDay.places[index + 1].stayDuration
            )
            print("🕐 다음 장소 시간 자동 계산: 도착 \(arrivalTime), 출발 \(selectedDay.places[index + 1].departureTime!)")
            
            isCalculatingRoute = false
            notifyUpdate()
            
            // 연쇄 업데이트: 다음 장소도 있고 시간이 있으면 계속 계산
            if updateNextPlaces && index + 1 < places.count - 1 {
                print("🔄 연쇄 업데이트: 다음 경로도 재계산...")
                await updateRoute(at: index + 1, updateNextPlaces: true)
            }
            
        } catch {
            print("❌ 도보 경로 실패: \(error)")
            await MainActor.run {
                errorMessage = "경로 계산에 실패했습니다: \(error.localizedDescription)"
                isCalculatingRoute = false
            }
        }
    }
    
    private func recalculateAllRoutes() async {
        guard selectedDay.places.count >= 2 else {
            print("📦 경로 재계산 스킵: 장소 2개 미만")
            return
        }
        
        print("📦 스마트 경로 재계산 시작")
        
        // 스마트 경로 업데이트: 변경된 구간만 needsUpdate 설정
        for i in 0..<selectedDay.places.count - 1 {
            guard let route = selectedDay.places[i].routeToNext else {
                continue
            }
            
            let currentPlace = selectedDay.places[i]
            let nextPlace = selectedDay.places[i + 1]
            
            // 경로의 출발지/도착지 ID와 현재 place ID 비교
            let routeIsValid = route.fromPlaceId == currentPlace.placeId &&
                              route.toPlaceId == nextPlace.placeId
            
            if !routeIsValid {
                // 경로가 유효하지 않음 → needsUpdate 설정
                selectedDay.places[i].routeToNext?.needsUpdate = true
                print("⚠️ 경로 재설정 필요: \(currentPlace.name) → \(nextPlace.name)")
            } else {
                // 경로가 여전히 유효함 → needsUpdate 해제
                selectedDay.places[i].routeToNext?.needsUpdate = false
                print("✅ 경로 유효: \(currentPlace.name) → \(nextPlace.name)")
            }
        }
        
        cascadeTimesFrom(index: 1)
        notifyUpdate()
    }
    
    
    
    
    // MARK: - Time Cascade
    
    /// 특정 인덱스부터 시작해서 모든 후속 장소들의 도착/출발 시간을 재계산
    func cascadeTimesFrom(index: Int) {
        guard index >= 0 && index < selectedDay.places.count else {
            return
        }
        
        print("⏰ 시간 연쇄 업데이트 시작: index=\(index)")
        
        for i in index..<selectedDay.places.count {
            if i > 0 {
                let prevPlace = selectedDay.places[i - 1]
                guard let prevDeparture = prevPlace.departureTime,
                      let route = prevPlace.routeToNext else {
                    print("⚠️ 이전 장소의 출발 시간 또는 경로 없음: index=\(i)")
                    continue
                }
                
                // 새로운 도착 시간 = 이전 장소 출발 시간 + 이동 시간
                let newArrival = prevDeparture.addingTimeInterval(route.duration)
                selectedDay.places[i].arrivalTime = newArrival
                
                // 새로운 출발 시간 = 도착 시간 + 체류 시간
                let newDeparture = newArrival.addingTimeInterval(selectedDay.places[i].stayDuration)
                selectedDay.places[i].departureTime = newDeparture
                
                print("⏰ 장소 \(i) 시간 업데이트: 도착 \(formatTime(newArrival)), 출발 \(formatTime(newDeparture))")
            }
        }
        
        print("✅ 시간 연쇄 업데이트 완료")
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    // MARK: - Helper
    
    private func notifyUpdate() {
        onTripUpdate?(trip)
    }
}
