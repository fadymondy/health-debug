import Foundation
import SwiftData

/// Fires a push notification if no water has been logged within the gap threshold.
///
/// Evaluated by the background hydration check pass every 30 minutes.
/// Default gap: 60 minutes without a water log triggers an alert.
@MainActor
public final class HydrationAlertScheduler {

    public static let shared = HydrationAlertScheduler()
    private init() {}

    private static let idPrefix = "io.threex1.HealthDebug.alert.hydration."
    private static let cooldown: TimeInterval = 30 * 60 // 30 min between alerts

    private var lastAlertDate: Date?

    /// Check last water log timestamp and fire if gap exceeded.
    public func checkAndFire(context: ModelContext, profile: UserProfile?) async {
        guard profile?.hydrationAlertEnabled ?? true else { return }

        // Cooldown
        if let last = lastAlertDate,
           Date.now.timeIntervalSince(last) < Self.cooldown { return }

        let gapMinutes = profile?.hydrationAlertGapMinutes ?? 60
        let logs = (try? context.fetch(WaterLog.todayDescriptor())) ?? []
        let lastLog = logs.map(\.timestamp).max()

        let gapExceeded: Bool
        if let last = lastLog {
            gapExceeded = Date.now.timeIntervalSince(last) > TimeInterval(gapMinutes * 60)
        } else {
            // No water logged today at all — only alert if it's past 9am
            let hour = Calendar.current.component(.hour, from: Date.now)
            gapExceeded = hour >= 9
        }

        guard gapExceeded else { return }
        lastAlertDate = Date.now

        await NotificationManager.shared.schedule(
            id: Self.idPrefix + UUID().uuidString,
            title: String(localized: "Time to Drink Water"),
            body: String(localized: "You haven't logged water in a while. Stay hydrated — drink a glass now."),
            category: .hydration,
            source: .system,
            deepLink: "hydration"
        )
    }
}
