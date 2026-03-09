# StockPulse - Claude Code Guidelines

## Product Vision
StockPulse is a production-grade iOS stock market app for tracking
stocks, viewing price charts, and managing a personal watchlist.
Min deployment: iOS 17. Swift 5.9+. SwiftUI only, no UIKit.
Bundle ID: com.sweta.stockpulse

---

## Architecture: MVVM + Clean Architecture

### Dependency Flow
SwiftUI View → ViewModel → Use Case Protocol → Use Case Implementation → Repository Protocol → Repository Implementation

### Rules
- Views contain ZERO business logic
- ViewModels call Use Case protocols only, never Repositories directly
- Use Case implementations live in Domain — pure Swift, zero framework imports
- Use Case implementations depend ONLY on Repository protocols
- Repository protocols live in Domain, implementations live in Data
- No import of Data layer inside Features package
- No circular dependencies between packages
- Core lives inside main app target

---

## Project Structure
```
StockPulse/                              # Project root
├── project.yml                          # XcodeGen — source of truth for .xcodeproj
├── CLAUDE.md                            # This file
├── Configurations/
│   ├── Base.xcconfig                    # Shared settings
│   ├── Debug.xcconfig                   # Dev API key, full logging
│   ├── Staging.xcconfig                 # Staging API key, limited logging
│   └── Release.xcconfig                 # Prod API key, no logging
│
├── LocalPackages/
│   ├── Domain/                          # Package 1 — zero external dependencies
│   │   ├── Package.swift
│   │   └── Sources/Domain/
│   │       ├── Models/                  # Stock, Quote, WatchlistItem, User
│   │       ├── Repositories/            # Protocols only: StockRepositoryProtocol
│   │       └── UseCases/
│   │           ├── Protocols/           # FetchStockUseCaseProtocol, etc.
│   │           └── Implementations/     # FetchStockUseCase (pure Swift, no frameworks)
│   │                                    # Depends ONLY on Repository protocols
│   ├── Data/                            # Package 2 — depends on Domain
│   │   ├── Package.swift
│   │   └── Sources/Data/
│   │       ├── Repositories/            # StockRepositoryImpl, etc.
│   │       ├── Network/                 # APIClient, Endpoints, DTOs
│   │       ├── Persistence/             # SwiftData / UserDefaults
│   │       └── Mappers/                 # DTO → Domain Model mappers
│   │
│   └── Features/                        # Package 3 — depends on Domain
│       ├── Package.swift
│       └── Sources/Features/
│           ├── Auth/
│           │   ├── Views/
│           │   └── ViewModels/
│           ├── Dashboard/
│           │   ├── Views/
│           │   └── ViewModels/
│           ├── StockDetail/
│           │   ├── Views/
│           │   └── ViewModels/
│           ├── Watchlist/
│           │   ├── Views/
│           │   └── ViewModels/
│           ├── Search/
│           │   ├── Views/
│           │   └── ViewModels/
│           └── Notifications/
│               ├── Views/
│               └── ViewModels/
│
└── StockPulse/                          # Main app target
    ├── StockPulseApp.swift              # @main, bootstraps DI + Navigation
    ├── Info.plist
    ├── Assets.xcassets
    └── Core/                            # Inside main app target
        ├── Navigation/                  # AppCoordinator, RouterProtocol, AppRoute
        ├── DI/                          # AppContainer, Factory registrations
        ├── DesignSystem/                # Colors, Typography, Components
        └── Utilities/                   # Extensions, Constants
```

---

## Package Dependency Rules
```
Domain     ←── Data        (Data imports Domain)
Domain     ←── Features    (Features imports Domain)
Domain     ←── Core        (Core imports Domain)
Factory    ←── Data        (Data uses Factory)
Factory    ←── Features    (Features uses Factory)
Factory    ←── Core        (Core uses Factory)
Data       ←── Core        (Core wires Data implementations)
```

Domain NEVER imports Data or Features.
Features NEVER imports Data directly.

---

## XcodeGen
- project.yml is the source of truth for the Xcode project
- NEVER manually edit .pbxproj
- After Claude creates any new file, run: xcodegen generate
- Commit project.yml, gitignore .xcodeproj if desired

---

## Dependency Injection: Factory by Michael Long
- Library: hmlongco/Factory (SPM)
- One Container per layer (DomainContainer, DataContainer, FeaturesContainer)
- AppContainer in Core/DI wires everything together
- Always inject via protocols, never concrete types
- Use @Injected property wrapper in ViewModels
- Mock containers for all previews and tests

