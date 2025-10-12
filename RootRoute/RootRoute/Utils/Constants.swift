//
//  Constants.swift
//  RootRoute
//
//  Created by 고경표 on 10/10/25.
//

import Foundation

enum Constants {
    // Google Maps API Key
    static let googleMapsAPIKey = "AIzaSyBGgVsaKPOssT21icAbj9yoeBAMDhHYyhE"
    
    // 기본 체류 시간 (1시간)
    static let defaultStayDuration: TimeInterval = 3600
    
    // 날짜 포맷
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()
    
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"  // 24시간제 명시
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()
    
    static let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M월 d일 HH:mm"  // 24시간제 명시
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()
}

