//
//  DayMapView.swift
//  RootRoute
//
//  Created by 고경표 on 10/10/25.
//

internal import SwiftUI
import MapKit

struct DayMapView: View {
    let dayPlan: DayPlan
    @Environment(\.dismiss) var dismiss
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var showUserLocation = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                MapViewRepresentable(
                    places: dayPlan.places,
                    region: $region,
                    showUserLocation: $showUserLocation
                )
                .ignoresSafeArea()
                
                // 현위치 버튼
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            showUserLocation.toggle()
                        }) {
                            Image(systemName: showUserLocation ? "location.fill" : "location")
                                .font(.system(size: 20))
                                .foregroundColor(showUserLocation ? Color(hex: "784FDA") : .primary)
                                .frame(width: 44, height: 44)
                                .background(Color(uiColor: .systemBackground))
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
                        }
                        .padding(.trailing, 16)
                        .padding(.bottom, 16)
                    }
                }
            }
            .navigationTitle(DateFormatter.dayFormatter.string(from: dayPlan.date))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("완료") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .onAppear {
                updateRegionToFitPlaces()
            }
        }
    }
    
    private func updateRegionToFitPlaces() {
        guard !dayPlan.places.isEmpty else { return }
        
        let coordinates = dayPlan.places.map { place in
            CLLocationCoordinate2D(
                latitude: place.coordinate.latitude,
                longitude: place.coordinate.longitude
            )
        }
        
        let minLat = coordinates.map { $0.latitude }.min() ?? 0
        let maxLat = coordinates.map { $0.latitude }.max() ?? 0
        let minLon = coordinates.map { $0.longitude }.min() ?? 0
        let maxLon = coordinates.map { $0.longitude }.max() ?? 0
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.3, 0.01),
            longitudeDelta: max((maxLon - minLon) * 1.3, 0.01)
        )
        
        region = MKCoordinateRegion(center: center, span: span)
    }
}

// MARK: - MapKit UIViewRepresentable

struct MapViewRepresentable: UIViewRepresentable {
    let places: [PlaceItem]
    @Binding var region: MKCoordinateRegion
    @Binding var showUserLocation: Bool
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = false
        
        // 다크 모드 지도 설정 (선이 잘 보이도록)
        mapView.overrideUserInterfaceStyle = .dark
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.setRegion(region, animated: true)
        mapView.showsUserLocation = showUserLocation
        
        // 기존 장소 annotations만 제거 (사용자 위치는 유지)
        let placeAnnotations = mapView.annotations.filter { $0 is NumberedAnnotation }
        mapView.removeAnnotations(placeAnnotations)
        mapView.removeOverlays(mapView.overlays)
        
        // 장소별 번호 annotations 추가
        for (index, place) in places.enumerated() {
            let annotation = NumberedAnnotation(
                coordinate: CLLocationCoordinate2D(
                    latitude: place.coordinate.latitude,
                    longitude: place.coordinate.longitude
                ),
                title: place.name,
                subtitle: formatArrivalTime(place.arrivalTime),
                number: index + 1
            )
            mapView.addAnnotation(annotation)
        }
        
