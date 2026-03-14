//
//  FetchTimeSeriesUseCase.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import Foundation   // Calendar, Date

public final class FetchTimeSeriesUseCase: FetchTimeSeriesUseCaseProtocol {
    private let repository: StockRepositoryProtocol

    public init(repository: StockRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(symbol: String, range: TimeRange) async throws -> [PricePoint] {
        let points = try await repository.fetchTimeSeries(symbol: symbol)
        let cutoff = cutoffDate(for: range)
        return points.filter { $0.date >= cutoff }
    }

    private func cutoffDate(for range: TimeRange) -> Date {
        let calendar = Calendar.current
        let now = Date()
        switch range {
        case .oneWeek:     return calendar.date(byAdding: .weekOfYear, value: -1, to: now) ?? now
        case .oneMonth:    return calendar.date(byAdding: .month,      value: -1, to: now) ?? now
        case .threeMonths: return calendar.date(byAdding: .month,      value: -3, to: now) ?? now
        case .oneYear:     return calendar.date(byAdding: .year,       value: -1, to: now) ?? now
        }
    }
}
