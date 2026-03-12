import Foundation
import SwiftData

@Model
public final class StandSession {
    public var startTime: Date
    public var durationSeconds: Int // target: 180 (3 minutes)
    public var completed: Bool

    public init(startTime: Date = .now, durationSeconds: Int = 180, completed: Bool = false) {
        self.startTime = startTime
        self.durationSeconds = durationSeconds
        self.completed = completed
    }
}
