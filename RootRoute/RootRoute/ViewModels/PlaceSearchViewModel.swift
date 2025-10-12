//
//  PlaceSearchViewModel.swift
//  RootRoute
//
//  Created by 고경표 on 10/10/25.
//

import Foundation
import Combine

/// 장소 검색 ViewModel
@MainActor
class PlaceSearchViewModel: ObservableObject {
    @Published var searchQuery: String = ""
    @Published var searchResults: [PlaceSearchResult] = []
    @Published var isSearching = false
    @Published var errorMessage: String?
    
    private let placesService = GooglePlacesService()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupSearchDebounce()
    }
    
    private func setupSearchDebounce() {
        // 검색어 변경 시 1초 후 자동 검색 (비용 절감)
        $searchQuery
            .debounce(for: .seconds(1.0), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] query in
                guard let self = self else { return }
                
                if query.isEmpty {
                    self.searchResults = []
                    self.errorMessage = nil
                } else if query.count >= 2 {  // 최소 2글자 이상
                    Task {
                        await self.performSearch(query: query)
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    func performSearch(query: String) async {
        isSearching = true
        errorMessage = nil
        
        do {
            print("🔍 검색 시작: \(query)")
            let results = try await placesService.searchPlaces(query: query)
            print("✅ 검색 결과: \(results.count)개")
            searchResults = results
        } catch {
            print("❌ 검색 실패: \(error)")
            errorMessage = "검색에 실패했습니다: \(error.localizedDescription)"
            searchResults = []
        }
        
        isSearching = false
    }
    
    func getPlaceDetails(for result: PlaceSearchResult) async -> PlaceDetail? {
        do {
            print("📍 장소 상세 정보 요청: \(result.placeId)")
            let detail = try await placesService.getPlaceDetails(placeId: result.placeId)
            print("✅ 장소 상세 정보 받음: \(detail.name)")
            return detail
        } catch {
            print("❌ 장소 상세 정보 실패: \(error)")
            errorMessage = "장소 정보를 불러오지 못했습니다"
            return nil
        }
    }
}

