//
//  CompanyInfoView.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import SwiftUI
import Domain

struct CompanyInfoView: View {
    let overview: CompanyOverview?

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("About")
                .font(.headline)

            if let overview {
                HStack(spacing: 16) {
                    Label(overview.sector, systemImage: "building.2")
                    Label(overview.industry, systemImage: "tag")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

                Text(overview.description)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(isExpanded ? nil : 4)
                    .animation(.easeInOut, value: isExpanded)

                Button(isExpanded ? "Show Less" : "Read More") {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isExpanded.toggle()
                    }
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.blue)
            } else {
                // Skeleton while loading
                VStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.secondary.opacity(0.2))
                            .frame(height: 14)
                    }
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 24) {
        CompanyInfoView(overview: .mockAAPL)
        CompanyInfoView(overview: nil)
    }
    .padding()
}
