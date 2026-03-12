import SwiftUI
import SwiftData
import HealthDebugKit

// MARK: - Navigation Destinations

enum MacHealthScreen: Hashable {
    case hydration, steps, heartRate, sleep, standTimer, nutrition, caffeine, shutdown, analytics, aiChat, weight, dailyFlow
}

// MARK: - Root

struct MacContentView: View {
    @Environment(\.modelContext) private var context
    @Query(UserProfile.currentDescriptor()) private var profiles: [UserProfile]
    @Query(SleepConfig.currentDescriptor()) private var sleepConfigs: [SleepConfig]
    @State private var selectedTab = "feed"

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Feed", systemImage: "list.bullet.rectangle.portrait.fill", value: "feed") {
                MacDashboardView()
            }
            Tab("Insights", systemImage: "chart.line.uptrend.xyaxis", value: "insights") {
                NavigationStack { MacAnalyticsDetailView() }
            }
            Tab("Awareness", systemImage: "brain.head.profile.fill", value: "awareness") {
                NavigationStack { MacAIChatView() }
            }
            Tab("Settings", systemImage: "gearshape.fill", value: "settings") {
                NavigationStack {
                    if let profile = profiles.first {
                        MacProfileView(profile: profile, sleepConfig: sleepConfigs.first)
                    } else {
                        MacCreateProfileView()
                    }
                }
            }
            Tab("Search", systemImage: "magnifyingglass", value: "search", role: .search) {
                MacSearchView()
            }
        }
        .frame(minWidth: 900, minHeight: 640)
        .onAppear { ensureProfile() }
    }

    private func ensureProfile() {
        guard profiles.isEmpty else { return }
        let profile = UserProfile(); profile.name = ""; profile.email = ""
        context.insert(profile)
        let config = SleepConfig(); context.insert(config)
        try? context.save()
    }
}

// MARK: - Dashboard Tab

