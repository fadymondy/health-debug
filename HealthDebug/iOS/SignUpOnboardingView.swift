import SwiftUI
import SwiftData
import HealthKit
import HealthDebugKit

/// Unified sign-up + onboarding flow.
/// Steps: 0 Account → 1 Health Permissions → 2 Baseline → 3 Work Window → 4 Sleep
struct SignUpOnboardingView: View {
    @Environment(\.modelContext) private var context
    @ObservedObject private var auth = AuthManager.shared
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var onComplete: () -> Void   // called after last step
    var onSignIn: () -> Void     // called when user taps "Sign in instead"

    // MARK: - State

    @State private var step = 0
    private let totalSteps = 5

    // Step 0 — Account
    @State private var name = ""
    @State private var bio = ""
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false

    // Step 1 — HealthKit
    @State private var healthStatus: HKAuthorizationStatus = .notDetermined
    @State private var requestingHealth = false

    // Steps 2-4 — Profile
    @State private var profile = UserProfile()
    @State private var sleepConfig = SleepConfig()
    @State private var workStart = Calendar.current.date(from: DateComponents(hour: 9))!
    @State private var workEnd   = Calendar.current.date(from: DateComponents(hour: 19))!
    @State private var sleepTime = Calendar.current.date(from: DateComponents(hour: 23))!

    // MARK: - Body

    var body: some View {
        ZStack {
            // Same gradient background as auth screen
            authBackground

            // ECG heartbeat — same as sign-in background
            HeartbeatBackground()
                .ignoresSafeArea()
                .opacity(0.35)  // subtle behind content

            VStack(spacing: 0) {
                // Progress bar
                ProgressView(value: Double(step + 1), total: Double(totalSteps))
                    .tint(AppTheme.primary)
                    .padding(.horizontal, 24)
                    .padding(.top, 56)
                    .padding(.bottom, 8)

                // Step label
                Text("Step \(step + 1) of \(totalSteps)")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 16)

                // Pages — ZStack instead of TabView to prevent swipe navigation
                ZStack {
                    accountStep.opacity(step == 0 ? 1 : 0)
                    healthStep.opacity(step == 1 ? 1 : 0)
                    baselineStep.opacity(step == 2 ? 1 : 0)
                    workStep.opacity(step == 3 ? 1 : 0)
                    sleepStep.opacity(step == 4 ? 1 : 0)
                }
                .animation(.easeInOut(duration: 0.3), value: step)

                // Navigation buttons
                GlassEffectContainer {
                    HStack(spacing: 12) {
                        if step > 0 {
                            Button("Back") { withAnimation { step -= 1 } }
                                .buttonStyle(.glass)
                                .buttonBorderShape(.roundedRectangle(radius: 10))
                        }
                        Spacer()
                        nextButton
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                }
            }
        }
    }

    // MARK: - Next Button

