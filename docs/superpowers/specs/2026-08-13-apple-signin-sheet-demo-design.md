# Sign in with Apple + Sheet Demo Design

**Date:** 2026-08-13
**Status:** Approved

---

## Goal

Add Sign in with Apple wired through the full Clean Architecture stack (Domain → Data → Features → DI), replace the Notifications tab placeholder with a Settings tab, and demonstrate two sheet presentation patterns using the existing `SheetCoordinator` infrastructure.

Anonymous users can use the app freely. Auth is optional and triggered from Settings.

---

## Domain Layer

**New file: `Domain/Models/AuthUser.swift`**

```swift
public struct AuthUser: Equatable {
    public let userId: String
    public let email: String?
    public let displayName: String?
    public let isAnonymous: Bool

    public static let anonymous = AuthUser(
        userId: "", email: nil, displayName: nil, isAnonymous: true
    )
}
```

**New file: `Domain/Repositories/AuthRepositoryProtocol.swift`**

```swift
public protocol AuthRepositoryProtocol {
    func signInWithApple(userId: String, email: String?, displayName: String?) async throws -> AuthUser
    func getCurrentUser() -> AuthUser
    func signOut()
}
```

**New use case protocols + implementations** in `Domain/UseCases/Protocols/` and `Domain/UseCases/Implementations/`:

| Protocol | Implementation | Responsibility |
|---|---|---|
| `SignInWithAppleUseCaseProtocol` | `SignInWithAppleUseCase` | Delegates to repo, returns `AuthUser` |
| `GetCurrentUserUseCaseProtocol` | `GetCurrentUserUseCase` | Returns stored user or `.anonymous` |
| `SignOutUseCaseProtocol` | `SignOutUseCase` | Clears stored credentials via repo |

All implementations are pure Swift structs. Zero framework imports. Constructor-injected with `AuthRepositoryProtocol`.

---

## Data Layer

**New file: `Data/Persistence/KeychainStore.swift`**

A focused struct wrapping the `Security` framework to read/write a single string value by key. Not exposed outside the Data package. Used only by `AuthRepositoryImpl`.

```swift
struct KeychainStore {
    func save(_ value: String, forKey key: String)
    func read(forKey key: String) -> String?
    func delete(forKey key: String)
}
```

**New file: `Data/Repositories/AuthRepositoryImpl.swift`**

Implements `AuthRepositoryProtocol`:
- `signInWithApple`: saves `userId`, `email`, `displayName` to Keychain, returns a mapped `AuthUser`
- `getCurrentUser`: reads Keychain; returns `AuthUser.anonymous` if `userId` key is missing
- `signOut`: deletes all auth keys from Keychain

The `ASAuthorizationAppleIDCredential` fields (`user`, `email`, `fullName`) are passed in as plain strings — the `AuthenticationServices` import stays in the Features layer where the UI lives, not in Data.

---

## Features Layer

### Auth

**`Features/Auth/ViewModels/AuthViewModel.swift`**

```swift
enum AuthStep {
    case prompt
    case inProgress
    case success(AuthUser)
    case error(String)
}

protocol AuthViewModelProtocol: ObservableObject {
    var step: AuthStep { get }
    func signInWithApple(userId: String, email: String?, displayName: String?) async
}

final class AuthViewModel: ObservableObject, AuthViewModelProtocol {
    @Published var step: AuthStep = .prompt
    // constructor-injected SignInWithAppleUseCaseProtocol
}
```

**`Features/Auth/Views/AuthSheetView.swift`**

Multi-step sheet root view. Renders based on `step`:
- `.prompt` → `SignInWithAppleButton` (medium detent)
- `.inProgress` → `ProgressView` spinner (medium detent, non-interactive)
- `.success(user)` → confirmation with display name + Done button (large detent)
- `.error(message)` → error message + Retry button (medium detent)

Detent changes programmatically via `SheetCoordinator.setDetent()` as steps advance.

### Settings

**`Features/Settings/ViewModels/SettingsViewModel.swift`**

```swift
protocol SettingsViewModelProtocol: ObservableObject {
    var currentUser: AuthUser { get }
    func signOut()
}

final class SettingsViewModel: ObservableObject, SettingsViewModelProtocol {
    @Published var currentUser: AuthUser = .anonymous
    // constructor-injected GetCurrentUserUseCase + SignOutUseCase
    // loads currentUser on init
}
```

**`Features/Settings/Views/SettingsView.swift`**

- Signed-in state: avatar initial, display name or email, Sign Out button
- Guest state: "Guest" label, "Sign in with Apple" button that calls `onSignInTapped` closure
- `onSignInTapped` is passed in from the coordinator — keeps the view decoupled from navigation

---

## Sheet Demo

### Demo 1 — Multi-step Auth Sheet

Triggered from `SettingsView` via `SettingsCoordinator.presentSheet(.authFlow)`.

```
.authFlow sheet
  └─ AuthSheetView (SheetCoordinator manages internal state)
       ├─ .prompt      → medium detent
       ├─ .inProgress  → medium detent, non-draggable (grabberHidden)
       └─ .success     → large detent (expands automatically)
```

