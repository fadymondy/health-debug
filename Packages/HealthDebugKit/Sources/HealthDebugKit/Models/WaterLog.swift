import Foundation
import SwiftData

@Model
public final class WaterLog: @unchecked Sendable {
    public var amount: Int // milliliters
    public var timestamp: Date
    public var source: String // "watch", "menubar", "ios"

    public init(amount: Int = 250, timestamp: Date = .now, source: String = "ios") {
        self.amount = amount
        self.timestamp = timestamp
        self.source = source
    }
}
