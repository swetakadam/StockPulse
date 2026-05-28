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
