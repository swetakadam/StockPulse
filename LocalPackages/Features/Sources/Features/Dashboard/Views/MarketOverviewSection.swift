//
//  MarketOverviewSection.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import SwiftUI

struct MarketOverviewSection: View {
    let indices: [MarketIndex]

    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: Date())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Markets")
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()
                Text(formattedTime)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(indices) { index in
                        MarketIndexCard(index: index)
                    }
                }
                .scrollTargetLayout()
                .padding(.horizontal)
            }
            .scrollTargetBehavior(.viewAligned)
        }
    }
}

#Preview {
    MarketOverviewSection(indices: MarketIndex.mockList)
        .padding(.vertical)
}
