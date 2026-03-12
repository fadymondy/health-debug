import Foundation
import SwiftData

/// Schedules a one-shot hygiene reminder after each meal log.
///
/// Fires N minutes (configurable, default 5) after a meal is logged,
/// reminding the user to wash hands and brush teeth.
@MainActor
public final class HygieneAlertScheduler {

    // MARK: - Singleton

    public static let shared = HygieneAlertScheduler()
    private init() {}

    // MARK: - Notification ID prefix

    private static let idPrefix = "io.threex1.HealthDebug.alert.hygiene."

    // MARK: - Trigger after meal log

    /// Call this immediately after a meal is successfully logged.
    /// Schedules a one-shot reminder N minutes from now.
    public func scheduleAfterMeal(profile: UserProfile?) async {
        let enabled = profile?.hygieneAlertEnabled ?? true
        guard enabled else { return }

        let delay = profile?.hygieneAlertDelayMinutes ?? 5
        let fireDate = Date(timeIntervalSinceNow: TimeInterval(delay * 60))
        let notifID = Self.idPrefix + UUID().uuidString

        await NotificationManager.shared.schedule(
            id: notifID,
            title: String(localized: "Hygiene Reminder"),
            body: String(localized: "Wash your hands and brush your teeth — your body will thank you."),
            category: .hygiene,
            source: .system,
            triggerDate: fireDate,
            deepLink: nil
        )
    }
}
