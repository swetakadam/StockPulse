# StockPulse — Claude Code Guidelines

## Product Vision
StockPulse is a production-grade iOS stock market app for tracking
stocks, viewing price charts, and managing a personal watchlist.
Built as a learning project and architecture template for LoopNet.
Min deployment: iOS 17. Swift 5.9+. SwiftUI only, no UIKit.
Bundle ID: com.sweta.stockpulse

---

## ✅ Current Status (March 2026)

### Completed Phases
| Phase | Feature | Status |
|-------|---------|--------|
| 1 | Project Setup (XcodeGen, xcconfig, SPM) | ✅ |
| 2 | Domain Layer (Models, UseCases, Protocols) | ✅ |
| 3 | Data Layer (Network, Cache, Persistence) | ✅ |
| 4 | Navigation (Coordinators, Deep Links) | ✅ |
| 5 | Dashboard (Market overview, Trending, Movers) | ✅ |
| 6 | Stock Detail (Price, Stats, Company Info) | ✅ |
| 7 | Search (Debounced, Recent, Trending) | ✅ |
| 8 | Watchlist (List, Sort, Swipe Delete) | ✅ |
| 9 | AI Voice Assistant (WebRTC, tool calling, transcription) | ✅ |
| 10 | Agentic Research Engine (plan/reflect/synthesize + SEC 10-K) | ✅ |
| 11 | Polish and Testing | 🔄 In Progress |

### APIs
- **Finnhub** — stock data. Free tier: 60 calls/min. Auth via xcconfig token.
- **Azure OpenAI gpt-realtime-mini** — WebRTC voice session. Ephemeral token via APIM.
- **Azure OpenAI GPT-4.1 mini** — Agent planner/reflector/synthesizer/10-K parser. REST via APIM.
- **SEC EDGAR** — 10-K filings. Public, no API key. User-Agent header required.
  - `company_tickers.json` → CIK lookup
  - `submissions/{CIK}.json` → latest 10-K accession + primaryDocument filename
  - `Archives/edgar/data/{CIK}/{accession}/{file}.htm` → full filing HTML

---

## Architecture: MVVM + Clean Architecture

### Dependency Flow
```
SwiftUI View
    ↓
ViewModel (ObservableObject, constructor injection)
    ↓
Use Case Protocol (Domain)
    ↓
Use Case Implementation (Domain, pure Swift)
    ↓
Repository Protocol (Domain)
    ↓
Repository Implementation (Data)
    ↓
APIClient / Cache / Store (Data)
```

### Golden Rules
- Views contain ZERO business logic
- ViewModels use constructor injection — NO @Injected in Features package
- Use Case implementations: pure Swift, zero framework imports
- DTOs never leave the Data layer — always map to Domain models
- Features never import Data directly
- Domain never imports Data or Features
- Factory manages all DI — no Swift singletons

---