    @ViewBuilder
    private var nextButton: some View {
        switch step {
        case 0:
            Button {
                Task { await createAccount() }
            } label: {
                ZStack {
                    if auth.isLoading { ProgressView().frame(width: 80) }
                    else { Text("Continue") }
                }
            }
            .buttonStyle(.glassProminent)
            .buttonBorderShape(.roundedRectangle(radius: 10))
            .tint(AppTheme.primary)
            .disabled(name.isEmpty || email.isEmpty || password.count < 6 || auth.isLoading)
            .opacity(name.isEmpty || email.isEmpty || password.count < 6 ? 0.5 : 1)

        case 1:
            Button {
                if healthStatus == .notDetermined { requestHealthAccess() }
                else { withAnimation { step += 1 } }
            } label: {
                ZStack {
                    if requestingHealth { ProgressView().frame(width: 80) }
                    else { Text(healthStatus == .notDetermined ? "Allow Access" : "Continue") }
                }
            }
            .buttonStyle(.glassProminent)
            .buttonBorderShape(.roundedRectangle(radius: 10))
            .tint(AppTheme.primary)
            .disabled(requestingHealth)

        case 2, 3:
            Button("Next") { withAnimation { step += 1 } }
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.roundedRectangle(radius: 10))
                .tint(AppTheme.primary)

        default:
            Button("Get Started") { finishOnboarding() }
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.roundedRectangle(radius: 10))
                .tint(AppTheme.primary)
        }
    }

    // MARK: - Step 0: Account

    private var accountStep: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                stepHeader(
                    icon: "person.crop.circle.badge.plus",
                    title: "Create your account",
                    subtitle: "Set up your Health Debug profile"
                )

                GlassEffectContainer {
                    VStack(spacing: 14) {
                        glassField(label: "Full name", systemImage: "person") {
                            TextField("", text: $name,
                                      prompt: Text("Your name").foregroundStyle(.tertiary))
                                .textContentType(.name)
                                .autocorrectionDisabled(false)
                        }

                        glassField(label: "Bio", systemImage: "text.quote") {
                            TextField("", text: $bio,
                                      prompt: Text("Short bio (optional)").foregroundStyle(.tertiary))
                                .autocorrectionDisabled()
                        }

                        Divider().opacity(0.3)

                        glassField(label: "Email", systemImage: "envelope") {
                            TextField("", text: $email,
                                      prompt: Text("your@email.com").foregroundStyle(.tertiary))
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                        }

                        glassField(label: "Password", systemImage: "lock") {
                            HStack(spacing: 8) {
                                Group {
                                    if showPassword {
                                        TextField("", text: $password,
                                                  prompt: Text("Min 6 characters").foregroundStyle(.tertiary))
                                    } else {
                                        SecureField("", text: $password,
                                                    prompt: Text("Min 6 characters").foregroundStyle(.tertiary))
                                    }
                                }
                                .textContentType(.newPassword)
                                Button { showPassword.toggle() } label: {
                                    Image(systemName: showPassword ? "eye.slash" : "eye")
                                        .font(.system(size: 13))
                                        .foregroundStyle(.tertiary)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        if let error = auth.errorMessage {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.circle.fill").font(.system(size: 12))
                                Text(error).font(.system(size: 12))
                            }
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .glassEffectTransition(.materialize)
                        }

                        // OR Google
                        HStack(spacing: 12) {
                            Rectangle().fill(.separator).frame(height: 1)
                            Text("OR").font(.system(size: 11, weight: .medium)).foregroundStyle(.tertiary).kerning(0.8)
                            Rectangle().fill(.separator).frame(height: 1)
                        }

                        Button {
                            Task { await auth.signInWithGoogle() }
                        } label: {
                            HStack(spacing: 10) {
                                ZStack {
                                    Circle().fill(.white).frame(width: 24, height: 24)
                                    GoogleGLogo().frame(width: 15, height: 15)
                                }
                                Text("Continue with Google")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 38)
                        }
                        .buttonStyle(.glass)
                        .buttonBorderShape(.roundedRectangle(radius: 10))
                        .disabled(auth.isLoading)
                        .opacity(auth.isLoading ? 0.5 : 1)
                    }
                    .padding(20)
                    .glassEffect(
                        reduceTransparency ? .identity : .regular,
                        in: RoundedRectangle(cornerRadius: 20)
                    )
                }

                // Already have account
                HStack(spacing: 4) {
                    Text("Already have an account?").foregroundStyle(.secondary)
                    Button("Sign in") { withAnimation(.bouncy) { onSignIn() } }
                        .fontWeight(.semibold)
                }
                .font(.system(size: 13))
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Step 1: HealthKit Permissions

    private var healthStep: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                stepHeader(
                    icon: "heart.text.clipboard.fill",
                    title: "Health Access",
                    subtitle: "We need access to Apple Health to track and optimize your metabolic health."
                )

                VStack(spacing: 10) {
                    ForEach(healthItems, id: \.label) { item in
                        HStack(spacing: 14) {
                            Image(systemName: item.icon)
                                .font(.system(size: 18))
                                .foregroundStyle(AppTheme.gradient)
                                .frame(width: 28)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.label).font(.subheadline.weight(.medium))
                                Text(item.detail).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if healthStatus == .sharingAuthorized {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .glassEffect(.regular.tint(AppTheme.primary.opacity(0.06)),
                                     in: RoundedRectangle(cornerRadius: 14))
                    }
                }

                if healthStatus == .sharingDenied {
                    Text("Access denied. Go to Settings → Privacy → Health to grant access.")
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }

    private struct HealthItem { let icon: String; let label: String; let detail: String }
    private let healthItems: [HealthItem] = [
        .init(icon: "figure.walk",          label: "Steps & Activity",  detail: "Daily step count and active energy"),
        .init(icon: "heart.fill",            label: "Heart Rate",        detail: "Resting and workout heart rate"),
        .init(icon: "bed.double.fill",       label: "Sleep",             detail: "Sleep duration and quality"),
        .init(icon: "scalemass.fill",        label: "Body Metrics",      detail: "Weight, BMI, body composition"),
        .init(icon: "drop.fill",             label: "Hydration",         detail: "Water intake logging"),
        .init(icon: "figure.strengthtraining.traditional", label: "Workouts", detail: "Workout sessions"),
    ]

    // MARK: - Step 2: Baseline

    private var baselineStep: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                stepHeader(icon: "scalemass.fill", title: "Your Baseline",
                           subtitle: "Enter your current body metrics from your scale")

                VStack(spacing: 14) {
                    metricRow(label: "Weight",      value: $profile.weightKg,      unit: "kg")
                    metricRow(label: "Height",      value: $profile.heightCm,      unit: "cm")
                    metricRow(label: "Muscle Mass", value: $profile.muscleMassKg,  unit: "kg")
                    Divider().opacity(0.4)
                    intRow(label: "Metabolic Age",  value: $profile.metabolicAge,  unit: "yrs")
                    intRow(label: "Visceral Fat",   value: $profile.visceralFat,   unit: "lvl")
                    metricRow(label: "Body Water",  value: $profile.bodyWaterPercent, unit: "%")
                    Divider().opacity(0.4)
                    Text("Targets").font(.headline).foregroundStyle(AppTheme.accent)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    metricRow(label: "Target Weight",      value: $profile.targetWeightKg,        unit: "kg")
                    intRow(label: "Target Visceral Fat",   value: $profile.targetVisceralFat,     unit: "lvl")
                    metricRow(label: "Target Body Water",  value: $profile.targetBodyWaterPercent, unit: "%")
                    intRow(label: "Target Metabolic Age",  value: $profile.targetMetabolicAge,    unit: "yrs")
                }
                .padding(16)
                .glassEffect(.regular.tint(AppTheme.primary.opacity(0.08)),
                             in: RoundedRectangle(cornerRadius: 20))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Step 3: Work Window

    private var workStep: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                stepHeader(icon: "deskclock.fill", title: "Work Window",
                           subtitle: "We'll schedule stand reminders during your work hours")

                VStack(spacing: 14) {
                    DatePicker("Work Start", selection: $workStart, displayedComponents: .hourAndMinute)
                    DatePicker("Work End",   selection: $workEnd,   displayedComponents: .hourAndMinute)
                    Divider().opacity(0.4)
                    HStack {
                        Text("Daily Water Goal")
                        Spacer()
                        Stepper("\(profile.dailyWaterGoalMl) ml",
                                value: $profile.dailyWaterGoalMl, in: 1000...5000, step: 250)
                            .fixedSize()
                    }
                }
                .padding(16)
                .glassEffect(.regular.tint(AppTheme.secondary.opacity(0.08)),
                             in: RoundedRectangle(cornerRadius: 20))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Step 4: Sleep

    private var sleepStep: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                stepHeader(icon: "moon.zzz.fill", title: "Sleep Schedule",
                           subtitle: "We'll trigger the GERD shutdown timer before your bedtime")

                VStack(spacing: 14) {
                    DatePicker("Target Bedtime", selection: $sleepTime,
                               displayedComponents: .hourAndMinute)
                    HStack {
                        Text("Shutdown Window")
                        Spacer()
                        Stepper("\(sleepConfig.shutdownWindowHours)h before bed",
                                value: $sleepConfig.shutdownWindowHours, in: 1...6)
                            .fixedSize()
                    }
                    Divider().opacity(0.4)
                    let shutdownHour = (Calendar.current.component(.hour, from: sleepTime)
                        - sleepConfig.shutdownWindowHours + 24) % 24
                    let minute = Calendar.current.component(.minute, from: sleepTime)
                    Label("No eating after \(String(format: "%d:%02d", shutdownHour, minute)) to prevent acid reflux.",
                          systemImage: "info.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .glassEffect(.regular.tint(AppTheme.secondary.opacity(0.08)),
                             in: RoundedRectangle(cornerRadius: 20))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Reusable Components

    private func stepHeader(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 44))
                .foregroundStyle(AppTheme.gradient)
                .shadow(color: AppTheme.primary.opacity(0.35), radius: 14)
            Text(title).font(.title2.bold())
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private func glassField<Content: View>(
        label: String, systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.system(size: 12, weight: .medium)).foregroundStyle(.secondary)
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 14)).foregroundStyle(.tertiary).frame(width: 18)
                content().font(.system(size: 15))
            }
            .padding(.horizontal, 14).padding(.vertical, 11)
            .glassEffect(
                reduceTransparency ? .identity : .regular.tint(Color.primary.opacity(0.03)),
                in: RoundedRectangle(cornerRadius: 11)
            )
        }
    }

    private func metricRow(label: String, value: Binding<Double>, unit: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField(label, value: value, format: .number.precision(.fractionLength(1)))
                .keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 80)
            Text(unit).foregroundStyle(.secondary).frame(width: 40, alignment: .leading)
        }
    }

    private func intRow(label: String, value: Binding<Int>, unit: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField(label, value: value, format: .number)
                .keyboardType(.numberPad).multilineTextAlignment(.trailing).frame(width: 60)
            Text(unit).foregroundStyle(.secondary).frame(width: 50, alignment: .leading)
        }
    }

    // MARK: - Actions

    private func createAccount() async {
        await auth.signUp(email: email, password: password, name: name, bio: bio)
        if auth.isSignedIn {
            withAnimation { step = 1 }
        }
    }

    private func requestHealthAccess() {
        requestingHealth = true
        let hk = HKHealthStore()
        guard HKHealthStore.isHealthDataAvailable() else {
            requestingHealth = false; withAnimation { step += 1 }; return
        }
        let readTypes: Set<HKObjectType> = [
            HKQuantityType(.stepCount), HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.heartRate), HKQuantityType(.bodyMass),
            HKQuantityType(.bodyFatPercentage), HKQuantityType(.dietaryWater),
            HKCategoryType(.sleepAnalysis), HKObjectType.workoutType()
        ]
        let writeTypes: Set<HKSampleType> = [
            HKQuantityType(.dietaryWater), HKObjectType.workoutType()
        ]
        hk.requestAuthorization(toShare: writeTypes, read: readTypes) { _, _ in
            Task { @MainActor in
                self.requestingHealth = false
                self.healthStatus = hk.authorizationStatus(for: HKQuantityType(.stepCount))
                withAnimation { self.step += 1 }
            }
        }
    }

    private func finishOnboarding() {
        let wsc = Calendar.current.dateComponents([.hour, .minute], from: workStart)
        profile.workStartHour   = wsc.hour ?? 9
        profile.workStartMinute = wsc.minute ?? 0
        let wec = Calendar.current.dateComponents([.hour, .minute], from: workEnd)
        profile.workEndHour     = wec.hour ?? 19
        profile.workEndMinute   = wec.minute ?? 0
        let sc = Calendar.current.dateComponents([.hour, .minute], from: sleepTime)
        sleepConfig.targetSleepHour   = sc.hour ?? 23
        sleepConfig.targetSleepMinute = sc.minute ?? 0
        sleepConfig.lastUpdated = .now
        profile.onboardingCompleted = true
        profile.lastUpdated = .now
        context.insert(profile)
        context.insert(sleepConfig)
        try? context.save()

        // Sync profile to Firestore for cross-platform access
        let uid = auth.uid
        Task {
            FirestoreSyncService.shared.syncProfile(profile, sleepConfig: sleepConfig, uid: uid)
            await FirestoreSyncService.shared.syncHealthKitSnapshot(uid: uid)
        }

        onComplete()
    }

    // MARK: - Background (same as AuthView)

    private var authBackground: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.04, green: 0.04, blue: 0.10),
                         Color(red: 0.06, green: 0.06, blue: 0.14)],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()
            RadialGradient(
                colors: [Color(red: 0.38, green: 0.20, blue: 0.90).opacity(0.35), .clear],
                center: .init(x: 0.15, y: 0.12), startRadius: 0, endRadius: 340
            ).ignoresSafeArea()
            RadialGradient(
                colors: [Color(red: 0.10, green: 0.65, blue: 0.72).opacity(0.22), .clear],
                center: .init(x: 0.88, y: 0.85), startRadius: 0, endRadius: 300
            ).ignoresSafeArea()
        }
    }
}
