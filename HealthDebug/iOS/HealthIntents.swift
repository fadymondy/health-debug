import AppIntents
import SwiftData
import HealthDebugKit

// MARK: - Log Water Intent

struct LogWaterIntent: AppIntent {
    static let title: LocalizedStringResource = "Log Water"
    static let description: IntentDescription = "Log water intake in Health Debug"

    @Parameter(title: "Amount (ml)", default: 250)
    var amount: Int

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = try ModelContainerFactory.create()
        let context = ModelContext(container)
        HydrationManager.shared.logWater(amount, source: "siri", context: context, profile: nil)
        return .result(dialog: "Logged \(amount)ml of water.")
    }

    static var parameterSummary: some ParameterSummary {
        Summary("Log \(\.$amount) ml of water")
    }
}

// MARK: - Log Meal Intent

struct LogMealIntent: AppIntent {
    static let title: LocalizedStringResource = "Log Meal"
    static let description: IntentDescription = "Log a meal in Health Debug"

    @Parameter(title: "Food Name")
    var foodName: String

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = try ModelContainerFactory.create()
        let context = ModelContext(container)
        let result = FoodRegistry.classify(foodName)
        NutritionManager.shared.logMeal(foodName, category: .protein, context: context)
        let safety = result.isSafe ? "safe" : "unsafe (\(result.triggers.map(\.rawValue).joined(separator: ", ")))"
        return .result(dialog: "Logged \(foodName) — \(safety).")
    }

    static var parameterSummary: some ParameterSummary {
        Summary("Log \(\.$foodName) as a meal")
    }
}

// MARK: - Log Caffeine Intent

struct LogCaffeineIntent: AppIntent {
    static let title: LocalizedStringResource = "Log Caffeine"
    static let description: IntentDescription = "Log caffeine intake in Health Debug"

    @Parameter(title: "Type", default: "Black Coffee")
    var type: String

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = try ModelContainerFactory.create()
        let context = ModelContext(container)
        let caffeineType = CaffeineType(rawValue: type) ?? .blackCoffee
        CaffeineManager.shared.logCaffeine(caffeineType, context: context)
        return .result(dialog: "Logged \(caffeineType.rawValue).")
    }

    static var parameterSummary: some ParameterSummary {
        Summary("Log \(\.$type) caffeine")
    }
}

// MARK: - Health Summary Intent

struct HealthSummaryIntent: AppIntent {
    static let title: LocalizedStringResource = "Health Summary"
    static let description: IntentDescription = "Get your 72-hour health summary"

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = try ModelContainerFactory.create()
        let context = ModelContext(container)
        let engine = AnalyticsEngine.shared
        let healthContext = engine.buildContext(context: context, profile: nil, sleepConfig: nil)

        let summary = """
        Water: \(healthContext.hydration.totalMl)ml / \(healthContext.hydration.goalMl)ml goal
        Meals: \(healthContext.nutrition.totalMeals) (\(healthContext.nutrition.unsafeMeals) unsafe)
        Caffeine: \(healthContext.caffeine.totalDrinks) drinks (\(healthContext.caffeine.sugarBased) sugar)
        Walks: \(healthContext.movement.completedWalks) / \(healthContext.movement.targetSessions)
        """
        return .result(dialog: "\(summary)")
    }
}

// MARK: - Shortcuts Provider

struct HealthDebugShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogWaterIntent(),
            phrases: [
                "Log water in \(.applicationName)",
                "Drink water \(.applicationName)"
            ],
            shortTitle: "Log Water",
            systemImageName: "drop.fill"
        )
        AppShortcut(
            intent: LogMealIntent(),
            phrases: [
                "Log meal in \(.applicationName)",
                "I ate something \(.applicationName)"
            ],
            shortTitle: "Log Meal",
            systemImageName: "fork.knife"
        )
        AppShortcut(
            intent: LogCaffeineIntent(),
            phrases: [
                "Log caffeine in \(.applicationName)",
                "I had coffee \(.applicationName)"
            ],
            shortTitle: "Log Caffeine",
            systemImageName: "cup.and.saucer.fill"
        )
        AppShortcut(
            intent: HealthSummaryIntent(),
            phrases: [
                "Health summary \(.applicationName)",
                "How's my health \(.applicationName)"
            ],
            shortTitle: "Health Summary",
            systemImageName: "heart.text.clipboard"
        )
    }
}
