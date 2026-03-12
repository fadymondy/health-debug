import Foundation
import SwiftData
import UserNotifications

/// Manages hydration tracking, smart distribution across work window,
/// dehydration warnings, and uric acid flush protocol for gout prevention.
@MainActor
public final class HydrationManager: ObservableObject {

    public static let shared = HydrationManager()

    // MARK: - Published State

    @Published public var todayTotal: Int = 0
    @Published public var dailyGoal: Int = 2500
    @Published public var logs: [WaterLog] = []
    @Published public var lastLogTime: Date?

    /// Minimum seconds between water logs to prevent accidental double-taps.
    public static let logCooldownSeconds: TimeInterval = 30
    /// Maximum daily intake in ml (safety cap: 5 liters).
    public static let maxDailyMl: Int = 5000

    private init() {}

    // MARK: - Validation

    /// Whether a new log is allowed (cooldown + daily cap).
    public var canLog: Bool {
        if todayTotal >= Self.maxDailyMl { return false }
        if let last = lastLogTime, Date.now.timeIntervalSince(last) < Self.logCooldownSeconds { return false }
        return true
    }

    // MARK: - Quick Log

    /// Log a water intake (default 250ml). Returns false if validation fails.
    @discardableResult
    public func logWater(_ amount: Int = 250, source: String = "ios", context: ModelContext, profile: UserProfile? = nil) -> Bool {
        guard canLog else { return false }
        let log = WaterLog(amount: amount, timestamp: .now, source: source)
        context.insert(log)
        try? context.save()
        lastLogTime = .now
        refresh(context: context)
        // Auto-schedule next hydration reminder
        if let profile, let nextMin = minutesUntilNextDrink(profile: profile) {
            scheduleReminder(inMinutes: nextMin)
        }
        return true
    }

    // MARK: - Refresh

    public func refresh(context: ModelContext) {
        todayTotal = WaterLog.todayTotal(in: context)
        logs = (try? context.fetch(WaterLog.todayDescriptor())) ?? []
    }

    // MARK: - Hydration Schedule

    /// How much water should have been consumed by now, based on linear distribution
    /// across the work window.
    public func expectedIntakeByNow(profile: UserProfile) -> Int {
        let calendar = Calendar.current
        let now = Date.now
        let today = calendar.startOfDay(for: now)

        let workStart = calendar.date(bySettingHour: profile.workStartHour,
                                       minute: profile.workStartMinute,
                                       second: 0, of: today)!
        let workEnd = calendar.date(bySettingHour: profile.workEndHour,
                                     minute: profile.workEndMinute,
                                     second: 0, of: today)!

        guard now >= workStart else { return 0 }
        guard now <= workEnd else { return profile.dailyWaterGoalMl }

        let totalWindow = workEnd.timeIntervalSince(workStart)
        let elapsed = now.timeIntervalSince(workStart)
        let fraction = elapsed / totalWindow

        return Int(Double(profile.dailyWaterGoalMl) * fraction)
    }

    /// How many ml behind schedule the user is.
    public func deficit(profile: UserProfile) -> Int {
        max(0, expectedIntakeByNow(profile: profile) - todayTotal)
    }

    /// Hydration status for display.
    public enum HydrationStatus: String {
        case onTrack = "On Track"
        case slightlyBehind = "Slightly Behind"
        case dehydrated = "Dehydrated"
        case goalReached = "Goal Reached"
    }

    public func status(profile: UserProfile) -> HydrationStatus {
        if todayTotal >= profile.dailyWaterGoalMl {
            return .goalReached
        }
        let gap = deficit(profile: profile)
        if gap <= 250 {
            return .onTrack
        } else if gap <= 500 {
            return .slightlyBehind
        } else {
            return .dehydrated
        }
    }

    /// Color-coded status for UI.
    public func statusColor(profile: UserProfile) -> String {
        switch status(profile: profile) {
        case .onTrack, .goalReached: return "primary"
        case .slightlyBehind: return "orange"
        case .dehydrated: return "red"
        }
    }

    // MARK: - Gout Protocol

    /// For gout prevention: water helps flush uric acid.
    /// Returns a recommendation based on current intake.
    public func goutFlushRecommendation(profile: UserProfile) -> String {
        let remaining = max(0, profile.dailyWaterGoalMl - todayTotal)
        if remaining == 0 {
            return "Daily goal reached. Uric acid flush on track."
        }
        let glasses = (remaining + 249) / 250 // round up
        return "\(glasses) more glass\(glasses == 1 ? "" : "es") to hit your flush target."
    }

    // MARK: - Next Drink Reminder

    /// Minutes until the user should drink next to stay on schedule.
    /// Returns nil if the work window is over or goal is met.
    public func minutesUntilNextDrink(profile: UserProfile) -> Int? {
        guard todayTotal < profile.dailyWaterGoalMl else { return nil }

        let calendar = Calendar.current
        let now = Date.now
        let today = calendar.startOfDay(for: now)

        let workEnd = calendar.date(bySettingHour: profile.workEndHour,
                                     minute: profile.workEndMinute,
                                     second: 0, of: today)!
        guard now < workEnd else { return nil }

        let remaining = profile.dailyWaterGoalMl - todayTotal
        let glasses = (remaining + 249) / 250
        guard glasses > 0 else { return nil }

        let timeLeft = workEnd.timeIntervalSince(now)
        let intervalMinutes = Int(timeLeft / 60.0) / glasses
        return max(1, intervalMinutes)
    }

    // MARK: - Notifications

    public func scheduleReminder(inMinutes: Int) {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = "Hydration Reminder"
        content.body = "Time for a glass of water. Stay hydrated to flush uric acid."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(inMinutes * 60),
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: "io.threex1.HealthDebug.hydrationReminder",
            content: content,
            trigger: trigger
        )
        center.add(request)
    }
}
