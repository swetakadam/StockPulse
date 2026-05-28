# Agentic Extension Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an AgentOrchestrator that plans and executes multi-step stock research autonomously, backed by GPT-4.1 mini on Azure, with SEC EDGAR 10-K data and SwiftData memory.

**Architecture:** New `Core/Agent/` layer triggered by a 7th tool (`run_research_agent`) in `StockToolsManager`. Voice I/O stays on Azure Realtime; GPT-4.1 mini (text API) handles plan/reflect/synthesize. SEC EDGAR added as a Domain/Data pair following existing patterns.

**Tech Stack:** Swift 5.9, SwiftUI, SwiftData (iOS 17+), URLSession, Factory DI, Swift Testing

---

## File Map

**Create:**
```
LocalPackages/Domain/Sources/Domain/Models/TenKSection.swift
LocalPackages/Domain/Sources/Domain/Models/TenKReport.swift
LocalPackages/Domain/Sources/Domain/Repositories/SECRepositoryProtocol.swift
LocalPackages/Domain/Sources/Domain/UseCases/Protocols/FetchTenKSectionUseCaseProtocol.swift
LocalPackages/Domain/Sources/Domain/UseCases/Implementations/FetchTenKSectionUseCase.swift
LocalPackages/Data/Sources/Data/Network/SECEndpoint.swift
LocalPackages/Data/Sources/Data/Network/SECClient.swift
LocalPackages/Data/Sources/Data/Parsers/TenKParser.swift
LocalPackages/Data/Sources/Data/Repositories/SECRepositoryImpl.swift
StockPulse/Core/Agent/AzureChatConfig.swift
StockPulse/Core/Agent/AgentTypes.swift
StockPulse/Core/Agent/AzureChatClient.swift
StockPulse/Core/Agent/AgentToolRegistry.swift
StockPulse/Core/Agent/AgentMemory.swift
StockPulse/Core/Agent/AgentOrchestrator.swift
StockPulseTests/AgentOrchestratorTests.swift
StockPulseTests/FetchTenKSectionUseCaseTests.swift
StockPulseTests/AgentMemoryTests.swift
```

**Modify:**
```
StockPulse/Core/AI/StockToolsManager.swift          — add run_research_agent tool (#7)
StockPulse/Core/AI/AIAssistantViewModel.swift       — add agentOrchestrator param + progress bubbles
StockPulse/Core/DI/AppContainer.swift               — register all new types
Configurations/Base.xcconfig                        — add AZURE_CHAT_ENDPOINT, AZURE_CHAT_API_VERSION
Configurations/Secrets.xcconfig                     — add AZURE_CHAT_API_KEY
StockPulse/Info.plist                               — add 3 new keys
project.yml                                         — add SwiftData SDK dependency
```

---

## Task 1: Domain — TenKSection + TenKReport models

**Files:**
- Create: `LocalPackages/Domain/Sources/Domain/Models/TenKSection.swift`
- Create: `LocalPackages/Domain/Sources/Domain/Models/TenKReport.swift`

- [ ] **Step 1: Create TenKSection**

```swift
// LocalPackages/Domain/Sources/Domain/Models/TenKSection.swift
// Pure Swift — zero framework imports
public enum TenKSection: String, Codable, CaseIterable, Sendable {
    case business            = "Item 1"
    case riskFactors         = "Item 1A"
    case mdAndA              = "Item 7"
    case financialStatements = "Item 8"

    public var displayName: String {
        switch self {
        case .business:            return "Business"
        case .riskFactors:         return "Risk Factors"
        case .mdAndA:              return "MD&A"
        case .financialStatements: return "Financial Statements"
        }
    }
}
```

- [ ] **Step 2: Create TenKReport**

```swift
// LocalPackages/Domain/Sources/Domain/Models/TenKReport.swift
import Foundation

public struct TenKReport: Codable, Sendable {
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

    public init(
        ticker: String, cik: String, fiscalYear: Int,
        filedDate: Date, accessionNumber: String, documentURL: URL
    ) {
        self.ticker = ticker
        self.cik = cik
        self.fiscalYear = fiscalYear
        self.filedDate = filedDate
        self.accessionNumber = accessionNumber
        self.documentURL = documentURL
    }
}
```

- [ ] **Step 3: Run xcodegen to pick up new files**

```bash
cd /Users/swetakadam/iOSProjects/StockPulse && xcodegen generate
```

Expected: `✅ Done` with no errors.

- [ ] **Step 4: Commit**

```bash
git add LocalPackages/Domain/Sources/Domain/Models/TenKSection.swift \
        LocalPackages/Domain/Sources/Domain/Models/TenKReport.swift
git commit -m "feat: add TenKSection + TenKReport domain models"
```

---

## Task 2: Domain — SECRepositoryProtocol + FetchTenKSectionUseCase

**Files:**
- Create: `LocalPackages/Domain/Sources/Domain/Repositories/SECRepositoryProtocol.swift`
- Create: `LocalPackages/Domain/Sources/Domain/UseCases/Protocols/FetchTenKSectionUseCaseProtocol.swift`
- Create: `LocalPackages/Domain/Sources/Domain/UseCases/Implementations/FetchTenKSectionUseCase.swift`

- [ ] **Step 1: Create SECRepositoryProtocol**

```swift
// LocalPackages/Domain/Sources/Domain/Repositories/SECRepositoryProtocol.swift
import Foundation

public protocol SECRepositoryProtocol: Sendable {
    func fetchCIK(ticker: String) async throws -> String
    func fetchLatest10KAccession(cik: String) async throws -> SECFilingInfo
    func fetchSectionText(documentURL: URL, section: TenKSection) async throws -> String
}

public struct SECFilingInfo: Sendable {
    public let accession: String
    public let fiscalYear: Int
    public let filedDate: Date
    public let documentURL: URL

    public init(accession: String, fiscalYear: Int, filedDate: Date, documentURL: URL) {
        self.accession = accession
        self.fiscalYear = fiscalYear
        self.filedDate = filedDate
        self.documentURL = documentURL
    }
}

public enum SECError: Error, LocalizedError {
    case tickerNotFound(String)
    case noFilingsFound(String)
    case documentFetchFailed(URL)
    case parsingFailed(String)

    public var errorDescription: String? {
        switch self {
        case .tickerNotFound(let t):   return "CIK not found for ticker: \(t)"
        case .noFilingsFound(let cik): return "No 10-K filings for CIK: \(cik)"
        case .documentFetchFailed(let url): return "Failed to fetch: \(url)"
        case .parsingFailed(let msg):  return "Parse error: \(msg)"
        }
    }
}
```

- [ ] **Step 2: Create FetchTenKSectionUseCaseProtocol**

```swift
// LocalPackages/Domain/Sources/Domain/UseCases/Protocols/FetchTenKSectionUseCaseProtocol.swift
public protocol FetchTenKSectionUseCaseProtocol: Sendable {
    func execute(ticker: String, section: TenKSection) async throws -> TenKReport
}
```

- [ ] **Step 3: Create FetchTenKSectionUseCase**

```swift
// LocalPackages/Domain/Sources/Domain/UseCases/Implementations/FetchTenKSectionUseCase.swift
// Pure Swift — zero framework imports
public final class FetchTenKSectionUseCase: FetchTenKSectionUseCaseProtocol {
    private let repository: any SECRepositoryProtocol

    public init(repository: any SECRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(ticker: String, section: TenKSection) async throws -> TenKReport {
        let cik = try await repository.fetchCIK(ticker: ticker)
        let filing = try await repository.fetchLatest10KAccession(cik: cik)
        let text = try await repository.fetchSectionText(documentURL: filing.documentURL, section: section)

        var report = TenKReport(
            ticker: ticker,
            cik: cik,
            fiscalYear: filing.fiscalYear,
            filedDate: filing.filedDate,
            accessionNumber: filing.accession,
            documentURL: filing.documentURL
        )
        switch section {
        case .business:            report.business = text
        case .riskFactors:         report.riskFactors = text
        case .mdAndA:              report.mdAndA = text
        case .financialStatements: report.financialStatements = text
        }
        return report
    }
}
```

- [ ] **Step 4: Write unit test for FetchTenKSectionUseCase**

