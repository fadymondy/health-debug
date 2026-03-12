import SwiftUI
import SwiftData
import HealthDebugKit

// MARK: - Navigation Destinations

enum HealthScreen: Hashable {
    case steps, energy, heartRate, sleep
    case hydration, standTimer, nutrition, caffeine, shutdown, weight
    case dailyFlow
}

// MARK: - Content View

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.layoutDirection) private var layoutDirection
    @StateObject private var health = HealthKitManager.shared
    @StateObject private var standTimer = StandTimerManager.shared
    @StateObject private var hydration = HydrationManager.shared
    @StateObject private var shutdownMgr = ShutdownManager.shared
    @StateObject private var caffeineMgr = CaffeineManager.shared
    @StateObject private var nutritionMgr = NutritionManager.shared
    @StateObject private var layout = DashboardLayout.shared
    @StateObject private var ai = AIService.shared
    @StateObject private var analytics = AnalyticsEngine.shared
    @Query(UserProfile.currentDescriptor()) private var profiles: [UserProfile]
    @Query(SleepConfig.currentDescriptor()) private var sleepConfigs: [SleepConfig]

    @Binding var deepLinkScreen: HealthScreen?
    @State private var showEditLayout = false
    @State private var navPath: [HealthScreen] = []
    @State private var showAPISettings = false

    init(deepLinkScreen: Binding<HealthScreen?> = .constant(nil)) {
        _deepLinkScreen = deepLinkScreen
    }

    var body: some View {
        NavigationStack(path: $navPath) {
            ScrollView {
                VStack(spacing: 16) {
                    if !health.isAuthorized {
                        authCard
                    } else {
                        welcomeHeader
                        healthScoreCard
                        feedSection
                        analyzeButton
                        if !analytics.lastAnalysis.isEmpty {
                            analysisSection
                        }
                        pinnedSection
                        allCardsSection
                    }
                }
                .padding(.vertical)
            }
            .refreshable {
                await health.refreshAll()
                refreshWidgets()
            }
            .navigationTitle(LocalizedStringKey("Dashboard"))
            .navigationDestination(for: HealthScreen.self) { screen in
                switch screen {
                case .steps: StepsDetailView()
                case .energy: EnergyDetailView()
                case .heartRate: HeartRateDetailView()
                case .sleep: SleepDetailView()
                case .hydration: HydrationDetailView()
                case .standTimer: StandTimerDetailView()
                case .nutrition: NutritionDetailView()
                case .caffeine: CaffeineDetailView()
                case .shutdown: ShutdownDetailView()
                case .weight: ZeppDetailView()
                case .dailyFlow: DailyFlowDetailView()
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NotificationBellButton()
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAPISettings = true
                    } label: {
                        Image(systemName: ai.selectedProvider == .apple ? "apple.intelligence" : "cloud.fill")
                            .font(.subheadline)
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button { showEditLayout = true } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "square.grid.2x2")
                            Text(LocalizedStringKey("Edit")).font(.subheadline)
                        }
                    }
                }
            }
            .sheet(isPresented: $showEditLayout) {
                DashboardEditSheet()
                    .presentationDetents([.large])
            }
            .sheet(isPresented: $showAPISettings) {
                APISettingsSheet()
            }
            .onAppear {
                hydration.refresh(context: context)
                if let profile = profiles.first { hydration.dailyGoal = profile.dailyWaterGoalMl }
                nutritionMgr.refresh(context: context)
                caffeineMgr.refresh(context: context)
                shutdownMgr.startCountdown(config: sleepConfigs.first)
                standTimer.refreshTodayCount(context: context)
                flushWidgetActions()
                refreshWidgets()
            }
            .onChange(of: deepLinkScreen) { _, screen in
                guard let screen else { return }
                navPath = [screen]
                deepLinkScreen = nil
            }
        }
    }

    // MARK: - Widget Action Flush

    private func flushWidgetActions() {
        let reader = WidgetActionReader.shared

        let hydrationMl = reader.consumeHydration()
        if hydrationMl > 0 {
            hydration.logWater(hydrationMl, source: "widget", context: context, profile: profiles.first)
        }

        if let pomodoroAction = reader.consumePomodoro() {
            switch pomodoroAction {
            case "start": standTimer.startCycle()
            case "break": standTimer.startBreak()
            default: break
            }
        }

        if reader.consumeCaffeineClean() {
            _ = caffeineMgr.logCaffeine(.espresso, context: context, profile: profiles.first)
        }
    }

    // MARK: - AI: Health Score

    private var profile: UserProfile? { profiles.first }

    private var healthScore: Int {
        var score = 0.0
        var components = 0.0
        let hydrationPct = profile.map {
            min(1.0, Double(hydration.todayTotal) / Double(max(1, $0.dailyWaterGoalMl)))
        } ?? min(1.0, Double(hydration.todayTotal) / 2500.0)
        score += hydrationPct * 20; components += 20
        score += (nutritionMgr.safetyScore / 100.0) * 20; components += 20
        score += (caffeineMgr.cleanTransitionPercent / 100.0) * 20; components += 20
        let standPct = min(1.0, Double(standTimer.todayCompleted) / Double(StandTimerManager.dailyTarget))
        score += standPct * 20; components += 20
        let sleepPct = min(1.0, health.sleepHours / 8.0)
        score += sleepPct * 20; components += 20
        guard components > 0 else { return 0 }
        return Int((score / components) * 100)
    }

    private var healthScoreColor: Color {
        switch healthScore {
        case 80...: return AppTheme.primary
        case 50..<80: return .orange
        default: return .red
        }
    }

    private var healthScoreLabel: String {
        switch healthScore {
        case 80...: return NSLocalizedString("Excellent", comment: "")
        case 60..<80: return NSLocalizedString("Good", comment: "")
        case 40..<60: return NSLocalizedString("Fair", comment: "")
        default: return NSLocalizedString("Needs Attention", comment: "")
        }
    }

    private var healthScoreCard: some View {
        Button {
            runAnalysis()
        } label: {
            VStack(spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(LocalizedStringKey("Health Score"))
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text(LocalizedStringKey("Your health score today"))
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: ai.selectedProvider == .apple ? "apple.intelligence" : "cloud.fill")
                            .font(.caption2)
                        Text(ai.selectedProvider.rawValue)
                            .font(.caption2.bold())
                    }
                    .foregroundStyle(ai.selectedProvider == .apple ? AppTheme.primary : AppTheme.accent)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .glassEffect(.regular.tint(AppTheme.primary.opacity(0.1)), in: Capsule())
                }

                HStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .stroke(healthScoreColor.opacity(0.15), lineWidth: 10)
                            .frame(width: 100, height: 100)
                        Circle()
                            .trim(from: 0, to: CGFloat(healthScore) / 100.0)
                            .stroke(healthScoreColor.gradient, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                            .frame(width: 100, height: 100)
                            .rotationEffect(.degrees(-90))
                            .animation(.spring(response: 0.6), value: healthScore)
                        VStack(spacing: 0) {
                            HStack(alignment: .lastTextBaseline, spacing: 2) {
                                Text(verbatim: "\(healthScore)")
                                    .font(.system(size: 30, weight: .bold, design: .rounded))
                                    .foregroundStyle(healthScoreColor)
                                Text(LocalizedStringKey("/100"))
                                    .font(.caption.bold())
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        scoreComponentRow(icon: "drop.fill", label: "Hydration", color: AppTheme.secondary,
                            value: profile.map { min(1.0, Double(hydration.todayTotal) / Double(max(1, $0.dailyWaterGoalMl))) } ?? 0)
                        scoreComponentRow(icon: "fork.knife", label: "Nutrition", color: AppTheme.primary,
                            value: nutritionMgr.safetyScore / 100.0)
                        scoreComponentRow(icon: "figure.stand", label: "Stands", color: AppTheme.accent,
                            value: min(1.0, Double(standTimer.todayCompleted) / Double(StandTimerManager.dailyTarget)))
                        scoreComponentRow(icon: "moon.zzz.fill", label: "Sleep", color: AppTheme.secondary,
                            value: min(1.0, health.sleepHours / 8.0))
                    }
                    Spacer()
                }

                HStack {
                    Text(verbatim: healthScoreLabel)
                        .font(.subheadline.bold())
                        .foregroundStyle(healthScoreColor)
                    Spacer()
                    if ai.isLoading {
                        ProgressView().controlSize(.small)
                        Text(LocalizedStringKey("Analyzing…"))
                            .font(.caption).foregroundStyle(.secondary)
                    } else {
                        Label(LocalizedStringKey("Tap to analyze"), systemImage: "sparkles")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(.regular.tint(healthScoreColor.opacity(0.1)), in: RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal)
        }
        .buttonStyle(.plain)
        .disabled(ai.isLoading)
    }

    private func scoreComponentRow(icon: String, label: String, color: Color, value: Double) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption2).foregroundStyle(color)
                .frame(width: 16)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2).fill(color.opacity(0.15)).frame(height: 4)
                    RoundedRectangle(cornerRadius: 2).fill(color)
                        .frame(width: geo.size.width * max(0, min(1, value)), height: 4)
                        .animation(.spring(response: 0.5), value: value)
                }
            }
            .frame(height: 4)
            Text(LocalizedStringKey(label))
                .font(.caption2).foregroundStyle(.secondary)
                .frame(width: 60, alignment: .leading)
        }
    }

    // MARK: - AI: Feed Section

    private var feedSection: some View {
        VStack(spacing: 12) {
            HStack {
                Label(LocalizedStringKey("Health Feed"), systemImage: "dot.radiowaves.left.and.right")
                    .font(.headline)
                    .foregroundStyle(AppTheme.primary)
                Spacer()
            }
            .padding(.horizontal)

            HealthFeedCard(
                icon: "drop.fill",
                title: NSLocalizedString("Hydration", comment: ""),
                color: AppTheme.secondary,
                value: profile.map { "\(hydration.todayTotal) ml / \($0.dailyWaterGoalMl) ml" }
                    ?? "\(hydration.todayTotal) ml / 2500 ml",
                statusLabel: profile.map { hydration.status(profile: $0).rawValue } ?? "–",
                statusColor: hydrationFeedColor,
                primaryActionLabel: NSLocalizedString("Log 250ml", comment: ""),
                primaryActionIcon: "drop.circle.fill",
                askAIQuery: "How is my hydration today? Give brief advice."
            ) {
                hydration.logWater(250, source: "feed", context: context, profile: profile)
            }

            HealthFeedCard(
                icon: "fork.knife",
                title: NSLocalizedString("Nutrition", comment: ""),
                color: nutritionFeedColor,
                value: "\(nutritionMgr.todaySafeCount) \(NSLocalizedString("safe", comment: "")) · \(nutritionMgr.todayUnsafeCount) \(NSLocalizedString("unsafe", comment: ""))",
                statusLabel: nutritionMgr.safetyStatus.rawValue,
                statusColor: nutritionFeedColor,
                primaryActionLabel: NSLocalizedString("Log Meal", comment: ""),
                primaryActionIcon: "fork.knife.circle.fill",
                askAIQuery: "Analyze my nutrition today and suggest improvements."
            ) {}

            HealthFeedCard(
                icon: "cup.and.saucer.fill",
                title: NSLocalizedString("Caffeine", comment: ""),
                color: caffeineFeedColor,
                value: "\(caffeineMgr.todayCleanCount) \(NSLocalizedString("clean", comment: "")) · \(caffeineMgr.todaySugarCount) \(NSLocalizedString("sugar", comment: ""))",
                statusLabel: caffeineMgr.transitionStatus.rawValue,
                statusColor: caffeineFeedColor,
                primaryActionLabel: NSLocalizedString("View Logs", comment: ""),
                primaryActionIcon: "list.bullet.circle.fill",
                askAIQuery: "Give me caffeine advice for today."
            ) {}

            HealthFeedCard(
                icon: "figure.walk",
                title: NSLocalizedString("Steps & Energy", comment: ""),
                color: AppTheme.primary,
                value: "\(formatted(health.stepCount)) \(NSLocalizedString("steps", comment: "")) · \(String(format: "%.0f", health.activeEnergy)) kcal",
                statusLabel: health.stepCount >= 10000 ? NSLocalizedString("Goal Met", comment: "") : NSLocalizedString("In Progress", comment: ""),
                statusColor: health.stepCount >= 10000 ? AppTheme.primary : .orange,
                primaryActionLabel: NSLocalizedString("View Detail", comment: ""),
                primaryActionIcon: "chart.bar.fill",
                askAIQuery: "How are my activity levels today? Any recommendations?"
            ) {}

            HealthFeedCard(
                icon: "moon.zzz.fill",
                title: NSLocalizedString("Sleep", comment: ""),
                color: sleepFeedColor,
                value: String(format: "%.1f hrs", health.sleepHours),
                statusLabel: sleepFeedLabel,
                statusColor: sleepFeedColor,
                primaryActionLabel: NSLocalizedString("View Detail", comment: ""),
                primaryActionIcon: "moon.circle.fill",
                askAIQuery: "Analyze my sleep quality and give advice."
            ) {}
        }
    }

    // MARK: - AI: Analyze Button & Analysis

    private var analyzeButton: some View {
        GlassEffectContainer {
            Button {
                runAnalysis()
            } label: {
                HStack {
                    if ai.isLoading {
                        ProgressView().controlSize(.small)
                        Text(ai.selectedProvider == .apple ? LocalizedStringKey("Analyzing on-device…") : LocalizedStringKey("Analyzing 72h of data…"))
                    } else {
                        Label(LocalizedStringKey("Analyze My Health"), systemImage: "brain.head.profile.fill")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .tint(AppTheme.primary)
            .controlSize(.large)
            .disabled(ai.isLoading)
        }
        .padding(.horizontal)
    }

    private var analysisSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(LocalizedStringKey("Full Analysis"), systemImage: "brain.head.profile.fill")
                    .font(.headline)
                    .foregroundStyle(AppTheme.primary)
                Spacer()
                Text(ai.selectedProvider.rawValue)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Divider()
            MarkdownView(content: analytics.lastAnalysis)
                .textSelection(.enabled)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(AppTheme.primary.opacity(0.1)), in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
    }

    // MARK: - AI: Feed Colors

    private var hydrationFeedColor: Color {
        guard let profile else { return AppTheme.secondary }
        switch hydration.status(profile: profile) {
        case .onTrack, .goalReached: return AppTheme.primary
        case .slightlyBehind: return .orange
        case .dehydrated: return .red
        }
    }

    private var nutritionFeedColor: Color {
        switch nutritionMgr.safetyStatus {
        case .allSafe, .noMeals: return AppTheme.primary
        case .warning: return .orange
        case .critical: return .red
        }
    }

    private var caffeineFeedColor: Color {
        switch caffeineMgr.transitionStatus {
        case .clean, .noIntake: return AppTheme.primary
        case .transitioning: return .orange
        case .redBullDependent: return .red
        }
    }

    private var sleepFeedLabel: String {
        switch health.sleepHours {
        case 7...: return NSLocalizedString("Good", comment: "")
        case 5..<7: return NSLocalizedString("Low", comment: "")
        default: return NSLocalizedString("Critical", comment: "")
        }
    }

    private var sleepFeedColor: Color {
        switch health.sleepHours {
        case 7...: return AppTheme.primary
        case 5..<7: return .orange
        default: return .red
        }
    }

    // MARK: - AI: Run Analysis

    private func runAnalysis() {
        let healthContext = analytics.buildContext(context: context, profile: profile, sleepConfig: sleepConfigs.first)
        let prompt = analytics.buildPrompt(healthContext: healthContext)
        Task {
            do {
                analytics.isAnalyzing = true
                let result = try await ai.analyze(prompt: prompt)
                analytics.lastAnalysis = result
                analytics.isAnalyzing = false
            } catch {
                analytics.lastAnalysis = "Error: \(error.localizedDescription)"
                analytics.isAnalyzing = false
            }
        }
    }

    // MARK: - Widget Refresh

    private func refreshWidgets() {
        let flowScore = [
            hydration.todayTotal >= 500,
            nutritionMgr.todayMeals.count >= 1,
            standTimer.todayCompleted >= 2,
            !caffeineMgr.fattyLiverAlert,
            shutdownMgr.state != .violated,
            health.sleepHours >= 6
        ].filter { $0 }.count

        WidgetRefresher.refresh(
            steps: health.stepCount,
            stepsGoal: 10000,
            activeEnergy: health.activeEnergy,
            energyGoal: 500,
            heartRate: health.heartRate,
            sleepHours: health.sleepHours,
            sleepGoal: 8,
            hydrationMl: hydration.todayTotal,
            hydrationGoalMl: hydration.dailyGoal,
            pomodoroCompleted: standTimer.todayCompleted,
            pomodoroTarget: PomodoroManager.dailyTarget,
            pomodoroPhase: standTimer.phase.rawValue,
            nutritionSafetyScore: Int(nutritionMgr.safetyScore),
            mealsLogged: nutritionMgr.todayMeals.count,
            caffeineIsClean: !caffeineMgr.fattyLiverAlert,
            caffeineDrinksToday: caffeineMgr.todayTotal,
            caffeineDrinksClean: caffeineMgr.todayCleanCount,
            shutdownActive: shutdownMgr.state == .active,
            shutdownSecondsRemaining: shutdownMgr.secondsUntilSleep,
            weightKg: health.zeppMetrics.weight,
            weightBodyFat: health.zeppMetrics.bodyFatPercent,
            dailyFlowScore: flowScore
        )
        // Sync latest snapshot to Firestore for macOS real-time updates
        let uid = AuthManager.shared.uid
        if !uid.isEmpty {
            let snap = WidgetDataStore.shared.read()
            FirebaseSync.shared.writeSnapshot(snap, uid: uid)
        }
    }

    // MARK: - Welcome Header

    private var welcomeHeader: some View {
        HStack(spacing: 12) {
            if let data = profiles.first?.avatarData, let uiImg = UIImage(data: data) {
                Image(uiImage: uiImg)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(AppTheme.primary.opacity(0.7))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(greetingText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(profiles.first?.name.isEmpty == false ? profiles.first!.name : NSLocalizedString("Health Debug", comment: ""))
                    .font(.title3.bold())
            }
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 4)
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return NSLocalizedString("Good morning,", comment: "")
        case 12..<17: return NSLocalizedString("Good afternoon,", comment: "")
        case 17..<21: return NSLocalizedString("Good evening,", comment: "")
        default:      return NSLocalizedString("Good night,", comment: "")
        }
    }

    // MARK: - Auth Card

    private var authCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "lock.shield")
                .font(.system(size: 40)).foregroundStyle(AppTheme.secondary)
            Text(LocalizedStringKey("HealthKit Access Required")).font(.headline)
            Text(LocalizedStringKey("Tap to authorize reading your health data."))
                .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
            Button {
                Task { try? await health.requestAuthorization(); await health.refreshAll() }
            } label: {
                Text(LocalizedStringKey("Authorize HealthKit"))
            }
            .buttonStyle(.glassProminent).tint(AppTheme.primary)
        }
        .padding(24).frame(maxWidth: .infinity)
        .glassEffect(.regular.tint(AppTheme.secondary.opacity(0.3)), in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
    }

    // MARK: - Pinned Section (2x2 grid)

    private var pinnedSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(LocalizedStringKey("Pinned"))
                    .font(.title3.bold())
                Spacer()
                Button {
                    showEditLayout = true
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal).padding(.top, 4)

            LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 12) {
                ForEach(layout.pinnedOrdered, id: \.self) { cardID in
                    pinnedCardView(for: cardID)
                }
            }
            .padding(.horizontal)
        }
        .onLongPressGesture {
            showEditLayout = true
        }
    }

    @ViewBuilder
    private func pinnedCardView(for cardID: String) -> some View {
        switch cardID {
        case "steps":
            NavigationLink(value: HealthScreen.steps) {
                HealthMetricCard(
                    icon: "figure.walk", title: "Steps",
                    value: formatted(health.stepCount), unit: nil,
                    caption: String(format: NSLocalizedString("%.0f%% of daily goal", comment: ""), min(100, health.stepCount / 10000 * 100)),
                    color: AppTheme.primary,
                    progress: min(1.0, health.stepCount / 10000)
                )
            }
        case "energy":
            NavigationLink(value: HealthScreen.energy) {
                HealthMetricCard(
                    icon: "flame.fill", title: "Active Energy",
                    value: formatted(health.activeEnergy), unit: "kcal",
                    caption: String(format: NSLocalizedString("%.0f%% of 600 kcal", comment: ""), min(100, health.activeEnergy / 600 * 100)),
                    color: .orange,
                    progress: min(1.0, health.activeEnergy / 600)
                )
            }
        case "heartRate":
            NavigationLink(value: HealthScreen.heartRate) {
                HealthMetricCard(
                    icon: "heart.fill", title: "Heart Rate",
                    value: formatted(health.heartRate), unit: "BPM",
                    caption: heartZoneLabel,
                    color: .red,
                    progress: min(1.0, max(0, (health.heartRate - 40) / 120)),
                    statusColor: heartZoneColor
                )
            }
        case "sleep":
            NavigationLink(value: HealthScreen.sleep) {
                HealthMetricCard(
                    icon: "moon.zzz.fill", title: "Sleep",
                    value: String(format: "%.1f", health.sleepHours), unit: "hrs",
                    caption: sleepQualityLabel,
                    color: AppTheme.secondary,
                    progress: min(1.0, health.sleepHours / 8.0),
                    statusColor: sleepQualityColor
                )
            }
        case "hydration":
            NavigationLink(value: HealthScreen.hydration) {
                HealthMetricCard(
                    icon: "drop.fill", title: "Hydration",
                    value: "\(hydration.todayTotal)", unit: "ml",
                    caption: profiles.first.map { hydration.status(profile: $0).rawValue } ?? "",
                    color: AppTheme.secondary,
                    progress: min(1.0, Double(hydration.todayTotal) / Double(max(1, hydration.dailyGoal)))
                )
            }
        case "standTimer":
            NavigationLink(value: HealthScreen.standTimer) {
                HealthMetricCard(
                    icon: "timer", title: NSLocalizedString("Pomodoro", comment: ""),
                    value: "\(standTimer.todayCompleted)", unit: nil,
                    caption: "\(NSLocalizedString("of", comment: "")) \(StandTimerManager.dailyTarget) \(NSLocalizedString("sessions", comment: ""))",
                    color: AppTheme.accent,
                    progress: min(1.0, Double(standTimer.todayCompleted) / Double(StandTimerManager.dailyTarget)),
                    statusColor: standTimerStatusColor
                )
            }
        case "nutrition":
            NavigationLink(value: HealthScreen.nutrition) {
                HealthMetricCard(
                    icon: "fork.knife", title: "Nutrition",
                    value: String(format: "%.0f%%", nutritionMgr.safetyScore), unit: nil,
                    caption: "\(nutritionMgr.todaySafeCount) \(NSLocalizedString("safe", comment: "")) · \(nutritionMgr.todayUnsafeCount) \(NSLocalizedString("unsafe", comment: ""))",
                    color: nutritionStatusColor,
                    progress: nutritionMgr.safetyScore / 100,
                    statusColor: nutritionStatusColor
                )
            }
        case "caffeine":
            NavigationLink(value: HealthScreen.caffeine) {
                HealthMetricCard(
                    icon: "cup.and.saucer.fill", title: "Caffeine",
                    value: String(format: "%.0f%%", caffeineMgr.cleanTransitionPercent), unit: nil,
                    caption: caffeineMgr.transitionStatus.rawValue,
                    color: caffeineStatusColor,
                    progress: caffeineMgr.cleanTransitionPercent / 100,
                    statusColor: caffeineStatusColor
                )
            }
        case "shutdown":
            NavigationLink(value: HealthScreen.shutdown) {
                HealthMetricCard(
                    icon: "moon.fill", title: "Shutdown",
                    value: shutdownMgr.state == .active
                        ? ShutdownManager.formatCountdown(shutdownMgr.secondsUntilSleep)
                        : ShutdownManager.formatCountdown(shutdownMgr.secondsUntilShutdown),
                    unit: nil,
                    caption: shutdownMgr.state == .active
                        ? NSLocalizedString("Active", comment: "")
                        : NSLocalizedString("OK", comment: ""),
                    color: shutdownMgr.state == .active ? .orange : AppTheme.secondary,
                    progress: nil,
                    statusColor: shutdownMgr.state == .active ? .orange : AppTheme.primary
                )
            }
        case "weight":
            NavigationLink(value: HealthScreen.weight) {
                HealthMetricCard(
                    icon: "scalemass.fill", title: "Weight",
                    value: String(format: "%.1f", health.zeppMetrics.weight), unit: "kg",
                    caption: health.zeppMetrics.lastUpdated.map {
                        $0.formatted(.relative(presentation: .named))
                    } ?? NSLocalizedString("Never synced", comment: ""),
                    color: AppTheme.primary,
                    progress: nil
                )
            }
        case "dailyFlow":
            NavigationLink(value: HealthScreen.dailyFlow) {
                DailyFlowMetricCard()
            }
        default:
            EmptyView()
        }
    }

    // MARK: - All Cards Section

    private var allCardsSection: some View {
        VStack(spacing: 14) {
            HStack {
                Text(LocalizedStringKey("All Cards"))
                    .font(.title3.bold())
                Spacer()
            }
            .padding(.horizontal).padding(.top, 4)

            ForEach(layout.unpinnedCards, id: \.self) { cardID in
                fullCardView(for: cardID)
            }
        }
    }

    @ViewBuilder
    private func fullCardView(for cardID: String) -> some View {
        switch cardID {
        case "dailyFlow":
            NavigationLink(value: HealthScreen.dailyFlow) {
                DailyFlowFullCard()
            }
        case "steps":
            NavigationLink(value: HealthScreen.steps) {
                HealthCard(
                    icon: "figure.walk", title: "Steps",
                    color: AppTheme.primary,
                    primaryValue: formatted(health.stepCount),
                    detail: "/ 10,000 \(NSLocalizedString("steps", comment: ""))",
                    statusText: String(format: NSLocalizedString("%.0f%% of daily goal", comment: ""), min(100, health.stepCount / 10000 * 100)),
                    statusColor: AppTheme.primary,
                    progress: min(1.0, health.stepCount / 10000),
                    quickActions: []
                )
            }
        case "energy":
            NavigationLink(value: HealthScreen.energy) {
                HealthCard(
                    icon: "flame.fill", title: "Active Energy",
                    color: .orange,
                    primaryValue: "\(formatted(health.activeEnergy)) kcal",
                    detail: "/ 600 kcal",
                    statusText: String(format: NSLocalizedString("%.0f%% of goal", comment: ""), min(100, health.activeEnergy / 600 * 100)),
                    statusColor: .orange,
                    progress: min(1.0, health.activeEnergy / 600),
                    quickActions: []
                )
            }
        case "heartRate":
            NavigationLink(value: HealthScreen.heartRate) {
                HealthCard(
                    icon: "heart.fill", title: "Heart Rate",
                    color: .red,
                    primaryValue: "\(formatted(health.heartRate)) BPM",
                    detail: heartZoneLabel,
                    statusText: heartZoneLabel,
                    statusColor: heartZoneColor,
                    progress: min(1.0, max(0, (health.heartRate - 40) / 120)),
                    quickActions: []
                )
            }
        case "sleep":
            NavigationLink(value: HealthScreen.sleep) {
                HealthCard(
                    icon: "moon.zzz.fill", title: "Sleep",
                    color: AppTheme.secondary,
                    primaryValue: String(format: "%.1f hrs", health.sleepHours),
                    detail: NSLocalizedString("/ 8 hours target", comment: ""),
                    statusText: sleepQualityLabel,
                    statusColor: sleepQualityColor,
                    progress: min(1.0, health.sleepHours / 8.0),
                    quickActions: []
                )
            }
        case "hydration":
            NavigationLink(value: HealthScreen.hydration) {
                HealthCard(
                    icon: "drop.fill", title: "Hydration",
                    color: AppTheme.secondary,
                    primaryValue: "\(hydration.todayTotal) ml",
                    detail: "/ \(hydration.dailyGoal) ml",
                    statusText: profiles.first.map { hydration.status(profile: $0).rawValue } ?? "",
                    statusColor: hydrationStatusColor,
                    progress: min(1.0, Double(hydration.todayTotal) / Double(max(1, hydration.dailyGoal))),
                    quickActions: [
                        .init(label: NSLocalizedString("Log 250ml", comment: ""), icon: "plus.circle.fill", color: AppTheme.secondary) {
                            hydration.logWater(250, source: "quick", context: context, profile: profiles.first)
                        },
                        .init(label: NSLocalizedString("Log 500ml", comment: ""), icon: "drop.circle.fill", color: AppTheme.secondary) {
                            hydration.logWater(500, source: "quick", context: context, profile: profiles.first)
                        }
                    ]
                )
            }
        case "standTimer":
            NavigationLink(value: HealthScreen.standTimer) {
                HealthCard(
                    icon: "timer", title: NSLocalizedString("Pomodoro", comment: ""),
                    color: AppTheme.accent,
                    primaryValue: "\(standTimer.todayCompleted)",
                    detail: "/ \(StandTimerManager.dailyTarget) \(NSLocalizedString("sessions", comment: ""))",
                    statusText: standTimerStatusText,
                    statusColor: standTimerStatusColor,
                    progress: min(1.0, Double(standTimer.todayCompleted) / Double(StandTimerManager.dailyTarget)),
                    quickActions: standTimer.phase == .idle ? [
                        .init(label: NSLocalizedString("Start Focus", comment: ""), icon: "play.circle.fill", color: AppTheme.accent) {
                            standTimer.startCycle()
                        }
                    ] : standTimer.phase == .work ? [
                        .init(label: NSLocalizedString("Take Break", comment: ""), icon: "pause.circle.fill", color: AppTheme.secondary) {
                            standTimer.startBreak()
                        }
                    ] : []
                )
            }
        case "nutrition":
            NavigationLink(value: HealthScreen.nutrition) {
                HealthCard(
                    icon: "fork.knife", title: "Nutrition",
                    color: nutritionStatusColor,
                    primaryValue: String(format: "%.0f%%", nutritionMgr.safetyScore),
                    detail: "\(nutritionMgr.todaySafeCount) \(NSLocalizedString("safe", comment: "")) · \(nutritionMgr.todayUnsafeCount) \(NSLocalizedString("unsafe", comment: ""))",
                    statusText: nutritionMgr.safetyStatus.rawValue,
                    statusColor: nutritionStatusColor,
                    progress: nutritionMgr.safetyScore / 100,
                    quickActions: [
                        .init(label: NSLocalizedString("Log Meal", comment: ""), icon: "plus.circle.fill", color: nutritionStatusColor) { }
                    ],
                    badge: nutritionMgr.todayUnsafeCount > 0 ? "\(nutritionMgr.todayUnsafeCount) ⚠" : nil
                )
            }
        case "caffeine":
            NavigationLink(value: HealthScreen.caffeine) {
                HealthCard(
                    icon: "cup.and.saucer.fill", title: "Caffeine",
                    color: caffeineStatusColor,
                    primaryValue: String(format: "%.0f%%", caffeineMgr.cleanTransitionPercent),
                    detail: "\(caffeineMgr.todayCleanCount) \(NSLocalizedString("clean", comment: "")) · \(caffeineMgr.todaySugarCount) \(NSLocalizedString("sugar", comment: ""))",
                    statusText: caffeineMgr.transitionStatus.rawValue,
                    statusColor: caffeineStatusColor,
                    progress: caffeineMgr.cleanTransitionPercent / 100,
                    quickActions: []
                )
            }
        case "shutdown":
            NavigationLink(value: HealthScreen.shutdown) {
                let isActive = shutdownMgr.state == .active
                HealthCard(
                    icon: "moon.fill", title: "System Shutdown",
                    color: isActive ? .orange : AppTheme.secondary,
                    primaryValue: isActive
                        ? ShutdownManager.formatCountdown(shutdownMgr.secondsUntilSleep)
                        : ShutdownManager.formatCountdown(shutdownMgr.secondsUntilShutdown),
                    detail: isActive
                        ? NSLocalizedString("Active — No food until sleep", comment: "")
                        : NSLocalizedString("You can eat normally", comment: ""),
                    statusText: isActive ? NSLocalizedString("ACTIVE", comment: "") : NSLocalizedString("OK", comment: ""),
                    statusColor: isActive ? .orange : AppTheme.primary,
                    progress: nil,
                    quickActions: []
                )
            }
        case "weight":
            NavigationLink(value: HealthScreen.weight) {
                HealthCard(
                    icon: "scalemass.fill", title: "Weight",
                    color: AppTheme.primary,
                    primaryValue: String(format: "%.1f kg", health.zeppMetrics.weight),
                    detail: health.zeppMetrics.lastUpdated.map {
                        NSLocalizedString("Synced", comment: "") + " " + $0.formatted(.relative(presentation: .named))
                    } ?? NSLocalizedString("Never synced", comment: ""),
                    statusText: nil,
                    statusColor: AppTheme.primary,
                    progress: nil,
                    quickActions: []
                )
            }
        default:
            EmptyView()
        }
    }

    // MARK: - Computed Status Properties

    private var heartZoneLabel: String {
        switch health.heartRate {
        case 0..<50: return NSLocalizedString("Low", comment: "")
        case 50..<100: return NSLocalizedString("Normal", comment: "")
        case 100..<140: return NSLocalizedString("Elevated", comment: "")
        default: return NSLocalizedString("High", comment: "")
        }
    }
    private var heartZoneColor: Color {
        switch health.heartRate {
        case 0..<50: return .blue
        case 50..<100: return AppTheme.primary
        case 100..<140: return .orange
        default: return .red
        }
    }
    private var sleepQualityLabel: String {
        switch health.sleepHours {
        case 7...: return NSLocalizedString("Good", comment: "")
        case 5..<7: return NSLocalizedString("Low", comment: "")
        default: return NSLocalizedString("Critical", comment: "")
        }
    }
    private var sleepQualityColor: Color {
        switch health.sleepHours {
        case 7...: return AppTheme.primary
        case 5..<7: return .orange
        default: return .red
        }
    }
    private var hydrationStatusColor: Color {
        guard let profile = profiles.first else { return AppTheme.secondary }
        switch hydration.status(profile: profile) {
        case .onTrack, .goalReached: return AppTheme.primary
        case .slightlyBehind: return .orange
        case .dehydrated: return .red
        }
    }
    private var standTimerStatusText: String {
        switch standTimer.phase {
        case .idle:        return NSLocalizedString("Inactive", comment: "")
        case .work:        return String(format: NSLocalizedString("%d min left", comment: ""), Int(standTimer.secondsRemaining) / 60)
        case .standAlert:  return NSLocalizedString("Stand Up!", comment: "")
        case .shortBreak:  return String(format: "%d:%02d", Int(standTimer.secondsRemaining) / 60, Int(standTimer.secondsRemaining) % 60)
        case .longBreak:   return String(format: "%d:%02d", Int(standTimer.secondsRemaining) / 60, Int(standTimer.secondsRemaining) % 60)
        }
    }
    private var standTimerStatusColor: Color {
        switch standTimer.phase {
        case .idle:        return .secondary
        case .work:        return AppTheme.accent
        case .standAlert:  return .orange
        case .shortBreak:  return AppTheme.primary
        case .longBreak:   return AppTheme.secondary
        }
    }
    private var nutritionStatusColor: Color {
        switch nutritionMgr.safetyStatus {
        case .allSafe, .noMeals: return AppTheme.primary
        case .warning: return .orange
        case .critical: return .red
        }
    }
    private var caffeineStatusColor: Color {
        switch caffeineMgr.transitionStatus {
        case .clean, .noIntake: return AppTheme.primary
        case .transitioning: return .orange
        case .redBullDependent: return .red
        }
    }

    private func formatted(_ value: Double) -> String {
        value >= 1000 ? String(format: "%.1fk", value / 1000) : String(format: "%.0f", value)
    }
}

