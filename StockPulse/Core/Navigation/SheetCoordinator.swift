//
//  SheetCoordinator.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import SwiftUI

/// Manages multi-step sheet flows with their own NavigationPath and detent state.
final class SheetCoordinator: ObservableObject {
    @Published var sheetPath = NavigationPath()
    @Published var currentDetent: PresentationDetent = .large

    var onDismiss: (() -> Void)?

    // MARK: - Navigation

    func push(_ route: AppRoute) {
        sheetPath.append(route)
    }

    func pop() {
        guard !sheetPath.isEmpty else { return }
        sheetPath.removeLast()
    }

    func popToRoot() {
        sheetPath = NavigationPath()
    }

    // MARK: - Detent control
    // Supported detents:
    //   .medium           — half screen
    //   .large            — full height sheet
    //   .fraction(0.3)    — draggable small sheet
    //   .height(300)      — fixed custom height

    func setDetent(_ detent: PresentationDetent) {
        currentDetent = detent
    }

    // MARK: - Dismiss

    func dismiss() {
        popToRoot()
        onDismiss?()
    }
}
