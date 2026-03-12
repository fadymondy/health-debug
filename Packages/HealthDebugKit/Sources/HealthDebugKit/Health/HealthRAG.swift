import Foundation
import SwiftData

@MainActor
public final class HealthRAG: ObservableObject {
    public static let shared = HealthRAG()

    public struct Message: Identifiable, Equatable {
        public let id = UUID()
        public let role: Role
        public let content: String
        public let timestamp: Date

        public enum Role: String {
            case user
            case assistant
            case system
        }

        public init(role: Role, content: String, timestamp: Date = .now) {
            self.role = role
            self.content = content
            self.timestamp = timestamp
        }
    }

    // Smart action types the AI can suggest
    public enum SmartAction: Equatable {
        case logWater(Int)           // amount in ml
        case logMeal(String, String) // name, category
        case logCaffeine(String)     // type name
        case startStandTimer
        case none
    }

    @Published public var messages: [Message] = []
    @Published public var isProcessing: Bool = false
    @Published public var pendingAction: SmartAction = .none

    private init() {}

    /// Send a message and get AI response with health context
    public func send(_ text: String, context: ModelContext, profile: UserProfile?, sleepConfig: SleepConfig?) async {
        // Add user message
        let userMessage = Message(role: .user, content: text)
        messages.append(userMessage)

        isProcessing = true
        defer { isProcessing = false }

        // Build health context
        let engine = AnalyticsEngine.shared
        let healthContext = engine.buildContext(context: context, profile: profile, sleepConfig: sleepConfig)

        // Build conversation prompt with RAG context
        let prompt = buildRAGPrompt(userMessage: text, healthContext: healthContext)

        do {
            let ai = AIService.shared
            let response = try await ai.analyze(prompt: prompt)
            let assistantMessage = Message(role: .assistant, content: response)
            messages.append(assistantMessage)

            // Parse for smart actions
            pendingAction = parseSmartAction(from: response)
        } catch {
            let errorMessage = Message(role: .assistant, content: "Sorry, I couldn't process that: \(error.localizedDescription)")
            messages.append(errorMessage)
        }
    }

    /// Execute a pending smart action
    public func executeAction(_ action: SmartAction, context: ModelContext, profile: UserProfile?) {
        switch action {
        case .logWater(let amount):
            HydrationManager.shared.logWater(amount, source: "ai", context: context, profile: profile)
        case .logMeal(let name, let category):
            let cat = FoodCategory(rawValue: category) ?? .protein
            NutritionManager.shared.logMeal(name, category: cat, context: context)
        case .logCaffeine(let type):
            if let caffeineType = CaffeineType(rawValue: type) {
                CaffeineManager.shared.logCaffeine(caffeineType, context: context, profile: profile)
            }
        case .startStandTimer:
            StandTimerManager.shared.startCycle()
        case .none:
            break
        }
        pendingAction = .none
    }

    public func clearHistory() {
        messages.removeAll()
        pendingAction = .none
    }

    // MARK: - Private

    private func buildRAGPrompt(userMessage: String, healthContext: HealthContext) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        let contextJSON = (try? encoder.encode(healthContext)).flatMap { String(data: $0, encoding: .utf8) } ?? "{}"

        // Build conversation history (last 10 messages)
        let recentHistory = messages.suffix(10).map { msg in
            "\(msg.role.rawValue): \(msg.content)"
        }.joined(separator: "\n\n")

        return """
        You are the Health Debug AI assistant. You help users optimize their health based on real data.

        CURRENT HEALTH DATA (last 72 hours):
        \(contextJSON)

        CONVERSATION HISTORY:
        \(recentHistory)

        SMART ACTIONS:
        When the user wants to log something, include one of these tags at the END of your response:
        [ACTION:LOG_WATER:amount_ml] — e.g. [ACTION:LOG_WATER:250]
        [ACTION:LOG_MEAL:name:category] — e.g. [ACTION:LOG_MEAL:Grilled Chicken:protein]
        [ACTION:LOG_CAFFEINE:type] — e.g. [ACTION:LOG_CAFFEINE:Green Tea]
        [ACTION:START_TIMER] — start stand timer

        Categories for meals: protein, carb, fat, drink
        Caffeine types: Red Bull, Cold Brew, Matcha, Green Tea, Espresso, Black Coffee

        USER MESSAGE:
        \(userMessage)

        Respond concisely. Use markdown formatting. Be specific with health advice based on the actual data.
        """
    }

    private func parseSmartAction(from response: String) -> SmartAction {
        if let range = response.range(of: #"\[ACTION:LOG_WATER:(\d+)\]"#, options: .regularExpression) {
            let match = String(response[range])
            if let amount = Int(match.replacingOccurrences(of: "[ACTION:LOG_WATER:", with: "").replacingOccurrences(of: "]", with: "")) {
                return .logWater(amount)
            }
        }
        if let range = response.range(of: #"\[ACTION:LOG_MEAL:([^:]+):([^\]]+)\]"#, options: .regularExpression) {
            let match = String(response[range])
                .replacingOccurrences(of: "[ACTION:LOG_MEAL:", with: "")
                .replacingOccurrences(of: "]", with: "")
            let parts = match.split(separator: ":", maxSplits: 1).map(String.init)
            if parts.count == 2 {
                return .logMeal(parts[0], parts[1])
            }
        }
        if let range = response.range(of: #"\[ACTION:LOG_CAFFEINE:([^\]]+)\]"#, options: .regularExpression) {
            let match = String(response[range])
                .replacingOccurrences(of: "[ACTION:LOG_CAFFEINE:", with: "")
                .replacingOccurrences(of: "]", with: "")
            return .logCaffeine(match)
        }
        if response.contains("[ACTION:START_TIMER]") {
            return .startStandTimer
        }
        return .none
    }
}
