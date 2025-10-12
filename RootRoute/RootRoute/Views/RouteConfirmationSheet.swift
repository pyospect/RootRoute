//
//  RouteConfirmationSheet.swift
//  RootRoute
//
//  Created by AI on 10/11/25.
//

internal import SwiftUI
import WebKit
import CoreLocation

struct RouteConfirmationSheet: View {
    @Environment(\.dismiss) var dismiss
    
    let fromPlace: PlaceItem
    let toPlace: PlaceItem
    let existingRoute: Route?
    let onConfirm: (TravelMode, TimeInterval, Bool, ReservationInfo?) -> Void
    
    @State private var selectedTab: RouteTab = .map
    @State private var selectedMode: TravelMode
    @State private var durationMinutes: Double = 0  // 슬라이더용 (0~240분)
    @State private var requiresReservation: Bool = false
    @State private var reservationCompleted: Bool = false
    @State private var reservationMemo: String = ""
    @State private var showToast: Bool = true  // 토스트 표시 여부
    @State private var isEditingDuration: Bool = false  // 직접 입력 모드
    @State private var durationInputText: String = ""  // 직접 입력 텍스트
    @FocusState private var isDurationFocused: Bool
    
    init(fromPlace: PlaceItem, toPlace: PlaceItem, existingRoute: Route? = nil, onConfirm: @escaping (TravelMode, TimeInterval, Bool, ReservationInfo?) -> Void) {
        self.fromPlace = fromPlace
        self.toPlace = toPlace
        self.existingRoute = existingRoute
        self.onConfirm = onConfirm
        
        // 기존 경로가 있으면 그 값으로 초기화
        _selectedMode = State(initialValue: existingRoute?.travelMode ?? .transit)
        
        if let route = existingRoute {
            let totalMinutes = route.durationMinutes
            // 10분 단위로 반올림
            let roundedMinutes = (Double(totalMinutes) / 10.0).rounded() * 10.0
            _durationMinutes = State(initialValue: min(240, max(0, roundedMinutes)))
            _requiresReservation = State(initialValue: route.requiresReservation)
            
            if let info = route.reservationInfo {
                _reservationCompleted = State(initialValue: info.isReserved)
                _reservationMemo = State(initialValue: info.memo ?? "")
            }
        }
    }
    
    enum RouteTab: String, CaseIterable {
        case map = "지도"
        case input = "입력"
    }
    
