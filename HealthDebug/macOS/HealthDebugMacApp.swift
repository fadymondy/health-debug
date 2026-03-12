import SwiftUI
import SwiftData
import HealthDebugKit

@main
struct HealthDebugMacApp: App {
    var sharedModelContainer: ModelContainer = {
        do {
            return try ModelContainerFactory.create()
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        MenuBarExtra("Health Debug", systemImage: "heart.text.clipboard") {
            MenuBarView()
                .modelContainer(sharedModelContainer)
        }
        .menuBarExtraStyle(.window)

        WindowGroup {
            MacContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
