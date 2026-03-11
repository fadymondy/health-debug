import Foundation
import SwiftData

public enum CaffeineType: String, Codable, Sendable, CaseIterable {
    case redBull = "Red Bull"
    case coldBrew = "Cold Brew"
    case matcha = "Matcha"
    case greenTea = "Green Tea"
    case espresso = "Espresso"
    case blackCoffee = "Black Coffee"
    case other = "Other"

    public var isSugarBased: Bool {
        switch self {
        case .redBull: true
        default: false
        }
    }

    public var isClean: Bool {
        switch self {
        case .coldBrew, .matcha, .greenTea, .espresso, .blackCoffee: true
        default: false
        }
    }
}

@Model
public final class CaffeineLog: @unchecked Sendable {
    public var type: String // CaffeineType rawValue
    public var isSugarBased: Bool
    public var timestamp: Date

    public init(type: CaffeineType, timestamp: Date = .now) {
        self.type = type.rawValue
        self.isSugarBased = type.isSugarBased
        self.timestamp = timestamp
    }
}
