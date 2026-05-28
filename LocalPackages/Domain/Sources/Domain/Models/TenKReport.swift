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
