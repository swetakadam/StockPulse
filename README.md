# StockPulse 📈

A production-grade iOS stock market app built with SwiftUI, Clean Architecture, and MVVM. Built as a learning project and architecture template.

> **Note:** This project was built as a hands-on exercise in iOS Clean Architecture using Claude Code as an AI pair programmer.

---

## Screenshots

| Dashboard | Stock Detail | Search | Watchlist |
|-----------|-------------|--------|-----------|
| Market overview with liquid glass cards | Real-time price, stats, company info | Debounced live search | Sort, swipe to delete |

---

## Tech Stack

| Category | Choice | Why |
|----------|--------|-----|
| UI | SwiftUI | iOS 17+, declarative |
| Architecture | MVVM + Clean Architecture | Testable, scalable |
| DI | Factory by Michael Long | Protocol-first, testable |
| Navigation | Coordinator + NavigationPath | Type-safe, deep-link ready |
| API | Finnhub (free tier) | 60 calls/min, no daily cap |
| Caching | Two-level (Memory + UserDefaults) | Instant loads, offline support |
| Project | XcodeGen | No .pbxproj conflicts |
| Min iOS | iOS 17 | NavigationPath, SwiftData |

---

## Architecture

### MVVM + Clean Architecture

```
┌─────────────────────────────────────────────────┐
│                   SwiftUI View                   │
│         (zero business logic, closures           │
│          for navigation, generic ViewModel)      │
└────────────────────┬────────────────────────────┘
                     │ observes @Published
┌────────────────────▼────────────────────────────┐
│                  ViewModel                       │
│     (ObservableObject, constructor injection,    │
│      @MainActor on async methods only)           │
└────────────────────┬────────────────────────────┘
                     │ calls protocol
┌────────────────────▼────────────────────────────┐
│              Use Case Protocol                   │
│                  (Domain)                        │
└────────────────────┬────────────────────────────┘
                     │ implemented by
┌────────────────────▼────────────────────────────┐
│           Use Case Implementation                │
│    (Domain, pure Swift, zero frameworks)         │
└────────────────────┬────────────────────────────┘
                     │ calls protocol
┌────────────────────▼────────────────────────────┐
│           Repository Protocol                    │
│                  (Domain)                        │
└────────────────────┬────────────────────────────┘
                     │ implemented by
┌────────────────────▼────────────────────────────┐
│         Repository Implementation                │
│      (Data — APIClient + Cache + Store)          │
└─────────────────────────────────────────────────┘
```

### Package Structure

```
StockPulse/
├── LocalPackages/
│   ├── Domain/          # Pure Swift — zero external dependencies
│   │   ├── Models/      # Stock, Quote, CompanyOverview, RecentSearch
│   │   ├── Repositories/# Protocol definitions only
│   │   ├── UseCases/    # Business logic implementations
│   │   └── CachePolicy.swift  # Single flag: freeTier / premiumTier
│   │
│   ├── Data/            # Depends on Domain + Factory
│   │   ├── Network/     # FinnhubClient, APIEndpoint, DTOs
│   │   ├── Mappers/     # DTO → Domain model (DTOs never leave Data)
│   │   ├── Persistence/ # StockCache, WatchlistStore, RecentSearchStore
│   │   └── Repositories/# StockRepositoryImpl
│   │
│   └── Features/        # Depends on Domain + Factory
│       ├── Dashboard/   # Market overview, trending, movers
│       ├── StockDetail/ # Price, chart placeholder, stats, company info
│       ├── Search/      # Debounced search, recent history, trending
│       └── Watchlist/   # List, sort, swipe delete, total value
│
└── StockPulse/          # Main app target
    └── Core/
        ├── Navigation/  # Coordinators, AppRoute, deep links
        └── DI/          # AppContainer — all Factory registrations
```

### Dependency Rules

```
Domain ← Data       ✅  Data imports Domain
Domain ← Features   ✅  Features imports Domain
Data   ← Features   ❌  Features NEVER imports Data
Data   ← Domain     ❌  Domain NEVER imports Data
```

Anything shared between Data and Features (like `StockCacheProtocol`,
`CachePolicy`) lives in **Domain** — the only package everyone can import.

---

## Navigation Architecture

### The Problem We Solved

Standard SwiftUI navigation with a shared `ObservableObject` coordinator
causes a chain reaction:

```
path changes
  → coordinator @Published fires
    → AppCoordinator objectWillChange fires
      → AppCoordinatorView redraws
        → DashboardView @StateObject resets
          → NavigationPath clears  ← BUG 💥
```

