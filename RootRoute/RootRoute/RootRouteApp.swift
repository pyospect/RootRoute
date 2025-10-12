//
//  RootRouteApp.swift
//  RootRoute
//
//  Created by 고경표 on 10/10/25.
//

internal import SwiftUI

@main
struct RootRouteApp: App {
    @StateObject private var tripListViewModel = TripListViewModel()
    
    init() {
        // 라이트 모드 고정
        setupAppearance()
    }
    
    var body: some Scene {
        WindowGroup {
            TripListView()
                .environmentObject(tripListViewModel)
                .preferredColorScheme(.light)
        }
    }
    
    private func setupAppearance() {
        // 전체 앱을 라이트 모드로 고정
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.windows.forEach { window in
                window.overrideUserInterfaceStyle = .light
            }
        }
    }
}
