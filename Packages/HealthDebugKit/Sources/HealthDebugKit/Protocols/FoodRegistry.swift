import Foundation

/// Defines the safe/unsafe food classification system per the PRD.
/// No calorie counting — strictly Boolean safe/unsafe with trigger warnings.
public enum FoodRegistry {

    // MARK: - Blacklist (Triggers Critical System Warnings)

    /// IBS/GERD triggers
    public static let ibsGerdTriggers: Set<String> = [
        "Whole Eggs", "Falafel", "Deep Fried Foods",
        "Raw Onion", "Raw Garlic", "Cheddar Cheese", "Yellow Cheese",
    ]

    /// Gout triggers (high purine)
    public static let goutTriggers: Set<String> = [
        "Red Meat", "Liver", "Duck",
        "Beans", "Lentils", "Legumes",
    ]

    /// Fatty liver triggers
    public static let fattyLiverTriggers: Set<String> = [
        "Refined Sugar", "Honey", "Nutella", "Jam",
        "White Flour", "Mixed Carbs",
    ]

    /// Complete blacklist
    public static let allBlacklist: Set<String> = {
        ibsGerdTriggers.union(goutTriggers).union(fattyLiverTriggers)
    }()

    // MARK: - Whitelist (Safe Foods - Fast Logging)

    public static let safeProteins: [String] = [
        "Grilled Chicken Breast", "White Fish", "Cottage Cheese", "Greek Yogurt",
    ]

    public static let safeCarbs: [String] = [
        "Oats", "Whole Wheat Toast", "White Rice", "Brown Rice",
    ]

    public static let safeFats: [String] = [
        "Olive Oil", "Avocado",
    ]

    public static let allWhitelist: [String] = {
        safeProteins + safeCarbs + safeFats
    }()

    // MARK: - Classification

    /// Returns the triggers for a given food item, or empty if safe.
    public static func classify(_ foodName: String) -> (isSafe: Bool, triggers: [TriggerType]) {
        let normalized = foodName.lowercased()
        var triggers: [TriggerType] = []

        for item in ibsGerdTriggers where normalized.contains(item.lowercased()) {
            triggers.append(.ibsGerd)
            break
        }
        for item in goutTriggers where normalized.contains(item.lowercased()) {
            triggers.append(.gout)
            break
        }
        for item in fattyLiverTriggers where normalized.contains(item.lowercased()) {
            triggers.append(.fattyLiver)
            break
        }

        return (triggers.isEmpty, triggers)
    }

    /// Max rice spoons per meal (PRD rule).
    public static let maxRiceSpoonsPerMeal = 5
}
