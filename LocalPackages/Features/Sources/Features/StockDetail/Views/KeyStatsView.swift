//
//  KeyStatsView.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import SwiftUI
import Domain

struct KeyStatsView: View {
    let stock:    Stock?
    let overview: CompanyOverview?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Key Stats")
                .font(.headline)

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: 12
            ) {
                StatCell(label: "Open",   value: "—")
                StatCell(label: "Volume", value: formatVolume(stock?.volume))
                if let overview {
                    StatCell(label: "Market Cap", value: overview.marketCap)
                    StatCell(label: "P/E Ratio",  value: overview.peRatio)
                    StatCell(label: "EPS",        value: overview.eps)
                    StatCell(label: "52W High",   value: overview.weekHigh52)
                    StatCell(label: "52W Low",    value: overview.weekLow52)
                    StatCell(label: "Avg Volume", value: overview.avgVolume)
                    StatCell(label: "Sector",     value: overview.sector)
                }
            }
        }
    }

    // MARK: - Formatters

    private func formatVolume(_ value: Int?) -> String {
        guard let v = value, v > 0 else { return "—" }
        switch v {
        case 1_000_000...: return String(format: "%.1fM", Double(v) / 1_000_000)
        case 1_000...:     return String(format: "%.1fK", Double(v) / 1_000)
        default:           return "\(v)"
        }
    }
}

// MARK: - StatCell

private struct StatCell: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    KeyStatsView(stock: .mockAAPL, overview: .mockAAPL)
        .padding()
}
