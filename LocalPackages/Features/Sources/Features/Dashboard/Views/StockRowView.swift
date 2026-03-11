//
//  StockRowView.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import SwiftUI
import Domain

struct StockRowView: View {
    let stock: Stock
    var onTap: (() -> Void)?

    @State private var didChange = false

    private var isPositive: Bool { stock.changePercent >= 0 }
    private var changeColor: Color { isPositive ? Color(.systemGreen) : Color(.systemRed) }

    var body: some View {
        Button {
            onTap?()
        } label: {
            HStack(spacing: 12) {
                // Leading: symbol + company
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

                // Trailing: price + change pill
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
                        .background(changeColor.opacity(0.15))
                        .foregroundStyle(changeColor)
                        .clipShape(Capsule())
                }
                .scaleEffect(didChange ? 1.04 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: didChange)
                .onChange(of: stock.currentPrice) {
                    didChange = true
                    Task {
                        try? await Task.sleep(nanoseconds: 300_000_000)
                        didChange = false
                    }
                }
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)

        Divider()
            .padding(.leading, 0)
    }
}

#Preview {
    VStack(spacing: 0) {
        StockRowView(stock: .mockAAPL)
        StockRowView(stock: .mockGOOGL)
    }
    .padding(.horizontal)
}
