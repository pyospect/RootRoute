//
//  GooglePlacesService.swift
//  RootRoute
//
//  Created by 고경표 on 10/10/25.
//

import Foundation
import CoreLocation
import MapKit

/// Google Places API (New) 서비스
class GooglePlacesService {
    private let apiKey = "AIzaSyBGgVsaKPOssT21icAbj9yoeBAMDhHYyhE"
    
    /// 장소 자동완성 검색
    func searchPlaces(query: String) async throws -> [PlaceSearchResult] {
        let urlString = "https://places.googleapis.com/v1/places:autocomplete"
        
        guard let url = URL(string: urlString) else {
            throw PlacesAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        
        let requestBody: [String: Any] = [
            "input": query,
            "languageCode": "ko"
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PlacesAPIError.noResults
        }
        
        print("📡 HTTP Status: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode != 200 {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("📡 API 응답: \(errorJson)")
            }
            throw PlacesAPIError.noResults
        }
        
        let decoder = JSONDecoder()
        let searchResponse = try decoder.decode(PlaceAutocompleteNewResponse.self, from: data)
        
        print("📡 Suggestions: \(searchResponse.suggestions.count)개")
        
        return searchResponse.suggestions.compactMap { suggestion in
            guard let placePrediction = suggestion.placePrediction else { return nil }
            
            let name = placePrediction.structuredFormat?.mainText?.text ?? placePrediction.text?.text ?? ""
            let description = placePrediction.text?.text ?? ""
            
            return PlaceSearchResult(
                placeId: placePrediction.placeId,
                name: name,
                description: description,
                mapItem: nil
            )
        }
    }
    
    /// 장소 상세 정보 가져오기
    func getPlaceDetails(placeId: String) async throws -> PlaceDetail {
        let urlString = "https://places.googleapis.com/v1/places/\(placeId)"
        
        guard let url = URL(string: urlString) else {
            throw PlacesAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        request.setValue("displayName,formattedAddress,location", forHTTPHeaderField: "X-Goog-FieldMask")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PlacesAPIError.noResults
        }
        
        if httpResponse.statusCode != 200 {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("❌ API 에러: \(errorJson)")
            }
            throw PlacesAPIError.noResults
        }
        
        let decoder = JSONDecoder()
        let detailResponse = try decoder.decode(PlaceDetailsNewResponse.self, from: data)
        
        let coordinate = CLLocationCoordinate2D(
            latitude: detailResponse.location.latitude,
            longitude: detailResponse.location.longitude
        )
        
        return PlaceDetail(
            placeId: placeId,
            name: detailResponse.displayName?.text ?? "알 수 없는 장소",
            address: detailResponse.formattedAddress ?? "주소 정보 없음",
            coordinate: coordinate
        )
    }
}

// MARK: - Response Models (Places API New)

struct PlaceAutocompleteNewResponse: Codable {
    let suggestions: [Suggestion]
}

struct Suggestion: Codable {
    let placePrediction: PlacePrediction?
}

struct PlacePrediction: Codable {
    let placeId: String
    let text: TextContent?
    let structuredFormat: StructuredFormat?
}

struct TextContent: Codable {
    let text: String?
}

struct StructuredFormat: Codable {
    let mainText: TextContent?
    let secondaryText: TextContent?
}

struct PlaceDetailsNewResponse: Codable {
    let displayName: TextContent?
    let formattedAddress: String?
    let location: LocationNew
}

struct LocationNew: Codable {
    let latitude: Double
    let longitude: Double
}

// MARK: - Models

/// 장소 검색 결과
struct PlaceSearchResult: Identifiable, Codable {
    let id = UUID()
    let placeId: String
    let name: String
    let description: String
    var mapItem: MKMapItem?
    
    enum CodingKeys: String, CodingKey {
        case placeId, name, description
    }
}

/// 장소 상세 정보
struct PlaceDetail {
    let placeId: String
    let name: String
    let address: String
    let coordinate: CLLocationCoordinate2D
}

enum PlacesAPIError: Error, LocalizedError {
    case invalidURL
    case invalidPlaceId
    case noResults
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "잘못된 URL"
        case .invalidPlaceId:
            return "잘못된 장소 ID"
        case .noResults:
            return "검색 결과가 없습니다"
        }
    }
}

