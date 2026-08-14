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

            AssistantTab()
                .tabItem { Label("Assistant", systemImage: "waveform.circle.fill") }
                .tag(AppCoordinator.AppTab.assistant)

            SettingsTab(coordinator: coordinator.settingsCoordinator)
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(AppCoordinator.AppTab.settings)
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
                },
                onFilterTapped: {
                    coordinator.presentSheet(.stockFilter)
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
            .sheet(item: $coordinator.presentedSheet) { route in
                switch route {
                case .stockFilter:
                    StockFilterView(
                        onApply:   { _ in coordinator.dismissSheet() },
                        onDismiss: { coordinator.dismissSheet() }
                    )
                    .presentationDetents([.medium, .large], selection: $coordinator.activeDetent)
                    .presentationDragIndicator(.visible)
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
    @EnvironmentObject var appCoordinator: AppCoordinator
    @StateObject private var viewModel = Container.shared.watchlistViewModel()

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            WatchlistView(
                viewModel: viewModel,
                onStockTapped: { symbol in
                    coordinator.navigate(to: .stockDetail(symbol: symbol))
                },
                onSearchTapped: {
                    appCoordinator.activeTab = .search
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

// MARK: - Assistant Tab

private struct AssistantTab: View {
    @StateObject private var viewModel = Container.shared.aiAssistantViewModel()

    var body: some View {
        NavigationStack {
            AIAssistantView(viewModel: viewModel)
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

// MARK: - Settings Tab

private struct SettingsTab: View {
    @ObservedObject var coordinator: SettingsCoordinator
    @StateObject private var settingsVM = Container.shared.settingsViewModel()

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            SettingsView(
                viewModel: settingsVM,
                onSignInTapped: { coordinator.presentSheet(.authFlow) }
            )
        }
        .sheet(item: $coordinator.presentedSheet) { route in
            switch route {
            case .authFlow:
                let authVM = Container.shared.authViewModel()
                AuthSheetView(
                    viewModel: authVM,
                    onDetentChange: { coordinator.sheetCoordinator.setDetent($0) },
                    onDismiss: { coordinator.dismissSheet() }
                )
                .presentationDetents([.medium, .large], selection: $coordinator.sheetCoordinator.currentDetent)
                .presentationDragIndicator(.visible)
            default:
                EmptyView()
            }
        }
    }
}
