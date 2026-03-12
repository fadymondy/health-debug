import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

/// Collects the latest values from all managers and writes a `WidgetSnapshot` to the
/// shared App Group store, then triggers a WidgetKit timeline reload.
///
/// Call `WidgetRefresher.refresh(...)` any time a manager publishes new data.
@MainActor
public final class WidgetRefresher {

    public static func refresh(
        steps: Double,
        stepsGoal: Double,
        activeEnergy: Double,
        energyGoal: Double,
        heartRate: Double,
        sleepHours: Double,
        sleepGoal: Double,
        hydrationMl: Int,
        hydrationGoalMl: Int,
        pomodoroCompleted: Int,
        pomodoroTarget: Int,
        pomodoroPhase: String,
        nutritionSafetyScore: Int,
        mealsLogged: Int,
        caffeineIsClean: Bool,
        caffeineDrinksToday: Int,
        caffeineDrinksClean: Int,
        shutdownActive: Bool,
        shutdownSecondsRemaining: TimeInterval,
        weightKg: Double,
        weightBodyFat: Double,
        dailyFlowScore: Int
    ) {
        let snapshot = WidgetSnapshot(
            steps: steps,
            stepsGoal: stepsGoal,
            activeEnergy: activeEnergy,
            energyGoal: energyGoal,
            heartRate: heartRate,
            sleepHours: sleepHours,
            sleepGoal: sleepGoal,
            hydrationMl: hydrationMl,
            hydrationGoalMl: hydrationGoalMl,
            pomodoroCompleted: pomodoroCompleted,
            pomodoroTarget: pomodoroTarget,
            pomodoroPhase: pomodoroPhase,
            nutritionSafetyScore: nutritionSafetyScore,
            mealsLogged: mealsLogged,
            caffeineIsClean: caffeineIsClean,
            caffeineDrinksToday: caffeineDrinksToday,
            caffeineDrinksClean: caffeineDrinksClean,
            shutdownActive: shutdownActive,
            shutdownSecondsRemaining: shutdownSecondsRemaining,
            weightKg: weightKg,
            weightBodyFat: weightBodyFat,
            dailyFlowScore: dailyFlowScore,
            dailyFlowTotal: 6,
            updatedAt: .now
        )
        WidgetDataStore.shared.write(snapshot)
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
}
