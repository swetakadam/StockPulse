# StockPulse 📈

A production-grade iOS stock market app built with SwiftUI, Clean Architecture, MVVM, and an AI Voice Assistant powered by Azure OpenAI Realtime API.

> Built as a hands-on exercise in iOS Clean Architecture using Claude Code as an AI pair programmer.

---

## Screenshots

| Dashboard | Stock Detail | Search | Watchlist | AI Assistant |
|-----------|-------------|--------|-----------|--------------|
| Market overview with liquid glass cards | Real-time price, stats, company info | Debounced live search | Sort, swipe to delete | Voice + tool calling |

---

## Tech Stack

| Category | Choice | Why |
|----------|--------|-----|
| UI | SwiftUI | iOS 17+, declarative |
| Architecture | MVVM + Clean Architecture | Testable, scalable |
| DI | Factory by Michael Long | Protocol-first, testable |
| Navigation | Coordinator + NavigationPath | Type-safe, deep-link ready |
| Stock API | Finnhub (free tier) | 60 calls/min, no daily cap |
| AI Voice | Azure OpenAI gpt-realtime-mini | WebRTC, tool calling |
| WebRTC | stasel/WebRTC M114 | Native iOS WebRTC |
| Caching | Two-level (Memory + UserDefaults) | Instant loads, offline support |
| Project | XcodeGen | No .pbxproj conflicts |
| Min iOS | iOS 17 | NavigationPath, SwiftData |

---

## Features

### 📊 Dashboard
- Market overview — S&P 500, NASDAQ, DOW with liquid glass cards
- Trending stocks horizontal scroll
- Watchlist preview section
- Top gainers / losers with segmented control
- Pull to refresh
- Two-phase loading: cache instantly, network fills gaps silently
- Good Morning/Afternoon/Evening greeting

### 📈 Stock Detail
- Real-time price with change indicator
- Company logo via AsyncImage
- Key stats: Market Cap, P/E, EPS, 52W High/Low, Avg Volume
- Price chart placeholder (Finnhub candles = premium)
- Company info with expandable description
- Add/Remove watchlist with instant star update
- Optimistic UI updates

### 🔍 Search
- Debounced live search (300ms)
- Recent searches history (Clean Architecture — use cases, not UserDefaults directly)
- Trending symbols grid
- Add to watchlist directly from results
- Tap result → Stock Detail

### ⭐️ Watchlist
- Clean list style (like native Stocks app)
- Total portfolio value header
- Sort by: Name, Price, Change%
- Swipe to delete
- Empty state with prompt to Search
- Always reloads on appear (watchlist is small, always fresh)

### 🤖 AI Voice Assistant
- Azure OpenAI gpt-realtime-mini via WebRTC
- 6 tools wired to real Use Cases:
  - `get_stock_price` → FetchStockUseCase
  - `search_stock` → SearchStocksUseCase
  - `add_to_watchlist` → AddToWatchlistUseCase
  - `remove_from_watchlist` → RemoveFromWatchlistUseCase
  - `navigate_to_stock` → NavigationStateManager
  - `get_watchlist` → FetchWatchlistUseCase
- Smart audio routing (speaker / headphones / Bluetooth)
- Real-time transcript with message bubbles
- Typing indicator animation
- Stock-only system instructions (refuses off-topic questions)
- NotificationCenter sync — watchlist star updates instantly from AI actions

---

## Architecture

### MVVM + Clean Architecture

