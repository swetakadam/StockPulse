//
//  WatchlistEmptyView.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import SwiftUI

struct WatchlistEmptyView: View {
    var onSearchTapped: () -> Void = {}

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "star.slash")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                Text("No Stocks Yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("Search for stocks and add them\nto your watchlist.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: onSearchTapped) {
                Label("Search Stocks", systemImage: "magnifyingglass")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding()
        .accessibilityIdentifier("watchlist_empty_state")
    }
}

#Preview {
    WatchlistEmptyView()
}
