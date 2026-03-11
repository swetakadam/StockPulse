//
//  MarketIndexCard.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import SwiftUI

struct MarketIndexCard: View {
    let index: MarketIndex

    @State private var isPulsing = false

    private var isPositive: Bool { index.change >= 0 }
    private var changeColor: Color { isPositive ? Color(.systemGreen) : Color(.systemRed) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(index.name)
                .font(.headline)
                .foregroundStyle(.primary)

            Text(String(format: "%.2f", index.value))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.primary)

            HStack(spacing: 4) {
                Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                    .font(.caption)
                Text(String(format: "%+.2f (%.2f%%)", index.change, index.changePercent))
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundStyle(changeColor)

            // Sparkline placeholder
            Rectangle()
                .fill(changeColor.opacity(0.25))
                .frame(height: 36)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .padding(16)
        .frame(width: 160)
        .glassCard()
        .scaleEffect(isPulsing ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPulsing)
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)
                            .repeatCount(1, autoreverses: true)) {
                isPulsing = true
            }
        }
    }
}

#Preview {
    HStack(spacing: 12) {
        MarketIndexCard(index: .mockSP500)
        MarketIndexCard(index: .mockNASDAQ)
    }
    .padding()
}
