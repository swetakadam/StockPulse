//
//  StockToolsManager.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import Foundation
import WebRTC
import Domain
import Features
import OSLog

/// Routes GPT tool calls to StockPulse Use Cases.
/// Plain class — owned by WebRTCManager.
/// Constructor injection — all use cases passed from AppContainer.
final class StockToolsManager {

    private let logger = Logger(
        subsystem: "com.sweta.stockpulse",
        category: "AI.Tools"
    )

    private let fetchStockUseCase:          any FetchStockUseCaseProtocol
    private let searchStocksUseCase:        any SearchStocksUseCaseProtocol
    private let fetchWatchlistUseCase:      any FetchWatchlistUseCaseProtocol
    private let addToWatchlistUseCase:      any AddToWatchlistUseCaseProtocol
    private let removeFromWatchlistUseCase: any RemoveFromWatchlistUseCaseProtocol

    weak var dataChannel: RTCDataChannel?

    init(
        fetchStockUseCase:          any FetchStockUseCaseProtocol,
        searchStocksUseCase:        any SearchStocksUseCaseProtocol,
        fetchWatchlistUseCase:      any FetchWatchlistUseCaseProtocol,
        addToWatchlistUseCase:      any AddToWatchlistUseCaseProtocol,
        removeFromWatchlistUseCase: any RemoveFromWatchlistUseCaseProtocol
    ) {
        self.fetchStockUseCase          = fetchStockUseCase
        self.searchStocksUseCase        = searchStocksUseCase
        self.fetchWatchlistUseCase      = fetchWatchlistUseCase
        self.addToWatchlistUseCase      = addToWatchlistUseCase
        self.removeFromWatchlistUseCase = removeFromWatchlistUseCase
    }

    // MARK: - Session Update

    /// Registers all 6 tools with Azure OpenAI when data channel opens.
    func sendSessionUpdate() {
        let event: [String: Any] = [
            "type": "session.update",
            "session": [
                "voice": RealtimeConfig.voice,
                "instructions": """
                    You are StockPulse Assistant — a focused stock market assistant.
                    You ONLY answer questions about stocks, markets, and the StockPulse app.
                    
                    YOU CAN HELP WITH:
                    - Stock prices, changes, and performance
                    - Searching for stocks by name or symbol
                    - Adding or removing stocks from watchlist
                    - Navigating to stock detail screens
                    - Explaining what stocks are in the watchlist
                    
                    YOU MUST REFUSE ANYTHING ELSE:
                    - If asked about weather, sports, politics, movies, cooking, 
                      travel, relationships, coding, or ANY non-stock topic,
                      respond with: "I'm StockPulse Assistant and I can only 
                      help with stock market questions. Try asking me about 
                      a stock price or your watchlist!"
                    - Never answer general knowledge questions
                    - Never engage in casual conversation beyond stock topics
                    - Never provide financial advice or investment recommendations
                    - Always say: "Past performance does not guarantee future results"
                      when discussing price changes
                    
                    TOOL RULES:
                    - Always use get_stock_price tool for price questions — never guess
                    - Always use search_stock tool when user mentions a company name
                    - Always confirm before adding or removing from watchlist
                    - After navigating to a stock, briefly confirm the action
                    
                    Keep all responses under 3 sentences. Be concise and helpful.
                """,
                "modalities": ["text", "audio"],
                "turn_detection": [
                    "type": "server_vad",
                    "threshold": NSNumber(value: 0.5),
                    "prefix_padding_ms": 300,
                    "silence_duration_ms": 600
                ],
                "tool_choice": "auto",
                "tools": toolDefinitions()
            ]
        ]
        sendDataChannelMessage(event)
        logger.debug("✅ Session update sent — 6 tools registered")
    }

    // MARK: - Tool Call Router

    func handleToolCall(name: String, callId: String, argsString: String) {
        let args = parseArgs(argsString)
        Task {
            let result: String
            switch name {
            case "get_stock_price":
                result = await fetchStockPrice(
                    symbol: (args["symbol"] as? String ?? "").uppercased()
                )
            case "search_stock":
                result = await searchStock(
                    query: args["query"] as? String ?? ""
                )
            case "add_to_watchlist":
                result = await addToWatchlist(
                    symbol: (args["symbol"] as? String ?? "").uppercased()
                )
            case "remove_from_watchlist":
                result = await removeFromWatchlist(
                    symbol: (args["symbol"] as? String ?? "").uppercased()
                )
            case "navigate_to_stock":
                result = navigateToStock(
                    symbol: (args["symbol"] as? String ?? "").uppercased()
                )
            case "get_watchlist":
                result = await getWatchlist()
            default:
                logger.warning("⚠️ Unknown tool: \(name)")
                result = encodeError("Unknown tool: \(name)")
            }
            sendToolResult(callId: callId, result: result)
        }
    }

    // MARK: - Tool Implementations

    private func fetchStockPrice(symbol: String) async -> String {
        guard !symbol.isEmpty else { return encodeError("Symbol required") }
        guard let stock = try? await fetchStockUseCase.execute(symbol: symbol) else {
            return encodeError("Could not fetch \(symbol)")
        }
        return encode([
            "symbol":        stock.symbol,
            "companyName":   stock.companyName,
            "price":         String(format: "%.2f", stock.currentPrice),
            "change":        String(format: "%.2f", stock.change),
            "changePercent": String(format: "%.2f%%", stock.changePercent)
        ])
    }

