import Foundation
import SwiftData
import FirebaseFirestore
import HealthDebugKit

/// Single source of truth for UserProfile and SleepConfig.
///
/// - Firestore is primary: loads on sign-in and writes back on every save.
/// - SwiftData is the local cache: used offline and as the SwiftUI model source.
/// - All views that used @Query(UserProfile) should instead observe ProfileStore.
@MainActor
final class ProfileStore: ObservableObject {
    static let shared = ProfileStore()

    @Published private(set) var profile: UserProfile?
    @Published private(set) var sleepConfig: SleepConfig?
    @Published private(set) var isLoading = false

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    private init() {}

    // MARK: - Load from Firestore

    /// Start a real-time listener for users/{uid}/profile/data.
    /// Also keeps SwiftData cache in sync for offline use.
    func startListening(uid: String, modelContext: ModelContext) {
        guard !uid.isEmpty else { return }
        stopListening()
        isLoading = true

        listener = db.collection("users").document(uid)
            .collection("profile").document("data")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                Task { @MainActor in
                    self.isLoading = false
                    guard let data = snapshot?.data(), !data.isEmpty else {
                        // Firestore doc doesn't exist yet — fall back to local SwiftData
                        self.loadFromSwiftData(modelContext: modelContext)
                        return
                    }
                    self.applyFirestoreData(data, modelContext: modelContext)
                }
            }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    // MARK: - Save (writes to both Firestore + SwiftData)

    func saveProfile(_ profile: UserProfile, sleepConfig: SleepConfig,
                     uid: String, modelContext: ModelContext) {
        // Update in-memory
        self.profile = profile
        self.sleepConfig = sleepConfig

        // SwiftData local cache
        modelContext.insert(profile)
        modelContext.insert(sleepConfig)
        try? modelContext.save()

        // Firestore primary store
        FirestoreSyncService.shared.syncProfile(profile, sleepConfig: sleepConfig, uid: uid)
    }

    // MARK: - Private helpers

    private func loadFromSwiftData(modelContext: ModelContext) {
        let profileDescriptor = FetchDescriptor<UserProfile>(
            sortBy: [SortDescriptor(\.lastUpdated, order: .reverse)]
        )
        let sleepDescriptor = FetchDescriptor<SleepConfig>(
            sortBy: [SortDescriptor(\.lastUpdated, order: .reverse)]
        )
        profile = (try? modelContext.fetch(profileDescriptor))?.first
        sleepConfig = (try? modelContext.fetch(sleepDescriptor))?.first
    }

    private func applyFirestoreData(_ d: [String: Any], modelContext: ModelContext) {
        // Build a UserProfile from Firestore data
        let p = UserProfile(
            weightKg:                d["weightKg"]               as? Double ?? 108,
            heightCm:                d["heightCm"]               as? Double ?? 179,
            muscleMassKg:            d["muscleMassKg"]           as? Double ?? 0,
            metabolicAge:            d["metabolicAge"]           as? Int    ?? 53,
            visceralFat:             d["visceralFat"]            as? Int    ?? 14,
            bodyWaterPercent:        d["bodyWaterPercent"]       as? Double ?? 46.7,
            workStartHour:           d["workStartHour"]          as? Int    ?? 9,
            workStartMinute:         d["workStartMinute"]        as? Int    ?? 0,
            workEndHour:             d["workEndHour"]            as? Int    ?? 19,
            workEndMinute:           d["workEndMinute"]          as? Int    ?? 0,
            targetWeightKg:          d["targetWeightKg"]         as? Double ?? 90,
            targetVisceralFat:       d["targetVisceralFat"]      as? Int    ?? 10,
            targetBodyWaterPercent:  d["targetBodyWaterPercent"] as? Double ?? 55,
            targetMetabolicAge:      d["targetMetabolicAge"]     as? Int    ?? 35,
            dailyWaterGoalMl:        d["dailyWaterGoalMl"]       as? Int    ?? 2500,
            onboardingCompleted:     d["onboardingCompleted"]    as? Bool   ?? false,
            name:                    d["name"]                   as? String ?? "",
            email:                   d["email"]                  as? String ?? "",
            bio:                     d["bio"]                    as? String ?? "",
            lastUpdated:             (d["profileUpdatedAt"] as? Timestamp)?.dateValue() ?? .now
        )

        // Build SleepConfig from nested "sleep" map
        var sc = SleepConfig()
        if let sleep = d["sleep"] as? [String: Any] {
            sc = SleepConfig(
                targetSleepHour:     sleep["targetSleepHour"]     as? Int ?? 23,
                targetSleepMinute:   sleep["targetSleepMinute"]   as? Int ?? 0,
                shutdownWindowHours: sleep["shutdownWindowHours"] as? Int ?? 4
            )
        }

        profile = p
        sleepConfig = sc

        // Upsert into local SwiftData cache
        let descriptor = FetchDescriptor<UserProfile>(
            sortBy: [SortDescriptor(\.lastUpdated, order: .reverse)]
        )
        if let existing = (try? modelContext.fetch(descriptor))?.first {
            // Update existing record in place
            existing.weightKg               = p.weightKg
            existing.heightCm               = p.heightCm
            existing.muscleMassKg           = p.muscleMassKg
            existing.metabolicAge           = p.metabolicAge
            existing.visceralFat            = p.visceralFat
            existing.bodyWaterPercent       = p.bodyWaterPercent
            existing.workStartHour          = p.workStartHour
            existing.workStartMinute        = p.workStartMinute
            existing.workEndHour            = p.workEndHour
            existing.workEndMinute          = p.workEndMinute
            existing.targetWeightKg         = p.targetWeightKg
            existing.targetVisceralFat      = p.targetVisceralFat
            existing.targetBodyWaterPercent = p.targetBodyWaterPercent
            existing.targetMetabolicAge     = p.targetMetabolicAge
            existing.dailyWaterGoalMl       = p.dailyWaterGoalMl
            existing.onboardingCompleted    = p.onboardingCompleted
            existing.name                   = p.name
            existing.email                  = p.email
            existing.bio                    = p.bio
            existing.lastUpdated            = p.lastUpdated
        } else {
            modelContext.insert(p)
        }

        let sleepDesc = FetchDescriptor<SleepConfig>(
            sortBy: [SortDescriptor(\.lastUpdated, order: .reverse)]
        )
        if let existingSleep = (try? modelContext.fetch(sleepDesc))?.first {
            existingSleep.targetSleepHour     = sc.targetSleepHour
            existingSleep.targetSleepMinute   = sc.targetSleepMinute
            existingSleep.shutdownWindowHours = sc.shutdownWindowHours
        } else {
            modelContext.insert(sc)
        }
        try? modelContext.save()
    }
}
