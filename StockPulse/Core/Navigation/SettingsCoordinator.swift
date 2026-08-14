//
//  SettingsCoordinator.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import SwiftUI

final class SettingsCoordinator: ObservableObject, RouterProtocol {
    @Published var path = NavigationPath()
    @Published var presentedSheet: SheetRoute?
    @Published var presentedFullScreen: SheetRoute?
    @Published var activeDetent: PresentationDetent = .medium

    var sheetCoordinator = SheetCoordinator()

    func navigate(to route: AppRoute) {
        path.append(route)
    }

    func navigateBack() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func navigateToRoot() {
        path = NavigationPath()
    }

    func handleDeepLink(url: URL) -> Bool { false }

    func handleNotification(userInfo: [AnyHashable: Any]) -> Bool { false }

    func handleVoiceIntent(_ intent: VoiceIntent) -> Bool {
        switch intent {
        case .goBack:  navigateBack(); return true
        case .dismiss: dismissSheet(); return true
        default:       return false
        }
    }

    func presentSheet(_ route: SheetRoute) {
        sheetCoordinator.currentDetent = .medium
        presentedSheet = route
    }

    func presentFullScreen(_ route: SheetRoute) {
        presentedFullScreen = route
    }

    func dismissSheet() {
        presentedSheet = nil
        sheetCoordinator.popToRoot()
    }

    func dismissFullScreen() {
        presentedFullScreen = nil
    }

    func setDetent(_ detent: PresentationDetent) {
        activeDetent = detent
    }
}