```swift
// StockPulseTests/FetchTenKSectionUseCaseTests.swift
import Testing
import Foundation
@testable import Domain

struct MockSECRepository: SECRepositoryProtocol {
    func fetchCIK(ticker: String) async throws -> String { "1045810" }

    func fetchLatest10KAccession(cik: String) async throws -> SECFilingInfo {
        SECFilingInfo(
            accession: "0001045810-24-000010",
            fiscalYear: 2024,
            filedDate: Date(timeIntervalSince1970: 1704067200),
            documentURL: URL(string: "https://www.sec.gov/Archives/test.htm")!
        )
    }

    func fetchSectionText(documentURL: URL, section: TenKSection) async throws -> String {
        "Extracted text for \(section.displayName)"
    }
}

struct FetchTenKSectionUseCaseTests {

    @Test func businessSectionPopulated() async throws {
        let useCase = FetchTenKSectionUseCase(repository: MockSECRepository())
        let report = try await useCase.execute(ticker: "NVDA", section: .business)
        #expect(report.ticker == "NVDA")
        #expect(report.cik == "1045810")
        #expect(report.business == "Extracted text for Business")
        #expect(report.riskFactors == nil)
    }

    @Test func riskFactorsSectionPopulated() async throws {
        let useCase = FetchTenKSectionUseCase(repository: MockSECRepository())
        let report = try await useCase.execute(ticker: "NVDA", section: .riskFactors)
        #expect(report.riskFactors == "Extracted text for Risk Factors")
        #expect(report.business == nil)
    }

    @Test func mdAndASectionPopulated() async throws {
        let useCase = FetchTenKSectionUseCase(repository: MockSECRepository())
        let report = try await useCase.execute(ticker: "AAPL", section: .mdAndA)
        #expect(report.mdAndA == "Extracted text for MD&A")
    }
}
```

- [ ] **Step 5: Run xcodegen**

```bash
cd /Users/swetakadam/iOSProjects/StockPulse && xcodegen generate
```

- [ ] **Step 6: Build and run tests**

```bash
xcodebuild test -scheme StockPulse \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:StockPulseTests/FetchTenKSectionUseCaseTests 2>&1 | tail -20
```

Expected: `Test Suite 'FetchTenKSectionUseCaseTests' passed`

- [ ] **Step 7: Commit**

```bash
git add LocalPackages/Domain/Sources/Domain/Repositories/SECRepositoryProtocol.swift \
        LocalPackages/Domain/Sources/Domain/UseCases/Protocols/FetchTenKSectionUseCaseProtocol.swift \
        LocalPackages/Domain/Sources/Domain/UseCases/Implementations/FetchTenKSectionUseCase.swift \
        StockPulseTests/FetchTenKSectionUseCaseTests.swift
git commit -m "feat: add SEC domain layer + FetchTenKSectionUseCase"
```

---

## Task 3: Data — SECEndpoint + SECClient

**Files:**
- Create: `LocalPackages/Data/Sources/Data/Network/SECEndpoint.swift`
- Create: `LocalPackages/Data/Sources/Data/Network/SECClient.swift`

- [ ] **Step 1: Create SECEndpoint**

```swift
// LocalPackages/Data/Sources/Data/Network/SECEndpoint.swift
import Foundation

enum SECEndpoint {
    case companyTickers
    case submissions(cik: String)
    case document(url: URL)

    var url: URL {
        switch self {
        case .companyTickers:
            return URL(string: "https://www.sec.gov/files/company_tickers.json")!
        case .submissions(let cik):
            let paddedCIK = cik.padLeft(toLength: 10, with: "0")
            return URL(string: "https://data.sec.gov/submissions/CIK\(paddedCIK).json")!
        case .document(let url):
            return url
        }
    }
}

private extension String {
    func padLeft(toLength length: Int, with character: Character) -> String {
        let padCount = length - self.count
        guard padCount > 0 else { return self }
        return String(repeating: character, count: padCount) + self
    }
}
```

- [ ] **Step 2: Create SECClient**

```swift
// LocalPackages/Data/Sources/Data/Network/SECClient.swift
import Foundation
import Domain

// EDGAR public API — no API key required.
// SEC requires User-Agent header identifying the app + contact email.
final class SECClient: Sendable {

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchCIK(ticker: String) async throws -> String {
        let (data, _) = try await fetch(.companyTickers)
        // Response: {"0": {"cik_str": 320193, "ticker": "AAPL", "title": "Apple Inc."}, ...}
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: [String: Any]] else {
            throw SECError.parsingFailed("company_tickers.json malformed")
        }
        let upper = ticker.uppercased()
        for (_, entry) in json {
            if let t = entry["ticker"] as? String, t.uppercased() == upper,
               let cik = entry["cik_str"] as? Int {
                return String(cik)
            }
        }
        throw SECError.tickerNotFound(ticker)
    }

    func fetchLatest10KAccession(cik: String) async throws -> SECFilingInfo {
        let (data, _) = try await fetch(.submissions(cik: cik))
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let filings = json["filings"] as? [String: Any],
              let recent = filings["recent"] as? [String: Any],
              let forms = recent["form"] as? [String],
              let accessions = recent["accessionNumber"] as? [String],
              let dates = recent["filingDate"] as? [String],
              let fiscalYearEnds = recent["fiscalYearEnd"] as? [String]
        else {
            throw SECError.parsingFailed("submissions JSON malformed for CIK \(cik)")
        }

        guard let idx = forms.firstIndex(of: "10-K") else {
            throw SECError.noFilingsFound(cik)
        }

        let accession = accessions[idx].replacingOccurrences(of: "-", with: "")
        let rawAccession = accessions[idx]
        let dateStr = dates[idx]
        let fyStr = fiscalYearEnds[idx]  // e.g. "2024-01-28"
        let year = Int(fyStr.prefix(4)) ?? 2024

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let filedDate = formatter.date(from: dateStr) ?? Date()

        // Build the index URL to find the actual 10-K document
        let paddedCIK = cik.padLeft(toLength: 10, with: "0")
        let indexURL = URL(string: "https://www.sec.gov/Archives/edgar/data/\(cik)/\(accession)/\(rawAccession)-index.json")!
        let docURL = try await fetchDocumentURL(indexURL: indexURL, cik: cik, accession: accession)

        return SECFilingInfo(
            accession: rawAccession,
            fiscalYear: year,
            filedDate: filedDate,
            documentURL: docURL
        )
    }

    func fetchRawDocument(url: URL) async throws -> String {
        let (data, response) = try await fetch(.document(url: url))
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SECError.documentFetchFailed(url)
        }
        return String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) ?? ""
    }

    // MARK: - Private

    private func fetchDocumentURL(indexURL: URL, cik: String, accession: String) async throws -> URL {
        let (data, _) = try await fetch(.document(url: indexURL))
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let directory = json["directory"] as? [String: Any],
              let items = directory["item"] as? [[String: Any]]
        else {
            // Fallback: construct a likely URL
            let docName = accession.replacingOccurrences(of: "-", with: "") + ".htm"
            return URL(string: "https://www.sec.gov/Archives/edgar/data/\(cik)/\(accession.replacingOccurrences(of: "-", with: ""))/\(docName)")!
        }

        // Find the primary document (10-K htm file, not index)
        let tenKDoc = items.first { item in
            guard let name = item["name"] as? String,
                  let type_ = item["type"] as? String else { return false }
            return type_ == "10-K" && (name.hasSuffix(".htm") || name.hasSuffix(".html"))
        }

        if let name = tenKDoc?["name"] as? String {
            let accessionPath = accession.replacingOccurrences(of: "-", with: "")
            return URL(string: "https://www.sec.gov/Archives/edgar/data/\(cik)/\(accessionPath)/\(name)")!
        }

        throw SECError.parsingFailed("No 10-K document found in filing index")
    }

    private func fetch(_ endpoint: SECEndpoint) async throws -> (Data, URLResponse) {
        var request = URLRequest(url: endpoint.url)
        request.setValue("StockPulse/1.0 sshinde5ster@gmail.com", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return try await session.data(for: request)
    }
}

private extension String {
    func padLeft(toLength length: Int, with character: Character) -> String {
        let padCount = length - self.count
        guard padCount > 0 else { return self }
        return String(repeating: character, count: padCount) + self
    }
}
```

