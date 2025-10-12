//
//  DirectionsService.swift
//  RootRoute
//
//  Created by 고경표 on 10/10/25.
//

import Foundation
import CoreLocation

/// Google Directions API 서비스
class DirectionsService {
    private let apiKey = "AIzaSyBGgVsaKPOssT21icAbj9yoeBAMDhHYyhE"
    
    /// 대중교통 경로 계산
    func getTransitRoute(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D, departureTime: Date) async throws -> Route {
        let urlString = "https://maps.googleapis.com/maps/api/directions/json"
        
        var components = URLComponents(string: urlString)!
        components.queryItems = [
            URLQueryItem(name: "origin", value: "\(origin.latitude),\(origin.longitude)"),
            URLQueryItem(name: "destination", value: "\(destination.latitude),\(destination.longitude)"),
            URLQueryItem(name: "mode", value: "transit"),
            URLQueryItem(name: "departure_time", value: "\(Int(departureTime.timeIntervalSince1970))"),
            URLQueryItem(name: "language", value: "ko"),
            URLQueryItem(name: "key", value: apiKey)
        ]
        
        guard let url = components.url else {
            throw DirectionsError.invalidURL
        }
        
        print("🚇 대중교통 경로 계산 시도")
        print("   출발: \(origin.latitude), \(origin.longitude)")
        print("   도착: \(destination.latitude), \(destination.longitude)")
        print("   출발 시간: \(departureTime)")
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw DirectionsError.noRouteFound
        }
        
        print("📡 HTTP Status: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode != 200 {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("📡 API 응답: \(errorJson)")
            }
            throw DirectionsError.noRouteFound
        }
        
        let decoder = JSONDecoder()
        let directionsResponse = try decoder.decode(DirectionsResponse.self, from: data)
        
        // 상태 확인
        guard directionsResponse.status == "OK" else {
            print("⚠️ 대중교통 경로 실패: \(directionsResponse.status)")
            throw DirectionsError.transitNotAvailable(directionsResponse.status)
        }
        
        guard let route = directionsResponse.routes.first,
              let leg = route.legs.first else {
            print("⚠️ 대중교통 경로를 찾을 수 없음")
            throw DirectionsError.noRouteFound
        }
        
        let duration = TimeInterval(leg.duration.value)
        let distance = Double(leg.distance.value)
        let polyline = route.overviewPolyline.points
        
        print("✅ 대중교통 경로 계산 성공")
        print("   거리: \(distance)m")
        print("   시간: \(duration)초 (\(Int(duration/60))분)")
        
        return Route(
            fromPlaceId: "",
            toPlaceId: "",
            travelMode: .transit,
            duration: duration,
            distance: distance,
            encodedPolyline: polyline,
            displayMode: .transit
        )
    }
    
    /// 도보 경로 계산
    func getWalkingRoute(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) async throws -> Route {
        let urlString = "https://maps.googleapis.com/maps/api/directions/json"
        
        var components = URLComponents(string: urlString)!
        components.queryItems = [
            URLQueryItem(name: "origin", value: "\(origin.latitude),\(origin.longitude)"),
            URLQueryItem(name: "destination", value: "\(destination.latitude),\(destination.longitude)"),
            URLQueryItem(name: "mode", value: "walking"),
            URLQueryItem(name: "language", value: "ko"),
            URLQueryItem(name: "key", value: apiKey)
        ]
        
        guard let url = components.url else {
            throw DirectionsError.invalidURL
        }
        
        print("🚶 도보 경로 계산 시작")
        print("   출발: \(origin.latitude), \(origin.longitude)")
        print("   도착: \(destination.latitude), \(destination.longitude)")
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw DirectionsError.noRouteFound
        }
        
        print("📡 HTTP Status: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode != 200 {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("📡 API 응답: \(errorJson)")
            }
            throw DirectionsError.noRouteFound
        }
        
        let decoder = JSONDecoder()
        let directionsResponse = try decoder.decode(DirectionsResponse.self, from: data)
        
        guard directionsResponse.status == "OK",
              let route = directionsResponse.routes.first,
              let leg = route.legs.first else {
            print("⚠️ 경로를 찾을 수 없음")
            throw DirectionsError.noRouteFound
        }
        
        let duration = TimeInterval(leg.duration.value)
        let distance = Double(leg.distance.value)
        let polyline = route.overviewPolyline.points
        
        print("✅ 도보 경로 계산 성공")
        print("   거리: \(distance)m")
        print("   시간: \(duration)초 (\(Int(duration/60))분)")
        
        return Route(
            fromPlaceId: "",
            toPlaceId: "",
            travelMode: .walking,
            duration: duration,
            distance: distance,
            encodedPolyline: polyline
        )
    }
}

// MARK: - Response Models (Legacy Directions API)

struct DirectionsResponse: Codable {
    let status: String
    let routes: [DirectionsRoute]
}

struct DirectionsRoute: Codable {
    let legs: [DirectionsLeg]
    let overviewPolyline: OverviewPolyline
    
    enum CodingKeys: String, CodingKey {
        case legs
        case overviewPolyline = "overview_polyline"
    }
}

struct DirectionsLeg: Codable {
    let distance: ValueText
    let duration: ValueText
}

struct ValueText: Codable {
    let value: Int
    let text: String
}

struct OverviewPolyline: Codable {
    let points: String
}

// MARK: - Errors

enum DirectionsError: Error, LocalizedError {
    case invalidURL
    case noRouteFound
    case transitNotAvailable(String) // 대중교통이 지원되지 않는 지역
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "잘못된 URL"
        case .noRouteFound:
            return "경로를 찾을 수 없습니다"
        case .transitNotAvailable(let status):
            return "대중교통 정보 없음 (상태: \(status))"
        case .apiError(let message):
            return "API 오류: \(message)"
        }
    }
}

