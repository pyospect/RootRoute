//
//  PlaceEditSheet.swift
//  RootRoute
//
//  Created by 고경표 on 10/10/25.
//

internal import SwiftUI

struct PlaceEditSheet: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var arrivalTime: Date
    @State private var stayHours: Int
    @State private var stayMinutes: Int
    @State private var memo: String
    @State private var showDeleteAlert = false
    @State private var showStayTimePicker = false
    @State private var isEditingStay: Bool = false  // 직접 입력 모드
    @State private var stayInputText: String = ""  // 직접 입력 텍스트
    @FocusState private var isStayFocused: Bool
    
    let place: PlaceItem
    let onSave: (Date?, TimeInterval, String) -> Void
    let onDelete: (() -> Void)?
    
    init(place: PlaceItem, onSave: @escaping (Date?, TimeInterval, String) -> Void, onDelete: (() -> Void)? = nil) {
        self.place = place
        self.onSave = onSave
        self.onDelete = onDelete
        
        _arrivalTime = State(initialValue: place.arrivalTime ?? Date())
        
        // 체류 시간을 시간과 분으로 분리
        let totalMinutes = place.stayMinutes
        _stayHours = State(initialValue: totalMinutes / 60)
        _stayMinutes = State(initialValue: totalMinutes % 60)
        
        _memo = State(initialValue: place.memo ?? "")
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 장소 정보 카드
                    placeInfoCard
                    
                    // 지도 보기 버튼 (상단으로 이동)
                    mapButton
                    
                    // 시간 설정
                    timeSettingsSection
                    
                    // 메모
                    memoSection
                    
                    // 삭제 버튼
                    if onDelete != nil {
                        deleteButton
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("장소 편집")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                }
            }
            .alert("장소 삭제", isPresented: $showDeleteAlert) {
                Button("취소", role: .cancel) {}
                Button("삭제", role: .destructive) {
                    onDelete?()
                    dismiss()
                }
            } message: {
                Text("\(place.name)을(를) 일정에서 삭제하시겠습니까?")
            }
        }
    }
    
    // MARK: - 장소 정보 카드
    private var placeInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .font(.title2)
                    .foregroundColor(.red)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(place.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    if let address = place.address {
                        Text(address)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    // MARK: - 시간 설정
    private var timeSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("시간 설정")
                .font(.headline)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                // 도착 시간 (한 줄로 통일)
                HStack {
                    Label("도착 시간", systemImage: "clock.fill")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    DatePicker("", selection: $arrivalTime, displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                }
                .padding(16)
                
                Divider()
                    .padding(.horizontal, 16)
                
                // 체류 시간 (-10분/+10분 버튼 + 직접 입력)
                VStack(spacing: 0) {
                    HStack {
                        Label("체류 시간", systemImage: "timer")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    
                    HStack(spacing: 12) {
                        // -10분 버튼
                        Button(action: {
                            if isEditingStay {
                                isStayFocused = false
                                isEditingStay = false
                            }
                            let currentMinutes = totalMinutes
                            if currentMinutes >= 10 {
                                let newMinutes = currentMinutes - 10
                                stayHours = newMinutes / 60
                                stayMinutes = newMinutes % 60
                            }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(totalMinutes >= 10 ? Color(hex: "784FDA") : .gray)
                        }
                        .disabled(totalMinutes < 10)
                        .buttonStyle(.plain)
                        
                        Spacer()
                        
                        // 시간 표시 (탭하면 직접 입력)
                        if isEditingStay {
                            TextField("", text: $stayInputText)
                                .font(.system(size: 36, weight: .semibold, design: .rounded))
                                .foregroundColor(Color(hex: "784FDA"))
                                .multilineTextAlignment(.center)
                                .keyboardType(.numberPad)
                                .focused($isStayFocused)
                                .frame(maxWidth: 120)
                                .onChange(of: stayInputText) { _, newValue in
                                    // 숫자만 허용
                                    let filtered = newValue.filter { $0.isNumber }
                                    if filtered != newValue {
                                        stayInputText = filtered
                                    }
                                }
                                .toolbar {
                                    ToolbarItemGroup(placement: .keyboard) {
                                        Spacer()
                                        Button("완료") {
                                            if let minutes = Int(stayInputText) {
                                                let validMinutes = max(0, minutes)
                                                stayHours = validMinutes / 60
                                                stayMinutes = validMinutes % 60
                                            }
                                            isStayFocused = false
                                            isEditingStay = false
                                        }
                                        .foregroundColor(Color(hex: "784FDA"))
                                    }
                                }
                        } else {
                            Button(action: {
                                stayInputText = "\(totalMinutes)"
                                isEditingStay = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    isStayFocused = true
                                }
                            }) {
                                VStack(spacing: 2) {
                                    Text(stayTimeText)
                                        .font(.system(size: 36, weight: .semibold, design: .rounded))
                                        .foregroundColor(Color(hex: "784FDA"))
                                    
                                    Text("탭하여 직접 입력")
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        
                        Spacer()
                        
                        // +10분 버튼
                        Button(action: {
                            if isEditingStay {
                                isStayFocused = false
                                isEditingStay = false
                            }
                            let currentMinutes = totalMinutes
                            let newMinutes = currentMinutes + 10
                            stayHours = newMinutes / 60
                            stayMinutes = newMinutes % 60
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(Color(hex: "784FDA"))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }
    
    // MARK: - 메모
    private var memoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("메모")
                .font(.headline)
                .padding(.horizontal, 4)
            
            ZStack(alignment: .topLeading) {
                if memo.isEmpty {
                    Text("이 장소에 대한 메모를 입력하세요")
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                }
                
                TextEditor(text: $memo)
                    .frame(minHeight: 120)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .scrollContentBackground(.hidden)
            }
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }
    
    // MARK: - 지도 보기 버튼
    private var mapButton: some View {
        Button(action: {
            openInGoogleMaps()
        }) {
            HStack {
                Image(systemName: "map.fill")
                    .font(.body)
                
                Text("Google 지도로 보기")
                    .font(.body)
                    .fontWeight(.medium)
                
                Spacer()
                
                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .foregroundColor(Color(hex: "784FDA"))
            .padding(16)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }
    
    // MARK: - 삭제 버튼
    private var deleteButton: some View {
        Button(role: .destructive, action: {
            showDeleteAlert = true
        }) {
            HStack {
                Image(systemName: "trash.fill")
                    .font(.body)
                
                Text("일정에서 삭제")
                    .font(.body)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Helper Properties
    private var stayTimeText: String {
        if stayHours > 0 && stayMinutes > 0 {
            return "\(stayHours)시간 \(stayMinutes)분"
        } else if stayHours > 0 {
            return "\(stayHours)시간"
        } else if stayMinutes > 0 {
            return "\(stayMinutes)분"
        } else {
            return "시간 선택"
        }
    }
    
    // MARK: - Actions
    private func saveChanges() {
        let staySeconds = TimeInterval((stayHours * 60 + stayMinutes) * 60)
        onSave(arrivalTime, staySeconds, memo)
        dismiss()
    }
    
    // 총 체류 시간 (분)
    private var totalMinutes: Int {
        stayHours * 60 + stayMinutes
    }
    
    // Google Maps로 장소 열기
    private func openInGoogleMaps() {
        // 장소명과 좌표를 함께 사용 (장소명이 제대로 표시됨)
        let encodedName = place.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? place.name
        let urlString = "comgooglemaps://?q=\(encodedName)&center=\(place.latitude),\(place.longitude)"
        
        if let url = URL(string: urlString),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            // Google Maps 앱 없으면 웹으로 (Place ID가 있으면 사용)
            let webUrlString: String
            if !place.placeId.isEmpty {
                webUrlString = "https://www.google.com/maps/search/?api=1&query=\(encodedName)&query_place_id=\(place.placeId)"
            } else {
                webUrlString = "https://www.google.com/maps/search/?api=1&query=\(encodedName)"
            }
            
            if let webUrl = URL(string: webUrlString) {
                UIApplication.shared.open(webUrl)
            }
        }
    }
}


