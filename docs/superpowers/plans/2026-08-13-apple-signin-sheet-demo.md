# Sign in with Apple + Sheet Demo Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire Sign in with Apple through the full Clean Architecture stack (Domain → Data → Features → DI) and demonstrate two sheet patterns — multi-step detent-changing auth sheet and multi-detent draggable stock filter sheet.

**Architecture:** Domain defines `AuthUser`, `AuthRepositoryProtocol`, and three use cases (pure Swift structs). Data implements the repository with `KeychainStore`. Features owns ViewModels (with protocols) and Views (generic over their ViewModel protocol). The app target wires DI via Factory and adds a Settings tab replacing the Notifications placeholder.

**Tech Stack:** Swift Testing (`@Test`/`@Suite`), Factory DI, AuthenticationServices (Features layer only), Security framework (Data layer only), SwiftUI sheets with `presentationDetents`.

---

## File Map

### Create — Domain
| File | Responsibility |
|---|---|
| `LocalPackages/Domain/Sources/Domain/Models/AuthUser.swift` | `AuthUser` struct + `AuthError` enum |
| `LocalPackages/Domain/Sources/Domain/Repositories/AuthRepositoryProtocol.swift` | Repository contract |
| `LocalPackages/Domain/Sources/Domain/UseCases/Protocols/SignInWithAppleUseCaseProtocol.swift` | Use case contract |
| `LocalPackages/Domain/Sources/Domain/UseCases/Protocols/GetCurrentUserUseCaseProtocol.swift` | Use case contract |
| `LocalPackages/Domain/Sources/Domain/UseCases/Protocols/SignOutUseCaseProtocol.swift` | Use case contract |
| `LocalPackages/Domain/Sources/Domain/UseCases/Implementations/SignInWithAppleUseCase.swift` | Thin delegation to repo |
| `LocalPackages/Domain/Sources/Domain/UseCases/Implementations/GetCurrentUserUseCase.swift` | Thin delegation to repo |
| `LocalPackages/Domain/Sources/Domain/UseCases/Implementations/SignOutUseCase.swift` | Thin delegation to repo |
| `LocalPackages/Domain/Tests/DomainTests/Mocks/MockAuthRepository.swift` | Test double |
| `LocalPackages/Domain/Tests/DomainTests/UseCases/SignInWithAppleUseCaseTests.swift` | Unit tests |
| `LocalPackages/Domain/Tests/DomainTests/UseCases/GetCurrentUserUseCaseTests.swift` | Unit tests |
| `LocalPackages/Domain/Tests/DomainTests/UseCases/SignOutUseCaseTests.swift` | Unit tests |

### Create — Data
| File | Responsibility |
|---|---|
| `LocalPackages/Data/Sources/Data/Persistence/KeychainStore.swift` | Keychain read/write/delete (Security framework) |
| `LocalPackages/Data/Sources/Data/Repositories/AuthRepositoryImpl.swift` | `AuthRepositoryProtocol` impl — stores userId/email/displayName in Keychain |

### Create — Features
| File | Responsibility |
|---|---|
| `LocalPackages/Features/Tests/FeaturesTests/Mocks/MockAuthUseCases.swift` | Test doubles for auth use cases |
| `LocalPackages/Features/Sources/Features/Auth/ViewModels/AuthViewModel.swift` | `AuthStep` state machine — prompt → inProgress → success/error |
| `LocalPackages/Features/Tests/FeaturesTests/ViewModels/AuthViewModelTests.swift` | Unit tests |
| `LocalPackages/Features/Sources/Features/Settings/ViewModels/SettingsViewModel.swift` | Loads current user, exposes signOut |
| `LocalPackages/Features/Tests/FeaturesTests/ViewModels/SettingsViewModelTests.swift` | Unit tests |
| `LocalPackages/Features/Sources/Features/Auth/Views/AuthSheetView.swift` | Multi-step sheet: prompt / inProgress / success / error |
| `LocalPackages/Features/Sources/Features/Settings/Views/SettingsView.swift` | Profile section (signed-in vs guest) + Sign In button |
| `LocalPackages/Features/Sources/Features/StockFilter/StockFilterView.swift` | `StockFilter` struct + draggable multi-detent filter sheet |

### Create — App Target
| File | Responsibility |
|---|---|
| `StockPulse/Core/Navigation/SettingsCoordinator.swift` | Owns `presentedSheet`, `sheetCoordinator` for auth flow |

### Modify — App Target
| File | Change |
|---|---|
| `StockPulse/Core/DI/AppContainer.swift` | Add `keychainStore`, `authRepository`, 3 use cases, `authViewModel`, `settingsViewModel` |
| `StockPulse/Core/Navigation/AppCoordinator.swift` | Rename `.notifications` → `.settings`, add `settingsCoordinator`, update `activeCoordinator` switch |
| `StockPulse/Core/Navigation/AppCoordinatorView.swift` | Replace Notifications tab with `SettingsTab`, add `.stockFilter` sheet to `DashboardTab` |

### Modify — Features
| File | Change |
|---|---|
| `LocalPackages/Features/Sources/Features/Dashboard/Views/DashboardView.swift` | Add `onFilterTapped: (() -> Void)?` parameter + toolbar filter button |

---

## Task 1: Domain — AuthUser model and AuthError

**Files:**
- Create: `LocalPackages/Domain/Sources/Domain/Models/AuthUser.swift`

- [ ] **Step 1: Create the file**

```swift
// LocalPackages/Domain/Sources/Domain/Models/AuthUser.swift

public struct AuthUser: Equatable {
    public let userId: String
    public let email: String?
    public let displayName: String?
    public let isAnonymous: Bool

    public static let anonymous = AuthUser(
        userId: "", email: nil, displayName: nil, isAnonymous: true
    )

    public init(userId: String, email: String?, displayName: String?, isAnonymous: Bool) {
        self.userId = userId
        self.email = email
        self.displayName = displayName
        self.isAnonymous = isAnonymous
    }
}

public enum AuthError: Error, LocalizedError, Equatable {
    case keychainFailure
    case credentialRevoked

    public var errorDescription: String? {
        switch self {
        case .keychainFailure:   return "Unable to save credentials. Please try again."
        case .credentialRevoked: return "Your sign-in has been revoked. Please sign in again."
        }
    }
}
```

