//
//  DayPlan.swift
//  RootRoute
//
//  Created by 고경표 on 10/10/25.
//

import Foundation

/// 일일 계획
struct DayPlan: Identifiable, Codable {
    let id: UUID
    var dayNumber: Int
    var date: Date
    var places: [PlaceItem]
    
    init(dayNumber: Int, date: Date, places: [PlaceItem] = []) {
        self.id = UUID()
        self.dayNumber = dayNumber
        self.date = date
        self.places = places
    }
    
    /// 해당 일의 총 이동 거리 (km)
    var totalDistance: Double {
        places.compactMap { $0.routeToNext?.distance }.reduce(0, +)
    }
    
    /// 해당 일의 총 이동 시간 (분)
    var totalTravelTime: TimeInterval {
        places.compactMap { $0.routeToNext?.duration }.reduce(0, +)
    }
}

