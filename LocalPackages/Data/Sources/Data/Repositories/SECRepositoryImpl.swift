import Foundation
import Domain

public final class SECRepositoryImpl: SECRepositoryProtocol {
    private let client: SECClient
    private let parser: TenKParser
    private let htmlCache = NSCache<NSURL, NSString>()

    public init(client: SECClient, parser: TenKParser) {
        self.client = client
        self.parser = parser
        htmlCache.countLimit = 5
    }

    public func fetchCIK(ticker: String) async throws -> String {
        try await client.fetchCIK(ticker: ticker)
    }

    public func fetchLatest10KAccession(cik: String) async throws -> SECFilingInfo {
        try await client.fetchLatest10KAccession(cik: cik)
    }

    public func fetchSectionText(documentURL: URL, section: TenKSection) async throws -> String {
        let rawHTML: String
        if let cached = htmlCache.object(forKey: documentURL as NSURL) as String? {
            print("[SEC] 💾 Cache hit for \(documentURL.lastPathComponent)")
            rawHTML = cached
        } else {
            rawHTML = try await client.fetchRawDocument(url: documentURL)
            htmlCache.setObject(rawHTML as NSString, forKey: documentURL as NSURL)
        }
        return try await parser.extract(section: section, from: rawHTML)
    }
}
