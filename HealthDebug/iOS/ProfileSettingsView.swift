import SwiftUI
import SwiftData
import PhotosUI
import HealthDebugKit

struct ProfileSettingsView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var auth: AuthManager
    @Bindable var profile: UserProfile
    var sleepConfig: SleepConfig?

    @State private var workStart: Date
    @State private var workEnd: Date
    @State private var sleepTime: Date
    @State private var shutdownHours: Int
    @State private var weightAlertTime: Date
    @State private var photoItem: PhotosPickerItem?
    @State private var isSaving = false
    @State private var showSignOutConfirm = false

    init(profile: UserProfile, sleepConfig: SleepConfig?) {
        self.profile = profile
        self.sleepConfig = sleepConfig
        let cal = Calendar.current
        let sc = sleepConfig ?? SleepConfig()
        _workStart = State(initialValue: cal.date(from: DateComponents(hour: profile.workStartHour, minute: profile.workStartMinute)) ?? Date())
        _workEnd = State(initialValue: cal.date(from: DateComponents(hour: profile.workEndHour, minute: profile.workEndMinute)) ?? Date())
        _sleepTime = State(initialValue: cal.date(from: DateComponents(hour: sc.targetSleepHour, minute: sc.targetSleepMinute)) ?? Date())
        _shutdownHours = State(initialValue: sc.shutdownWindowHours)
        _weightAlertTime = State(initialValue: cal.date(from: DateComponents(hour: profile.weightAlertHour, minute: profile.weightAlertMinute)) ?? Date())
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                avatarHeader
                personalInfoCard
                bodyCompositionCard
                targetsCard
                workWindowCard
                notificationsCard
                sleepCard
                computedCard
                accountCard
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
        .navigationTitle(LocalizedStringKey("Profile"))
        .navigationBarTitleDisplayMode(.large)
        .confirmationDialog("Sign Out", isPresented: $showSignOutConfirm, titleVisibility: .visible) {
            Button("Sign Out", role: .destructive) {
                auth.signOut()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isSaving = true
                    save()
                    isSaving = false
                } label: {
                    if isSaving {
                        ProgressView().controlSize(.small)
                    } else {
                        Text(LocalizedStringKey("Save"))
                            .fontWeight(.semibold)
                    }
                }
                .tint(AppTheme.primary)
            }
        }
        .onChange(of: photoItem) { _, new in
            guard let new else { return }
            Task {
                if let data = try? await new.loadTransferable(type: Data.self) {
                    profile.avatarData = data
                }
            }
        }
        .tint(AppTheme.primary)
    }

    // MARK: - Avatar Header

    private var avatarHeader: some View {
        VStack(spacing: 12) {
            PhotosPicker(selection: $photoItem, matching: .images) {
                ZStack(alignment: .bottomTrailing) {
                    Group {
                        if let data = profile.avatarData, let uiImg = UIImage(data: data) {
                            Image(uiImage: uiImg)
                                .resizable()
                                .scaledToFill()
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .foregroundStyle(AppTheme.primary.opacity(0.6))
                        }
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())

                    Image(systemName: "camera.circle.fill")
                        .font(.title3)
                        .foregroundStyle(AppTheme.primary)
                        .background(Color(.systemBackground), in: Circle())
                        .offset(x: 4, y: 4)
                }
            }
            .buttonStyle(.plain)

            if !profile.name.isEmpty {
                Text(profile.name)
                    .font(.title3.bold())
            }
            if !profile.email.isEmpty {
                Text(profile.email)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    // MARK: - Personal Info

    private var personalInfoCard: some View {
        settingsCard(title: LocalizedStringKey("Personal Info"), icon: "person.fill", color: AppTheme.primary) {
            VStack(spacing: 0) {
                settingsRow {
                    HStack {
                        Text(LocalizedStringKey("Name"))
                        Spacer()
                        TextField(LocalizedStringKey("Your name"), text: $profile.name)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(.secondary)
                    }
                }
                Divider().padding(.leading)
                settingsRow {
                    HStack {
                        Text(LocalizedStringKey("Email"))
                        Spacer()
                        TextField(LocalizedStringKey("your@email.com"), text: $profile.email)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(.secondary)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }
                }
                Divider().padding(.leading)
                settingsRow {
                    HStack {
                        Text(LocalizedStringKey("Bio"))
                        Spacer()
                        TextField(LocalizedStringKey("Short bio"), text: $profile.bio)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Body Composition

    private var bodyCompositionCard: some View {
        settingsCard(title: LocalizedStringKey("Body Composition"), icon: "figure.arms.open", color: .orange) {
            VStack(spacing: 0) {
                numericRow(LocalizedStringKey("Weight"), value: $profile.weightKg, unit: "kg")
                Divider().padding(.leading)
                numericRow(LocalizedStringKey("Height"), value: $profile.heightCm, unit: "cm")
                Divider().padding(.leading)
                numericRow(LocalizedStringKey("Muscle Mass"), value: $profile.muscleMassKg, unit: "kg")
                Divider().padding(.leading)
                intRow(LocalizedStringKey("Metabolic Age"), value: $profile.metabolicAge, unit: "years")
                Divider().padding(.leading)
                intRow(LocalizedStringKey("Visceral Fat"), value: $profile.visceralFat, unit: "level")
                Divider().padding(.leading)
                numericRow(LocalizedStringKey("Body Water"), value: $profile.bodyWaterPercent, unit: "%")
            }
        }
    }

    // MARK: - Targets

    private var targetsCard: some View {
        settingsCard(title: LocalizedStringKey("Targets"), icon: "target", color: AppTheme.secondary) {
            VStack(spacing: 0) {
                numericRow(LocalizedStringKey("Target Weight"), value: $profile.targetWeightKg, unit: "kg")
                Divider().padding(.leading)
                intRow(LocalizedStringKey("Target Visceral Fat"), value: $profile.targetVisceralFat, unit: "level")
                Divider().padding(.leading)
                numericRow(LocalizedStringKey("Target Body Water"), value: $profile.targetBodyWaterPercent, unit: "%")
                Divider().padding(.leading)
                intRow(LocalizedStringKey("Target Metabolic Age"), value: $profile.targetMetabolicAge, unit: "years")
            }
        }
    }

    // MARK: - Work Window

    private var workWindowCard: some View {
        settingsCard(title: LocalizedStringKey("Work Window"), icon: "briefcase.fill", color: .blue) {
            VStack(spacing: 0) {
                settingsRow {
                    DatePicker(String(localized: "Start"), selection: $workStart, displayedComponents: .hourAndMinute)
                }
                Divider().padding(.leading)
                settingsRow {
                    DatePicker(String(localized: "End"), selection: $workEnd, displayedComponents: .hourAndMinute)
                }
                Divider().padding(.leading)
                settingsRow {
                    Stepper(value: $profile.dailyWaterGoalMl, in: 1000...5000, step: 250) {
                        HStack(spacing: 4) {
                            Text(LocalizedStringKey("Daily Water Goal"))
                            Spacer()
                            Text(verbatim: "\(profile.dailyWaterGoalMl)")
                                .foregroundStyle(.secondary)
                            Text("ml")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Notifications

    private var notificationsCard: some View {
        settingsCard(title: LocalizedStringKey("Notifications"), icon: "bell.fill", color: .purple) {
            VStack(spacing: 0) {
                // Weight Alert
                settingsRow {
                    Toggle(isOn: $profile.weightAlertEnabled) {
                        Label(String(localized: "Daily Weight Check-In"), systemImage: "scalemass.fill")
                    }
                }
                if profile.weightAlertEnabled {
                    Divider().padding(.leading)
                    settingsRow {
                        DatePicker(String(localized: "Wake Time"), selection: $weightAlertTime, displayedComponents: .hourAndMinute)
                    }
                    Divider().padding(.leading)
                    settingsRow {
                        Stepper(value: $profile.weightAlertDelayMinutes, in: 1...30) {
                            HStack(spacing: 4) {
                                Text(LocalizedStringKey("Remind after"))
                                Spacer()
                                Text(verbatim: "\(profile.weightAlertDelayMinutes)")
                                    .foregroundStyle(.secondary)
                                Text(LocalizedStringKey("min"))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                Divider().padding(.leading)
                // Hygiene
                settingsRow {
                    Toggle(isOn: $profile.hygieneAlertEnabled) {
                        Label(String(localized: "Post-Meal Hygiene"), systemImage: "hand.raised.fill")
                    }
                }
                if profile.hygieneAlertEnabled {
                    Divider().padding(.leading)
                    settingsRow {
                        Stepper(value: $profile.hygieneAlertDelayMinutes, in: 1...30) {
                            HStack(spacing: 4) {
                                Text(LocalizedStringKey("Remind after"))
                                Spacer()
                                Text(verbatim: "\(profile.hygieneAlertDelayMinutes)")
                                    .foregroundStyle(.secondary)
                                Text(LocalizedStringKey("min"))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                Divider().padding(.leading)
                // Pomodoro
                settingsRow {
                    Toggle(isOn: $profile.pomodoroStartAlertEnabled) {
                        Label(String(localized: "Work Start Alert"), systemImage: "play.circle.fill")
                    }
                }
                if profile.pomodoroStartAlertEnabled {
                    Divider().padding(.leading)
                    settingsRow {
                        Stepper(value: $profile.pomodoroStartLeadMinutes, in: 5...60, step: 5) {
                            HStack(spacing: 4) {
                                Text(LocalizedStringKey("Lead time"))
                                Spacer()
                                Text(verbatim: "\(profile.pomodoroStartLeadMinutes)")
                                    .foregroundStyle(.secondary)
                                Text(LocalizedStringKey("min before"))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                Divider().padding(.leading)
                settingsRow {
                    Toggle(isOn: $profile.pomodoroEndAlertEnabled) {
                        Label(String(localized: "Work End Alert"), systemImage: "stop.circle.fill")
                    }
                }
                if profile.pomodoroEndAlertEnabled {
                    Divider().padding(.leading)
                    settingsRow {
                        Stepper(value: $profile.pomodoroEndLeadMinutes, in: 5...60, step: 5) {
                            HStack(spacing: 4) {
                                Text(LocalizedStringKey("Lead time"))
                                Spacer()
                                Text(verbatim: "\(profile.pomodoroEndLeadMinutes)")
                                    .foregroundStyle(.secondary)
                                Text(LocalizedStringKey("min before"))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                Divider().padding(.leading)
                // Heart Rate
                settingsRow {
                    Stepper(value: $profile.heartRateHighThreshold, in: 80...200, step: 5) {
                        HStack(spacing: 4) {
                            Text(LocalizedStringKey("High HR"))
                            Spacer()
                            Text(verbatim: "\(profile.heartRateHighThreshold)")
                                .foregroundStyle(.secondary)
                            Text(LocalizedStringKey("bpm"))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Divider().padding(.leading)
                settingsRow {
                    Stepper(value: $profile.heartRateLowThreshold, in: 30...70, step: 5) {
                        HStack(spacing: 4) {
                            Text(LocalizedStringKey("Low HR"))
                            Spacer()
                            Text(verbatim: "\(profile.heartRateLowThreshold)")
                                .foregroundStyle(.secondary)
                            Text(LocalizedStringKey("bpm"))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Divider().padding(.leading)
                // Meal Reminder
                settingsRow {
                    Toggle(isOn: $profile.mealReminderEnabled) {
                        Label(String(localized: "Meal Logging Reminder"), systemImage: "fork.knife")
                    }
                }
                Divider().padding(.leading)
                // Coffee
                settingsRow {
                    Toggle(isOn: $profile.coffeeAlertEnabled) {
                        Label(String(localized: "Coffee Time Alert"), systemImage: "cup.and.heat.waves.fill")
                    }
                }
                if profile.coffeeAlertEnabled {
                    Divider().padding(.leading)
                    settingsRow {
                        DatePicker(
                            String(localized: "Coffee time"),
                            selection: Binding(
                                get: { Calendar.current.date(from: DateComponents(hour: profile.coffeeAlertHour, minute: profile.coffeeAlertMinute)) ?? Date() },
                                set: { d in
                                    let c = Calendar.current.dateComponents([.hour, .minute], from: d)
                                    profile.coffeeAlertHour = c.hour ?? 10
                                    profile.coffeeAlertMinute = c.minute ?? 0
                                }
                            ),
                            displayedComponents: .hourAndMinute
                        )
                    }
                }
                Divider().padding(.leading)
                // Hydration
                settingsRow {
                    Toggle(isOn: $profile.hydrationAlertEnabled) {
                        Label(String(localized: "Hydration Alert"), systemImage: "drop.fill")
                    }
                }
                if profile.hydrationAlertEnabled {
                    Divider().padding(.leading)
                    settingsRow {
                        Stepper(value: $profile.hydrationAlertGapMinutes, in: 30...180, step: 15) {
                            HStack(spacing: 4) {
                                Text(LocalizedStringKey("Alert after"))
                                Spacer()
                                Text(verbatim: "\(profile.hydrationAlertGapMinutes)")
                                    .foregroundStyle(.secondary)
                                Text(LocalizedStringKey("min without water"))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                Divider().padding(.leading)
                // Movement
                settingsRow {
                    Toggle(isOn: $profile.movementAlertEnabled) {
                        Label(String(localized: "Movement Alert"), systemImage: "figure.walk")
                    }
                }
                if profile.movementAlertEnabled {
                    Divider().padding(.leading)
                    settingsRow {
                        Stepper(value: $profile.movementAlertIntervalMinutes, in: 30...120, step: 15) {
                            HStack(spacing: 4) {
                                Text(LocalizedStringKey("Every"))
                                Spacer()
                                Text(verbatim: "\(profile.movementAlertIntervalMinutes)")
                                    .foregroundStyle(.secondary)
                                Text(LocalizedStringKey("min"))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                Divider().padding(.leading)
                // GERD
                settingsRow {
                    Stepper(value: $profile.gerdShutdownLeadMinutes, in: 5...60, step: 5) {
                        HStack(spacing: 4) {
                            Text(LocalizedStringKey("GERD warning"))
                            Spacer()
                            Text(verbatim: "\(profile.gerdShutdownLeadMinutes)")
                                .foregroundStyle(.secondary)
                            Text(LocalizedStringKey("min before"))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Sleep

    private var sleepCard: some View {
        settingsCard(title: LocalizedStringKey("Sleep"), icon: "moon.fill", color: AppTheme.secondary) {
            VStack(spacing: 0) {
                settingsRow {
                    DatePicker(String(localized: "Bedtime"), selection: $sleepTime, displayedComponents: .hourAndMinute)
                }
                Divider().padding(.leading)
                settingsRow {
                    Stepper(value: $shutdownHours, in: 1...6) {
                        HStack(spacing: 4) {
                            Text(LocalizedStringKey("Shutdown Window"))
                            Spacer()
                            Text(verbatim: "\(shutdownHours)")
                                .foregroundStyle(.secondary)
                            Text(LocalizedStringKey("hours"))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Computed

    private var computedCard: some View {
        settingsCard(title: LocalizedStringKey("Computed"), icon: "function", color: .gray) {
            VStack(spacing: 0) {
                settingsRow {
                    HStack {
                        Text(LocalizedStringKey("BMI"))
                        Spacer()
                        Text(String(format: "%.1f", profile.bmi))
                            .foregroundStyle(.secondary)
                    }
                }
                Divider().padding(.leading)
                settingsRow {
                    HStack {
                        Text(LocalizedStringKey("Work Hours"))
                        Spacer()
                        Text(String(format: "%.1f h", profile.workWindowHours))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Account

    private var accountCard: some View {
        settingsCard(title: LocalizedStringKey("Account"), icon: "person.badge.key.fill", color: .red) {
            VStack(spacing: 0) {
                if let email = auth.user?.email {
                    settingsRow {
                        HStack {
                            Text(email)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                    }
                    Divider().padding(.leading)
                }
                settingsRow {
                    Button {
                        showSignOutConfirm = true
                    } label: {
                        HStack {
                            Spacer()
                            Text(LocalizedStringKey("Sign Out"))
                                .fontWeight(.semibold)
                                .foregroundStyle(.red)
                            Spacer()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func settingsCard<Content: View>(title: LocalizedStringKey, icon: String, color: Color, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(color)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            content()
        }
        .glassEffect(.regular.tint(color.opacity(0.06)), in: RoundedRectangle(cornerRadius: 20))
    }

    private func settingsRow<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
    }

    private func numericRow(_ label: LocalizedStringKey, value: Binding<Double>, unit: String) -> some View {
        settingsRow {
            HStack {
                Text(label)
                Spacer()
                TextField(label, value: value, format: .number.precision(.fractionLength(1)))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 70)
                Text(unit)
                    .foregroundStyle(.secondary)
                    .frame(width: 44, alignment: .leading)
            }
        }
    }

    private func intRow(_ label: LocalizedStringKey, value: Binding<Int>, unit: String) -> some View {
        settingsRow {
            HStack {
                Text(label)
                Spacer()
                TextField(label, value: value, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 60)
                Text(unit)
                    .foregroundStyle(.secondary)
                    .frame(width: 44, alignment: .leading)
            }
        }
    }

    // MARK: - Save

    private func save() {
        let cal = Calendar.current
        let ws = cal.dateComponents([.hour, .minute], from: workStart)
        profile.workStartHour = ws.hour ?? 9
        profile.workStartMinute = ws.minute ?? 0
        let we = cal.dateComponents([.hour, .minute], from: workEnd)
        profile.workEndHour = we.hour ?? 19
        profile.workEndMinute = we.minute ?? 0
        let wa = cal.dateComponents([.hour, .minute], from: weightAlertTime)
        profile.weightAlertHour = wa.hour ?? 7
        profile.weightAlertMinute = wa.minute ?? 0
        profile.lastUpdated = .now
        let sc = cal.dateComponents([.hour, .minute], from: sleepTime)
        if let existingSleep = try? context.fetch(SleepConfig.currentDescriptor()).first {
            existingSleep.targetSleepHour = sc.hour ?? 23
            existingSleep.targetSleepMinute = sc.minute ?? 0
            existingSleep.shutdownWindowHours = shutdownHours
            existingSleep.lastUpdated = .now
        }
        try? context.save()
        let savedSleep = (try? context.fetch(SleepConfig.currentDescriptor()).first)
        // Mirror to Firestore for cross-platform sync
        let uid = AuthManager.shared.uid
        if !uid.isEmpty, let sleep = savedSleep {
            FirestoreSyncService.shared.syncProfile(profile, sleepConfig: sleep, uid: uid)
        }
        Task {
            await WeightAlertScheduler.shared.reschedule(profile: profile)
            await PomodoroAlertScheduler.shared.reschedule(profile: profile)
            await CoffeeTimeScheduler.shared.reschedule(profile: profile)
            await MovementAlertScheduler.shared.reschedule(profile: profile)
            if let sleep = savedSleep {
                await SleepOverrunScheduler.shared.reschedule(sleepConfig: sleep)
                await GERDShutdownAlertScheduler.shared.reschedule(
                    sleepConfig: sleep,
                    leadMinutes: profile.gerdShutdownLeadMinutes
                )
            }
        }
    }
}
