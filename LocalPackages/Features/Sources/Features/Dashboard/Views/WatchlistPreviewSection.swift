//
//  WatchlistPreviewSection.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import SwiftUI
import Domain

struct WatchlistPreviewSection: View {
    let stocks: [Stock]
    var onStockTapped: (String) -> Void = { _ in }
    var onSeeAllTapped: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("My Watchlist")
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()
                Button("See All", action: onSeeAllTapped)
                    .font(.subheadline)
                    .foregroundStyle(.tint)
            }

            if stocks.isEmpty {
                emptyState
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(stocks.prefix(5))) { stock in
                        StockRowView(stock: stock) {
                            onStockTapped(stock.symbol)
                        }
                    }
                }
            }
        }
        .padding(16)
        .glassCard()
        .padding(.horizontal)
    }

    private var emptyState: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "star.slash")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                Text("Add stocks to watchlist")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 24)
            Spacer()
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        WatchlistPreviewSection(stocks: Stock.mockList)
        WatchlistPreviewSection(stocks: [])
    }
    .padding(.vertical)
}
