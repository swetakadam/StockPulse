import Testing
import Foundation
import Domain
@testable import Features

@Suite("SettingsViewModel")
@MainActor
struct SettingsViewModelTests {

    func makeSUT(
        user: AuthUser = .anonymous
    ) -> (SettingsViewModel, MockGetCurrentUserUseCase, MockSignOutUseCase) {
        let getCurrentUser = MockGetCurrentUserUseCase()
        getCurrentUser.userToReturn = user
        let signOut = MockSignOutUseCase()
        let vm = SettingsViewModel(
            getCurrentUserUseCase: getCurrentUser,
            signOutUseCase: signOut
        )
        return (vm, getCurrentUser, signOut)
    }

    @Test("Loads current user on init")
    func loadsCurrentUserOnInit() {
        let user = AuthUser(userId: "u1", email: "u@x.com", displayName: "U", isAnonymous: false)
        let (vm, getUser, _) = makeSUT(user: user)

        #expect(vm.currentUser == user)
        #expect(getUser.executeCallCount == 1)
    }

    @Test("Guest state is anonymous on init")
    func guestStateIsAnonymousOnInit() {
        let (vm, _, _) = makeSUT()
        #expect(vm.currentUser == .anonymous)
        #expect(vm.currentUser.isAnonymous)
    }

    @Test("signOut resets currentUser to anonymous")
    func signOutResetsToAnonymous() {
        let user = AuthUser(userId: "u1", email: nil, displayName: nil, isAnonymous: false)
        let (vm, _, signOut) = makeSUT(user: user)

        vm.signOut()

        #expect(vm.currentUser == .anonymous)
        #expect(signOut.executeCallCount == 1)
    }
}