struct MacDashboardView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var watcher     = SharedStoreWatcher.shared
    @StateObject private var hydration   = HydrationManager.shared
    @StateObject private var nutrition   = NutritionManager.shared
    @StateObject private var caffeine    = CaffeineManager.shared
    @StateObject private var standTimer  = StandTimerManager.shared
    @StateObject private var shutdownMgr = ShutdownManager.shared
    @StateObject private var ai          = AIService.shared
    @StateObject private var analytics   = AnalyticsEngine.shared
    @Query(UserProfile.currentDescriptor()) private var profiles: [UserProfile]
    @Query(SleepConfig.currentDescriptor()) private var sleepConfigs: [SleepConfig]

    @State private var navPath: [MacHealthScreen] = []

    private var profile: UserProfile? { profiles.first }
    private var snap: WidgetSnapshot { watcher.snapshot }

    // MARK: Health Score (mirrors iOS exactly)

    private var healthScore: Int {
        var s = 0.0; var t = 0.0
        let h = profile.map { min(1.0, Double(hydration.todayTotal) / Double(max(1, $0.dailyWaterGoalMl))) } ?? min(1.0, Double(hydration.todayTotal) / 2500.0)
        s += h * 20; t += 20
        s += (nutrition.safetyScore / 100.0) * 20; t += 20
        s += (caffeine.cleanTransitionPercent / 100.0) * 20; t += 20
        s += min(1.0, Double(standTimer.todayCompleted) / Double(StandTimerManager.dailyTarget)) * 20; t += 20
        s += min(1.0, snap.sleepHours / 8.0) * 20; t += 20
        return t > 0 ? Int((s / t) * 100) : 0
    }
    private var scoreColor: Color { healthScore >= 80 ? AppTheme.primary : healthScore >= 50 ? .orange : .red }
    private var scoreLabel: String { healthScore >= 80 ? "Excellent" : healthScore >= 60 ? "Good" : healthScore >= 40 ? "Fair" : "Needs Attention" }

    var body: some View {
        NavigationStack(path: $navPath) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    welcomeHeader
                    healthScoreCard.onTapGesture { navPath.append(.analytics) }
                    feedSection
                    GlassEffectContainer {
                        Button { runAnalysis() } label: {
                            Label(ai.isLoading ? "Analyzing…" : "Analyze My Health", systemImage: "brain.head.profile.fill")
                                .frame(maxWidth: .infinity).font(.headline)
                        }
                        .buttonStyle(.glassProminent).tint(AppTheme.primary).controlSize(.large).disabled(ai.isLoading)
                    }
                    if !analytics.lastAnalysis.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Full Analysis", systemImage: "brain.head.profile.fill")
                                .font(.headline).foregroundStyle(AppTheme.primary)
                            Divider()
                            MarkdownView(content: analytics.lastAnalysis).textSelection(.enabled)
                        }
                        .padding()
                        .glassEffect(.regular.tint(AppTheme.primary.opacity(0.08)), in: RoundedRectangle(cornerRadius: 16))
                    }
                    pinnedGrid
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("Feed")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button { watcher.refreshSnapshot(); refreshAll() } label: { Image(systemName: "arrow.clockwise") }
                        .help("Refresh")
                }
                ToolbarItem(placement: .automatic) {
                    Text("Synced: \(snap.updatedAt.formatted(date: .omitted, time: .shortened))")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .navigationDestination(for: MacHealthScreen.self) { screen in
                switch screen {
                case .hydration:  MacHydrationDetailView()
                case .steps:      MacStepsDetailView()
                case .heartRate:  MacHeartRateDetailView()
                case .sleep:      MacSleepDetailView()
                case .standTimer: MacFocusDetailView()
                case .nutrition:  MacNutritionDetailView()
                case .caffeine:   MacCaffeineDetailView()
                case .shutdown:   MacShutdownDetailView()
                case .analytics:  MacAnalyticsDetailView()
                case .aiChat:     MacAIChatView()
                case .weight:     MacWeightDetailView()
                case .dailyFlow:  MacDailyFlowDetailView()
                }
            }
            .onAppear { refreshAll() }
            .onReceive(watcher.didChange) {
                try? context.save()
                refreshAll()
            }
        }
    }

    // MARK: - Welcome Header

    private var welcomeHeader: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 40)).foregroundStyle(AppTheme.primary)
            VStack(alignment: .leading, spacing: 2) {
                Text(greetingText).font(.subheadline).foregroundStyle(.secondary)
                Text(profile?.name.isEmpty == false ? profile!.name : "Health Debug").font(.title2.bold())
            }
            Spacer()
            Text("v\(HealthDebugKit.version)").font(.caption).foregroundStyle(.secondary)
        }
    }

    private var greetingText: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 5..<12:  "Good morning,"
        case 12..<17: "Good afternoon,"
        case 17..<21: "Good evening,"
        default:      "Good night,"
        }
    }

    // MARK: - Health Score Card

    private var healthScoreCard: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Health Score").font(.headline).foregroundStyle(.secondary)
                    Text("Your health score today").font(.caption).foregroundStyle(.tertiary)
                }
                Spacer()
                Label(ai.selectedProvider.rawValue,
                    systemImage: ai.selectedProvider == .apple ? "apple.intelligence" : "cloud.fill")
                    .font(.caption2.bold()).foregroundStyle(AppTheme.primary)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .glassEffect(.regular.tint(AppTheme.primary.opacity(0.1)), in: Capsule())
            }
            HStack(spacing: 24) {
                ZStack {
                    Circle().stroke(scoreColor.opacity(0.15), lineWidth: 10).frame(width: 90, height: 90)
                    Circle().trim(from: 0, to: CGFloat(healthScore) / 100)
                        .stroke(scoreColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .frame(width: 90, height: 90).rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.6), value: healthScore)
                    HStack(alignment: .lastTextBaseline, spacing: 1) {
                        Text("\(healthScore)").font(.system(size: 26, weight: .bold, design: .rounded)).foregroundStyle(scoreColor)
                        Text("/100").font(.caption.bold()).foregroundStyle(.secondary)
                    }
                }
                VStack(alignment: .leading, spacing: 8) {
                    scoreRow(icon: "drop.fill", label: "Hydration", color: AppTheme.secondary,
                        value: profile.map { min(1, Double(hydration.todayTotal) / Double(max(1, $0.dailyWaterGoalMl))) } ?? 0)
                    scoreRow(icon: "fork.knife",  label: "Nutrition", color: AppTheme.primary, value: nutrition.safetyScore / 100)
                    scoreRow(icon: "figure.stand", label: "Stands",   color: AppTheme.accent,
                        value: min(1, Double(standTimer.todayCompleted) / Double(StandTimerManager.dailyTarget)))
                    scoreRow(icon: "moon.zzz.fill", label: "Sleep",   color: AppTheme.secondary, value: min(1, snap.sleepHours / 8))
                }
                Spacer()
            }
            HStack {
                Text(scoreLabel).font(.subheadline.bold()).foregroundStyle(scoreColor)
                Spacer()
                if ai.isLoading {
                    ProgressView().controlSize(.small)
                    Text("Analyzing…").font(.caption).foregroundStyle(.secondary)
                } else {
                    Label("Tap to analyze", systemImage: "sparkles").font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .glassEffect(.regular.tint(scoreColor.opacity(0.1)), in: RoundedRectangle(cornerRadius: 20))
        .contentShape(Rectangle()).cursor(.pointingHand)
    }

    private func scoreRow(icon: String, label: String, color: Color, value: Double) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon).font(.caption2).foregroundStyle(color).frame(width: 14)
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2).fill(color.opacity(0.15)).frame(height: 4)
                    RoundedRectangle(cornerRadius: 2).fill(color)
                        .frame(width: g.size.width * max(0, min(1, value)), height: 4)
                        .animation(.spring(response: 0.5), value: value)
                }
            }.frame(height: 4)
            Text(label).font(.caption2).foregroundStyle(.secondary).frame(width: 60, alignment: .leading)
        }
    }

    // MARK: - Feed Section (mirrors iOS feedSection exactly)

    private var feedSection: some View {
        VStack(spacing: 12) {
            HStack {
                Label("Health Feed", systemImage: "dot.radiowaves.left.and.right")
                    .font(.headline).foregroundStyle(AppTheme.primary)
                Spacer()
            }

            MacFeedCard(icon: "drop.fill", title: "Hydration", color: AppTheme.secondary,
                value: profile.map { "\(hydration.todayTotal) ml / \($0.dailyWaterGoalMl) ml" } ?? "\(hydration.todayTotal) ml / 2500 ml",
                status: profile.map { hydration.status(profile: $0).rawValue } ?? "—",
                statusColor: hydrationFeedColor,
                actionLabel: "Log 250ml", actionIcon: "drop.circle.fill",
                aiQuery: "How is my hydration today? Give brief advice."
            ) { hydration.logWater(250, source: "mac", context: context, profile: profile) }
            onTap: { navPath.append(.hydration) }

            MacFeedCard(icon: "fork.knife", title: "Nutrition", color: nutritionFeedColor,
                value: "\(nutrition.todaySafeCount) safe · \(nutrition.todayUnsafeCount) unsafe",
                status: nutrition.safetyStatus.rawValue, statusColor: nutritionFeedColor,
                actionLabel: "Log Meal", actionIcon: "fork.knife.circle.fill",
                aiQuery: "Analyze my nutrition today and suggest improvements."
            ) { navPath.append(.nutrition) }
            onTap: { navPath.append(.nutrition) }

            MacFeedCard(icon: "cup.and.saucer.fill", title: "Caffeine", color: caffeineFeedColor,
                value: "\(caffeine.todayCleanCount) clean · \(caffeine.todaySugarCount) sugar",
                status: caffeine.transitionStatus.rawValue, statusColor: caffeineFeedColor,
                actionLabel: "View Logs", actionIcon: "list.bullet.circle.fill",
                aiQuery: "Give me caffeine advice for today."
            ) { navPath.append(.caffeine) }
            onTap: { navPath.append(.caffeine) }

            MacFeedCard(icon: "figure.walk", title: "Steps & Energy", color: AppTheme.primary,
                value: "\(snap.steps >= 1000 ? String(format: "%.1fk", snap.steps/1000) : "\(Int(snap.steps))") steps · \(String(format: "%.0f", snap.activeEnergy)) kcal",
                status: snap.steps >= 10000 ? "Goal Met" : "In Progress",
                statusColor: snap.steps >= 10000 ? AppTheme.primary : .orange,
                actionLabel: "View Detail", actionIcon: "chart.bar.fill",
                aiQuery: "How are my activity levels today? Any recommendations?"
            ) { navPath.append(.steps) }
            onTap: { navPath.append(.steps) }

            MacFeedCard(icon: "heart.fill", title: "Heart Rate", color: .red,
                value: String(format: "%.0f BPM", snap.heartRate),
                status: heartZoneLabel, statusColor: heartZoneColor,
                actionLabel: "View Detail", actionIcon: "heart.circle.fill",
                aiQuery: "What does my current heart rate indicate?"
            ) { navPath.append(.heartRate) }
            onTap: { navPath.append(.heartRate) }

            MacFeedCard(icon: "moon.zzz.fill", title: "Sleep", color: sleepFeedColor,
                value: String(format: "%.1f hrs", snap.sleepHours),
                status: sleepFeedLabel, statusColor: sleepFeedColor,
                actionLabel: "View Detail", actionIcon: "moon.circle.fill",
                aiQuery: "Analyze my sleep quality and give advice."
            ) { navPath.append(.sleep) }
            onTap: { navPath.append(.sleep) }

            MacFeedCard(icon: "timer", title: "Pomodoro / Stand", color: AppTheme.accent,
                value: "\(standTimer.todayCompleted) / \(StandTimerManager.dailyTarget) sessions",
                status: standTimer.phase.rawValue.capitalized,
                statusColor: standTimer.todayCompleted >= StandTimerManager.dailyTarget ? .green : .orange,
                actionLabel: standTimer.phase == .idle ? "Start Focus" : "Take Break",
                actionIcon: "timer.circle.fill",
                aiQuery: "How are my focus and stand sessions today?"
            ) {
                if standTimer.phase == .idle { standTimer.startCycle() } else { standTimer.startBreak() }
            } onTap: { navPath.append(.standTimer) }

            MacFeedCard(icon: "moon.fill", title: "GERD Shutdown",
                color: shutdownMgr.state == .active ? .orange : AppTheme.secondary,
                value: shutdownMgr.state == .active
                    ? ShutdownManager.formatCountdown(shutdownMgr.secondsUntilSleep)
                    : ShutdownManager.formatCountdown(shutdownMgr.secondsUntilShutdown),
                status: shutdownMgr.state == .active ? "Active" : "OK",
                statusColor: shutdownMgr.state == .active ? .orange : AppTheme.primary,
                actionLabel: "View Detail", actionIcon: "moon.circle.fill",
                aiQuery: "Explain my GERD shutdown timer status."
            ) { navPath.append(.shutdown) }
            onTap: { navPath.append(.shutdown) }

            MacFeedCard(icon: "scalemass.fill", title: "Weight", color: AppTheme.primary,
                value: String(format: "%.1f kg · %.1f%% fat", snap.weightKg, snap.weightBodyFat),
                status: snap.weightKg > 0 ? "Synced from iPhone" : "No data yet",
                statusColor: snap.weightKg > 0 ? AppTheme.primary : .secondary,
                actionLabel: "View Detail", actionIcon: "scalemass.fill",
                aiQuery: "Analyze my weight and body composition."
            ) { navPath.append(.weight) }
            onTap: { navPath.append(.weight) }
        }
    }

    // MARK: - Pinned Grid (2-column, mirrors iOS pinnedSection)

    private var pinnedGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Pinned").font(.title3.bold())
            LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 12) {
                macPinnedCard(icon: "figure.walk", title: "Steps",
                    value: snap.steps >= 1000 ? String(format: "%.1fk", snap.steps/1000) : "\(Int(snap.steps))",
                    unit: nil,
                    caption: String(format: "%.0f%% of goal", min(100, snap.steps / max(1, snap.stepsGoal) * 100)),
                    color: AppTheme.primary, progress: min(1, snap.steps / max(1, snap.stepsGoal))
                ) { navPath.append(.steps) }

                macPinnedCard(icon: "flame.fill", title: "Active Energy",
                    value: String(format: "%.0f", snap.activeEnergy), unit: "kcal",
                    caption: String(format: "%.0f%% of goal", min(100, snap.activeEnergy / max(1, snap.energyGoal) * 100)),
                    color: .orange, progress: min(1, snap.activeEnergy / max(1, snap.energyGoal))
                ) { navPath.append(.steps) }

                macPinnedCard(icon: "heart.fill", title: "Heart Rate",
                    value: String(format: "%.0f", snap.heartRate), unit: "BPM",
                    caption: heartZoneLabel, color: .red,
                    progress: min(1, max(0, (snap.heartRate - 40) / 120))
                ) { navPath.append(.heartRate) }

                macPinnedCard(icon: "moon.zzz.fill", title: "Sleep",
                    value: String(format: "%.1f", snap.sleepHours), unit: "hrs",
                    caption: sleepFeedLabel, color: AppTheme.secondary,
                    progress: min(1, snap.sleepHours / max(1, snap.sleepGoal))
                ) { navPath.append(.sleep) }

                macPinnedCard(icon: "drop.fill", title: "Hydration",
                    value: "\(hydration.todayTotal)", unit: "ml",
                    caption: profile.map { hydration.status(profile: $0).rawValue } ?? "",
                    color: AppTheme.secondary,
                    progress: profile.map { min(1, Double(hydration.todayTotal) / Double(max(1, $0.dailyWaterGoalMl))) } ?? 0
                ) { navPath.append(.hydration) }

                macPinnedCard(icon: "timer", title: "Pomodoro",
                    value: "\(standTimer.todayCompleted)", unit: nil,
                    caption: "of \(StandTimerManager.dailyTarget) sessions",
                    color: AppTheme.accent,
                    progress: min(1, Double(standTimer.todayCompleted) / Double(StandTimerManager.dailyTarget))
                ) { navPath.append(.standTimer) }

                macPinnedCard(icon: "fork.knife", title: "Nutrition",
                    value: String(format: "%.0f%%", nutrition.safetyScore), unit: nil,
                    caption: "\(nutrition.todaySafeCount) safe · \(nutrition.todayUnsafeCount) unsafe",
                    color: nutritionFeedColor, progress: nutrition.safetyScore / 100
                ) { navPath.append(.nutrition) }

                macPinnedCard(icon: "cup.and.saucer.fill", title: "Caffeine",
                    value: String(format: "%.0f%%", caffeine.cleanTransitionPercent), unit: nil,
                    caption: caffeine.transitionStatus.rawValue,
                    color: caffeineFeedColor, progress: caffeine.cleanTransitionPercent / 100
                ) { navPath.append(.caffeine) }

                macPinnedCard(icon: "scalemass.fill", title: "Weight",
                    value: String(format: "%.1f", snap.weightKg), unit: "kg",
                    caption: String(format: "%.1f%% body fat", snap.weightBodyFat),
                    color: AppTheme.primary, progress: nil
                ) { navPath.append(.weight) }

                macPinnedCard(icon: "moon.fill", title: "Shutdown",
                    value: shutdownMgr.state == .active
                        ? ShutdownManager.formatCountdown(shutdownMgr.secondsUntilSleep)
                        : ShutdownManager.formatCountdown(shutdownMgr.secondsUntilShutdown),
                    unit: nil,
                    caption: shutdownMgr.state == .active ? "Active" : "OK",
                    color: shutdownMgr.state == .active ? .orange : AppTheme.secondary,
                    progress: nil
                ) { navPath.append(.shutdown) }
            }
        }
    }

    private func macPinnedCard(icon: String, title: String, value: String, unit: String?,
        caption: String, color: Color, progress: Double?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon).font(.title3).foregroundStyle(color)
                    Spacer()
                    Text(title).font(.caption.bold()).foregroundStyle(.secondary)
                }
                HStack(alignment: .lastTextBaseline, spacing: 3) {
                    Text(value).font(.system(size: 22, weight: .bold, design: .rounded)).foregroundStyle(color)
                    if let u = unit { Text(u).font(.caption.bold()).foregroundStyle(.secondary) }
                }
                Text(caption).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                if let p = progress {
                    GeometryReader { g in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2).fill(color.opacity(0.15)).frame(height: 4)
                            RoundedRectangle(cornerRadius: 2).fill(color)
                                .frame(width: g.size.width * max(0, min(1, p)), height: 4)
                                .animation(.spring(response: 0.5), value: p)
                        }
                    }.frame(height: 4)
                }
            }
            .padding(14).frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(.regular.tint(color.opacity(0.08)), in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain).cursor(.pointingHand)
    }

    // MARK: - Computed helpers

    private var heartZoneLabel: String {
        switch snap.heartRate { case 0..<50: "Low"; case 50..<100: "Normal"; case 100..<140: "Elevated"; default: "High" }
    }
    private var heartZoneColor: Color {
        switch snap.heartRate { case 50..<100: AppTheme.primary; case 100..<140: .orange; default: .red }
    }
    private var sleepFeedLabel: String {
        switch snap.sleepHours { case 7...: "Good"; case 5..<7: "Low"; default: "Critical" }
    }
    private var sleepFeedColor: Color {
        switch snap.sleepHours { case 7...: AppTheme.primary; case 5..<7: .orange; default: .red }
    }
    private var hydrationFeedColor: Color {
        guard let p = profile else { return AppTheme.secondary }
        switch hydration.status(profile: p) {
        case .onTrack, .goalReached: return AppTheme.primary
        case .slightlyBehind: return .orange
        case .dehydrated: return .red
        }
    }
    private var nutritionFeedColor: Color {
        switch nutrition.safetyStatus {
        case .allSafe, .noMeals: return AppTheme.primary
        case .warning: return .orange
        case .critical: return .red
        }
    }
    private var caffeineFeedColor: Color {
        switch caffeine.transitionStatus {
        case .clean, .noIntake: return AppTheme.primary
        case .transitioning: return .orange
        case .redBullDependent: return .red
        }
    }

    // MARK: - Actions

    private func runAnalysis() {
        guard let container = try? ModelContainerFactory.create() else { return }
        let ctx = analytics.buildContext(context: ModelContext(container), profile: profile, sleepConfig: sleepConfigs.first)
        Task {
            analytics.isAnalyzing = true
            analytics.lastAnalysis = (try? await ai.analyze(prompt: analytics.buildPrompt(healthContext: ctx))) ?? ""
            analytics.isAnalyzing = false
        }
    }

    private func refreshAll() {
        watcher.refreshSnapshot()
        hydration.refresh(context: context)
        if let p = profile { hydration.dailyGoal = p.dailyWaterGoalMl }
        nutrition.refresh(context: context)
        caffeine.refresh(context: context)
        standTimer.refreshTodayCount(context: context)
        shutdownMgr.startCountdown(config: sleepConfigs.first)
    }
}

