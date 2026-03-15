# StockPulse — Claude Code Prompts Reference

All prompts used during StockPulse development, organized by phase.
Use these as templates for future projects like LoopNet.

---

## How to Use These Prompts

1. Start with `/plan` in Claude Code terminal
2. Paste the prompt
3. Review the plan carefully before approving
4. Type `yes` or `go` to execute
5. Run `xcodegen generate` after execution
6. Build with CMD+B in Xcode

---

## Phase 1 — Project Setup

### XcodeGen + xcconfig + SPM Packages
```
Read CLAUDE.md carefully before planning.
Set up the StockPulse iOS project with:
- XcodeGen project.yml with Debug/Staging/Release schemes
- xcconfig files for each scheme
- Secrets.xcconfig (gitignored) for API keys
- 3 local SPM packages: Domain, Data, Features
- Factory dependency (hmlongco/Factory 2.3.0)
- Bundle ID: com.sweta.stockpulse
- Team ID: 2RB6B6Z8G3
- Min iOS: 17.0

Do NOT create anything yet. Wait for my approval.
```

---

## Phase 2 — Domain Layer

### Models + Repository Protocols + Use Cases
```
Read CLAUDE.md carefully before planning.
Create the Domain layer for StockPulse.
Do NOT modify Package.swift or .pbxproj files.

Files to create in LocalPackages/Domain/Sources/Domain/:

Models/Stock.swift — Stock, Quote, WatchlistItem structs + StockDomainError + mock data
Repositories/StockRepositoryProtocol.swift — 6 async/await methods
UseCases/Protocols/ — FetchStockUseCaseProtocol, SearchStocksUseCaseProtocol,
                      FetchWatchlistUseCaseProtocol, AddToWatchlistUseCaseProtocol,
                      RemoveFromWatchlistUseCaseProtocol
UseCases/Implementations/ — All 5 implementations (pure Swift, zero framework imports)

Business rules:
- AddToWatchlist: validate → dedup (silent) → size check (50 max) → persist
- RemoveFromWatchlist: validate → idempotent check → remove
- FetchWatchlist: sorts by addedAt descending
- SearchStocks: trims whitespace, throws emptyQuery if empty
- FetchStock: throws notFound if empty result

Show complete file contents. Do NOT create yet. Wait for my approval.
```

---

## Phase 3 — Data Layer

### Network + DTOs + Mappers + Persistence
```
Read CLAUDE.md carefully before planning.
Create the Data layer for StockPulse.
Do NOT modify Package.swift or .pbxproj files.

Files to create in LocalPackages/Data/Sources/Data/:

Network/NetworkError.swift — rich error enum with isRetryable + requiresReauth
Network/APIEndpoint.swift — all endpoints as public enum
Network/APIClient.swift — APIClientProtocol + FinnhubClient
                          reads FINNHUB_API_KEY from Bundle.main
                          accepts bundle parameter for SPM compatibility
Network/DTOs/ — internal DTOs (never leave Data layer)
Mappers/StockMapper.swift — DTO → Domain model mapping
Persistence/WatchlistStore.swift — WatchlistStoreProtocol + UserDefaultsWatchlistStore
                                    with DispatchQueue serial queue
Repositories/StockRepositoryImpl.swift — implements StockRepositoryProtocol

All types must be public.
DTOs and StockMapper remain internal.
Do NOT create yet. Wait for my approval.
```

---

## Phase 4 — Navigation Layer

### Coordinators + Deep Links + Voice Intent
```
Read CLAUDE.md carefully before planning.
Plan the Navigation layer for StockPulse.
Do NOT create anything yet.
Do NOT modify any Package.swift or .pbxproj files.

Create 15 files in StockPulse/Core/Navigation/:

1. AppRoute.swift — enum: dashboard, stockDetail(symbol:), search, watchlist,
                    notifications, notification(userInfo:[String:String])
2. SheetRoute.swift — enum Identifiable+Hashable: addToWatchlist(symbol:),
                      stockFilter, settings, authFlow
3. VoiceIntent.swift — future AI: navigate, search, addToWatchlist,
                        removeFromWatchlist, dismiss, goBack, goHome, unknown
4. CoordinatorProtocol.swift — base protocol
5. RouterProtocol.swift — extends CoordinatorProtocol+ObservableObject
6. NavigationStateManager.swift — singleton bridge for Push/AppIntents/AI Voice
7. AuthCoordinator.swift
8. DashboardCoordinator.swift — deep link parsing for stockpulse:// and https://
9. StockDetailCoordinator.swift
10. WatchlistCoordinator.swift
11. SearchCoordinator.swift
12. SheetCoordinator.swift
13. AppCoordinator.swift — root coordinator, Combine observation
14. AppCoordinatorView.swift — TabView with per-tab NavigationStack
15. StockPulseApp.swift — @main entry point

Show complete file contents. Do NOT create yet. Wait for my approval.
```

