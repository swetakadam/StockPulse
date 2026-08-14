import Testing
import Foundation
@testable import Domain

@Suite("SignOutUseCase")
struct SignOutUseCaseTests {

    @Test("Calls repository signOut exactly once")
    func callsRepositorySignOut() {
        let repo = MockAuthRepository()
        let sut = SignOutUseCase(repository: repo)

        sut.execute()

        #expect(repo.signOutCallCount == 1)
    }

    @Test("User is anonymous after signOut")
    func userIsAnonymousAfterSignOut() {
        let repo = MockAuthRepository()
        repo.userToReturn = AuthUser(userId: "u1", email: nil, displayName: nil, isAnonymous: false)
        let sut = SignOutUseCase(repository: repo)

        sut.execute()

        #expect(repo.userToReturn == .anonymous)
    }
}
