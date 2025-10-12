//
//  DayTab.swift
//  RootRoute
//
//  Created by 고경표 on 10/10/25.
//

internal import SwiftUI

struct DayTab: View {
    let dayNumber: Int
    let date: Date
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            // 날짜를 크게 강조 (상단)
            Text(dayString)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(isSelected ? Color(hex: "784FDA") : .primary)
            
            // Day 레이블을 하단에
            Text("Day \(dayNumber)")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(isSelected ? Color(hex: "784FDA") : .secondary)
        }
        .frame(width: 70, height: 64)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isSelected ? Color(hex: "784FDA").opacity(0.12) : Color(uiColor: .secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(isSelected ? Color(hex: "784FDA") : Color.clear, lineWidth: 2)
        )
    }
    
    private var dayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
}