---

## Phase 5 — Dashboard Feature

### ViewModel + 8 Views + Glass Cards
```
Read CLAUDE.md carefully before planning.
Plan the Dashboard feature for StockPulse.
Do NOT create anything yet.
Do NOT modify any Package.swift or .pbxproj files.

All View files go in:
LocalPackages/Features/Sources/Features/Dashboard/Views/
All ViewModel files go in:
LocalPackages/Features/Sources/Features/Dashboard/ViewModels/

DESIGN SYSTEM RULES:
- Liquid glass: use .glassEffect() on iOS 26+,
  fallback to .ultraThinMaterial + blur on iOS 17+
- Create GlassCardModifier handling both with #available(iOS 26, *)
- Dark mode: all colors use Color assets or adaptive colors
- Green = positive: Color(.systemGreen)
- Red = negative: Color(.systemRed)
- Animations: .spring(response: 0.3, dampingFraction: 0.7)
- Every View must have #Preview using mock data

ARCHITECTURE RULES:
- Views contain ZERO business logic
- ViewModels use constructor injection (no @Injected in Features)
- ViewModels are final class conforming to ObservableObject
- Each ViewModel has a protocol for testability
- DashboardView is generic: DashboardView<ViewModel: DashboardViewModelProtocol>

Plan these 9 files:
1. DashboardViewModel.swift — MarketIndex struct, protocol, @MainActor methods
2. GlassCardModifier.swift — iOS 26 native + ultraThinMaterial fallback
3. MarketIndexCard.swift — S&P 500, NASDAQ, DOW cards with sparkline placeholder
4. MarketOverviewSection.swift — horizontal scroll, .scrollTargetBehavior
5. StockRowView.swift — reusable row, green/red pill, price change animation
6. TrendingStocksSection.swift — horizontal scroll cards with .glassCard()
7. WatchlistPreviewSection.swift — max 5 items, empty state
8. GainersLosersSection.swift — segmented control, spring animation
9. DashboardView.swift — generic ViewModel, loading/error/content states,
                          greeting by time of day, .refreshable, .task

Show complete file contents. Do NOT create yet. Wait for my approval.
```

### Fix @Injected Errors (Constructor Injection)
```
Fix the @Injected compile errors in DashboardViewModel.
Do NOT modify any other files.

ROOT CAUSE:
@Injected(\.fetchStockUseCase) requires Container keys visible in Features.
Container extension is in AppContainer.swift (main target).
Features package cannot see main target — causes compile errors.

FIX — Constructor Injection (industry standard Clean Architecture):

FILE 1 — DashboardViewModel.swift:
- Remove: import Factory
- Remove both @Injected properties
- Add public init with explicit dependencies:
  public init(
      fetchStockUseCase: any FetchStockUseCaseProtocol,
      fetchWatchlistUseCase: any FetchWatchlistUseCaseProtocol,
      cache: any StockCacheProtocol
  )
- Store as private let properties
- Remove @MainActor from class declaration
- Add @MainActor to loadDashboard() and refreshDashboard() only

FILE 2 — AppContainer.swift:
Add Factory registration:
var dashboardViewModel: Factory<DashboardViewModel> {
    self {
        DashboardViewModel(
            fetchStockUseCase: self.fetchStockUseCase(),
            fetchWatchlistUseCase: self.fetchWatchlistUseCase(),
            cache: self.stockCache()
        )
    }
}

Show complete updated files. Wait for my approval.
```

### Fix GlassCardModifier iOS 26 Shape
```
Fix 3 UI bugs in the Dashboard.
Do NOT modify any other files.

BUG 1 — GlassCardModifier.swift:
iOS 26 .glassEffect() defaults to circle/capsule shape.
Fix with explicit shape:
if #available(iOS 26, *) {
    content.glassEffect(.regular.tint(.clear),
                        in: RoundedRectangle(cornerRadius: 16))
} else {
    content
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
}

BUG 2 — TrendingStocksSection.swift:
Add .frame(height: 180) to the ScrollView for explicit height.

BUG 3 — DashboardViewModel.swift:
withTaskGroup returns results in completion order.
Fix fetchStocks() to preserve order using (Int, Stock?) index tuples.

Wait for my approval.
```

