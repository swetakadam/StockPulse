//
//  TrendingSearchesView.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import SwiftUI

struct TrendingSearchesView: View {
    let symbols: [String]
    var onSymbolTapped: (String) -> Void = { _ in }

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Trending")
                .font(.headline)
                .padding(.horizontal)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(symbols, id: \.self) { symbol in
                    Button {
                        onSymbolTapped(symbol)
                    } label: {
                        Text(symbol)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .glassCard()
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }
}

#Preview {
    TrendingSearchesView(
        symbols: ["AAPL", "MSFT", "GOOGL", "TSLA", "NVDA", "META", "AMZN", "BRK.B"]
    )
    .padding(.vertical)
}
