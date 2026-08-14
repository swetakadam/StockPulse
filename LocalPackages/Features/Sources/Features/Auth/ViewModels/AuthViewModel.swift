import Foundation
import Domain

public enum AuthStep: Equatable {
    case prompt
    case inProgress
    case success(AuthUser)
    case error(String)
}

public protocol AuthViewModelProtocol: ObservableObject {
    var step: AuthStep { get }
    func signInWithApple(userId: String, email: String?, displayName: String?) async
    func reset()
    func setError(_ message: String)
}

public final class AuthViewModel: ObservableObject, AuthViewModelProtocol {
    @Published public var step: AuthStep = .prompt

    private let signInWithAppleUseCase: any SignInWithAppleUseCaseProtocol

    public init(signInWithAppleUseCase: any SignInWithAppleUseCaseProtocol) {
        self.signInWithAppleUseCase = signInWithAppleUseCase
    }

    @MainActor
    public func signInWithApple(userId: String, email: String?, displayName: String?) async {
        step = .inProgress
        do {
            let user = try await signInWithAppleUseCase.execute(userId: userId, email: email, displayName: displayName)
            step = .success(user)
        } catch {
            step = .error(error.localizedDescription)
        }
    }

    @MainActor
    public func reset() {
        step = .prompt
    }

    @MainActor
    public func setError(_ message: String) {
        step = .error(message)
    }
}
