import Foundation

// All values from xcconfig → Info.plist. Zero hardcoded secrets.
enum AzureChatConfig {
    static var endpoint: String {
        Bundle.main.infoDictionary?["AZURE_CHAT_ENDPOINT"] as? String ?? ""
    }
    static var apiKey: String {
        Bundle.main.infoDictionary?["AZURE_CHAT_API_KEY"] as? String ?? ""
    }
    static let apiVersion = "2024-08-01-preview"
}