- [ ] **Step 2: Verify it compiles**

```bash
swift build --package-path LocalPackages/Domain 2>&1 | tail -5
```
Expected: `Build complete!`

- [ ] **Step 3: Commit**

```bash
git add LocalPackages/Domain/Sources/Domain/Models/AuthUser.swift
git commit -m "feat(domain): add AuthUser model and AuthError"
```

---

## Task 2: Domain — AuthRepositoryProtocol

**Files:**
- Create: `LocalPackages/Domain/Sources/Domain/Repositories/AuthRepositoryProtocol.swift`

- [ ] **Step 1: Create the file**

```swift
// LocalPackages/Domain/Sources/Domain/Repositories/AuthRepositoryProtocol.swift

public protocol AuthRepositoryProtocol {
    func signInWithApple(userId: String, email: String?, displayName: String?) async throws -> AuthUser
    func getCurrentUser() -> AuthUser
    func signOut()
}
```

- [ ] **Step 2: Verify it compiles**

```bash
swift build --package-path LocalPackages/Domain 2>&1 | tail -5
```
Expected: `Build complete!`

- [ ] **Step 3: Commit**

```bash
git add LocalPackages/Domain/Sources/Domain/Repositories/AuthRepositoryProtocol.swift
git commit -m "feat(domain): add AuthRepositoryProtocol"
```

---

## Task 3: Domain — Use case protocols

**Files:**
- Create: `LocalPackages/Domain/Sources/Domain/UseCases/Protocols/SignInWithAppleUseCaseProtocol.swift`
- Create: `LocalPackages/Domain/Sources/Domain/UseCases/Protocols/GetCurrentUserUseCaseProtocol.swift`
- Create: `LocalPackages/Domain/Sources/Domain/UseCases/Protocols/SignOutUseCaseProtocol.swift`

- [ ] **Step 1: Create SignInWithAppleUseCaseProtocol**

```swift
// LocalPackages/Domain/Sources/Domain/UseCases/Protocols/SignInWithAppleUseCaseProtocol.swift

public protocol SignInWithAppleUseCaseProtocol {
    func execute(userId: String, email: String?, displayName: String?) async throws -> AuthUser
}
```

- [ ] **Step 2: Create GetCurrentUserUseCaseProtocol**

```swift
// LocalPackages/Domain/Sources/Domain/UseCases/Protocols/GetCurrentUserUseCaseProtocol.swift

public protocol GetCurrentUserUseCaseProtocol {
    func execute() -> AuthUser
}
```

- [ ] **Step 3: Create SignOutUseCaseProtocol**

```swift
// LocalPackages/Domain/Sources/Domain/UseCases/Protocols/SignOutUseCaseProtocol.swift

public protocol SignOutUseCaseProtocol {
    func execute()
}
```

- [ ] **Step 4: Verify compile**

```bash
swift build --package-path LocalPackages/Domain 2>&1 | tail -5
```
Expected: `Build complete!`

- [ ] **Step 5: Commit**

```bash
git add LocalPackages/Domain/Sources/Domain/UseCases/Protocols/
git commit -m "feat(domain): add auth use case protocols"
```

---

## Task 4: Domain — SignInWithAppleUseCase (TDD)

**Files:**
- Create: `LocalPackages/Domain/Tests/DomainTests/Mocks/MockAuthRepository.swift`
- Create: `LocalPackages/Domain/Tests/DomainTests/UseCases/SignInWithAppleUseCaseTests.swift`
- Create: `LocalPackages/Domain/Sources/Domain/UseCases/Implementations/SignInWithAppleUseCase.swift`

- [ ] **Step 1: Create MockAuthRepository**

```swift
// LocalPackages/Domain/Tests/DomainTests/Mocks/MockAuthRepository.swift
import Foundation
@testable import Domain

final class MockAuthRepository: AuthRepositoryProtocol {
    var userToReturn: AuthUser = .anonymous
    var shouldThrow = false
    var thrownError: Error = AuthError.keychainFailure

    var signInCallCount = 0
    var getCurrentUserCallCount = 0
    var signOutCallCount = 0
    var lastUserId: String?

    func signInWithApple(userId: String, email: String?, displayName: String?) async throws -> AuthUser {
        signInCallCount += 1
        lastUserId = userId
        if shouldThrow { throw thrownError }
        return userToReturn
    }

    func getCurrentUser() -> AuthUser {
        getCurrentUserCallCount += 1
        return userToReturn
    }

    func signOut() {
        signOutCallCount += 1
        userToReturn = .anonymous
    }
}
```

- [ ] **Step 2: Write the failing test**

```swift
// LocalPackages/Domain/Tests/DomainTests/UseCases/SignInWithAppleUseCaseTests.swift
import Testing
import Foundation
@testable import Domain

@Suite("SignInWithAppleUseCase")
struct SignInWithAppleUseCaseTests {

    @Test("Returns AuthUser on success")
    func returnsAuthUserOnSuccess() async throws {
        let repo = MockAuthRepository()
        let expected = AuthUser(userId: "abc123", email: "test@example.com", displayName: "Test User", isAnonymous: false)
        repo.userToReturn = expected
        let sut = SignInWithAppleUseCase(repository: repo)

        let result = try await sut.execute(userId: "abc123", email: "test@example.com", displayName: "Test User")

        #expect(result == expected)
        #expect(repo.signInCallCount == 1)
        #expect(repo.lastUserId == "abc123")
    }

    @Test("Propagates repository error")
    func propagatesRepositoryError() async throws {
        let repo = MockAuthRepository()
        repo.shouldThrow = true
        let sut = SignInWithAppleUseCase(repository: repo)

        await #expect(throws: AuthError.keychainFailure) {
            try await sut.execute(userId: "abc123", email: nil, displayName: nil)
        }
    }
}
```

- [ ] **Step 3: Run test — expect FAIL (type not found)**

```bash
swift test --package-path LocalPackages/Domain --filter SignInWithAppleUseCaseTests 2>&1 | tail -10
```
Expected: error — `cannot find type 'SignInWithAppleUseCase'`

- [ ] **Step 4: Implement SignInWithAppleUseCase**

