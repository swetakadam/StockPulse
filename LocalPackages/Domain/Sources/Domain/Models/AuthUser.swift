// LocalPackages/Domain/Sources/Domain/Models/AuthUser.swift

import Foundation

public struct AuthUser: Equatable {
    public let userId: String
    public let email: String?
    public let displayName: String?
    public let isAnonymous: Bool

    public static let anonymous = AuthUser(
        userId: "", email: nil, displayName: nil, isAnonymous: true
    )

    public init(userId: String, email: String?, displayName: String?, isAnonymous: Bool) {
        self.userId = userId
        self.email = email
        self.displayName = displayName
        self.isAnonymous = isAnonymous
    }
}

public enum AuthError: Error, LocalizedError, Equatable {
    case keychainFailure
    case credentialRevoked

    public var errorDescription: String? {
        switch self {
        case .keychainFailure:   return "Unable to save credentials. Please try again."
        case .credentialRevoked: return "Your sign-in has been revoked. Please sign in again."
        }
    }
}