// MARK: - Feed Card

private struct MacFeedCard: View {
    let icon: String
    let title: String
    let color: Color
    let value: String
    let status: String
    let statusColor: Color
    let actionLabel: String
    let actionIcon: String
    let aiQuery: String
    let onAction: () -> Void
    let onTap: () -> Void

    @StateObject private var rag = HealthRAG.shared
    @Environment(\.modelContext) private var context
    @Query(UserProfile.currentDescriptor()) private var profiles: [UserProfile]
    @Query(SleepConfig.currentDescriptor()) private var sleepConfigs: [SleepConfig]

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon).font(.title2).foregroundStyle(color).frame(width: 36)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.caption.bold()).foregroundStyle(.secondary)
                Text(value).font(.headline)
                Text(status).font(.caption).foregroundStyle(statusColor)
            }
            Spacer()
            GlassEffectContainer {
                HStack(spacing: 6) {
                    Button { onAction() } label: { Label(actionLabel, systemImage: actionIcon) }
                        .buttonStyle(.glassProminent).tint(color).controlSize(.small)
                    Button {
                        Task { await rag.send(aiQuery, context: context, profile: profiles.first, sleepConfig: sleepConfigs.first) }
                    } label: { Label("Ask AI", systemImage: "sparkles") }
                        .buttonStyle(.glass).controlSize(.small)
                }
            }
            Image(systemName: "chevron.right").foregroundStyle(.tertiary).font(.caption)
        }
        .padding(14)
        .glassEffect(.regular.tint(color.opacity(0.06)), in: RoundedRectangle(cornerRadius: 14))
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
        .cursor(.pointingHand)
    }
}

