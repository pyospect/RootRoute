//
//  PlaceRow.swift
//  RootRoute
//
//  Created by 고경표 on 10/10/25.
//

internal import SwiftUI

struct PlaceRow: View {
    let place: PlaceItem
    let number: Int
    let route: Route?
    let isLastPlace: Bool
    let onEditRoute: (() -> Void)?
    let onOpenInMaps: (() -> Void)?
    let onDelete: (() -> Void)?
    let onDuplicate: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 9) {  // 8 → 9
            // 장소 카드
            placeCard
            
            // 경로 카드 (마지막 장소가 아니고 경로가 있을 때만)
            if !isLastPlace {
                if let route = route {
                    routeSection(route)
                } else {
                    // 경로가 없을 때 경고 표시
                    emptyRouteSection
                }
            }
        }
    }
    
    // MARK: - 장소 카드
    private var placeCard: some View {
        HStack(spacing: 0) {
            // 시간 정보 (왼쪽) - 원래대로 복원
            if let arrival = place.arrivalTime, let departure = place.departureTime {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 0) {
                        Text("IN")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.green)
                            .frame(width: 26, alignment: .leading)
                        
                        Text(Constants.timeFormatter.string(from: arrival))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 0) {
                        Text("OUT")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.red)
                            .frame(width: 26, alignment: .leading)
                        
                        Text(Constants.timeFormatter.string(from: departure))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 72, alignment: .leading)
                
                Divider()
                    .frame(height: 32)
                    .padding(.horizontal, 8)
            }
            
            // 번호 뱃지
            ZStack {
                Circle()
                    .fill(Color(hex: "784FDA"))
                    .frame(width: 28, height: 28)
                
                Text("\(number)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.trailing, 10)
            
            // 장소 이름
            Text(place.name)
                .font(.system(size: 14, weight: .bold))
                .lineLimit(1)
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, cardVerticalPadding)  // 체류시간에 따라 동적 높이
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(10)
        .contextMenu {
            // 다음 장소로 이동 길찾기 (마지막 장소가 아닐 때만)
            if !isLastPlace, let onOpenInMaps = onOpenInMaps {
                Button(action: onOpenInMaps) {
                    Label("다음 장소 이동 길찾기", systemImage: "map.fill")
                }
            }
            
            // 복제
            if let onDuplicate = onDuplicate {
                Button(action: onDuplicate) {
                    Label("복제", systemImage: "doc.on.doc")
                }
            }
            
            // 삭제
            if let onDelete = onDelete {
                Button(role: .destructive, action: onDelete) {
                    Label("삭제", systemImage: "trash")
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    // 체류시간에 비례한 카드 높이 계산
    private var cardVerticalPadding: CGFloat {
        let hours = Int(place.stayDuration / 3600)  // 초를 시간으로 변환 (소수점 버림)
        
        // 0~1시간: 10pt, 2시간: 20pt, 3시간: 30pt, ...
        if hours < 2 {
            return 10
        } else {
            return CGFloat(hours * 10)
        }
    }
    
    // MARK: - 경로 섹션
    private func routeSection(_ route: Route) -> some View {
        VStack(spacing: 4) {
            // 경로 카드 (재설정 필요 시 색상/텍스트 변경)
            routeCard(route)
            
            // 예약 필요 배너
            if route.requiresReservation, !(route.reservationInfo?.isReserved ?? false) {
                reservationBanner
            }
        }
        .padding(.leading, 84) // IN/OUT 시간 영역 + 여백 (72 + 12)
    }
    
    // MARK: - 경로 없음 섹션
    private var emptyRouteSection: some View {
        Button(action: {
            onEditRoute?()
        }) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 11))
                
                Text("경로를 설정해주세요")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.orange)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .frame(minHeight: 28)
            .background(Color.orange.opacity(0.15))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.orange.opacity(0.4), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .padding(.leading, 84)
    }
    
    private func routeCard(_ route: Route) -> some View {
        Button(action: {
            onEditRoute?()
        }) {
            HStack(spacing: 6) {
                // needsUpdate일 때 경고 표시
                if route.needsUpdate {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 11))
                    
                    Text("경로 재설정 필요")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.orange)
                } else {
                    // 교통수단 아이콘
                    Text(route.travelMode.icon)
                        .font(.system(size: 11))
                    
                    // 교통수단명 · 소요시간
                    Text("\(route.travelMode.displayName) · \(formattedDuration(route))")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                // 예약 상태 아이콘 (재설정 필요할 때는 숨김)
                if !route.needsUpdate && route.requiresReservation {
                    if let info = route.reservationInfo, info.isReserved {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 11))
                    } else {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.orange)
                            .font(.system(size: 11))
                    }
                }
                
                // 편집 아이콘
                Image(systemName: "chevron.right")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .frame(minHeight: 28)
            .background(route.needsUpdate ? Color.orange.opacity(0.15) : Color(uiColor: .tertiarySystemGroupedBackground))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(route.needsUpdate ? Color.orange.opacity(0.4) : Color.clear, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            if let onOpenInMaps = onOpenInMaps {
                Button(action: onOpenInMaps) {
                    Label("Google 지도에서 보기", systemImage: "map.fill")
                }
            }
        }
    }
    
    private var reservationBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "ticket.fill")
                .foregroundColor(.orange)
                .font(.system(size: 11))
            
            Text("예약이 필요합니다")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.orange)
            
            Spacer()
            
            Button(action: {
                onEditRoute?()
            }) {
                Text("예약하기")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.orange)
                    .cornerRadius(5)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(6)
    }
    
    private func formattedDuration(_ route: Route) -> String {
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
