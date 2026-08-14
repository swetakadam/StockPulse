import Foundation
import Domain
@testable import Features

final class MockSignInWithAppleUseCase: SignInWithAppleUseCaseProtocol {
    var userToReturn = AuthUser(userId: "mock123", email: "mock@test.com", displayName: "Mock User", isAnonymous: false)
    var shouldThrow = false
    var executeCallCount = 0

    func execute(userId: String, email: String?, displayName: String?) async throws -> AuthUser {
        executeCallCount += 1
        if shouldThrow { throw AuthError.keychainFailure }
        return userToReturn
    }
}

final class MockGetCurrentUserUseCase: GetCurrentUserUseCaseProtocol {
    var userToReturn: AuthUser = .anonymous
    var executeCallCount = 0

    func execute() -> AuthUser {
        executeCallCount += 1
        return userToReturn
    }
}

final class MockSignOutUseCase: SignOutUseCaseProtocol {
    var executeCallCount = 0

    func execute() {
        executeCallCount += 1
    }
}
