//
//  APIClient.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import Foundation

// MARK: - Protocol

public protocol APIClientProtocol {
    func fetch<T: Decodable>(endpoint: APIEndpoint) async throws -> T
}

// MARK: - AlphaVantageClient

public final class AlphaVantageClient: APIClientProtocol {
    private let baseURL: String
    private let apiKey: String

    /// Reads credentials from Info.plist (populated via xcconfig).
    public init() throws {
        let info = Bundle.main.infoDictionary
        guard
            let key = info?["ALPHAVANTAGE_API_KEY"] as? String, !key.isEmpty
        else {
            throw NetworkError.missingAPIKey
        }
        guard
            let url = info?["ALPHAVANTAGE_BASE_URL"] as? String, !url.isEmpty
        else {
            throw NetworkError.missingAPIKey
        }
        self.apiKey = key
        self.baseURL = url
    }

    public func fetch<T: Decodable>(endpoint: APIEndpoint) async throws -> T {
        // 1. Build URL
        guard var components = URLComponents(string: baseURL) else {
            throw NetworkError.invalidURL
        }
        var items = endpoint.queryItems
        items.append(URLQueryItem(name: "apikey", value: apiKey))
        components.queryItems = items

        guard let url = components.url else {
            throw NetworkError.invalidURL
        }

        // 2. Execute request
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: URLRequest(url: url))
        } catch {
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
}