Example:
```swift
extension Container {
    var stockRepository: Factory<StockRepositoryProtocol> {
        self { StockRepositoryImpl() }
    }
    var fetchStockUseCase: Factory<FetchStockUseCaseProtocol> {
        self { FetchStockUseCase(repository: self.stockRepository()) }
    }
}
```

---

## Navigation Architecture
- Pattern: Coordinator + NavigationStack + NavigationPath (iOS 17+)
- AppCoordinator owns root navigation state
- Each feature has its own FeatureCoordinator
- Cross-feature navigation goes through AppCoordinator only
- Universal Links handled in AppCoordinator via onOpenURL

### Sheet Types
- .sheet()                               # single view or multi-step flow
- .fullScreenCover()                     # full screen sheets
- .presentationDetents([.medium,.large]) # half / draggable sheets
- popToRoot / dismiss entire stack       # full flow dismiss (e.g. post-Auth)

### AppRoute
```swift
enum AppRoute: Hashable {
    case stockDetail(symbol: String)
    case watchlist
    case auth
    case search
}
```

---

## Stock Data: Alpha Vantage
- Docs: https://www.alphavantage.co/documentation/
- Base URL: https://www.alphavantage.co/query
- Auth: apikey query parameter (injected per environment via xcconfig)
- Rate limits: 25 calls/day (free), 75/min (premium)

### Key Endpoints
- GLOBAL_QUOTE          → single stock quote
- TIME_SERIES_INTRADAY  → real-time intraday prices
- SYMBOL_SEARCH         → stock search
- OVERVIEW              → company details

### API Rules
- All calls: async/await only, no completion handlers
- DTOs never leave Data layer — always map to Domain models
- APIClient is a protocol — MockAPIClient for tests and previews
- API key read from Bundle via xcconfig — never hardcoded

---

## Build Configurations & xcconfig

| Scheme  | Config  | Bundle ID                     | API Key Source       |
|---------|---------|-------------------------------|----------------------|
| Debug   | Debug   | com.sweta.stockpulse.debug    | ALPHAVANTAGE_DEV_KEY |
| Staging | Staging | com.sweta.stockpulse.staging  | ALPHAVANTAGE_STG_KEY |
| Release | Release | com.sweta.stockpulse          | ALPHAVANTAGE_PROD_KEY|

### xcconfig files manage:
- ALPHAVANTAGE_API_KEY
- ALPHAVANTAGE_BASE_URL
- BUNDLE_ID_SUFFIX
- APP_DISPLAY_NAME
- Swift flags (DEBUG, STAGING, RELEASE)

---

## UI & Design
- Dark mode: full support, Color assets with dark variants
- Design system: centralized in Core/DesignSystem
- Animations: subtle, prefer .animation(.spring()) and .transition()
- SwiftUI previews required for EVERY View file
- Previews must use mock/stub data, never live data

---

## Future Features (design for, don't build yet)
- Push Notifications (APNs)
- Live Activities (ActivityKit)
- Widget support (WidgetKit)
- Universal Links / deep linking (wire AppCoordinator now)

---

## ⚠️ Critical Rules
1. NEVER modify .pbxproj — run xcodegen generate instead
2. After Claude creates any new .swift file, run xcodegen generate
3. Never put business logic in SwiftUI Views
4. Always use async/await — no callbacks or Combine unless required
5. Every ViewModel must have a protocol for testability
6. Add Logger statements for all async flows and navigation events
7. Use Case implementations are pure Swift — zero framework imports
8. API key is NEVER hardcoded — always read from Bundle via xcconfig
9. DTOs never leave the Data layer
10. Features never import Data directly

---

## Testing Strategy
- Unit tests: Swift Testing framework (@Test attribute)
- UI tests: XCTest + @MainActor
- Every UseCase must have unit tests
- Every ViewModel must have unit tests using mock repositories
- MockAPIClient used for all network tests

Run tests:
```bash
xcodebuild test -scheme StockPulse \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

---

## Current Status
- Phase: Domain Layer — ready to build ✅
- XcodeGen: ✅ installed and working
- SPM packages: ✅ Domain, Data, Features, Factory all resolved
- Build configs: ✅ Debug, Staging, Release wired via xcconfig
- Info.plist: ✅ created
- API: Alpha Vantage (API key setup pending)
- Features in progress: None yet
