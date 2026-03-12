import Foundation
import SwiftData

/// Fires periodic movement reminders during working hours.
///
/// Reminds the user to stand up, move, or step away from the screen.
/// Interval configurable in Settings (default 60 min). Only fires during
/// the configured work window.
@MainActor
public final class MovementAlertScheduler {

    public static let shared = MovementAlertScheduler()
    private init() {}

    private static let idPrefix = "io.threex1.HealthDebug.alert.movement."

    /// Reschedule repeating movement alerts across the work window.
    /// Creates one alert per interval slot within work hours.
    public func reschedule(profile: UserProfile) async {
        NotificationManager.shared.cancelAll(prefix: Self.idPrefix)

        guard profile.movementAlertEnabled else { return }

        let intervalMinutes = profile.movementAlertIntervalMinutes
        let startMinutes = profile.workStartHour * 60 + profile.workStartMinute
        let endMinutes   = profile.workEndHour   * 60 + profile.workEndMinute

        var current = startMinutes + intervalMinutes
        var index = 0
        while current < endMinutes {
            let hour   = (current / 60) % 24
            let minute = current % 60
            let id     = Self.idPrefix + "slot\(index)"

            await NotificationManager.shared.scheduleDaily(
                id: id,
                title: String(localized: "Move Your Body"),
                body: String(localized: "Stand up, stretch, or take a short walk. Your body needs it."),
                category: .movement,
                hour: hour,
                minute: minute,
                deepLink: "standTimer"
            )

            current += intervalMinutes
            index += 1
        }
    }

    public func cancel() {
        NotificationManager.shared.cancelAll(prefix: Self.idPrefix)
    }
}
