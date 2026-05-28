public protocol FetchTenKSectionUseCaseProtocol: Sendable {
    func execute(ticker: String, section: TenKSection) async throws -> TenKReport
}
