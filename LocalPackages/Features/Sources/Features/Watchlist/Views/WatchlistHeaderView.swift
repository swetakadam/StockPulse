//
//  WatchlistHeaderView.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import SwiftUI

struct WatchlistHeaderView: View {
    let totalValue: Double
    let stockCount: Int

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Total Value")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(String(format: "$%.2f", totalValue))
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("Stocks")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(stockCount)")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

#Preview {
    WatchlistHeaderView(totalValue: 12450.75, stockCount: 5)
}