// MARK: - View+Cursor

extension View {
    func cursor(_ cursor: NSCursor) -> some View {
        self.onHover { inside in if inside { cursor.push() } else { NSCursor.pop() } }
    }
}

// MARK: - Search Tab

struct MacSearchView: View {
    @State private var query = ""

    private let allScreens: [(label: String, icon: String, keywords: [String])] = [
        ("Hydration",   "drop.fill",                   ["water", "hydration", "drink", "ml"]),
        ("Nutrition",   "fork.knife",                  ["food", "meal", "nutrition", "safe", "eat"]),
        ("Caffeine",    "cup.and.saucer.fill",          ["coffee", "caffeine", "espresso", "tea"]),
        ("Steps",       "figure.walk",                 ["steps", "walk", "movement", "activity"]),
        ("Sleep",       "moon.zzz.fill",               ["sleep", "rest", "hours", "night"]),
        ("Focus",       "timer",                       ["focus", "pomodoro", "timer", "stand", "break"]),
        ("Heart Rate",  "heart.fill",                  ["heart", "bpm", "pulse", "rate"]),
        ("Weight",      "scalemass.fill",               ["weight", "kg", "body", "fat"]),
        ("Shutdown",    "moon.fill",                    ["shutdown", "gerd", "night", "food stop"]),
        ("Analytics",   "chart.xyaxis.line",            ["ai", "analytics", "analysis", "insights"]),
        ("AI Chat",     "bubble.left.and.sparkles.fill",["chat", "ask", "ai", "assistant"]),
        ("Daily Flow",  "waveform.path.ecg",            ["flow", "daily", "score", "balance"]),
    ]

