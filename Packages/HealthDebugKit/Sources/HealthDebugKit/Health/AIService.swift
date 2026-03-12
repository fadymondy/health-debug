import Foundation
import Security
import FoundationModels

/// AI service with Apple Intelligence on-device as default, BYOK cloud providers as optional.
/// API keys stored securely in Keychain.
@MainActor
public final class AIService: ObservableObject {

    public static let shared = AIService()

    public enum Provider: String, CaseIterable, Codable, Sendable {
        case apple = "Apple Intelligence"
        case claude = "Claude"
        case openai = "GPT"
        case gemini = "Gemini"

        public var isOnDevice: Bool { self == .apple }

        public var modelName: String {
            switch self {
            case .apple: return "On-Device"
            case .claude: return "claude-sonnet-4-5-20250514"
            case .openai: return "gpt-4o"
            case .gemini: return "gemini-2.0-flash"
            }
        }

        public var baseURL: String {
            switch self {
            case .apple: return ""
            case .claude: return "https://api.anthropic.com/v1/messages"
            case .openai: return "https://api.openai.com/v1/chat/completions"
            case .gemini: return "https://generativelanguage.googleapis.com/v1beta/models"
            }
        }

        public var keychainKey: String {
            "io.threex1.HealthDebug.apiKey.\(rawValue)"
        }

        /// Cloud providers that require API keys.
        public static var cloudProviders: [Provider] {
            [.claude, .openai, .gemini]
        }
    }

    /// Apple Intelligence availability status.
    public enum AppleAIStatus: Equatable {
        case available
        case unavailable(String)
        case checking
    }

    @Published public var selectedProvider: Provider = .apple
    @Published public var isConfigured: Bool = true // Apple Intelligence works by default
    @Published public var isLoading: Bool = false
    @Published public var appleAIStatus: AppleAIStatus = .checking

    private init() {
        checkAppleIntelligence()
        checkConfiguration()
    }

    // MARK: - Apple Intelligence

    private func checkAppleIntelligence() {
        let model = SystemLanguageModel.default
        switch model.availability {
        case .available:
            appleAIStatus = .available
        case .unavailable:
            appleAIStatus = .unavailable("Apple Intelligence is not available on this device. Enable it in Settings or use a cloud provider.")
        @unknown default:
            appleAIStatus = .unavailable("Unknown availability status.")
        }
    }

    public var isAppleAIAvailable: Bool {
        appleAIStatus == .available
    }

    // MARK: - Keychain

    public func saveAPIKey(_ key: String, for provider: Provider) {
        guard !provider.isOnDevice else { return }
        let data = key.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: provider.keychainKey,
            kSecValueData as String: data,
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
        checkConfiguration()
    }

    public func getAPIKey(for provider: Provider) -> String? {
        guard !provider.isOnDevice else { return nil }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: provider.keychainKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    public func deleteAPIKey(for provider: Provider) {
        guard !provider.isOnDevice else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: provider.keychainKey,
        ]
        SecItemDelete(query as CFDictionary)
        checkConfiguration()
    }

    public func hasAPIKey(for provider: Provider) -> Bool {
        if provider.isOnDevice { return isAppleAIAvailable }
        return getAPIKey(for: provider) != nil
    }

    private func checkConfiguration() {
        if selectedProvider.isOnDevice {
            isConfigured = isAppleAIAvailable
        } else {
            isConfigured = hasAPIKey(for: selectedProvider)
        }
    }

    // MARK: - AI Chat

    /// Send a prompt to the selected AI provider and return the response.
    public func analyze(prompt: String) async throws -> String {
        isLoading = true
        defer { isLoading = false }

        switch selectedProvider {
        case .apple:
            return try await callAppleIntelligence(prompt: prompt)
        case .claude:
            guard let apiKey = getAPIKey(for: .claude) else { throw AIError.noAPIKey }
            return try await callClaude(prompt: prompt, apiKey: apiKey)
        case .openai:
            guard let apiKey = getAPIKey(for: .openai) else { throw AIError.noAPIKey }
            return try await callOpenAI(prompt: prompt, apiKey: apiKey)
        case .gemini:
            guard let apiKey = getAPIKey(for: .gemini) else { throw AIError.noAPIKey }
            return try await callGemini(prompt: prompt, apiKey: apiKey)
        }
    }

    // MARK: - Apple Intelligence (On-Device)

    private func callAppleIntelligence(prompt: String) async throws -> String {
        guard isAppleAIAvailable else {
            throw AIError.appleAIUnavailable
        }
        let session = LanguageModelSession(instructions: """
            You are a health optimization assistant for the "Health Debug" app. \
            Analyze health data and provide concise, actionable insights. \
            Focus on hydration, nutrition safety, caffeine habits, movement, and sleep.
            """)
        let response = try await session.respond(to: prompt)
        return response.content
    }

    // MARK: - Claude API

    private func callClaude(prompt: String, apiKey: String) async throws -> String {
        var request = URLRequest(url: URL(string: Provider.claude.baseURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let body: [String: Any] = [
            "model": Provider.claude.modelName,
            "max_tokens": 1024,
            "messages": [["role": "user", "content": prompt]]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AIError.apiError(String(data: data, encoding: .utf8) ?? "Unknown error")
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let content = (json?["content"] as? [[String: Any]])?.first?["text"] as? String
        return content ?? "No response"
    }

    // MARK: - OpenAI API

    private func callOpenAI(prompt: String, apiKey: String) async throws -> String {
        var request = URLRequest(url: URL(string: Provider.openai.baseURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "model": Provider.openai.modelName,
            "messages": [["role": "user", "content": prompt]],
            "max_tokens": 1024
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AIError.apiError(String(data: data, encoding: .utf8) ?? "Unknown error")
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let choices = json?["choices"] as? [[String: Any]]
        let message = choices?.first?["message"] as? [String: Any]
        return message?["content"] as? String ?? "No response"
    }

    // MARK: - Gemini API

    private func callGemini(prompt: String, apiKey: String) async throws -> String {
        let urlString = "\(Provider.gemini.baseURL)/\(Provider.gemini.modelName):generateContent?key=\(apiKey)"
        var request = URLRequest(url: URL(string: urlString)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "contents": [["parts": [["text": prompt]]]]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AIError.apiError(String(data: data, encoding: .utf8) ?? "Unknown error")
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let candidates = json?["candidates"] as? [[String: Any]]
        let content = candidates?.first?["content"] as? [String: Any]
        let parts = content?["parts"] as? [[String: Any]]
        return parts?.first?["text"] as? String ?? "No response"
    }

    // MARK: - Errors

    public enum AIError: LocalizedError {
        case noAPIKey
        case appleAIUnavailable
        case apiError(String)

        public var errorDescription: String? {
            switch self {
            case .noAPIKey: return "No API key configured. Go to Settings to add one."
            case .appleAIUnavailable: return "Apple Intelligence is not available. Enable it in Settings or switch to a cloud provider."
            case .apiError(let msg): return "API Error: \(msg)"
            }
        }
    }
}
