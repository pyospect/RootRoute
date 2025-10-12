//
//  ReservationInfo.swift
//  RootRoute
//
//  Created by 고경표 on 10/10/25.
//

import Foundation

/// 예약 정보
struct ReservationInfo: Codable {
    var isReserved: Bool
    var reservationNumber: String?
    var seatNumber: String?
    var price: Double?
    var bookingURL: String?
    var memo: String?
    
    init(isReserved: Bool = false) {
        self.isReserved = isReserved
    }
}