Showcases: programmatic detent change, multi-step state machine in a sheet, `SheetCoordinator.setDetent()`.

### Demo 2 — Multi-detent Stock Filter Sheet

Triggered from a Filter button in Dashboard or Search via `coordinator.presentSheet(.stockFilter)`.

```
.stockFilter sheet
  └─ StockFilterView
       ├─ starts at .medium (half screen — basic filters visible)
       └─ user drags up → .large (full height — advanced filters revealed)
```

Uses `presentationDetents([.medium, .large])` with a `$selectedDetent` binding wired to `SheetCoordinator.currentDetent`. No button needed — drag gesture drives the expansion.

`StockFilterView` is minimal — its purpose is demonstrating the sheet pattern, not a real filter system. It shows a few sector toggle chips (e.g. Tech, Finance, Energy) and a price range picker. It passes the selected state back via an `onApply: (StockFilter) -> Void` closure injected from the coordinator. `StockFilter` is a simple struct in the Features layer (not Domain — no business logic depends on it).

---

## Navigation

**`SettingsCoordinator`** — new coordinator mirroring `AuthCoordinator` shape:

```swift
final class SettingsCoordinator: ObservableObject, RouterProtocol {
    @Published var path = NavigationPath()
    @Published var presentedSheet: SheetRoute?
    var sheetCoordinator = SheetCoordinator()
}
```

**`AppCoordinatorView`** — replace the Notifications `NavigationStack` placeholder with a `SettingsTab` struct following the isolated tab pattern:

```swift
private struct SettingsTab: View {
    @ObservedObject var coordinator: SettingsCoordinator
    @StateObject private var viewModel = Container.shared.settingsViewModel()
    ...
}
```

**`AppCoordinator`** — add `var settingsCoordinator = SettingsCoordinator()` as a plain `var` (not `@Published`).

**`AppCoordinator.AppTab`** — rename `.notifications` to `.settings`. Update the `activeCoordinator` computed property: `case .settings: return settingsCoordinator` (previously `case .notifications: return dashboardCoordinator`).

---

## Dependency Injection

All registrations go in `AppContainer.swift`:

```swift
// Singletons — shared resources
var keychainStore: Factory<KeychainStore> {
    self { KeychainStore() }.singleton
}
var authRepository: Factory<AuthRepositoryProtocol> {
    self { AuthRepositoryImpl(keychain: self.keychainStore()) }.singleton
}

// Use cases — new instance per call
var signInWithAppleUseCase: Factory<SignInWithAppleUseCaseProtocol> {
    self { SignInWithAppleUseCase(repository: self.authRepository()) }
}
var getCurrentUserUseCase: Factory<GetCurrentUserUseCaseProtocol> {
    self { GetCurrentUserUseCase(repository: self.authRepository()) }
}
var signOutUseCase: Factory<SignOutUseCaseProtocol> {
    self { SignOutUseCase(repository: self.authRepository()) }
}

// ViewModels — new instance per screen
var authViewModel: Factory<AuthViewModel> {
    self { AuthViewModel(signInWithAppleUseCase: self.signInWithAppleUseCase()) }
}
var settingsViewModel: Factory<SettingsViewModel> {
    self { SettingsViewModel(
        getCurrentUserUseCase: self.getCurrentUserUseCase(),
        signOutUseCase: self.signOutUseCase()
    )}
}
```

`authRepository` and `keychainStore` are singletons — Keychain is a shared resource and auth state must be consistent across the app. Use cases and ViewModels are fresh instances per call/screen.

---

## XcodeGen

Every new `.swift` file requires `xcodegen generate` after creation. New files span three packages:

- `Domain/Sources/Domain/Models/AuthUser.swift`
- `Domain/Sources/Domain/Repositories/AuthRepositoryProtocol.swift`
- `Domain/Sources/Domain/UseCases/Protocols/` — 3 files
- `Domain/Sources/Domain/UseCases/Implementations/` — 3 files
- `Data/Sources/Data/Persistence/KeychainStore.swift`
- `Data/Sources/Data/Repositories/AuthRepositoryImpl.swift`
- `Features/Sources/Features/Auth/ViewModels/AuthViewModel.swift`
- `Features/Sources/Features/Auth/Views/AuthSheetView.swift`
- `Features/Sources/Features/Settings/ViewModels/SettingsViewModel.swift`
- `Features/Sources/Features/Settings/Views/SettingsView.swift`
- `StockPulse/Core/Navigation/SettingsCoordinator.swift`
- `StockPulse/Core/Features/StockFilter/StockFilterView.swift`

Run `xcodegen generate` once after all files are created, not after each file.

---

## Constraints & Non-Goals

- No backend — Apple user ID stored in Keychain only
- No iCloud sync of watchlist (future feature, `AgentMemory` pattern applies)
- No push notification permission request in Settings (placeholder tab is gone; notifications are future)
- `AuthenticationServices` import stays in Features only — never in Domain or Data
- Anonymous users have full app access — no feature is gated behind auth
