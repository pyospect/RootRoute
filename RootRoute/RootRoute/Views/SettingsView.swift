//
//  SettingsView.swift
//  RootRoute
//
//  Created by 고경표 on 10/10/25.
//

internal import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var settings = UserSettings.shared
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("하루 시작 시간", selection: $settings.defaultStartHour) {
                        ForEach(0..<24, id: \.self) { hour in
                            Text(hourText(hour)).tag(hour)
                        }
                    }
                } header: {
                    Text("일정 설정")
                } footer: {
                    Text("새로 추가하는 여행의 첫 장소 도착 시간이 이 시간으로 설정됩니다.")
                }
                
                Section {
                    HStack {
                        Text("앱 버전")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("정보")
                }
            }
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("완료") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func hourText(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "a h시"
        
        let calendar = Calendar.current
        let date = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
        return formatter.string(from: date)
    }
}

