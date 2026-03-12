import Foundation
import SwiftData

/// Schedules one or more daily coffee time reminder notifications.
///
/// Fires at user-configured time slots. Toggled and configured in Settings.
@MainActor
public final class CoffeeTimeScheduler {

    public static let shared = CoffeeTimeScheduler()
    private init() {}

    private static let idPrefix = "io.threex1.HealthDebug.alert.coffee."

    /// Reschedule after settings change. Pass profile for toggle + time.
    public func reschedule(profile: UserProfile) async {
        // Cancel all existing coffee reminders
        NotificationManager.shared.cancelAll(prefix: Self.idPrefix)

        guard profile.coffeeAlertEnabled else { return }

        await NotificationManager.shared.scheduleDaily(
            id: Self.idPrefix + "primary",
            title: String(localized: "Coffee Time"),
            body: String(localized: "Time for your coffee break. Enjoy it mindfully."),
            category: .coffee,
            hour: profile.coffeeAlertHour,
            minute: profile.coffeeAlertMinute,
            deepLink: "caffeine"
        )
    }

    public func cancel() {
        NotificationManager.shared.cancelAll(prefix: Self.idPrefix)
    }
}
