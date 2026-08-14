import Foundation
import Domain

public final class AuthRepositoryImpl: AuthRepositoryProtocol {
    private let keychain: KeychainStore

    private enum Keys {
        static let userId      = "auth.userId"
        static let email       = "auth.email"
        static let displayName = "auth.displayName"
    }

    public init() {
        self.keychain = KeychainStore()
    }

    init(keychain: KeychainStore) {
        self.keychain = keychain
    }

    public func signInWithApple(userId: String, email: String?, displayName: String?) async throws -> AuthUser {
        keychain.save(userId, forKey: Keys.userId)
        if let email       { keychain.save(email,       forKey: Keys.email) }
        if let displayName { keychain.save(displayName, forKey: Keys.displayName) }
        return AuthUser(userId: userId, email: email, displayName: displayName, isAnonymous: false)
    }

    public func getCurrentUser() -> AuthUser {
        guard let userId = keychain.read(forKey: Keys.userId), !userId.isEmpty else {
            return .anonymous
        }
        return AuthUser(
            userId:      userId,
            email:       keychain.read(forKey: Keys.email),
            displayName: keychain.read(forKey: Keys.displayName),
            isAnonymous: false
        )
    }

    public func signOut() {
        keychain.delete(forKey: Keys.userId)
        keychain.delete(forKey: Keys.email)
        keychain.delete(forKey: Keys.displayName)
    }
}
