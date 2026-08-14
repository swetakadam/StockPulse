import Foundation
@testable import Domain

final class MockAuthRepository: AuthRepositoryProtocol {
    var userToReturn: AuthUser = .anonymous
    var shouldThrow = false
    var thrownError: Error = AuthError.keychainFailure

    var signInCallCount = 0
    var getCurrentUserCallCount = 0
    var signOutCallCount = 0
    var lastUserId: String?

    func signInWithApple(userId: String, email: String?, displayName: String?) async throws -> AuthUser {
        signInCallCount += 1
        lastUserId = userId
        if shouldThrow { throw thrownError }
        return userToReturn
    }

    func getCurrentUser() -> AuthUser {
        getCurrentUserCallCount += 1
        return userToReturn
    }

    func signOut() {
        signOutCallCount += 1
        userToReturn = .anonymous
    }
}