    private var filtered: [(label: String, icon: String, keywords: [String])] {
        guard !query.isEmpty else { return allScreens }
        let q = query.lowercased()
        return allScreens.filter { $0.label.lowercased().contains(q) || $0.keywords.contains { $0.contains(q) } }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                    TextField("Search health data, screens, insights…", text: $query).textFieldStyle(.plain).font(.body)
                    if !query.isEmpty {
                        Button { query = "" } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary) }
                            .buttonStyle(.plain)
                    }
                }
                .padding(12).glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal).padding(.top, 16)

                if query.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "magnifyingglass").font(.system(size: 52)).foregroundStyle(AppTheme.primary)
                            .padding().glassEffect(.regular.tint(AppTheme.primary.opacity(0.15)), in: .circle)
                        Text("Smart Search").font(.title2.bold())
                        Text("Search across all your health data, screens, and AI insights.")
                            .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
                        Spacer()
                    }
                } else if filtered.isEmpty {
                    VStack(spacing: 12) {
                        Spacer()
                        Image(systemName: "questionmark.circle").font(.system(size: 40)).foregroundStyle(.secondary)
                        Text("No results for \"\(query)\"").font(.headline).foregroundStyle(.secondary)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(filtered, id: \.label) { item in
                                HStack(spacing: 14) {
                                    Image(systemName: item.icon).font(.title2).foregroundStyle(AppTheme.primary).frame(width: 36)
                                    Text(item.label).font(.headline)
                                    Spacer()
                                    Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                                }
                                .padding(14)
                                .glassEffect(.regular.tint(AppTheme.primary.opacity(0.05)), in: RoundedRectangle(cornerRadius: 12))
                                .contentShape(Rectangle())
                            }
                        }
                        .padding().safeAreaInset(edge: .bottom) { Color.clear.frame(height: 80) }
                    }
                }
            }
            .navigationTitle("Search")
        }
    }
}

// MARK: - Detail Views

struct MacHydrationDetailView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var hydration = HydrationManager.shared
    @Query(UserProfile.currentDescriptor()) private var profiles: [UserProfile]
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(hydration.todayTotal) ml")
                            .font(.system(size: 48, weight: .bold, design: .rounded)).foregroundStyle(.blue)
                        Text(profiles.first.map { "of \($0.dailyWaterGoalMl) ml goal" } ?? "of 2500 ml goal")
                            .font(.subheadline).foregroundStyle(.secondary)
                        if let p = profiles.first {
                            Text(hydration.status(profile: p).rawValue).font(.caption.bold())
                                .foregroundStyle(hydration.status(profile: p) == .goalReached ? .green : .orange)
                        }
                    }
                    Spacer()
                    GlassEffectContainer {
                        VStack(spacing: 8) {
                            ForEach([150, 250, 350, 500], id: \.self) { ml in
                                Button("+\(ml) ml") {
                                    hydration.logWater(ml, source: "mac", context: context, profile: profiles.first)
                                }
                                .buttonStyle(.glassProminent).tint(.blue)
                            }
                        }
                    }
                }
                .padding().glassEffect(.regular.tint(.blue.opacity(0.08)), in: RoundedRectangle(cornerRadius: 16))
                macProgressBar(value: profiles.first.map { min(1, Double(hydration.todayTotal) / Double(max(1, $0.dailyWaterGoalMl))) } ?? 0,
                    color: .blue, label: "Daily Progress")
            }.padding()
        }
        .navigationTitle("Hydration")
        .onAppear { hydration.refresh(context: context) }
    }
}

struct MacStepsDetailView: View {
    @StateObject private var watcher = SharedStoreWatcher.shared
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                macStatCard(
                    value: watcher.snapshot.steps >= 1000 ? String(format: "%.1fk", watcher.snapshot.steps/1000) : "\(Int(watcher.snapshot.steps))",
                    label: "Steps Today",
                    caption: String(format: "%.0f%% of %.0f", min(100, watcher.snapshot.steps / max(1, watcher.snapshot.stepsGoal) * 100), watcher.snapshot.stepsGoal),
                    color: .teal)
                HStack(spacing: 12) {
                    macStatCard(value: String(format: "%.0f kcal", watcher.snapshot.activeEnergy),
                        label: "Active Energy", caption: "of \(Int(watcher.snapshot.energyGoal)) kcal goal", color: .orange)
                    macStatCard(value: String(format: "%.0f BPM", watcher.snapshot.heartRate),
                        label: "Heart Rate", caption: heartZone, color: .red)
                }
                macProgressBar(value: min(1, watcher.snapshot.steps / max(1, watcher.snapshot.stepsGoal)),
                    color: .teal, label: "Step Goal")
            }.padding()
        }
        .navigationTitle("Movement")
        .onAppear { watcher.refreshSnapshot() }
    }
    private var heartZone: String {
        switch watcher.snapshot.heartRate { case 0..<50: "Low"; case 50..<100: "Normal"; case 100..<140: "Elevated"; default: "High" }
    }
}

