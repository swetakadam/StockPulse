import Foundation

enum SECEndpoint {
    case companyTickers
    case submissions(cik: String)
    case document(url: URL)

    var url: URL {
        switch self {
        case .companyTickers:
            return URL(string: "https://www.sec.gov/files/company_tickers.json")!
        case .submissions(let cik):
            let paddedCIK = cik.padLeft(toLength: 10, with: "0")
            return URL(string: "https://data.sec.gov/submissions/CIK\(paddedCIK).json")!
        case .document(let url):
            return url
        }
    }
}

private extension String {
    func padLeft(toLength length: Int, with character: Character) -> String {
        let padCount = length - self.count
        guard padCount > 0 else { return self }
        return String(repeating: character, count: padCount) + self
    }
}
