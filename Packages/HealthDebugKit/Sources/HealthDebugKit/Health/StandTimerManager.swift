import Foundation
import SwiftData
import UserNotifications

/// Manages the 90-minute Pomodoro stand timer cycle.
/// Every 90 minutes of sitting → notification → 3-minute walk session.
/// Based on insulin sensitivity research: prolonged sitting degrades glucose uptake.
@MainActor
public final class StandTimerManager: ObservableObject {

    public static let shared = StandTimerManager()

    /// Interval between stand breaks (90 minutes).
    public static let sitIntervalSeconds: TimeInterval = 90 * 60
    /// Duration of a walk break (3 minutes).
    public static let walkDurationSeconds: Int = 180
    /// Target stand sessions per work day.
    public static let dailyTarget: Int = 6

    // MARK: - State

    public enum TimerState: Equatable {
        case idle
        case sitting          // counting down 90 min
        case standAlert       // time to stand — waiting for user
        case walking          // 3-min walk in progress
    }

    @Published public var state: TimerState = .idle
    @Published public var sitSecondsRemaining: TimeInterval = sitIntervalSeconds
    @Published public var walkSecondsRemaining: Int = walkDurationSeconds
    @Published public var todayCompleted: Int = 0

    private var sitTimer: Timer?
    private var walkTimer: Timer?
    private var currentSession: StandSession?

    private init() {}

    // MARK: - Start / Stop Cycle

    /// Begin a 90-min sit cycle. Schedules a local notification at expiry.
    public func startCycle() {
        guard state == .idle || state == .standAlert else { return }
        state = .sitting
        sitSecondsRemaining = Self.sitIntervalSeconds
        scheduleNotification()
        startSitCountdown()
    }

    /// Stop the current cycle entirely.
    public func stopCycle() {
        sitTimer?.invalidate()
        sitTimer = nil
        walkTimer?.invalidate()
        walkTimer = nil
        cancelNotification()
        state = .idle
        sitSecondsRemaining = Self.sitIntervalSeconds
        walkSecondsRemaining = Self.walkDurationSeconds
    }

    // MARK: - Walk Session

    /// User acknowledged the stand alert — begin 3-min walk.
    public func beginWalk(context: ModelContext) {
        state = .walking
        walkSecondsRemaining = Self.walkDurationSeconds
        currentSession = StandSession(startTime: .now, durationSeconds: Self.walkDurationSeconds, completed: false)
        context.insert(currentSession!)
        startWalkCountdown(context: context)
    }

    /// Skip the stand alert and restart the sit cycle.
    public func skipStand() {
        startCycle()
    }

    // MARK: - Notification Authorization

    public func requestNotificationPermission() async {
        let center = UNUserNotificationCenter.current()
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    // MARK: - Refresh Today Count

    public func refreshTodayCount(context: ModelContext) {
        todayCompleted = StandSession.todayCompletedCount(in: context)
    }

    // MARK: - Private Timers

    private func startSitCountdown() {
        sitTimer?.invalidate()
        let start = Date.now
        sitTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                let elapsed = Date.now.timeIntervalSince(start)
                let remaining = Self.sitIntervalSeconds - elapsed
                if remaining <= 0 {
                    self.sitTimer?.invalidate()
                    self.sitTimer = nil
                    self.sitSecondsRemaining = 0
                    self.state = .standAlert
                } else {
                    self.sitSecondsRemaining = remaining
                }
            }
        }
    }

    private func startWalkCountdown(context: ModelContext) {
        walkTimer?.invalidate()
        let start = Date.now
        walkTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                let elapsed = Int(Date.now.timeIntervalSince(start))
                let remaining = Self.walkDurationSeconds - elapsed
                if remaining <= 0 {
                    self.walkTimer?.invalidate()
                    self.walkTimer = nil
                    self.walkSecondsRemaining = 0
                    self.completeWalk(context: context)
                } else {
                    self.walkSecondsRemaining = remaining
                }
            }
        }
    }

    private func completeWalk(context: ModelContext) {
        currentSession?.completed = true
        try? context.save()
        todayCompleted += 1
        currentSession = nil
        // Auto-start next sit cycle
        startCycle()
    }

    // MARK: - Notifications

    private static let notificationID = "io.threex1.HealthDebug.standReminder"

    private func scheduleNotification() {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = "Time to Stand"
        content.body = "You've been sitting for 90 minutes. Take a 3-minute walk to boost insulin sensitivity."
        content.sound = .default
        content.interruptionLevel = .timeSensitive

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: Self.sitIntervalSeconds,
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: Self.notificationID,
            content: content,
            trigger: trigger
        )
        center.add(request)
    }

    private func cancelNotification() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [Self.notificationID])
    }
}
