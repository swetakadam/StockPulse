//
//  AppCoordinatorView.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import SwiftUI
import Factory
import Features

struct AppCoordinatorView: View {
    @EnvironmentObject var coordinator: AppCoordinator

    var body: some View {
        TabView(selection: $coordinator.activeTab) {
            NavigationStack(path: $coordinator.dashboardCoordinator.path) {
                DashboardView(
                    viewModel: Container.shared.dashboardViewModel(),
                    onStockTapped: { symbol in
                        coordinator.dashboardCoordinator.navigate(
                            to: .stockDetail(symbol: symbol)
                        )
                    },
                    onSeeAllWatchlist: {
                        coordinator.dashboardCoordinator.navigate(to: .watchlist)
                    }
                )
                .navigationDestination(for: AppRoute.self) { destinationView(for: $0) }
            }
            .tabItem { Label("Home",          systemImage: "chart.line.uptrend.xyaxis") }
            .tag(AppCoordinator.AppTab.dashboard)

            NavigationStack(path: $coordinator.watchlistCoordinator.path) {
                Text("Watchlist")
                    .navigationDestination(for: AppRoute.self) { destinationView(for: $0) }
            }
            .tabItem { Label("Watchlist",     systemImage: "star.fill") }
            .tag(AppCoordinator.AppTab.watchlist)

            NavigationStack(path: $coordinator.searchCoordinator.path) {
                Text("Search")
                    .navigationDestination(for: AppRoute.self) { destinationView(for: $0) }
            }
            .tabItem { Label("Search",        systemImage: "magnifyingglass") }
            .tag(AppCoordinator.AppTab.search)

            NavigationStack {
                Text("Notifications")
            }
            .tabItem { Label("Notifications", systemImage: "bell.fill") }
            .tag(AppCoordinator.AppTab.notifications)
        }
        .fullScreenCover(isPresented: $coordinator.isShowingAuth) {
            Text("Auth Flow")                           // replaced in Features phase
        }
        .onOpenURL { url in
            coordinator.handleUniversalLink(url: url)
        }
    }

    // MARK: - Destination builder (placeholder — replaced per feature)

    @ViewBuilder
    private func destinationView(for route: AppRoute) -> some View {
        switch route {
        case .dashboard:
            Text("Dashboard")
        case .stockDetail(let symbol):
            StockDetailView(viewModel: Container.shared.stockDetailViewModel(symbol), symbol: symbol)
        case .search:
            Text("Search")
        case .watchlist:
            Text("Watchlist")
        case .notifications:
            Text("Notifications")
        case .notification:
            Text("Notification Detail")
        }
    }
}