```swift
// LocalPackages/Domain/Sources/Domain/UseCases/Implementations/SignInWithAppleUseCase.swift

public final class SignInWithAppleUseCase: SignInWithAppleUseCaseProtocol {
    private let repository: any AuthRepositoryProtocol

    public init(repository: any AuthRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(userId: String, email: String?, displayName: String?) async throws -> AuthUser {
        try await repository.signInWithApple(userId: userId, email: email, displayName: displayName)
    }
}
```

- [ ] **Step 5: Run test — expect PASS**

```bash
swift test --package-path LocalPackages/Domain --filter SignInWithAppleUseCaseTests 2>&1 | tail -10
```
Expected: `Test run with 2 tests passed`

- [ ] **Step 6: Commit**

```bash
git add LocalPackages/Domain/Tests/DomainTests/Mocks/MockAuthRepository.swift \
        LocalPackages/Domain/Tests/DomainTests/UseCases/SignInWithAppleUseCaseTests.swift \
        LocalPackages/Domain/Sources/Domain/UseCases/Implementations/SignInWithAppleUseCase.swift
git commit -m "feat(domain): add SignInWithAppleUseCase with tests"
```

---

## Task 5: Domain — GetCurrentUserUseCase (TDD)

**Files:**
- Create: `LocalPackages/Domain/Tests/DomainTests/UseCases/GetCurrentUserUseCaseTests.swift`
- Create: `LocalPackages/Domain/Sources/Domain/UseCases/Implementations/GetCurrentUserUseCase.swift`

- [ ] **Step 1: Write the failing test**

```swift
// LocalPackages/Domain/Tests/DomainTests/UseCases/GetCurrentUserUseCaseTests.swift
import Testing
import Foundation
@testable import Domain

@Suite("GetCurrentUserUseCase")
struct GetCurrentUserUseCaseTests {

    @Test("Returns anonymous when no user is stored")
    func returnsAnonymousWhenNoUserStored() {
        let repo = MockAuthRepository()
        repo.userToReturn = .anonymous
        let sut = GetCurrentUserUseCase(repository: repo)

        let result = sut.execute()

        #expect(result == .anonymous)
        #expect(result.isAnonymous)
        #expect(repo.getCurrentUserCallCount == 1)
    }

    @Test("Returns stored user when signed in")
    func returnsStoredUserWhenSignedIn() {
        let repo = MockAuthRepository()
        let user = AuthUser(userId: "u1", email: "u@x.com", displayName: "U", isAnonymous: false)
        repo.userToReturn = user
        let sut = GetCurrentUserUseCase(repository: repo)

        let result = sut.execute()

        #expect(result == user)
        #expect(!result.isAnonymous)
    }
}
```

- [ ] **Step 2: Run test — expect FAIL**

```bash
swift test --package-path LocalPackages/Domain --filter GetCurrentUserUseCaseTests 2>&1 | tail -5
```
Expected: error — `cannot find type 'GetCurrentUserUseCase'`

- [ ] **Step 3: Implement GetCurrentUserUseCase**

```swift
// LocalPackages/Domain/Sources/Domain/UseCases/Implementations/GetCurrentUserUseCase.swift

public final class GetCurrentUserUseCase: GetCurrentUserUseCaseProtocol {
    private let repository: any AuthRepositoryProtocol

    public init(repository: any AuthRepositoryProtocol) {
        self.repository = repository
    }

    public func execute() -> AuthUser {
        repository.getCurrentUser()
    }
}
```

- [ ] **Step 4: Run test — expect PASS**

```bash
swift test --package-path LocalPackages/Domain --filter GetCurrentUserUseCaseTests 2>&1 | tail -5
```
Expected: `Test run with 2 tests passed`

- [ ] **Step 5: Commit**

```bash
git add LocalPackages/Domain/Tests/DomainTests/UseCases/GetCurrentUserUseCaseTests.swift \
        LocalPackages/Domain/Sources/Domain/UseCases/Implementations/GetCurrentUserUseCase.swift
git commit -m "feat(domain): add GetCurrentUserUseCase with tests"
```

---

## Task 6: Domain — SignOutUseCase (TDD)

**Files:**
- Create: `LocalPackages/Domain/Tests/DomainTests/UseCases/SignOutUseCaseTests.swift`
- Create: `LocalPackages/Domain/Sources/Domain/UseCases/Implementations/SignOutUseCase.swift`

- [ ] **Step 1: Write the failing test**

```swift
// LocalPackages/Domain/Tests/DomainTests/UseCases/SignOutUseCaseTests.swift
import Testing
import Foundation
@testable import Domain

@Suite("SignOutUseCase")
struct SignOutUseCaseTests {

    @Test("Calls repository signOut exactly once")
    func callsRepositorySignOut() {
        let repo = MockAuthRepository()
        let sut = SignOutUseCase(repository: repo)

        sut.execute()

        #expect(repo.signOutCallCount == 1)
    }

    @Test("User is anonymous after signOut")
    func userIsAnonymousAfterSignOut() {
        let repo = MockAuthRepository()
        repo.userToReturn = AuthUser(userId: "u1", email: nil, displayName: nil, isAnonymous: false)
        let sut = SignOutUseCase(repository: repo)

        sut.execute()

        #expect(repo.userToReturn == .anonymous)
    }
}
```

- [ ] **Step 2: Run test — expect FAIL**

```bash
swift test --package-path LocalPackages/Domain --filter SignOutUseCaseTests 2>&1 | tail -5
```
Expected: error — `cannot find type 'SignOutUseCase'`

- [ ] **Step 3: Implement SignOutUseCase**

```swift
// LocalPackages/Domain/Sources/Domain/UseCases/Implementations/SignOutUseCase.swift

public final class SignOutUseCase: SignOutUseCaseProtocol {
    private let repository: any AuthRepositoryProtocol

    public init(repository: any AuthRepositoryProtocol) {
        self.repository = repository
    }

    public func execute() {
        repository.signOut()
    }
}
```

- [ ] **Step 4: Run all Domain tests — expect PASS**

```bash
swift test --package-path LocalPackages/Domain 2>&1 | tail -5
```
Expected: all tests passed

- [ ] **Step 5: Commit**

