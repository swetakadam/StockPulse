//
//  RealtimeSessionManager.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import Foundation
import OSLog

/// Single responsibility: fetch ephemeral token from APIM.
/// Called once per session before WebRTC connection.
final class RealtimeSessionManager: ObservableObject {

    private let logger = Logger(
        subsystem: "com.sweta.stockpulse",
        category: "AI.Session"
    )

    @Published var sessionToken: String?
    @Published var isLoading = false
    @Published var errorMessage: String?

    @MainActor
    func fetchEphemeralToken() async {
        isLoading = true
        errorMessage = nil

        guard let url = URL(string: RealtimeConfig.sessionsURL) else {
            errorMessage = "Invalid sessions URL — check APIM_ENDPOINT in xcconfig"
            isLoading = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(
            RealtimeConfig.apimSubscriptionKey,
            forHTTPHeaderField: "Ocp-Apim-Subscription-Key"
        )
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": RealtimeConfig.deploymentName,
            "voice": RealtimeConfig.voice
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            if let http = response as? HTTPURLResponse {
                logger.debug("Session API status: \(http.statusCode)")
            }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let clientSecret = json["client_secret"] as? [String: Any],
               let tokenValue = clientSecret["value"] as? String {
                sessionToken = tokenValue
                logger.debug("✅ Ephemeral token received")
            } else {
                let raw = String(data: data, encoding: .utf8) ?? "unknown"
                errorMessage = "Failed to parse token"
                logger.error("❌ Raw response: \(raw)")
            }
        } catch {
            errorMessage = "Network error: \(error.localizedDescription)"
            logger.error("❌ Session error: \(error.localizedDescription)")
        }

        isLoading = false
    }
}
