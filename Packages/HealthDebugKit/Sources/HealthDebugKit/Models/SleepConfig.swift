import Foundation
import SwiftData

@Model
public final class SleepConfig {
    public var targetSleepHour: Int // 0-23
    public var targetSleepMinute: Int // 0-59
    public var shutdownWindowHours: Int // default: 4
    public var lastUpdated: Date

    public init(
        targetSleepHour: Int = 23,
        targetSleepMinute: Int = 0,
        shutdownWindowHours: Int = 4,
        lastUpdated: Date = .now
    ) {
        self.targetSleepHour = targetSleepHour
        self.targetSleepMinute = targetSleepMinute
        self.shutdownWindowHours = shutdownWindowHours
        self.lastUpdated = lastUpdated
    }

    public var shutdownStartTime: DateComponents {
        var components = DateComponents()
        var hour = targetSleepHour - shutdownWindowHours
        if hour < 0 { hour += 24 }
        components.hour = hour
        components.minute = targetSleepMinute
        return components
    }
}