```bash
git add LocalPackages/Domain/Tests/DomainTests/UseCases/SignOutUseCaseTests.swift \
        LocalPackages/Domain/Sources/Domain/UseCases/Implementations/SignOutUseCase.swift
git commit -m "feat(domain): add SignOutUseCase with tests"
```

---

## Task 7: Data — KeychainStore

**Files:**
- Create: `LocalPackages/Data/Sources/Data/Persistence/KeychainStore.swift`

`KeychainStore` wraps the Security framework. Not exposed outside Data — no `public` modifier needed. Unit testing Keychain requires a real device; this is verified via integration in Task 16.

- [ ] **Step 1: Create the file**

```swift
// LocalPackages/Data/Sources/Data/Persistence/KeychainStore.swift
import Foundation
import Security

struct KeychainStore {
    func save(_ value: String, forKey key: String) {
        let data = Data(value.utf8)
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecValueData:   data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    func read(forKey key: String) -> String? {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecReturnData:  true,
            kSecMatchLimit:  kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else { return nil }
        return value
    }

    func delete(forKey key: String) {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrAccount: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
```

- [ ] **Step 2: Verify Data package compiles**

```bash
swift build --package-path LocalPackages/Data 2>&1 | tail -5
```
Expected: `Build complete!`

- [ ] **Step 3: Commit**

```bash
git add LocalPackages/Data/Sources/Data/Persistence/KeychainStore.swift
git commit -m "feat(data): add KeychainStore"
```

---

## Task 8: Data — AuthRepositoryImpl

**Files:**
- Create: `LocalPackages/Data/Sources/Data/Repositories/AuthRepositoryImpl.swift`

- [ ] **Step 1: Create the file**

```swift
// LocalPackages/Data/Sources/Data/Repositories/AuthRepositoryImpl.swift
import Foundation
import Domain

public final class AuthRepositoryImpl: AuthRepositoryProtocol {
    private let keychain: KeychainStore

    private enum Keys {
        static let userId      = "auth.userId"
        static let email       = "auth.email"
        static let displayName = "auth.displayName"
    }

    public init(keychain: KeychainStore) {
        self.keychain = keychain
    }

    public func signInWithApple(userId: String, email: String?, displayName: String?) async throws -> AuthUser {
        keychain.save(userId, forKey: Keys.userId)
        if let email       { keychain.save(email,       forKey: Keys.email) }
        if let displayName { keychain.save(displayName, forKey: Keys.displayName) }
        return AuthUser(userId: userId, email: email, displayName: displayName, isAnonymous: false)
    }

    public func getCurrentUser() -> AuthUser {
        guard let userId = keychain.read(forKey: Keys.userId), !userId.isEmpty else {
            return .anonymous
        }
        return AuthUser(
            userId:      userId,
            email:       keychain.read(forKey: Keys.email),
            displayName: keychain.read(forKey: Keys.displayName),
            isAnonymous: false
        )
    }

    public func signOut() {
        keychain.delete(forKey: Keys.userId)
        keychain.delete(forKey: Keys.email)
        keychain.delete(forKey: Keys.displayName)
    }
}
```

- [ ] **Step 2: Verify Data package compiles**

```bash
swift build --package-path LocalPackages/Data 2>&1 | tail -5
```
Expected: `Build complete!`

- [ ] **Step 3: Commit**

```bash
git add LocalPackages/Data/Sources/Data/Repositories/AuthRepositoryImpl.swift
git commit -m "feat(data): add AuthRepositoryImpl with Keychain persistence"
```

---

## Task 9: Features — AuthViewModel (TDD)

**Files:**
- Create: `LocalPackages/Features/Tests/FeaturesTests/Mocks/MockAuthUseCases.swift`
- Create: `LocalPackages/Features/Sources/Features/Auth/ViewModels/AuthViewModel.swift`
- Create: `LocalPackages/Features/Tests/FeaturesTests/ViewModels/AuthViewModelTests.swift`

- [ ] **Step 1: Create MockAuthUseCases**

```swift
// LocalPackages/Features/Tests/FeaturesTests/Mocks/MockAuthUseCases.swift
import Foundation
import Domain
@testable import Features

final class MockSignInWithAppleUseCase: SignInWithAppleUseCaseProtocol {
    var userToReturn = AuthUser(userId: "mock123", email: "mock@test.com", displayName: "Mock User", isAnonymous: false)
    var shouldThrow = false
    var executeCallCount = 0

    func execute(userId: String, email: String?, displayName: String?) async throws -> AuthUser {
        executeCallCount += 1
        if shouldThrow { throw AuthError.keychainFailure }
        return userToReturn
    }
}

final class MockGetCurrentUserUseCase: GetCurrentUserUseCaseProtocol {
    var userToReturn: AuthUser = .anonymous
    var executeCallCount = 0

    func execute() -> AuthUser {
        executeCallCount += 1
        return userToReturn
    }
}

final class MockSignOutUseCase: SignOutUseCaseProtocol {
    var executeCallCount = 0

    func execute() {
        executeCallCount += 1
    }
}
```

- [ ] **Step 2: Write the failing test**

```swift
// LocalPackages/Features/Tests/FeaturesTests/ViewModels/AuthViewModelTests.swift
import Testing
import Foundation
import Domain
@testable import Features

@Suite("AuthViewModel")
@MainActor
struct AuthViewModelTests {

    func makeSUT() -> (AuthViewModel, MockSignInWithAppleUseCase) {
        let useCase = MockSignInWithAppleUseCase()
        let vm = AuthViewModel(signInWithAppleUseCase: useCase)
        return (vm, useCase)
    }

    @Test("Initial step is prompt")
    func initialStepIsPrompt() {
        let (vm, _) = makeSUT()
        #expect(vm.step == .prompt)
    }

    @Test("signInWithApple advances to success on valid credential")
    func signInWithAppleSucceeds() async {
        let (vm, useCase) = makeSUT()
        let expected = AuthUser(userId: "abc", email: "a@b.com", displayName: "AB", isAnonymous: false)
        useCase.userToReturn = expected

        await vm.signInWithApple(userId: "abc", email: "a@b.com", displayName: "AB")

        #expect(vm.step == .success(expected))
        #expect(useCase.executeCallCount == 1)
    }

    @Test("signInWithApple sets error step on use case failure")
    func signInWithAppleFails() async {
        let (vm, useCase) = makeSUT()
        useCase.shouldThrow = true

        await vm.signInWithApple(userId: "abc", email: nil, displayName: nil)

        if case .error = vm.step { } else {
            Issue.record("Expected .error, got \(vm.step)")
        }
    }

    @Test("reset returns step to prompt")
    func resetReturnsToPrompt() async {
        let (vm, _) = makeSUT()
        await vm.signInWithApple(userId: "abc", email: nil, displayName: nil)
        vm.reset()
        #expect(vm.step == .prompt)
    }

    @Test("setError sets error step with message")
    func setErrorSetsErrorStep() {
        let (vm, _) = makeSUT()
        vm.setError("Something went wrong")
        #expect(vm.step == .error("Something went wrong"))
    }
}
```

