//
//  TripWorkspaceView.swift
//  RootRoute
//
//  Created by 고경표 on 10/10/25.
//

internal import SwiftUI

struct TripWorkspaceView: View {
    @EnvironmentObject private var listViewModel: TripListViewModel
    @StateObject private var workspaceVM: TripWorkspaceViewModel
    @State private var showPlaceSearch = false
    @State private var showMapView = false
    @State private var selectedPlaceForEdit: IdentifiablePlaceIndex?
    @State private var editingRouteInfo: EditingRouteWithSheetInfo?
    
    // Sheet용 래퍼
    struct IdentifiablePlaceIndex: Identifiable {
        let id = UUID()
        let index: Int
        let place: PlaceItem
    }
    
    struct EditingRouteWithSheetInfo: Identifiable {
        let id = UUID()
        let index: Int
        let fromPlace: PlaceItem
        let toPlace: PlaceItem
        let existingRoute: Route?  // 경로가 없을 수도 있음
    }
    
    init(trip: Trip) {
        _workspaceVM = StateObject(wrappedValue: TripWorkspaceViewModel(trip: trip))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 날짜 탭
            dayTabsView
            
            // 장소 리스트
            placeListView
        }
        .navigationTitle(workspaceVM.trip.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { showMapView = true }) {
                    Image(systemName: "map.fill")
                        .font(.title3)
                }
                .disabled(workspaceVM.selectedDay.places.isEmpty)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showPlaceSearch = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
            }
        }
        .sheet(isPresented: $showPlaceSearch) {
            PlaceSearchView { placeDetail in
                Task {
                    await workspaceVM.addPlace(placeDetail)
                }
            }
        }
        .sheet(isPresented: $showMapView) {
            DayMapView(dayPlan: workspaceVM.selectedDay)
        }
        .sheet(item: $selectedPlaceForEdit) { placeInfo in
            PlaceEditSheet(
                place: placeInfo.place,
                onSave: { arrivalTime, stayDuration, memo in
                    print("💾 PlaceEditSheet 저장: index=\(placeInfo.index)")
                    Task {
                        await workspaceVM.updatePlaceDetails(
                            at: placeInfo.index,
                            arrivalTime: arrivalTime,
                            stayDuration: stayDuration,
                            memo: memo
                        )
                    }
                },
                onDelete: {
                    print("🗑️ PlaceEditSheet에서 삭제: index=\(placeInfo.index)")
                    Task {
                        workspaceVM.removePlace(at: placeInfo.index)
                    }
                }
            )
            .onAppear {
                print("🎨 PlaceEditSheet 표시: index=\(placeInfo.index), place=\(placeInfo.place.name)")
            }
        }
        .sheet(isPresented: $workspaceVM.isShowingRouteConfirmation) {
            if let index = workspaceVM.pendingRouteIndex,
               index >= 0,
               index < workspaceVM.selectedDay.places.count - 1 {
                let fromPlace = workspaceVM.selectedDay.places[index]
                let toPlace = workspaceVM.selectedDay.places[index + 1]
                
                RouteConfirmationSheet(
                    fromPlace: fromPlace,
                    toPlace: toPlace,
                    onConfirm: { mode, duration, requiresReservation, reservationInfo in
                        Task {
                            await workspaceVM.confirmRouteFromSheet(mode: mode, duration: duration, requiresReservation: requiresReservation, reservationInfo: reservationInfo)
                        }
                    }
                )
            }
        }
        .sheet(item: $editingRouteInfo) { info in
            RouteConfirmationSheet(
                fromPlace: info.fromPlace,
                toPlace: info.toPlace,
                existingRoute: info.existingRoute,
                onConfirm: { mode, duration, requiresReservation, reservationInfo in
                    Task {
                        await workspaceVM.updateRouteManually(at: info.index, mode: mode, duration: duration, requiresReservation: requiresReservation, reservationInfo: reservationInfo)
                    }
                }
            )
        }
        .onAppear {
            workspaceVM.onTripUpdate = { updatedTrip in
                listViewModel.updateTrip(updatedTrip)
            }
            syncWorkspaceTrip()
        }
        .onChange(of: listViewModel.trips) {
            syncWorkspaceTrip()
        }
        .overlay {
            if workspaceVM.isCalculatingRoute {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("경로 계산 중...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(20)
                .background(.ultraThinMaterial)
                .cornerRadius(12)
            }
        }
        .alert("오류", isPresented: Binding(
            get: { workspaceVM.errorMessage != nil },
            set: { if !$0 { workspaceVM.errorMessage = nil } }
        )) {
            Button("확인", role: .cancel) {
                workspaceVM.errorMessage = nil
            }
        } message: {
            Text(workspaceVM.errorMessage ?? "오류가 발생했습니다")
        }
    }
    
    private var dayTabsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(0..<workspaceVM.trip.days.count, id: \.self) { index in
                    DayTab(
                        dayNumber: index + 1,
                        date: workspaceVM.trip.days[index].date,
                        isSelected: workspaceVM.selectedDayIndex == index
                    )
                    .onTapGesture {
                        withAnimation {
                            workspaceVM.selectedDayIndex = index
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(Color(uiColor: .systemBackground))
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var placeListView: some View {
        Group {
            if workspaceVM.selectedDay.places.isEmpty {
                emptyPlacesView
            } else {
                placesWithRoutesView
            }
        }
    }
    
    private var emptyPlacesView: some View {
        VStack(spacing: 20) {
            Image(systemName: "mappin.and.ellipse")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("장소를 추가해주세요")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Button(action: { showPlaceSearch = true }) {
                Label("장소 검색", systemImage: "magnifyingglass")
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color(hex: "784FDA"))
                    .cornerRadius(10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var placesWithRoutesView: some View {
        VStack(spacing: 0) {
            List {
                ForEach(Array(workspaceVM.selectedDay.places.enumerated()), id: \.element.id) { index, place in
                    placeRowView(for: place, at: index)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 4, trailing: 16))
                        .listRowBackground(Color.clear)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                Task {
                                    await workspaceVM.deletePlace(at: index)
                                }
                            } label: {
                                Label("삭제", systemImage: "trash")
                            }
                        }
                }
                .onMove { from, to in
                    workspaceVM.movePlaces(from: from, to: to)
                }
            }
            .listStyle(.plain)
            .background(Color(uiColor: .systemGroupedBackground))
        }
    }
    
    private func placeRowView(for place: PlaceItem, at index: Int) -> some View {
        let isLastPlace = index == workspaceVM.selectedDay.places.count - 1
        let nextPlace: PlaceItem? = !isLastPlace ? workspaceVM.selectedDay.places[index + 1] : nil
        
        let editRouteAction: (() -> Void)? = {
            guard let next = nextPlace else { return nil }
            return {
                editingRouteInfo = EditingRouteWithSheetInfo(
                    index: index,
                    fromPlace: place,
                    toPlace: next,
                    existingRoute: place.routeToNext  // nil일 수도 있음
                )
            }
        }()
        
        let openMapsAction: (() -> Void)? = {
            guard !isLastPlace, let next = nextPlace else { return nil }
            return {
                openInMaps(from: place, to: next)
            }
        }()
        
        let deleteAction: (() -> Void) = {
            Task {
                await workspaceVM.deletePlace(at: index)
            }
        }
        
        let duplicateAction: (() -> Void) = {
            Task {
                await workspaceVM.duplicatePlace(at: index)
            }
        }
        
        return PlaceRow(
            place: place,
            number: index + 1,
            route: place.routeToNext,
            isLastPlace: isLastPlace,
            onEditRoute: editRouteAction,
            onOpenInMaps: openMapsAction,
            onDelete: deleteAction,
            onDuplicate: duplicateAction
        )
        .onTapGesture {
            print("👆 PlaceRow 탭: index=\(index), place=\(place.name)")
            selectedPlaceForEdit = IdentifiablePlaceIndex(index: index, place: place)
        }
    }
    
    private func openInMaps(from: PlaceItem, to: PlaceItem) {
        print("🗺️ Google Maps로 대중교통 경로 열기: \(from.name) → \(to.name)")
        
        // 출발 시간 계산 (도착시간 + 체류시간)
        var departureTime: Date?
        if let arrivalTime = from.arrivalTime {
            departureTime = arrivalTime.addingTimeInterval(from.stayDuration)
        }
        
        // Google Maps 앱 URL (Place ID + 장소명 + 출발시간)
        var urlComponents = URLComponents()
        urlComponents.scheme = "comgooglemaps"
        urlComponents.host = ""
        
        var queryItems: [URLQueryItem] = []
        
        // 출발지 (Place ID가 있으면 사용, 없으면 장소명+좌표)
        if !from.placeId.isEmpty {
            queryItems.append(URLQueryItem(name: "saddr", value: ""))
            queryItems.append(URLQueryItem(name: "saddr_place_id", value: from.placeId))
        } else {
            let fromQuery = "\(from.name), \(from.latitude),\(from.longitude)"
            queryItems.append(URLQueryItem(name: "saddr", value: fromQuery))
        }
        
        // 도착지 (Place ID가 있으면 사용, 없으면 장소명+좌표)
        if !to.placeId.isEmpty {
            queryItems.append(URLQueryItem(name: "daddr", value: ""))
            queryItems.append(URLQueryItem(name: "daddr_place_id", value: to.placeId))
        } else {
            let toQuery = "\(to.name), \(to.latitude),\(to.longitude)"
            queryItems.append(URLQueryItem(name: "daddr", value: toQuery))
        }
        
        // 이동 수단
        queryItems.append(URLQueryItem(name: "directionsmode", value: "transit"))
        
        // 출발 시간 (Unix timestamp)
        if let departureTime = departureTime {
            let timestamp = Int(departureTime.timeIntervalSince1970)
            queryItems.append(URLQueryItem(name: "departure_time", value: "\(timestamp)"))
            
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            print("📅 출발 시간: \(formatter.string(from: departureTime))")
        }
        
        urlComponents.queryItems = queryItems
        
        if let url = urlComponents.url,
           UIApplication.shared.canOpenURL(url) {
            print("✅ Google Maps 앱으로 열림")
            print("   URL: \(url.absoluteString)")
            UIApplication.shared.open(url)
        } else {
            // Google Maps 앱 없으면 웹으로
            openInMapsWeb(from: from, to: to, departureTime: departureTime)
        }
    }
    
    // 웹 버전 Google Maps
    private func openInMapsWeb(from: PlaceItem, to: PlaceItem, departureTime: Date?) {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "www.google.com"
        urlComponents.path = "/maps/dir/"
        
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "api", value: "1"),
            URLQueryItem(name: "travelmode", value: "transit")
        ]
        
        // 출발지 (Place ID 우선, 없으면 장소명)
        if !from.placeId.isEmpty {
            queryItems.append(URLQueryItem(name: "origin", value: from.name))
            queryItems.append(URLQueryItem(name: "origin_place_id", value: from.placeId))
        } else {
            queryItems.append(URLQueryItem(name: "origin", value: from.name))
        }
        
        // 도착지 (Place ID 우선, 없으면 장소명)
        if !to.placeId.isEmpty {
            queryItems.append(URLQueryItem(name: "destination", value: to.name))
            queryItems.append(URLQueryItem(name: "destination_place_id", value: to.placeId))
        } else {
            queryItems.append(URLQueryItem(name: "destination", value: to.name))
        }
        
        // 출발 시간
        if let departureTime = departureTime {
            let timestamp = Int(departureTime.timeIntervalSince1970)
            queryItems.append(URLQueryItem(name: "departure_time", value: "\(timestamp)"))
        }
        
        urlComponents.queryItems = queryItems
        
        if let webUrl = urlComponents.url {
            print("✅ 웹 브라우저로 Google Maps 열림")
            print("   URL: \(webUrl.absoluteString)")
            UIApplication.shared.open(webUrl)
        }
    }
    
    private func openPlaceInMaps(_ place: PlaceItem) {
        print("🗺️ Google Maps로 장소 보기: \(place.name)")
        
        // 장소명과 좌표를 함께 사용 (장소명이 제대로 표시됨)
        let encodedName = place.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? place.name
        let urlString = "comgooglemaps://?q=\(encodedName)&center=\(place.latitude),\(place.longitude)"
        
        if let url = URL(string: urlString),
           UIApplication.shared.canOpenURL(url) {
            print("✅ Google Maps 앱으로 열림")
            UIApplication.shared.open(url)
        } else {
            // Google Maps 앱 없으면 웹으로 (Place ID가 있으면 사용)
            let webUrlString: String
            if !place.placeId.isEmpty {
                webUrlString = "https://www.google.com/maps/search/?api=1&query=\(encodedName)&query_place_id=\(place.placeId)"
            } else {
                webUrlString = "https://www.google.com/maps/search/?api=1&query=\(encodedName)"
            }
            
            if let webUrl = URL(string: webUrlString) {
                print("✅ 웹 브라우저로 Google Maps 열림")
                UIApplication.shared.open(webUrl)
            }
        }
    }
}

private extension TripWorkspaceView {
    func syncWorkspaceTrip() {
        guard let latestTrip = listViewModel.trips.first(where: { $0.id == workspaceVM.trip.id }) else {
            return
        }
        workspaceVM.refreshTrip(latestTrip)
    }
}