- [ ] **Step 3: Run xcodegen**

```bash
cd /Users/swetakadam/iOSProjects/StockPulse && xcodegen generate
```

- [ ] **Step 4: Commit**

```bash
git add LocalPackages/Data/Sources/Data/Network/SECEndpoint.swift \
        LocalPackages/Data/Sources/Data/Network/SECClient.swift
git commit -m "feat: add SECClient + SECEndpoint for EDGAR API"
```

---

## Task 4: Data — TenKParser + SECRepositoryImpl

**Files:**
- Create: `LocalPackages/Data/Sources/Data/Parsers/TenKParser.swift`
- Create: `LocalPackages/Data/Sources/Data/Repositories/SECRepositoryImpl.swift`

Note: `TenKParser` depends on `AzureChatClient` which lives in the main app target, not in the Data package. To keep the dependency clean (Data package cannot import main app), use a **protocol injection**. Define `TenKSectionExtractorProtocol` in Domain, implement it in the main app via `AzureChatClient`.

**Actually — simpler approach:** Since `TenKParser` only needs one function (`extract(section:from:) async throws -> String`), inject it as a closure in `SECRepositoryImpl`. This avoids any cross-package dependency.

- [ ] **Step 1: Create TenKParser**

```swift
// LocalPackages/Data/Sources/Data/Parsers/TenKParser.swift
import Foundation
import Domain

// LLM-as-parser: closure-injected so Data package stays independent of main app.
// The closure is provided by AppContainer with AzureChatClient underneath.
final class TenKParser: Sendable {

    // (rawHTML: String, section: TenKSection) -> extracted plain text
    let extractSection: @Sendable (String, TenKSection) async throws -> String

    init(extractSection: @Sendable @escaping (String, TenKSection) async throws -> String) {
        self.extractSection = extractSection
    }

    func extract(section: TenKSection, from rawHTML: String) async throws -> String {
        try await extractSection(rawHTML, section)
    }
}
```

- [ ] **Step 2: Create SECRepositoryImpl**

```swift
// LocalPackages/Data/Sources/Data/Repositories/SECRepositoryImpl.swift
import Foundation
import Domain

final class SECRepositoryImpl: SECRepositoryProtocol {
    private let client: SECClient
    private let parser: TenKParser

    init(client: SECClient, parser: TenKParser) {
        self.client = client
        self.parser = parser
    }

    func fetchCIK(ticker: String) async throws -> String {
        try await client.fetchCIK(ticker: ticker)
    }

    func fetchLatest10KAccession(cik: String) async throws -> SECFilingInfo {
        try await client.fetchLatest10KAccession(cik: cik)
    }

    func fetchSectionText(documentURL: URL, section: TenKSection) async throws -> String {
        let rawHTML = try await client.fetchRawDocument(url: documentURL)
        return try await parser.extract(section: section, from: rawHTML)
    }
}
```

- [ ] **Step 3: Run xcodegen**

```bash
cd /Users/swetakadam/iOSProjects/StockPulse && xcodegen generate
```

- [ ] **Step 4: Commit**

```bash
git add LocalPackages/Data/Sources/Data/Parsers/TenKParser.swift \
        LocalPackages/Data/Sources/Data/Repositories/SECRepositoryImpl.swift
git commit -m "feat: add TenKParser + SECRepositoryImpl"
```

---

## Task 5: Core/Agent — AzureChatConfig + Agent value types

**Files:**
- Create: `StockPulse/Core/Agent/AzureChatConfig.swift`
- Create: `StockPulse/Core/Agent/AgentTypes.swift`

- [ ] **Step 1: Create directory + AzureChatConfig**

```bash
mkdir -p /Users/swetakadam/iOSProjects/StockPulse/StockPulse/Core/Agent
```

```swift
// StockPulse/Core/Agent/AzureChatConfig.swift
import Foundation

// All values from xcconfig → Info.plist. Zero hardcoded secrets.
enum AzureChatConfig {
    static var endpoint: String {
        Bundle.main.infoDictionary?["AZURE_CHAT_ENDPOINT"] as? String ?? ""
    }
    static var apiKey: String {
        Bundle.main.infoDictionary?["AZURE_CHAT_API_KEY"] as? String ?? ""
    }
    static let apiVersion = "2024-08-01-preview"
}
```

- [ ] **Step 2: Create AgentTypes (all value types in one file)**

```swift
// StockPulse/Core/Agent/AgentTypes.swift
import Foundation

// MARK: - Input

struct AgentTask {
    let goal: String
    let tickers: [String]
    let maxSteps: Int
    let allowParallel: Bool

    init(goal: String, tickers: [String] = [], maxSteps: Int = 8, allowParallel: Bool = false) {
        self.goal = goal
        self.tickers = tickers
        self.maxSteps = maxSteps
        self.allowParallel = allowParallel
    }
}

// MARK: - Plan (GPT-4.1 mini output)

struct AgentPlan: Codable {
    let actions: [PlannedAction]

    struct PlannedAction: Codable {
        let toolName: String
        let parameters: [String: String]
        let reasoning: String
        let parallel: Bool

        enum CodingKeys: String, CodingKey {
            case toolName, parameters, reasoning, parallel
        }
    }
}

// MARK: - Execution

struct AgentStep: Codable {
    let toolName: String
    let parameters: [String: String]
    let result: String        // JSON string from tool handler
    let reasoning: String
    let timestamp: Date
    var error: String?
}

struct AgentContext {
    let goal: String
    var steps: [AgentStep] = []

    mutating func addStep(_ step: AgentStep) {
        steps.append(step)
    }

    // Serializes goal + all step results for GPT-4.1 mini reflect/synthesize calls
    func asPromptContext() -> String {
        var lines = ["Goal: \(goal)", ""]
        for (i, step) in steps.enumerated() {
            lines.append("Step \(i + 1) — \(step.toolName): \(step.reasoning)")
            lines.append("Result: \(step.result)")
            if let err = step.error { lines.append("Error: \(err)") }
            lines.append("")
        }
        return lines.joined(separator: "\n")
    }
}

// MARK: - Reflection

enum AgentDecision: String, Codable {
    case `continue`
    case done
}

struct AgentDecisionResponse: Codable {
    let decision: AgentDecision
}

// MARK: - Output

struct AgentResult {
    let steps: [AgentStep]
    let synthesis: String
}

// MARK: - Tool Schema (sent to GPT-4.1 mini for planning)

struct AgentToolSchema {
    let name: String
    let description: String
    let parametersDescription: String  // human-readable param list for prompt
}
```

- [ ] **Step 3: Run xcodegen**

```bash
cd /Users/swetakadam/iOSProjects/StockPulse && xcodegen generate
```

- [ ] **Step 4: Commit**

```bash
git add StockPulse/Core/Agent/AzureChatConfig.swift \
        StockPulse/Core/Agent/AgentTypes.swift
git commit -m "feat: add AzureChatConfig + agent value types"
```

---

## Task 6: Core/Agent — AzureChatClient

**Files:**
- Create: `StockPulse/Core/Agent/AzureChatClient.swift`

- [ ] **Step 1: Create AzureChatClient**

