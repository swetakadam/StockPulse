public final class GetCurrentUserUseCase: GetCurrentUserUseCaseProtocol {
    private let repository: any AuthRepositoryProtocol

    public init(repository: any AuthRepositoryProtocol) {
        self.repository = repository
    }

    public func execute() -> AuthUser {
        repository.getCurrentUser()
    }
}
