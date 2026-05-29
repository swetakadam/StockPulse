import Foundation
import Domain
import OSLog

class AzureChatClient {

    private let logger = Logger(subsystem: "com.sweta.stockpulse", category: "Agent.ChatClient")

    // MARK: - Plan

    func plan(goal: String, tools: [AgentToolSchema]) async throws -> AgentPlan {
        let toolsDescription = tools.map {
            "- \($0.name): \($0.description). Parameters: \($0.parametersDescription)"
        }.joined(separator: "\n")

        let systemPrompt = """
        You are a stock research planner. Given a goal and tools, return a JSON research plan.

        Respond ONLY with valid JSON in this exact format:
        {
          "actions": [
            {
              "toolName": "<tool name>",
              "parameters": {"key": "value"},
              "reasoning": "<one sentence why>",
              "parallel": false
            }
          ]
        }

        Rules:
        - Use ONLY tool names from this list:
        \(toolsDescription)
        - For multi-ticker price comparisons, set "parallel": true
        - Maximum 8 actions total
        - Parameter values must be strings
        - For any "research", "analyze", "compare", or "deep dive" goal: ALWAYS include \
        fetch_10k_section for the "business" section of every company mentioned. \
        Do NOT plan only price fetches for research goals.
        - When comparing two companies, fetch 10-K business section for BOTH companies.
        """

        let content = try await sendMessage(
            system: systemPrompt,
            user: "Research goal: \(goal)",
            maxTokens: 1000,
            jsonMode: false
        )

        // Extract the JSON block from the response (model may wrap it in markdown)
        let jsonString = extractJSON(from: content) ?? content
        guard let data = jsonString.data(using: .utf8),
              let plan = try? JSONDecoder().decode(AgentPlan.self, from: data) else {
            logger.error("❌ Failed to parse AgentPlan from: \(content)")
            let ticker = goal.components(separatedBy: .whitespaces)
                .first { $0 == $0.uppercased() && $0.count <= 5 } ?? "AAPL"
            return AgentPlan(actions: [
                AgentPlan.PlannedAction(
                    toolName: "get_stock_price",
                    parameters: ["symbol": ticker],
                    reasoning: "Fetch current price",
                    parallel: false
                )
            ])
        }
        logger.debug("✅ Plan created with \(plan.actions.count) actions")
        return plan
    }

    // MARK: - Reflect

    func reflect(context: AgentContext) async throws -> AgentDecision {
        let system = """
        You are a research reflection agent. Review the research goal and completed steps.
        Decide if enough data has been gathered to synthesize a good answer.

        Respond with ONLY the word "continue" or "done" and nothing else.

        Choose "done" if: enough data has been gathered to give a meaningful, specific answer to the goal.
        Choose "continue" if: the goal asked for research or analysis but no filing/10-K data has been \
        fetched yet, OR multiple companies were requested and some have not been researched at all.
        Do NOT stop just because several steps have completed — stop when the data is actually sufficient.
        """

        let content: String
        do {
            content = try await sendMessage(
                system: system,
                user: context.asPromptContext(),
                maxTokens: 20,
                jsonMode: false
            )
        } catch {
            logger.warning("⚠️ reflect() failed, defaulting to done: \(error)")
            return .done
        }

        return content.lowercased().contains("continue") ? .continue : .done
    }

    // MARK: - Synthesize

    func synthesize(context: AgentContext) async throws -> String {
        // Use the pre-formatted synthesis when 10-K or price data is available.
        // parseSection() already produced 4-6 sentence summaries per section —
        // passing them through GPT-4.1 mini again only collapses them into 1-2 lines.
        let direct = context.buildSynthesis()
        if !direct.isEmpty { return direct }

        // Fallback: no structured data — ask the LLM to summarize what it knows
        let system = """
        You are a stock research analyst. Summarize the research data below in 4-6 sentences. \
        Include specific products, numbers, and facts. No disclaimers.
        """
        return try await sendMessage(
            system: system,
            user: context.asSynthesisContext(),
            maxTokens: 1500,
            jsonMode: false
        )
    }

    // MARK: - Parse 10-K Section

    func parseSection(rawHTML: String, section: TenKSection) async throws -> String {
        let system = """
        You are analyzing a plain-text excerpt from an SEC 10-K filing. \
        Summarize the "\(section.displayName)" section in 4-6 concise sentences. \
        Focus on key facts: business model, products, revenue drivers, risks, or financials — \
        whatever is most relevant to the section. Omit legal boilerplate and repetition.
        """

        // Strip HTML tags to plain text
        var plain = rawHTML.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
        plain = plain.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        // Find the section by its "ITEM N." anchor and extract up to 25 000 chars from there.
        // Without this, we'd just see the HTML head/CSS — none of the actual section content.
        let chunk: String
        if let range = plain.range(of: section.searchPattern, options: .caseInsensitive) {
            let remaining = plain.distance(from: range.lowerBound, to: plain.endIndex)
            let end = plain.index(range.lowerBound, offsetBy: min(25_000, remaining))
            chunk = String(plain[range.lowerBound..<end])
        } else {
            chunk = String(plain.prefix(25_000))
        }

        return try await sendMessage(
            system: system,
            user: chunk,
            maxTokens: 1500,
            jsonMode: false
        )
    }

    // MARK: - Helpers

    /// Extracts the first {...} JSON block from a response that may include markdown fences.
    private func extractJSON(from text: String) -> String? {
        guard let start = text.firstIndex(of: "{"),
              let end = text.lastIndex(of: "}") else { return nil }
        return String(text[start...end])
    }

    // MARK: - Core HTTP

    func sendMessage(system: String, user: String, maxTokens: Int, jsonMode: Bool) async throws -> String {
        guard let url = URL(string: "\(AzureChatConfig.endpoint)?api-version=\(AzureChatConfig.apiVersion)") else {
            throw AzureChatError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(AzureChatConfig.apiKey, forHTTPHeaderField: "api-key")

        var body: [String: Any] = [
            "messages": [
                ["role": "system", "content": system],
                ["role": "user",   "content": user]
            ],
            "max_tokens": maxTokens
        ]
        if jsonMode {
            body["response_format"] = ["type": "json_object"]
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw AzureChatError.invalidResponse
        }
        guard http.statusCode == 200 else {
            let msg = String(data: data, encoding: .utf8) ?? "unknown"
            logger.error("❌ Azure Chat \(http.statusCode): \(msg)")
            throw AzureChatError.serverError(statusCode: http.statusCode, message: msg)
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any] else {
            let raw = String(data: data, encoding: .utf8) ?? "unreadable"
            logger.error("❌ noResponse — raw body: \(raw.prefix(400))")
            throw AzureChatError.noResponse
        }
        // content can be null when finish_reason is content_filter or length
        guard let content = message["content"] as? String else {
            let finishReason = (choices.first?["finish_reason"] as? String) ?? "unknown"
            logger.error("❌ content null — finish_reason: \(finishReason)")
            throw AzureChatError.noResponse
        }

        return content
    }
}

// MARK: - Errors

enum AzureChatError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case noResponse
    case serverError(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:      return "Invalid Azure Chat API URL"
        case .invalidResponse: return "Invalid server response"
        case .noResponse:      return "No response from GPT-4.1 mini"
        case .serverError(let code, let msg): return "Server error (\(code)): \(msg)"
        }
    }
}
