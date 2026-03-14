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
                StatCell(title: "Market Cap", value: formatMarketCap(stock?.marketCap))
                StatCell(title: "P/E Ratio",  value: formatDouble(overview?.peRatio,    format: "%.1f"))
                StatCell(title: "EPS",        value: formatDouble(overview?.eps,         format: "$%.2f"))
                StatCell(title: "52W High",   value: formatDouble(overview?.week52High,  format: "$%.2f"))
                StatCell(title: "52W Low",    value: formatDouble(overview?.week52Low,   format: "$%.2f"))
                StatCell(title: "Volume",     value: formatVolume(stock?.volume))
                StatCell(title: "Div. Yield", value: formatDividend(overview?.dividendYield))
                StatCell(title: "Sector",     value: overview?.sector ?? "—")
            }
        }
    }

    // MARK: - Formatters

    private func formatMarketCap(_ value: Double?) -> String {
        guard let v = value, v > 0 else { return "—" }
        switch v {
        case 1_000_000_000_000...: return String(format: "$%.2fT", v / 1_000_000_000_000)
        case 1_000_000_000...:     return String(format: "$%.2fB", v / 1_000_000_000)
        default:                   return String(format: "$%.2fM", v / 1_000_000)
        }
    }

    private func formatDouble(_ value: Double?, format: String) -> String {
        guard let v = value, v > 0 else { return "—" }
        return String(format: format, v)
    }

    private func formatVolume(_ value: Int?) -> String {
        guard let v = value, v > 0 else { return "—" }
        switch v {
        case 1_000_000...: return String(format: "%.1fM", Double(v) / 1_000_000)
        case 1_000...:     return String(format: "%.1fK", Double(v) / 1_000)
        default:           return "\(v)"
        }
    }

    private func formatDividend(_ value: Double?) -> String {
        guard let v = value, v > 0 else { return "—" }
        return String(format: "%.2f%%", v * 100)
    }
}

// MARK: - StatCell

private struct StatCell: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
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
