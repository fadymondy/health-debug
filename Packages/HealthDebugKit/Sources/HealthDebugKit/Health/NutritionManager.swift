import Foundation
import SwiftData

/// Manages safe-mode nutrition logging.
/// Boolean safe/unsafe — no calorie counting.
/// Uses FoodRegistry blacklist/whitelist for classification.
@MainActor
public final class NutritionManager: ObservableObject {

    public static let shared = NutritionManager()

    @Published public var todayMeals: [MealLog] = []
    @Published public var todayUnsafe: [MealLog] = []
    @Published public var todaySafeCount: Int = 0
    @Published public var todayUnsafeCount: Int = 0

    private init() {}

    // MARK: - Log Meal

    /// Log a meal from the whitelist (safe, no triggers).
    public func logSafeMeal(_ name: String, category: FoodCategory, context: ModelContext) {
        let meal = MealLog(name: name, category: category, isSafe: true, triggers: [])
        context.insert(meal)
        try? context.save()
        refresh(context: context)
    }

    /// Log a custom meal with auto-classification.
    public func logMeal(_ name: String, category: FoodCategory, notes: String = "", context: ModelContext) {
        let result = FoodRegistry.classify(name)
        let meal = MealLog(name: name, category: category, isSafe: result.isSafe, triggers: result.triggers, notes: notes)
        context.insert(meal)
        try? context.save()
        refresh(context: context)
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
