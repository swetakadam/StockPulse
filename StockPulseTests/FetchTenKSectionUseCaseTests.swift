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
