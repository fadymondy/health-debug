import SwiftUI
import SwiftData
import HealthDebugKit

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.layoutDirection) private var layoutDirection
    @StateObject private var health = HealthKitManager.shared
    @StateObject private var standTimer = StandTimerManager.shared
    @StateObject private var hydration = HydrationManager.shared
    @StateObject private var shutdownMgr = ShutdownManager.shared
    @StateObject private var caffeineMgr = CaffeineManager.shared
    @StateObject private var nutritionMgr = NutritionManager.shared
    @Query(UserProfile.currentDescriptor()) private var profiles: [UserProfile]
    @Query(SleepConfig.currentDescriptor()) private var sleepConfigs: [SleepConfig]

    @State private var showSettings = false
    @State private var showDailyFlow = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    if !health.isAuthorized {
                        authCard
                    } else {
                        metricsGrid
                        activitySection
                        healthSection
                    }
                }
                .padding(.vertical)
            }
            .refreshable { await health.refreshAll() }
            .navigationTitle(LocalizedStringKey("Dashboard"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button { showDailyFlow = true } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "checklist")
                            Text(LocalizedStringKey("Daily Flow"))
                                .font(.subheadline)
                        }
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                if let profile = profiles.first {
                    ProfileSettingsView(profile: profile, sleepConfig: sleepConfigs.first)
                }
            }
            .sheet(isPresented: $showDailyFlow) {
                DailyFlowSheet()
                    .presentationDetents([.medium, .large])
            }
            .onAppear {
                hydration.refresh(context: context)
                if let profile = profiles.first { hydration.dailyGoal = profile.dailyWaterGoalMl }
                nutritionMgr.refresh(context: context)
                caffeineMgr.refresh(context: context)
                shutdownMgr.startCountdown(config: sleepConfigs.first)
                standTimer.refreshTodayCount(context: context)
            }
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

    // MARK: - Metrics Grid (Apple Health style — 2×2)

    private var metricsGrid: some View {
        LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 12) {
            NavigationLink(destination: StepsDetailView()) {
                HealthMetricCard(
                    icon: "figure.walk", title: "Steps",
                    value: formatted(health.stepCount),
                    unit: nil,
                    caption: String(format: NSLocalizedString("%.0f%% of daily goal", comment: ""), min(100, health.stepCount / 10000 * 100)),
                    color: AppTheme.primary,
                    progress: min(1.0, health.stepCount / 10000)
                )
            }.buttonStyle(.plain)

            NavigationLink(destination: EnergyDetailView()) {
                HealthMetricCard(
                    icon: "flame.fill", title: "Active Energy",
                    value: formatted(health.activeEnergy),
                    unit: "kcal",
                    caption: String(format: NSLocalizedString("%.0f%% of 600 kcal", comment: ""), min(100, health.activeEnergy / 600 * 100)),
                    color: .orange,
                    progress: min(1.0, health.activeEnergy / 600)
                )
            }.buttonStyle(.plain)

            NavigationLink(destination: HeartRateDetailView()) {
                HealthMetricCard(
                    icon: "heart.fill", title: "Heart Rate",
                    value: formatted(health.heartRate),
                    unit: "BPM",
                    caption: heartZoneLabel,
                    color: .red,
                    // Map BPM to 0–1 within normal range 40–160 bpm
                    progress: min(1.0, max(0, (health.heartRate - 40) / 120)),
                    statusColor: heartZoneColor
                )
            }.buttonStyle(.plain)

            NavigationLink(destination: SleepDetailView()) {
                HealthMetricCard(
                    icon: "moon.zzz.fill", title: "Sleep",
                    value: String(format: "%.1f", health.sleepHours),
                    unit: "hrs",
                    caption: sleepQualityLabel,
                    color: AppTheme.secondary,
                    progress: min(1.0, health.sleepHours / 8.0),
                    statusColor: sleepQualityColor
                )
            }.buttonStyle(.plain)
        }
        .padding(.horizontal)
    }

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

    // MARK: - Activity Section

    private var activitySection: some View {
        VStack(spacing: 14) {
            sectionHeader("Activity")

            NavigationLink(destination: HydrationDetailView()) {
                HealthCard(
                    icon: "drop.fill", title: "Hydration",
                    color: AppTheme.secondary,
                    primaryValue: "\(hydration.todayTotal) ml",
                    detail: "/ \(hydration.dailyGoal) ml",
                    statusText: profiles.first.map { hydration.status(profile: $0).rawValue } ?? "",
                    statusColor: hydrationStatusColor,
                    progress: min(1.0, Double(hydration.todayTotal) / Double(max(1, hydration.dailyGoal))),
                    quickActions: [
                        .init(label: "Log 250ml", icon: "plus.circle.fill", color: AppTheme.secondary) {
                            hydration.logWater(250, source: "quick", context: context, profile: profiles.first)
                        },
                        .init(label: "Log 500ml", icon: "drop.circle.fill", color: AppTheme.secondary) {
                            hydration.logWater(500, source: "quick", context: context, profile: profiles.first)
                        }
                    ]
                )
            }.buttonStyle(.plain)

            NavigationLink(destination: StandTimerDetailView()) {
                HealthCard(
                    icon: "figure.stand", title: "Stand Timer",
                    color: AppTheme.accent,
                    primaryValue: "\(standTimer.todayCompleted)",
                    detail: "/ \(StandTimerManager.dailyTarget) \(NSLocalizedString("sessions", comment: ""))",
                    statusText: standTimerStatusText,
                    statusColor: standTimerStatusColor,
                    progress: min(1.0, Double(standTimer.todayCompleted) / Double(StandTimerManager.dailyTarget)),
                    quickActions: standTimer.state == .idle ? [
                        .init(label: NSLocalizedString("Start", comment: ""), icon: "play.circle.fill", color: AppTheme.accent) {
                            standTimer.startCycle()
                        }
                    ] : []
                )
            }.buttonStyle(.plain)
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
        switch standTimer.state {
        case .idle: return NSLocalizedString("Inactive", comment: "")
        case .sitting: return String(format: NSLocalizedString("%d min left", comment: ""), Int(standTimer.sitSecondsRemaining) / 60)
        case .standAlert: return NSLocalizedString("Stand Now!", comment: "")
        case .walking: return String(format: "%d:%02d", standTimer.walkSecondsRemaining / 60, standTimer.walkSecondsRemaining % 60)
        }
    }
    private var standTimerStatusColor: Color {
        switch standTimer.state {
        case .idle: return .secondary
        case .sitting: return AppTheme.accent
        case .standAlert: return .orange
        case .walking: return AppTheme.primary
        }
    }

    // MARK: - Health Section

    private var healthSection: some View {
        VStack(spacing: 14) {
            sectionHeader("Health")

            NavigationLink(destination: NutritionDetailView()) {
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
            }.buttonStyle(.plain)

            NavigationLink(destination: CaffeineDetailView()) {
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
            }.buttonStyle(.plain)

            NavigationLink(destination: ShutdownDetailView()) {
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
            }.buttonStyle(.plain)

            NavigationLink(destination: ZeppDetailView()) {
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
            }.buttonStyle(.plain)

            NavigationLink(destination: SleepDetailView()) {
                HealthCard(
                    icon: "bed.double.fill", title: "Last Night",
                    color: AppTheme.secondary,
                    primaryValue: String(format: "%.1f hrs", health.sleepHours),
                    detail: NSLocalizedString("/ 8 hours target", comment: ""),
                    statusText: sleepQualityLabel,
                    statusColor: sleepQualityColor,
                    progress: min(1.0, health.sleepHours / 8.0),
                    quickActions: []
                )
            }.buttonStyle(.plain)
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

    // MARK: - Section Header

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(LocalizedStringKey(title))
                .font(.title3.bold())
                .foregroundStyle(.primary)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 4)
    }

    private func formatted(_ value: Double) -> String {
        value >= 1000 ? String(format: "%.1fk", value / 1000) : String(format: "%.0f", value)
    }
}