// MARK: - Dashboard Edit Sheet

struct DashboardEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var layout = DashboardLayout.shared

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(LocalizedStringKey("Long-press any pinned card or tap Edit to customize your dashboard. Pin up to 4 cards for the top grid."))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section(header: Text(LocalizedStringKey("Card Order & Pins"))) {
                    ForEach(layout.allCardOrder, id: \.self) { cardID in
                        HStack(spacing: 14) {
                            // Pin toggle
                            Button {
                                layout.togglePin(cardID)
                            } label: {
                                Image(systemName: layout.isPinned(cardID) ? "pin.fill" : "pin")
                                    .foregroundStyle(layout.isPinned(cardID) ? AppTheme.secondary : .secondary)
                                    .font(.subheadline)
                            }
                            .buttonStyle(.plain)

                            // Card icon + name
                            Label(LocalizedStringKey(cardDisplayName(cardID)), systemImage: cardIcon(cardID))
                                .font(.subheadline)

                            Spacer()

                            // Pinned badge
                            if layout.isPinned(cardID) {
                                Text(LocalizedStringKey("Pinned"))
                                    .font(.caption2.bold())
                                    .foregroundStyle(AppTheme.secondary)
                                    .padding(.horizontal, 7).padding(.vertical, 3)
                                    .glassEffect(.regular.tint(AppTheme.secondary.opacity(0.2)), in: Capsule())
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    .onMove { source, destination in
                        layout.move(from: source, to: destination)
                    }
                }

                Section {
                    NavigationLink(destination: WidgetGalleryView()) {
                        Label(LocalizedStringKey("Widget Gallery"), systemImage: "square.grid.2x2")
                            .font(.subheadline)
                    }
                }
            }
            .navigationTitle(LocalizedStringKey("Edit Dashboard"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(LocalizedStringKey("Done")) { dismiss() }
                        .fontWeight(.semibold)
                }
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
            }
        }
    }

    private func cardDisplayName(_ id: String) -> String {
        switch id {
        case "dailyFlow": return "Daily Flow"
        case "steps": return "Steps"
        case "energy": return "Active Energy"
        case "heartRate": return "Heart Rate"
        case "sleep": return "Sleep"
        case "hydration": return "Hydration"
        case "standTimer": return NSLocalizedString("Pomodoro", comment: "")
        case "nutrition": return "Nutrition"
        case "caffeine": return "Caffeine"
        case "shutdown": return "System Shutdown"
        case "weight": return "Weight"
        default: return id
        }
    }

    private func cardIcon(_ id: String) -> String {
        switch id {
        case "dailyFlow": return "checklist"
        case "steps": return "figure.walk"
        case "energy": return "flame.fill"
        case "heartRate": return "heart.fill"
        case "sleep": return "moon.zzz.fill"
        case "hydration": return "drop.fill"
        case "standTimer": return "timer"
        case "nutrition": return "fork.knife"
        case "caffeine": return "cup.and.saucer.fill"
        case "shutdown": return "moon.fill"
        case "weight": return "scalemass.fill"
        default: return "square"
        }
    }
}

