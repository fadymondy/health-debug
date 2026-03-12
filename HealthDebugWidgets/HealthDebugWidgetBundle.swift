import WidgetKit
import SwiftUI

@main
struct HealthDebugWidgetBundle: WidgetBundle {
    var body: some Widget {
        // Home screen widgets
        StepsWidget()
        EnergyWidget()
        HeartRateWidget()
        SleepWidget()
        HydrationWidget()
        StandTimerWidget()
        NutritionWidget()
        CaffeineWidget()
        ShutdownWidget()
        WeightWidget()
        DailyFlowWidget()

        // Lock screen widgets
        StepsLockWidget()
        HeartRateLockWidget()
        HydrationLockWidget()
        StandTimerLockWidget()
        SleepLockWidget()
        DailyFlowLockWidget()
    }
}
