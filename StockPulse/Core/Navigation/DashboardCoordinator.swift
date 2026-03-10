//
//  DashboardCoordinator.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import SwiftUI

final class DashboardCoordinator: ObservableObject, RouterProtocol {
    @Published var path = NavigationPath()
    @Published var presentedSheet: SheetRoute?
    @Published var presentedFullScreen: SheetRoute?
    @Published var activeDetent: PresentationDetent = .large

    // MARK: - CoordinatorProtocol

    func navigate(to route: AppRoute) {
        switch route {
        case .dashboard:
            navigateToRoot()
        case .stockDetail, .search, .notifications:
            path.append(route)
        case .notification(let userInfo):
            if let symbol = userInfo["symbol"] {
                path.append(AppRoute.stockDetail(symbol: symbol))
            }
        case .watchlist:
            presentSheet(.addToWatchlist(symbol: ""))
        }
    }

    func navigateBack() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func navigateToRoot() {
        path = NavigationPath()
    }

    func handleDeepLink(url: URL) -> Bool {
        // stockpulse://stock/{symbol}
        if url.scheme == "stockpulse", url.host == "stock",
           let symbol = url.pathComponents.dropFirst().first {
            navigate(to: .stockDetail(symbol: symbol))
            return true
        }
        // https://stockpulse.com/stock/{symbol}
        if url.scheme == "https", url.host == "stockpulse.com",
           url.pathComponents.count >= 3, url.pathComponents[1] == "stock" {
            navigate(to: .stockDetail(symbol: url.pathComponents[2]))
            return true
        }
        return false
    }

    func handleNotification(userInfo: [AnyHashable: Any]) -> Bool {
        guard let symbol = userInfo["symbol"] as? String else { return false }
        navigate(to: .stockDetail(symbol: symbol))
        return true
    }

    func handleVoiceIntent(_ intent: VoiceIntent) -> Bool {
        switch intent {
        case .navigate(let route):
            navigate(to: route)
            return true
        case .search:
            navigate(to: .search)
            return true
        case .goBack:
            navigateBack()
            return true
        case .goHome:
            navigateToRoot()
            return true
        case .dismiss:
            dismissSheet()
            return true
        default:
            return false
        }
    }

    // MARK: - RouterProtocol

    func presentSheet(_ route: SheetRoute) {
        presentedSheet = route
    }

    func presentFullScreen(_ route: SheetRoute) {
        presentedFullScreen = route
    }

    func dismissSheet() {
        presentedSheet = nil
    }

    func dismissFullScreen() {
        presentedFullScreen = nil
    }

    func setDetent(_ detent: PresentationDetent) {
        activeDetent = detent
    }
}