- [ ] **Step 3: Run test — expect FAIL**

```bash
swift test --package-path LocalPackages/Features --filter AuthViewModelTests 2>&1 | tail -10
```
Expected: error — `cannot find type 'AuthViewModel'`

- [ ] **Step 4: Implement AuthViewModel**

```swift
// LocalPackages/Features/Sources/Features/Auth/ViewModels/AuthViewModel.swift
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
```

- [ ] **Step 5: Run test — expect PASS**

```bash
swift test --package-path LocalPackages/Features --filter AuthViewModelTests 2>&1 | tail -5
```
Expected: `Test run with 5 tests passed`

- [ ] **Step 6: Commit**

```bash
git add LocalPackages/Features/Tests/FeaturesTests/Mocks/MockAuthUseCases.swift \
        LocalPackages/Features/Sources/Features/Auth/ViewModels/AuthViewModel.swift \
        LocalPackages/Features/Tests/FeaturesTests/ViewModels/AuthViewModelTests.swift
git commit -m "feat(features): add AuthViewModel with tests"
```

---

## Task 10: Features — SettingsViewModel (TDD)

**Files:**
- Create: `LocalPackages/Features/Sources/Features/Settings/ViewModels/SettingsViewModel.swift`
- Create: `LocalPackages/Features/Tests/FeaturesTests/ViewModels/SettingsViewModelTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
// LocalPackages/Features/Tests/FeaturesTests/ViewModels/SettingsViewModelTests.swift
import Testing
import Foundation
import Domain
@testable import Features

@Suite("SettingsViewModel")
@MainActor
struct SettingsViewModelTests {

    func makeSUT(
        user: AuthUser = .anonymous
    ) -> (SettingsViewModel, MockGetCurrentUserUseCase, MockSignOutUseCase) {
        let getCurrentUser = MockGetCurrentUserUseCase()
        getCurrentUser.userToReturn = user
        let signOut = MockSignOutUseCase()
        let vm = SettingsViewModel(
            getCurrentUserUseCase: getCurrentUser,
            signOutUseCase: signOut
        )
        return (vm, getCurrentUser, signOut)
    }

    @Test("Loads current user on init")
    func loadsCurrentUserOnInit() {
        let user = AuthUser(userId: "u1", email: "u@x.com", displayName: "U", isAnonymous: false)
        let (vm, getUser, _) = makeSUT(user: user)

        #expect(vm.currentUser == user)
        #expect(getUser.executeCallCount == 1)
    }

    @Test("Guest state is anonymous on init")
    func guestStateIsAnonymousOnInit() {
        let (vm, _, _) = makeSUT()
        #expect(vm.currentUser == .anonymous)
        #expect(vm.currentUser.isAnonymous)
    }

    @Test("signOut resets currentUser to anonymous")
    func signOutResetsToAnonymous() {
        let user = AuthUser(userId: "u1", email: nil, displayName: nil, isAnonymous: false)
        let (vm, _, signOut) = makeSUT(user: user)

        vm.signOut()

        #expect(vm.currentUser == .anonymous)
        #expect(signOut.executeCallCount == 1)
    }
}
```

- [ ] **Step 2: Run test — expect FAIL**

```bash
swift test --package-path LocalPackages/Features --filter SettingsViewModelTests 2>&1 | tail -5
```
Expected: error — `cannot find type 'SettingsViewModel'`

- [ ] **Step 3: Implement SettingsViewModel**

```swift
// LocalPackages/Features/Sources/Features/Settings/ViewModels/SettingsViewModel.swift
import Foundation
import Domain

public protocol SettingsViewModelProtocol: ObservableObject {
    var currentUser: AuthUser { get }
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
    public func signOut() {
        signOutUseCase.execute()
        currentUser = .anonymous
    }
}
```

- [ ] **Step 4: Run all Features tests — expect PASS**

```bash
swift test --package-path LocalPackages/Features 2>&1 | tail -5
```
Expected: all tests passed

- [ ] **Step 5: Commit**

```bash
git add LocalPackages/Features/Sources/Features/Settings/ViewModels/SettingsViewModel.swift \
        LocalPackages/Features/Tests/FeaturesTests/ViewModels/SettingsViewModelTests.swift
git commit -m "feat(features): add SettingsViewModel with tests"
```

---

## Task 11: Features — AuthSheetView

**Files:**
- Create: `LocalPackages/Features/Sources/Features/Auth/Views/AuthSheetView.swift`

`AuthSheetView` handles `ASAuthorizationController` result directly because `AuthenticationServices` must not be imported in Domain or Data. It passes extracted strings up to the ViewModel.

- [ ] **Step 1: Create the file**

```swift
// LocalPackages/Features/Sources/Features/Auth/Views/AuthSheetView.swift
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
            case .prompt:           promptView
            case .inProgress:       inProgressView
            case .success(let user): successView(user: user)
            case .error(let msg):   errorView(message: msg)
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
            break
        case .failure(let error):
            viewModel.setError(error.localizedDescription)
        }
    }
}
```

- [ ] **Step 2: Verify Features compiles**

```bash
swift build --package-path LocalPackages/Features 2>&1 | tail -5
```
Expected: `Build complete!`

- [ ] **Step 3: Commit**

```bash
git add LocalPackages/Features/Sources/Features/Auth/Views/AuthSheetView.swift
git commit -m "feat(features): add AuthSheetView (multi-step sheet demo)"
```

