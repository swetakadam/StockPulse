# Agentic Extension — Design Spec
**Date:** 2026-05-28  
**Project:** StockPulse iOS  
**Status:** Approved — ready for implementation

---

## Goal

Extend the existing voice assistant from a reactive single-tool-call model into a proactive multi-step agentic system. The AI can autonomously plan a sequence of tool calls, execute them, reflect on intermediate results, and synthesize a spoken response — without user prompting at each step.

Secondary goal: add SEC EDGAR as a data source so the agent can pull 10-K filings during research.

---

## Chosen Approach: Clean Agent Layer (Approach B)

New `Core/Agent/` directory isolates all orchestration logic. The existing voice pipeline (WebRTC → StockToolsManager → use cases) is unchanged except for one new tool: `run_research_agent`. Single-tool queries remain fast with zero orchestrator overhead.

---

## Architecture Overview

```
Voice Input (WebRTC / Azure OpenAI Realtime)
    ↓
WebRTCManager  [unchanged]
    ↓
StockToolsManager  [+1 new tool]
    ├── Tools 1–6: direct use case calls  [unchanged]
    └── Tool 7: run_research_agent(goal:tickers:allow_parallel:)
                    ↓
            AgentOrchestrator  [NEW]
                ├── AzureChatClient → GPT-4.1 mini (plan / reflect / synthesize / parse)
                ├── AgentToolRegistry → wraps 5 existing use cases + fetch_10k_section
                ├── AgentMemory → SwiftData (cross-session persistence)
                └── returns synthesis string → spoken by realtime model

Data layer additions:
    SECClient → EDGAR public API (no key required)
    TenKParser → LLM-as-parser via AzureChatClient
    SECRepositoryImpl

Domain layer additions:
    TenKReport, TenKSection models
    SECRepositoryProtocol
    FetchTenKSectionUseCase
```

---

## New File Layout

```
StockPulse/Core/Agent/
├── AgentOrchestrator.swift
├── AgentTask.swift
├── AgentStep.swift
├── AgentContext.swift
├── AgentMemory.swift
├── AgentToolRegistry.swift
└── AzureChatClient.swift

LocalPackages/Domain/Sources/Domain/
├── Models/TenKReport.swift
├── Models/TenKSection.swift
├── Repositories/SECRepositoryProtocol.swift
└── UseCases/
    ├── Protocols/FetchTenKSectionUseCaseProtocol.swift
    └── Implementations/FetchTenKSectionUseCase.swift

LocalPackages/Data/Sources/Data/
├── Network/SECClient.swift
├── Network/SECEndpoint.swift
├── Parsers/TenKParser.swift
└── Repositories/SECRepositoryImpl.swift
```

---

## Core/Agent Layer

### AgentTask
```swift
struct AgentTask {
    let goal: String
    let tickers: [String]
    let maxSteps: Int        // default 8
    let allowParallel: Bool  // enables TaskGroup for multi-ticker
}
```

### AgentStep
```swift
struct AgentStep: Codable {
    let toolName: String
    let parameters: [String: String]
    let result: String       // JSON string from tool handler
    let reasoning: String    // GPT-4.1 mini's "why this step" note
    let timestamp: Date
    var error: String?
}
```

### AgentContext (in-memory, single run)
```swift
struct AgentContext {
    let goal: String
    var steps: [AgentStep] = []

    mutating func addStep(_ step: AgentStep)
    func asPromptContext() -> String  // serialized for GPT-4.1 mini reflect calls
}
```

### AgentPlan (GPT-4.1 mini planning output, Codable)
```swift
struct AgentPlan: Codable {
    struct PlannedAction: Codable {
        let toolName: String
        let parameters: [String: String]
        let reasoning: String
        let parallel: Bool   // true = run concurrently with siblings
    }
    let actions: [PlannedAction]
}
```

### AgentDecision (reflect output)
```swift
enum AgentDecision: String, Codable {
    case `continue`
    case done
    case branch   // model returns new AgentPlan to append
}
```

### AzureChatClient
Thin HTTP client for GPT-4.1 mini. Same HTTP shape as existing chat demo:
- Endpoint: `AZURE_CHAT_ENDPOINT` from xcconfig
- Auth: `api-key` header from `AZURE_CHAT_API_KEY` xcconfig
- API version: `2024-08-01-preview`
- No SDK dependency — plain `URLSession`

```swift
final class AzureChatClient {
    func plan(goal: String, tools: [AgentToolSchema]) async throws -> AgentPlan   // maxTokens: 1000
    func reflect(context: AgentContext) async throws -> AgentDecision             // maxTokens: 200
    func synthesize(context: AgentContext) async throws -> String                 // maxTokens: 800
    func parseSection(rawHTML: String, section: TenKSection) async throws -> String // maxTokens: 2000
}
```