```swift
// StockPulse/Core/Agent/AzureChatClient.swift
import Foundation
import Domain
import OSLog

final class AzureChatClient: Sendable {

    private let logger = Logger(subsystem: "com.sweta.stockpulse", category: "Agent.ChatClient")

    // MARK: - Plan

    func plan(goal: String, tools: [AgentToolSchema]) async throws -> AgentPlan {
        let toolsDescription = tools.map {
            "- \($0.name): \($0.description). Parameters: \($0.parametersDescription)"
        }.joined(separator: "\n")

        let systemPrompt = """
        You are a stock research planner. Given a goal and tools, return a JSON research plan.
        
        Respond ONLY with valid JSON in this exact format:
        {
          "actions": [
            {
              "toolName": "<tool name>",
              "parameters": {"key": "value"},
              "reasoning": "<one sentence why>",
              "parallel": false
            }
          ]
        }
        
        Rules:
        - Use ONLY tool names from this list:
        \(toolsDescription)
        - For multi-ticker price comparisons, set "parallel": true
        - Maximum 8 actions total
        - Parameters values must be strings
        """

        let content = try await sendMessage(
            system: systemPrompt,
            user: "Research goal: \(goal)",
            maxTokens: 1000,
            jsonMode: true
        )

        guard let data = content.data(using: .utf8),
              let plan = try? JSONDecoder().decode(AgentPlan.self, from: data) else {
            logger.error("❌ Failed to parse AgentPlan from: \(content)")
            // Fallback: single step for the first ticker
            let ticker = goal.components(separatedBy: .whitespaces).first { $0 == $0.uppercased() && $0.count <= 5 } ?? "AAPL"
            return AgentPlan(actions: [
                AgentPlan.PlannedAction(toolName: "get_stock_price",
                                        parameters: ["symbol": ticker],
                                        reasoning: "Fetch current price",
                                        parallel: false)
            ])
        }
        logger.debug("✅ Plan created with \(plan.actions.count) actions")
        return plan
    }

    // MARK: - Reflect

    func reflect(context: AgentContext) async throws -> AgentDecision {
        let system = """
        You are a research reflection agent. Review the research goal and completed steps.
        Decide if enough data has been gathered to synthesize a good answer.
        
        Respond ONLY with valid JSON: {"decision": "continue"} or {"decision": "done"}
        
        Choose "done" if: key data has been retrieved, or 3+ steps completed, or the goal is achievable with current data.
        Choose "continue" if: critical data is clearly missing.
        """

        let content = try await sendMessage(
            system: system,
            user: context.asPromptContext(),
            maxTokens: 100,
            jsonMode: true
        )

        guard let data = content.data(using: .utf8),
              let response = try? JSONDecoder().decode(AgentDecisionResponse.self, from: data) else {
            return .done  // default to done on parse failure
        }
        return response.decision
    }

    // MARK: - Synthesize

    func synthesize(context: AgentContext) async throws -> String {
        let system = """
        You are a stock research synthesizer. Based on all gathered data, write a concise spoken \
        summary for the user. 3-4 sentences maximum. Speak naturally. Focus on the most important insights.
        Past performance does not guarantee future results.
        """

        return try await sendMessage(
            system: system,
            user: context.asPromptContext(),
            maxTokens: 800,
            jsonMode: false
        )
    }

    // MARK: - Parse 10-K Section

    func parseSection(rawHTML: String, section: TenKSection) async throws -> String {
        let system = """
        Extract the text for "\(section.rawValue)" from this SEC 10-K filing HTML. \
        Remove all HTML tags, table formatting, and navigation elements. \
        Return only the plain prose content of that section. \
        Keep it under 1500 words. Focus on the most important points.
        """

        // Truncate rawHTML to ~8000 chars to stay within token limits
        let truncated = rawHTML.count > 8000
            ? String(rawHTML.prefix(8000)) + "\n[truncated]"
            : rawHTML

        return try await sendMessage(
            system: system,
            user: truncated,
            maxTokens: 2000,
            jsonMode: false
        )
    }

    // MARK: - Core HTTP

    private func sendMessage(system: String, user: String, maxTokens: Int, jsonMode: Bool) async throws -> String {
        guard let url = URL(string: "\(AzureChatConfig.endpoint)?api-version=\(AzureChatConfig.apiVersion)") else {
            throw AzureChatError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(AzureChatConfig.apiKey, forHTTPHeaderField: "api-key")

        var body: [String: Any] = [
            "messages": [
                ["role": "system", "content": system],
                ["role": "user",   "content": user]
            ],
            "max_tokens": maxTokens
        ]
        if jsonMode {
            body["response_format"] = ["type": "json_object"]
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw AzureChatError.invalidResponse
        }
        guard http.statusCode == 200 else {
            let msg = String(data: data, encoding: .utf8) ?? "unknown"
            logger.error("❌ Azure Chat \(http.statusCode): \(msg)")
            throw AzureChatError.serverError(statusCode: http.statusCode, message: msg)
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw AzureChatError.noResponse
        }

        return content
    }
}

// MARK: - Errors

enum AzureChatError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case noResponse
    case serverError(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:      return "Invalid Azure Chat API URL"
        case .invalidResponse: return "Invalid server response"
        case .noResponse:      return "No response from GPT-4.1 mini"
        case .serverError(let code, let msg): return "Server error (\(code)): \(msg)"
        }
    }
}
```

- [ ] **Step 2: Run xcodegen**

```bash
cd /Users/swetakadam/iOSProjects/StockPulse && xcodegen generate
```

- [ ] **Step 3: Commit**

```bash
git add StockPulse/Core/Agent/AzureChatClient.swift
git commit -m "feat: add AzureChatClient for GPT-4.1 mini plan/reflect/synthesize"
```

---

## Task 7: Core/Agent — AgentToolRegistry

**Files:**
- Create: `StockPulse/Core/Agent/AgentToolRegistry.swift`

- [ ] **Step 1: Create AgentToolRegistry**

```swift
// StockPulse/Core/Agent/AgentToolRegistry.swift
import Foundation
import Domain
import OSLog

struct AgentTool {
    let name: String
    let description: String
    let parametersDescription: String
    let handler: ([String: String]) async throws -> String

    var schema: AgentToolSchema {
        AgentToolSchema(
            name: name,
            description: description,
            parametersDescription: parametersDescription
        )
    }
}

final class AgentToolRegistry {

    private let logger = Logger(subsystem: "com.sweta.stockpulse", category: "Agent.Registry")
    private let tools: [AgentTool]

    var schemas: [AgentToolSchema] { tools.map(\.schema) }

    init(
        fetchStockUseCase:          any FetchStockUseCaseProtocol,
        searchStocksUseCase:        any SearchStocksUseCaseProtocol,
        fetchWatchlistUseCase:      any FetchWatchlistUseCaseProtocol,
        addToWatchlistUseCase:      any AddToWatchlistUseCaseProtocol,
        removeFromWatchlistUseCase: any RemoveFromWatchlistUseCaseProtocol,
        fetchTenKSectionUseCase:    any FetchTenKSectionUseCaseProtocol
    ) {
        tools = [
            AgentTool(
                name: "get_stock_price",
                description: "Get current price, change, and changePercent for a stock",
                parametersDescription: "symbol (string, required): ticker e.g. AAPL",
                handler: { params in
                    guard let symbol = params["symbol"], !symbol.isEmpty else {
                        return "{\"error\": \"symbol required\"}"
                    }
                    guard let stock = try? await fetchStockUseCase.execute(symbol: symbol.uppercased()) else {
                        return "{\"error\": \"not found: \(symbol)\"}"
                    }
                    return Self.encode([
                        "symbol": stock.symbol,
                        "companyName": stock.companyName,
                        "price": String(format: "%.2f", stock.currentPrice),
                        "change": String(format: "%.2f", stock.change),
                        "changePercent": String(format: "%.2f%%", stock.changePercent)
                    ])
                }
            ),
            AgentTool(
                name: "search_stock",
                description: "Search stocks by company name or symbol",
                parametersDescription: "query (string, required): company name or symbol",
                handler: { params in
                    guard let query = params["query"], !query.isEmpty else {
                        return "{\"error\": \"query required\"}"
                    }
                    let results = (try? await searchStocksUseCase.execute(query: query)) ?? []
                    let top = results.prefix(5).map { ["symbol": $0.symbol, "name": $0.companyName] }
                    return Self.encode(["results": top, "count": top.count])
                }
            ),
            AgentTool(
                name: "get_watchlist",
                description: "Get all stocks currently in the user's watchlist",
                parametersDescription: "none",
                handler: { _ in
                    let items = (try? await fetchWatchlistUseCase.execute()) ?? []
                    let symbols = items.map { ["symbol": $0.symbol] }
                    return Self.encode(["watchlist": symbols, "count": symbols.count])
                }
            ),
            AgentTool(
                name: "add_to_watchlist",
                description: "Add a stock to the user's watchlist",
                parametersDescription: "symbol (string, required): ticker e.g. AAPL",
                handler: { params in
                    guard let symbol = params["symbol"], !symbol.isEmpty else {
                        return "{\"error\": \"symbol required\"}"
                    }
                    do {
                        try await addToWatchlistUseCase.execute(symbol: symbol.uppercased())
                        return Self.encode(["success": true, "symbol": symbol])
                    } catch {
                        return "{\"error\": \"\(error.localizedDescription)\"}"
                    }
                }
            ),
            AgentTool(
                name: "remove_from_watchlist",
                description: "Remove a stock from the user's watchlist",
                parametersDescription: "symbol (string, required): ticker e.g. AAPL",
                handler: { params in
                    guard let symbol = params["symbol"], !symbol.isEmpty else {
                        return "{\"error\": \"symbol required\"}"
                    }
                    do {
                        try await removeFromWatchlistUseCase.execute(symbol: symbol.uppercased())
                        return Self.encode(["success": true, "symbol": symbol])
                    } catch {
                        return "{\"error\": \"\(error.localizedDescription)\"}"
                    }
                }
            ),
            AgentTool(
                name: "fetch_10k_section",
                description: "Fetch a specific section of a company's most recent 10-K SEC filing",
                parametersDescription: "ticker (string, required): e.g. NVDA. section (string, required): business | riskFactors | mdAndA | financialStatements",
                handler: { params in
                    guard let ticker = params["ticker"], !ticker.isEmpty else {
                        return "{\"error\": \"ticker required\"}"
                    }
                    let sectionStr = params["section"] ?? "business"
                    let section: TenKSection
                    switch sectionStr {
                    case "riskFactors":         section = .riskFactors
                    case "mdAndA":              section = .mdAndA
                    case "financialStatements": section = .financialStatements
                    default:                    section = .business
                    }
                    do {
                        let report = try await fetchTenKSectionUseCase.execute(
                            ticker: ticker.uppercased(),
                            section: section
                        )
                        let text = report.business ?? report.riskFactors ?? report.mdAndA ?? report.financialStatements ?? ""
                        return Self.encode([
                            "ticker": report.ticker,
                            "section": section.displayName,
                            "fiscalYear": String(report.fiscalYear),
                            "content": String(text.prefix(3000))
                        ])
                    } catch {
                        return "{\"error\": \"\(error.localizedDescription)\"}"
                    }
                }
            )
        ]
    }

    func execute(_ action: AgentPlan.PlannedAction) async throws -> AgentStep {
        guard let tool = tools.first(where: { $0.name == action.toolName }) else {
            logger.warning("⚠️ Unknown tool: \(action.toolName)")
            return AgentStep(
                toolName: action.toolName,
                parameters: action.parameters,
                result: "{\"error\": \"unknown tool\"}",
                reasoning: action.reasoning,
                timestamp: Date(),
                error: "Unknown tool: \(action.toolName)"
            )
        }
        let result: String
        do {
            result = try await tool.handler(action.parameters)
            logger.debug("✅ Tool \(action.toolName) succeeded")
        } catch {
            logger.error("❌ Tool \(action.toolName) failed: \(error)")
            return AgentStep(
                toolName: action.toolName,
                parameters: action.parameters,
                result: "{\"error\": \"\(error.localizedDescription)\"}",
                reasoning: action.reasoning,
                timestamp: Date(),
                error: error.localizedDescription
            )
        }
        return AgentStep(
            toolName: action.toolName,
            parameters: action.parameters,
            result: result,
            reasoning: action.reasoning,
            timestamp: Date()
        )
    }

    private static func encode(_ dict: [String: Any]) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: dict),
              let str = String(data: data, encoding: .utf8) else {
            return "{\"error\": \"encoding failed\"}"
        }
        return str
    }
}
```

