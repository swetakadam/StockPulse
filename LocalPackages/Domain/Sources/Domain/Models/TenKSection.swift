// Pure Swift — zero framework imports
public enum TenKSection: String, Codable, CaseIterable, Sendable {
    case business            = "Item 1"
    case riskFactors         = "Item 1A"
    case mdAndA              = "Item 7"
    case financialStatements = "Item 8"

    public var displayName: String {
        switch self {
        case .business:            return "Business"
        case .riskFactors:         return "Risk Factors"
        case .mdAndA:              return "MD&A"
        case .financialStatements: return "Financial Statements"
        }
    }

    // SEC 10-K section headers use "ITEM N." — search case-insensitively
    public var searchPattern: String {
        switch self {
        case .business:            return "ITEM 1."
        case .riskFactors:         return "ITEM 1A."
        case .mdAndA:              return "ITEM 7."
        case .financialStatements: return "ITEM 8."
        }
    }
}