All four methods POST to the same endpoint with different system prompts. `parseSection` instructs the model to extract the requested 10-K section from raw EDGAR HTML and return plain prose.

### AgentToolRegistry
Single source of truth for tool schemas + handlers. All handlers are `([String: String]) async throws -> String` (JSON in → JSON out).

Registered tools:
1. `get_stock_price` → FetchStockUseCase
2. `search_stock` → SearchStocksUseCase
3. `get_watchlist` → FetchWatchlistUseCase
4. `add_to_watchlist` → AddToWatchlistUseCase
5. `remove_from_watchlist` → RemoveFromWatchlistUseCase
6. `fetch_10k_section` → FetchTenKSectionUseCase

```swift
struct AgentTool {
    let name: String
    let description: String
    let parameterSchema: [String: String]
    let handler: ([String: String]) async throws -> String
}

final class AgentToolRegistry {
    // Constructor-injected use cases (all protocols)
    var schemas: [AgentToolSchema] { tools.map(\.schema) }
    func execute(_ action: AgentPlan.PlannedAction) async throws -> AgentStep
}
```

### AgentOrchestrator
```swift
final class AgentOrchestrator {
    var progressHandler: ((String) -> Void)?

    init(chatClient: AzureChatClient,
         toolRegistry: AgentToolRegistry,
         memory: AgentMemory)

    func execute(task: AgentTask) async throws -> AgentResult {
        var context = AgentContext(goal: task.goal)
        let plan = try await chatClient.plan(goal: task.goal, tools: toolRegistry.schemas)

        var pendingParallel: [AgentPlan.PlannedAction] = []

        for action in plan.actions.prefix(task.maxSteps) {
            if action.parallel && task.allowParallel {
                pendingParallel.append(action)
            } else {
                if !pendingParallel.isEmpty {
                    let steps = try await executeParallel(pendingParallel)
                    steps.forEach { context.addStep($0) }
                    pendingParallel = []
                }
                progressHandler?("⚙ \(action.reasoning)")
                let step = try await toolRegistry.execute(action)
                context.addStep(step)
                let decision = try await chatClient.reflect(context: context)
                if decision == .done { break }
            }
        }

        progressHandler?("⚙ Synthesizing...")
        let synthesis = try await chatClient.synthesize(context: context)
        await memory.store(task: task, context: context, synthesis: synthesis)
        return AgentResult(steps: context.steps, synthesis: synthesis)
    }

    private func executeParallel(_ actions: [AgentPlan.PlannedAction]) async throws -> [AgentStep] {
        try await withThrowingTaskGroup(of: AgentStep.self) { group in
            for action in actions { group.addTask { try await toolRegistry.execute(action) } }
            return try await group.reduce(into: []) { $0.append($1) }
        }
    }
}
```

### AgentMemory (SwiftData)
```swift
@Model
final class StoredAgentResult {
    var ticker: String       // primary lookup key
    var goal: String
    var synthesis: String
    var stepsJSON: Data      // [AgentStep] JSON-encoded
    var timestamp: Date
}

final class AgentMemory {
    private let modelContext: ModelContext

    func store(task: AgentTask, context: AgentContext, synthesis: String) async
    func recall(ticker: String) async -> StoredAgentResult?
    func recentResults(limit: Int) async -> [StoredAgentResult]
}
```

---

## SEC / 10-K Integration

### Domain Models
```swift
// TenKSection.swift
public enum TenKSection: String, Codable, CaseIterable {
    case business            = "Item 1"
    case riskFactors         = "Item 1A"
    case mdAndA              = "Item 7"
    case financialStatements = "Item 8"
}

// TenKReport.swift
public struct TenKReport: Codable {
    public let ticker: String
    public let cik: String
    public let fiscalYear: Int
    public let filedDate: Date
    public let accessionNumber: String
    public var business: String?
    public var riskFactors: String?
    public var mdAndA: String?
    public var financialStatements: String?
    public var documentURL: URL
}
```

### Domain Protocols
```swift
public protocol SECRepositoryProtocol {
    func fetchCIK(ticker: String) async throws -> String
    func fetchLatest10KAccession(cik: String) async throws -> (accession: String, fiscalYear: Int, filedDate: Date, documentURL: URL)
    func fetchSectionText(documentURL: URL, section: TenKSection) async throws -> String
}

public protocol FetchTenKSectionUseCaseProtocol {
    func execute(ticker: String, section: TenKSection) async throws -> TenKReport
}
```

