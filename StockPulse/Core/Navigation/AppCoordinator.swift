//
//  AppCoordinator.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import SwiftUI
import Combine

final class AppCoordinator: ObservableObject {

    // MARK: - AppTab

    enum AppTab: String, CaseIterable {
        case dashboard
        case watchlist
        case search
        case notifications
        case assistant
    }

    // MARK: - Feature Coordinators

    var authCoordinator        = AuthCoordinator()
    var dashboardCoordinator   = DashboardCoordinator()
    var stockDetailCoordinator = StockDetailCoordinator()
    var watchlistCoordinator   = WatchlistCoordinator()
    var searchCoordinator      = SearchCoordinator()

    // MARK: - Root State

    @Published var activeTab: AppTab = .dashboard
    @Published var isShowingAuth: Bool = false

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init() {
        authCoordinator.onComplete = { [weak self] in
            self?.authFlowComplete()
        }
        observeNavigationStateManager()
    }

    // MARK: - Universal Links

    func handleUniversalLink(url: URL) {
        let coordinators: [any CoordinatorProtocol] = [
            dashboardCoordinator,
            stockDetailCoordinator,
            watchlistCoordinator,
            searchCoordinator
        ]
        for coordinator in coordinators {
            if coordinator.handleDeepLink(url: url) { return }
        }
    }

    // MARK: - Notifications

    func handleNotification(userInfo: [AnyHashable: Any]) {
        activeTab = .dashboard
        dashboardCoordinator.handleNotification(userInfo: userInfo)
    }

    // MARK: - Voice

    func handleVoiceIntent(_ intent: VoiceIntent) {
        switch intent {
        case .navigate(let route):
            activeCoordinator.navigate(to: route)
        case .search(let query):
            activeTab = .search
            searchCoordinator.handleVoiceIntent(.search(query: query))
        case .addToWatchlist, .removeFromWatchlist:
            watchlistCoordinator.handleVoiceIntent(intent)
        case .goHome:
            activeTab = .dashboard
            dashboardCoordinator.navigateToRoot()
        case .goBack, .dismiss:
            activeCoordinator.handleVoiceIntent(intent)
        case .unknown:
            break
        }
    }

    // MARK: - Auth

    func showAuthFlow() {
        isShowingAuth = true
    }

    func authFlowComplete() {
        isShowingAuth = false
    }

    // MARK: - Private

    private var activeCoordinator: any CoordinatorProtocol {
        switch activeTab {
        case .dashboard:     return dashboardCoordinator
        case .watchlist:     return watchlistCoordinator
        case .search:        return searchCoordinator
        case .notifications: return dashboardCoordinator
        case .assistant:     return dashboardCoordinator
        }
    }

    private func observeNavigationStateManager() {
        NavigationStateManager.shared.$pendingRoute
            .compactMap { $0 }
            .sink { [weak self] route in
                guard let self else { return }
                switch route {
                case .stockDetail:
                    // Switch to dashboard tab first, then navigate
                    self.activeTab = .dashboard
                    // Brief delay allows NavigationStack to become active
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self.dashboardCoordinator.navigate(to: route)
                        NavigationStateManager.shared.clearAll()
                    }
                default:
                    self.activeCoordinator.navigate(to: route)
                    NavigationStateManager.shared.clearAll()
                }
            }
            .store(in: &cancellables)

        NavigationStateManager.shared.$pendingVoiceIntent
            .compactMap { $0 }
            .sink { [weak self] intent in
                self?.handleVoiceIntent(intent)
                NavigationStateManager.shared.clearAll()
            }
            .store(in: &cancellables)
    }
}
