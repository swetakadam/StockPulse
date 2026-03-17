//
//  PriceHeaderView.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import SwiftUI
import Domain

struct PriceHeaderView: View {
    let stock: Stock?
    var isInWatchlist: Bool = false
    var logoURL: String? = nil
    var onWatchlistToggle: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Logo + symbol/name row + watchlist star
            HStack(spacing: 12) {
                if let logoURL, let url = URL(string: logoURL) {
                    AsyncImage(url: url) { image in
                        image.resizable()
                             .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.secondary.opacity(0.2))
                    }
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(stock?.symbol ?? "")
                        .font(.title2)
                        .fontWeight(.bold)
                        .accessibilityIdentifier("stock_symbol_label")
                    Text(stock?.companyName ?? "")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    onWatchlistToggle()
                } label: {
                    Image(systemName: isInWatchlist ? "star.fill" : "star")
                        .font(.title2)
                        .foregroundStyle(isInWatchlist ? .yellow : .secondary)
                }
                .accessibilityIdentifier("watchlist_toggle_button")
            }

            // Price row
            if let stock {
                Text(stock.currentPrice, format: .currency(code: "USD"))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .accessibilityIdentifier("stock_price_label")

                HStack(spacing: 8) {
                    Text(changeText(stock.change))
                    Text(changePercentText(stock.changePercent))
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(stock.change >= 0 ? Color.green : Color.red)
            } else {
                // Skeleton while loading
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondary.opacity(0.25))
                    .frame(width: 180, height: 42)
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 120, height: 20)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: stock == nil)
    }

    private func changeText(_ change: Double) -> String {
        change >= 0
            ? String(format: "+%.2f", change)
            : String(format: "%.2f", change)
    }

    private func changePercentText(_ pct: Double) -> String {
        pct >= 0
            ? String(format: "(+%.2f%%)", pct)
            : String(format: "(%.2f%%)", pct)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 24) {
        PriceHeaderView(
            stock: .mockAAPL,
            isInWatchlist: true,
            logoURL: CompanyOverview.mockAAPL.logoURL
        ) {}
        PriceHeaderView(stock: .mockGOOGL) {}
        PriceHeaderView(stock: nil) {}
    }
    .padding()
}
