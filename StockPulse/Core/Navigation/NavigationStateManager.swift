//
//  NavigationStateManager.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import Foundation

/// Singleton bus for cross-cutting navigation events (notifications, voice, deep links).
final class NavigationStateManager: ObservableObject {
    static let shared = NavigationStateManager()

    @Published var pendingRoute: AppRoute?
    @Published var pendingSheet: SheetRoute?
    @Published var pendingVoiceIntent: VoiceIntent?
    @Published var pendingNotification: [AnyHashable: Any]?

    private init() {}

    func postRoute(_ route: AppRoute) {
        pendingRoute = route
    }

    func postSheet(_ route: SheetRoute) {
        pendingSheet = route
    }

    func postVoiceIntent(_ intent: VoiceIntent) {
        pendingVoiceIntent = intent
    }

    func postNotification(userInfo: [AnyHashable: Any]) {
        pendingNotification = userInfo
    }

    func clearAll() {
        pendingRoute = nil
        pendingSheet = nil
        pendingVoiceIntent = nil
        pendingNotification = nil
    }
}
