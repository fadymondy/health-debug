import Foundation
import SwiftData

/// Manages safe-mode nutrition logging.
/// Boolean safe/unsafe — no calorie counting.
/// Uses FoodRegistry blacklist/whitelist for classification.
@MainActor
public final class NutritionManager: ObservableObject {

    public static let shared = NutritionManager()

    /// Minimum seconds between meal logs.
    public static let logCooldownSeconds: TimeInterval = 30
    /// Maximum meals per day (safety cap).
    public static let maxDailyMeals: Int = 12
    /// Maximum food name length.
    public static let maxFoodNameLength: Int = 60

    @Published public var todayMeals: [MealLog] = []
    @Published public var todayUnsafe: [MealLog] = []
    @Published public var todaySafeCount: Int = 0
    @Published public var todayUnsafeCount: Int = 0
    @Published public var lastLogTime: Date?

    private init() {}

    // MARK: - Validation

    public var canLog: Bool {
        if todayMeals.count >= Self.maxDailyMeals { return false }
        if let last = lastLogTime, Date.now.timeIntervalSince(last) < Self.logCooldownSeconds { return false }
        return true
    }

    /// Validates and sanitizes a food name.
    public static func validateFoodName(_ name: String) -> String? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard trimmed.count <= maxFoodNameLength else {
            return String(trimmed.prefix(maxFoodNameLength))
        }
        return trimmed
    }

    // MARK: - Log Meal

    /// Log a meal from the whitelist (safe, no triggers).
    @discardableResult
    public func logSafeMeal(_ name: String, category: FoodCategory, context: ModelContext) -> Bool {
        guard canLog else { return false }
        let meal = MealLog(name: name, category: category, isSafe: true, triggers: [])
        context.insert(meal)
        try? context.save()
        lastLogTime = .now
        refresh(context: context)
        return true
    }

    /// Log a custom meal with auto-classification.
    @discardableResult
    public func logMeal(_ name: String, category: FoodCategory, notes: String = "", context: ModelContext) -> Bool {
        guard canLog else { return false }
        guard let validName = Self.validateFoodName(name) else { return false }
        let result = FoodRegistry.classify(validName)
        let meal = MealLog(name: validName, category: category, isSafe: result.isSafe, triggers: result.triggers, notes: notes)
        context.insert(meal)
        try? context.save()
        lastLogTime = .now
        refresh(context: context)
        return true
    }

    // MARK: - Refresh

    public func refresh(context: ModelContext) {
        todayMeals = (try? context.fetch(MealLog.todayDescriptor())) ?? []
        todayUnsafe = (try? context.fetch(MealLog.todayUnsafeDescriptor())) ?? []
        todaySafeCount = todayMeals.filter(\.isSafe).count
        todayUnsafeCount = todayUnsafe.count
    }

    // MARK: - Safety Score

    /// Percentage of safe meals today.
    public var safetyScore: Double {
        guard !todayMeals.isEmpty else { return 100 }
        return Double(todaySafeCount) / Double(todayMeals.count) * 100
    }

    public enum SafetyStatus: String {
        case allSafe = "All Safe"
        case warning = "Warning"
        case critical = "Critical"
        case noMeals = "No Meals"
    }

    public var safetyStatus: SafetyStatus {
        if todayMeals.isEmpty { return .noMeals }
        if todayUnsafeCount == 0 { return .allSafe }
        if todayUnsafeCount <= 1 { return .warning }
        return .critical
    }

    // MARK: - Trigger Summary

    /// Unique triggers hit today.
    public var todayTriggers: Set<String> {
        var triggers: Set<String> = []
        for meal in todayUnsafe {
            for trigger in meal.triggers {
                triggers.insert(trigger)
            }
        }
        return triggers
    }
}
