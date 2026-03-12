import Foundation
import SwiftData
import HealthDebugKit

/// Registers background notification check handlers with NotificationScheduler.
/// Called once at app launch from HealthDebugApp.
@MainActor
func registerNotificationHandlers() {
    let container = try? ModelContainerFactory.create()

    // Health check pass — meal reminder + hydration check
    NotificationScheduler.shared.registerHealthCheckHandler { [weak container] in
        guard let container else { return }
        Task { @MainActor in
            let ctx = ModelContext(container)
            let profiles = (try? ctx.fetch(UserProfile.currentDescriptor())) ?? []
            await MealReminderScheduler.shared.checkAndFire(context: ctx, profile: profiles.first)
        }
    }

    NotificationScheduler.shared.registerHydrationCheckHandler { [weak container] in
        guard let container else { return }
        Task { @MainActor in
            let ctx = ModelContext(container)
            let profiles = (try? ctx.fetch(UserProfile.currentDescriptor())) ?? []
            await HydrationAlertScheduler.shared.checkAndFire(context: ctx, profile: profiles.first)
        }
    }

    // AI tips generation pass
    NotificationScheduler.shared.registerAITipHandler { [weak container] in
        guard let ctx = container.map({ ModelContext($0) }) else { return }
        let profiles = (try? ctx.fetch(UserProfile.currentDescriptor())) ?? []
        let sleepConfigs = (try? ctx.fetch(SleepConfig.currentDescriptor())) ?? []
        let profile = profiles.first
        let sleep = sleepConfigs.first

        await AIHealthTipsScheduler.shared.generateAndDeliver(
            context: ctx,
            profile: profile,
            sleepConfig: sleep
        )
    }
}
