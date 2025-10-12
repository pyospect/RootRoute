//
//  TripListViewModel.swift
//  RootRoute
//
//  Created by 고경표 on 10/10/25.
//

import Foundation
import Combine
internal import SwiftUI

/// 여행 목록 ViewModel
@MainActor
class TripListViewModel: ObservableObject {
    @Published var trips: [Trip] = []
    @Published var isShowingCreateSheet = false
    
    private let storage: UserDefaults
    
    init(storage: UserDefaults = .standard) {
        self.storage = storage
        loadTrips()
    }
    
    func loadTrips() {
        // UserDefaults에서 로드 (나중에 CoreData나 다른 DB로 변경 가능)
        if let data = storage.data(forKey: "trips"),
           let decoded = try? JSONDecoder().decode([Trip].self, from: data) {
            trips = decoded.sorted { $0.startDate > $1.startDate }
        }
    }
    
    func saveTrips() {
        if let encoded = try? JSONEncoder().encode(trips) {
            storage.set(encoded, forKey: "trips")
        }
    }
    
    func createTrip(name: String, startDate: Date, endDate: Date) {
        let newTrip = Trip(name: name, startDate: startDate, endDate: endDate)
        trips.insert(newTrip, at: 0)
        saveTrips()
    }
    
    func deleteTrip(at indexSet: IndexSet) {
        trips.remove(atOffsets: indexSet)
        saveTrips()
    }
    
    func updateTrip(_ trip: Trip) {
        if let index = trips.firstIndex(where: { $0.id == trip.id }) {
            trips[index] = trip
            saveTrips()
        }
    }
}
