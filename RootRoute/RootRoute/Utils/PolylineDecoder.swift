//
//  PolylineDecoder.swift
//  RootRoute
//
//  Created by 고경표 on 10/10/25.
//

import Foundation
import CoreLocation

/// Google Polyline 디코더
struct PolylineDecoder {
    
    /// 구글의 encoded polyline을 좌표 배열로 디코딩
    static func decode(_ encodedString: String) -> [CLLocationCoordinate2D] {
        var coordinates: [CLLocationCoordinate2D] = []
        var index = encodedString.startIndex
        var lat = 0
        var lng = 0
        
        while index < encodedString.endIndex {
            var result = 0
            var shift = 0
            var byte: Int
            
            repeat {
                byte = Int(encodedString[index].asciiValue! - 63)
                index = encodedString.index(after: index)
                result |= (byte & 0x1F) << shift
                shift += 5
            } while byte >= 0x20
            
            let deltaLat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1))
            lat += deltaLat
            
            result = 0
            shift = 0
            
            repeat {
                byte = Int(encodedString[index].asciiValue! - 63)
                index = encodedString.index(after: index)
                result |= (byte & 0x1F) << shift
                shift += 5
            } while byte >= 0x20
            
            let deltaLng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1))
            lng += deltaLng
            
            let coordinate = CLLocationCoordinate2D(
                latitude: Double(lat) / 1e5,
                longitude: Double(lng) / 1e5
            )
            coordinates.append(coordinate)
        }
        
        return coordinates
    }
}

