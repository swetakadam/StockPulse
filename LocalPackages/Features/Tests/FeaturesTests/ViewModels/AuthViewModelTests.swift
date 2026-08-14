import Testing
import Foundation
import Domain
@testable import Features

@Suite("AuthViewModel")
@MainActor
struct AuthViewModelTests {

    func makeSUT() -> (AuthViewModel, MockSignInWithAppleUseCase) {
        let useCase = MockSignInWithAppleUseCase()
        let vm = AuthViewModel(signInWithAppleUseCase: useCase)
        return (vm, useCase)
    }

    @Test("Initial step is prompt")
    func initialStepIsPrompt() {
        let (vm, _) = makeSUT()
        #expect(vm.step == .prompt)
    }

    @Test("signInWithApple advances to success on valid credential")
    func signInWithAppleSucceeds() async {
        let (vm, useCase) = makeSUT()
        let expected = AuthUser(userId: "abc", email: "a@b.com", displayName: "AB", isAnonymous: false)
        useCase.userToReturn = expected

        await vm.signInWithApple(userId: "abc", email: "a@b.com", displayName: "AB")

        #expect(vm.step == .success(expected))
        #expect(useCase.executeCallCount == 1)
    }

    @Test("signInWithApple sets error step on use case failure")
    func signInWithAppleFails() async {
        let (vm, useCase) = makeSUT()
        useCase.shouldThrow = true

        await vm.signInWithApple(userId: "abc", email: nil, displayName: nil)

        if case .error = vm.step { } else {
            Issue.record("Expected .error, got \(vm.step)")
        }
    }

    @Test("reset returns step to prompt")
    func resetReturnsToPrompt() async {
        let (vm, _) = makeSUT()
        await vm.signInWithApple(userId: "abc", email: nil, displayName: nil)
        vm.reset()
        #expect(vm.step == .prompt)
    }

    @Test("setError sets error step with message")
    func setErrorSetsErrorStep() {
        let (vm, _) = makeSUT()
        vm.setError("Something went wrong")
        #expect(vm.step == .error("Something went wrong"))
    }
}
