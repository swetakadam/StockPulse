//
//  StockDetailView.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import SwiftUI
import Domain

public struct StockDetailView<ViewModel: StockDetailViewModelProtocol>: View {
    @StateObject private var viewModel: ViewModel
    private let symbol: String
    @State private var showError = false

    public init(viewModel: ViewModel, symbol: String) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.symbol = symbol
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                PriceHeaderView(stock: viewModel.stock)
                    .padding(.horizontal)

                PriceChartView(
                    pricePoints: viewModel.pricePoints,
                    selectedRange: viewModel.selectedRange,
                    onRangeSelected: { range in
                        Task { await viewModel.selectRange(range) }
                    }
                )
                .padding(.horizontal)

                KeyStatsView(stock: viewModel.stock, overview: viewModel.overview)
                    .padding(.horizontal)

                CompanyInfoView(overview: viewModel.overview)
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle(viewModel.stock?.companyName ?? symbol)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await viewModel.toggleWatchlist() }
                } label: {
                    Image(systemName: viewModel.isInWatchlist ? "star.fill" : "star")
                        .foregroundStyle(viewModel.isInWatchlist ? .yellow : .primary)
                }
            }
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.ultraThinMaterial)
            }
        }
        .task {
            await viewModel.loadDetail()
        }
        .onChange(of: viewModel.error) { _, newValue in
            showError = newValue != nil
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(viewModel.error ?? "")
        }
    }
}

// MARK: - Preview

#if DEBUG
private final class MockStockDetailViewModel: ObservableObject, StockDetailViewModelProtocol {
    let symbol: String = "AAPL"
    @Published var stock: Stock?           = .mockAAPL
    @Published var overview: CompanyOverview? = .mockAAPL
    @Published var pricePoints: [PricePoint]  = PricePoint.mockList
    @Published var selectedRange: TimeRange   = .oneMonth
    @Published var isLoading: Bool            = false
    @Published var error: String?             = nil
    @Published var isInWatchlist: Bool        = false
    func loadDetail()                    async {}
    func toggleWatchlist()               async {}
    func selectRange(_ range: TimeRange) async { selectedRange = range }
}
#endif

#Preview {
    NavigationStack {
        StockDetailView<MockStockDetailViewModel>(
            viewModel: MockStockDetailViewModel(),
            symbol: "AAPL"
        )
    }
}
