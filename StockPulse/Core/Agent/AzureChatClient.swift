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

        Choose "done" if: key data has been retrieved, or 3+ steps completed, or the goal is achievable with current data.
        Choose "continue" if: critical data is clearly missing.
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
        let system = """
        You are a stock research synthesizer. Based on all gathered data, write a concise spoken \
        summary for the user. 3-4 sentences maximum. Speak naturally. Focus on the most important insights.
        Past performance does not guarantee future results.
        """

        return try await sendMessage(
            system: system,
            user: context.asPromptContext(),
            maxTokens: 800,
            jsonMode: false
        )
    }

    // MARK: - Parse 10-K Section

    func parseSection(rawHTML: String, section: TenKSection) async throws -> String {
        let system = """
        Extract the text for "\(section.rawValue)" from this SEC 10-K filing HTML. \
        Remove all HTML tags, table formatting, and navigation elements. \
        Return only the plain prose content of that section. \
        Keep it under 1500 words. Focus on the most important points.
        """

        let truncated = rawHTML.count > 8000
            ? String(rawHTML.prefix(8000)) + "\n[truncated]"
            : rawHTML

        return try await sendMessage(
            system: system,
            user: truncated,
            maxTokens: 2000,
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
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String else {
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
