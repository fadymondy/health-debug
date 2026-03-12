import SwiftUI
import SwiftData
import HealthDebugKit

@main
struct HealthDebugWatchApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            WaterLog.self,
            MealLog.self,
            StandSession.self,
            CaffeineLog.self,
            SleepConfig.self,
            UserProfile.self,
        ])
        #if targetEnvironment(simulator)
        let cloudKit: ModelConfiguration.CloudKitDatabase = .none
        #else
        let cloudKit: ModelConfiguration.CloudKitDatabase = .automatic
        #endif

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: cloudKit
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            WatchContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
