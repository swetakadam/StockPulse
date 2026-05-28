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

        let accessionNoDashes = accessions[idx].replacingOccurrences(of: "-", with: "")
        let rawAccession = accessions[idx]
        let dateStr = dates[idx]
        let fyStr = fiscalYearEnds[idx]
        let year = Int(fyStr.prefix(4)) ?? 2024

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let filedDate = formatter.date(from: dateStr) ?? Date()

        let indexURL = URL(string: "https://www.sec.gov/Archives/edgar/data/\(cik)/\(accessionNoDashes)/\(rawAccession)-index.json")!
        let docURL = try await fetchDocumentURL(indexURL: indexURL, cik: cik, accession: accessionNoDashes, rawAccession: rawAccession)

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

    private func fetchDocumentURL(indexURL: URL, cik: String, accession: String, rawAccession: String) async throws -> URL {
        let (data, _) = try await fetch(.document(url: indexURL))
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let directory = json["directory"] as? [String: Any],
              let items = directory["item"] as? [[String: Any]]
        else {
            let docName = accession + ".htm"
            return URL(string: "https://www.sec.gov/Archives/edgar/data/\(cik)/\(accession)/\(docName)")!
        }

        let tenKDoc = items.first { item in
            guard let name = item["name"] as? String,
                  let type_ = item["type"] as? String else { return false }
            return type_ == "10-K" && (name.hasSuffix(".htm") || name.hasSuffix(".html"))
        }

        if let name = tenKDoc?["name"] as? String {
            return URL(string: "https://www.sec.gov/Archives/edgar/data/\(cik)/\(accession)/\(name)")!
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
