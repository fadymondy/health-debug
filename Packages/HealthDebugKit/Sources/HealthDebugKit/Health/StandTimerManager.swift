import Foundation
import SwiftData
import UserNotifications

// MARK: - Pomodoro Phase

public enum PomodoroPhase: String, Equatable {
    case idle
    case work           // focus interval (default 25 min)
    case standAlert     // work done — waiting for user to start break
    case shortBreak     // short break after each work session (default 5 min)
    case longBreak      // long break after every N work sessions (default 15 min)
}

// MARK: - PomodoroManager

/// Full Pomodoro cycle manager.
/// Cycle: work → shortBreak → work → shortBreak → … → (every `cyclesBeforeLongBreak`) → longBreak → repeat.
/// Legacy alias: `StandTimerManager` maps to this class for backward compatibility.
@MainActor
public final class PomodoroManager: ObservableObject {

    public static let shared = PomodoroManager()

    // MARK: - Configuration (in seconds)

    public static let workDurationSeconds: TimeInterval     = 25 * 60
    public static let shortBreakSeconds: TimeInterval       = 5 * 60
    public static let longBreakSeconds: TimeInterval        = 15 * 60
    public static let cyclesBeforeLongBreak: Int            = 4
    /// Daily target: completed work sessions.
    public static let dailyTarget: Int                      = 8

    // Legacy compat: `sitIntervalSeconds` maps to work duration.
    public static var sitIntervalSeconds: TimeInterval { workDurationSeconds }
    // Legacy compat: `walkDurationSeconds` maps to short break.
    public static var walkDurationSeconds: Int { Int(shortBreakSeconds) }

    // MARK: - Published State

    @Published public var phase: PomodoroPhase = .idle
    /// Seconds remaining in the current phase.
    @Published public var secondsRemaining: TimeInterval = workDurationSeconds
    /// Completed work sessions today.
    @Published public var todayCompleted: Int = 0
    /// Total completed cycles this session.
    @Published public var completedCycles: Int = 0
    /// Current cycle position within a set (1…cyclesBeforeLongBreak).
    @Published public var cyclePosition: Int = 0

    // MARK: - Legacy compat computed properties

    /// Alias for `secondsRemaining` when in work phase.
    public var sitSecondsRemaining: TimeInterval { secondsRemaining }
    /// Alias for `secondsRemaining` (as Int) when in break phase.
    public var walkSecondsRemaining: Int { Int(secondsRemaining) }

    /// Legacy state enum — maps new phases to old cases.
    public enum TimerState: Equatable {
        case idle
        case sitting
        case standAlert
        case walking
    }

    public var state: TimerState {
        switch phase {
        case .idle:         return .idle
        case .work:         return .sitting
        case .standAlert:   return .standAlert
        case .shortBreak:   return .walking
        case .longBreak:    return .walking
        }
    }

    // MARK: - Private

    private var activeTimer: Timer?
    private var phaseStartDate: Date?
    private var currentSession: PomodoroSession?

    private init() {}

    // MARK: - Public API

    /// Start or resume a work session.
    public func startCycle() {
        guard phase == .idle else { return }
        beginPhase(.work)
    }

    /// Stop the timer entirely and reset.
    public func stopCycle() {
        cancelTimer()
        cancelAllNotifications()
        phase = .idle
        secondsRemaining = Self.workDurationSeconds
    }

    /// Skip the current break and go straight to the next work session.
    public func skipBreak() {
        guard phase == .shortBreak || phase == .longBreak || phase == .standAlert else { return }
        cancelTimer()
        cancelAllNotifications()
        phase = .idle
        beginPhase(.work)
    }

    /// Legacy: begin walk = start short break.
    public func beginWalk(context: ModelContext) {
        guard phase == .work || phase == .idle else { return }
        completeWorkSession(context: context)
    }

    /// Start the appropriate break after standAlert.
    public func startBreak() {
        guard phase == .standAlert else { return }
        cancelTimer()
        cancelAllNotifications()
        let isLong = cyclePosition == 0 && completedCycles > 0
        beginPhase(isLong ? .longBreak : .shortBreak)
    }