// MARK: - Health Card

struct HealthCardQuickAction: Identifiable {
    let id = UUID()
    let label: String
    let icon: String
    let color: Color
    let action: () -> Void
}

struct HealthCard: View {
    let icon: String
    let title: String
    let color: Color
    let primaryValue: String
    let detail: String
    let statusText: String?
    let statusColor: Color
    let progress: Double?
    let quickActions: [HealthCardQuickAction]
    var badge: String? = nil

    @Environment(\.layoutDirection) private var layoutDirection

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Title row
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(LocalizedStringKey(title))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                if let badge {
                    Text(badge)
                        .font(.caption2.bold()).foregroundStyle(.white)
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background(Color.red, in: Capsule())
                }
                Image(systemName: layoutDirection == .rightToLeft ? "chevron.left" : "chevron.right")
                    .font(.caption.weight(.semibold)).foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16).padding(.top, 16).padding(.bottom, 8)

            // Primary metric
            Text(verbatim: primaryValue)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(statusColor)
                .padding(.horizontal, 16)

            // Detail
            Text(LocalizedStringKey(detail))
                .font(.caption).foregroundStyle(.secondary)
                .padding(.horizontal, 16).padding(.top, 2)

            // Status pill
            if let statusText, !statusText.isEmpty {
                Text(LocalizedStringKey(statusText))
                    .font(.caption2.bold()).foregroundStyle(statusColor)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .glassEffect(.regular.tint(statusColor.opacity(0.2)), in: Capsule())
                    .padding(.horizontal, 16).padding(.top, 6)
            }

            // Progress bar
            if let progress {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2).fill(color.opacity(0.12)).frame(height: 4)
                        RoundedRectangle(cornerRadius: 2).fill(color)
                            .frame(width: geo.size.width * progress, height: 4)
                            .animation(.spring(response: 0.5), value: progress)
                    }
                }
                .frame(height: 4)
                .padding(.horizontal, 16).padding(.top, 10)
            }

            // Quick actions
            if !quickActions.isEmpty {
                Divider().padding(.horizontal, 16).padding(.top, progress != nil ? 10 : 12)
                HStack(spacing: 8) {
                    ForEach(quickActions) { action in
                        Button {
                            action.action()
                        } label: {
                            Label(LocalizedStringKey(action.label), systemImage: action.icon)
                                .font(.caption.bold()).foregroundStyle(.secondary)
                        }
                        .buttonStyle(.glass).tint(action.color)
                    }
                    Spacer()
                }
                .padding(.horizontal, 12).padding(.vertical, 8)
            } else {
                Spacer().frame(height: 14)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(color.opacity(0.07)), in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
        // Prevent the card's own glass from absorbing the NavigationLink tap
        .allowsHitTesting(false)
    }
}