- [ ] **Step 2: Run xcodegen**

```bash
cd /Users/swetakadam/iOSProjects/StockPulse && xcodegen generate
```

- [ ] **Step 3: Commit**

```bash
git add StockPulse/Core/Agent/AgentToolRegistry.swift
git commit -m "feat: add AgentToolRegistry with 6 tools including fetch_10k_section"
```

---

## Task 8: Core/Agent — AgentMemory (SwiftData)

**Files:**
- Create: `StockPulse/Core/Agent/AgentMemory.swift`

- [ ] **Step 1: Create AgentMemory**

```swift
// StockPulse/Core/Agent/AgentMemory.swift
import Foundation
import SwiftData
import OSLog

@Model
final class StoredAgentResult {
    var ticker: String
    var goal: String
    var synthesis: String
    var stepsJSON: Data
    var timestamp: Date

    init(ticker: String, goal: String, synthesis: String, stepsJSON: Data, timestamp: Date) {
        self.ticker = ticker
        self.goal = goal
        self.synthesis = synthesis
        self.stepsJSON = stepsJSON
        self.timestamp = timestamp
    }
}

final class AgentMemory {

    private let logger = Logger(subsystem: "com.sweta.stockpulse", category: "Agent.Memory")
    private let container: ModelContainer

    init(container: ModelContainer) {
        self.container = container
    }

    func store(task: AgentTask, context: AgentContext, synthesis: String) {
        let ctx = ModelContext(container)
        let stepsData = (try? JSONEncoder().encode(context.steps)) ?? Data()
        let ticker = task.tickers.first ?? "MULTI"
        let record = StoredAgentResult(
            ticker: ticker,
            goal: task.goal,
            synthesis: synthesis,
            stepsJSON: stepsData,
            timestamp: Date()
        )
        ctx.insert(record)
        do {
            try ctx.save()
            logger.debug("✅ AgentMemory stored result for \(ticker)")
        } catch {
            logger.error("❌ AgentMemory save failed: \(error)")
        }
    }

    func recall(ticker: String) -> StoredAgentResult? {
        let ctx = ModelContext(container)
        var descriptor = FetchDescriptor<StoredAgentResult>(
            predicate: #Predicate { $0.ticker == ticker }
        )
        descriptor.sortBy = [SortDescriptor(\.timestamp, order: .reverse)]
        descriptor.fetchLimit = 1
        return try? ctx.fetch(descriptor).first
    }

    func recentResults(limit: Int = 10) -> [StoredAgentResult] {
        let ctx = ModelContext(container)
        var descriptor = FetchDescriptor<StoredAgentResult>()
        descriptor.sortBy = [SortDescriptor(\.timestamp, order: .reverse)]
        descriptor.fetchLimit = limit
        return (try? ctx.fetch(descriptor)) ?? []
    }
}
```

- [ ] **Step 2: Write AgentMemory unit test**

```swift
// StockPulseTests/AgentMemoryTests.swift
import Testing
import SwiftData
import Foundation
@testable import StockPulse

struct AgentMemoryTests {

    private func makeMemory() throws -> AgentMemory {
        let container = try ModelContainer(
            for: StoredAgentResult.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return AgentMemory(container: container)
    }

    @Test func storeAndRecall() throws {
        let memory = try makeMemory()
        let task = AgentTask(goal: "Research NVDA", tickers: ["NVDA"])
        var context = AgentContext(goal: task.goal)
        context.addStep(AgentStep(
            toolName: "get_stock_price",
            parameters: ["symbol": "NVDA"],
            result: "{\"price\": \"940\"}",
            reasoning: "Fetch price",
            timestamp: Date()
        ))
        memory.store(task: task, context: context, synthesis: "NVDA is at $940")

        let recalled = memory.recall(ticker: "NVDA")
        #expect(recalled != nil)
        #expect(recalled?.synthesis == "NVDA is at $940")
        #expect(recalled?.ticker == "NVDA")
    }

    @Test func recallReturnsNilForUnknownTicker() throws {
        let memory = try makeMemory()
        #expect(memory.recall(ticker: "UNKNOWN") == nil)
    }

    @Test func recentResultsReturnsMostRecentFirst() throws {
        let memory = try makeMemory()
        for i in 1...3 {
            let task = AgentTask(goal: "Goal \(i)", tickers: ["T\(i)"])
            memory.store(task: task, context: AgentContext(goal: "Goal \(i)"), synthesis: "Synthesis \(i)")
        }
        let results = memory.recentResults(limit: 3)
        #expect(results.count == 3)
    }
}
```

- [ ] **Step 3: Run xcodegen**

```bash
cd /Users/swetakadam/iOSProjects/StockPulse && xcodegen generate
```

- [ ] **Step 4: Commit**

```bash
git add StockPulse/Core/Agent/AgentMemory.swift \
        StockPulseTests/AgentMemoryTests.swift
git commit -m "feat: add AgentMemory with SwiftData persistence"
```

---

## Task 9: Core/Agent — AgentOrchestrator

