//
//  RecentSearchesView.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import SwiftUI
import Domain

struct RecentSearchesView: View {
    let searches: [RecentSearch]
    var onSearchTapped: (String) -> Void = { _ in }
    var onRemove: (String) -> Void = { _ in }
    var onClearAll: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent")
                    .font(.headline)
                Spacer()
                Button("Clear All", action: onClearAll)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 0) {
                ForEach(searches) { search in
                    HStack {
                        Image(systemName: "clock")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 20)

                        Button(search.query) {
                            onSearchTapped(search.query)
                        }
                        .font(.subheadline)
                        .foregroundStyle(.primary)

                        Spacer()

                        Button {
                            onRemove(search.query)
                        } label: {
                            Image(systemName: "xmark")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 10)

                    if search.id != searches.last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding(16)
        .glassCard()
        .padding(.horizontal)
    }
}

#Preview {
    RecentSearchesView(searches: [
        RecentSearch(query: "AAPL"),
        RecentSearch(query: "Tesla"),
        RecentSearch(query: "NVDA")
    ])
    .padding(.vertical)
}
