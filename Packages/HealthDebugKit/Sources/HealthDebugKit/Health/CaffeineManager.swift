import Foundation
import SwiftData
import UserNotifications

/// Manages caffeine tracking with Red Bull deprecation protocol.
/// - 90-120 min post-wake caffeine block (cortisol window)
/// - Tracks Red Bull → clean caffeine transition
/// - Fatty liver alerts on sugar-based caffeine
@MainActor
public final class CaffeineManager: ObservableObject {

    public static let shared = CaffeineManager()

    /// Minutes after waking before caffeine is optimal (cortisol window).
    public static let caffeineBlockMinutes: Int = 90
    /// Minimum seconds between caffeine logs.
    public static let logCooldownSeconds: TimeInterval = 60
    /// Maximum caffeine logs per day (safety cap).
    public static let maxDailyLogs: Int = 8

    // MARK: - State

    @Published public var todayLogs: [CaffeineLog] = []
    @Published public var todaySugarCount: Int = 0
    @Published public var todayCleanCount: Int = 0
    @Published public var todayTotal: Int = 0
    @Published public var lastLogTime: Date?

    private init() {}

    // MARK: - Validation

    public var canLog: Bool {
        if todayTotal >= Self.maxDailyLogs { return false }
        if let last = lastLogTime, Date.now.timeIntervalSince(last) < Self.logCooldownSeconds { return false }
        return true
    }

    // MARK: - Log Caffeine

    @discardableResult
    public func logCaffeine(_ type: CaffeineType, context: ModelContext, profile: UserProfile? = nil) -> Bool {
        guard canLog else { return false }
        let log = CaffeineLog(type: type)
        context.insert(log)
        try? context.save()
        lastLogTime = .now
        refresh(context: context)
        // Schedule caffeine block end notification if in block
        if let profile, isInCaffeineBlock(profile: profile) {
            let remaining = caffeineBlockMinutesRemaining(profile: profile)
            if remaining > 0 {
                scheduleCaffeineBlockEndNotification(inMinutes: remaining)
            }
        }
        return true
    }

    // MARK: - Refresh

    public func refresh(context: ModelContext) {
        todayLogs = (try? context.fetch(CaffeineLog.todayDescriptor())) ?? []
        todayTotal = todayLogs.count
        todaySugarCount = todayLogs.filter(\.isSugarBased).count
        todayCleanCount = todayLogs.filter { !$0.isSugarBased }.count
    }

    // MARK: - Caffeine Block (Post-Wake Window)

    /// Whether caffeine is currently in the block window (first 90 min after wake).
    /// Uses work start hour as proxy for wake time.
    public func isInCaffeineBlock(profile: UserProfile?) -> Bool {
        guard let profile else { return false }
        let calendar = Calendar.current
        let now = Date.now
        let today = calendar.startOfDay(for: now)

        // Assume wake time = 1 hour before work start
        let wakeHour = max(0, profile.workStartHour - 1)
        let wakeTime = calendar.date(bySettingHour: wakeHour,
                                      minute: profile.workStartMinute,
                                      second: 0, of: today)!
        let blockEnd = calendar.date(byAdding: .minute,
                                      value: Self.caffeineBlockMinutes,
                                      to: wakeTime)!

        return now >= wakeTime && now < blockEnd
    }

    /// Minutes remaining in the caffeine block window.
    public func caffeineBlockMinutesRemaining(profile: UserProfile?) -> Int {
        guard let profile else { return 0 }
        let calendar = Calendar.current
        let now = Date.now
        let today = calendar.startOfDay(for: now)

        let wakeHour = max(0, profile.workStartHour - 1)
        let wakeTime = calendar.date(bySettingHour: wakeHour,
                                      minute: profile.workStartMinute,
                                      second: 0, of: today)!
        let blockEnd = calendar.date(byAdding: .minute,
                                      value: Self.caffeineBlockMinutes,
                                      to: wakeTime)!

        guard now < blockEnd else { return 0 }
        return max(0, Int(blockEnd.timeIntervalSince(now) / 60))
    }

    // MARK: - Red Bull Deprecation

    /// Transition score: 0% (all Red Bull) to 100% (all clean).
    public var cleanTransitionPercent: Double {
        guard todayTotal > 0 else { return 100 }
        return Double(todayCleanCount) / Double(todayTotal) * 100
    }

    public enum TransitionStatus: String {
        case clean = "Clean"
        case transitioning = "Transitioning"
        case redBullDependent = "Red Bull Dependent"
        case noIntake = "No Caffeine"
    }

    public var transitionStatus: TransitionStatus {
        if todayTotal == 0 { return .noIntake }
        if todaySugarCount == 0 { return .clean }
        if todayCleanCount > todaySugarCount { return .transitioning }
        return .redBullDependent
    }

    // MARK: - Fatty Liver Alert

    /// Fatty liver risk flag: sugar-based caffeine contributes to liver fat.
    public var fattyLiverAlert: Bool {
        todaySugarCount > 0
    }

    public var fattyLiverMessage: String {
        if todaySugarCount == 0 {
            return "No sugar-based caffeine today. Liver is happy."
        }
        return "\(todaySugarCount) sugar-based drink\(todaySugarCount == 1 ? "" : "s") today. Switch to clean caffeine to protect your liver."
    }

    // MARK: - Notifications

    /// Notify when caffeine block window ends.
    public func scheduleCaffeineBlockEndNotification(inMinutes: Int) {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = "Caffeine Window Open"
        content.body = "Cortisol has dropped. You can have caffeine now — prefer clean sources over Red Bull."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(inMinutes * 60),
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: "io.threex1.HealthDebug.caffeineBlockEnd",
            content: content,
            trigger: trigger
        )
        center.add(request)
    }
}