## Project Structure
```
StockPulse/
├── project.yml                          # XcodeGen source of truth
├── CLAUDE.md                            # This file
├── README.md                            # Architecture docs
├── Configurations/
│   ├── Base.xcconfig                    # FINNHUB_BASE_URL
│   ├── Debug.xcconfig                   # Dev keys
│   ├── Staging.xcconfig                 # Staging keys
│   ├── Release.xcconfig                 # Prod keys
│   └── Secrets.xcconfig                 # GITIGNORED — real keys
│
├── LocalPackages/
│   ├── Domain/                          # Zero external dependencies
│   │   └── Sources/Domain/
│   │       ├── Models/
│   │       │   ├── Stock.swift
│   │       │   ├── Quote.swift
│   │       │   ├── WatchlistItem.swift
│   │       │   ├── CompanyOverview.swift
│   │       │   └── RecentSearch.swift
│   │       ├── Repositories/
│   │       │   ├── StockRepositoryProtocol.swift
│   │       │   └── RecentSearchRepositoryProtocol.swift
│   │       ├── UseCases/Protocols/
│   │       ├── UseCases/Implementations/
│   │       ├── CachePolicy.swift
│   │       └── StockCacheProtocol.swift
│   │
│   ├── Data/                            # Depends on Domain + Factory
│   │   └── Sources/Data/
│   │       ├── Network/
│   │       │   ├── APIClient.swift      # FinnhubClient
│   │       │   ├── APIEndpoint.swift
│   │       │   └── DTOs/               # Internal — never leave Data
│   │       ├── Mappers/
│   │       │   └── StockMapper.swift
│   │       ├── Persistence/
│   │       │   ├── StockCache.swift
│   │       │   ├── WatchlistStore.swift
│   │       │   └── RecentSearchStore.swift
│   │       ├── Repositories/
│   │       │   └── StockRepositoryImpl.swift
│   │       │   └── SECRepositoryImpl.swift  # fetchCIK, fetchLatest10KAccession, fetchSectionText (HTML cache)
│   │       └── Network/SEC/
│   │           ├── SECClient.swift          # EDGAR API: CIK lookup, submissions, raw HTML download
│   │           ├── SECEndpoint.swift        # URL definitions for EDGAR endpoints
│   │           └── TenKParser.swift         # Closure-injected LLM parser
│   │
│   └── Features/                        # Depends on Domain + Factory
│       └── Sources/Features/
│           ├── Dashboard/
│           │   ├── Views/
│           │   └── ViewModels/
│           ├── StockDetail/
│           │   ├── Views/
│           │   └── ViewModels/
│           ├── Search/
│           │   ├── Views/
│           │   └── ViewModels/
│           └── Watchlist/
│               ├── Views/
│               └── ViewModels/
│
└── StockPulse/                          # Main app target
    ├── StockPulseApp.swift
    ├── Info.plist
    ├── Assets.xcassets
    └── Core/
        ├── Navigation/
        │   ├── AppCoordinator.swift
        │   ├── AppCoordinatorView.swift
        │   ├── AppRoute.swift
        │   ├── AppRoute.swift
        │   ├── CoordinatorProtocol.swift
        │   ├── RouterProtocol.swift
        │   ├── NavigationStateManager.swift
        │   ├── VoiceIntent.swift
        │   ├── SheetRoute.swift
        │   ├── AuthCoordinator.swift
        │   ├── DashboardCoordinator.swift
        │   ├── SearchCoordinator.swift
        │   ├── WatchlistCoordinator.swift
        │   ├── StockDetailCoordinator.swift
        │   └── SheetCoordinator.swift
        ├── Agent/
        │   ├── AzureChatConfig.swift    # GPT-4.1 mini endpoint + api-key from xcconfig
        │   ├── AzureChatClient.swift    # plan/reflect/synthesize/parseSection (class, not final — subclassable for tests)
        │   ├── AgentModels.swift        # AgentPlan, AgentStep, AgentContext, AgentDecision, AgentToolSchema
        │   ├── AgentToolRegistry.swift  # 6 tools wired to Domain use cases
        │   ├── AgentOrchestrator.swift  # plan→execute→reflect loop, progressHandler for UI
        │   └── AgentMemory.swift        # SwiftData model: StoredAgentResult
        ├── DI/
        │   └── AppContainer.swift       # ALL Factory registrations
        ├── DesignSystem/
        └── Utilities/
```

---

## Dependency Injection: Factory

### Registration Pattern
```swift
// AppContainer.swift — ALL registrations here
extension Container {

    // Singletons — shared instance across app
    var stockCache: Factory<StockCacheProtocol> {
        self { StockCache() }.singleton
    }
    var recentSearchStore: Factory<RecentSearchRepositoryProtocol> {
        self { RecentSearchStore() }.singleton
    }

    // Use cases — new instance per call
    var fetchStockUseCase: Factory<FetchStockUseCaseProtocol> {
        self { FetchStockUseCase(repository: self.stockRepository()) }
    }

    // ViewModels — new instance per screen
    var dashboardViewModel: Factory<DashboardViewModel> {
        self {
            DashboardViewModel(
                fetchStockUseCase: self.fetchStockUseCase(),
                fetchWatchlistUseCase: self.fetchWatchlistUseCase(),
                cache: self.stockCache()
            )
        }
    }
}
```

### Constructor Injection in Features (REQUIRED)
```swift
// CORRECT — Features package cannot see AppContainer keys
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

// WRONG — @Injected not visible in Features package
@Injected(\.fetchStockUseCase) private var fetchStockUseCase
```

### @MainActor Rule
```swift
// WRONG — causes Factory init error in nonisolated context
@MainActor
public final class DashboardViewModel: ObservableObject { }

// CORRECT — annotate methods that update @Published properties
public final class DashboardViewModel: ObservableObject {
    @MainActor public func loadDashboard() async { }
    @MainActor public func refreshDashboard() async { }
}
```

---

## Navigation Architecture

### Pattern: Isolated Tab Coordinators
Each tab is its own SwiftUI View observing its coordinator via
@ObservedObject. This isolates redraws — path changes in one tab
never cause other tabs or AppCoordinatorView to redraw.

```swift
// CORRECT — isolated tab, no cross-tab redraws
private struct DashboardTab: View {
    @ObservedObject var coordinator: DashboardCoordinator
    @StateObject private var viewModel = Container.shared.dashboardViewModel()

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            DashboardView(
                viewModel: viewModel,
                onStockTapped: { symbol in
                    coordinator.navigate(to: .stockDetail(symbol: symbol))
                }
            )
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .stockDetail(let symbol):
                    StockDetailView(
                        viewModel: Container.shared.stockDetailViewModel(),
                        symbol: symbol
                    )
                default: EmptyView()
                }
            }
        }
    }
}

// WRONG — coordinator as @Published on AppCoordinator causes
// chain reaction: path change → AppCoordinator publishes →
// AppCoordinatorView redraws → @StateObject resets → path clears
@Published var dashboardCoordinator = DashboardCoordinator()
```

