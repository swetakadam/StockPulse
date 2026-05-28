//
//  AgentOrchestrator.swift
//  StockPulse
//

import Foundation
import OSLog

// MARK: - Protocol (enables mock in tests)

protocol AgentToolRegistryProtocol: Sendable {
    var schemas: [AgentToolSchema] { get }
    func execute(_ action: AgentPlan.PlannedAction) async throws -> AgentStep
}

// MARK: - AgentOrchestrator

final class AgentOrchestrator {

    private let logger = Logger(subsystem: "com.sweta.stockpulse", category: "Agent.Orchestrator")
    private let chatClient: AzureChatClient
    private let toolRegistry: any AgentToolRegistryProtocol
    private let memory: AgentMemory

    // Called after each step completes — used by StockToolsManager to post UI progress bubbles
    var progressHandler: ((String) -> Void)?

    init(chatClient: AzureChatClient, toolRegistry: any AgentToolRegistryProtocol, memory: AgentMemory) {
        self.chatClient = chatClient
        self.toolRegistry = toolRegistry
        self.memory = memory
    }

    func execute(task: AgentTask) async throws -> AgentResult {
        logger.debug("🤖 Starting agent for goal: \(task.goal)")
        var context = AgentContext(goal: task.goal)

        let plan = try await chatClient.plan(goal: task.goal, tools: toolRegistry.schemas)
        logger.debug("📋 Plan: \(plan.actions.count) actions")

        var pendingParallel: [AgentPlan.PlannedAction] = []

        for action in plan.actions.prefix(task.maxSteps) {
            if action.parallel && task.allowParallel {
                pendingParallel.append(action)
                continue
            }

            // Flush any accumulated parallel steps before running sequential step
            if !pendingParallel.isEmpty {
                let parallelSteps = try await executeParallel(pendingParallel)
                parallelSteps.forEach { context.addStep($0) }
                pendingParallel = []
            }

            progressHandler?("⚙ \(action.reasoning)")
            let step = try await toolRegistry.execute(action)
            context.addStep(step)
            logger.debug("✅ Step done: \(action.toolName)")

            let decision = try await chatClient.reflect(context: context)
            if decision == .done {
                logger.debug("🏁 Reflect: done")
                break
            }
        }

        // Flush remaining parallel actions
        if !pendingParallel.isEmpty {
            let parallelSteps = try await executeParallel(pendingParallel)
            parallelSteps.forEach { context.addStep($0) }
        }

        progressHandler?("⚙ Synthesizing...")
        let synthesis = try await chatClient.synthesize(context: context)
        logger.debug("✅ Synthesis complete")

        let stepsJSON = (try? JSONEncoder().encode(context.steps)) ?? Data()
        let ticker = task.tickers.first ?? "MULTI"
        try? memory.store(ticker: ticker, goal: task.goal, synthesis: synthesis, stepsJSON: stepsJSON)

        return AgentResult(steps: context.steps, synthesis: synthesis)
    }

    private func executeParallel(_ actions: [AgentPlan.PlannedAction]) async throws -> [AgentStep] {
        let progressHandler = self.progressHandler
        let toolRegistry = self.toolRegistry
        return try await withThrowingTaskGroup(of: AgentStep.self) { group in
            for action in actions {
                group.addTask {
                    try await toolRegistry.execute(action)
                }
            }
            var steps: [AgentStep] = []
            for try await step in group {
                steps.append(step)
                progressHandler?("⚙ \(step.reasoning)")
            }
            return steps
        }
    }
}
