//
//  AppCoordinator.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import SwiftUI
import OSLog

// TODO: Wire onOpenURL for Universal Links; add per-feature coordinators
@MainActor
final class AppCoordinator: ObservableObject, RouterProtocol {
    @Published var path = NavigationPath()
    @Published var presentedSheet: AppRoute?
    @Published var presentedFullScreenCover: AppRoute?

    private let logger = Logger(subsystem: "com.sweta.stockpulse", category: "AppCoordinator")

    func navigate(to route: AppRoute) {
        logger.debug("Navigating to \(String(describing: route))")
        // TODO: Implement — push route onto NavigationPath or present sheet
    }

    func dismiss() {
        // TODO: Implement — pop last path element or dismiss sheet
    }

    func popToRoot() {
        // TODO: Implement — clear NavigationPath
        path.removeLast(path.count)
    }
}