```
┌─────────────────────────────────────────────────┐
│                   SwiftUI View                   │
│    (zero business logic, generic ViewModel,      │
│     closures for navigation)                     │
└────────────────────┬────────────────────────────┘
                     │ observes @Published
┌────────────────────▼────────────────────────────┐
│                  ViewModel                       │
│  (ObservableObject, constructor injection,       │
│   @MainActor on async methods only)              │
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
│           Repository Protocol (Domain)           │
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
│   │   ├── UseCases/    # Business logic (10 use cases)
│   │   ├── CachePolicy.swift   # freeTier / premiumTier flag
│   │   └── StockCacheProtocol.swift
│   │
│   ├── Data/            # Depends on Domain + Factory
│   │   ├── Network/     # FinnhubClient, APIEndpoint, DTOs
│   │   ├── Mappers/     # DTO → Domain (DTOs never leave Data)
│   │   ├── Persistence/ # StockCache, WatchlistStore, RecentSearchStore
│   │   └── Repositories/# StockRepositoryImpl
│   │
│   └── Features/        # Depends on Domain + Factory
│       ├── Dashboard/
│       ├── StockDetail/
│       ├── Search/
│       └── Watchlist/
│
└── StockPulse/          # Main app target
    └── Core/
        ├── AI/          # WebRTC + Azure OpenAI Realtime
        │   ├── RealtimeConfig.swift      # All config from Bundle/xcconfig
        │   ├── RealtimeSessionManager.swift
        │   ├── WebRTCManager.swift
        │   ├── StockToolsManager.swift   # Tool calls → Use Cases
        │   ├── AIAssistantViewModel.swift
        │   └── AIAssistantView.swift
        ├── Navigation/  # Coordinators, AppRoute, deep links
        └── DI/          # AppContainer — all Factory registrations
```

### AI Architecture

```
User Voice Input
      ↓ WebRTC audio
Azure gpt-realtime-mini
      ↓ tool_call (data channel)
StockToolsManager
      ↓ constructor injection
Use Cases (Domain)
      ↓
Repository (Data) → Finnhub API / Cache
      ↑
tool_result (data channel)
      ↑
GPT speaks response
      ↑ WebRTC audio
User hears response
```

---

## Navigation Architecture

### The Problem We Solved

Standard SwiftUI navigation with shared `ObservableObject` coordinator causes:

```
path changes → coordinator @Published fires
  → AppCoordinator objectWillChange fires
    → AppCoordinatorView redraws
      → DashboardView @StateObject resets
        → NavigationPath clears ← BUG 💥
```

### The Solution: Isolated Tab Views

```swift
// Each tab isolated — path changes never bubble up
private struct DashboardTab: View {
    @ObservedObject var coordinator: DashboardCoordinator
    @StateObject private var viewModel = Container.shared.dashboardViewModel()

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            DashboardView(viewModel: viewModel, ...)
        }
    }
}

// AppCoordinator — coordinators as plain var (NOT @Published)
final class AppCoordinator: ObservableObject {
    var dashboardCoordinator = DashboardCoordinator()  // ✅ plain var
    @Published var activeTab: AppTab = .dashboard      // ✅ @Published
}
```

---

## Caching Strategy

### Two-Level Cache

```
Request stock "AAPL"
       ↓
Memory Cache (Dictionary) ← instant, app session
       ↓ miss
Disk Cache (UserDefaults)  ← fast, survives restart
       ↓ miss
Finnhub API               ← concurrent (60/min)
       ↓ success
Save to memory + disk
```

### CachePolicy — One Flag Controls Everything

```swift
// Change this ONE line to switch all behavior:
public static let current: CachePolicy = .premiumTier

// .freeTier    → 24hr TTL, sequential (Alpha Vantage 25/day)
// .premiumTier → 60s TTL, concurrent  (Finnhub 60/min)
```

---

## Setup Instructions

### 1. Clone & Install Tools

```bash
git clone https://github.com/swetakadam/StockPulse.git
cd StockPulse
brew install xcodegen
xcodegen generate
```

### 2. Get API Keys

