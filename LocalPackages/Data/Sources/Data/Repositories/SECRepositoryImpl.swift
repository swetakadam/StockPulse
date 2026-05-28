import Foundation
import Domain

public final class SECRepositoryImpl: SECRepositoryProtocol {
    private let client: SECClient
    private let parser: TenKParser

    public init(client: SECClient, parser: TenKParser) {
        self.client = client
        self.parser = parser
    }

    public func fetchCIK(ticker: String) async throws -> String {
        try await client.fetchCIK(ticker: ticker)
    }

    public func fetchLatest10KAccession(cik: String) async throws -> SECFilingInfo {
        try await client.fetchLatest10KAccession(cik: cik)
    }

    public func fetchSectionText(documentURL: URL, section: TenKSection) async throws -> String {
        let rawHTML = try await client.fetchRawDocument(url: documentURL)
        return try await parser.extract(section: section, from: rawHTML)
    }
}
