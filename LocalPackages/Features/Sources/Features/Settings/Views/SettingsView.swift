import SwiftUI
import Domain

public struct SettingsView<ViewModel: SettingsViewModelProtocol>: View {
    @ObservedObject public var viewModel: ViewModel
    public var onSignInTapped: () -> Void

    public init(viewModel: ViewModel, onSignInTapped: @escaping () -> Void) {
        self.viewModel      = viewModel
        self.onSignInTapped = onSignInTapped
    }

    public var body: some View {
        List {
            accountSection
            Section("App") {
                LabeledContent(
                    "Version",
                    value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
                )
            }
        }
        .navigationTitle("Settings")
    }

    private var accountSection: some View {
        Section("Account") {
            if viewModel.currentUser.isAnonymous {
                Button(action: onSignInTapped) {
                    Label("Sign in with Apple", systemImage: "apple.logo")
                }
            } else {
                HStack(spacing: 12) {
                    Image(systemName: "person.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(viewModel.currentUser.displayName
                             ?? viewModel.currentUser.email
                             ?? "Apple User")
                            .font(.headline)
                        if viewModel.currentUser.displayName != nil,
                           let email = viewModel.currentUser.email {
                            Text(email)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Button(role: .destructive) {
                    viewModel.signOut()
                } label: {
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
        }
    }
}