**Finnhub** (stock data):
1. Sign up at [finnhub.io](https://finnhub.io) — no credit card
2. Copy your API key

**Azure OpenAI** (AI voice — optional):
1. Deploy `gpt-realtime-mini` in Azure AI Foundry (East US 2)
2. Set up APIM gateway for ephemeral token endpoint

### 3. Configure Secrets

Create `Configurations/Secrets.xcconfig` (gitignored):

```
# Stock API
FINNHUB_API_KEY=your_finnhub_key
FINNHUB_DEV_KEY=your_finnhub_key

# AI Voice (optional)
APIM_SUBSCRIPTION_KEY=your_apim_key
APIM_ENDPOINT=https:/$()/your-apim.azure-api.net
WEBRTC_ENDPOINT=https:/$()/eastus2.realtimeapi-preview.ai.azure.com/v1/realtimertc
REALTIME_DEPLOYMENT=gpt-realtime-mini
```

⚠️ Use `$()` to escape `//` in xcconfig (xcconfig treats `//` as comment)
⚠️ No spaces around `=`

### 4. Build & Run

```bash
open StockPulse.xcodeproj
# Select Debug scheme → iPhone 17 Pro Max → CMD+R
```

---

## Lessons Learned / Gotchas

### 1. xcconfig Double Slash
```
# WRONG — truncates to "https:"
FINNHUB_BASE_URL=https://finnhub.io/api/v1

# CORRECT
FINNHUB_BASE_URL=https:/$()/finnhub.io/api/v1
```

### 2. @MainActor on Methods Not Class
```swift
// WRONG — Factory init error
@MainActor public final class DashboardViewModel { }

// CORRECT
public final class DashboardViewModel {
    @MainActor public func loadDashboard() async { }
}
```

### 3. @Published Coordinators Reset Navigation
Coordinators on AppCoordinator must be plain `var`, not `@Published`.
Path changes cause chain reaction redraws that reset NavigationPath.

### 4. StockCacheProtocol in Domain
Both Data and Features need it. Must live in Domain — the only
package both can import.

### 5. iOS 26 NSTaggedDate Crash
```swift
encoder.dateEncodingStrategy = .secondsSince1970
decoder.dateDecodingStrategy = .secondsSince1970
```

### 6. WebRTC Audio Route
```swift
// Only override to speaker if no headphones connected
let hasExternalOutput = session.currentRoute.outputs.contains {
    $0.portType == .headphones || $0.portType == .bluetoothA2DP
}
guard !hasExternalOutput else { return }
rtcAudioSession.overrideOutputAudioPort(.speaker)
```

### 7. SPM Bundle.main
`Bundle.main` inside SPM package points to package bundle not app bundle.
Pass `Bundle.main` explicitly from main target.

### 8. AI Navigation Tab Switch
When AI navigates to a stock, switch tab first then push route:
```swift
self.activeTab = .dashboard
DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
    self.dashboardCoordinator.navigate(to: route)
}
```

### 9. Watchlist Star from AI
Use NotificationCenter to sync AI watchlist changes to StockDetail:
```swift
NotificationCenter.default.post(name: .watchlistDidChange,
    userInfo: ["symbol": symbol, "action": "added"])
```

---

## Future Roadmap

- [ ] Notifications screen (news feed, earnings calendar, price alerts)
- [ ] Real-time chart data (Finnhub premium candles)
- [ ] Push Notifications (APNs)
- [ ] Live Activities (ActivityKit) — stock ticker
- [ ] Widget support (WidgetKit)
- [ ] Unit tests for all Use Cases and ViewModels
- [ ] App icon and launch screen
- [ ] Company names via Finnhub profile on Dashboard

---

## Project Stats

| Metric | Count |
|--------|-------|
| Swift files | 75+ |
| SPM packages | 3 (Domain, Data, Features) |
| Use cases | 10 |
| ViewModels | 5 |
| Screens | 5 (Dashboard, Detail, Search, Watchlist, AI) |
| AI Tools | 6 |
| API endpoints | 7 |

---

## Built With

- [SwiftUI](https://developer.apple.com/xcode/swiftui/)
- [Factory](https://github.com/hmlongco/Factory) — Dependency Injection
- [Finnhub API](https://finnhub.io) — Stock market data
- [Azure OpenAI](https://azure.microsoft.com/en-us/products/ai-services/openai-service) — AI Voice
- [stasel/WebRTC](https://github.com/stasel/WebRTC) — WebRTC framework
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) — Project generation
- [Claude Code](https://claude.ai/code) — AI pair programming

---

*Built by Sweta Kadam — March 2026*
