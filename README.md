# StockPulse 📈

A production-grade iOS stock market app built with SwiftUI, Clean Architecture, MVVM, an AI Voice Assistant, and an Agentic Research Engine — all powered by Azure OpenAI.

> Built as a hands-on exercise in iOS Clean Architecture and agentic AI using Claude Code as an AI pair programmer.

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
| SEC Filings | EDGAR public API | Free, no key required |
| AI Voice | Azure OpenAI gpt-realtime-mini | WebRTC, tool calling |
| AI Research | Azure OpenAI GPT-4.1 mini | Plan/reflect/synthesize loop |
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
- 7 tools wired to real Use Cases:
  - `get_stock_price` → FetchStockUseCase
  - `search_stock` → SearchStocksUseCase
  - `add_to_watchlist` → AddToWatchlistUseCase
  - `remove_from_watchlist` → RemoveFromWatchlistUseCase
  - `navigate_to_stock` → NavigationStateManager
  - `get_watchlist` → FetchWatchlistUseCase
  - `run_research_agent` → AgentOrchestrator (agentic loop)
- Smart audio routing (speaker / headphones / Bluetooth)
- Real-time transcript with per-response message bubbles
- User transcription bubbles in correct chronological order
- Progress bubbles showing each agent reasoning step live
- 60-second silence auto-disconnect
- Stock-only system instructions (refuses off-topic questions)
- NotificationCenter sync — watchlist star updates instantly from AI actions

### 🔬 Agentic Research Engine
Triggered when you ask for research, analysis, or a deep dive on any stock.

**Flow:**
1. Voice model calls `run_research_agent` with the research goal
2. `AgentOrchestrator` asks GPT-4.1 mini to create a JSON plan (which tools to run and why)
3. Tools execute — price lookups run in parallel, 10-K fetches run sequentially
4. `reflect()` checks if enough data was gathered; loops if not
5. `synthesize()` produces a structured spoken briefing from all gathered data
6. Result is spoken back to the user via WebRTC audio

**Plan → Execute → Reflect → Synthesize loop:**
```
AgentOrchestrator
  ├── plan()       GPT-4.1 mini → JSON action list
  ├── execute()    AgentToolRegistry runs each tool
  │   ├── get_stock_price   → Finnhub API
  │   ├── fetch_10k_section → SEC EDGAR → HTML strip → GPT parse
  │   ├── search_stock      → Finnhub search
  │   └── get/add/remove watchlist → WatchlistStore
  ├── reflect()    GPT-4.1 mini → "continue" or "done"
  └── synthesize() GPT-4.1 mini → structured spoken briefing
```

**SEC 10-K pipeline:**
```
fetch_10k_section(ticker, section)
  → EDGAR /company_tickers.json → CIK lookup
  → EDGAR /submissions/{CIK}.json → latest 10-K accession + HTM filename
  → EDGAR /Archives/…/{ticker}-{date}.htm → download (1–2 MB)
  → Strip HTML tags, find section anchor (ITEM 1., ITEM 1A., etc.)
  → Extract 25,000 chars from anchor
  → GPT-4.1 mini → 4–6 sentence plain-English summary
  → Cached per document URL (NSCache, limit 5) — no re-downloads
```

**AgentMemory (SwiftData):**
- Stores past research results keyed by ticker + section
- Used in future: skip re-fetching if data is fresh

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
        │   ├── StockToolsManager.swift   # Tool calls → Use Cases + Agent
        │   ├── AIAssistantViewModel.swift
        │   └── AIAssistantView.swift
        ├── Agent/       # Agentic Research Engine
        │   ├── AzureChatConfig.swift     # GPT-4.1 mini endpoint config
        │   ├── AzureChatClient.swift     # plan/reflect/synthesize/parseSection
        │   ├── AgentToolRegistry.swift   # 6 tools wired to Use Cases
        │   ├── AgentOrchestrator.swift   # Plan→Execute→Reflect→Synthesize loop
        │   ├── AgentMemory.swift         # SwiftData — past research results
        │   └── AgentModels.swift         # AgentPlan, AgentStep, AgentContext
        ├── Navigation/  # Coordinators, AppRoute, deep links
        └── DI/          # AppContainer — all Factory registrations
```

### AI Architecture

```
User Voice Input
      ↓ WebRTC audio
Azure gpt-realtime-mini (WebRTC session)
      ↓ tool_call: simple tools (data channel)
StockToolsManager → Use Cases → Finnhub / WatchlistStore
      ↑ tool_result
      ↓ tool_call: run_research_agent
AgentOrchestrator
  ├── plan()        → GPT-4.1 mini → JSON plan
  ├── execute()     → AgentToolRegistry
  │   ├── get_stock_price       → Finnhub API
  │   ├── fetch_10k_section     → EDGAR API → GPT-4.1 mini parse
  │   ├── search_stock          → Finnhub API
  │   └── watchlist tools       → WatchlistStore
  ├── reflect()     → GPT-4.1 mini → continue / done
  └── synthesize()  → GPT-4.1 mini → spoken briefing text
      ↑ tool_result (synthesis text)
GPT speaks synthesized research
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