### FetchTenKSectionUseCase
Fetches CIK → latest 10-K accession → raw document → parses requested section.
Populates only the requested field in `TenKReport` (lazy by design).

### Data Layer

**SECClient** — no API key required. EDGAR User-Agent header required:
`User-Agent: StockPulse/1.0 sshinde5ster@gmail.com`

Endpoints:
- `https://www.sec.gov/files/company_tickers.json` — ticker→CIK map
- `https://data.sec.gov/submissions/CIK{cik}.json` — filings index
- Raw filing document URL from filings index

**TenKParser** — LLM-as-parser (v1). Sends raw EDGAR HTML to `AzureChatClient.parseSection()`. Prompt instructs: extract only the named Item text, strip HTML tags, return plain prose under 2000 tokens.

**SECRepositoryImpl** — wires `SECClient` + `TenKParser`.

---

## Integration Points

### StockToolsManager changes
One new tool added to `sendSessionUpdate()` payload:
```json
{
  "name": "run_research_agent",
  "description": "Run a multi-step research analysis on one or more stocks. Use for thesis, comparison, deep analysis, or comprehensive overview. Before calling this tool, verbally acknowledge the request (e.g. 'Let me research that for you, give me a moment').",
  "parameters": {
    "goal": { "type": "string" },
    "tickers": { "type": "array", "items": { "type": "string" } },
    "allow_parallel": { "type": "boolean" }
  }
}
```

One new case in `handleToolCall()` that constructs `AgentTask` and calls `agentOrchestrator.execute(task:)`.

`StockToolsManager` gains one new constructor parameter: `agentOrchestrator: AgentOrchestrator`.

### AppContainer registrations
```swift
var azureChatClient: Factory<AzureChatClient> { self { AzureChatClient() }.singleton }

var agentMemory: Factory<AgentMemory> { self { AgentMemory(modelContext: ...) }.singleton }

var secRepository: Factory<SECRepositoryProtocol> {
    self { SECRepositoryImpl(client: SECClient(), parser: TenKParser(chatClient: self.azureChatClient())) }.singleton
}

var fetchTenKSectionUseCase: Factory<FetchTenKSectionUseCaseProtocol> {
    self { FetchTenKSectionUseCase(repository: self.secRepository()) }
}

var agentOrchestrator: Factory<AgentOrchestrator> {
    self {
        AgentOrchestrator(
            chatClient: self.azureChatClient(),
            toolRegistry: AgentToolRegistry(
                fetchStockUseCase: self.fetchStockUseCase(),
                searchStocksUseCase: self.searchStocksUseCase(),
                fetchWatchlistUseCase: self.fetchWatchlistUseCase(),
                addToWatchlistUseCase: self.addToWatchlistUseCase(),
                removeFromWatchlistUseCase: self.removeFromWatchlistUseCase(),
                fetchTenKSectionUseCase: self.fetchTenKSectionUseCase()
            ),
            memory: self.agentMemory()
        )
    }
}
```

`aiAssistantViewModel` factory gains `agentOrchestrator` parameter.

### xcconfig additions (Secrets.xcconfig — gitignored)
```
AZURE_CHAT_ENDPOINT=https://apim-chat-gateway.azure-api.net/ai-gateway-chat-demo-eastus-reso/openai/deployments/gpt-4.1-mini/chat/completions
AZURE_CHAT_API_KEY=your_key_here
AZURE_CHAT_API_VERSION=2024-08-01-preview
```

Add to `Base.xcconfig` (not gitignored):
```
AZURE_CHAT_ENDPOINT=$(AZURE_CHAT_ENDPOINT)
AZURE_CHAT_API_VERSION=2024-08-01-preview
```

Add to Info.plist:
```xml
<key>AZURE_CHAT_ENDPOINT</key><string>$(AZURE_CHAT_ENDPOINT)</string>
<key>AZURE_CHAT_API_KEY</key><string>$(AZURE_CHAT_API_KEY)</string>
<key>AZURE_CHAT_API_VERSION</key><string>$(AZURE_CHAT_API_VERSION)</string>
```

### project.yml
Add `SwiftData.framework` to main app target (system framework, no SPM needed).

---

## Progress Notification (UI Step Bubbles)

```swift
// StockToolsManager sets before execute():
agentOrchestrator.progressHandler = { [weak self] message in
    NotificationCenter.default.post(name: .agentStepProgress, object: nil,
                                    userInfo: ["message": message])
}

// AIAssistantViewModel subscribes in setupBindings():
NotificationCenter.default.addObserver(forName: .agentStepProgress, ...) { note in
    let msg = note.userInfo?["message"] as? String ?? ""
    self.messages.append(TranscriptMessage(role: .system, text: msg, timestamp: Date()))
}
```

