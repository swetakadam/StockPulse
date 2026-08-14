import Testing
import Foundation
@testable import Domain

@Suite("GetCurrentUserUseCase")
struct GetCurrentUserUseCaseTests {

    @Test("Returns anonymous when no user is stored")
    func returnsAnonymousWhenNoUserStored() {
        let repo = MockAuthRepository()
        repo.userToReturn = .anonymous
        let sut = GetCurrentUserUseCase(repository: repo)

        let result = sut.execute()

        #expect(result == .anonymous)
        #expect(result.isAnonymous)
        #expect(repo.getCurrentUserCallCount == 1)
    }

    @Test("Returns stored user when signed in")
    func returnsStoredUserWhenSignedIn() {
        let repo = MockAuthRepository()
        let user = AuthUser(userId: "u1", email: "u@x.com", displayName: "U", isAnonymous: false)
        repo.userToReturn = user
        let sut = GetCurrentUserUseCase(repository: repo)

        let result = sut.execute()

        #expect(result == user)
        #expect(!result.isAnonymous)
    }
}
