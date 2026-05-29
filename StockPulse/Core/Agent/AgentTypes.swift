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

    // Used by reflect() — raw JSON results so the model can reason about completeness
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

    // Builds the final spoken briefing directly from tool results without an extra LLM call.
    // parseSection() already produced a 4-6 sentence 10-K summary per section —
    // asking GPT-4.1 mini to re-synthesize it only collapses it into 1-2 generic sentences.
    func buildSynthesis() -> String {
        var filingBlocks: [String] = []
        var priceLines:   [String] = []

        for step in steps {
            guard step.error == nil,
                  let data = step.result.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  json["error"] == nil else { continue }

            switch step.toolName {
            case "fetch_10k_section":
                let content = json["content"] as? String ?? ""
                let ticker  = json["ticker"]  as? String ?? ""
                let section = json["section"] as? String ?? ""
                guard !content.isEmpty else { break }
                let label = filingBlocks.isEmpty && section.lowercased() == "business"
                    ? "" : "\(ticker) \(section): "
                filingBlocks.append("\(label)\(content)")

            case "get_stock_price":
                let sym    = json["symbol"]        as? String ?? ""
                let price  = json["price"]         as? String ?? "?"
                let change = json["change"]        as? String ?? "0"
                let pct    = json["changePercent"] as? String ?? "0%"
                let dir    = (Double(change) ?? 0) >= 0 ? "up" : "down"
                priceLines.append("\(sym) is trading at $\(price), \(dir) \(pct) today")

            default: break
            }
        }

        guard !filingBlocks.isEmpty || !priceLines.isEmpty else { return "" }

        var parts = filingBlocks
        if !priceLines.isEmpty {
            parts.append(priceLines.joined(separator: ". ") + ".")
        }
        return parts.joined(separator: " ")
    }

    // Used by synthesize() — extracts and formats data into readable sections
    // so the LLM sees clean source material, not JSON blobs
    func asSynthesisContext() -> String {
        var lines = ["Research goal: \(goal)", ""]
        var marketLines: [String] = []
        var filingBlocks: [String] = []

        for step in steps {
            guard step.error == nil,
                  let data = step.result.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  json["error"] == nil else { continue }

            switch step.toolName {
            case "get_stock_price":
                let sym    = json["symbol"]      as? String ?? ""
                let name   = json["companyName"] as? String ?? sym
                let price  = json["price"]       as? String ?? "?"
                let change = json["change"]      as? String ?? "0"
                let pct    = json["changePercent"] as? String ?? "0%"
                marketLines.append("• \(sym) (\(name)): $\(price)  \(change) (\(pct)) today")

            case "fetch_10k_section":
                let ticker  = json["ticker"]     as? String ?? ""
                let section = json["section"]    as? String ?? ""
                let fy      = json["fiscalYear"] as? String ?? ""
                let content = json["content"]    as? String ?? ""
                guard !content.isEmpty else { break }
                filingBlocks.append("--- \(ticker) 10-K | \(section) | FY\(fy) ---\n\(content)")

            default:
                break
            }
        }

        if !filingBlocks.isEmpty {
            lines.append("SEC 10-K FILING CONTENT:")
            lines.append(contentsOf: filingBlocks)
            lines.append("")
        }
        if !marketLines.isEmpty {
            lines.append("CURRENT MARKET DATA:")
            lines.append(contentsOf: marketLines)
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
