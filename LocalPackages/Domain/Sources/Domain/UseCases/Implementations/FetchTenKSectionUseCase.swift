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