        // 곡선 polyline 추가 (각 경로마다 독립적으로)
        if places.count >= 2 {
            for i in 0..<(places.count - 1) {
                let start = CLLocationCoordinate2D(
                    latitude: places[i].coordinate.latitude,
                    longitude: places[i].coordinate.longitude
                )
                let end = CLLocationCoordinate2D(
                    latitude: places[i+1].coordinate.latitude,
                    longitude: places[i+1].coordinate.longitude
                )
                
                // 경로 인덱스에 따라 곡선 방향 결정 (왕복 시 구분)
                let curvePoints = createCurvedPath(from: start, to: end, routeIndex: i)
                
                // 각 경로마다 별도의 polyline 생성 (왕복 경로가 겹치지 않도록)
                let polyline = MKPolyline(coordinates: curvePoints, count: curvePoints.count)
                mapView.addOverlay(polyline)
            }
        }
    }
    
    // 두 점 사이에 곡선 경로 생성
    private func createCurvedPath(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D, routeIndex: Int) -> [CLLocationCoordinate2D] {
        let midLat = (start.latitude + end.latitude) / 2
        let midLon = (start.longitude + end.longitude) / 2
        
        // 경로 방향 벡터 계산
        let deltaLat = end.latitude - start.latitude
        let deltaLon = end.longitude - start.longitude
        let distance = sqrt(deltaLat * deltaLat + deltaLon * deltaLon)
        
        // 곡률: 거리의 30%
        let curveAmount = distance * 0.30
        
        // 모든 경로를 한쪽 방향으로만 곡선 그리기
        let perpFactor: Double = 1.0
        
        // 수직 벡터 (진행 방향에 대해 수직)
        // 위도/경도이므로 단순히 90도 회전
        let perpLat = -deltaLon * perpFactor
        let perpLon = deltaLat * perpFactor
        
        // 정규화
        let perpLength = sqrt(perpLat * perpLat + perpLon * perpLon)
        let normalizedPerpLat = perpLat / perpLength
        let normalizedPerpLon = perpLon / perpLength
        
        // 제어점: 중간점에서 수직 방향으로 offset
        let controlPoint = CLLocationCoordinate2D(
            latitude: midLat + normalizedPerpLat * curveAmount,
            longitude: midLon + normalizedPerpLon * curveAmount
        )
        
        // Quadratic Bezier curve 포인트 계산 (30개 지점으로 더 부드러운 곡선)
        return (0...30).map { i in
            let t = Double(i) / 30.0
            return quadraticBezierPoint(t: t, p0: start, p1: controlPoint, p2: end)
        }
    }
    
    // Quadratic Bezier 포인트 계산
    private func quadraticBezierPoint(t: Double, p0: CLLocationCoordinate2D, p1: CLLocationCoordinate2D, p2: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        let lat = pow(1-t, 2) * p0.latitude + 2*(1-t)*t * p1.latitude + pow(t, 2) * p2.latitude
        let lon = pow(1-t, 2) * p0.longitude + 2*(1-t)*t * p1.longitude + pow(t, 2) * p2.longitude
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    private func formatArrivalTime(_ date: Date?) -> String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        // Annotation View 설정 (번호가 표시된 핀)
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let numberedAnnotation = annotation as? NumberedAnnotation else {
                return nil
            }
            
            let identifier = "NumberedPin"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
            } else {
                annotationView?.annotation = annotation
            }
            
            // 번호가 표시된 커스텀 이미지 생성 (원형 배지)
            let pinImage = createNumberedPinImage(number: numberedAnnotation.number)
            annotationView?.image = pinImage
            annotationView?.centerOffset = CGPoint(x: 0, y: 0) // 중앙 정렬
            
            return annotationView
        }
        
        // Polyline Renderer 설정 (점선, Primary 색상)
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor(red: 120/255, green: 79/255, blue: 218/255, alpha: 1.0)  // Primary 색상 #784FDA
                renderer.lineWidth = 2
                renderer.lineDashPattern = [2, 6] // 점선 패턴
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        // 번호가 표시된 원형 배지 이미지 생성
        private func createNumberedPinImage(number: Int) -> UIImage {
            let size = CGSize(width: 32, height: 32)
            let renderer = UIGraphicsImageRenderer(size: size)
            
            let image = renderer.image { context in
                // 원형 배경 (Primary 색상)
                let circlePath = UIBezierPath(
                    ovalIn: CGRect(x: 2, y: 2, width: 28, height: 28)
                )
                UIColor(red: 120/255, green: 79/255, blue: 218/255, alpha: 1.0).setFill()  // Primary 색상 #784FDA
                circlePath.fill()
                
                // 테두리
                UIColor.white.setStroke()
                circlePath.lineWidth = 2
                circlePath.stroke()
                
                // 번호 텍스트
                let numberText = "\(number)"
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 16),
                    .foregroundColor: UIColor.white
                ]
                let textSize = numberText.size(withAttributes: attributes)
                let textRect = CGRect(
                    x: 16 - textSize.width / 2,
                    y: 16 - textSize.height / 2,
                    width: textSize.width,
                    height: textSize.height
                )
                numberText.draw(in: textRect, withAttributes: attributes)
            }
            
            return image
        }
    }
}

// MARK: - Custom Annotation

class NumberedAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let title: String?
    let subtitle: String?
    let number: Int
    
    init(coordinate: CLLocationCoordinate2D, title: String?, subtitle: String?, number: Int) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        self.number = number
        super.init()
    }
}

// MARK: - DateFormatter Extension

extension DateFormatter {
    static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M월 d일 (E)"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()
}