The realtime model speaks acknowledgment before calling the tool (enforced via tool description system prompt instruction — no code change required).

---

## End-to-End Flow: "Give me a full thesis on NVDA"

1. User speaks → Azure Realtime transcribes
2. GPT-4o Realtime says *"Let me research that, give me a moment"* then calls `run_research_agent`
3. `StockToolsManager` builds `AgentTask`, calls `agentOrchestrator.execute(task:)`
4. **PLAN**: GPT-4.1 mini returns `AgentPlan` with 5 actions
5. **EXECUTE** (sequential):
   - `get_stock_price(NVDA)` → Finnhub → `$940` → progress bubble
   - `fetch_10k_section(NVDA, business)` → EDGAR → GPT parse → progress bubble
   - `fetch_10k_section(NVDA, riskFactors)` → EDGAR → GPT parse → progress bubble
   - `fetch_10k_section(NVDA, mdAndA)` → EDGAR → GPT parse → progress bubble
   - `get_watchlist()` → local store → progress bubble
6. **SYNTHESIZE**: GPT-4.1 mini receives all 5 results → spoken summary string
7. **PERSIST**: `AgentMemory.store(ticker: "NVDA", ...)`
8. Tool result returned → realtime model speaks synthesis

## End-to-End Flow: "Compare NVDA vs AMD vs INTC"

Steps 1–4 as above. Plan contains `parallel: true` on all `get_stock_price` actions.
`withThrowingTaskGroup` fires all 3 Finnhub calls concurrently, merges results, synthesizes comparison.

## Cross-Session Memory Recall

User: *"What did you find on NVDA last time?"*
→ `run_research_agent(goal: "recall last NVDA research")`
→ `agentMemory.recall(ticker: "NVDA")` → `StoredAgentResult`
→ synthesize: *"Last time I researched NVDA on May 20th it was at $890, now it's $940..."*

---

## Testing Strategy

| Layer | What | Mock |
|---|---|---|
| `FetchTenKSectionUseCase` | Returns correct TenKReport fields per section | `MockSECRepository` |
| `AgentToolRegistry` | Each handler returns valid JSON | Existing mock use cases |
| `AgentOrchestrator` — sequential | Steps execute in plan order | `MockAzureChatClient`, `MockAgentToolRegistry` |
| `AgentOrchestrator` — parallel | TaskGroup fires concurrently | Same mocks, verify step count |
| `AgentMemory` | Store + recall returns correct result | In-memory `ModelContainer` |
| `AzureChatClient` | Parses `choices[0].message.content` | `MockURLProtocol` + fixture JSON |
| `SECClient` | CIK lookup + accession parsing | `MockURLProtocol` + EDGAR fixture JSON |
| `TenKParser` | Extracted section text non-empty | `MockAzureChatClient` |

All mocks follow the existing `MockDashboardViewModel` pattern (protocol conformance, hardcoded return values).

---

## Rollout Order (single session)

| # | What to build | Key files |
|---|---|---|
| 1 | Domain: TenKReport, TenKSection, SECRepositoryProtocol, FetchTenKSectionUseCase | Domain package |
| 2 | Data: SECClient, SECEndpoint, TenKParser, SECRepositoryImpl | Data package |
| 3 | AzureChatClient | Core/Agent/ |
| 4 | AgentTask, AgentStep, AgentContext, AgentPlan, AgentDecision, AgentResult | Core/Agent/ |
| 5 | AgentToolRegistry | Core/Agent/ |
| 6 | AgentMemory (SwiftData) | Core/Agent/ |
| 7 | AgentOrchestrator | Core/Agent/ |
| 8 | StockToolsManager: add run_research_agent tool + delegate to orchestrator | Core/AI/ |
| 9 | AppContainer: register all new types | Core/DI/ |
| 10 | xcconfig + Info.plist + project.yml | Config files |
| 11 | Progress bubbles in AIAssistantViewModel | Core/AI/ |
| 12 | xcodegen generate + build + smoke test | Terminal |

---

## Constraints

- No new SPM packages — SwiftData is a system framework
- EDGAR User-Agent header is required by SEC: `StockPulse/1.0 sshinde5ster@gmail.com`
- `maxSteps: 8` prevents runaway agent loops
- DTOs from SECClient never leave the Data layer — always mapped to `TenKReport`
- `AzureChatClient` is a singleton shared by `AgentOrchestrator` and `TenKParser`
- All new ViewModels/registrations follow `@MainActor on methods, not class` rule
- No `@Injected` in Features package — constructor injection only
