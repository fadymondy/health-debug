import Foundation

/// Shared data store for WidgetKit — written by the main app, read by widget extensions.
/// Uses App Group UserDefaults (group.io.3x1.HealthDebug) so the widget process can read
/// fresh metrics without HealthKit/SwiftData access.
public struct WidgetSnapshot: Codable, Sendable {
    // Steps
    public var steps: Double
    public var stepsGoal: Double

    // Energy
    public var activeEnergy: Double
    public var energyGoal: Double

    // Heart Rate
    public var heartRate: Double

    // Sleep
    public var sleepHours: Double
    public var sleepGoal: Double

    // Hydration
    public var hydrationMl: Int
    public var hydrationGoalMl: Int

    // Stand Timer
    public var pomodoroCompleted: Int
    public var pomodoroTarget: Int
    public var pomodoroPhase: String  // PomodoroPhase.rawValue

    // Nutrition
    public var nutritionSafetyScore: Int   // 0-100
    public var mealsLogged: Int

    // Caffeine
    public var caffeineIsClean: Bool
    public var caffeineDrinksToday: Int

    // Shutdown
    public var shutdownActive: Bool
    public var shutdownSecondsRemaining: TimeInterval

    // Weight
    public var weightKg: Double
    public var weightBodyFat: Double

    // Daily Flow
    public var dailyFlowScore: Int   // 0-6
    public var dailyFlowTotal: Int   // always 6

    // Metadata
    public var updatedAt: Date

    public init(
        steps: Double = 0, stepsGoal: Double = 10000,
        activeEnergy: Double = 0, energyGoal: Double = 500,
        heartRate: Double = 0,
        sleepHours: Double = 0, sleepGoal: Double = 8,
        hydrationMl: Int = 0, hydrationGoalMl: Int = 2500,
        pomodoroCompleted: Int = 0, pomodoroTarget: Int = 8, pomodoroPhase: String = "idle",
        nutritionSafetyScore: Int = 0, mealsLogged: Int = 0,
        caffeineIsClean: Bool = true, caffeineDrinksToday: Int = 0,
        shutdownActive: Bool = false, shutdownSecondsRemaining: TimeInterval = 0,
        weightKg: Double = 0, weightBodyFat: Double = 0,
        dailyFlowScore: Int = 0, dailyFlowTotal: Int = 6,
        updatedAt: Date = .now
    ) {
        self.steps = steps
        self.stepsGoal = stepsGoal
        self.activeEnergy = activeEnergy
        self.energyGoal = energyGoal
        self.heartRate = heartRate
        self.sleepHours = sleepHours
        self.sleepGoal = sleepGoal
        self.hydrationMl = hydrationMl
        self.hydrationGoalMl = hydrationGoalMl
        self.pomodoroCompleted = pomodoroCompleted
        self.pomodoroTarget = pomodoroTarget
        self.pomodoroPhase = pomodoroPhase
        self.nutritionSafetyScore = nutritionSafetyScore
        self.mealsLogged = mealsLogged
        self.caffeineIsClean = caffeineIsClean
        self.caffeineDrinksToday = caffeineDrinksToday
        self.shutdownActive = shutdownActive
        self.shutdownSecondsRemaining = shutdownSecondsRemaining
        self.weightKg = weightKg
        self.weightBodyFat = weightBodyFat
        self.dailyFlowScore = dailyFlowScore
        self.dailyFlowTotal = dailyFlowTotal
        self.updatedAt = updatedAt
    }
}

// MARK: - Widget Action Reader

/// Reads and clears pending actions queued by interactive widget buttons.
/// The widget extension writes these via `WidgetActionStore`; the main app flushes them here.
public final class WidgetActionReader: @unchecked Sendable {
    public static let shared = WidgetActionReader()

    private static let appGroupID = "group.io.3x1.HealthDebug"
    private let defaults: UserDefaults

    // Keys must match WidgetActions.swift in the widget extension
    private static let hydrationKey  = "widget_action_hydration_ml"
    private static let pomodoroKey   = "widget_action_pomodoro"
    private static let caffeineKey   = "widget_action_caffeine_clean"

    private init() {
        defaults = UserDefaults(suiteName: Self.appGroupID) ?? UserDefaults.standard
    }

    /// Returns pending hydration ml to log (0 if none), then clears the key.
    public func consumeHydration() -> Int {
        let ml = defaults.integer(forKey: Self.hydrationKey)
        if ml > 0 { defaults.removeObject(forKey: Self.hydrationKey) }
        return ml
    }

    /// Returns pending pomodoro action ("start" | "break") if any, then clears.
    public func consumePomodoro() -> String? {
        guard let action = defaults.string(forKey: Self.pomodoroKey), !action.isEmpty else { return nil }
        defaults.removeObject(forKey: Self.pomodoroKey)
        return action
    }

    /// Returns true if a clean caffeine drink should be logged, then clears.
    public func consumeCaffeineClean() -> Bool {
        let pending = defaults.bool(forKey: Self.caffeineKey)
        if pending { defaults.removeObject(forKey: Self.caffeineKey) }
        return pending
    }
}

// MARK: - Widget Data Store

/// Reads and writes `WidgetSnapshot` via shared App Group UserDefaults.
public final class WidgetDataStore: @unchecked Sendable {

    public static let shared = WidgetDataStore()

    private static let appGroupID = "group.io.3x1.HealthDebug"
    private static let snapshotKey = "widget_snapshot_v1"

    private let defaults: UserDefaults

    private init() {
        defaults = UserDefaults(suiteName: Self.appGroupID)
            ?? UserDefaults.standard
    }

    /// Write latest snapshot from the main app process.
    public func write(_ snapshot: WidgetSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: Self.snapshotKey)
    }

    /// Read the latest snapshot (from widget extension or app process).
    public func read() -> WidgetSnapshot {
        guard
            let data = defaults.data(forKey: Self.snapshotKey),
            let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
        else {
            return WidgetSnapshot()
        }
        return snapshot
    }
}
