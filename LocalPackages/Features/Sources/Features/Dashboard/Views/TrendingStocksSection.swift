//
//  TrendingStocksSection.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import SwiftUI
import Domain

struct TrendingStocksSection: View {
    let stocks: [Stock]
    var onStockTapped: (String) -> Void = { _ in }
    var onSeeAllTapped: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Trending")
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()
                Button("See All", action: onSeeAllTapped)
                    .font(.subheadline)
                    .foregroundStyle(.tint)
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(stocks) { stock in
                        TrendingStockCard(stock: stock)
                            .onTapGesture { onStockTapped(stock.symbol) }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - TrendingStockCard

private struct TrendingStockCard: View {
    let stock: Stock

    private var isPositive: Bool { stock.changePercent >= 0 }
    private var changeColor: Color { isPositive ? Color(.systemGreen) : Color(.systemRed) }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(stock.symbol)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.primary)

            Text(stock.companyName)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .frame(width: 120, alignment: .leading)

            Spacer(minLength: 4)

            Text(String(format: "$%.2f", stock.currentPrice))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)

            Text(String(format: "%+.2f%%", stock.changePercent))
                .font(.caption)
                .fontWeight(.semibold)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(changeColor.opacity(0.15))
                .foregroundStyle(changeColor)
                .clipShape(Capsule())
        }
        .padding(14)
        .frame(width: 148, height: 160)
        .glassCard()
    }
}

#Preview {
    TrendingStocksSection(stocks: Stock.mockList)
        .padding(.vertical)
}
