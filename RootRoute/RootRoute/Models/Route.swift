//
//  Route.swift
//  RootRoute
//
//  Created by 고경표 on 10/10/25.
//

import Foundation

/// 이동 수단 (뚜벅이 전용)
enum TravelMode: String, Codable, CaseIterable {
    case transit = "TRANSIT"      // 대중교통
    case walking = "WALKING"      // 도보
    case driving = "DRIVING"      // 자동차 (참고용)
    
    var icon: String {
        switch self {
        case .transit: return "🚇"
        case .walking: return "🚶"
        case .driving: return "🚗"
        }
    }
    
    var displayName: String {
        switch self {
        case .transit: return "대중교통"
        case .walking: return "도보"
        case .driving: return "자동차"
        }
    }
}

/// 대중교통 세부 타입
enum TransitType: String, Codable {
    case subway      // 지하철
    case bus         // 버스
    case train       // 일반 열차
    case highSpeed   // 고속열차 (신칸센, KTX 등)
    case ferry       // 페리
    case cableCar    // 케이블카
    
    var icon: String {
        switch self {
        case .subway: return "tram.fill"
        case .bus: return "bus.fill"
        case .train: return "train.side.front.car"
        case .highSpeed: return "train.side.rear.car"
        case .ferry: return "ferry.fill"
        case .cableCar: return "cablecar.fill"
        }
    }
}

/// 경로 표시 모드
enum RouteDisplayMode: String, Codable {
    case walking      // 도보 (기본)
    case transit      // 대중교통 (사용자 선택)
}

/// 장소 간 경로 정보
struct Route: Identifiable, Codable {
    let id: UUID
    var fromPlaceId: String
    var toPlaceId: String
    var travelMode: TravelMode
    var transitType: TransitType?  // 대중교통일 때만
    var duration: TimeInterval  // 소요 시간 (초)
    var distance: Double  // 거리 (미터)
    var encodedPolyline: String  // 실제 경로 (구글 인코딩)
    var requiresReservation: Bool  // 예약 필요 여부 (사용자 지정)
    var reservationInfo: ReservationInfo?
    var isManualDuration: Bool  // 수동으로 입력한 시간인지 (API 실패 시)
    var displayMode: RouteDisplayMode  // 사용자가 선택한 표시 모드
    var suggestTransit: Bool  // 도보 20분 이상이면 대중교통 권장
    var needsUpdate: Bool = false  // 재배치 등으로 재설정이 필요한지 여부
    
    init(fromPlaceId: String, toPlaceId: String, travelMode: TravelMode, duration: TimeInterval, distance: Double, encodedPolyline: String, displayMode: RouteDisplayMode = .walking) {
        self.id = UUID()
        self.fromPlaceId = fromPlaceId
        self.toPlaceId = toPlaceId
        self.travelMode = travelMode
        self.duration = duration
        self.distance = distance
        self.encodedPolyline = encodedPolyline
        self.requiresReservation = false
        self.isManualDuration = false
        self.displayMode = displayMode
        self.suggestTransit = false
    }
    
    /// 소요 시간 (분)
    var durationMinutes: Int {
        Int(duration / 60)
    }
    
    /// 거리 (km)
    var distanceKm: Double {
        distance / 1000
    }
    
    var modeDescription: String {
        if travelMode == .transit, let type = transitType {
            switch type {
            case .subway: return "지하철"
            case .bus: return "버스"
            case .train: return "열차"
            case .highSpeed: return "고속열차"
            case .ferry: return "페리"
            case .cableCar: return "케이블카"
            }
        }
        return travelMode.displayName
    }
}

