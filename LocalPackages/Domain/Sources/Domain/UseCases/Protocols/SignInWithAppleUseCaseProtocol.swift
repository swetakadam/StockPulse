import Foundation

public protocol SignInWithAppleUseCaseProtocol {
    func execute(userId: String, email: String?, displayName: String?) async throws -> AuthUser
}
