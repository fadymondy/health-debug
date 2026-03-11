import Foundation
import SwiftData

public enum FoodCategory: String, Codable, Sendable, CaseIterable {
    case protein
    case carb
    case fat
    case drink
    case snack
}

public enum TriggerType: String, Codable, Sendable, CaseIterable {
    case ibsGerd = "IBS/GERD"
    case gout = "Gout"
    case fattyLiver = "Fatty Liver"
}

@Model
public final class MealLog: @unchecked Sendable {
    public var name: String
    public var category: String // FoodCategory rawValue
    public var isSafe: Bool
    public var triggers: [String] // TriggerType rawValues
    public var timestamp: Date
    public var notes: String

    public init(
        name: String,
        category: FoodCategory = .protein,
        isSafe: Bool = true,
        triggers: [TriggerType] = [],
        timestamp: Date = .now,
        notes: String = ""
    ) {
        self.name = name
        self.category = category.rawValue
        self.isSafe = isSafe
        self.triggers = triggers.map(\.rawValue)
        self.timestamp = timestamp
        self.notes = notes
    }
}