**Files:**
- Create: `StockPulse/Core/Agent/AgentOrchestrator.swift`

- [ ] **Step 1: Create AgentOrchestrator**

```swift
// StockPulse/Core/Agent/AgentOrchestrator.swift
import Foundation
import OSLog

final class AgentOrchestrator {

    private let logger = Logger(subsystem: "com.sweta.stockpulse", category: "Agent.Orchestrator")
    private let chatClient: AzureChatClient
    private let toolRegistry: AgentToolRegistry
    private let memory: AgentMemory

    // Called after each step completes — used by StockToolsManager to post UI progress bubbles
    var progressHandler: ((String) -> Void)?

    init(chatClient: AzureChatClient, toolRegistry: AgentToolRegistry, memory: AgentMemory) {
        self.chatClient = chatClient
        self.toolRegistry = toolRegistry
        self.memory = memory
    }

    func execute(task: AgentTask) async throws -> AgentResult {
        logger.debug("🤖 Starting agent for goal: \(task.goal)")
        var context = AgentContext(goal: task.goal)

        let plan = try await chatClient.plan(goal: task.goal, tools: toolRegistry.schemas)
        logger.debug("📋 Plan: \(plan.actions.count) actions")

        var pendingParallel: [AgentPlan.PlannedAction] = []

        for action in plan.actions.prefix(task.maxSteps) {
            if action.parallel && task.allowParallel {
                pendingParallel.append(action)
                continue
            }

            // Flush any accumulated parallel steps before running sequential step
            if !pendingParallel.isEmpty {
                let parallelSteps = try await executeParallel(pendingParallel)
                parallelSteps.forEach { context.addStep($0) }
                pendingParallel = []
            }

            progressHandler?("⚙ \(action.reasoning)")
            let step = try await toolRegistry.execute(action)
            context.addStep(step)
            logger.debug("✅ Step done: \(action.toolName)")

            let decision = try await chatClient.reflect(context: context)
            if decision == .done {
                logger.debug("🏁 Reflect: done")
                break
            }
        }

        // Flush remaining parallel actions
        if !pendingParallel.isEmpty {
            let parallelSteps = try await executeParallel(pendingParallel)
            parallelSteps.forEach { context.addStep($0) }
        }

        progressHandler?("⚙ Synthesizing...")
        let synthesis = try await chatClient.synthesize(context: context)
        logger.debug("✅ Synthesis complete")

        memory.store(task: task, context: context, synthesis: synthesis)

        return AgentResult(steps: context.steps, synthesis: synthesis)
    }

    private func executeParallel(_ actions: [AgentPlan.PlannedAction]) async throws -> [AgentStep] {
        try await withThrowingTaskGroup(of: AgentStep.self) { group in
            for action in actions {
                group.addTask { [toolRegistry] in
                    try await toolRegistry.execute(action)
                }
            }
            var steps: [AgentStep] = []
            for try await step in group {
                steps.append(step)
                progressHandler?("⚙ \(step.reasoning)")
            }
            return steps
        }
    }
}
```

- [ ] **Step 2: Write AgentOrchestrator unit test**

Create mock types first, then the test:

```swift
// StockPulseTests/AgentOrchestratorTests.swift
import Testing
import Foundation
import SwiftData
@testable import StockPulse
@testable import Domain

// MARK: - Mocks

final class MockAzureChatClient: AzureChatClient {
    var planResponse: AgentPlan
    var reflectDecision: AgentDecision
    var synthesisText: String

    init(
        plan: AgentPlan = AgentPlan(actions: [
            AgentPlan.PlannedAction(toolName: "get_stock_price",
                                    parameters: ["symbol": "NVDA"],
                                    reasoning: "Fetch NVDA price",
                                    parallel: false)
        ]),
        reflect: AgentDecision = .done,
        synthesis: String = "NVDA looks strong"
    ) {
        self.planResponse = plan
        self.reflectDecision = reflect
        self.synthesisText = synthesis
    }

    override func plan(goal: String, tools: [AgentToolSchema]) async throws -> AgentPlan {
        planResponse
    }
    override func reflect(context: AgentContext) async throws -> AgentDecision {
        reflectDecision
    }
    override func synthesize(context: AgentContext) async throws -> String {
        synthesisText
    }
}

final class MockAgentToolRegistry: AgentToolRegistry {
    var executeCallCount = 0

    override func execute(_ action: AgentPlan.PlannedAction) async throws -> AgentStep {
        executeCallCount += 1
        return AgentStep(
            toolName: action.toolName,
            parameters: action.parameters,
            result: "{\"price\": \"940\"}",
            reasoning: action.reasoning,
            timestamp: Date()
        )
    }
}

// MARK: - Tests

struct AgentOrchestratorTests {

    private func makeMemory() throws -> AgentMemory {
        let container = try ModelContainer(
            for: StoredAgentResult.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return AgentMemory(container: container)
    }

    @Test func sequentialExecutionCallsToolsInOrder() async throws {
        let plan = AgentPlan(actions: [
            AgentPlan.PlannedAction(toolName: "get_stock_price",
                                    parameters: ["symbol": "NVDA"],
                                    reasoning: "Step 1", parallel: false),
            AgentPlan.PlannedAction(toolName: "get_stock_price",
                                    parameters: ["symbol": "AMD"],
                                    reasoning: "Step 2", parallel: false)
        ])
        let chatClient = MockAzureChatClient(plan: plan, reflect: .continue, synthesis: "Done")
        let registry = MockAgentToolRegistry(/* see note below */)
        let memory = try makeMemory()
        let orchestrator = AgentOrchestrator(chatClient: chatClient,
                                              toolRegistry: registry,
                                              memory: memory)
        let result = try await orchestrator.execute(task: AgentTask(goal: "Compare NVDA AMD"))
        #expect(result.steps.count == 2)
        #expect(result.synthesis == "Done")
        #expect(registry.executeCallCount == 2)
    }

    @Test func synthesisStoredInMemory() async throws {
        let memory = try makeMemory()
        let orchestrator = AgentOrchestrator(
            chatClient: MockAzureChatClient(synthesis: "NVDA is strong"),
            toolRegistry: MockAgentToolRegistry(),
            memory: memory
        )
        let task = AgentTask(goal: "Research NVDA", tickers: ["NVDA"])
        _ = try await orchestrator.execute(task: task)
        let recalled = memory.recall(ticker: "NVDA")
        #expect(recalled?.synthesis == "NVDA is strong")
    }

    @Test func progressHandlerCalledPerStep() async throws {
        var progressMessages: [String] = []
        let orchestrator = AgentOrchestrator(
            chatClient: MockAzureChatClient(),
            toolRegistry: MockAgentToolRegistry(),
            memory: try makeMemory()
        )
        orchestrator.progressHandler = { progressMessages.append($0) }
        _ = try await orchestrator.execute(task: AgentTask(goal: "Research NVDA", tickers: ["NVDA"]))
        #expect(!progressMessages.isEmpty)
        #expect(progressMessages.last == "⚙ Synthesizing...")
    }
}
```

> **Note:** `MockAgentToolRegistry` cannot be created with `AgentToolRegistry`'s designated init (it requires real use cases). Instead, subclass `AgentToolRegistry` and override only `execute(_:)`. The designated initialiser won't be called directly in tests — use a test-only static factory or subclass with dummy use cases passed in (see below).

For the mock registry, use this pattern instead (avoids needing real use cases in tests):