### Coordinator Rules
```swift
// AppCoordinator — coordinators as plain var (NOT @Published)
var dashboardCoordinator  = DashboardCoordinator()
var watchlistCoordinator  = WatchlistCoordinator()
var searchCoordinator     = SearchCoordinator()

// Only tab selection and auth are @Published
@Published var activeTab: AppTab = .dashboard
@Published var isShowingAuth: Bool = false
```

### Deep Link Format
```
stockpulse://stock/AAPL            → Stock Detail
stockpulse://search                → Search tab
https://stockpulse.com/stock/AAPL  → Stock Detail (Universal Link)
```

### AppRoute
```swift
enum AppRoute: Hashable {
    case dashboard
    case stockDetail(symbol: String)
    case search
    case watchlist
    case notifications
    case notification(userInfo: [String: String])
}
```

---

## Caching Strategy

### Two-Level Cache (StockCache)
```
1. Memory cache (Dictionary)  → instant, app session lifetime
        ↓ miss
2. Disk cache (UserDefaults)  → fast, survives app restart
        ↓ miss
3. Network (Finnhub API)      → concurrent (premiumTier policy)
        ↓ success
   Save to memory + disk
```

### CachePolicy — Single Flag to Rule All Behavior
```swift
// Domain/CachePolicy.swift
// Change this ONE line to switch behavior:
public static let current: CachePolicy = .premiumTier

// freeTier    → 24hr TTL, sequential fetch (Alpha Vantage 25/day)
// premiumTier → 60s TTL, concurrent fetch (Finnhub 60/min)
```

### Two-Phase Loading Pattern (Dashboard, StockDetail)
```swift
public func loadDashboard() async {
    isLoading = true

    // Phase 1: Serve cache instantly — hide spinner if data exists
    await loadFromCacheInstantly()
    if !trendingStocks.isEmpty { isLoading = false }

    // Phase 2: Fetch network silently — UI updates quietly
    trendingStocks = await fetchStocks(symbols: trendingSymbols)
    // ...

    isLoading = false // always false when done
}
```

---

## API: Finnhub

### Endpoints Used
| Endpoint | Path | Used For | Free? |
|----------|------|----------|-------|
| Quote | /quote | Price, change, high, low | ✅ |
| Profile | /stock/profile2 | Company name, logo, sector | ✅ |
| Metrics | /stock/metric | P/E, EPS, 52W High/Low | ✅ |
| Search | /search | Symbol search | ✅ |
| Candles | /stock/candle | Chart data | ❌ Premium |

### Auth + xcconfig
```
Base URL: https://finnhub.io/api/v1
Auth:     ?token=YOUR_KEY

# In Base.xcconfig — use $() to escape // (xcconfig treats // as comment)
FINNHUB_BASE_URL=https:/$()/finnhub.io/api/v1
FINNHUB_API_KEY=your_key_here  ← in Secrets.xcconfig (gitignored)
```

### Curl Logging (built in)
```
🌐 Cache MISS: AAPL — will fetch from network
🌐 REQUEST curl -X GET 'https://finnhub.io/api/v1/quote?symbol=AAPL&token=[REDACTED]'
✅ RESPONSE 200: https://finnhub.io/api/v1/quote?symbol=AAPL
💾 Saved: AAPL TTL:86400.000000s
💾 Memory HIT: AAPL
```

---

## Build Configurations

| Scheme | Config | Bundle ID |
|--------|--------|-----------|
| Debug | Debug | com.sweta.stockpulse.debug |
| Staging | Staging | com.sweta.stockpulse.staging |
| Release | Release | com.sweta.stockpulse |

---

## Design System

### Glass Card — iOS 26 + iOS 17 Fallback
```swift
// GlassCardModifier.swift — apply with .glassCard()
if #available(iOS 26, *) {
    content.glassEffect(
        .regular.tint(.clear),
        in: RoundedRectangle(cornerRadius: 16)
    )
} else {
    content
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
}
```

### Colors
```swift
Color(.systemGreen)  // positive price change
Color(.systemRed)    // negative price change
.primary             // primary text
.secondary           // supporting text
.tint                // accent / interactive
```

### Animations
```swift
.animation(.spring(response: 0.3, dampingFraction: 0.7), value: x)
.transition(.opacity.combined(with: .move(edge: .bottom)))
```

### Generic ViewModel Pattern (testability)
```swift
// Views are generic over their ViewModel protocol
struct DashboardView<ViewModel: DashboardViewModelProtocol>: View {
    @StateObject var viewModel: ViewModel
}

// Production
DashboardView(viewModel: DashboardViewModel(...))

// Preview / Test
DashboardView(viewModel: MockDashboardViewModel())
```

