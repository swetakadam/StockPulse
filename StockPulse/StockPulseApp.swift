//
//  StockPulseApp.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import SwiftUI

@main
struct StockPulseApp: App {
    @StateObject private var appCoordinator = AppCoordinator()

    var body: some Scene {
        WindowGroup {
            AppCoordinatorView()
                .environmentObject(appCoordinator)
        }
    }
}