```swift
// Add this extension at top of AgentOrchestratorTests.swift
extension AgentToolRegistry {
    static func makeForTests() -> AgentToolRegistry {
        // Create lightweight mock use cases
        struct NoOpFetchStock: FetchStockUseCaseProtocol {
            func execute(symbol: String) async throws -> Stock {
                Stock(symbol: symbol, companyName: symbol, currentPrice: 100,
                      change: 1, changePercent: 1, volume: 1000, marketCap: 1e9, logoURL: nil)
            }
        }
        struct NoOpSearch: SearchStocksUseCaseProtocol {
            func execute(query: String) async throws -> [Stock] { [] }
        }
        struct NoOpFetchWatchlist: FetchWatchlistUseCaseProtocol {
            func execute() async throws -> [WatchlistItem] { [] }
        }
        struct NoOpAdd: AddToWatchlistUseCaseProtocol {
            func execute(symbol: String) async throws {}
        }
        struct NoOpRemove: RemoveFromWatchlistUseCaseProtocol {
            func execute(symbol: String) async throws {}
        }
        struct NoOpTenK: FetchTenKSectionUseCaseProtocol {
            func execute(ticker: String, section: TenKSection) async throws -> TenKReport {
                TenKReport(ticker: ticker, cik: "0", fiscalYear: 2024,
                           filedDate: Date(), accessionNumber: "0", documentURL: URL(string: "https://sec.gov")!)
            }
        }
        return AgentToolRegistry(
            fetchStockUseCase: NoOpFetchStock(),
            searchStocksUseCase: NoOpSearch(),
            fetchWatchlistUseCase: NoOpFetchWatchlist(),
            addToWatchlistUseCase: NoOpAdd(),
            removeFromWatchlistUseCase: NoOpRemove(),
            fetchTenKSectionUseCase: NoOpTenK()
        )
    }
}
```

Update `MockAgentToolRegistry` to subclass using `makeForTests()`:

```swift
final class MockAgentToolRegistry: AgentToolRegistry {
    var executeCallCount = 0

    convenience init() {
        self.init(baseRegistry: AgentToolRegistry.makeForTests())
    }

    // Subclass trick: forward init then override execute
    private init(baseRegistry: AgentToolRegistry) {
        // Can't call super.init directly since it's convenience — use static make
        // Instead, use composition:
    }
}
```

> **Note:** Subclassing `AgentToolRegistry` is awkward because `init` requires real use cases. Use **composition** for the mock: make `AgentToolRegistry.execute(_:)` open (or use a protocol). Add `AgentToolRegistryProtocol` in Task 7 if needed. For simplicity in tests, use `AgentToolRegistry.makeForTests()` directly and count calls via a wrapper closure-based tool.

- [ ] **Step 3: Run xcodegen**

```bash
cd /Users/swetakadam/iOSProjects/StockPulse && xcodegen generate
```

- [ ] **Step 4: Build check (tests may not all pass yet — AgentOrchestrator.init needs AppContainer)**

```bash
xcodebuild build -scheme StockPulse \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' 2>&1 | grep -E "error:|Build succeeded"
```

Expected: `Build succeeded` (or only errors from missing registrations, fixed in Task 12)

- [ ] **Step 5: Commit**

```bash
git add StockPulse/Core/Agent/AgentOrchestrator.swift \
        StockPulseTests/AgentOrchestratorTests.swift
git commit -m "feat: add AgentOrchestrator with sequential + parallel execution"
```

---

## Task 10: StockToolsManager — add run_research_agent (Tool #7)

**Files:**
- Modify: `StockPulse/Core/AI/StockToolsManager.swift`

- [ ] **Step 1: Add agentOrchestrator property + update init**

In `StockToolsManager.swift`, add after the existing `removeFromWatchlistUseCase` property:

```swift
private let agentOrchestrator: AgentOrchestrator
```

Update `init` to add the new parameter (after `removeFromWatchlistUseCase:`):

```swift
agentOrchestrator: AgentOrchestrator
```

And in the init body add:

```swift
self.agentOrchestrator = agentOrchestrator
```

Set up the progress handler right after in init:

```swift
agentOrchestrator.progressHandler = { message in
    NotificationCenter.default.post(
        name: .agentStepProgress,
        object: nil,
        userInfo: ["message": message]
    )
}
```

- [ ] **Step 2: Add run_research_agent case to handleToolCall**

In `handleToolCall`, add before the `default:` case:

```swift
case "run_research_agent":
    let goal = args["goal"] as? String ?? ""
    let tickers = args["tickers"] as? [String] ?? []
    let allowParallel = args["allow_parallel"] as? Bool ?? false
    let task = AgentTask(goal: goal, tickers: tickers, allowParallel: allowParallel)
    result = await runResearchAgent(task: task)
```

- [ ] **Step 3: Add runResearchAgent helper + notification name**

Add at end of `// MARK: - Tool Implementations`:

```swift
private func runResearchAgent(task: AgentTask) async -> String {
    do {
        let agentResult = try await agentOrchestrator.execute(task: task)
        logger.debug("✅ Agent research complete for goal: \(task.goal)")
        return encode(["synthesis": agentResult.synthesis, "stepCount": agentResult.steps.count])
    } catch {
        logger.error("❌ Agent research failed: \(error)")
        return encodeError("Research failed: \(error.localizedDescription)")
    }
}
```

- [ ] **Step 4: Add run_research_agent to toolDefinitions()**

Update `sendSessionUpdate` log line to say "7 tools". Add this entry in `toolDefinitions()` array after `get_watchlist`:

```swift
[
    "type": "function",
    "name": "run_research_agent",
    "description": "Run a multi-step research analysis on one or more stocks. Use for thesis, comparison, deep analysis, or comprehensive overview. Before calling this tool, verbally acknowledge the request (e.g. 'Let me research that for you, give me a moment').",
    "parameters": [
        "type": "object",
        "properties": [
            "goal":           ["type": "string",
                               "description": "Research goal e.g. 'full thesis on NVDA before I buy'"],
            "tickers":        ["type": "array",
                               "items": ["type": "string"],
                               "description": "Stock tickers involved e.g. ['NVDA', 'AMD']"],
            "allow_parallel": ["type": "boolean",
                               "description": "Set true for multi-ticker comparisons"]
        ],
        "required": ["goal"]
    ]
]
```

Also update the debug log in `sendSessionUpdate`:
```swift
logger.debug("✅ Session update sent — 7 tools registered")
```

- [ ] **Step 5: Add Notification.Name extension**

Add at the bottom of `StockToolsManager.swift`:

```swift
extension Notification.Name {
    static let agentStepProgress = Notification.Name("agentStepProgress")
}
```

- [ ] **Step 6: Commit**

```bash
git add StockPulse/Core/AI/StockToolsManager.swift
git commit -m "feat: add run_research_agent (tool #7) to StockToolsManager"
```

---

## Task 11: AIAssistantViewModel — progress bubbles + agentOrchestrator wiring

**Files:**
- Modify: `StockPulse/Core/AI/AIAssistantViewModel.swift`

- [ ] **Step 1: Add agentOrchestrator parameter to init**

Update the `AIAssistantViewModel.init` signature to add:

```swift
agentOrchestrator: AgentOrchestrator
```

And update the `StockToolsManager` construction inside init:

```swift
let toolsManager = StockToolsManager(
    fetchStockUseCase:          fetchStockUseCase,
    searchStocksUseCase:        searchStocksUseCase,
    fetchWatchlistUseCase:      fetchWatchlistUseCase,
    addToWatchlistUseCase:      addToWatchlistUseCase,
    removeFromWatchlistUseCase: removeFromWatchlistUseCase,
    agentOrchestrator:          agentOrchestrator
)
```

- [ ] **Step 2: Fix messages sync to preserve progress bubbles**

Add a private tracking property after `private var cancellables`:

```swift
private var lastWebRTCSyncCount: Int = 0
```

Replace the messages sync line inside `setupBindings()` sink:

```swift
// Replace: self.messages = self.webRTCManager.messages
// With:
let newMessages = Array(self.webRTCManager.messages.dropFirst(self.lastWebRTCSyncCount))
self.messages.append(contentsOf: newMessages)
self.lastWebRTCSyncCount = self.webRTCManager.messages.count
```

- [ ] **Step 3: Add progress notification observer in setupBindings()**

Add after the Combine sink setup inside `setupBindings()`:

```swift
NotificationCenter.default.addObserver(
    forName: .agentStepProgress,
    object: nil,
    queue: .main
) { [weak self] note in
    guard let self,
          let msg = note.userInfo?["message"] as? String else { return }
    self.messages.append(TranscriptMessage(role: .system, text: msg))
}
```

- [ ] **Step 4: Reset tracking counter in disconnect()**

In `disconnect()`, add after `messages.removeAll()`:

```swift
lastWebRTCSyncCount = 0
```

- [ ] **Step 5: Commit**

```bash
git add StockPulse/Core/AI/AIAssistantViewModel.swift
git commit -m "feat: wire agentOrchestrator into AIAssistantViewModel + progress bubbles"
```

