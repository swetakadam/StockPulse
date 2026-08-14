import Testing
import Foundation
@testable import Domain

@Suite("SignInWithAppleUseCase")
struct SignInWithAppleUseCaseTests {

    @Test("Returns AuthUser on success")
    func returnsAuthUserOnSuccess() async throws {
        let repo = MockAuthRepository()
        let expected = AuthUser(userId: "abc123", email: "test@example.com", displayName: "Test User", isAnonymous: false)
        repo.userToReturn = expected
        let sut = SignInWithAppleUseCase(repository: repo)

        let result = try await sut.execute(userId: "abc123", email: "test@example.com", displayName: "Test User")

        #expect(result == expected)
        #expect(repo.signInCallCount == 1)
        #expect(repo.lastUserId == "abc123")
    }

    @Test("Propagates repository error")
    func propagatesRepositoryError() async throws {
        let repo = MockAuthRepository()
        repo.shouldThrow = true
        let sut = SignInWithAppleUseCase(repository: repo)

        await #expect(throws: AuthError.keychainFailure) {
            try await sut.execute(userId: "abc123", email: nil, displayName: nil)
        }
    }
}
