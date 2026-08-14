import SwiftUI
import AuthenticationServices
import Domain

public struct AuthSheetView<ViewModel: AuthViewModelProtocol>: View {
    @ObservedObject public var viewModel: ViewModel
    public var onDetentChange: (PresentationDetent) -> Void
    public var onDismiss: () -> Void

    public init(
        viewModel: ViewModel,
        onDetentChange: @escaping (PresentationDetent) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.viewModel      = viewModel
        self.onDetentChange = onDetentChange
        self.onDismiss      = onDismiss
    }

    public var body: some View {
        VStack(spacing: 24) {
            switch viewModel.step {
            case .prompt:            promptView
            case .inProgress:        inProgressView
            case .success(let user): successView(user: user)
            case .error(let msg):    errorView(message: msg)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .onChange(of: viewModel.step) { _, newStep in
            switch newStep {
            case .success: onDetentChange(.large)
            default:       onDetentChange(.medium)
            }
        }
    }

    private var promptView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text("Sign in to StockPulse")
                .font(.title2).bold()
            Text("Sync your watchlist and preferences across devices.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            SignInWithAppleButton(.signIn, onRequest: configureRequest, onCompletion: handleCompletion)
                .signInWithAppleButtonStyle(.black)
                .frame(height: 50)
            Button("Continue without signing in") { onDismiss() }
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var inProgressView: some View {
        VStack(spacing: 16) {
            ProgressView().scaleEffect(1.5)
            Text("Signing in…")
                .foregroundStyle(.secondary)
        }
    }

    private func successView(user: AuthUser) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green)
            Text("Welcome\(user.displayName.map { ", \($0)" } ?? "")!")
                .font(.title2).bold()
            if let email = user.email {
                Text(email)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Button("Done") { onDismiss() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.red)
            Text("Sign in failed")
                .font(.title2).bold()
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Try Again") { viewModel.reset() }
                .buttonStyle(.borderedProminent)
        }
    }

    private func configureRequest(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
    }

    private func handleCompletion(_ result: Result<ASAuthorization, any Error>) {
        switch result {
        case .success(let auth):
            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential else { return }
            let parts = [credential.fullName?.givenName, credential.fullName?.familyName]
                .compactMap { $0 }
            let displayName = parts.isEmpty ? nil : parts.joined(separator: " ")
            Task {
                await viewModel.signInWithApple(
                    userId:      credential.user,
                    email:       credential.email,
                    displayName: displayName
                )
            }
        case .failure(let error as ASAuthorizationError) where error.code == .canceled:
            // User dismissed the system sheet — no state change needed.
            // Note: AKAuthenticationError -7003 (no Apple ID in Simulator Settings)
            // also surfaces as .canceled. Sign into an Apple ID in the Simulator's
            // Settings app to enable Sign in with Apple during development.
            break
        case .failure(let error):
            viewModel.setError(error.localizedDescription)
        }
    }
}
