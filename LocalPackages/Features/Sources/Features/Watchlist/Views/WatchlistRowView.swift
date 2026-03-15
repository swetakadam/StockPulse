//
//  WatchlistRowView.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import SwiftUI
import Domain

struct WatchlistRowView: View {
    let stock: Stock
    var onTap: () -> Void = {}

    private var isPositive: Bool { stock.changePercent >= 0 }
    private var changeColor: Color { isPositive ? Color(.systemGreen) : Color(.systemRed) }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(stock.symbol)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    Text(stock.companyName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(String(format: "$%.2f", stock.currentPrice))
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)

                    Text(String(format: "%+.2f%%", stock.changePercent))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(changeColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    List {
        WatchlistRowView(stock: .mockAAPL)
        WatchlistRowView(stock: .mockGOOGL)
    }
}
