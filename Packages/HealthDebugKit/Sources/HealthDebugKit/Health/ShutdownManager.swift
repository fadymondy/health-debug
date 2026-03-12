import Foundation
import SwiftData
import UserNotifications

/// Manages the GERD & Sinus "System Shutdown" timer.
/// 4-hour pre-sleep fasting window. During shutdown: no food, only water/chamomile/anise tea.
@MainActor
public final class ShutdownManager: ObservableObject {

    public static let shared = ShutdownManager()

    // MARK: - Allowed Items During Shutdown

    public static let allowedDrinks: [String] = [
        "Water",
        "Chamomile Tea",
        "Anise Tea",
    ]

    // MARK: - State

    public enum ShutdownState: Equatable {
        case inactive          // outside shutdown window
        case active            // within shutdown window — fasting
        case violated          // user ate during shutdown
    }

    @Published public var state: ShutdownState = .inactive
    @Published public var secondsUntilSleep: TimeInterval = 0
    @Published public var secondsUntilShutdown: TimeInterval = 0
    @Published public var shutdownStartTime: Date?
    @Published public var sleepTime: Date?

    private var timer: Timer?

    private init() {}

    // MARK: - Compute Shutdown Window

    /// Call on appear and periodically. Calculates shutdown start/end from SleepConfig.
    public func refresh(config: SleepConfig?) {
        guard let config else {
            state = .inactive
            return
        }

        let calendar = Calendar.current
        let now = Date.now
        let today = calendar.startOfDay(for: now)

        // Sleep time today (or tomorrow if already past)
        var sleepDate = calendar.date(bySettingHour: config.targetSleepHour,
                                       minute: config.targetSleepMinute,
                                       second: 0, of: today)!
        if sleepDate < now {
            sleepDate = calendar.date(byAdding: .day, value: 1, to: sleepDate)!
        }

        // Shutdown starts shutdownWindowHours before sleep
        let shutdownDate = calendar.date(byAdding: .hour,
                                          value: -config.shutdownWindowHours,
                                          to: sleepDate)!

        self.sleepTime = sleepDate
        self.shutdownStartTime = shutdownDate
        self.secondsUntilSleep = sleepDate.timeIntervalSince(now)
        self.secondsUntilShutdown = shutdownDate.timeIntervalSince(now)

        if now >= shutdownDate {
            state = .active
        } else {
            state = .inactive
        }
    }

    /// Start a 1-second timer to update countdowns.
    public func startCountdown(config: SleepConfig?) {
        stopCountdown()
        refresh(config: config)
        // Schedule shutdown start notification if still inactive
        if state == .inactive, secondsUntilShutdown > 60 {
            scheduleShutdownNotification(inSeconds: secondsUntilShutdown)
        }
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refresh(config: config)
            }
        }
    }

    public func stopCountdown() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Food Safety Check

    /// Returns whether a food/drink is allowed during shutdown.
    public func isAllowedDuringShutdown(_ name: String) -> Bool {
        Self.allowedDrinks.contains { name.localizedCaseInsensitiveContains($0) }
            || name.localizedCaseInsensitiveContains("water")
    }

    /// Risk level if eating during shutdown.
    public enum FlareRisk: String {
        case none = "None"
        case moderate = "GERD Flare Risk"
        case high = "GERD + Sinus Risk"
    }

    /// Assess the risk of eating a specific food during shutdown.
    public func flareRisk(for foodName: String, isShutdownActive: Bool) -> FlareRisk {
        guard isShutdownActive else { return .none }
        if isAllowedDuringShutdown(foodName) { return .none }
        // Acidic, spicy, or heavy foods are high risk
        let highRiskKeywords = ["spicy", "fried", "dairy", "chocolate", "citrus", "tomato", "coffee", "soda", "alcohol", "mint"]
        if highRiskKeywords.contains(where: { foodName.localizedCaseInsensitiveContains($0) }) {
            return .high
        }
        return .moderate
    }

    // MARK: - Formatting

    public static func formatCountdown(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let secs = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%d:%02d", minutes, secs)
    }

    // MARK: - Notifications

    private func scheduleShutdownNotification(inSeconds: TimeInterval) {
        let center = UNUserNotificationCenter.current()
        // Remove any existing
        center.removePendingNotificationRequests(withIdentifiers: ["io.threex1.HealthDebug.shutdownStart"])

        let content = UNMutableNotificationContent()
        content.title = "System Shutdown"
        content.body = "GERD shutdown has started. No more food — only water, chamomile, or anise tea until sleep."
        content.sound = .default
        content.interruptionLevel = .timeSensitive

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(1, inSeconds),
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: "io.threex1.HealthDebug.shutdownStart",
            content: content,
            trigger: trigger
        )
        center.add(request)
    }
}
