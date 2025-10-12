//
//  TripListView.swift
//  RootRoute
//
//  Created by 고경표 on 10/10/25.
//

internal import SwiftUI

struct TripListView: View {
    @EnvironmentObject private var viewModel: TripListViewModel
    @State private var showCreateSheet = false
    @State private var showSettings = false
    @State private var editingTrip: Trip?
    @State private var currentPage: Int = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 배경 그라데이션
                LinearGradient(
                    colors: [Color(hex: "784FDA").opacity(0.1), Color.white],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 컨텐츠
                    if viewModel.trips.isEmpty {
                        emptyStateView
                    } else {
                        carouselView
                    }
                }
            }
            .navigationTitle("RootRoute")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showCreateSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCreateSheet) {
                CreateTripSheet { name, startDate, endDate in
                    viewModel.createTrip(name: name, startDate: startDate, endDate: endDate)
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(item: $editingTrip) { trip in
                EditTripSheet(trip: trip) { name, startDate, endDate in
                    var updatedTrip = trip
                    updatedTrip.name = name
                    updatedTrip.startDate = startDate
                    updatedTrip.endDate = endDate
                    updatedTrip.updateDays()
                    viewModel.updateTrip(updatedTrip)
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "map.fill")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            Text("여행을 계획해보세요")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("새로운 여행을 만들고\n뚜벅이 친화적인 일정을 계획하세요")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: { showCreateSheet = true }) {
                Label("새 여행 만들기", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color(hex: "784FDA"))
                    .cornerRadius(12)
            }
            .padding(.top)
        }
        .padding()
    }
    
    private var carouselView: some View {
        GeometryReader { geometry in
            VStack(spacing: 20) {
                // 캐러셀 (화면 높이의 3/4)
                TabView(selection: $currentPage) {
                    ForEach(Array(viewModel.trips.enumerated()), id: \.element.id) { index, trip in
                        TripCardView(
                            trip: trip,
                            onEdit: { editingTrip = trip },
                            onDelete: {
                                if let deleteIndex = viewModel.trips.firstIndex(where: { $0.id == trip.id }) {
                                    viewModel.deleteTrip(at: IndexSet(integer: deleteIndex))
                                }
                            }
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                .frame(height: geometry.size.height * 0.75)
                
                Spacer()
            }
        }
    }
}

struct TripCardView: View {
    let trip: Trip
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var showDeleteAlert = false
    
    var body: some View {
        NavigationLink(destination: TripWorkspaceView(trip: trip)) {
            VStack(spacing: 0) {
                // 상단: 여행 정보
                VStack(alignment: .leading, spacing: 16) {
                    // 여행명
                    Text(trip.name)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    // 기간
                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .font(.system(size: 16))
                        Text("\(Constants.dateFormatter.string(from: trip.startDate)) - \(Constants.dateFormatter.string(from: trip.endDate))")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.white.opacity(0.9))
                    
                    // 일수
                    HStack(spacing: 8) {
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 16))
                        Text("\(trip.duration)일")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.white.opacity(0.9))
                    
                    Spacer()
                    
                    // 장소 개수
                    if !trip.days.isEmpty {
                        let totalPlaces = trip.days.reduce(0) { $0 + $1.places.count }
                        HStack(spacing: 8) {
                            Image(systemName: "mappin.and.ellipse")
                                .font(.system(size: 16))
                            Text("\(totalPlaces)개 장소")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.white.opacity(0.9))
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "784FDA"), Color(hex: "784FDA").opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                
                // 하단: 액션 버튼
                HStack(spacing: 0) {
                    Button(action: onEdit) {
                        HStack(spacing: 8) {
                            Image(systemName: "pencil")
                            Text("편집")
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(hex: "784FDA"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                    }
                    .buttonStyle(.plain)
                    
                    Divider()
                        .frame(height: 24)
                    
                    Button(action: { showDeleteAlert = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "trash")
                            Text("삭제")
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                    }
                    .buttonStyle(.plain)
                }
                .background(Color(uiColor: .systemBackground))
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
        .alert("여행 삭제", isPresented: $showDeleteAlert) {
            Button("취소", role: .cancel) {}
            Button("삭제", role: .destructive, action: onDelete)
        } message: {
            Text("\(trip.name)을(를) 삭제하시겠습니까?")
        }
    }
}

struct CreateTripSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var tripName = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(86400 * 2) // 2일 후
    
    let onCreate: (String, Date, Date) -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section("여행 정보") {
                    TextField("여행 이름", text: $tripName)
                }
                
                Section("일정") {
                    DatePicker("출발일", selection: $startDate, displayedComponents: .date)
                    DatePicker("도착일", selection: $endDate, displayedComponents: .date)
                    
                    if endDate < startDate {
                        Text("도착일은 출발일보다 늦어야 합니다")
                            .font(.caption)
                            .foregroundColor(.red)
                    } else {
                        let days = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day! + 1
                        Text("\(days)일 여행")
                            .font(.caption)
                            .foregroundColor(Color(hex: "784FDA"))
                    }
                }
            }
            .navigationTitle("새 여행 만들기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("생성") {
                        onCreate(tripName, startDate, endDate)
                        dismiss()
                    }
                    .disabled(tripName.isEmpty || endDate < startDate)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

struct EditTripSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var tripName: String
    @State private var startDate: Date
    @State private var endDate: Date
    
    let onSave: (String, Date, Date) -> Void
    
    init(trip: Trip, onSave: @escaping (String, Date, Date) -> Void) {
        self.onSave = onSave
        _tripName = State(initialValue: trip.name)
        _startDate = State(initialValue: trip.startDate)
        _endDate = State(initialValue: trip.endDate)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("여행 정보") {
                    TextField("여행 이름", text: $tripName)
                }
                
                Section("일정") {
                    DatePicker("출발일", selection: $startDate, displayedComponents: .date)
                    DatePicker("도착일", selection: $endDate, displayedComponents: .date)
                    
                    if endDate < startDate {
                        Text("도착일은 출발일보다 늦어야 합니다")
                            .font(.caption)
                            .foregroundColor(.red)
                    } else {
                        let days = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day! + 1
                        Text("\(days)일 여행")
                            .font(.caption)
                            .foregroundColor(Color(hex: "784FDA"))
                    }
                }
            }
            .navigationTitle("여행 편집")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        onSave(tripName, startDate, endDate)
                        dismiss()
                    }
                    .disabled(tripName.isEmpty || endDate < startDate)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
