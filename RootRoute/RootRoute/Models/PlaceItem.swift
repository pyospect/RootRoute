//
//  PlaceItem.swift
//  RootRoute
//
//  Created by 고경표 on 10/10/25.
//

import Foundation
import CoreLocation

/// 여행지 장소
struct PlaceItem: Identifiable, Codable {
    let id: UUID
    var placeId: String  // Google Place ID
    var name: String
    var address: String?
    var latitude: Double
    var longitude: Double
    var arrivalTime: Date?
    var departureTime: Date?
    var stayDuration: TimeInterval  // 체류 시간 (초)
    var memo: String?
    var routeToNext: Route?  // 다음 장소로 가는 경로
    
    init(placeId: String, name: String, address: String? = nil, coordinate: CLLocationCoordinate2D, stayDuration: TimeInterval = 3600) {
        self.id = UUID()
        self.placeId = placeId
        self.name = name
        self.address = address
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.stayDuration = stayDuration
    }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    /// 체류 시간 (분)
    var stayMinutes: Int {
        Int(stayDuration / 60)
    }
}