---

## Task 12: Features — SettingsView

**Files:**
- Create: `LocalPackages/Features/Sources/Features/Settings/Views/SettingsView.swift`

- [ ] **Step 1: Create the file**

```swift
// LocalPackages/Features/Sources/Features/Settings/Views/SettingsView.swift
import SwiftUI
import Domain

public struct SettingsView<ViewModel: SettingsViewModelProtocol>: View {
    @ObservedObject public var viewModel: ViewModel
    public var onSignInTapped: () -> Void

    public init(viewModel: ViewModel, onSignInTapped: @escaping () -> Void) {
        self.viewModel       = viewModel
        self.onSignInTapped  = onSignInTapped
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
                        Text(viewModel.currentUser.displayName ?? "Apple User")
                            .font(.headline)
                        if let email = viewModel.currentUser.email {
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
```

- [ ] **Step 2: Verify Features compiles**

```bash
swift build --package-path LocalPackages/Features 2>&1 | tail -5
```
Expected: `Build complete!`

- [ ] **Step 3: Commit**

```bash
git add LocalPackages/Features/Sources/Features/Settings/Views/SettingsView.swift
git commit -m "feat(features): add SettingsView"
```

---

## Task 13: Features — StockFilterView (multi-detent sheet demo)

**Files:**
- Create: `LocalPackages/Features/Sources/Features/StockFilter/StockFilterView.swift`

`StockFilter` is a Features-layer struct — no business logic depends on it. The view demonstrates dragging between `.medium` (basic filters) and `.large` (more filters revealed) detents.

- [ ] **Step 1: Create the file**

```swift
// LocalPackages/Features/Sources/Features/StockFilter/StockFilterView.swift
import SwiftUI

public struct StockFilter: Equatable {
    public var sectors: Set<String>
    public var maxPrice: Double?

    public static let empty = StockFilter(sectors: [], maxPrice: nil)

    public init(sectors: Set<String> = [], maxPrice: Double? = nil) {
        self.sectors  = sectors
        self.maxPrice = maxPrice
    }
}

public struct StockFilterView: View {
    @State private var filter: StockFilter
    public var onApply: (StockFilter) -> Void
    public var onDismiss: () -> Void

    private let basicSectors    = ["Technology", "Finance", "Energy"]
    private let advancedSectors = ["Healthcare", "Consumer", "Industrials"]

    public init(
        initialFilter: StockFilter = .empty,
        onApply:  @escaping (StockFilter) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        _filter       = State(initialValue: initialFilter)
        self.onApply  = onApply
        self.onDismiss = onDismiss
    }

    public var body: some View {
        VStack(spacing: 0) {
            dragHandle
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    sectorSection(title: "Sector", sectors: basicSectors)
                    advancedSection
                    priceSection
                    applyButton
                        .padding(.bottom, 8)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
        }
    }

    private var dragHandle: some View {
        VStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.secondary.opacity(0.4))
                .frame(width: 36, height: 4)
                .padding(.top, 8)
            HStack {
                Text("Filter Stocks")
                    .font(.headline)
                Spacer()
                Button("Reset") { filter = .empty }
                    .font(.subheadline)
                    .foregroundStyle(.tint)
            }
            .padding(.horizontal, 20)
            Divider()
        }
    }

    private func sectorSection(title: String, sectors: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline).foregroundStyle(.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(sectors, id: \.self) { sector in
                        chipButton(sector)
                    }
                }
            }
        }
    }

    private var advancedSection: some View {
        sectorSection(title: "More Sectors  ↑ drag to reveal more", sectors: advancedSectors)
    }

    private func chipButton(_ sector: String) -> some View {
        let selected = filter.sectors.contains(sector)
        return Button {
            if selected { filter.sectors.remove(sector) } else { filter.sectors.insert(sector) }
        } label: {
            Text(sector)
                .font(.subheadline)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(selected ? Color.accentColor : Color(.secondarySystemBackground))
                .foregroundStyle(selected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var priceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Max Price")
                .font(.subheadline).foregroundStyle(.secondary)
            Slider(
                value: Binding(
                    get: { filter.maxPrice ?? 1000 },
                    set: { filter.maxPrice = $0 < 1000 ? $0 : nil }
                ),
                in: 10...1000, step: 10
            )
            Text(filter.maxPrice.map { "Up to $\(Int($0))" } ?? "Any price")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    private var applyButton: some View {
        Button {
            onApply(filter)
            onDismiss()
        } label: {
            Text("Apply Filters")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}
```

- [ ] **Step 2: Verify Features compiles**

```bash
swift build --package-path LocalPackages/Features 2>&1 | tail -5
```
Expected: `Build complete!`

- [ ] **Step 3: Commit**

```bash
git add LocalPackages/Features/Sources/Features/StockFilter/StockFilterView.swift
git commit -m "feat(features): add StockFilterView (multi-detent sheet demo)"
```

---

## Task 14: Features — DashboardView filter button

**Files:**
- Modify: `LocalPackages/Features/Sources/Features/Dashboard/Views/DashboardView.swift`

Add an optional `onFilterTapped` closure and a toolbar button. The coordinator wires the closure; the view just calls it.

- [ ] **Step 1: Add `onFilterTapped` parameter and toolbar to DashboardView**

Locate the current `init` in `DashboardView.swift`:
```swift
var onStockTapped:     (String) -> Void = { _ in }
var onSeeAllWatchlist: () -> Void       = {}

public init(
    viewModel: ViewModel,
    onStockTapped:     @escaping (String) -> Void = { _ in },
    onSeeAllWatchlist: @escaping () -> Void       = {}
) {
    _viewModel = StateObject(wrappedValue: viewModel)
    self.onStockTapped     = onStockTapped
    self.onSeeAllWatchlist = onSeeAllWatchlist
}
```

Replace with:
```swift
var onStockTapped:     (String) -> Void = { _ in }
var onSeeAllWatchlist: () -> Void       = {}
var onFilterTapped:    () -> Void       = {}

public init(
    viewModel: ViewModel,
    onStockTapped:     @escaping (String) -> Void = { _ in },
    onSeeAllWatchlist: @escaping () -> Void       = {},
    onFilterTapped:    @escaping () -> Void       = {}
) {
    _viewModel = StateObject(wrappedValue: viewModel)
    self.onStockTapped     = onStockTapped
    self.onSeeAllWatchlist = onSeeAllWatchlist
    self.onFilterTapped    = onFilterTapped
}
```

