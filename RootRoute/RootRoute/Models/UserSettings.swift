//
//  UserSettings.swift
//  RootRoute
//
//  Created by 고경표 on 10/10/25.
//

import Foundation
import Combine

/// 사용자 설정
class UserSettings: ObservableObject {
    static let shared = UserSettings()
    
    @Published var defaultStartHour: Int {
        didSet {
            UserDefaults.standard.set(defaultStartHour, forKey: "defaultStartHour")
        }
    }
    
    private init() {
        self.defaultStartHour = UserDefaults.standard.object(forKey: "defaultStartHour") as? Int ?? 9
    }
    
    /// 특정 날짜의 시작 시간 생성
    func startTime(for date: Date) -> Date {
        let calendar = Calendar.current
        return calendar.date(bySettingHour: defaultStartHour, minute: 0, second: 0, of: date) ?? date
    }
}

