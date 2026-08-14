import Foundation
import Domain

public protocol SettingsViewModelProtocol: ObservableObject {
    var currentUser: AuthUser { get }
    func refresh()
    func signOut()
}

public final class SettingsViewModel: ObservableObject, SettingsViewModelProtocol {
    @Published public var currentUser: AuthUser

    private let getCurrentUserUseCase: any GetCurrentUserUseCaseProtocol
    private let signOutUseCase:        any SignOutUseCaseProtocol

    public init(
        getCurrentUserUseCase: any GetCurrentUserUseCaseProtocol,
        signOutUseCase:        any SignOutUseCaseProtocol
    ) {
        self.getCurrentUserUseCase = getCurrentUserUseCase
        self.signOutUseCase        = signOutUseCase
        self.currentUser           = getCurrentUserUseCase.execute()
    }

    @MainActor
    public func refresh() {
        currentUser = getCurrentUserUseCase.execute()
    }

    @MainActor
    public func signOut() {
        signOutUseCase.execute()
        currentUser = .anonymous
    }
}
