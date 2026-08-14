public final class SignInWithAppleUseCase: SignInWithAppleUseCaseProtocol {
    private let repository: any AuthRepositoryProtocol

    public init(repository: any AuthRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(userId: String, email: String?, displayName: String?) async throws -> AuthUser {
        try await repository.signInWithApple(userId: userId, email: email, displayName: displayName)
    }
}