// MARK: - Health Metric Card (2×2 grid)

struct HealthMetricCard: View {
    let icon: String
    let title: String
    let value: String
    let unit: String?
    let caption: String
    let color: Color
    let progress: Double?
    var statusColor: Color? = nil

    @Environment(\.layoutDirection) private var layoutDirection

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .font(.subheadline.weight(.semibold)).foregroundStyle(.secondary)
                Text(LocalizedStringKey(title))
                    .font(.caption.weight(.medium)).foregroundStyle(.secondary)
                Spacer()
                Image(systemName: layoutDirection == .rightToLeft ? "chevron.left" : "chevron.right")
                    .font(.caption2).foregroundStyle(.tertiary)
            }

            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(verbatim: value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                if let unit {
                    Text(LocalizedStringKey(unit))
                        .font(.caption.bold()).foregroundStyle(.secondary)
                }
            }

            Text(LocalizedStringKey(caption))
                .font(.caption2)
                .foregroundStyle(statusColor ?? .secondary)
                .lineLimit(1)

            if let progress {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2).fill(color.opacity(0.12)).frame(height: 3)
                        RoundedRectangle(cornerRadius: 2).fill(color)
                            .frame(width: geo.size.width * progress, height: 3)
                            .animation(.spring(response: 0.5), value: progress)
                    }
                }
                .frame(height: 3)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(color.opacity(0.08)), in: RoundedRectangle(cornerRadius: 16))
        // Prevent card glass from stealing the NavigationLink tap
        .allowsHitTesting(false)
    }
}

#Preview {
    MainAppView()
}