Create `Configurations/Secrets.xcconfig` (gitignored — never commit this file):

```
# ── Stock data (Finnhub) ──────────────────────────────────────────────────────
FINNHUB_API_KEY=your_finnhub_key
FINNHUB_DEV_KEY=your_finnhub_key
FINNHUB_STG_KEY=your_finnhub_key

# ── AI Voice — Azure OpenAI gpt-realtime-mini (WebRTC) ───────────────────────
# Ephemeral token endpoint is fronted by APIM; subscription key goes here.
APIM_SUBSCRIPTION_KEY=your_apim_subscription_key
APIM_ENDPOINT=https:/$()/your-apim.azure-api.net
WEBRTC_ENDPOINT=https:/$()/eastus2.realtimeapi-preview.ai.azure.com/v1/realtimertc
REALTIME_DEPLOYMENT=gpt-realtime-mini

# ── AI Research — Azure OpenAI GPT-4.1 mini (Agent planner / 10-K parser) ────
# Direct REST endpoint for the chat completions deployment.
# Format: https://your-apim.azure-api.net/<route>/openai/deployments/<model>/chat/completions
AZURE_CHAT_ENDPOINT=https:/$()/your-apim.azure-api.net/your-route/openai/deployments/gpt-4.1-mini/chat/completions
AZURE_CHAT_API_KEY=your_azure_chat_api_key
# API version is set in Base.xcconfig — currently 2024-08-01-preview
```

⚠️ Use `$()` to escape `//` in xcconfig (xcconfig treats `//` as a line comment)
⚠️ No spaces around `=`
⚠️ `Secrets.xcconfig` is in `.gitignore` — never commit real keys

### 4. Build & Run

```bash
open StockPulse.xcodeproj
# Select Debug scheme → iPhone 17 Pro Max → CMD+R
```

---

## Scripts

### Build & Run

```bash
# Generate Xcode project after any new Swift file or project.yml change
xcodegen generate

# Build for simulator (no Xcode needed)
xcodebuild -scheme StockPulse \
  -destination 'platform=iOS Simulator,arch=arm64,name=iPhone 17 Pro' \
  -configuration Debug build

# Install + launch on a booted simulator
APP=~/Library/Developer/Xcode/DerivedData/StockPulse-*/Build/Products/Debug-iphonesimulator/StockPulse.app
xcrun simctl install booted "$APP"
xcrun simctl launch booted com.sweta.stockpulse.debug
```

### Run Unit Tests

```bash
xcodebuild test \
  -scheme StockPulse \
  -destination 'platform=iOS Simulator,arch=arm64,name=iPhone 17 Pro' \
  | xcpretty          # optional — brew install xcpretty for clean output
```

### Simulator Log Stream

Stream all StockPulse logs (info level and above) while the app is running:

```bash
xcrun simctl spawn booted log stream \
  --predicate 'subsystem == "com.sweta.stockpulse"' \
  --level info 2>&1
```

Useful filter prefixes visible in the logs:

| Prefix | Source |
|--------|--------|
| `[Agent.ChatClient]` | GPT-4.1 mini plan / reflect / synthesize calls |
| `[Agent.Registry]` | Tool execution results (first 300 chars) |
| `[Agent.Orchestrator]` | Loop steps, reflect decisions |
| `[SEC.Client]` | EDGAR CIK lookup, submissions fetch, HTML download |
| `[AI.WebRTC]` | WebRTC peer connection events |
| `[AI.Tools]` | Tool call routing and results |

### Verify Secrets Are Wired

Quick sanity check — prints the first 8 chars of each key (safe to run, no full key exposed):

```bash
# From project root
plutil -p StockPulse/Info.plist | grep -E "FINNHUB|AZURE|APIM|WEBRTC"
```

---

## Testing the Agentic Research Feature

Connect to the AI Voice Assistant and try these queries:

| Query | Expected behaviour |
|-------|--------------------|
| "What's the price of TSLA?" | Direct price lookup — no agent loop |
| "Add Apple to my watchlist" | Watchlist write — no agent loop |
| "Research NVIDIA" | Agent: 10-K business section → synthesized briefing |
| "Do a deep dive on Apple" | Agent: 10-K business + price → detailed analysis |
| "Compare Apple and Microsoft" | Agent: 10-K for both companies → side-by-side synthesis |
| "Research CoStar Group and Zillow" | Agent: 10-K for both → real estate sector comparison |
| "Analyze the risks for Tesla" | Agent: 10-K risk factors section → risk briefing |

**What to watch for:**
- Progress system bubbles show each agent step with its reasoning
- `[SEC.Client]` log entries confirm CIK lookup + document download
- `[Agent.Registry]` log entries show the tool result (first 300 chars)
- Synthesis should lead with 10-K content (business model, revenue drivers) before price

