import SwiftUI
import SwiftData
import UserNotifications
import BackgroundTasks
import HealthDebugKit
import FirebaseCore
import FirebaseCrashlytics
import FirebaseAnalytics
import FirebaseMessaging
import GoogleSignIn

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
        FirebaseApp.configure()
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
        IBMPlexFontSetup.apply()
        NotificationManager.registerBackgroundTasks()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .font(Font.ibm(.body))
                .environmentObject(AuthManager.shared)
                .environmentObject(BiometricAuth.shared)
                .environmentObject(ProfileStore.shared)
                .onAppear {
                    Task {
                        await NotificationManager.shared.requestAuthorization()
                        NotificationManager.scheduleBackgroundHealthCheck()
                        NotificationManager.scheduleHydrationCheck()
                        NotificationManager.scheduleAITipsTask()
                        registerNotificationHandlers()
                    }
                }
                .onOpenURL { url in
                    // Handle Google Sign-In redirect
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
        .modelContainer(sharedModelContainer)
    }
}

struct RootView: View {
    @Environment(\.modelContext) private var context
    @ObservedObject private var auth = AuthManager.shared
    @ObservedObject private var biometric = BiometricAuth.shared
    @ObservedObject private var profileStore = ProfileStore.shared
    @State private var showSplash = true
    @State private var showSignUp = false
    @State private var healthKitSyncedThisSession = false

    private var needsOnboarding: Bool {
        !(profileStore.profile?.onboardingCompleted ?? false)
    }

    var body: some View {
        ZStack {
            if showSplash {
                SplashView()
                    .transition(.opacity)

            } else if showSignUp {
                SignUpOnboardingView(
                    onComplete: { withAnimation { showSignUp = false } },
                    onSignIn:   { withAnimation { showSignUp = false } }
                )
                .transition(.opacity)

            } else if !auth.isSignedIn {
                AuthView(onSignUp: { withAnimation { showSignUp = true } })
                    .transition(.opacity)

            } else if !biometric.isUnlocked {
                BiometricLockView()
                    .transition(.opacity)

            } else if needsOnboarding {
                OnboardingView { }
                    .transition(.opacity)

            } else {
                MainAppView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.6), value: showSplash)
        .animation(.easeInOut(duration: 0.4), value: auth.isSignedIn)
        .animation(.easeInOut(duration: 0.4), value: showSignUp)
        .animation(.easeInOut(duration: 0.3), value: biometric.isUnlocked)
        .onAppear {
            if auth.isSignedIn {
                profileStore.startListening(uid: auth.uid, modelContext: context)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                withAnimation { showSplash = false }
                if auth.isSignedIn { biometric.lock() }
            }
        }
        .onChange(of: auth.isSignedIn) { _, signedIn in
            if signedIn {
                profileStore.startListening(uid: auth.uid, modelContext: context)
                if !showSignUp { biometric.lock() }
            } else {
                profileStore.stopListening()
                biometric.isUnlocked = false
                healthKitSyncedThisSession = false
            }
        }
        .onChange(of: biometric.isUnlocked) { _, unlocked in
            guard unlocked, auth.isSignedIn, !needsOnboarding, !healthKitSyncedThisSession else { return }
            healthKitSyncedThisSession = true
            let uid = auth.uid
            Task { await FirestoreSyncService.shared.syncHealthKitSnapshot(uid: uid) }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            if auth.isSignedIn { biometric.lock() }
        }
    }
}

// MARK: - Main App View

struct MainAppView: View {
    @ObservedObject private var profileStore = ProfileStore.shared

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
            if let profile = profileStore.profile {
                ProfileSettingsView(profile: profile, sleepConfig: profileStore.sleepConfig)
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
