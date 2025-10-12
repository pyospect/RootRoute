//
//  RouteCard.swift
//  RootRoute
//
//  Created by 고경표 on 10/10/25.
//

internal import SwiftUI

struct RouteCard: View {
    let route: Route
    let onOpenInMaps: () -> Void
    let onEditRoute: () -> Void
    
    var body: some View {
        Button(action: onEditRoute) {
            HStack(spacing: 8) {
                // 재설정 필요 경고
                if route.needsUpdate {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                
                // 교통수단 아이콘
                Text(route.travelMode.icon)
                    .font(.body)
                
                // 소요시간
                Text(formattedDuration)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(route.needsUpdate ? .orange : nil)
                
                // 예약 필요 - 상태별 아이콘
                if route.requiresReservation {
                    if let info = route.reservationInfo, info.isReserved {
                        // 예약 완료
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else {
                        // 예약 필요 (미완료)
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                Spacer()
                
                // 편집 아이콘
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .foregroundColor(route.travelMode == .walking ? .secondary : Color(hex: "784FDA"))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(action: onOpenInMaps) {
                Label("Google 지도에서 보기", systemImage: "map.fill")
            }
        }
    }
    
    private var formattedDuration: String {
        let totalMinutes = route.durationMinutes
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        
        if hours > 0 && minutes > 0 {
            return "\(hours)시간 \(minutes)분"
        } else if hours > 0 {
            return "\(hours)시간"
        } else {
            return "\(minutes)분"
        }
    }
}