---

## Phase 5 — Caching Layer

### CachePolicy + StockCache + Two-Phase Loading
```
Read CLAUDE.md carefully before planning.
Build a full caching layer for StockPulse.
Do NOT modify Package.swift or .pbxproj files.

CONTEXT:
Alpha Vantage free tier = 25 API calls per DAY (later switched to Finnhub).
We need CachePolicy.current flag controlling:
1. Cache TTL (24hr free / 60s premium)
2. Fetch strategy (sequential free / concurrent premium)
3. Cache-first vs network-first loading

IMPORTANT DI RULE:
StockCache must NOT use Swift singleton (no static shared).
Register in AppContainer via Factory .singleton scope.

Files to create/modify:
1. Domain/CachePolicy.swift — freeTier/premiumTier enum, single flag
2. Domain/StockCacheProtocol.swift — in Domain so both Data+Features can import
3. Data/Persistence/StockCache.swift — two-level cache, concurrent DispatchQueue
                                       barrier writes, .secondsSince1970 dates
4. Data/Repositories/StockRepositoryImpl.swift — cache-first pattern
5. Features/Dashboard/ViewModels/DashboardViewModel.swift — policy-based fetch
6. AppContainer.swift — stockCache Factory .singleton, inject into repository

KEY PATTERNS:
- stock(for:): separate read queue.sync from write queue.sync(flags:.barrier)
- save(): queue.sync(flags:.barrier) — synchronous so backgrounding doesn't lose data
- Two-phase loading: cache instantly → network silently
- hasLoadedOnce guard prevents tab-switch reloads
- refreshDashboard() calls cache.invalidateAll() then reloads

Show complete file contents. Do NOT create yet. Wait for my approval.
```

---

## Phase 6 — Stock Detail

### ViewModel + 5 Views + Finnhub Metrics
```
Read CLAUDE.md carefully before planning.
Build the Stock Detail feature for StockPulse.
Do NOT modify Package.swift or .pbxproj files.

CONTEXT:
- GlassCardModifier already exists in Features/Dashboard/Views/
- CachePolicy.current = .premiumTier (Finnhub 60/min)
- Candles endpoint requires Finnhub premium — show placeholder

FINNHUB ENDPOINTS FOR STOCK DETAIL:
- /quote — price, change (already cached, 0 extra calls)
- /stock/profile2 — company name, logo, sector (1 call, cache 24hr)
- /stock/metric — P/E, EPS, 52W High/Low, avg volume (1 call, cache 24hr)

Domain files to create:
- Models/CompanyOverview.swift — + PricePoint + TimeRange enum
- UseCases/Protocols/FetchCompanyOverviewUseCaseProtocol.swift
- UseCases/Protocols/FetchTimeSeriesUseCaseProtocol.swift
- UseCases/Implementations/FetchCompanyOverviewUseCase.swift
- UseCases/Implementations/FetchTimeSeriesUseCase.swift
- Modify StockRepositoryProtocol — add fetchCompanyOverview + fetchTimeSeries

Data files to create:
- DTOs/OverviewDTO.swift — FinnhubProfileDTO
- DTOs/DailyTimeSeriesDTO.swift — FinnhubCandleDTO (arrays not dict)
- Modify APIEndpoint — add .overview, .timeSeries, .metrics cases
- Modify StockRepositoryImpl — implement 2 new methods, cache overview

Features files to create:
- StockDetail/ViewModels/StockDetailViewModel.swift — two-phase loading,
                          isInWatchlist check on load, fetchWatchlistUseCase
- StockDetail/Views/PriceHeaderView.swift — logo via AsyncImage, star button
- StockDetail/Views/PriceChartView.swift — Swift Charts, premium placeholder
- StockDetail/Views/KeyStatsView.swift — LazyVGrid, all metrics fields
- StockDetail/Views/CompanyInfoView.swift — expandable description
- StockDetail/Views/StockDetailView.swift — generic ViewModel, two-phase

AppContainer — add stockDetailViewModel Factory (no symbol parameter)

Show complete file contents. Do NOT create yet. Wait for my approval.
```

