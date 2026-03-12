import SwiftUI
import SwiftData
import HealthDebugKit

@main
struct HealthDebugApp: App {
    var sharedModelContainer: ModelContainer = {
        do {
            return try ModelContainerFactory.create()
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(sharedModelContainer)
    }
}

struct RootView: View {
    @Environment(\.modelContext) private var context
    @Query(UserProfile.currentDescriptor()) private var profiles: [UserProfile]
    @State private var showOnboarding = false

    private var needsOnboarding: Bool {
        profiles.isEmpty || !(profiles.first?.onboardingCompleted ?? false)
    }

    var body: some View {
        Group {
            if needsOnboarding || showOnboarding {
                OnboardingView {
                    showOnboarding = false
                }
            } else {
                ContentView()
            }
        }
        .onAppear {
            showOnboarding = needsOnboarding
        }
    }
}