    private func searchStock(query: String) async -> String {
        guard !query.isEmpty else { return encodeError("Query required") }
        guard let results = try? await searchStocksUseCase.execute(query: query) else {
            return encodeError("Search failed for: \(query)")
        }
        let stocks = results.prefix(5).map { stock in
            ["symbol": stock.symbol, "companyName": stock.companyName]
        }
        return encode(["results": stocks, "count": stocks.count])
    }

    private func addToWatchlist(symbol: String) async -> String {
        guard !symbol.isEmpty else { return encodeError("Symbol required") }
        do {
            try await addToWatchlistUseCase.execute(symbol: symbol)
            NotificationCenter.default.post(
                name: .watchlistDidChange,
                object: nil,
                userInfo: ["symbol": symbol, "action": "added"]
            )
            logger.debug("✅ Added \(symbol) to watchlist")
            return encode(["success": true, "symbol": symbol,
                           "message": "Added \(symbol) to watchlist"])
        } catch {
            return encodeError("Failed to add \(symbol): \(error.localizedDescription)")
        }
    }

    private func removeFromWatchlist(symbol: String) async -> String {
        guard !symbol.isEmpty else { return encodeError("Symbol required") }
        do {
            try await removeFromWatchlistUseCase.execute(symbol: symbol)
            NotificationCenter.default.post(
                name: .watchlistDidChange,
                object: nil,
                userInfo: ["symbol": symbol, "action": "removed"]
            )
            logger.debug("✅ Removed \(symbol) from watchlist")
            return encode(["success": true, "symbol": symbol,
                           "message": "Removed \(symbol) from watchlist"])
        } catch {
            return encodeError("Failed to remove \(symbol): \(error.localizedDescription)")
        }
    }

    private func navigateToStock(symbol: String) -> String {
        guard !symbol.isEmpty else { return encodeError("Symbol required") }
        DispatchQueue.main.async {
            NavigationStateManager.shared.pendingRoute = .stockDetail(symbol: symbol)
        }
        logger.debug("✅ Navigation triggered: \(symbol)")
        return encode(["success": true, "symbol": symbol,
                       "message": "Navigating to \(symbol)"])
    }

    private func getWatchlist() async -> String {
        guard let items = try? await fetchWatchlistUseCase.execute() else {
            return encodeError("Could not fetch watchlist")
        }
        let symbols = items.map { ["symbol": $0.symbol] }
        return encode(["watchlist": symbols, "count": symbols.count])
    }

    // MARK: - Tool Definitions

    private func toolDefinitions() -> [[String: Any]] {
        [
            [
                "type": "function",
                "name": "get_stock_price",
                "description": "Get current price, change, and changePercent for a stock.",
                "parameters": [
                    "type": "object",
                    "properties": [
                        "symbol": ["type": "string",
                                   "description": "Ticker e.g. AAPL, TSLA"]
                    ],
                    "required": ["symbol"]
                ]
            ],
            [
                "type": "function",
                "name": "search_stock",
                "description": "Search stocks by company name or symbol.",
                "parameters": [
                    "type": "object",
                    "properties": [
                        "query": ["type": "string",
                                  "description": "Company name or symbol e.g. Apple"]
                    ],
                    "required": ["query"]
                ]
            ],
            [
                "type": "function",
                "name": "add_to_watchlist",
                "description": "Add a stock to the user watchlist.",
                "parameters": [
                    "type": "object",
                    "properties": [
                        "symbol": ["type": "string",
                                   "description": "Ticker symbol e.g. AAPL"]
                    ],
                    "required": ["symbol"]
                ]
            ],
            [
                "type": "function",
                "name": "remove_from_watchlist",
                "description": "Remove a stock from the user watchlist.",
                "parameters": [
                    "type": "object",
                    "properties": [
                        "symbol": ["type": "string",
                                   "description": "Ticker symbol e.g. AAPL"]
                    ],
                    "required": ["symbol"]
                ]
            ],
            [
                "type": "function",
                "name": "navigate_to_stock",
                "description": "Navigate to stock detail screen.",
                "parameters": [
                    "type": "object",
                    "properties": [
                        "symbol": ["type": "string",
                                   "description": "Ticker symbol e.g. AAPL"]
                    ],
                    "required": ["symbol"]
                ]
            ],
            [
                "type": "function",
                "name": "get_watchlist",
                "description": "Get all stocks in the user watchlist.",
                "parameters": [
                    "type": "object",
                    "properties": [:],
                    "required": []
                ]
            ]
        ]
    }

    // MARK: - Send Tool Result Back to GPT

    private func sendToolResult(callId: String, result: String) {
        sendDataChannelMessage([
            "type": "conversation.item.create",
            "item": [
                "type":    "function_call_output",
                "call_id": callId,
                "output":  result
            ]
        ])
        sendDataChannelMessage(["type": "response.create"])
        logger.debug("✅ Tool result sent for callId: \(callId)")
    }

    // MARK: - Data Channel Helper

    func sendDataChannelMessage(_ dict: [String: Any]) {
        guard let channel = dataChannel,
              channel.readyState == .open,
              let data = try? JSONSerialization.data(withJSONObject: dict)
        else {
            logger.warning("⚠️ Data channel not ready")
            return
        }
        channel.sendData(RTCDataBuffer(data: data, isBinary: false))
    }

    // MARK: - Helpers

    private func parseArgs(_ argsString: String) -> [String: Any] {
        guard let data = argsString.data(using: .utf8),
              let args = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return [:] }
        return args
    }

    private func encode(_ dict: [String: Any]) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: dict),
              let string = String(data: data, encoding: .utf8)
        else { return "{\"error\": \"Encoding failed\"}" }
        return string
    }

    private func encodeError(_ message: String) -> String {
        "{\"error\": \"\(message)\"}"
    }
}
