//
//  RealtimeConfig.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import Foundation

/// All config read from Bundle via xcconfig → Info.plist.
/// Keys stored in Secrets.xcconfig (gitignored). Zero hardcoded values.
enum RealtimeConfig {

    static var apimEndpoint: String {
        Bundle.main.infoDictionary?["APIM_ENDPOINT"] as? String ?? ""
    }

    static var apimSubscriptionKey: String {
        Bundle.main.infoDictionary?["APIM_SUBSCRIPTION_KEY"] as? String ?? ""
    }

    /// WebRTC SDP exchange endpoint — stays direct (cannot go through APIM)
    static var webRTCEndpoint: String {
        Bundle.main.infoDictionary?["WEBRTC_ENDPOINT"] as? String ?? ""
    }

    static var deploymentName: String {
        Bundle.main.infoDictionary?["REALTIME_DEPLOYMENT"] as? String ?? ""
    }

    /// Voice for GPT responses — keep consistent across session and session.update.
    ///
    /// Supported values are: 'alloy', 'ash', 'ballad', 'coral', 'echo', 'sage', 'shimmer', 'verse', 'marin', and 'cedar'
    static let voice = "coral"

    /// Ephemeral token endpoint — goes through APIM gateway
    static var sessionsURL: String {
        "\(apimEndpoint)/realtime/openai/realtimeapi/sessions?api-version=2025-04-01-preview"
    }
}
