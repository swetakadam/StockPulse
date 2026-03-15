//
//  SearchResultRow.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import SwiftUI
import Domain

struct SearchResultRow: View {
    let stock: Stock
    var onTap: () -> Void = {}
    var onAddToWatchlist: () -> Void = {}

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Symbol circle avatar
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Text(String(stock.symbol.prefix(2)))
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(.tint)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(stock.symbol)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(stock.companyName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                // Add to watchlist
                Button {
                    onAddToWatchlist()
                } label: {
                    Image(systemName: "star")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(8)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)

        Divider()
    }
}

#Preview {
    VStack {
        SearchResultRow(stock: .mockAAPL)
        SearchResultRow(stock: .mockGOOGL)
    }
    .padding()
}