**Log stream during testing:**
```bash
xcrun simctl spawn booted log stream \
  --predicate 'subsystem == "com.sweta.stockpulse"' \
  --level info 2>&1
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

### 10. EDGAR `fiscalYearEnd` is at Company Level, Not `recent[]`
The EDGAR submissions JSON has `fiscalYearEnd` at the root company object,
not inside the `recent` filings array. Guarding on it inside `recent` always
fails with `parsingFailed`. Use `recent["primaryDocument"]` for the HTM filename.

### 11. 10-K HTML — Section Anchor Search
The first 8,000 chars of a raw 10-K HTM is DOCTYPE/CSS — no content.
Strip all HTML tags first, then search for the ITEM anchor (`ITEM 1.`,
`ITEM 1A.`, `ITEM 7.`, `ITEM 8.`) and extract 25,000 chars from that point.

### 12. OSLog `.debug` is Suppressed on Simulator by Default
Use `--level info` in `log stream`, not `--level debug`.
Or use `logger.info()` for anything you need to observe during testing.

### 13. WebRTC Echo and Interruption Challenges

Running a real-time voice AI through WebRTC on iOS creates a chain of echo and
interruption problems. Here is every problem we hit and how we solved it.

#### Problem 1 — Echo feedback loop
When the AI speaks through the device speaker, the microphone picks up that audio.
The server-side VAD (Voice Activity Detection) hears the playback and thinks the
user is speaking. The AI responds to itself in an infinite loop.

**First attempt — hardware AEC via `voiceChat` mode:**
Setting `AVAudioSession.Mode.voiceChat` activates the device's hardware acoustic
echo canceller (AEC). On a real device this works reasonably well, but the
simulator has no hardware AEC so the echo remains. The bigger problem: the
behaviour was inconsistent across devices and the echo was still audible enough
to trigger false VAD detections.

**Final solution — mic mute during playback:**
Disable `localAudioTrack.isEnabled` the moment `output_audio_buffer.started` fires
and re-enable it on `output_audio_buffer.stopped`. The mic is off for exactly the
duration of the AI's audio output — zero echo possible.

```swift
case "output_audio_buffer.started":
    localAudioTrack?.isEnabled = false   // mic off — prevents echo

case "output_audio_buffer.stopped":
    localAudioTrack?.isEnabled = true    // mic back on — user can speak
```

#### Problem 2 — Muted mic blocks user interruption
Muting the mic solves echo but creates a new problem: the user cannot interrupt
the AI mid-sentence because the server's VAD never receives their voice.

**Solution — mute toggle button:**
Expose a visible mute/unmute button in the UI. The button shows a red
`🎤/ Muted — tap to speak` badge while the AI is talking. Tapping it unmutes
the mic, the server VAD detects the user's speech, and the AI stops.

```swift
// WebRTCManager
func toggleMute() {
    guard let track = localAudioTrack else { return }
    let unmuting = !track.isEnabled
    if unmuting && isGPTSpeaking {
        // Cancel AI response BEFORE enabling mic (see Problem 3)
        stockToolsManager.sendDataChannelMessage(["type": "response.cancel"])
    }
    track.isEnabled = unmuting
}
```

#### Problem 3 — Unmuting while AI speaks feeds speaker audio into mic
If the user taps "unmute" while the AI is speaking, the mic immediately becomes
active while the speaker is still playing. The VAD now hears the speaker output
as if it were user speech and triggers a new AI response — the AI responds to
its own voice.

**Solution — cancel before unmute:**
When unmuting while `isGPTSpeaking == true`, send `response.cancel` to the
server first. The AI stops generating and the speaker goes silent before the
mic is enabled. The user can then speak into a clean audio environment.

#### Problem 4 — Voice changes character after tool calls
Each `response.create` event triggers a fresh TTS (text-to-speech) synthesis
pass. Without an explicit voice setting on that event, the model can drift
in pitch, pace, or prosody between the pre-tool response and the post-tool
response — it can sound like a subtly different speaker.

**Solution — re-specify voice on every `response.create`:**
```swift
sendDataChannelMessage([
    "type": "response.create",
    "response": ["voice": RealtimeConfig.voice]   // reinforce "coral" every time
])
```
This does not eliminate all variation (neural TTS is stochastic) but it
significantly reduces the noticeable character shifts between turns.

#### Summary of the full audio state machine

```
output_audio_buffer.started  →  mic OFF  (echo prevention)
output_audio_buffer.stopped  →  mic ON   (user can speak)

User taps unmute while AI speaks:
  1. response.cancel          →  AI stops immediately
  2. mic ON                   →  clean audio for user input
  3. output_audio_buffer.stopped fires  →  no-op (mic already on)
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
- [ ] AgentMemory cache — skip re-fetching fresh 10-K data across sessions
- [ ] riskFactors / mdAndA agent plans — planner currently defaults to business section
- [ ] Multi-turn research — follow-up questions that refine previous research

---

## Project Stats

| Metric | Count |
|--------|-------|
| Swift files | 90+ |
| SPM packages | 3 (Domain, Data, Features) |
| Use cases | 12 |
| ViewModels | 5 |
| Screens | 5 (Dashboard, Detail, Search, Watchlist, AI) |
| AI Tools (WebRTC) | 7 (incl. run_research_agent) |
| Agent Tools (loop) | 6 (price, search, watchlist ×3, 10-K) |
| External APIs | 3 (Finnhub, Azure OpenAI, SEC EDGAR) |

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
