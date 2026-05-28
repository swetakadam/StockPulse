//
//  AgentMemory.swift
//  StockPulse
//

import Foundation
import SwiftData

@Model
final class StoredAgentResult {
    var ticker: String
    var goal: String
    var synthesis: String
    var stepsJSON: Data
    var timestamp: Date

    init(ticker: String, goal: String, synthesis: String, stepsJSON: Data, timestamp: Date = Date()) {
        self.ticker = ticker
        self.goal = goal
        self.synthesis = synthesis
        self.stepsJSON = stepsJSON
        self.timestamp = timestamp
    }
}

final class AgentMemory {

    private let container: ModelContainer

    init(container: ModelContainer) {
        self.container = container
    }

    /// Persist a completed research result.
    func store(ticker: String, goal: String, synthesis: String, stepsJSON: Data) throws {
        let context = ModelContext(container)
        let result = StoredAgentResult(
            ticker: ticker,
            goal: goal,
            synthesis: synthesis,
            stepsJSON: stepsJSON
        )
        context.insert(result)
        try context.save()
    }

    /// Fetch the most recent result for a ticker, or nil if none.
    func recall(ticker: String) throws -> StoredAgentResult? {
        let context = ModelContext(container)
        var descriptor = FetchDescriptor<StoredAgentResult>(
            predicate: #Predicate { $0.ticker == ticker },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    /// Fetch the N most recent results across all tickers.
    func recentResults(limit: Int = 10) throws -> [StoredAgentResult] {
        let context = ModelContext(container)
        var descriptor = FetchDescriptor<StoredAgentResult>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return try context.fetch(descriptor)
    }
}
