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
