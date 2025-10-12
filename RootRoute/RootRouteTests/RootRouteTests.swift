//
//  RootRouteTests.swift
//  RootRouteTests
//
//  Created by 고경표 on 10/10/25.
//

import Foundation
import Testing
@testable import RootRoute

struct RootRouteTests {
    
    @MainActor
    @Test func refreshTripClampsSelectedIndex() throws {
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: Date())
        let endDate = calendar.date(byAdding: .day, value: 2, to: startDate)!
        let originalTrip = Trip(name: "테스트 여행", startDate: startDate, endDate: endDate)
        
        let viewModel = TripWorkspaceViewModel(trip: originalTrip)
        viewModel.selectedDayIndex = 2
        
        var shortenedTrip = originalTrip
        shortenedTrip.endDate = startDate
        shortenedTrip.updateDays()
        
        #expect(shortenedTrip.days.count == 1)
        
        viewModel.refreshTrip(shortenedTrip)
        
        #expect(viewModel.trip.days.count == 1)
        #expect(viewModel.selectedDayIndex == 0)
    }
    
    @MainActor
    @Test func tripListViewModelPersistsTripsInCustomStore() throws {
        let suiteName = "dev.pyospect.rootroute.tests.\(UUID().uuidString)"
        guard let storage = UserDefaults(suiteName: suiteName) else {
            Issue.record("테스트용 UserDefaults를 생성할 수 없습니다.")
            return
        }
        
        storage.removePersistentDomain(forName: suiteName)
        defer { storage.removePersistentDomain(forName: suiteName) }
        
        let startDate = Calendar.current.startOfDay(for: Date())
        let endDate = Calendar.current.date(byAdding: .day, value: 3, to: startDate)!
        
        let viewModel = TripListViewModel(storage: storage)
        #expect(viewModel.trips.isEmpty)
        
        viewModel.createTrip(name: "테스트 여행", startDate: startDate, endDate: endDate)
        #expect(viewModel.trips.count == 1)
        
        let reloadedViewModel = TripListViewModel(storage: storage)
        #expect(reloadedViewModel.trips.count == 1)
        #expect(reloadedViewModel.trips.first?.name == "테스트 여행")
    }
}