// MARK: - Health Card (Apple Health inspired)

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
                    .foregroundStyle(color)

                Text(LocalizedStringKey(title))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                if let badge {
                    Text(badge)
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.red, in: Capsule())
                }

                // RTL-aware chevron
                Image(systemName: layoutDirection == .rightToLeft ? "chevron.left" : "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)

            // Primary metric
            HStack(alignment: .lastTextBaseline, spacing: 0) {
                Text(verbatim: primaryValue)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, 16)

            // Detail text
            Text(LocalizedStringKey(detail))
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .padding(.top, 2)

            // Status pill
            if let statusText, !statusText.isEmpty {
                Text(LocalizedStringKey(statusText))
                    .font(.caption2.bold())
                    .foregroundStyle(statusColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .glassEffect(.regular.tint(statusColor.opacity(0.2)), in: Capsule())
                    .padding(.horizontal, 16)
                    .padding(.top, 6)
            }

            // Single line chart progress bar (Apple Health style)
            if let progress {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(color.opacity(0.12))
                            .frame(height: 4)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(color)
                            .frame(width: geo.size.width * progress, height: 4)
                            .animation(.spring(response: 0.5), value: progress)
                    }
                }
                .frame(height: 4)
                .padding(.horizontal, 16)
                .padding(.top, 10)
            }

            // Quick actions row
            if !quickActions.isEmpty {
                Divider()
                    .padding(.horizontal, 16)
                    .padding(.top, progress != nil ? 10 : 12)

                HStack(spacing: 8) {
                    ForEach(quickActions) { action in
                        Button {
                            action.action()
                        } label: {
                            Label(LocalizedStringKey(action.label), systemImage: action.icon)
                                .font(.caption.bold())
                                .foregroundStyle(action.color)
                        }
                        .buttonStyle(.glass)
                        .tint(action.color)
                    }
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            } else {
                Spacer().frame(height: 14)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.interactive().tint(color.opacity(0.07)), in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
    }
}

// MARK: - Health Metric Card (small 2×2 grid)

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
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(color)
                Text(LocalizedStringKey(title))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: layoutDirection == .rightToLeft ? "chevron.left" : "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(verbatim: value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                if let unit {
                    Text(LocalizedStringKey(unit))
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }
            }

            Text(LocalizedStringKey(caption))
                .font(.caption2)
                .foregroundStyle(statusColor ?? .secondary)
                .lineLimit(1)

            if let progress {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(color.opacity(0.12))
                            .frame(height: 3)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(color)
                            .frame(width: geo.size.width * progress, height: 3)
                            .animation(.spring(response: 0.5), value: progress)
                    }
                }
                .frame(height: 3)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.interactive().tint(color.opacity(0.08)), in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Daily Flow Sheet

struct DailyFlowSheet: View {
    var body: some View {
        NavigationStack {
            DailyFlowCard()
                .padding(.top)
            Spacer()
        }
        .navigationTitle(LocalizedStringKey("Daily Flow"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    MainAppView()
}
