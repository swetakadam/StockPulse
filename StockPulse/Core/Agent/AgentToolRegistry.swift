import Foundation
import Domain
import OSLog

struct AgentTool {
    let name: String
    let description: String
    let parametersDescription: String
    let handler: ([String: String]) async throws -> String

    var schema: AgentToolSchema {
        AgentToolSchema(
            name: name,
            description: description,
            parametersDescription: parametersDescription
        )
    }
}

final class AgentToolRegistry {

    private let logger = Logger(subsystem: "com.sweta.stockpulse", category: "Agent.Registry")
    private let tools: [AgentTool]

    var schemas: [AgentToolSchema] { tools.map(\.schema) }

    init(
        fetchStockUseCase:          any FetchStockUseCaseProtocol,
        searchStocksUseCase:        any SearchStocksUseCaseProtocol,
        fetchWatchlistUseCase:      any FetchWatchlistUseCaseProtocol,
        addToWatchlistUseCase:      any AddToWatchlistUseCaseProtocol,
        removeFromWatchlistUseCase: any RemoveFromWatchlistUseCaseProtocol,
        fetchTenKSectionUseCase:    any FetchTenKSectionUseCaseProtocol
    ) {
        let uc1 = fetchStockUseCase
        let uc2 = searchStocksUseCase
        let uc3 = fetchWatchlistUseCase
        let uc4 = addToWatchlistUseCase
        let uc5 = removeFromWatchlistUseCase
        let uc6 = fetchTenKSectionUseCase

        tools = [
            AgentTool(
                name: "get_stock_price",
                description: "Get current price, change, and changePercent for a stock",
                parametersDescription: "symbol (string, required): ticker e.g. AAPL",
                handler: { params in
                    guard let symbol = params["symbol"], !symbol.isEmpty else {
                        return "{\"error\": \"symbol required\"}"
                    }
                    guard let stock = try? await uc1.execute(symbol: symbol.uppercased()) else {
                        return "{\"error\": \"not found: \(symbol)\"}"
                    }
                    return AgentToolRegistry.encode([
                        "symbol": stock.symbol,
                        "companyName": stock.companyName,
                        "price": String(format: "%.2f", stock.currentPrice),
                        "change": String(format: "%.2f", stock.change),
                        "changePercent": String(format: "%.2f%%", stock.changePercent)
                    ])
                }
            ),
            AgentTool(
                name: "search_stock",
                description: "Search stocks by company name or symbol",
                parametersDescription: "query (string, required): company name or symbol",
                handler: { params in
                    guard let query = params["query"], !query.isEmpty else {
                        return "{\"error\": \"query required\"}"
                    }
                    let results = (try? await uc2.execute(query: query)) ?? []
                    let top = results.prefix(5).map { ["symbol": $0.symbol, "name": $0.companyName] }
                    return AgentToolRegistry.encode(["results": top, "count": top.count])
                }
            ),
            AgentTool(
                name: "get_watchlist",
                description: "Get all stocks currently in the user's watchlist",
                parametersDescription: "none",
                handler: { _ in
                    let items = (try? await uc3.execute()) ?? []
                    let symbols = items.map { ["symbol": $0.symbol] }
                    return AgentToolRegistry.encode(["watchlist": symbols, "count": symbols.count])
                }
            ),
            AgentTool(
                name: "add_to_watchlist",
                description: "Add a stock to the user's watchlist",
                parametersDescription: "symbol (string, required): ticker e.g. AAPL",
                handler: { params in
                    guard let symbol = params["symbol"], !symbol.isEmpty else {
                        return "{\"error\": \"symbol required\"}"
                    }
                    do {
                        try await uc4.execute(symbol: symbol.uppercased())
                        return AgentToolRegistry.encode(["success": true, "symbol": symbol])
                    } catch {
                        return "{\"error\": \"\(error.localizedDescription)\"}"
                    }
                }
            ),
            AgentTool(
                name: "remove_from_watchlist",
                description: "Remove a stock from the user's watchlist",
                parametersDescription: "symbol (string, required): ticker e.g. AAPL",
                handler: { params in
                    guard let symbol = params["symbol"], !symbol.isEmpty else {
                        return "{\"error\": \"symbol required\"}"
                    }
                    do {
                        try await uc5.execute(symbol: symbol.uppercased())
                        return AgentToolRegistry.encode(["success": true, "symbol": symbol])
                    } catch {
                        return "{\"error\": \"\(error.localizedDescription)\"}"
                    }
                }
            ),
            AgentTool(
                name: "fetch_10k_section",
                description: "Fetch a specific section of a company's most recent 10-K SEC filing",
                parametersDescription: "ticker (string, required): e.g. NVDA. section (string, required): business | riskFactors | mdAndA | financialStatements",
                handler: { params in
                    guard let ticker = params["ticker"], !ticker.isEmpty else {
                        return "{\"error\": \"ticker required\"}"
                    }
                    let sectionStr = params["section"] ?? "business"
                    let section: TenKSection
                    switch sectionStr {
                    case "riskFactors":         section = .riskFactors
                    case "mdAndA":              section = .mdAndA
                    case "financialStatements": section = .financialStatements
                    default:                    section = .business
                    }
                    do {
                        let report = try await uc6.execute(
                            ticker: ticker.uppercased(),
                            section: section
                        )
                        let text = report.business ?? report.riskFactors ?? report.mdAndA ?? report.financialStatements ?? ""
                        return AgentToolRegistry.encode([
                            "ticker": report.ticker,
                            "section": section.displayName,
                            "fiscalYear": String(report.fiscalYear),
                            "content": String(text.prefix(3000))
                        ])
                    } catch {
                        return "{\"error\": \"\(error.localizedDescription)\"}"
                    }
                }
            )
        ]
    }

    func execute(_ action: AgentPlan.PlannedAction) async throws -> AgentStep {
        guard let tool = tools.first(where: { $0.name == action.toolName }) else {
            logger.warning("⚠️ Unknown tool: \(action.toolName)")
            return AgentStep(
                toolName: action.toolName,
                parameters: action.parameters,
                result: "{\"error\": \"unknown tool\"}",
                reasoning: action.reasoning,
                timestamp: Date(),
                error: "Unknown tool: \(action.toolName)"
            )
        }
        let result: String
        do {
            result = try await tool.handler(action.parameters)
            logger.debug("✅ Tool \(action.toolName) succeeded")
        } catch {
            logger.error("❌ Tool \(action.toolName) failed: \(error)")
            return AgentStep(
                toolName: action.toolName,
                parameters: action.parameters,
                result: "{\"error\": \"\(error.localizedDescription)\"}",
                reasoning: action.reasoning,
                timestamp: Date(),
                error: error.localizedDescription
            )
        }
        return AgentStep(
            toolName: action.toolName,
            parameters: action.parameters,
            result: result,
            reasoning: action.reasoning,
            timestamp: Date()
        )
    }

    private static func encode(_ dict: [String: Any]) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: dict),
              let str = String(data: data, encoding: .utf8) else {
            return "{\"error\": \"encoding failed\"}"
        }
        return str
    }
}
