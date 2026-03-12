import Foundation
import SwiftData

/// Fires a daily notification at the user's configured bedtime if they haven't gone to sleep.
/// Uses a daily repeating UNCalendarNotificationTrigger at the bedtime hour/minute.
@MainActor
public final class SleepOverrunScheduler {

    public static let shared = SleepOverrunScheduler()
    private init() {}

    private static let notificationID = "io.threex1.HealthDebug.alert.sleepOverrun"

    public func reschedule(sleepConfig: SleepConfig) async {
        NotificationManager.shared.cancel(id: Self.notificationID)

        await NotificationManager.shared.scheduleDaily(
            id: Self.notificationID,
            title: String(localized: "Past Your Bedtime"),
            body: String(localized: "You're past your target sleep time. Put the phone down and rest."),
            category: .sleep,
            hour: sleepConfig.targetSleepHour,
            minute: sleepConfig.targetSleepMinute,
            deepLink: nil
        )
    }

    public func cancel() {
        NotificationManager.shared.cancel(id: Self.notificationID)
    }
}
