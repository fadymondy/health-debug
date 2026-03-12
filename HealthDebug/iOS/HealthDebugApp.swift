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
                ContentView()
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

struct SplashView: View {
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0
    @State private var titleOffset: CGFloat = 30
    @State private var titleOpacity: Double = 0
    @State private var shimmerOffset: CGFloat = -200
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            // Animated gradient background
            AppTheme.gradient
                .ignoresSafeArea()

            // Subtle radial pulse behind logo
            Circle()
                .fill(.white.opacity(0.08))
                .frame(width: 250, height: 250)
                .scaleEffect(pulseScale)
                .blur(radius: 40)

            VStack(spacing: 24) {
                // Logo with glass effect and shimmer
                Image("SplashLogo")
                    .resizable()
                    .frame(width: 130, height: 130)
                    .clipShape(RoundedRectangle(cornerRadius: 30))
                    .overlay {
                        RoundedRectangle(cornerRadius: 30)
                            .fill(
                                LinearGradient(
                                    colors: [.white.opacity(0.4), .clear, .white.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .offset(x: shimmerOffset)
                            .mask(RoundedRectangle(cornerRadius: 30))
                    }
                    .shadow(color: .black.opacity(0.25), radius: 25, y: 12)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)

                VStack(spacing: 8) {
                    Text("Health Debug")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)

                    Text("Your body. Optimized.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .offset(y: titleOffset)
                .opacity(titleOpacity)
            }
        }
        .onAppear {
            // Logo bounces in
            withAnimation(.spring(response: 0.7, dampingFraction: 0.6)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }

            // Title slides up after logo
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                titleOffset = 0
                titleOpacity = 1.0
            }

            // Shimmer sweep across logo
            withAnimation(.easeInOut(duration: 0.8).delay(0.5)) {
                shimmerOffset = 200
            }

            // Subtle pulse loop
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseScale = 1.15
            }
        }
    }
}
