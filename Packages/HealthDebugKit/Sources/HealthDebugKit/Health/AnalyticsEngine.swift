import Foundation
import SwiftData

/// Aggregates 72-hour health data context for AI analysis and JSON export.
@MainActor
public final class AnalyticsEngine: ObservableObject {

    public static let shared = AnalyticsEngine()

    /// Hours of context to include in analysis.
    public static let contextWindowHours: Int = 72

    @Published public var lastAnalysis: String = ""
    @Published public var isAnalyzing: Bool = false

    private init() {}

    // MARK: - 72-Hour Health Context

    /// Builds a structured health summary from the last 72 hours of data.
    public func buildContext(context: ModelContext, profile: UserProfile?, sleepConfig: SleepConfig?) -> HealthContext {
        let calendar = Calendar.current
        let now = Date.now
        let windowStart = calendar.date(byAdding: .hour, value: -Self.contextWindowHours, to: now)!

        // Water logs
        let waterLogs = fetchRecent(WaterLog.self, after: windowStart, keyPath: \WaterLog.timestamp, context: context)
        let totalWater = waterLogs.reduce(0) { $0 + $1.amount }

        // Meal logs
        let mealLogs = fetchRecent(MealLog.self, after: windowStart, keyPath: \MealLog.timestamp, context: context)
        let unsafeMeals = mealLogs.filter { !$0.isSafe }

        // Caffeine logs
        let caffeineLogs = fetchRecent(CaffeineLog.self, after: windowStart, keyPath: \CaffeineLog.timestamp, context: context)
        let sugarCaffeine = caffeineLogs.filter(\.isSugarBased)

        // Stand sessions
        let standSessions = fetchRecent(StandSession.self, after: windowStart, keyPath: \StandSession.startTime, context: context)
        let completedStands = standSessions.filter(\.completed)

        return HealthContext(
            windowHours: Self.contextWindowHours,
            generatedAt: now,
            profile: profile.map { ProfileSummary(
                weightKg: $0.weightKg,
                heightCm: $0.heightCm,
                bmi: $0.bmi,
                metabolicAge: $0.metabolicAge,
                visceralFat: $0.visceralFat,
                bodyWaterPercent: $0.bodyWaterPercent,
                dailyWaterGoalMl: $0.dailyWaterGoalMl
            )},
            hydration: HydrationSummary(
                totalMl: totalWater,
                logCount: waterLogs.count,
                goalMl: profile?.dailyWaterGoalMl ?? 2500
            ),
            nutrition: NutritionSummary(
                totalMeals: mealLogs.count,
                safeMeals: mealLogs.count - unsafeMeals.count,
                unsafeMeals: unsafeMeals.count,
                triggersHit: Array(Set(unsafeMeals.flatMap(\.triggers)))
            ),
            caffeine: CaffeineSummary(
                totalDrinks: caffeineLogs.count,
                sugarBased: sugarCaffeine.count,
                cleanBased: caffeineLogs.count - sugarCaffeine.count
            ),
            movement: MovementSummary(
                standSessions: standSessions.count,
                completedWalks: completedStands.count,
                targetSessions: StandTimerManager.dailyTarget
            ),
            sleep: SleepSummary(
                targetHour: sleepConfig?.targetSleepHour ?? 23,
                targetMinute: sleepConfig?.targetSleepMinute ?? 0,
                shutdownWindowHours: sleepConfig?.shutdownWindowHours ?? 4
            )
        )
    }

    // MARK: - JSON Export

    /// Exports the health context as JSON data.
    public func exportJSON(context: ModelContext, profile: UserProfile?, sleepConfig: SleepConfig?) -> Data? {
        let healthContext = buildContext(context: context, profile: profile, sleepConfig: sleepConfig)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try? encoder.encode(healthContext)
    }

    // MARK: - AI Prompt

    /// Builds the prompt for AI analysis.
    public func buildPrompt(healthContext: HealthContext) -> String {
        let json = {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            encoder.dateEncodingStrategy = .iso8601
            return (try? encoder.encode(healthContext)).flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
        }()

        return """
        You are a health optimization AI for the "Health Debug" app. Analyze the following 72-hour health data and provide:

        1. **Overall Health Score** (0-100) with brief justification
        2. **Top 3 Wins** — things the user did well
        3. **Top 3 Concerns** — areas needing improvement
        4. **Actionable Recommendations** — specific, practical next steps
        5. **Trigger Analysis** — if any food triggers were hit, explain the health impact

        Be concise, direct, and actionable. Use the user's actual data. Focus on:
        - Hydration vs goal
        - Safe vs unsafe meal ratio
        - Sugar caffeine usage (Red Bull deprecation progress)
        - Stand/walk session completion
        - GERD shutdown compliance

        Health Data (last 72 hours):
        \(json)
        """
    }

    // MARK: - Private Helpers

    private func fetchRecent<T: PersistentModel>(_ type: T.Type, after date: Date, keyPath: KeyPath<T, Date>, context: ModelContext) -> [T] {
        let descriptor = FetchDescriptor<T>()
        let all = (try? context.fetch(descriptor)) ?? []
        return all.filter { $0[keyPath: keyPath] >= date }
    }
}

// MARK: - Data Structures

public struct HealthContext: Codable, Sendable {
    public var windowHours: Int
    public var generatedAt: Date
    public var profile: ProfileSummary?
    public var hydration: HydrationSummary
    public var nutrition: NutritionSummary
    public var caffeine: CaffeineSummary
    public var movement: MovementSummary
    public var sleep: SleepSummary
}

public struct ProfileSummary: Codable, Sendable {
    public var weightKg: Double
    public var heightCm: Double
    public var bmi: Double
    public var metabolicAge: Int
    public var visceralFat: Int
    public var bodyWaterPercent: Double
    public var dailyWaterGoalMl: Int
}

public struct HydrationSummary: Codable, Sendable {
    public var totalMl: Int
    public var logCount: Int
    public var goalMl: Int
}

public struct NutritionSummary: Codable, Sendable {
    public var totalMeals: Int
    public var safeMeals: Int
    public var unsafeMeals: Int
    public var triggersHit: [String]
}

public struct CaffeineSummary: Codable, Sendable {
    public var totalDrinks: Int
    public var sugarBased: Int
    public var cleanBased: Int
}

public struct MovementSummary: Codable, Sendable {
    public var standSessions: Int
    public var completedWalks: Int
    public var targetSessions: Int
}

public struct SleepSummary: Codable, Sendable {
    public var targetHour: Int
    public var targetMinute: Int
    public var shutdownWindowHours: Int
}