Then add `.toolbar` to the `body`:
```swift
public var body: some View {
    Group {
        // ... existing content unchanged ...
    }
    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.isLoading)
    .safeAreaInset(edge: .top) { headerView }
    .task { await viewModel.loadDashboard() }
    .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
            Button { onFilterTapped() } label: {
                Image(systemName: "line.3.horizontal.decrease.circle")
            }
        }
    }
}
```

- [ ] **Step 2: Verify Features compiles**

```bash
swift build --package-path LocalPackages/Features 2>&1 | tail -5
```
Expected: `Build complete!`

- [ ] **Step 3: Run all Features tests to confirm no regression**

```bash
swift test --package-path LocalPackages/Features 2>&1 | tail -5
```
Expected: all tests passed

- [ ] **Step 4: Commit**

```bash
git add LocalPackages/Features/Sources/Features/Dashboard/Views/DashboardView.swift
git commit -m "feat(features): add filter toolbar button to DashboardView"
```

---

## Task 15: Navigation — SettingsCoordinator

**Files:**
- Create: `StockPulse/Core/Navigation/SettingsCoordinator.swift`

Mirrors `AuthCoordinator` shape. Owns a `SheetCoordinator` for the auth flow detent.

- [ ] **Step 1: Create the file**

```swift
// StockPulse/Core/Navigation/SettingsCoordinator.swift
import SwiftUI

final class SettingsCoordinator: ObservableObject, RouterProtocol {
    @Published var path = NavigationPath()
    @Published var presentedSheet: SheetRoute?
    @Published var presentedFullScreen: SheetRoute?
    @Published var activeDetent: PresentationDetent = .medium

    var sheetCoordinator = SheetCoordinator()

    func navigate(to route: AppRoute) {
        path.append(route)
    }

    func navigateBack() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func navigateToRoot() {
        path = NavigationPath()
    }

    func handleDeepLink(url: URL) -> Bool { false }

    func handleNotification(userInfo: [AnyHashable: Any]) -> Bool { false }

    func handleVoiceIntent(_ intent: VoiceIntent) -> Bool {
        switch intent {
        case .goBack:  navigateBack(); return true
        case .dismiss: dismissSheet(); return true
        default:       return false
        }
    }

    func presentSheet(_ route: SheetRoute) {
        sheetCoordinator.currentDetent = .medium
        presentedSheet = route
    }

    func presentFullScreen(_ route: SheetRoute) {
        presentedFullScreen = route
    }

    func dismissSheet() {
        presentedSheet = nil
        sheetCoordinator.popToRoot()
    }

    func dismissFullScreen() {
        presentedFullScreen = nil
    }

    func setDetent(_ detent: PresentationDetent) {
        activeDetent = detent
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add StockPulse/Core/Navigation/SettingsCoordinator.swift
git commit -m "feat(nav): add SettingsCoordinator"
```

---

## Task 16: DI — AppContainer additions

**Files:**
- Modify: `StockPulse/Core/DI/AppContainer.swift`

Add a `// MARK: - Auth` section after the existing `// MARK: - Recent Search` section.

- [ ] **Step 1: Add auth registrations to AppContainer**

Add the following inside `extension Container { ... }`, after the `// MARK: - Watchlist ViewModel` block:

```swift
// MARK: - Auth

var keychainStore: Factory<KeychainStore> {
    self { KeychainStore() }
        .singleton
}

var authRepository: Factory<any AuthRepositoryProtocol> {
    self { AuthRepositoryImpl(keychain: self.keychainStore()) }
        .singleton
}

var signInWithAppleUseCase: Factory<any SignInWithAppleUseCaseProtocol> {
    self { SignInWithAppleUseCase(repository: self.authRepository()) }
}

var getCurrentUserUseCase: Factory<any GetCurrentUserUseCaseProtocol> {
    self { GetCurrentUserUseCase(repository: self.authRepository()) }
}

var signOutUseCase: Factory<any SignOutUseCaseProtocol> {
    self { SignOutUseCase(repository: self.authRepository()) }
}

var authViewModel: Factory<AuthViewModel> {
    self { AuthViewModel(signInWithAppleUseCase: self.signInWithAppleUseCase()) }
}

var settingsViewModel: Factory<SettingsViewModel> {
    self {
        SettingsViewModel(
            getCurrentUserUseCase: self.getCurrentUserUseCase(),
            signOutUseCase:        self.signOutUseCase()
        )
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add StockPulse/Core/DI/AppContainer.swift
git commit -m "feat(di): register auth stack in AppContainer"
```

---

## Task 17: Navigation — AppCoordinator + AppCoordinatorView

**Files:**
- Modify: `StockPulse/Core/Navigation/AppCoordinator.swift`
- Modify: `StockPulse/Core/Navigation/AppCoordinatorView.swift`

### AppCoordinator changes

- [ ] **Step 1: Rename `.notifications` to `.settings` in the `AppTab` enum**

In `AppCoordinator.swift`, locate:
```swift
enum AppTab: String, CaseIterable {
    case dashboard
    case watchlist
    case search
    case notifications
    case assistant
}
```

Replace with:
```swift
enum AppTab: String, CaseIterable {
    case dashboard
    case watchlist
    case search
    case settings
    case assistant
}
```

- [ ] **Step 2: Add `settingsCoordinator` and fix `activeCoordinator`**

Locate:
```swift
var authCoordinator        = AuthCoordinator()
var dashboardCoordinator   = DashboardCoordinator()
var stockDetailCoordinator = StockDetailCoordinator()
var watchlistCoordinator   = WatchlistCoordinator()
var searchCoordinator      = SearchCoordinator()
```

Replace with:
```swift
var authCoordinator        = AuthCoordinator()
var dashboardCoordinator   = DashboardCoordinator()
var stockDetailCoordinator = StockDetailCoordinator()
var watchlistCoordinator   = WatchlistCoordinator()
var searchCoordinator      = SearchCoordinator()
var settingsCoordinator    = SettingsCoordinator()
```