---

## ⚠️ Critical Rules

1. **NEVER modify .pbxproj** — run `xcodegen generate` instead
2. **After ANY new .swift file** — run `xcodegen generate`
3. **No business logic in Views** — ViewModels only
4. **No @Injected in Features** — use constructor injection
5. **No Data imports in Features** — Domain only
6. **async/await only** — no callbacks or Combine unless required
7. **Every ViewModel has a protocol** — for testability + previews
8. **API key never hardcoded** — always via xcconfig → Bundle
9. **DTOs never leave Data** — always map to Domain models
10. **Tab ViewModels are @StateObject in tab views** — created once
11. **Screen ViewModels via Factory** — new instance per navigation
12. **xcconfig URL fix** — use $()/ for URLs containing //
13. **@MainActor on methods, not class** — avoids Factory init errors
14. **Coordinators are plain var on AppCoordinator** — NOT @Published

---

## Common Pitfalls & Fixes

### @MainActor isolation error in Factory
```swift
// Error: Call to main actor-isolated initializer in nonisolated context
// Fix: Remove @MainActor from class, add to async methods only
@MainActor public func loadDashboard() async { }
```

### xcconfig URL truncated (shows https: instead of https://...)
```
# Fix: Use $() to escape double slash
FINNHUB_BASE_URL=https:/$()/finnhub.io/api/v1
```

### Navigation path resets on tap
```
# Fix: Coordinators must be plain var (not @Published) on AppCoordinator
# Fix: Each tab must be isolated view with @ObservedObject coordinator
```

### Cache miss on app relaunch (NSTaggedDate crash on iOS 26)
```swift
// Fix: Use .secondsSince1970 date encoding strategy
encoder.dateEncodingStrategy = .secondsSince1970
decoder.dateDecodingStrategy = .secondsSince1970
```

### EXC_CRASH on dictionary mutation in cache
```swift
// Fix: Separate read (queue.sync) from write (queue.sync flags: .barrier)
// Never mutate inside a read block
```

### StockCacheProtocol / CachePolicy not visible in Features
```
// Fix: Place shared protocols in Domain (not Data)
// Both Data and Features can import Domain
```

### EDGAR `fiscalYearEnd` guard always fails
```swift
// WRONG — fiscalYearEnd is at company root level, not inside recent[]
guard let fiscalYearEnds = recent["fiscalYearEnd"] as? [String] else { throw }

// FIX — remove from guard; use recent["primaryDocument"] for the HTM filename
if let primaryDocs = recent["primaryDocument"] as? [String], idx < primaryDocs.count {
    docURL = URL(string: ".../\(primaryDocs[idx])")!
}
```

### 10-K HTML — section content is never in first 8,000 chars
The raw 10-K HTM starts with DOCTYPE + CSS, not filing content.
Strip all `<[^>]+>` tags first, then search for the section anchor
("ITEM 1.", "ITEM 1A.", "ITEM 7.", "ITEM 8."), and extract 25,000 chars from there.

### OSLog `.debug` is suppressed in simulator log stream by default
Use `logger.info()` for anything you need to observe in testing.
Log stream command: `xcrun simctl spawn booted log stream --predicate 'subsystem == "com.sweta.stockpulse"' --level info`

### AzureChatClient must be `class`, not `final class`
Tests subclass it to inject mock responses. Do not make it `final`.

---

## Testing Strategy
- Framework: Swift Testing (@Test attribute)
- Every UseCase: unit tests with mock repository
- Every ViewModel: unit tests with mock use cases
- MockAPIClient for all network tests
- Previews use MockViewModel — never live data

```bash
# Run all tests
xcodebuild test -scheme StockPulse \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max'
```

---

## Known Limitations & TODOs
- [ ] Chart data requires Finnhub premium (candles endpoint)
- [ ] Company names show symbol until profile endpoint loads
- [ ] Auth flow is placeholder
- [ ] Notifications tab is placeholder
- [ ] Unit tests (Phase 11)
- [ ] App icon + launch screen (Phase 11)
- [ ] Push notifications not wired
- [ ] Agent synthesis length — GPT-4.1 mini tends to produce 3-sentence summaries despite longer-form instructions
- [ ] AgentMemory not yet used for cache lookups — stored but not read back
- [ ] Agent planner only fetches "business" 10-K section; riskFactors/mdAndA require explicit user ask

## Future Features (designed for, not built)
- Push Notifications (APNs) — NavigationStateManager ready
- Live Activities (ActivityKit)
- Widget support (WidgetKit)
- Universal Links — AppCoordinator.handleUniversalLink() ready
- Multi-turn research memory — AgentMemory SwiftData model is ready, use it to skip re-fetching
