//
//  AgentOrchestratorTests.swift
//  StockPulseTests
//

import Testing
import Foundation
import SwiftData
@testable import StockPulse
@testable import Domain

// MARK: - MockAzureChatClient

final class MockAzureChatClient: AzureChatClient {
    var planResult: AgentPlan
    var reflectResult: AgentDecision
    var synthesisResult: String

    init(
        plan: AgentPlan = AgentPlan(actions: [
            AgentPlan.PlannedAction(
                toolName: "get_stock_price",
                parameters: ["symbol": "NVDA"],
                reasoning: "Fetch NVDA price",
                parallel: false
            )
        ]),
        reflect: AgentDecision = .done,
        synthesis: String = "NVDA looks strong"
    ) {
        self.planResult = plan
        self.reflectResult = reflect
        self.synthesisResult = synthesis
    }

    override func plan(goal: String, tools: [AgentToolSchema]) async throws -> AgentPlan {
        planResult
    }

    override func reflect(context: AgentContext) async throws -> AgentDecision {
        reflectResult
    }

    override func synthesize(context: AgentContext) async throws -> String {
        synthesisResult
    }
}

// MARK: - MockAgentToolRegistry

final class MockAgentToolRegistry: AgentToolRegistryProtocol {
    var executeCallCount = 0
    var schemas: [AgentToolSchema] { [] }

    func execute(_ action: AgentPlan.PlannedAction) async throws -> AgentStep {
        executeCallCount += 1
        return AgentStep(
            toolName: action.toolName,
            parameters: action.parameters,
            result: "{\"price\": \"940\"}",
            reasoning: action.reasoning,
            timestamp: Date()
        )
    }
}

// MARK: - Tests

@Suite("AgentOrchestrator")
struct AgentOrchestratorTests {

    private func makeMemory() throws -> AgentMemory {
        let container = try ModelContainer(
            for: StoredAgentResult.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return AgentMemory(container: container)
    }

    @Test func singleStepExecutesTool() async throws {
        let registry = MockAgentToolRegistry()
        let orchestrator = AgentOrchestrator(
            chatClient: MockAzureChatClient(),
            toolRegistry: registry,
            memory: try makeMemory()
        )
        let result = try await orchestrator.execute(
            task: AgentTask(goal: "Research NVDA", tickers: ["NVDA"])
        )
        #expect(result.steps.count == 1)
        #expect(result.synthesis == "NVDA looks strong")
        #expect(registry.executeCallCount == 1)
    }

    @Test func synthesisStoredInMemory() async throws {
        let memory = try makeMemory()
        let orchestrator = AgentOrchestrator(
            chatClient: MockAzureChatClient(synthesis: "NVDA is strong"),
            toolRegistry: MockAgentToolRegistry(),
            memory: memory
        )
        _ = try await orchestrator.execute(
            task: AgentTask(goal: "Research NVDA", tickers: ["NVDA"])
        )
        let recalled = try? memory.recall(ticker: "NVDA")
        #expect(recalled?.synthesis == "NVDA is strong")
    }

    @Test func progressHandlerCalledPerStep() async throws {
        var messages: [String] = []
        let orchestrator = AgentOrchestrator(
            chatClient: MockAzureChatClient(),
            toolRegistry: MockAgentToolRegistry(),
            memory: try makeMemory()
        )
        orchestrator.progressHandler = { messages.append($0) }
        _ = try await orchestrator.execute(
            task: AgentTask(goal: "Research NVDA", tickers: ["NVDA"])
        )
        #expect(!messages.isEmpty)
        #expect(messages.last == "⚙ Synthesizing...")
    }
}
