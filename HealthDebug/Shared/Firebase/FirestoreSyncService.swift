import Foundation
import FirebaseFirestore
import HealthKit
import HealthDebugKit

/// Syncs onboarding profile and HealthKit snapshot to Firestore for cross-platform access.
///
/// Firestore structure:
///   users/{uid}/profile            — UserProfile + SleepConfig
///   users/{uid}/healthkit/today    — Today's HealthKit metrics snapshot
@MainActor
final class FirestoreSyncService {
    static let shared = FirestoreSyncService()
    private let db = Firestore.firestore()

    private init() {}

    // MARK: - Profile Sync

    /// Write UserProfile + SleepConfig to Firestore after onboarding completes.
    func syncProfile(_ profile: UserProfile, sleepConfig: SleepConfig, uid: String) {
        guard !uid.isEmpty else { return }
        let data: [String: Any] = [
            // Physical
            "weightKg":           profile.weightKg,
            "heightCm":           profile.heightCm,
            "muscleMassKg":       profile.muscleMassKg,
            "metabolicAge":       profile.metabolicAge,
            "visceralFat":        profile.visceralFat,
            "bodyWaterPercent":   profile.bodyWaterPercent,
            // Targets
            "targetWeightKg":          profile.targetWeightKg,
            "targetVisceralFat":       profile.targetVisceralFat,
            "targetBodyWaterPercent":  profile.targetBodyWaterPercent,
            "targetMetabolicAge":      profile.targetMetabolicAge,
            // Work window
            "workStartHour":    profile.workStartHour,
            "workStartMinute":  profile.workStartMinute,
            "workEndHour":      profile.workEndHour,
            "workEndMinute":    profile.workEndMinute,
            // Hydration
            "dailyWaterGoalMl": profile.dailyWaterGoalMl,
            // Personal
            "name":  profile.name,
            "email": profile.email,
            "bio":   profile.bio,
            // Sleep config
            "sleep": [
                "targetSleepHour":      sleepConfig.targetSleepHour,
                "targetSleepMinute":    sleepConfig.targetSleepMinute,
                "shutdownWindowHours":  sleepConfig.shutdownWindowHours
            ] as [String: Any],
            "onboardingCompleted": true,
            "profileUpdatedAt": Timestamp(date: profile.lastUpdated)
        ]
        db.collection("users").document(uid)
            .collection("profile").document("data")
            .setData(data, merge: true)
    }

    // MARK: - HealthKit Snapshot

    /// Fetch current HealthKit data and write to Firestore users/{uid}/healthkit/today.
    /// Called once on first launch after sign-in.
    func syncHealthKitSnapshot(uid: String) async {
        guard !uid.isEmpty, HKHealthStore.isHealthDataAvailable() else { return }

        let store = HKHealthStore()
        var snapshot: [String: Any] = [
            "snapshotAt": Timestamp(date: .now)
        ]

        // Steps (today)
        if let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) {
            let predicate = todayPredicate()
            let descriptor = HKStatisticsQueryDescriptor(
                predicate: .quantitySample(type: stepType, predicate: predicate),
                options: .cumulativeSum
            )
            if let result = try? await descriptor.result(for: store) {
                snapshot["steps"] = result.sumQuantity()?.doubleValue(for: .count()) ?? 0
            }
        }

        // Active energy (today)
        if let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
            let descriptor = HKStatisticsQueryDescriptor(
                predicate: .quantitySample(type: energyType, predicate: todayPredicate()),
                options: .cumulativeSum
            )
            if let result = try? await descriptor.result(for: store) {
                snapshot["activeEnergyKcal"] = result.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
            }
        }

        // Latest heart rate
        if let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate) {
            let descriptor = HKSampleQueryDescriptor<HKQuantitySample>(
                predicates: [.quantitySample(type: hrType)],
                sortDescriptors: [SortDescriptor(\.endDate, order: .reverse)],
                limit: 1
            )
            if let samples = try? await descriptor.result(for: store),
               let sample = samples.first {
                snapshot["heartRateBpm"] = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                snapshot["heartRateAt"] = Timestamp(date: sample.endDate)
            }
        }

        // Sleep last night
        if let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) {
            let cal = Calendar.current
            let now = Date.now
            let start = cal.date(bySettingHour: 18, minute: 0, second: 0,
                                 of: cal.date(byAdding: .day, value: -1, to: now)!)!
            let end   = cal.date(bySettingHour: 12, minute: 0, second: 0, of: now)!
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
            let descriptor = HKSampleQueryDescriptor<HKCategorySample>(
                predicates: [.categorySample(type: sleepType, predicate: predicate)],
                sortDescriptors: [SortDescriptor(\.startDate)]
            )
            if let results = try? await descriptor.result(for: store) {
                var totalSeconds: TimeInterval = 0
                for s in results {
                    switch HKCategoryValueSleepAnalysis(rawValue: s.value) {
                    case .asleepCore, .asleepDeep, .asleepREM, .asleepUnspecified:
                        totalSeconds += s.endDate.timeIntervalSince(s.startDate)
                    default: break
                    }
                }
                snapshot["sleepHours"] = totalSeconds / 3600.0
            }
        }

        // Latest body mass
        if let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) {
            let descriptor = HKSampleQueryDescriptor<HKQuantitySample>(
                predicates: [.quantitySample(type: weightType)],
                sortDescriptors: [SortDescriptor(\.endDate, order: .reverse)],
                limit: 1
            )
            if let samples = try? await descriptor.result(for: store),
               let sample = samples.first {
                snapshot["weightKg"] = sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
                snapshot["weightAt"] = Timestamp(date: sample.endDate)
            }
        }

        // Latest body fat %
        if let bfType = HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage) {
            let descriptor = HKSampleQueryDescriptor<HKQuantitySample>(
                predicates: [.quantitySample(type: bfType)],
                sortDescriptors: [SortDescriptor(\.endDate, order: .reverse)],
                limit: 1
            )
            if let samples = try? await descriptor.result(for: store),
               let sample = samples.first {
                snapshot["bodyFatPercent"] = sample.quantity.doubleValue(for: .percent()) * 100
            }
        }

        // Resting heart rate
        if let rhrType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) {
            let descriptor = HKSampleQueryDescriptor<HKQuantitySample>(
                predicates: [.quantitySample(type: rhrType)],
                sortDescriptors: [SortDescriptor(\.endDate, order: .reverse)],
                limit: 1
            )
            if let samples = try? await descriptor.result(for: store),
               let sample = samples.first {
                snapshot["restingHeartRateBpm"] = sample.quantity.doubleValue(
                    for: HKUnit.count().unitDivided(by: .minute()))
            }
        }

        try? await db.collection("users").document(uid)
            .collection("healthkit").document("today")
            .setData(snapshot, merge: true)
    }

    // MARK: - Helper

    private func todayPredicate() -> NSPredicate {
        let start = Calendar.current.startOfDay(for: .now)
        return HKQuery.predicateForSamples(withStart: start, end: .now, options: .strictStartDate)
    }
}
