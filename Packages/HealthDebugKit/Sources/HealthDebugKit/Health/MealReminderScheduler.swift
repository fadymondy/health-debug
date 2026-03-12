import Foundation
import SwiftData

/// Reminds the user to log a meal if they haven't logged during their eating window.
///
/// Fires a one-shot notification at the eating window midpoint if no meal has been
/// logged today within the window. Evaluated by the background health check pass.
@MainActor
public final class MealReminderScheduler {

    public static let shared = MealReminderScheduler()
    private init() {}

    private static let idPrefix = "io.threex1.HealthDebug.alert.mealReminder."

    /// Check and fire reminder if no meal logged during current eating window.
    public func checkAndFire(context: ModelContext, profile: UserProfile?) async {
        guard profile?.mealReminderEnabled ?? true else { return }

        let meals = (try? context.fetch(MealLog.todayDescriptor())) ?? []

        // If already logged at least one meal today, skip
        guard meals.isEmpty else { return }

        // Only fire once per day — check if we already sent one today
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: .now)
        let notifs = (try? context.fetch(NotificationItem.allDescriptor())) ?? []
        let alreadySent = notifs.contains {
            $0.notificationCategory == .meal &&
            $0.timestamp >= todayStart
        }
        guard !alreadySent else { return }

        await NotificationManager.shared.schedule(
            id: Self.idPrefix + UUID().uuidString,
            title: String(localized: "Don't Forget to Log Your Meal"),
            body: String(localized: "You haven't logged any food today. Keep your nutrition tracking on track."),
            category: .meal,
            source: .system,
            deepLink: "nutrition"
        )
    }
}
