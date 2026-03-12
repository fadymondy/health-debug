import Foundation
import SwiftData

/// Schedules the daily weight check-in alert.
///
/// Fires once per day at the user's configured time + delay (default: 7:05am).
/// Deep-links to the weight screen. Configurable via UserProfile.
@MainActor
public final class WeightAlertScheduler {

    // MARK: - Singleton

    public static let shared = WeightAlertScheduler()
    private init() {}

    // MARK: - Notification ID

    private static let notificationID = "io.threex1.HealthDebug.alert.weightCheckIn"

    // MARK: - Schedule

    /// Reschedules (cancels + re-creates) the daily weight check-in notification
    /// based on the current UserProfile settings.
    public func reschedule(profile: UserProfile) async {
        NotificationManager.shared.cancel(id: Self.notificationID)

        guard profile.weightAlertEnabled else { return }

        let totalMinutes = profile.weightAlertHour * 60
            + profile.weightAlertMinute
            + profile.weightAlertDelayMinutes

        let hour   = (totalMinutes / 60) % 24
        let minute = totalMinutes % 60

        await NotificationManager.shared.scheduleDaily(
            id: Self.notificationID,
            title: String(localized: "Time to Weigh In"),
            body: String(localized: "Step on your smart scale and log your weight for today."),
            category: .weight,
            hour: hour,
            minute: minute,
            deepLink: "weight"
        )
    }

    // MARK: - Cancel

    public func cancel() {
        NotificationManager.shared.cancel(id: Self.notificationID)
    }

    // MARK: - One-shot (manual trigger, e.g. from background task)

    /// Fire an immediate weight check-in notification (used by BGTask health check pass).
    public func fireNow(context: ModelContext) async {
        let profiles = (try? context.fetch(UserProfile.currentDescriptor())) ?? []
        guard let profile = profiles.first, profile.weightAlertEnabled else { return }

        await NotificationManager.shared.schedule(
            id: UUID().uuidString,
            title: String(localized: "Time to Weigh In"),
            body: String(localized: "Step on your smart scale and log your weight for today."),
            category: .weight,
            source: .system,
            deepLink: "weight"
        )
    }
}