struct MacHeartRateDetailView: View {
    @StateObject private var watcher = SharedStoreWatcher.shared
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                macStatCard(value: String(format: "%.0f BPM", watcher.snapshot.heartRate),
                    label: "Heart Rate (from iPhone)", caption: heartZone, color: .red)
                macStatCard(value: String(format: "%.1f kg", watcher.snapshot.weightKg),
                    label: "Weight", caption: String(format: "%.1f%% body fat", watcher.snapshot.weightBodyFat), color: .purple)
                Text("Last synced from iPhone: \(watcher.snapshot.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption).foregroundStyle(.secondary).padding(.horizontal)
            }.padding()
        }
        .navigationTitle("Heart Rate")
        .onAppear { watcher.refreshSnapshot() }
    }
    private var heartZone: String {
        switch watcher.snapshot.heartRate { case 0..<50: "Low"; case 50..<100: "Normal"; case 100..<140: "Elevated"; default: "High" }
    }
}

struct MacSleepDetailView: View {
    @StateObject private var watcher = SharedStoreWatcher.shared
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                macStatCard(value: String(format: "%.1f hrs", watcher.snapshot.sleepHours), label: "Last Night",
                    caption: watcher.snapshot.sleepHours >= 7 ? "Good" : watcher.snapshot.sleepHours >= 5 ? "Low" : "Critical",
                    color: .indigo)
                macProgressBar(value: min(1, watcher.snapshot.sleepHours / max(1, watcher.snapshot.sleepGoal)),
                    color: .indigo, label: "Sleep Goal (\(Int(watcher.snapshot.sleepGoal))h)")
                Text("Last synced from iPhone: \(watcher.snapshot.updatedAt.formatted(date: .omitted, time: .shortened))")
                    .font(.caption).foregroundStyle(.secondary).padding(.horizontal)
            }.padding()
        }
        .navigationTitle("Sleep")
        .onAppear { watcher.refreshSnapshot() }
    }
}

struct MacFocusDetailView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var timer = StandTimerManager.shared
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(timer.todayCompleted) / \(StandTimerManager.dailyTarget)")
                            .font(.system(size: 48, weight: .bold, design: .rounded)).foregroundStyle(.orange)
                        Text("Sessions today").font(.subheadline).foregroundStyle(.secondary)
                        Text("Phase: \(timer.phase.rawValue.capitalized)").font(.caption.bold())
                    }
                    Spacer()
                    if timer.phase != .idle {
                        Text(String(format: "%02d:%02d", Int(timer.secondsRemaining)/60, Int(timer.secondsRemaining)%60))
                            .font(.system(size: 40, weight: .bold, design: .monospaced)).foregroundStyle(.orange)
                    }
                }
                .padding().glassEffect(.regular.tint(.orange.opacity(0.08)), in: RoundedRectangle(cornerRadius: 16))
                GlassEffectContainer {
                    HStack(spacing: 12) {
                        if timer.phase == .idle {
                            Button { timer.startCycle() } label: { Label("Start Focus", systemImage: "play.fill") }
                                .buttonStyle(.glassProminent).tint(.orange)
                        } else if timer.phase == .work {
                            Button { timer.startBreak() } label: { Label("Take Break", systemImage: "pause.fill") }
                                .buttonStyle(.glass)
                        }
                    }
                }
                macProgressBar(value: min(1, Double(timer.todayCompleted) / Double(StandTimerManager.dailyTarget)),
                    color: .orange, label: "Daily Sessions")
            }.padding()
        }
        .navigationTitle("Focus (Pomodoro)")
        .onAppear { timer.refreshTodayCount(context: context) }
    }
}

struct MacNutritionDetailView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var nutrition = NutritionManager.shared
    @State private var newFood = ""
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(format: "%.0f%%", nutrition.safetyScore))
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(nutrition.safetyScore >= 70 ? .green : .orange)
                        Text("Safety Score").font(.subheadline).foregroundStyle(.secondary)
                        Text(nutrition.safetyStatus.rawValue).font(.caption.bold())
                    }
                    Spacer()
                    VStack(spacing: 6) {
                        Label("\(nutrition.todaySafeCount) safe", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
                        Label("\(nutrition.todayUnsafeCount) unsafe", systemImage: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                    }
                }
                .padding().glassEffect(.regular.tint(.green.opacity(0.08)), in: RoundedRectangle(cornerRadius: 16))
                VStack(alignment: .leading, spacing: 10) {
                    Text("Log a Meal").font(.headline)
                    HStack {
                        TextField("Food name…", text: $newFood).textFieldStyle(.roundedBorder)
                        Button("Log") {
                            guard !newFood.isEmpty else { return }
                            nutrition.logMeal(newFood, category: .protein, context: context)
                            newFood = ""
                        }
                        .buttonStyle(.glassProminent).tint(.green).disabled(newFood.isEmpty)
                    }
                }
                .padding().glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
                if !nutrition.todayMeals.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Today's Meals").font(.headline)
                        ForEach(nutrition.todayMeals, id: \.timestamp) { meal in
                            HStack {
                                Image(systemName: meal.isSafe ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                    .foregroundStyle(meal.isSafe ? .green : .orange)
                                Text(meal.name).font(.subheadline)
                                Spacer()
                                Text(meal.timestamp.formatted(date: .omitted, time: .shortened))
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding().glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
                }
            }.padding()
        }
        .navigationTitle("Nutrition")
        .onAppear { nutrition.refresh(context: context) }
    }
}

