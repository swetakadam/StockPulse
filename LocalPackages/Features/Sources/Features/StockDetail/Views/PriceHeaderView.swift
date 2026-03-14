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

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let stock {
                Text(stock.currentPrice, format: .currency(code: "USD"))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

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
        PriceHeaderView(stock: .mockAAPL)
        PriceHeaderView(stock: .mockGOOGL)
        PriceHeaderView(stock: nil)
    }
    .padding()
}