Locate the `activeCoordinator` computed property:
```swift
private var activeCoordinator: any CoordinatorProtocol {
    switch activeTab {
    case .dashboard:     return dashboardCoordinator
    case .watchlist:     return watchlistCoordinator
    case .search:        return searchCoordinator
    case .notifications: return dashboardCoordinator
    case .assistant:     return dashboardCoordinator
    }
}
```

Replace with:
```swift
private var activeCoordinator: any CoordinatorProtocol {
    switch activeTab {
    case .dashboard: return dashboardCoordinator
    case .watchlist: return watchlistCoordinator
    case .search:    return searchCoordinator
    case .settings:  return settingsCoordinator
    case .assistant: return dashboardCoordinator
    }
}
```

### AppCoordinatorView changes

- [ ] **Step 3: Replace Notifications tab with SettingsTab and wire stock filter sheet to DashboardTab**

In `AppCoordinatorView.swift`, locate the Notifications tab in `body`:
```swift
NavigationStack {
    Text("Notifications")
}
.tabItem { Label("Notifications", systemImage: "bell.fill") }
.tag(AppCoordinator.AppTab.notifications)
```

Replace with:
```swift
SettingsTab(coordinator: coordinator.settingsCoordinator)
    .tabItem { Label("Settings", systemImage: "gearshape.fill") }
    .tag(AppCoordinator.AppTab.settings)
```

In `DashboardTab.body`, locate:
```swift
DashboardView(
    viewModel: viewModel,
    onStockTapped: { symbol in
        coordinator.navigate(to: .stockDetail(symbol: symbol))
    },
    onSeeAllWatchlist: {
        coordinator.navigate(to: .watchlist)
    }
)
```

Replace with:
```swift
DashboardView(
    viewModel: viewModel,
    onStockTapped: { symbol in
        coordinator.navigate(to: .stockDetail(symbol: symbol))
    },
    onSeeAllWatchlist: {
        coordinator.navigate(to: .watchlist)
    },
    onFilterTapped: {
        coordinator.presentSheet(.stockFilter)
    }
)
```

Then add a `.sheet` modifier to `DashboardTab.body` after `.navigationDestination`:
```swift
.sheet(item: $coordinator.presentedSheet) { route in
    switch route {
    case .stockFilter:
        StockFilterView(
            onApply:   { _ in coordinator.dismissSheet() },
            onDismiss: { coordinator.dismissSheet() }
        )
        .presentationDetents([.medium, .large], selection: $coordinator.activeDetent)
        .presentationDragIndicator(.visible)
    default:
        EmptyView()
    }
}
```

- [ ] **Step 4: Add SettingsTab struct at the bottom of AppCoordinatorView.swift**

```swift
// MARK: - Settings Tab

private struct SettingsTab: View {
    @ObservedObject var coordinator: SettingsCoordinator
    @StateObject private var settingsVM = Container.shared.settingsViewModel()

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            SettingsView(
                viewModel: settingsVM,
                onSignInTapped: { coordinator.presentSheet(.authFlow) }
            )
        }
        .sheet(item: $coordinator.presentedSheet) { route in
            switch route {
            case .authFlow:
                let authVM = Container.shared.authViewModel()
                AuthSheetView(
                    viewModel: authVM,
                    onDetentChange: { coordinator.sheetCoordinator.setDetent($0) },
                    onDismiss: { coordinator.dismissSheet() }
                )
                .presentationDetents([.medium, .large], selection: $coordinator.sheetCoordinator.currentDetent)
                .presentationDragIndicator(.visible)
            default:
                EmptyView()
            }
        }
    }
}
```

- [ ] **Step 5: Commit**

```bash
git add StockPulse/Core/Navigation/AppCoordinator.swift \
        StockPulse/Core/Navigation/AppCoordinatorView.swift
git commit -m "feat(nav): add SettingsTab, wire stock filter + auth sheets"
```

---

## Task 18: XcodeGen + Sign in with Apple capability

- [ ] **Step 1: Run xcodegen to register all new files**

```bash
xcodegen generate
```
Expected: `Generating project StockPulse...` with no errors.

- [ ] **Step 2: Enable Sign in with Apple capability in Xcode**

Open Xcode → select the `StockPulse` target → **Signing & Capabilities** tab → click **+ Capability** → add **Sign in with Apple**.

This writes the entitlement to the existing `.entitlements` file — `xcodegen` does not manage capabilities that require provisioning portal updates.

- [ ] **Step 3: Verify the build compiles in Xcode**

In Xcode, select the **StockPulse** scheme and a simulator, then press **⌘B**.
Expected: Build Succeeded with 0 errors.

- [ ] **Step 4: Commit the xcodegen output**

```bash
git add StockPulse.xcodeproj
git commit -m "chore: regenerate Xcode project with auth + settings files"
```

---

## Task 19: Integration verification

- [ ] **Step 1: Run all Domain tests**

```bash
swift test --package-path LocalPackages/Domain 2>&1 | tail -10
```
Expected: all tests passed

- [ ] **Step 2: Run all Features tests**

```bash
swift test --package-path LocalPackages/Features 2>&1 | tail -10
```
Expected: all tests passed

- [ ] **Step 3: Run full xcodebuild test suite**

```bash
xcodebuild test \
  -scheme StockPulse \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
  2>&1 | tail -20
```
Expected: `** TEST SUCCEEDED **`

- [ ] **Step 4: Smoke test on simulator**

Launch the app in the simulator and verify:
1. The Settings tab appears (gear icon, fifth tab)
2. Guest state shows "Sign in with Apple" row in Settings
3. Tapping "Sign in with Apple" opens the auth sheet at medium detent
4. Tapping "Continue without signing in" dismisses the sheet
5. The filter button (≡ with chevron) appears in Dashboard toolbar
6. Tapping it opens the stock filter sheet at medium detent
7. Dragging the filter sheet up expands it to large detent, revealing advanced sectors
8. "Apply Filters" dismisses the sheet
9. Anonymous users can navigate the full app without being blocked

- [ ] **Step 5: Final commit**

```bash
git add .
git commit -m "feat: Sign in with Apple + sheet demo (auth multi-step + filter multi-detent)"
```