struct MacCaffeineDetailView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var caffeine = CaffeineManager.shared
    @Query(UserProfile.currentDescriptor()) private var profiles: [UserProfile]
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(format: "%.0f%%", caffeine.cleanTransitionPercent))
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(caffeine.cleanTransitionPercent >= 70 ? .green : .orange)
                        Text("Transition Score").font(.subheadline).foregroundStyle(.secondary)
                        Text(caffeine.transitionStatus.rawValue).font(.caption.bold())
                    }
                    Spacer()
                    VStack(spacing: 6) {
                        Label("\(caffeine.todayCleanCount) clean", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
                        Label("\(caffeine.todaySugarCount) sugar", systemImage: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                    }
                }
                .padding().glassEffect(.regular.tint(.brown.opacity(0.08)), in: RoundedRectangle(cornerRadius: 16))
                VStack(alignment: .leading, spacing: 10) {
                    Text("Log Drink").font(.headline)
                    GlassEffectContainer {
                        LazyVGrid(columns: [.init(.flexible()), .init(.flexible()), .init(.flexible())], spacing: 8) {
                            ForEach([CaffeineType.espresso, .blackCoffee, .greenTea, .matcha, .coldBrew], id: \.self) { type in
                                Button(type.rawValue) { _ = caffeine.logCaffeine(type, context: context, profile: profiles.first) }
                                    .buttonStyle(.glass)
                            }
                        }
                    }
                }
                .padding().glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
            }.padding()
        }
        .navigationTitle("Caffeine")
        .onAppear { caffeine.refresh(context: context) }
    }
}

struct MacShutdownDetailView: View {
    @StateObject private var shutdown = ShutdownManager.shared
    @Query(SleepConfig.currentDescriptor()) private var sleepConfigs: [SleepConfig]
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                macStatCard(
                    value: shutdown.state == .active
                        ? ShutdownManager.formatCountdown(shutdown.secondsUntilSleep)
                        : ShutdownManager.formatCountdown(shutdown.secondsUntilShutdown),
                    label: "GERD Shutdown Timer",
                    caption: shutdown.state == .active ? "Shutdown Active" : "System OK",
                    color: shutdown.state == .active ? .orange : .green)
            }.padding()
        }
        .navigationTitle("System Shutdown")
        .onAppear { shutdown.startCountdown(config: sleepConfigs.first) }
    }
}

struct MacWeightDetailView: View {
    @StateObject private var watcher = SharedStoreWatcher.shared
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                macStatCard(value: String(format: "%.1f kg", watcher.snapshot.weightKg),
                    label: "Weight (Zepp via iPhone)", caption: "Synced from Apple Health", color: AppTheme.primary)
                macStatCard(value: String(format: "%.1f%%", watcher.snapshot.weightBodyFat),
                    label: "Body Fat", caption: "Zepp body composition", color: .purple)
                Text("Last synced: \(watcher.snapshot.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption).foregroundStyle(.secondary).padding(.horizontal)
            }.padding()
        }
        .navigationTitle("Weight")
        .onAppear { watcher.refreshSnapshot() }
    }
}

struct MacDailyFlowDetailView: View {
    @StateObject private var watcher = SharedStoreWatcher.shared
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                macStatCard(
                    value: "\(watcher.snapshot.dailyFlowScore) / \(watcher.snapshot.dailyFlowTotal)",
                    label: "Daily Flow Score",
                    caption: watcher.snapshot.dailyFlowScore >= 4 ? "Excellent flow" : watcher.snapshot.dailyFlowScore >= 2 ? "Moderate" : "Needs attention",
                    color: watcher.snapshot.dailyFlowScore >= 4 ? AppTheme.primary : .orange)
                macProgressBar(value: Double(watcher.snapshot.dailyFlowScore) / Double(max(1, watcher.snapshot.dailyFlowTotal)),
                    color: AppTheme.primary, label: "Daily Flow")
            }.padding()
        }
        .navigationTitle("Daily Flow")
        .onAppear { watcher.refreshSnapshot() }
    }
}

struct MacAnalyticsDetailView: View {
    @StateObject private var ai = AIService.shared
    @StateObject private var analytics = AnalyticsEngine.shared
    @Query(UserProfile.currentDescriptor()) private var profiles: [UserProfile]
    @Query(SleepConfig.currentDescriptor()) private var sleepConfigs: [SleepConfig]
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("AI Health Analysis").font(.title2.bold())
                    Spacer()
                    Text(ai.selectedProvider.rawValue).font(.caption).foregroundStyle(.secondary)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .glassEffect(.regular, in: Capsule())
                    Button {
                        guard let container = try? ModelContainerFactory.create() else { return }
                        let ctx = analytics.buildContext(context: ModelContext(container), profile: profiles.first, sleepConfig: sleepConfigs.first)
                        Task {
                            analytics.isAnalyzing = true
                            analytics.lastAnalysis = (try? await ai.analyze(prompt: analytics.buildPrompt(healthContext: ctx))) ?? ""
                            analytics.isAnalyzing = false
                        }
                    } label: { Label(ai.isLoading ? "Analyzing…" : "Analyze 72h", systemImage: "brain.head.profile.fill") }
                        .buttonStyle(.glassProminent).tint(.purple).disabled(ai.isLoading)
                }
                if ai.isLoading {
                    HStack { ProgressView(); Text("Analyzing your health data…").foregroundStyle(.secondary) }
                } else if analytics.lastAnalysis.isEmpty {
                    ContentUnavailableView("No Analysis Yet", systemImage: "brain.head.profile.fill",
                        description: Text("Tap Analyze 72h to generate an AI report."))
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        MarkdownView(content: analytics.lastAnalysis).textSelection(.enabled)
                    }
                    .padding().glassEffect(.regular.tint(.purple.opacity(0.08)), in: RoundedRectangle(cornerRadius: 16))
                }
            }.padding()
        }
        .navigationTitle("Analytics")
    }
}

struct MacAIChatView: View {
    @StateObject private var rag = HealthRAG.shared
    @Environment(\.modelContext) private var context
    @Query(UserProfile.currentDescriptor()) private var profiles: [UserProfile]
    @Query(SleepConfig.currentDescriptor()) private var sleepConfigs: [SleepConfig]
    @State private var input = ""
    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(Array(rag.messages.enumerated()), id: \.offset) { _, msg in
                            chatRow(msg).id(msg.id)
                        }
                    }.padding()
                }
                .onChange(of: rag.messages.count) { _, _ in
                    if let last = rag.messages.last { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
            Divider()
            HStack(spacing: 10) {
                TextField("Ask about your health…", text: $input).textFieldStyle(.roundedBorder).onSubmit { send() }
                Button("Send") { send() }
                    .buttonStyle(.glassProminent).tint(.pink).disabled(input.isEmpty || rag.isProcessing)
            }.padding()
        }
        .navigationTitle("AI Chat")
    }
    @ViewBuilder
    private func chatRow(_ msg: HealthRAG.Message) -> some View {
        let isAI = msg.role == .assistant
        HStack(alignment: .top, spacing: 10) {
            if isAI { Image(systemName: "sparkles").foregroundStyle(.purple).frame(width: 24) }
            if isAI {
                MarkdownView(content: msg.content).padding(10)
                    .glassEffect(.regular.tint(.purple.opacity(0.1)), in: RoundedRectangle(cornerRadius: 10))
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text(msg.content).padding(10)
                    .glassEffect(.regular.tint(.blue.opacity(0.1)), in: RoundedRectangle(cornerRadius: 10))
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            if !isAI { Image(systemName: "person.circle.fill").foregroundStyle(.secondary).frame(width: 24) }
        }
    }
    private func send() {
        let q = input.trimmingCharacters(in: .whitespaces); guard !q.isEmpty else { return }
        input = ""
        Task { await rag.send(q, context: context, profile: profiles.first, sleepConfig: sleepConfigs.first) }
    }
}

