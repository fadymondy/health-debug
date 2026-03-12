import Foundation
import SwiftData

/// Schedules daily Pomodoro start and end alerts.
///
/// - Start alert: fires N minutes before work start time (default 15 min early)
/// - End alert:   fires N minutes before work end time (default 15 min early)
/// Both are daily repeating UNCalendarNotificationTrigger notifications.
@MainActor
public final class PomodoroAlertScheduler {

    // MARK: - Singleton

    public static let shared = PomodoroAlertScheduler()
    private init() {}

    // MARK: - Notification IDs

    private static let startID = "io.threex1.HealthDebug.alert.pomodoroStart"
    private static let endID   = "io.threex1.HealthDebug.alert.pomodoroEnd"

    // MARK: - Reschedule both alerts

    /// Call after saving work hours or lead time settings.
    public func reschedule(profile: UserProfile) async {
        await rescheduleStart(profile: profile)
        await rescheduleEnd(profile: profile)
    }

    // MARK: - Start Alert

    private func rescheduleStart(profile: UserProfile) async {
        NotificationManager.shared.cancel(id: Self.startID)
        guard profile.pomodoroStartAlertEnabled else { return }

        let totalMinutes = profile.workStartHour * 60
            + profile.workStartMinute
            - profile.pomodoroStartLeadMinutes

        // Handle midnight wrap
        let clamped = ((totalMinutes % (24 * 60)) + (24 * 60)) % (24 * 60)
        let hour   = clamped / 60
        let minute = clamped % 60

        await NotificationManager.shared.scheduleDaily(
            id: Self.startID,
            title: String(localized: "Focus Session Starting Soon"),
            body: String(localized: "Your work day begins in \(profile.pomodoroStartLeadMinutes) minutes. Get ready to focus."),
            category: .pomodoroStart,
            hour: hour,
            minute: minute,
            deepLink: "standTimer"
        )
    }

    // MARK: - End Alert

    private func rescheduleEnd(profile: UserProfile) async {
        NotificationManager.shared.cancel(id: Self.endID)
        guard profile.pomodoroEndAlertEnabled else { return }

        let totalMinutes = profile.workEndHour * 60
            + profile.workEndMinute
            - profile.pomodoroEndLeadMinutes

        let clamped = ((totalMinutes % (24 * 60)) + (24 * 60)) % (24 * 60)
        let hour   = clamped / 60
        let minute = clamped % 60

        await NotificationManager.shared.scheduleDaily(
            id: Self.endID,
            title: String(localized: "Wrapping Up Soon"),
            body: String(localized: "Your work day ends in \(profile.pomodoroEndLeadMinutes) minutes. Start your final Pomodoro."),
            category: .pomodoroEnd,
            hour: hour,
            minute: minute,
            deepLink: "standTimer"
        )
    }

    // MARK: - Cancel

    public func cancelAll() {
        NotificationManager.shared.cancel(id: Self.startID)
        NotificationManager.shared.cancel(id: Self.endID)
    }
}
