import SwiftUI
import SwiftData
import UserNotifications
import BackgroundTasks
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

    init() {
        // Apply IBM Plex Sans as global font before any views are rendered
        IBMPlexFontSetup.apply()
        // Register BGTaskScheduler identifiers before app finishes launching
        NotificationManager.registerBackgroundTasks()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .font(Font.ibm(.body))
                .onAppear {
                    Task {
                        await NotificationManager.shared.requestAuthorization()
                        // Kick off initial background task schedules
                        NotificationManager.scheduleBackgroundHealthCheck()
                        NotificationManager.scheduleHydrationCheck()
                        NotificationManager.scheduleAITipsTask()
                        // Register background check handlers
                        registerNotificationHandlers()
                    }
                }
        }
        .modelContainer(sharedModelContainer)
    }
}

struct RootView: View {
    @Environment(\.modelContext) private var context
    @Query(UserProfile.currentDescriptor()) private var profiles: [UserProfile]
    @State private var showOnboarding = false
    @State private var showSplash = true

    private var needsOnboarding: Bool {
        profiles.isEmpty || !(profiles.first?.onboardingCompleted ?? false)
    }

    var body: some View {
        ZStack {
            if showSplash {
                SplashView()
                    .transition(.opacity)
            } else if needsOnboarding || showOnboarding {
                OnboardingView {
                    showOnboarding = false
                }
                .transition(.opacity)
            } else {
                MainAppView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.6), value: showSplash)
        .onAppear {
            showOnboarding = needsOnboarding
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                showSplash = false
            }
        }
    }
}

// MARK: - Main App View

struct MainAppView: View {
    @Query(UserProfile.currentDescriptor()) private var profiles: [UserProfile]
    @Query(SleepConfig.currentDescriptor()) private var sleepConfigs: [SleepConfig]

    @State private var selectedTab: String = "dashboard"
    @State private var deepLinkScreen: HealthScreen? = nil

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Dashboard", systemImage: "heart.text.clipboard", value: "dashboard") {
                ContentView(deepLinkScreen: $deepLinkScreen)
            }

            Tab("Search", systemImage: "magnifyingglass", value: "search", role: .search) {
                SearchView()
            }

            Tab("Profile", systemImage: "person.crop.circle", value: "profile") {
                profileTab
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .onOpenURL { url in
            guard url.scheme == "healthdebug", let host = url.host else { return }
            let screen: HealthScreen?
            switch host {
            case "steps":       screen = .steps
            case "energy":      screen = .energy
            case "heartRate":   screen = .heartRate
            case "sleep":       screen = .sleep
            case "hydration":   screen = .hydration
            case "standTimer":  screen = .standTimer
            case "nutrition":   screen = .nutrition
            case "caffeine":    screen = .caffeine
            case "shutdown":    screen = .shutdown
            case "weight":      screen = .weight
            case "dailyFlow":   screen = .dailyFlow
            default:            screen = nil
            }
            if let screen {
                selectedTab = "dashboard"
                deepLinkScreen = screen
            }
        }
    }

    @ViewBuilder
    private var profileTab: some View {
        NavigationStack {
            if let profile = profiles.first {
                ProfileSettingsView(profile: profile, sleepConfig: sleepConfigs.first)
            } else {
                ContentUnavailableView("No Profile", systemImage: "person.crop.circle.badge.exclamationmark")
            }
        }
    }
}

// MARK: - Search Placeholder (FEAT-SFY)

struct SearchPlaceholderView: View {
    @State private var query = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 52))
                    .foregroundStyle(AppTheme.primary)
                    .padding()
                    .glassEffect(.regular.tint(AppTheme.primary.opacity(0.15)), in: .circle)

                Text("Smart Search")
                    .font(.title2.bold())
                Text("Search across all your health data,\nscreens, and AI insights.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Spacer()
            }
            .padding()
            .navigationTitle("Search")
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always))
        }
    }
}

// MARK: - Splash View

struct SplashView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0
    @State private var titleOffset: CGFloat = 30
    @State private var titleOpacity: Double = 0
    @State private var shimmerOffset: CGFloat = -200
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            Circle()
                .fill(AppTheme.primary.opacity(0.06))
                .frame(width: 250, height: 250)
                .scaleEffect(pulseScale)
                .blur(radius: 40)

            VStack(spacing: 24) {
                Image("SplashLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 130, height: 130)
                    .overlay {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [.white.opacity(0.3), .clear, .white.opacity(0.15)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .offset(x: shimmerOffset)
                            .mask {
                                Image("SplashLogo")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            }
                    }
                    .shadow(color: AppTheme.primary.opacity(0.2), radius: 25, y: 12)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)

                VStack(spacing: 8) {
                    Text("Health Debug")
                        .font(.largeTitle.bold())
                        .foregroundStyle(AppTheme.gradient)

                    Text("Your body. Optimized.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .offset(y: titleOffset)
                .opacity(titleOpacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.6)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }

            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                titleOffset = 0
                titleOpacity = 1.0
            }

            withAnimation(.easeInOut(duration: 0.8).delay(0.5)) {
                shimmerOffset = 200
            }

            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseScale = 1.15
            }
        }
    }
}
