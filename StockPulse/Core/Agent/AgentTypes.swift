import Foundation

// MARK: - Input

struct AgentTask {
    let goal: String
    let tickers: [String]
    let maxSteps: Int
    let allowParallel: Bool

    init(goal: String, tickers: [String] = [], maxSteps: Int = 8, allowParallel: Bool = false) {
        self.goal = goal
        self.tickers = tickers
        self.maxSteps = maxSteps
        self.allowParallel = allowParallel
    }
}

// MARK: - Plan (GPT-4.1 mini output)

struct AgentPlan: Codable {
    let actions: [PlannedAction]

    struct PlannedAction: Codable {
        let toolName: String
        let parameters: [String: String]
        let reasoning: String
        let parallel: Bool

        enum CodingKeys: String, CodingKey {
            case toolName, parameters, reasoning, parallel
        }
    }
}

// MARK: - Execution

struct AgentStep: Codable {
    let toolName: String
    let parameters: [String: String]
    let result: String        // JSON string from tool handler
    let reasoning: String
    let timestamp: Date
    var error: String?
}

struct AgentContext {
    let goal: String
    var steps: [AgentStep] = []

    mutating func addStep(_ step: AgentStep) {
        steps.append(step)
    }

    // Serializes goal + all step results for GPT-4.1 mini reflect/synthesize calls
    func asPromptContext() -> String {
        var lines = ["Goal: \(goal)", ""]
        for (i, step) in steps.enumerated() {
            lines.append("Step \(i + 1) — \(step.toolName): \(step.reasoning)")
            lines.append("Result: \(step.result)")
            if let err = step.error { lines.append("Error: \(err)") }
            lines.append("")
        }
        return lines.joined(separator: "\n")
    }
}

// MARK: - Reflection

enum AgentDecision: String, Codable {
    case `continue`
    case done
}

struct AgentDecisionResponse: Codable {
    let decision: AgentDecision
}

// MARK: - Output

struct AgentResult {
    let steps: [AgentStep]
    let synthesis: String
}

// MARK: - Tool Schema (sent to GPT-4.1 mini for planning)

struct AgentToolSchema {
    let name: String
    let description: String
    let parametersDescription: String
}
