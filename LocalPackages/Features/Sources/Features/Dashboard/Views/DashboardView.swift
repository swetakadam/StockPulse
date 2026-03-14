//
//  DashboardView.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import SwiftUI
import Domain

// MARK: - DashboardView

public struct DashboardView<ViewModel: DashboardViewModelProtocol>: View {
    @StateObject private var viewModel: ViewModel

    /// Navigation closures — wired by AppCoordinatorView in the main target.
    var onStockTapped:     (String) -> Void = { _ in }
    var onSeeAllWatchlist: () -> Void       = {}

    public init(
        viewModel: ViewModel,
        onStockTapped:     @escaping (String) -> Void = { _ in },
        onSeeAllWatchlist: @escaping () -> Void       = {}
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onStockTapped     = onStockTapped
        self.onSeeAllWatchlist = onSeeAllWatchlist
    }

    // MARK: - Body

    public var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMsg = viewModel.error {
                errorView(message: errorMsg)
            } else {
                contentView
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.isLoading)
        .safeAreaInset(edge: .top) { headerView }
        .task { await viewModel.loadDashboard() }
    }

    // MARK: - Content

    private var contentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                MarketOverviewSection(indices: viewModel.marketIndices)

                TrendingStocksSection(
                    stocks: viewModel.trendingStocks,
                    onStockTapped: onStockTapped
                )

                WatchlistPreviewSection(
                    stocks: viewModel.watchlistStocks,
                    onStockTapped: onStockTapped,
                    onSeeAllTapped: onSeeAllWatchlist
                )

                GainersLosersSection(
                    gainers: viewModel.topGainers,
                    losers:  viewModel.topLosers,
                    onStockTapped: onStockTapped
                )

                Color.clear.frame(height: 20) // bottom breathing room
            }
            .padding(.vertical, 16)
        }
        .refreshable { await viewModel.refreshDashboard() }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("StockPulse")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text(greeting)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(.regularMaterial)
    }

    // MARK: - Error

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Retry") {
                Task { await viewModel.loadDashboard() }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(24)
        .glassCard()
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        default:      return "Good Evening"
        }
    }
}

// MARK: - Preview

private final class MockDashboardViewModel: ObservableObject, DashboardViewModelProtocol {
    @Published var marketIndices:   [MarketIndex] = MarketIndex.mockList
    @Published var trendingStocks:  [Stock]       = Stock.mockList
    @Published var watchlistStocks: [Stock]       = Stock.mockList
    @Published var topGainers:      [Stock]       = [.mockAAPL, .mockMSFT]
    @Published var topLosers:       [Stock]       = [.mockGOOGL, .mockAMZN]
    @Published var isLoading:       Bool          = false
    @Published var error:           String?

    func loadDashboard()    async {}
    func refreshDashboard() async {}
}

#Preview {
    DashboardView(viewModel: MockDashboardViewModel())
}
