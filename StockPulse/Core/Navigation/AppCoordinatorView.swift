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
            DashboardTab(coordinator: coordinator.dashboardCoordinator)
                .tabItem { Label("Home", systemImage: "chart.line.uptrend.xyaxis") }
                .tag(AppCoordinator.AppTab.dashboard)

            WatchlistTab(coordinator: coordinator.watchlistCoordinator)
                .tabItem { Label("Watchlist", systemImage: "star.fill") }
                .tag(AppCoordinator.AppTab.watchlist)

            SearchTab(coordinator: coordinator.searchCoordinator)
                .tabItem { Label("Search", systemImage: "magnifyingglass") }
                .tag(AppCoordinator.AppTab.search)

            NavigationStack {
                Text("Notifications")
            }
            .tabItem { Label("Notifications", systemImage: "bell.fill") }
            .tag(AppCoordinator.AppTab.notifications)
        }
        .fullScreenCover(isPresented: $coordinator.isShowingAuth) {
            Text("Auth Flow")
        }
        .onOpenURL { url in
            coordinator.handleUniversalLink(url: url)
        }
    }
}

// MARK: - Dashboard Tab
// Isolated view — only redraws when dashboardCoordinator changes
// @ObservedObject ensures path binding works without bubbling up

private struct DashboardTab: View {
    @ObservedObject var coordinator: DashboardCoordinator
    @StateObject private var viewModel = Container.shared.dashboardViewModel()

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            DashboardView(
                viewModel: viewModel,
                onStockTapped: { symbol in
                    coordinator.navigate(to: .stockDetail(symbol: symbol))
                },
                onSeeAllWatchlist: {
                    coordinator.navigate(to: .watchlist)
                }
            )
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .stockDetail(let symbol):
                    StockDetailView(
                        viewModel: Container.shared.stockDetailViewModel(),
                        symbol: symbol
                    )
                default:
                    EmptyView()
                }
            }
        }
    }
}

// MARK: - Watchlist Tab

private struct WatchlistTab: View {
    @ObservedObject var coordinator: WatchlistCoordinator

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            Text("Watchlist")
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .stockDetail(let symbol):
                        StockDetailView(
                            viewModel: Container.shared.stockDetailViewModel(),
                            symbol: symbol
                        )
                    default:
                        EmptyView()
                    }
                }
        }
    }
}

// MARK: - Search Tab

private struct SearchTab: View {
    @ObservedObject var coordinator: SearchCoordinator
    @StateObject private var viewModel = Container.shared.searchViewModel()

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            SearchView(
                viewModel: viewModel,
                onStockTapped: { symbol in
                    coordinator.navigate(to: .stockDetail(symbol: symbol))
                }
            )
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .stockDetail(let symbol):
                    StockDetailView(
                        viewModel: Container.shared.stockDetailViewModel(),
                        symbol: symbol
                    )
                default:
                    EmptyView()
                }
            }
        }
    }
}
