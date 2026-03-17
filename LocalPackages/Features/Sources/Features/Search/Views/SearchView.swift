//
//  SearchView.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import SwiftUI
import Domain

public struct SearchView<ViewModel: SearchViewModelProtocol>: View {
    @StateObject var viewModel: ViewModel
    var onStockTapped: (String) -> Void = { _ in }

    public init(
        viewModel: ViewModel,
        onStockTapped: @escaping (String) -> Void = { _ in }
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onStockTapped = onStockTapped
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // Empty query — show recent + trending
                if viewModel.query.isEmpty {
                    if !viewModel.recentSearches.isEmpty {
                        RecentSearchesView(
                            searches: viewModel.recentSearches,
                            onSearchTapped: { query in
                                viewModel.query = query
                                Task { await viewModel.search(query: query) }
                            },
                            onRemove: { viewModel.removeRecentSearch($0) },
                            onClearAll: { viewModel.clearRecentSearches() }
                        )
                    }

                    TrendingSearchesView(
                        symbols: viewModel.trendingSymbols,
                        onSymbolTapped: { symbol in
                            viewModel.query = symbol
                            Task { await viewModel.search(query: symbol) }
                        }
                    )
                }

                // Loading
                if viewModel.isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                            .padding()
                        Spacer()
                    }
                }

                // Error
                if let error = viewModel.error {
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .glassCard()
                        .padding(.horizontal)
                }

                // Results
                if !viewModel.results.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Results")
                            .font(.headline)
                            .padding(.horizontal)
                            .padding(.bottom, 8)

                        VStack(spacing: 0) {
                            ForEach(viewModel.results) { stock in
                                SearchResultRow(
                                    stock: stock,
                                    onTap: {
                                        onStockTapped(stock.symbol)
                                    },
                                    onAddToWatchlist: {
                                        Task {
                                            await viewModel.addToWatchlist(
                                                symbol: stock.symbol
                                            )
                                        }
                                    }
                                )
                                .accessibilityIdentifier("search_result_\(stock.symbol)")
                            }
                        }
                        .accessibilityIdentifier("search_results_list")
                        .padding(.horizontal)
                        .glassCard()
                        .padding(.horizontal)
                    }
                }

                Color.clear.frame(height: 20)
            }
            .padding(.vertical, 16)
        }
        .navigationTitle("Search")
        .searchable(
            text: $viewModel.query,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search stocks, ETFs..."
        )
        .onChange(of: viewModel.query) { _, newValue in
            Task { await viewModel.search(query: newValue) }
        }
    }
}

// MARK: - Preview Mock

private final class MockSearchViewModel: ObservableObject, SearchViewModelProtocol {
    @Published var query: String = ""
    @Published var results: [Stock] = [.mockAAPL, .mockGOOGL]
    @Published var recentSearches: [RecentSearch] = [
        RecentSearch(query: "AAPL"),
        RecentSearch(query: "Tesla")
    ]
    @Published var trendingSymbols = [
        "AAPL", "MSFT", "GOOGL", "TSLA",
        "NVDA", "META", "AMZN", "BRK.B"
    ]
    @Published var isLoading: Bool = false
    @Published var error: String? = nil

    func search(query: String) async {}
    func clearRecentSearches() { recentSearches = [] }
    func removeRecentSearch(_ q: String) {
        recentSearches.removeAll { $0.query == q }
    }
    func addToWatchlist(symbol: String) async {}
}

#Preview {
    NavigationStack {
        SearchView(viewModel: MockSearchViewModel())
    }
}
