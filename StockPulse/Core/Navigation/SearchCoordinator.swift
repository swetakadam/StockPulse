//
//  SearchCoordinator.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import SwiftUI

final class SearchCoordinator: ObservableObject, RouterProtocol {
    @Published var path = NavigationPath()
    @Published var presentedSheet: SheetRoute?
    @Published var presentedFullScreen: SheetRoute?
    @Published var activeDetent: PresentationDetent = .large

    // MARK: - CoordinatorProtocol

    func navigate(to route: AppRoute) {
        switch route {
        case .search:
            navigateToRoot()
        case .stockDetail:
            path.append(route)
        default:
            break
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
        return false
    }

    func handleNotification(userInfo: [AnyHashable: Any]) -> Bool {
        return false
    }

    func handleVoiceIntent(_ intent: VoiceIntent) -> Bool {
        switch intent {
        case .search:
            navigateToRoot()    // SearchViewModel observes NavigationStateManager for query
            return true
        case .navigate(let route):
            navigate(to: route)
            return true
        case .goBack:
            navigateBack()
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
