import Foundation
import SwiftData

/// Fires a warning notification N minutes before the GERD shutdown cutoff time.
///
/// Integrates with SleepConfig.shutdownStartTime. Lead time configurable
/// in Settings (default 15 min). Supplements the in-app ShutdownManager.
@MainActor
public final class GERDShutdownAlertScheduler {

    public static let shared = GERDShutdownAlertScheduler()
    private init() {}

    private static let notificationID = "io.threex1.HealthDebug.alert.gerdShutdown"

    /// Reschedule after sleep/shutdown settings change.
    public func reschedule(sleepConfig: SleepConfig, leadMinutes: Int) async {
        NotificationManager.shared.cancel(id: Self.notificationID)

        let shutdown = sleepConfig.shutdownStartTime
        let shutdownH = shutdown.hour ?? 19
        let shutdownM = shutdown.minute ?? 0

        let totalMinutes = shutdownH * 60 + shutdownM - leadMinutes
        let clamped = ((totalMinutes % (24 * 60)) + (24 * 60)) % (24 * 60)
        let hour   = clamped / 60
        let minute = clamped % 60

        await NotificationManager.shared.scheduleDaily(
            id: Self.notificationID,
            title: String(localized: "Shutdown Window in \(leadMinutes) Minutes"),
            body: String(localized: "Finish eating now — your GERD shutdown window starts soon."),
            category: .shutdown,
            hour: hour,
            minute: minute,
            deepLink: "shutdown"
        )
    }

    public func cancel() {
        NotificationManager.shared.cancel(id: Self.notificationID)
    }
}