### The Solution: Isolated Tab Views

Each tab is its own SwiftUI View with `@ObservedObject` on its coordinator.
Path changes only redraw that tab — nothing else.

```swift
// Each tab isolated — path changes never bubble up
private struct DashboardTab: View {
    @ObservedObject var coordinator: DashboardCoordinator
    @StateObject private var viewModel = Container.shared.dashboardViewModel()

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            DashboardView(viewModel: viewModel, ...)
                .navigationDestination(for: AppRoute.self) { ... }
        }
    }
}
```

```swift
// AppCoordinator — coordinators as plain var (NOT @Published)
final class AppCoordinator: ObservableObject {
    var dashboardCoordinator  = DashboardCoordinator()  // ✅ plain var
    var watchlistCoordinator  = WatchlistCoordinator()  // ✅ plain var

    @Published var activeTab: AppTab = .dashboard       // ✅ @Published
    @Published var isShowingAuth: Bool = false          // ✅ @Published
}
```

### Deep Links

```
stockpulse://stock/AAPL            → Stock Detail
stockpulse://search                → Search tab
https://stockpulse.com/stock/AAPL  → Universal Link → Stock Detail
```

---

## Caching Strategy

### Two-Level Cache

```
Request stock "AAPL"
       │
       ▼
┌─────────────────┐
│  Memory Cache   │ ← Dictionary, instant, app session only
│   (fastest)     │
└────────┬────────┘
    HIT  │  MISS
         ▼
┌─────────────────┐
│   Disk Cache    │ ← UserDefaults, survives app restart
│  (UserDefaults) │
└────────┬────────┘
    HIT  │  MISS
         ▼
┌─────────────────┐
│  Finnhub API    │ ← Network, concurrent (Finnhub 60/min)
│   (network)     │
└────────┬────────┘
         │ success
         ▼
  Save to memory + disk
```

### CachePolicy — One Flag Controls Everything

```swift
// Domain/CachePolicy.swift
// Change this ONE line to switch all behavior:
public static let current: CachePolicy = .premiumTier

//                    TTL      Fetch Strategy    Delay
// .freeTier       → 24hr    sequential        300ms  (Alpha Vantage)
// .premiumTier    → 60s     concurrent        none   (Finnhub)
```

### Two-Phase Loading

```swift
// Phase 1: Show cached data instantly — no spinner if cache is warm
await loadFromCacheInstantly()
if !data.isEmpty { isLoading = false }

// Phase 2: Fetch network silently — UI updates quietly
await fetchFromNetwork()
isLoading = false
```

---

## Dependency Injection

### Factory Pattern

```swift
// AppContainer.swift — single source of truth for all DI
extension Container {

    // Singleton — one instance for entire app lifetime
    var stockCache: Factory<StockCacheProtocol> {
        self { StockCache() }.singleton
    }

    // Use case — new instance each time (stateless)
    var fetchStockUseCase: Factory<FetchStockUseCaseProtocol> {
        self { FetchStockUseCase(repository: self.stockRepository()) }
    }

    // ViewModel — new instance per screen
    var stockDetailViewModel: Factory<StockDetailViewModel> {
        self {
            StockDetailViewModel(
                fetchStockUseCase: self.fetchStockUseCase(),
                fetchCompanyOverviewUseCase: self.fetchCompanyOverviewUseCase(),
                cache: self.stockCache()
            )
        }
    }
}
```

### Constructor Injection in Features

Features package cannot see `AppContainer` (that lives in the main app target).
So ViewModels declare their dependencies in `init()` — Factory wires them from outside.

```swift
// Features package — ViewModel declares what it needs
public final class DashboardViewModel: ObservableObject {
    private let fetchStockUseCase: any FetchStockUseCaseProtocol
    private let cache: any StockCacheProtocol

    public init(
        fetchStockUseCase: any FetchStockUseCaseProtocol,
        cache: any StockCacheProtocol
    ) {
        self.fetchStockUseCase = fetchStockUseCase
        self.cache = cache
    }
}

// Main app target — AppContainer wires it
var dashboardViewModel: Factory<DashboardViewModel> {
    self {
        DashboardViewModel(
            fetchStockUseCase: self.fetchStockUseCase(),
            cache: self.stockCache()
        )
    }
}
```

---

## Setup Instructions

### 1. Clone & Install Tools

```bash
git clone https://github.com/swetakadam/StockPulse.git
cd StockPulse

# Install XcodeGen
brew install xcodegen

# Generate .xcodeproj
xcodegen generate
```

### 2. Get a Free Finnhub API Key

