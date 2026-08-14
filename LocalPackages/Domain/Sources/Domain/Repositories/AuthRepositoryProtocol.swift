import Foundation

public protocol AuthRepositoryProtocol {
    func signInWithApple(userId: String, email: String?, displayName: String?) async throws -> AuthUser
    func getCurrentUser() -> AuthUser
    func signOut()
}
