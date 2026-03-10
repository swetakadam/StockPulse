//
//  CoordinatorProtocol.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import Foundation

/// Base protocol every feature coordinator conforms to.
protocol CoordinatorProtocol: AnyObject {
    func navigate(to route: AppRoute)
    func navigateBack()
    func navigateToRoot()

    /// Returns true if the coordinator consumed the URL.
    @discardableResult
    func handleDeepLink(url: URL) -> Bool

    /// Returns true if the coordinator consumed the notification.
    @discardableResult
    func handleNotification(userInfo: [AnyHashable: Any]) -> Bool

    /// Returns true if the coordinator consumed the intent.
    @discardableResult
    func handleVoiceIntent(_ intent: VoiceIntent) -> Bool
}
