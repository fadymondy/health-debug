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

// MARK: - Queries

extension PomodoroSession {
    /// FetchDescriptor for today's sessions, newest first.
    public static func todayDescriptor() -> FetchDescriptor<PomodoroSession> {
        let start = Calendar.current.startOfDay(for: .now)
        let pred = #Predicate<PomodoroSession> { $0.startTime >= start }
        var d = FetchDescriptor<PomodoroSession>(predicate: pred,
                                                 sortBy: [SortDescriptor(\.startTime, order: .reverse)])
        d.fetchLimit = 50
        return d
    }

    /// Count of completed work sessions today.
    public static func todayCompletedCount(in context: ModelContext) -> Int {
        let start = Calendar.current.startOfDay(for: .now)
        let workPhase = "work"
        let pred = #Predicate<PomodoroSession> {
            $0.startTime >= start && $0.completed == true && $0.phase == workPhase
        }
        return (try? context.fetchCount(FetchDescriptor<PomodoroSession>(predicate: pred))) ?? 0
    }
}

// MARK: - Backward compat alias (existing StandSession references keep working)
public typealias StandSession = PomodoroSession
