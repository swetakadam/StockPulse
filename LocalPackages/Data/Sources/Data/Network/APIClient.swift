//
//  APIClient.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import Foundation
import OSLog

// MARK: - Protocol

public protocol APIClientProtocol {
    func fetch<T: Decodable>(endpoint: APIEndpoint) async throws -> T
}

// MARK: - FinnhubClient

public final class FinnhubClient: APIClientProtocol {
    private let baseURL: String
    private let apiKey: String
    private let logger = Logger(subsystem: "com.sweta.stockpulse", category: "Network")

    /// Reads credentials from Info.plist (populated via xcconfig).
    public init(bundle: Bundle = .main) throws {
        let info = bundle.infoDictionary
        guard
            let key = info?["FINNHUB_API_KEY"] as? String, !key.isEmpty
        else {
            throw NetworkError.missingAPIKey
        }
        guard
            let url = info?["FINNHUB_BASE_URL"] as? String, !url.isEmpty
        else {
            throw NetworkError.missingAPIKey
        }
        self.apiKey  = key
        self.baseURL = url
    }

    public func fetch<T: Decodable>(endpoint: APIEndpoint) async throws -> T {
        // 1. Build URL — base path + endpoint path + query items + token
        guard var components = URLComponents(string: baseURL) else {
            throw NetworkError.invalidURL
        }
        components.path += endpoint.path
        var items = endpoint.queryItems
        items.append(URLQueryItem(name: "token", value: apiKey))
        components.queryItems = items

        guard let url = components.url else {
            throw NetworkError.invalidURL
        }

        let request = URLRequest(url: url)
        logAsCurl(request)

        // 2. Execute request
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            logger.error("❌ NETWORK ERROR: \(error.localizedDescription)")
            throw NetworkError.invalidResponse
        }

        // 3. Map HTTP status to NetworkError
        if let http = response as? HTTPURLResponse {
            switch http.statusCode {
            case 200...299: break
            case 401, 403:  throw NetworkError.authError(statusCode: http.statusCode)
            case 429:       throw NetworkError.rateLimitExceeded
            case 400...499: throw NetworkError.clientError(statusCode: http.statusCode)
            case 500...599: throw NetworkError.serverError(statusCode: http.statusCode)
            default:        throw NetworkError.invalidResponse
            }
            logger.debug("✅ RESPONSE \(http.statusCode): \(url.absoluteString)")
        }

        // 4. Decode
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch let error as DecodingError {
            throw NetworkError.decodingError(error.localizedDescription)
        } catch {
            throw NetworkError.decodingError(error.localizedDescription)
        }
    }

    private func logAsCurl(_ request: URLRequest) {
        guard let url = request.url else { return }
        let redactedURL = url.absoluteString
            .replacingOccurrences(of: apiKey, with: "[REDACTED]")
        var parts = ["curl -X \(request.httpMethod ?? "GET")"]
        request.allHTTPHeaderFields?.forEach { key, value in
            let safeValue = key.lowercased() == "authorization" ? "[REDACTED]" : value
            parts.append("-H '\(key): \(safeValue)'")
        }
        parts.append("'\(redactedURL)'")
        logger.debug("🌐 REQUEST\n\(parts.joined(separator: " \\\n  "))")
    }
}
