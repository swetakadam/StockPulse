import SwiftUI

public struct StockFilter: Equatable {
    public var sectors: Set<String>
    public var maxPrice: Double?

    public static let empty = StockFilter(sectors: [], maxPrice: nil)

    public init(sectors: Set<String> = [], maxPrice: Double? = nil) {
        self.sectors  = sectors
        self.maxPrice = maxPrice
    }
}

public struct StockFilterView: View {
    @State private var filter: StockFilter
    public var onApply: (StockFilter) -> Void
    public var onDismiss: () -> Void

    private let basicSectors    = ["Technology", "Finance", "Energy"]
    private let advancedSectors = ["Healthcare", "Consumer", "Industrials"]

    public init(
        initialFilter: StockFilter = .empty,
        onApply:   @escaping (StockFilter) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        _filter        = State(initialValue: initialFilter)
        self.onApply   = onApply
        self.onDismiss = onDismiss
    }

    public var body: some View {
        VStack(spacing: 0) {
            dragHandle
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    sectorSection(title: "Sector", sectors: basicSectors)
                    advancedSection
                    priceSection
                    applyButton
                        .padding(.bottom, 8)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
        }
    }

    private var dragHandle: some View {
        VStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.secondary.opacity(0.4))
                .frame(width: 36, height: 4)
                .padding(.top, 8)
            HStack {
                Text("Filter Stocks")
                    .font(.headline)
                Spacer()
                Button("Reset") { filter = .empty }
                    .font(.subheadline)
                    .foregroundStyle(.tint)
            }
            .padding(.horizontal, 20)
            Divider()
        }
    }

    private func sectorSection(title: String, sectors: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline).foregroundStyle(.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(sectors, id: \.self) { sector in
                        chipButton(sector)
                    }
                }
            }
        }
    }

    private var advancedSection: some View {
        sectorSection(title: "More Sectors  ↑ drag to reveal more", sectors: advancedSectors)
    }

    private func chipButton(_ sector: String) -> some View {
        let selected = filter.sectors.contains(sector)
        return Button {
            if selected { filter.sectors.remove(sector) } else { filter.sectors.insert(sector) }
        } label: {
            Text(sector)
                .font(.subheadline)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(selected ? Color.accentColor : Color.secondary.opacity(0.15))
                .foregroundStyle(selected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var priceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Max Price")
                .font(.subheadline).foregroundStyle(.secondary)
            Slider(
                value: Binding(
                    get: { filter.maxPrice ?? 1000 },
                    set: { filter.maxPrice = $0 < 1000 ? $0 : nil }
                ),
                in: 10...1000, step: 10
            )
            Text(filter.maxPrice.map { "Up to $\(Int($0))" } ?? "Any price")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    private var applyButton: some View {
        Button {
            onApply(filter)
            onDismiss()
        } label: {
            Text("Apply Filters")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}
