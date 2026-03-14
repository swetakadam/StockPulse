//
//  PriceChartView.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import SwiftUI
import Charts
import Domain

struct PriceChartView: View {
    let pricePoints:     [PricePoint]
    let selectedRange:   TimeRange
    let onRangeSelected: (TimeRange) -> Void

    var body: some View {
        VStack(spacing: 16) {
            chartBody
            rangePicker
        }
    }

    @ViewBuilder
    private var chartBody: some View {
        if pricePoints.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)
                Text("Chart data requires premium API")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Real-time charts available with Finnhub premium")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 200)
        } else {
            Chart(pricePoints) { point in
                LineMark(
                    x: .value("Date",  point.date),
                    y: .value("Price", point.close)
                )
                .foregroundStyle(lineColor)
                .interpolationMethod(.catmullRom)

                AreaMark(
                    x: .value("Date",  point.date),
                    y: .value("Price", point.close)
                )
                .foregroundStyle(lineColor.opacity(0.08))
                .interpolationMethod(.catmullRom)
            }
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks(position: .trailing) { value in
                    AxisValueLabel {
                        if let price = value.as(Double.self) {
                            Text(price, format: .currency(code: "USD").precision(.fractionLength(0)))
                                .font(.caption2)
                        }
                    }
                }
            }
            .frame(height: 200)
        }
    }

    private var rangePicker: some View {
        HStack(spacing: 0) {
            ForEach(TimeRange.allCases) { range in
                Button(range.rawValue) {
                    onRangeSelected(range)
                }
                .buttonStyle(.plain)
                .font(.caption.weight(.semibold))
                .foregroundStyle(selectedRange == range ? Color.accentColor : Color.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    selectedRange == range
                        ? Color.accentColor.opacity(0.12)
                        : Color.clear,
                    in: RoundedRectangle(cornerRadius: 8)
                )
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var lineColor: Color {
        guard let first = pricePoints.first,
              let last  = pricePoints.last else { return .blue }
        return last.close >= first.close ? .green : .red
    }
}

#Preview {
    PriceChartView(
        pricePoints: PricePoint.mockList,
        selectedRange: .oneMonth,
        onRangeSelected: { _ in }
    )
    .padding()
}
