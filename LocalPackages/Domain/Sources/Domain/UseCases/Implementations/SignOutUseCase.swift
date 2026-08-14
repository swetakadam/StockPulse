public final class SignOutUseCase: SignOutUseCaseProtocol {
    private let repository: any AuthRepositoryProtocol

    public init(repository: any AuthRepositoryProtocol) {
        self.repository = repository
    }

    public func execute() {
        repository.signOut()
    }
}
