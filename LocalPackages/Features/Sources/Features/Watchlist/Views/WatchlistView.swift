//
//  WatchlistView.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import SwiftUI
import Domain

public struct WatchlistView<ViewModel: WatchlistViewModelProtocol>: View {
    @StateObject var viewModel: ViewModel
    var onStockTapped:  (String) -> Void = { _ in }
    var onSearchTapped: () -> Void       = {}

    public init(
        viewModel: ViewModel,
        onStockTapped:  @escaping (String) -> Void = { _ in },
        onSearchTapped: @escaping () -> Void       = {}
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onStockTapped  = onStockTapped
        self.onSearchTapped = onSearchTapped
    }

    public var body: some View {
        Group {
            if viewModel.isLoading && viewModel.stocks.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.stocks.isEmpty {
                WatchlistEmptyView(onSearchTapped: onSearchTapped)
            } else {
                contentView
            }
        }
        .navigationTitle("Watchlist")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                sortMenu
            }
        }
        .task { await viewModel.loadWatchlist() }
    }

    // MARK: - Content

    private var contentView: some View {
        List {
            Section {
                WatchlistHeaderView(
                    totalValue: viewModel.totalValue,
                    stockCount: viewModel.stocks.count
                )
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            Section {
                ForEach(viewModel.sortedStocks) { stock in
                    WatchlistRowView(stock: stock) {
                        onStockTapped(stock.symbol)
                    }
                    .accessibilityIdentifier("watchlist_row_\(stock.symbol)")
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            Task { await viewModel.removeFromWatchlist(symbol: stock.symbol) }
                        } label: {
                            Label("Remove", systemImage: "trash")
                        }
                    }
                }
            } header: {
                Text("YOUR STOCKS")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .listStyle(.insetGrouped)
        .accessibilityIdentifier("watchlist_list")
        .refreshable { await viewModel.refreshWatchlist() }
    }

    // MARK: - Sort Menu

    private var sortMenu: some View {
        Menu {
            ForEach(WatchlistSortOption.allCases, id: \.self) { option in
                Button {
                    viewModel.sortOption = option
                } label: {
                    if viewModel.sortOption == option {
                        Label(option.rawValue, systemImage: "checkmark")
                    } else {
                        Text(option.rawValue)
                    }
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
                .accessibilityIdentifier("watchlist_sort_button")
        }
    }
}

// MARK: - Preview Mock

private final class MockWatchlistViewModel: ObservableObject, WatchlistViewModelProtocol {
    @Published var stocks:     [Stock]             = [.mockAAPL, .mockGOOGL]
    @Published var sortOption: WatchlistSortOption = .name
    @Published var isLoading:  Bool                = false
    @Published var error:      String?             = nil

    var totalValue:   Double  { stocks.reduce(0) { $0 + $1.currentPrice } }
    var sortedStocks: [Stock] { stocks }

    func loadWatchlist()    async {}
    func refreshWatchlist() async {}
    func removeFromWatchlist(symbol: String) async {
        stocks.removeAll { $0.symbol == symbol }
    }
}

#Preview {
    NavigationStack {
        WatchlistView(viewModel: MockWatchlistViewModel())
    }
}