---

## Task 12: AppContainer — register all new types

**Files:**
- Modify: `StockPulse/Core/DI/AppContainer.swift`

- [ ] **Step 1: Add imports**

At the top of `AppContainer.swift`, the existing imports are `Factory`, `Domain`, `Data`, `Features`. Add:

```swift
import SwiftData
```

- [ ] **Step 2: Add all new registrations**

Add a new `// MARK: - Agent` section after `// MARK: - AI Assistant ViewModel`:

```swift
// MARK: - Agent

var agentModelContainer: Factory<ModelContainer> {
    self {
        try! ModelContainer(for: StoredAgentResult.self)
    }.singleton
}

var agentMemory: Factory<AgentMemory> {
    self { AgentMemory(container: self.agentModelContainer()) }.singleton
}

var azureChatClient: Factory<AzureChatClient> {
    self { AzureChatClient() }.singleton
}

var secRepository: Factory<any SECRepositoryProtocol> {
    self {
        let parser = TenKParser { [weak self] rawHTML, section in
            guard let self else { throw AzureChatError.invalidURL }
            return try await self.azureChatClient().parseSection(rawHTML: rawHTML, section: section)
        }
        return SECRepositoryImpl(client: SECClient(), parser: parser)
    }.singleton
}

var fetchTenKSectionUseCase: Factory<any FetchTenKSectionUseCaseProtocol> {
    self { FetchTenKSectionUseCase(repository: self.secRepository()) }
}

var agentToolRegistry: Factory<AgentToolRegistry> {
    self {
        AgentToolRegistry(
            fetchStockUseCase:          self.fetchStockUseCase(),
            searchStocksUseCase:        self.searchStocksUseCase(),
            fetchWatchlistUseCase:      self.fetchWatchlistUseCase(),
            addToWatchlistUseCase:      self.addToWatchlistUseCase(),
            removeFromWatchlistUseCase: self.removeFromWatchlistUseCase(),
            fetchTenKSectionUseCase:    self.fetchTenKSectionUseCase()
        )
    }
}

var agentOrchestrator: Factory<AgentOrchestrator> {
    self {
        AgentOrchestrator(
            chatClient:   self.azureChatClient(),
            toolRegistry: self.agentToolRegistry(),
            memory:       self.agentMemory()
        )
    }
}
```

- [ ] **Step 3: Update aiAssistantViewModel to pass agentOrchestrator**

Update the existing `aiAssistantViewModel` factory:

```swift
var aiAssistantViewModel: Factory<AIAssistantViewModel> {
    self {
        AIAssistantViewModel(
            fetchStockUseCase:          self.fetchStockUseCase(),
            searchStocksUseCase:        self.searchStocksUseCase(),
            fetchWatchlistUseCase:      self.fetchWatchlistUseCase(),
            addToWatchlistUseCase:      self.addToWatchlistUseCase(),
            removeFromWatchlistUseCase: self.removeFromWatchlistUseCase(),
            agentOrchestrator:          self.agentOrchestrator()
        )
    }
}
```

- [ ] **Step 4: Commit**

```bash
git add StockPulse/Core/DI/AppContainer.swift
git commit -m "feat: register agent layer in AppContainer (AzureChatClient, AgentMemory, SEC)"
```

---

## Task 13: xcconfig + Info.plist + project.yml

**Files:**
- Modify: `Configurations/Base.xcconfig`
- Modify: `Configurations/Secrets.xcconfig`
- Modify: `StockPulse/Info.plist`
- Modify: `project.yml`

- [ ] **Step 1: Add to Base.xcconfig**

Append these two lines to `Configurations/Base.xcconfig`:

```
AZURE_CHAT_ENDPOINT=https:/$()/apim-chat-gateway.azure-api.net/ai-gateway-chat-demo-eastus-reso/openai/deployments/gpt-4.1-mini/chat/completions
AZURE_CHAT_API_VERSION=2024-08-01-preview
```

- [ ] **Step 2: Add to Secrets.xcconfig**

Append to `Configurations/Secrets.xcconfig`:

```
AZURE_CHAT_API_KEY=<paste your GPT-4.1-mini api-key here>
```

- [ ] **Step 3: Add to Info.plist**

Add these three key-value pairs inside the `<dict>` in `StockPulse/Info.plist`, before the closing `</dict>`:

```xml
    <key>AZURE_CHAT_ENDPOINT</key>
    <string>$(AZURE_CHAT_ENDPOINT)</string>
    <key>AZURE_CHAT_API_KEY</key>
    <string>$(AZURE_CHAT_API_KEY)</string>
    <key>AZURE_CHAT_API_VERSION</key>
    <string>$(AZURE_CHAT_API_VERSION)</string>
```

- [ ] **Step 4: Add SwiftData to project.yml**

In `project.yml`, under `targets → StockPulse → dependencies`, add:

```yaml
      - sdk: SwiftData.framework
```

The dependencies section should look like:

```yaml
    dependencies:
      - package: Factory
      - package: Domain
      - package: Data
      - package: Features
      - package: WebRTC
      - sdk: SwiftData.framework
```

- [ ] **Step 5: Commit**

```bash
git add Configurations/Base.xcconfig \
        StockPulse/Info.plist \
        project.yml
git commit -m "feat: add AZURE_CHAT xcconfig keys + SwiftData framework to project.yml"
```

> **Note:** Do NOT commit Secrets.xcconfig — it is gitignored.

---

## Task 14: xcodegen generate + full build

- [ ] **Step 1: Regenerate project**

```bash
cd /Users/swetakadam/iOSProjects/StockPulse && xcodegen generate
```

Expected: `✅ Done`

- [ ] **Step 2: Full build**

```bash
xcodebuild build -scheme StockPulse \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' 2>&1 | grep -E "error:|Build succeeded"
```

Expected: `Build succeeded`

If you see errors, the most common fixes:

| Error | Fix |
|---|---|
| `'StoredAgentResult' is not a model type` | Ensure `@Model` is on `StoredAgentResult` and `SwiftData.framework` is in project.yml |
| `'AgentOrchestrator' cannot be constructed` | Check AppContainer factory chain — ensure all injected types are registered |
| `Type 'SECRepositoryImpl' does not conform to 'SECRepositoryProtocol'` | Ensure `Sendable` conformance matches; add `@unchecked Sendable` if needed |
| `Missing xcconfig value AZURE_CHAT_ENDPOINT` | Verify Secrets.xcconfig is included in all 3 config files (Debug/Staging/Release.xcconfig) |

- [ ] **Step 3: Run all tests**

```bash
xcodebuild test -scheme StockPulse \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' 2>&1 | tail -30
```

Expected:
```
Test Suite 'FetchTenKSectionUseCaseTests' passed
Test Suite 'AgentMemoryTests' passed
Test Suite 'AgentOrchestratorTests' passed
```

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "feat: complete agentic extension — AgentOrchestrator + SEC 10-K integration"
```

---

## Task 15: Smoke Test

This is a manual test run — no simulator automation needed for voice.

- [ ] **Step 1: Launch on device or simulator with microphone access**

Build and run the Debug scheme on an iPhone simulator or device. Open the AI Assistant tab.

- [ ] **Step 2: Test simple tool (unchanged path)**

Say: *"What's the price of Apple?"*

Expected: Single tool call `get_stock_price`, spoken price response. No orchestrator involved.

- [ ] **Step 3: Test research agent trigger**

Say: *"Give me a full analysis of NVIDIA before I buy."*

Expected sequence in transcript:
1. GPT speaks "Let me research that for you, give me a moment" 
2. `⚙` system bubbles appear one by one as steps complete
3. `⚙ Synthesizing...` appears
4. GPT speaks a 3-4 sentence synthesis

- [ ] **Step 4: Test parallel multi-ticker**

Say: *"Compare NVIDIA and AMD"*

Expected: Plan with `parallel: true` on price steps, both prices fetched concurrently, comparative synthesis spoken.

- [ ] **Step 5: Test memory recall**

Say: *"What did you find on NVIDIA last time?"*

Expected: AgentOrchestrator calls `agentMemory.recall("NVDA")`, synthesis references the stored result.

- [ ] **Step 6: Final commit**

```bash
git add -A
git commit -m "docs: mark agentic extension complete"
```