1. Sign up at [finnhub.io](https://finnhub.io) — no credit card required
2. Copy your API key from the dashboard
3. Free tier: 60 API calls/minute

### 3. Configure Secrets

Create `Configurations/Secrets.xcconfig` (gitignored):

```
# Configurations/Secrets.xcconfig
FINNHUB_API_KEY=your_key_here
FINNHUB_DEV_KEY=your_key_here
FINNHUB_STG_KEY=your_key_here
FINNHUB_PROD_KEY=your_key_here
```

⚠️ No spaces around `=` in xcconfig files — spaces become part of the value!

### 4. Build & Run

```bash
# Open in Xcode
open StockPulse.xcodeproj

# Select Debug scheme → iPhone 17 Pro Max simulator → CMD+R
```

---

## Lessons Learned / Gotchas

### 1. xcconfig and Double Slash

xcconfig treats `//` as a comment character. URLs get truncated:
```
# WRONG — truncates to "https:"
FINNHUB_BASE_URL=https://finnhub.io/api/v1

# CORRECT — use $() to escape //
FINNHUB_BASE_URL=https:/$()/finnhub.io/api/v1
```

### 2. @MainActor on Class vs Methods

```swift
// WRONG — Factory closure is nonisolated, causes compile error:
// "Call to main actor-isolated initializer in nonisolated context"
@MainActor
public final class DashboardViewModel: ObservableObject { }

// CORRECT — annotate only the methods that update UI
public final class DashboardViewModel: ObservableObject {
    @MainActor public func loadDashboard() async { }
}
```

### 3. @Published Coordinators Cause Navigation Reset

If coordinators are `@Published` on `AppCoordinator`, every path change
triggers a full `AppCoordinatorView` redraw, resetting all `@StateObject`
ViewModels and clearing `NavigationPath`. Solution: plain `var`.

### 4. StockCacheProtocol Must Live in Domain

Both `Data` and `Features` need `StockCacheProtocol`. Since Features
cannot import Data, the protocol must live in `Domain` — the only
package both can import.

### 5. iOS 26 NSTaggedDate Crash

Default `JSONEncoder` date encoding causes crashes on iOS 26 when
reading from `UserDefaults`. Fix:
```swift
encoder.dateEncodingStrategy = .secondsSince1970
decoder.dateDecodingStrategy = .secondsSince1970
```

### 6. Concurrent Cache Writes Crash on iOS 26

Writing to a Dictionary inside a `queue.sync` read block causes
`EXC_CRASH`. Always separate reads from writes:
```swift
// Read
let result = queue.sync { memoryCache[symbol] }

// Write (separate call)
queue.sync(flags: .barrier) { memoryCache[symbol] = value }
```

### 7. Alpha Vantage vs Finnhub

We started with Alpha Vantage (25 calls/DAY free tier) and switched to
Finnhub (60 calls/MINUTE free tier). The `CachePolicy` enum and
`APIClientProtocol` abstraction made this a clean swap — only 4 files
changed, zero Domain or Features changes needed.

### 8. SPM Package Bundle vs App Bundle

`Bundle.main` inside an SPM package points to the package bundle,
not the app bundle. API keys from `Info.plist` won't be found.
Fix: pass `Bundle.main` explicitly from the main app target:
```swift
public init(bundle: Bundle = .main) throws {
    let info = bundle.infoDictionary  // works from main target
}
```

---

## Future Roadmap

- [ ] Real-time chart data (Finnhub premium candles endpoint)
- [ ] Push Notifications (APNs) — NavigationStateManager already wired
- [ ] Live Activities (ActivityKit) — stock price ticker
- [ ] Widget support (WidgetKit)
- [ ] AI Voice Assistant (WebRTC) — VoiceIntent enum future-proofed
- [ ] Unit tests for all Use Cases and ViewModels
- [ ] App icon and launch screen

---

## Project Stats

| Metric | Count |
|--------|-------|
| Swift files | 60+ |
| SPM packages | 3 (Domain, Data, Features) |
| Use cases | 10 |
| ViewModels | 4 |
| Screens | 4 (Dashboard, Detail, Search, Watchlist) |
| API endpoints | 5 |
| Lines of code | ~4,000 |

---

## Built With

- [SwiftUI](https://developer.apple.com/xcode/swiftui/)
- [Factory](https://github.com/hmlongco/Factory) — Dependency Injection
- [Finnhub API](https://finnhub.io) — Stock market data
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) — Project generation
- [Claude Code](https://claude.ai/code) — AI pair programming

---

*Built by Sweta Kadam — March 2026*
