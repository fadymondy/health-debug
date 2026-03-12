import Foundation
import FirebaseFirestore
import HealthDebugKit

/// Writes WidgetSnapshot to Firestore under users/{uid}/health/snapshot
/// and provides a real-time listener for macOS.
@MainActor
public final class FirebaseSync: ObservableObject {
    public static let shared = FirebaseSync()
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    private init() {}

    /// Write snapshot to Firestore (called by iOS on every refreshWidgets)
    public func writeSnapshot(_ snapshot: WidgetSnapshot, uid: String) {
        guard !uid.isEmpty else { return }
        let data: [String: Any] = [
            "steps": snapshot.steps,
            "stepsGoal": snapshot.stepsGoal,
            "activeEnergy": snapshot.activeEnergy,
            "energyGoal": snapshot.energyGoal,
            "heartRate": snapshot.heartRate,
            "sleepHours": snapshot.sleepHours,
            "sleepGoal": snapshot.sleepGoal,
            "hydrationMl": snapshot.hydrationMl,
            "hydrationGoalMl": snapshot.hydrationGoalMl,
            "pomodoroCompleted": snapshot.pomodoroCompleted,
            "pomodoroTarget": snapshot.pomodoroTarget,
            "pomodoroPhase": snapshot.pomodoroPhase,
            "nutritionSafetyScore": snapshot.nutritionSafetyScore,
            "mealsLogged": snapshot.mealsLogged,
            "caffeineIsClean": snapshot.caffeineIsClean,
            "caffeineDrinksToday": snapshot.caffeineDrinksToday,
            "caffeineDrinksClean": snapshot.caffeineDrinksClean,
            "shutdownActive": snapshot.shutdownActive,
            "shutdownSecondsRemaining": snapshot.shutdownSecondsRemaining,
            "weightKg": snapshot.weightKg,
            "weightBodyFat": snapshot.weightBodyFat,
            "dailyFlowScore": snapshot.dailyFlowScore,
            "dailyFlowTotal": snapshot.dailyFlowTotal,
            "updatedAt": Timestamp(date: snapshot.updatedAt)
        ]
        db.collection("users")
            .document(uid)
            .collection("health")
            .document("snapshot")
            .setData(data)
    }

    /// Listen for real-time snapshot updates (used by macOS)
    public func startListening(uid: String, onChange: @escaping @Sendable (WidgetSnapshot) -> Void) {
        guard !uid.isEmpty else { return }
        listener = db.collection("users")
            .document(uid)
            .collection("health")
            .document("snapshot")
            .addSnapshotListener { snapshot, _ in
                guard let data = snapshot?.data() else { return }
                Task { @MainActor in
                    if let snap = Self.decode(data) { onChange(snap) }
                }
            }
    }

    public func stopListening() {
        listener?.remove()
        listener = nil
    }

    private static func decode(_ d: [String: Any]) -> WidgetSnapshot? {
        WidgetSnapshot(
            steps: d["steps"] as? Double ?? 0,
            stepsGoal: d["stepsGoal"] as? Double ?? 10000,
            activeEnergy: d["activeEnergy"] as? Double ?? 0,
            energyGoal: d["energyGoal"] as? Double ?? 500,
            heartRate: d["heartRate"] as? Double ?? 0,
            sleepHours: d["sleepHours"] as? Double ?? 0,
            sleepGoal: d["sleepGoal"] as? Double ?? 8,
            hydrationMl: d["hydrationMl"] as? Int ?? 0,
            hydrationGoalMl: d["hydrationGoalMl"] as? Int ?? 2500,
            pomodoroCompleted: d["pomodoroCompleted"] as? Int ?? 0,
            pomodoroTarget: d["pomodoroTarget"] as? Int ?? 8,
            pomodoroPhase: d["pomodoroPhase"] as? String ?? "idle",
            nutritionSafetyScore: d["nutritionSafetyScore"] as? Int ?? 0,
            mealsLogged: d["mealsLogged"] as? Int ?? 0,
            caffeineIsClean: d["caffeineIsClean"] as? Bool ?? true,
            caffeineDrinksToday: d["caffeineDrinksToday"] as? Int ?? 0,
            caffeineDrinksClean: d["caffeineDrinksClean"] as? Int ?? 0,
            shutdownActive: d["shutdownActive"] as? Bool ?? false,
            shutdownSecondsRemaining: d["shutdownSecondsRemaining"] as? TimeInterval ?? 0,
            weightKg: d["weightKg"] as? Double ?? 0,
            weightBodyFat: d["weightBodyFat"] as? Double ?? 0,
            dailyFlowScore: d["dailyFlowScore"] as? Int ?? 0,
            dailyFlowTotal: d["dailyFlowTotal"] as? Int ?? 6,
            updatedAt: (d["updatedAt"] as? Timestamp)?.dateValue() ?? .now
        )
    }
}
