//
//  NetworkError.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import Foundation

public enum NetworkError: Error, LocalizedError, Equatable {
    case invalidURL
    case missingAPIKey
    case invalidResponse
    case authError(statusCode: Int)      // 401, 403
    case clientError(statusCode: Int)    // 400-499 excluding auth
    case serverError(statusCode: Int)    // 500-599
    case rateLimitExceeded               // 429 Alpha Vantage specific
    case decodingError(String)           // String (not Error) for Equatable
    case emptyResponse                   // success but no usable data

    // MARK: - Retry / Auth helpers

    public var isRetryable: Bool {
        switch self {
        case .serverError, .rateLimitExceeded: return true
        default:                               return false
        }
    }

    public var requiresReauth: Bool {
        switch self {
        case .authError: return true
        default:         return false
        }
    }

    // MARK: - LocalizedError

    public var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "The request URL is malformed. Please check your configuration."
        case .missingAPIKey:
            return "Alpha Vantage API key is missing. Add it to your xcconfig file."
        case .invalidResponse:
            return "The server returned an unexpected response format."
        case .authError(let code):
            return "Authentication failed (HTTP \(code)). Check your API key."
        case .clientError(let code):
            return "Request error (HTTP \(code)). Please try again."
        case .serverError(let code):
            return "Server error (HTTP \(code)). Please try again later."
        case .rateLimitExceeded:
            return "API rate limit reached. Please wait before making another request."
        case .decodingError(let detail):
            return "Failed to parse server response: \(detail)"
        case .emptyResponse:
            return "No data was returned for this request."
        }
    }
}
