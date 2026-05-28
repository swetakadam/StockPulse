//
//  AgentMemoryTests.swift
//  StockPulseTests
//

import Testing
import SwiftData
import Foundation
@testable import StockPulse

@Suite("AgentMemory")
struct AgentMemoryTests {

    private func makeMemory() throws -> AgentMemory {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: StoredAgentResult.self,
            configurations: config
        )
        return AgentMemory(container: container)
    }

    @Test func storeAndRecall() throws {
        let memory = try makeMemory()
        let stepsData = Data("[]".utf8)
        try memory.store(ticker: "AAPL", goal: "Research AAPL", synthesis: "AAPL looks strong", stepsJSON: stepsData)
        let result = try memory.recall(ticker: "AAPL")
        #expect(result != nil)
        #expect(result?.ticker == "AAPL")
        #expect(result?.synthesis == "AAPL looks strong")
    }

    @Test func recallReturnsNilForUnknownTicker() throws {
        let memory = try makeMemory()
        let result = try memory.recall(ticker: "UNKNOWN")
        #expect(result == nil)
    }

    @Test func recentResultsReturnsMostRecentFirst() throws {
        let memory = try makeMemory()
        let stepsData = Data("[]".utf8)
        // Insert older first
        try memory.store(ticker: "AAPL", goal: "Research AAPL old", synthesis: "old", stepsJSON: stepsData)
        // Small sleep to ensure different timestamps
        Thread.sleep(forTimeInterval: 0.01)
        try memory.store(ticker: "TSLA", goal: "Research TSLA", synthesis: "new", stepsJSON: stepsData)
        let results = try memory.recentResults(limit: 10)
        #expect(results.count == 2)
        #expect(results.first?.ticker == "TSLA")
    }
}