---

## Phase 6 — API Swap (Alpha Vantage → Finnhub)

### Swap API Layer
```
Read CLAUDE.md carefully before planning.
Swap Alpha Vantage API for Finnhub API.
Only modify Data layer — Domain and Features unchanged.
Do NOT modify Package.swift or .pbxproj files.

FINNHUB API FORMAT:
Base URL: https://finnhub.io/api/v1
Auth: query param ?token=API_KEY
Rate limit: 60 calls/minute free tier

ENDPOINTS:
Quote:    GET /quote?symbol=AAPL
          { "c": 150.0, "d": 1.5, "dp": 1.01, "h": 151.0,
            "l": 149.0, "o": 149.5, "pc": 148.5 }

Profile:  GET /stock/profile2?symbol=AAPL
          { "name": "Apple Inc", "ticker": "AAPL",
            "finnhubIndustry": "Technology",
            "marketCapitalization": 2800000.0, "logo": "..." }

Candles:  GET /stock/candle?symbol=AAPL&resolution=D&from=UNIX&to=UNIX
          { "c": [...], "h": [...], "l": [...], "o": [...],
            "t": [...], "s": "ok" }
          NOTE: if s == "no_data" treat as empty

Search:   GET /search?q=apple
          { "count": 2, "result": [{"symbol":"AAPL","description":"Apple Inc"}] }

Metrics:  GET /stock/metric?symbol=AAPL&metric=all
          { "metric": { "52WeekHigh": 199.62, "52WeekLow": 164.08,
                        "epsTTM": 6.43, "10DayAverageTradingVolume": 58.2 } }

Files to modify:
1. APIClient.swift — rename to FinnhubClient, read FINNHUB_API_KEY,
                     auth via ?token= param, add path to URL building
2. APIEndpoint.swift — replace all cases, add path property
3. All DTOs — replace with Finnhub field names
4. StockMapper.swift — update all mapping methods for Finnhub DTOs
5. StockRepositoryImpl.swift — update all method implementations
6. AppContainer.swift — update apiClient factory

Also update Secrets.xcconfig:
FINNHUB_API_KEY=your_key
Base.xcconfig:
FINNHUB_BASE_URL=https:/$()/finnhub.io/api/v1

Show complete file contents. Wait for my approval.
```

---

## Navigation Fix

### Isolated Tab Coordinators
```
Rewrite AppCoordinatorView.swift to fix navigation.

ROOT CAUSE:
AppCoordinatorView uses @EnvironmentObject AppCoordinator.
When dashboardCoordinator.path changes, AppCoordinator
objectWillChange fires, AppCoordinatorView redraws,
DashboardView @StateObject resets, path clears.

CORRECT FIX:
Extract each tab into its own View with @ObservedObject
on its coordinator directly. Path changes only redraw
that tab — never AppCoordinatorView.

Create isolated tab structs:
- DashboardTab: @ObservedObject coordinator, @StateObject viewModel
- WatchlistTab: @ObservedObject coordinator, @StateObject viewModel
- SearchTab: @ObservedObject coordinator, @StateObject viewModel

Each tab has its own NavigationStack bound to its coordinator.path.
Each tab has .navigationDestination for AppRoute.

Also fix AppCoordinator.swift:
Change coordinator properties from @Published to plain var:
var dashboardCoordinator  = DashboardCoordinator()  // NOT @Published
var watchlistCoordinator  = WatchlistCoordinator()  // NOT @Published
var searchCoordinator     = SearchCoordinator()     // NOT @Published

Keep @Published only for:
@Published var activeTab: AppTab = .dashboard
@Published var isShowingAuth: Bool = false

Wait for my approval.
```

---

## Phase 7 — Search Feature

