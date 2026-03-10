//
//  AuthCoordinator.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import SwiftUI

final class AuthCoordinator: ObservableObject, RouterProtocol {
    @Published var path = NavigationPath()
    @Published var presentedSheet: SheetRoute?
    @Published var presentedFullScreen: SheetRoute?
    @Published var activeDetent: PresentationDetent = .large
    @Published var isComplete: Bool = false

    var onComplete: (() -> Void)?

    // MARK: - CoordinatorProtocol

    func navigate(to route: AppRoute) {
        // Auth only handles internal auth routes; ignore others
        path.append(route)
    }

    func navigateBack() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func navigateToRoot() {
        path = NavigationPath()
    }

    func handleDeepLink(url: URL) -> Bool {
        return false     // Auth does not handle deep links
    }

    func handleNotification(userInfo: [AnyHashable: Any]) -> Bool {
        return false     // Auth does not handle notifications
    }

    func handleVoiceIntent(_ intent: VoiceIntent) -> Bool {
        switch intent {
        case .goBack:
            navigateBack()
            return true
        case .dismiss:
            completeAuthFlow()
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

    // MARK: - Auth flow completion

    func completeAuthFlow() {
        isComplete = true
        onComplete?()
    }
}
