//
//  PlaceSearchView.swift
//  RootRoute
//
//  Created by 고경표 on 10/10/25.
//

internal import SwiftUI

struct PlaceSearchView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = PlaceSearchViewModel()
    
    let onSelectPlace: (PlaceDetail) -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 검색 바
                searchBar
                
                // 에러 메시지
                if let errorMessage = viewModel.errorMessage {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)
                        
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button("다시 시도") {
                            Task {
                                await viewModel.performSearch(query: viewModel.searchQuery)
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                // 검색 결과
                else if viewModel.isSearching {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.searchResults.isEmpty && !viewModel.searchQuery.isEmpty {
                    emptyResultsView
                } else if !viewModel.searchResults.isEmpty {
                    searchResultsList
                }
            }
            .navigationTitle("장소 검색")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("장소 이름을 입력하세요", text: $viewModel.searchQuery)
                .textFieldStyle(.plain)
            
            if !viewModel.searchQuery.isEmpty {
                Button(action: { viewModel.searchQuery = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color(uiColor: .systemGray6))
        .cornerRadius(10)
        .padding()
    }
    
    private var emptyResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("검색 결과가 없습니다")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var searchResultsList: some View {
        List(viewModel.searchResults) { result in
            Button(action: {
                selectPlace(result)
            }) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(result.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                .padding(.vertical, 4)
            }
        }
        .listStyle(.plain)
    }
    
    private func selectPlace(_ result: PlaceSearchResult) {
        Task {
            if let placeDetail = await viewModel.getPlaceDetails(for: result) {
                await MainActor.run {
                    onSelectPlace(placeDetail)
                    dismiss()
                }
            }
        }
    }
}

