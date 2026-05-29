import Foundation
import Domain
import OSLog

// EDGAR public API — no API key required.
// SEC requires User-Agent header identifying the app + contact email.
public final class SECClient: Sendable {

    private let logger = Logger(subsystem: "com.sweta.stockpulse", category: "SEC.Client")
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchCIK(ticker: String) async throws -> String {
        print("[SEC] 🔍 fetchCIK: \(ticker)")
        logger.info("🔍 Fetching CIK for \(ticker)")
        let (data, _) = try await fetch(.companyTickers)
        // Response: {"0": {"cik_str": 320193, "ticker": "AAPL", "title": "Apple Inc."}, ...}
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: [String: Any]] else {
            print("[SEC] ❌ company_tickers.json malformed")
            throw SECError.parsingFailed("company_tickers.json malformed")
        }
        let upper = ticker.uppercased()
        for (_, entry) in json {
            if let t = entry["ticker"] as? String, t.uppercased() == upper,
               let cik = entry["cik_str"] as? Int {
                print("[SEC] ✅ CIK for \(ticker): \(cik)")
                logger.info("✅ CIK for \(ticker): \(cik)")
                return String(cik)
            }
        }
        print("[SEC] ❌ ticker not found: \(ticker)")
        throw SECError.tickerNotFound(ticker)
    }

    func fetchLatest10KAccession(cik: String) async throws -> SECFilingInfo {
        print("[SEC] 📄 fetchLatest10KAccession: CIK \(cik)")
        logger.info("📄 Fetching submissions for CIK \(cik)")
        let (data, _) = try await fetch(.submissions(cik: cik))

        // fiscalYearEnd lives at the TOP company level — NOT inside recent[].
        // The guard previously required it from recent[], which always fails.
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let filings = json["filings"] as? [String: Any],
              let recent = filings["recent"] as? [String: Any],
              let forms = recent["form"] as? [String],
              let accessions = recent["accessionNumber"] as? [String],
              let dates = recent["filingDate"] as? [String]
        else {
            print("[SEC] ❌ submissions JSON malformed for CIK \(cik)")
            throw SECError.parsingFailed("submissions JSON malformed for CIK \(cik)")
        }

        guard let idx = forms.firstIndex(of: "10-K") else {
            print("[SEC] ❌ no 10-K found for CIK \(cik)")
            throw SECError.noFilingsFound(cik)
        }

        let rawAccession     = accessions[idx]
        let accessionNoDashes = rawAccession.replacingOccurrences(of: "-", with: "")
        let dateStr          = dates[idx]

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let filedDate = formatter.date(from: dateStr) ?? Date()
        let year = Calendar.current.component(.year, from: filedDate)

        // recent["primaryDocument"] gives the main HTM filename directly — skip index fetch
        let docURL: URL
        if let primaryDocs = recent["primaryDocument"] as? [String],
           idx < primaryDocs.count,
           !primaryDocs[idx].isEmpty {
            let docName = primaryDocs[idx]
            docURL = URL(string: "https://www.sec.gov/Archives/edgar/data/\(cik)/\(accessionNoDashes)/\(docName)")!
            print("[SEC] ✅ primaryDocument: \(docName)")
            logger.info("✅ 10-K document: \(docName)")
        } else {
            print("[SEC] ⚠️ No primaryDocument — falling back to index fetch")
            let indexURL = URL(string: "https://www.sec.gov/Archives/edgar/data/\(cik)/\(accessionNoDashes)/\(rawAccession)-index.json")!
            docURL = try await fetchDocumentURL(indexURL: indexURL, cik: cik, accession: accessionNoDashes, rawAccession: rawAccession)
        }

        print("[SEC] 📎 \(rawAccession) FY\(year) → \(docURL)")
        return SECFilingInfo(
            accession: rawAccession,
            fiscalYear: year,
            filedDate: filedDate,
            documentURL: docURL
        )
    }

    func fetchRawDocument(url: URL) async throws -> String {
        print("[SEC] ⬇️ Downloading: \(url.lastPathComponent)")
        logger.info("⬇️ Downloading 10-K: \(url.lastPathComponent)")
        var request = URLRequest(url: url)
        request.setValue("StockPulse/1.0 sshinde5ster@gmail.com", forHTTPHeaderField: "User-Agent")
        request.setValue("text/html, */*", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 60
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            print("[SEC] ❌ HTTP \(status) for \(url.lastPathComponent)")
            logger.error("❌ Document fetch HTTP \(status): \(url)")
            throw SECError.documentFetchFailed(url)
        }
        let html = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) ?? ""
        print("[SEC] ✅ Downloaded \(data.count / 1024) KB — \(url.lastPathComponent)")
        logger.info("✅ Downloaded \(data.count / 1024) KB")
        return html
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