// MARK: - Profile

struct MacCreateProfileView: View {
    @Environment(\.modelContext) private var context
    @Query(UserProfile.currentDescriptor()) private var profiles: [UserProfile]
    @Query(SleepConfig.currentDescriptor()) private var sleepConfigs: [SleepConfig]
    @State private var name = ""; @State private var email = ""
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "person.crop.circle.badge.plus").font(.system(size: 64)).foregroundStyle(AppTheme.primary)
                .padding().glassEffect(.regular.tint(AppTheme.primary.opacity(0.12)), in: .circle)
            Text("Set Up Your Profile").font(.title2.bold())
            Text("Enter your info to personalise your health dashboard.")
                .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
            VStack(spacing: 12) {
                TextField("Full name", text: $name).textFieldStyle(.roundedBorder).frame(maxWidth: 320)
                TextField("Email", text: $email).textFieldStyle(.roundedBorder).frame(maxWidth: 320)
            }
            Button { createProfile() } label: {
                Label("Create Profile", systemImage: "person.crop.circle.fill.badge.checkmark").frame(width: 220)
            }
            .buttonStyle(.glassProminent).tint(AppTheme.primary).controlSize(.large).disabled(name.isEmpty)
            Spacer()
        }
        .padding().navigationTitle("Welcome")
    }
    private func createProfile() {
        let p = profiles.first ?? { let p = UserProfile(); context.insert(p); return p }()
        p.name = name; p.email = email
        if sleepConfigs.isEmpty { context.insert(SleepConfig()) }
        try? context.save()
    }
}

struct MacProfileView: View {
    @Bindable var profile: UserProfile
    var sleepConfig: SleepConfig?
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "person.crop.circle.fill").font(.system(size: 72)).foregroundStyle(AppTheme.primary)
                        Text(profile.name.isEmpty ? "Your Name" : profile.name).font(.title2.bold())
                        Text(profile.email).font(.subheadline).foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding().glassEffect(.regular.tint(AppTheme.primary.opacity(0.08)), in: RoundedRectangle(cornerRadius: 16))
                settingSection(title: "Personal Info", icon: "person.fill", color: AppTheme.primary) {
                    MacSettingRow(label: "Name") { TextField("Name", text: $profile.name).textFieldStyle(.roundedBorder) }
                    MacSettingRow(label: "Email") { TextField("Email", text: $profile.email).textFieldStyle(.roundedBorder) }
                }
                settingSection(title: "Body Composition", icon: "figure.arms.open", color: .orange) {
                    MacSettingRow(label: "Weight (kg)") { TextField("kg", value: $profile.weightKg, format: .number).textFieldStyle(.roundedBorder).frame(width: 80) }
                    MacSettingRow(label: "Height (cm)") { TextField("cm", value: $profile.heightCm, format: .number).textFieldStyle(.roundedBorder).frame(width: 80) }
                }
                settingSection(title: "Daily Targets", icon: "target", color: AppTheme.secondary) {
                    MacSettingRow(label: "Water Goal (ml)") { Stepper("\(profile.dailyWaterGoalMl) ml", value: $profile.dailyWaterGoalMl, in: 1000...5000, step: 250) }
                }
                if let config = sleepConfig {
                    settingSection(title: "Sleep", icon: "moon.fill", color: AppTheme.secondary) {
                        MacSettingRow(label: "Bedtime") { Text("\(config.targetSleepHour):\(String(format: "%02d", config.targetSleepMinute))").font(.subheadline.bold()) }
                        MacSettingRow(label: "Shutdown Window") { Text("\(config.shutdownWindowHours) hours").font(.subheadline.bold()) }
                    }
                }
            }.padding()
        }
        .navigationTitle("Profile")
    }
    private func settingSection<C: View>(title: String, icon: String, color: Color, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon).font(.headline).foregroundStyle(color)
            content()
        }
        .padding().glassEffect(.regular.tint(color.opacity(0.06)), in: RoundedRectangle(cornerRadius: 16))
    }
}

struct MacSettingRow<C: View>: View {
    let label: String; @ViewBuilder let content: () -> C
    var body: some View {
        HStack { Text(label).font(.subheadline).foregroundStyle(.secondary); Spacer(); content() }
    }
}

// MARK: - Shared helpers

private func macStatCard(value: String, label: String, caption: String, color: Color) -> some View {
    VStack(alignment: .leading, spacing: 4) {
        Text(label).font(.headline).foregroundStyle(.secondary)
        Text(value).font(.system(size: 48, weight: .bold, design: .rounded)).foregroundStyle(color)
        Text(caption).font(.caption.bold()).foregroundStyle(color.opacity(0.8))
    }
    .padding().frame(maxWidth: .infinity, alignment: .leading)
    .glassEffect(.regular.tint(color.opacity(0.08)), in: RoundedRectangle(cornerRadius: 16))
}

private func macProgressBar(value: Double, color: Color, label: String) -> some View {
    VStack(alignment: .leading, spacing: 6) {
        Text(label).font(.headline)
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4).fill(color.opacity(0.12)).frame(height: 12)
                RoundedRectangle(cornerRadius: 4).fill(color)
                    .frame(width: geo.size.width * max(0, min(1, value)), height: 12)
                    .animation(.spring(response: 0.5), value: value)
            }
        }.frame(height: 12)
    }
    .padding().glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
}

#Preview { MacContentView() }
