//
//  Trip.swift
//  RootRoute
//
//  Created by 고경표 on 10/10/25.
//

import Foundation

/// 여행 워크스페이스
struct Trip: Identifiable, Codable {
    let id: UUID
    var name: String
    var startDate: Date
    var endDate: Date
    var days: [DayPlan]
    var createdAt: Date
    var updatedAt: Date
    
    init(name: String, startDate: Date, endDate: Date) {
        self.id = UUID()
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.createdAt = Date()
        self.updatedAt = Date()
        
        // 날짜 차이 계산해서 일차 자동 생성
        let calendar = Calendar.current
        let dayCount = calendar.dateComponents([.day], from: startDate, to: endDate).day! + 1
        
        self.days = (0..<dayCount).map { dayIndex in
            DayPlan(
                dayNumber: dayIndex + 1,
                date: calendar.date(byAdding: .day, value: dayIndex, to: startDate)!
            )
        }
    }
    
    var duration: Int {
        Calendar.current.dateComponents([.day], from: startDate, to: endDate).day! + 1
    }
    
    /// 날짜 변경 시 일차 재생성 (기존 데이터는 유지하면서 일차 조정)
    mutating func updateDays() {
        let calendar = Calendar.current
        let dayCount = calendar.dateComponents([.day], from: startDate, to: endDate).day! + 1
        
        // 새로운 일차 수에 맞게 조정
        if dayCount > days.count {
            // 일수 증가: 새 날짜 추가
            let currentCount = days.count
            let additionalDays = (currentCount..<dayCount).map { dayIndex in
                DayPlan(
                    dayNumber: dayIndex + 1,
                    date: calendar.date(byAdding: .day, value: dayIndex, to: startDate)!
                )
            }
            days.append(contentsOf: additionalDays)
        } else if dayCount < days.count {
            // 일수 감소: 초과 날짜 제거
            days = Array(days.prefix(dayCount))
        }
        
        // 모든 날짜의 date 필드 업데이트
        for i in 0..<days.count {
            days[i].date = calendar.date(byAdding: .day, value: i, to: startDate)!
            days[i].dayNumber = i + 1
        }
        
        updatedAt = Date()
    }
}

extension Trip: Equatable {
    static func == (lhs: Trip, rhs: Trip) -> Bool {
        lhs.id == rhs.id
    }
}
