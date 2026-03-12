import Foundation
import SwiftData

/// Represents one completed Pomodoro phase (work or break).
@Model
public final class PomodoroSession {
    public var startTime: Date
    public var durationSeconds: Int
    public var completed: Bool
    /// Which phase this session records.
    public var phase: String   // "work" | "shortBreak" | "longBreak"
    /// Cycle index within the current day (0-based).
    public var cycleIndex: Int

    public init(
        startTime: Date = .now,
        durationSeconds: Int,
        completed: Bool = false,
        phase: String = "work",
        cycleIndex: Int = 0
    ) {
        self.startTime = startTime
        self.durationSeconds = durationSeconds
        self.completed = completed
        self.phase = phase
        self.cycleIndex = cycleIndex
    }
}

// MARK: - Backward compat alias (existing StandSession references keep working)
public typealias StandSession = PomodoroSession