### Full Search with Clean Architecture
```
Read CLAUDE.md carefully before planning.
Build the Search feature for StockPulse with Clean Architecture.
No direct UserDefaults in ViewModel — use use cases.
Do NOT modify Package.swift or .pbxproj files.

DOMAIN LAYER — RecentSearch:
- Models/RecentSearch.swift — Codable, Identifiable, Equatable
- Repositories/RecentSearchRepositoryProtocol.swift
- UseCases/Protocols/FetchRecentSearchesUseCaseProtocol.swift
- UseCases/Protocols/SaveRecentSearchUseCaseProtocol.swift
- UseCases/Protocols/ClearRecentSearchesUseCaseProtocol.swift
- UseCases/Implementations/FetchRecentSearchesUseCase.swift
- UseCases/Implementations/SaveRecentSearchUseCase.swift
- UseCases/Implementations/ClearRecentSearchesUseCase.swift

DATA LAYER:
- Persistence/RecentSearchStore.swift — UserDefaults, max 10, dedup,
                                         newest first, JSONEncoder/Decoder

FEATURES LAYER:
- Search/ViewModels/SearchViewModel.swift
  * Protocol + implementation
  * Debounced search: 300ms Task.sleep, Task cancellation on new keystroke
  * Constructor injection for all 5 use cases
  * trendingSymbols: ["AAPL","MSFT","GOOGL","TSLA","NVDA","META","AMZN","BRK.B"]
  * @MainActor on methods (not class) to avoid Factory init error

- Search/Views/SearchResultRow.swift — symbol circle avatar, watchlist button
- Search/Views/RecentSearchesView.swift — clock icon, remove + clear all
- Search/Views/TrendingSearchesView.swift — LazyVGrid 4 columns, glass cards
- Search/Views/SearchView.swift — .searchable modifier, .onChange debounce,
                                   empty state shows recent + trending,
                                   generic SearchView<ViewModel>

APPCONTAINER — register all search use cases + searchViewModel
APPCOORDINATORVIEW — update SearchTab with real SearchView

Show complete file contents. Do NOT create yet. Wait for my approval.
```

---

## Phase 8 — Watchlist Feature

### Full Watchlist with Sort + Swipe Delete
```
Read CLAUDE.md carefully before planning.
Build the Watchlist feature for StockPulse.
Do NOT modify Package.swift or .pbxproj files.

CONTEXT:
- FetchWatchlistUseCase, AddToWatchlistUseCase,
  RemoveFromWatchlistUseCase all exist in Domain
- FetchStockUseCase exists for fetching live prices
- WatchlistCoordinator exists in Core/Navigation
- Design: clean list style like native Stocks app
- No hasLoadedOnce guard — watchlist is small, always reload on appear

FEATURES:
- List of watched stocks with live price + change
- Swipe to delete with .destructive role
- Tap stock → Stock Detail
- Total value header (sum of all current prices)
- Sort menu: by name, price, change%
- Empty state with button to go to Search tab
- Pull to refresh

Files to create:
- Watchlist/ViewModels/WatchlistViewModel.swift
  * WatchlistSortOption enum: name, price, changePercent
  * Protocol + implementation
  * Constructor injection
  * Two-phase loading: cache first, network fills gaps
  * sortedStocks computed property
  * totalValue computed property
  * @MainActor on async methods

- Watchlist/Views/WatchlistHeaderView.swift — total value + stock count
- Watchlist/Views/WatchlistRowView.swift — clean row, solid color pill
- Watchlist/Views/WatchlistEmptyView.swift — star.slash icon, search button
- Watchlist/Views/WatchlistView.swift — List with .insetGrouped style,
                                         swipeActions, sort Menu toolbar,
                                         generic WatchlistView<ViewModel>

AppContainer — watchlistViewModel Factory
AppCoordinatorView — update WatchlistTab with real WatchlistView
                     pass onSearchTapped → appCoordinator.activeTab = .search

Show complete file contents. Do NOT create yet. Wait for my approval.
```

---

## Common Fix Prompts

### Fix @MainActor Factory Error
```
Fix MainActor isolation error in: [FILE PATH]

ERROR:
Call to main actor-isolated initializer in synchronous nonisolated context

FIX:
Remove @MainActor from class declaration.
Add @MainActor only to methods that update @Published properties:

@MainActor public func loadDashboard() async
@MainActor public func refreshDashboard() async

Also add @MainActor to protocol method signatures.
Do NOT change anything else.
```

### Fix xcconfig URL Truncation
```
Fix URL truncation in xcconfig.

PROBLEM:
xcconfig treats // as a comment — URL gets truncated to "https:"

FIX in Base.xcconfig:
FINNHUB_BASE_URL=https:/$()/finnhub.io/api/v1

The $() is the standard xcconfig workaround for //.
```