    /// Legacy: skip stand = skip to next work.
    public func skipStand() {
        guard phase == .shortBreak || phase == .longBreak else {
            startCycle()
            return
        }
        skipBreak()
    }

    // MARK: - Notification Auth

    public func requestNotificationPermission() async {
        _ = try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge])
    }

    // MARK: - Refresh today count

    public func refreshTodayCount(context: ModelContext) {
        todayCompleted = PomodoroSession.todayCompletedCount(in: context)
    }

    // MARK: - Phase Engine

    private func beginPhase(_ newPhase: PomodoroPhase) {
        cancelTimer()
        phase = newPhase
        let duration: TimeInterval
        switch newPhase {
        case .work:         duration = Self.workDurationSeconds
        case .shortBreak:   duration = Self.shortBreakSeconds
        case .longBreak:    duration = Self.longBreakSeconds
        case .standAlert, .idle: return
        }
        secondsRemaining = duration
        phaseStartDate = .now
        scheduleNotification(for: newPhase, duration: duration)
        startCountdown(duration: duration)
    }

    private func startCountdown(duration: TimeInterval) {
        let start = Date.now
        activeTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                let elapsed = Date.now.timeIntervalSince(start)
                let remaining = duration - elapsed
                if remaining <= 0 {
                    self.activeTimer?.invalidate()
                    self.activeTimer = nil
                    self.secondsRemaining = 0
                    self.handlePhaseExpired()
                } else {
                    self.secondsRemaining = remaining
                }
            }
        }
    }

    private func handlePhaseExpired() {
        switch phase {
        case .work:
            // Work session ended — show stand alert, waiting for user to start break
            cyclePosition += 1
            let isLongBreak = cyclePosition >= Self.cyclesBeforeLongBreak
            if isLongBreak {
                cyclePosition = 0
                completedCycles += 1
            }
            phase = .standAlert
            secondsRemaining = 0
        case .shortBreak, .longBreak:
            // Break ended — auto-start next work session
            phase = .idle
            beginPhase(.work)
        case .standAlert, .idle:
            break
        }
    }

    private func completeWorkSession(context: ModelContext) {
        cancelTimer()
        cancelAllNotifications()

        // Record completed work session
        let session = PomodoroSession(
            startTime: phaseStartDate ?? .now,
            durationSeconds: Int(Self.workDurationSeconds),
            completed: true,
            phase: "work",
            cycleIndex: completedCycles * Self.cyclesBeforeLongBreak + cyclePosition
        )
        context.insert(session)
        try? context.save()
        todayCompleted += 1

        // Advance cycle position
        cyclePosition += 1
        let isLongBreak = cyclePosition >= Self.cyclesBeforeLongBreak
        if isLongBreak {
            cyclePosition = 0
            completedCycles += 1
        }

        // Begin appropriate break
        beginPhase(isLongBreak ? .longBreak : .shortBreak)
    }

    private func cancelTimer() {
        activeTimer?.invalidate()
        activeTimer = nil
    }

    // MARK: - Notifications

    private func scheduleNotification(for newPhase: PomodoroPhase, duration: TimeInterval) {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.sound = .default
        content.interruptionLevel = .timeSensitive

        switch newPhase {
        case .work:
            content.title = NSLocalizedString("Focus Session Complete", comment: "")
            content.body = NSLocalizedString("Great work! Time for a break.", comment: "")
        case .shortBreak:
            content.title = NSLocalizedString("Break Over", comment: "")
            content.body = NSLocalizedString("Ready for the next focus session?", comment: "")
        case .longBreak:
            content.title = NSLocalizedString("Long Break Over", comment: "")
            content.body = NSLocalizedString("Fully recharged — let's get back to work!", comment: "")
        case .standAlert, .idle:
            return
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: duration, repeats: false)
        let id = "io.threex1.HealthDebug.pomodoro.\(newPhase.rawValue)"
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request)
    }

    private func cancelAllNotifications() {
        let ids = ["work", "shortBreak", "longBreak"].map { "io.threex1.HealthDebug.pomodoro.\($0)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }
}

// MARK: - Legacy alias

/// Backward-compat alias so existing call-sites (ContentView, DailyFlowView, IntelligenceView)
/// continue to compile without changes.
public typealias StandTimerManager = PomodoroManager
