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
        case .tickerNotFound(let t):        return "CIK not found for ticker: \(t)"
        case .noFilingsFound(let cik):      return "No 10-K filings for CIK: \(cik)"
        case .documentFetchFailed(let url): return "Failed to fetch: \(url)"
        case .parsingFailed(let msg):       return "Parse error: \(msg)"
        }
    }
}