    private var straightLineDistance: Double {
        let from = CLLocation(latitude: fromPlace.latitude, longitude: fromPlace.longitude)
        let to = CLLocation(latitude: toPlace.latitude, longitude: toPlace.longitude)
        return from.distance(from: to) / 1000
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 탭 선택
                Picker("", selection: $selectedTab) {
                    ForEach(RouteTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                // 탭 컨텐츠
                TabView(selection: $selectedTab) {
                    mapTab
                        .tag(RouteTab.map)
                    
                    inputTab
                        .tag(RouteTab.input)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("\(fromPlace.name) → \(toPlace.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        saveRoute()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValidInput)
                }
            }
        }
    }
    
    // MARK: - 지도 탭 (FAB 제거)
    private var mapTab: some View {
        ZStack(alignment: .bottom) {
            GoogleMapsWebView(
                fromPlace: fromPlace,
                toPlace: toPlace,
                mode: selectedMode
            )
            .ignoresSafeArea(edges: .bottom)
            
            // 토스트 안내 문구 (3초 후 페이드아웃)
            if showToast {
                Text("팝업이 열린다면 '웹으로 돌아가기'를 눌러주세요")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(uiColor: .systemBackground).opacity(0.9))
                    .cornerRadius(8)
                    .padding(.bottom, 16)
                    .opacity(showToast ? 1 : 0)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation(.easeOut(duration: 0.5)) {
                                showToast = false
                            }
                        }
                    }
            }
        }
    }
    
    // MARK: - 입력 탭
    private var inputTab: some View {
        Form {
            Section("경로 요약") {
                LabeledContent {
                    Text(fromPlace.name)
                        .font(.body)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                        .accessibilityLabel("출발지 \(fromPlace.name)")
                } label: {
                    Label("출발", systemImage: "figure.walk")
                        .foregroundStyle(.secondary)
                }
                
                LabeledContent {
                    Text(toPlace.name)
                        .font(.body)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                        .accessibilityLabel("도착지 \(toPlace.name)")
                } label: {
                    Label("도착", systemImage: "mappin")
                        .foregroundStyle(.secondary)
                }
                
                LabeledContent {
                    Text(String(format: "%.1f km", straightLineDistance))
                        .fontWeight(.semibold)
                        .accessibilityLabel("직선거리 \(String(format: "%.1f킬로미터", straightLineDistance))")
                } label: {
                    Label("직선거리", systemImage: "ruler")
                        .foregroundStyle(.secondary)
                }
            }
            
            Section("교통수단") {
                Picker("교통수단", selection: $selectedMode) {
                    ForEach([TravelMode.walking, .transit, .driving], id: \.self) { mode in
                        Text("\(mode.icon) \(mode.displayName)")
                            .tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.vertical, 4)
                .accessibilityLabel("교통수단 선택")
            }
            
            Section {
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Button(action: { adjustDuration(by: -10) }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 30))
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(durationMinutes > 0 ? Color(hex: "784FDA") : .gray)
                        .disabled(durationMinutes <= 0)
                        
                        Spacer()
                        
                        Group {
                            if isEditingDuration {
                                TextField("분 단위", text: $durationInputText)
                                    .font(.system(size: 34, weight: .semibold, design: .rounded))
                                    .multilineTextAlignment(.center)
                                    .keyboardType(.numberPad)
                                    .focused($isDurationFocused)
                                    .frame(maxWidth: 140)
                                    .onChange(of: durationInputText) { _, newValue in
                                        let filtered = newValue.filter { $0.isNumber }
                                        if filtered != newValue {
                                            durationInputText = filtered
                                        }
                                    }
                                    .toolbar {
                                        ToolbarItemGroup(placement: .keyboard) {
                                            Spacer()
                                            Button("완료") {
                                                commitDurationInput()
                                            }
                                            .foregroundColor(Color(hex: "784FDA"))
                                        }
                                    }
                            } else {
                                Button(action: beginManualDurationInput) {
                                    VStack(spacing: 2) {
                                        Text(formatDuration(Int(durationMinutes)))
                                            .font(.system(size: 34, weight: .semibold, design: .rounded))
                                            .foregroundColor(Color(hex: "784FDA"))
                                        
                                        Text("탭하여 직접 입력")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: { adjustDuration(by: 10) }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 30))
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(durationMinutes < 240 ? Color(hex: "784FDA") : .gray)
                        .disabled(durationMinutes >= 240)
                    }
                    
                    Slider(value: $durationMinutes, in: 0...240, step: 5) {
                        Text("소요 시간")
                    } minimumValueLabel: {
                        Text("0")
                            .font(.caption)
                    } maximumValueLabel: {
                        Text("240")
                            .font(.caption)
                    }
                    .tint(Color(hex: "784FDA"))
                    .accessibilityLabel("소요 시간 슬라이더")
                }
                .padding(.vertical, 4)
            } header: {
                Text("소요 시간")
            } footer: {
                Text("'지도' 탭에서 경로를 확인한 뒤 시간을 조정하세요.")
            }
            
            Section("예약") {
                Toggle(isOn: $requiresReservation.animation()) {
                    Label("예약 필요", systemImage: "ticket.fill")
                        .symbolRenderingMode(.hierarchical)
                }
                .accessibilityHint("예약 정보가 필요한 이동 구간에 사용하세요.")
            }
            
            if requiresReservation {
                Section {
                    Toggle(isOn: $reservationCompleted) {
                        Label("예약 완료", systemImage: "checkmark.circle")
                            .symbolRenderingMode(.hierarchical)
                    }
                    
                    if reservationCompleted {
                        TextEditor(text: $reservationMemo)
                            .frame(minHeight: 80)
                            .padding(.vertical, 4)
                            .scrollContentBackground(.hidden)
                            .background(Color(uiColor: .tertiarySystemGroupedBackground))
                            .cornerRadius(8)
                            .accessibilityLabel("예약 메모")
                    }
                } header: {
                    Text("예약 세부정보")
                } footer: {
                    Text("예약 번호, 좌석, 메모 등을 기록해 두세요.")
                }
            }
        }
        .formStyle(.grouped)
        .scrollDismissesKeyboard(.interactively)
    }
    
    private func adjustDuration(by change: Double) {
        let newValue = min(240, max(0, durationMinutes + change))
        durationMinutes = newValue
        isEditingDuration = false
        isDurationFocused = false
    }
    
    private func beginManualDurationInput() {
        durationInputText = "\(Int(durationMinutes))"
        isEditingDuration = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isDurationFocused = true
        }
    }
    
    private func commitDurationInput() {
        if let minutes = Int(durationInputText) {
            durationMinutes = min(240, max(0, Double(minutes)))
        }
        isDurationFocused = false
        isEditingDuration = false
    }
    
    private func formatDuration(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        
        if hours > 0 && mins > 0 {
            return "\(hours):\(String(format: "%02d", mins))"
        } else if hours > 0 {
            return "\(hours):00"
        } else {
            return "\(mins)분"
        }
    }
    
    private var isValidInput: Bool {
        return durationMinutes > 0
    }
    
    private func saveRoute() {
        let totalMinutes = Int(durationMinutes)
        let duration = TimeInterval(totalMinutes * 60)
        
        var reservationInfo: ReservationInfo? = nil
        if requiresReservation {
            var info = ReservationInfo(isReserved: reservationCompleted)
            info.memo = reservationMemo.isEmpty ? nil : reservationMemo
            reservationInfo = info
        }
        
        onConfirm(selectedMode, duration, requiresReservation, reservationInfo)
        dismiss()
    }
}

// MARK: - WebView (Place ID 포함)
struct GoogleMapsWebView: UIViewRepresentable {
    let fromPlace: PlaceItem
    let toPlace: PlaceItem
    let mode: TravelMode
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.scrollView.isScrollEnabled = true
        webView.scrollView.bounces = true
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "www.google.com"
        components.path = "/maps/dir/"
        
        let travelMode: String
        switch mode {
        case .walking: travelMode = "walking"
        case .transit: travelMode = "transit"
        case .driving: travelMode = "driving"
        }
        
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "api", value: "1"),
            URLQueryItem(name: "travelmode", value: travelMode)
        ]
        
        // Place ID 우선 사용
        if !fromPlace.placeId.isEmpty {
            queryItems.append(URLQueryItem(name: "origin", value: fromPlace.name))
            queryItems.append(URLQueryItem(name: "origin_place_id", value: fromPlace.placeId))
        } else {
            queryItems.append(URLQueryItem(name: "origin", value: "\(fromPlace.latitude),\(fromPlace.longitude)"))
        }
        
        if !toPlace.placeId.isEmpty {
            queryItems.append(URLQueryItem(name: "destination", value: toPlace.name))
            queryItems.append(URLQueryItem(name: "destination_place_id", value: toPlace.placeId))
        } else {
            queryItems.append(URLQueryItem(name: "destination", value: "\(toPlace.latitude),\(toPlace.longitude)"))
        }
        
        components.queryItems = queryItems
        
        if let url = components.url {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
}