### Fix iOS 26 NSTaggedDate Crash
```
Fix NSInvalidArgumentException crash in: [CACHE FILE]

CRASH: '-[__NSTaggedDate count]: unrecognized selector'
Occurs when decoding CachedStock from UserDefaults on iOS 26.

FIX — Use explicit date encoding strategy:
private func saveToDisk(_ cached: CachedStock, symbol: String) {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .secondsSince1970
    guard let data = try? encoder.encode(cached) else { return }
    defaults.set(data, forKey: diskKey(symbol))
}

private func loadFromDisk(symbol: String) -> CachedStock? {
    guard let data = defaults.data(forKey: diskKey(symbol)) else { return nil }
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .secondsSince1970
    return try? decoder.decode(CachedStock.self, from: data)
}
```

### Fix Cache Read/Write Race Crash
```
Fix EXC_CRASH on cache queue in: [CACHE FILE]

CRASH: Dictionary mutation inside read block.

FIX — Separate read from write:
public func stock(for symbol: String) -> Stock? {
    // Step 1: Read only — no mutations
    let result: (stock: Stock?, shouldPromote: CachedStock?) = queue.sync {
        if let cached = memoryCache[symbol], !cached.isExpired(ttl: policy.cacheTTL) {
            return (cached.stock, nil)
        }
        if let cached = loadFromDisk(symbol: symbol), !cached.isExpired(ttl: policy.cacheTTL) {
            return (cached.stock, cached) // signal promotion needed
        }
        return (nil, nil)
    }

    // Step 2: Promote to memory — separate barrier write
    if let toPromote = result.shouldPromote {
        queue.sync(flags: .barrier) { [weak self] in
            self?.memoryCache[toPromote.stock.symbol] = toPromote
        }
    }

    return result.stock
}
```

### Fix Navigation Not Firing
```
Fix navigation path resetting when tapping stocks.

ROOT CAUSE:
Coordinators are @Published on AppCoordinator.
Path change → coordinator publishes → AppCoordinator publishes
→ AppCoordinatorView redraws → @StateObject resets → path clears.

FIX 1 — AppCoordinator.swift:
Change coordinator properties from @Published to plain var:
var dashboardCoordinator  = DashboardCoordinator()
var watchlistCoordinator  = WatchlistCoordinator()
var searchCoordinator     = SearchCoordinator()

FIX 2 — AppCoordinatorView.swift:
Extract each tab into isolated struct with @ObservedObject:
private struct DashboardTab: View {
    @ObservedObject var coordinator: DashboardCoordinator
    @StateObject private var viewModel = Container.shared.dashboardViewModel()
}

Do NOT change anything else. Wait for my approval.
```

### Fix SPM Bundle.main Not Reading Info.plist
```
Fix Bundle.main issue in: LocalPackages/Data/Sources/Data/Network/APIClient.swift

ROOT CAUSE:
Bundle.main inside an SPM package points to package bundle,
not the host app bundle — Info.plist keys not found.

FIX:
Change init to accept bundle parameter:
public init(bundle: Bundle = .main) throws {
    let info = bundle.infoDictionary
    ...
}

In AppContainer.swift:
var apiClient: Factory<APIClientProtocol> {
    self { try! FinnhubClient(bundle: Bundle.main) }
        .singleton
}

Bundle.main in the MAIN TARGET correctly points to app bundle.
```

---

## Workflow Commands

```bash
# After Claude Code creates files
xcodegen generate

# Build
CMD+B in Xcode

# Commit pattern
git add .
git commit -m "feat: description

- bullet points of what changed"
git push

# Test deep links
xcrun simctl openurl booted "stockpulse://stock/AAPL"

# Check API manually
curl 'https://finnhub.io/api/v1/quote?symbol=AAPL&token=YOUR_KEY'
```

---

## Key Architecture Decisions

| Decision | Choice | Why |
|----------|--------|-----|
| DI in Features | Constructor injection | @Injected not visible cross-package |
| @MainActor | On methods, not class | Factory init runs in nonisolated context |
| Coordinators | Plain var on AppCoordinator | @Published causes redraw chain |
| Tab isolation | @ObservedObject per tab | Prevents NavigationPath reset |
| Cache location | StockCacheProtocol in Domain | Both Data + Features need it |
| API provider | Finnhub over Alpha Vantage | 60/min vs 25/day |
| Date encoding | .secondsSince1970 | iOS 26 NSTaggedDate crash |
| Cache writes | queue.sync(flags:.barrier) | Prevents dictionary mutation crash |

