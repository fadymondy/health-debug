import Foundation
import SwiftData

/// Delivers a notification when a significant heart rate change is detected.
///
/// Called from HealthKitManager when a new heart rate sample arrives via
/// HKAnchoredObjectQuery background delivery. Configurable spike/drop thresholds.
@MainActor
public final class HeartRateAlertScheduler {

    public static let shared = HeartRateAlertScheduler()
    private init() {}

    private static let idPrefix = "io.threex1.HealthDebug.alert.heartRate."

    /// Default thresholds — values outside this range trigger an alert.
    public static let defaultHighBPM: Int = 120
    public static let defaultLowBPM: Int  = 45

    /// Minimum interval between heart rate alerts to avoid spamming (seconds).
    private static let cooldown: TimeInterval = 300 // 5 min
    private var lastAlertDate: Date?

    /// Call from HealthKitManager when a new HR sample arrives.
    public func evaluate(bpm: Int, profile: UserProfile?) async {
        let highThreshold = profile?.heartRateHighThreshold ?? Self.defaultHighBPM
        let lowThreshold  = profile?.heartRateLowThreshold  ?? Self.defaultLowBPM

        let isHigh = bpm >= highThreshold
        let isLow  = bpm <= lowThreshold
        guard isHigh || isLow else { return }

        // Cooldown check
        if let last = lastAlertDate,
           Date.now.timeIntervalSince(last) < Self.cooldown { return }
        lastAlertDate = Date.now

        let title: String
        let body: String
        if isHigh {
            title = String(localized: "High Heart Rate Detected")
            body  = String(localized: "Your heart rate is \(bpm) bpm — above your \(highThreshold) bpm threshold.")
        } else {
            title = String(localized: "Low Heart Rate Detected")
            body  = String(localized: "Your heart rate is \(bpm) bpm — below your \(lowThreshold) bpm threshold.")
        }

        await NotificationManager.shared.schedule(
            id: Self.idPrefix + UUID().uuidString,
            title: title,
            body: body,
            category: .heartRate,
            source: .system,
            deepLink: "heartRate"
        )
    }
}
