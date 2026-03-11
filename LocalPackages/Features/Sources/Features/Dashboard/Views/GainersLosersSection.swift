//
//  GainersLosersSection.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import SwiftUI
import Domain

enum GainerLoserTab: String, CaseIterable {
    case gainers = "Gainers"
    case losers  = "Losers"
}

struct GainersLosersSection: View {
    let gainers: [Stock]
    let losers:  [Stock]
    var onStockTapped: (String) -> Void = { _ in }

    @State private var selectedTab: GainerLoserTab = .gainers

    private var displayedStocks: [Stock] {
        selectedTab == .gainers ? gainers : losers
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Market Movers")
                .font(.title3)
                .fontWeight(.semibold)

            Picker("", selection: $selectedTab) {
                ForEach(GainerLoserTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)

            VStack(spacing: 0) {
                ForEach(displayedStocks) { stock in
                    StockRowView(stock: stock) {
                        onStockTapped(stock.symbol)
                    }
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTab)
        }
        .padding(16)
        .glassCard()
        .padding(.horizontal)
    }
}

#Preview {
    GainersLosersSection(
        gainers: [Stock.mockAAPL, Stock.mockMSFT],
        losers:  [Stock.mockGOOGL, Stock.mockAMZN]
    )
    .padding(.vertical)
}
