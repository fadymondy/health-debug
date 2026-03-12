import SwiftUI
import SwiftData
import HealthDebugKit

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var health = HealthKitManager.shared
    @StateObject private var standTimer = StandTimerManager.shared
    @StateObject private var hydration = HydrationManager.shared
    @StateObject private var shutdownMgr = ShutdownManager.shared
    @StateObject private var caffeineMgr = CaffeineManager.shared
    @StateObject private var nutritionMgr = NutritionManager.shared
    @Query(UserProfile.currentDescriptor()) private var profiles: [UserProfile]
    @Query(SleepConfig.currentDescriptor()) private var sleepConfigs: [SleepConfig]

    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if !health.isAuthorized {
                        authCard
                    } else {
                        DailyFlowCard()
                        AIInsightCard(domain: .dashboard)
                        metricsGrid
                        NavigationLink(destination: HydrationDetailView()) {
                            hydrationCard
                        }.buttonStyle(.plain)
                        NavigationLink(destination: NutritionDetailView()) {
                            nutritionCard
                        }.buttonStyle(.plain)
                        NavigationLink(destination: CaffeineDetailView()) {
                            caffeineCard
                        }.buttonStyle(.plain)
                        NavigationLink(destination: ShutdownDetailView()) {
                            shutdownCard
                        }.buttonStyle(.plain)
                        NavigationLink(destination: StandTimerDetailView()) {
                            standTimerCard
                        }.buttonStyle(.plain)
                        NavigationLink(destination: ZeppDetailView()) {
                            zeppCard
                        }.buttonStyle(.plain)
                        NavigationLink(destination: SleepDetailView()) {
                            sleepCard
                        }.buttonStyle(.plain)
                    }
                }
                .padding(.vertical)
            }
            .refreshable { await health.refreshAll() }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                if let profile = profiles.first {
                    ProfileSettingsView(profile: profile, sleepConfig: sleepConfigs.first)
                }
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
                .font(.system(size: 40))
                .foregroundStyle(AppTheme.secondary)
            Text(LocalizedStringKey("HealthKit Access Required"))
                .font(.headline)
            Text(LocalizedStringKey("Tap to authorize reading your health data."))
                .font(.subheadline).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
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

    // MARK: - Metrics Grid

    private var metricsGrid: some View {
        LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 12) {
            NavigationLink(destination: StepsDetailView()) {
                MetricCard(
                    icon: "figure.walk", title: "Steps",
                    value: formatted(health.stepCount),
                    subtitle: "/ 10k goal",
                    progress: min(1.0, health.stepCount / 10000),
                    color: AppTheme.primary
                )
            }.buttonStyle(.plain)

            NavigationLink(destination: EnergyDetailView()) {
                MetricCard(
                    icon: "flame.fill", title: "Energy",
                    value: formatted(health.activeEnergy), unit: "kcal",
                    subtitle: "/ 600 kcal",
                    progress: min(1.0, health.activeEnergy / 600),
                    color: .orange
                )
            }.buttonStyle(.plain)

            NavigationLink(destination: HeartRateDetailView()) {
                MetricCard(
                    icon: "heart.fill", title: "Heart Rate",
                    value: formatted(health.heartRate), unit: "bpm",
                    subtitle: heartRateZone.label,
                    progress: nil,
                    color: .red,
                    statusColor: heartRateZone.color,
                    pulse: true
                )
            }.buttonStyle(.plain)

            NavigationLink(destination: SleepDetailView()) {
                MetricCard(
                    icon: "moon.zzz.fill", title: "Sleep",
                    value: String(format: "%.1f", health.sleepHours), unit: "hrs",
                    subtitle: sleepQuality.label,
                    progress: min(1.0, health.sleepHours / 8.0),
                    color: AppTheme.secondary,
                    statusColor: sleepQuality.color
                )
            }.buttonStyle(.plain)
        }
        .padding(.horizontal)
    }

    private var heartRateZone: (label: String, color: Color) {
        switch health.heartRate {
        case 0..<50: return ("Low", .blue)
        case 50..<100: return ("Normal", AppTheme.primary)
        case 100..<140: return ("Elevated", .orange)
        default: return ("High", .red)
        }
    }

    private var sleepQuality: (label: String, color: Color) {
        switch health.sleepHours {
        case 7...: return ("Good", AppTheme.primary)
        case 5..<7: return ("Low", .orange)
        default: return ("Critical", .red)
        }
    }

    // MARK: - Hydration Card

    private var hydrationCard: some View {
        let progress = min(1.0, Double(hydration.todayTotal) / Double(max(1, hydration.dailyGoal)))
        let statusColor: Color = {
            guard let profile = profiles.first else { return AppTheme.secondary }
            switch hydration.status(profile: profile) {
            case .onTrack, .goalReached: return AppTheme.secondary
            case .slightlyBehind: return .orange
            case .dehydrated: return .red
            }
        }()

        return DashboardCard(
            icon: "drop.fill",
            title: "Hydration",
            accentColor: AppTheme.secondary,
            primaryValue: "\(hydration.todayTotal)",
            primaryUnit: "ml",
            secondaryLine: "/ \(hydration.dailyGoal) ml goal",
            statusLabel: profiles.first.map { hydration.status(profile: $0).rawValue },
            statusColor: statusColor,
            progress: progress,
            alertIcon: hydration.todayTotal < 500 ? "exclamationmark.drop.fill" : nil
        )
    }

    // MARK: - Nutrition Card

    private var nutritionCard: some View {
        DashboardCard(
            icon: "fork.knife",
            title: "Nutrition",
            accentColor: nutritionStatusColor,
            primaryValue: String(format: "%.0f%%", nutritionMgr.safetyScore),
            primaryUnit: nil,
            secondaryLine: "\(nutritionMgr.todaySafeCount) safe · \(nutritionMgr.todayUnsafeCount) unsafe",
            statusLabel: nutritionMgr.safetyStatus.rawValue,
            statusColor: nutritionStatusColor,
            progress: nutritionMgr.safetyScore / 100,
            alertIcon: nutritionMgr.todayUnsafeCount > 0 ? "exclamationmark.triangle.fill" : nil,
            alertColor: .red
        )
    }

    private var nutritionStatusColor: Color {
        switch nutritionMgr.safetyStatus {
        case .allSafe, .noMeals: return AppTheme.primary
        case .warning: return .orange
        case .critical: return .red
        }
    }

    // MARK: - Caffeine Card

    private var caffeineCard: some View {
        DashboardCard(
            icon: "cup.and.saucer.fill",
            title: "Caffeine",
            accentColor: caffeineMgr.fattyLiverAlert ? .red : AppTheme.primary,
            primaryValue: String(format: "%.0f%%", caffeineMgr.cleanTransitionPercent),
            primaryUnit: nil,
            secondaryLine: "\(caffeineMgr.todayCleanCount) clean · \(caffeineMgr.todaySugarCount) sugar",
            statusLabel: caffeineMgr.transitionStatus.rawValue,
            statusColor: caffeineStatusColor,
            progress: caffeineMgr.cleanTransitionPercent / 100,
            alertIcon: caffeineMgr.fattyLiverAlert ? "exclamationmark.triangle.fill" : nil,
            alertColor: .red
        )
    }

    private var caffeineStatusColor: Color {
        switch caffeineMgr.transitionStatus {
        case .clean, .noIntake: return AppTheme.primary
        case .transitioning: return .orange
        case .redBullDependent: return .red
        }
    }

    // MARK: - Shutdown Card

    private var shutdownCard: some View {
        let isActive = shutdownMgr.state == .active
        let timeStr = isActive
            ? ShutdownManager.formatCountdown(shutdownMgr.secondsUntilSleep)
            : ShutdownManager.formatCountdown(shutdownMgr.secondsUntilShutdown)

        return DashboardCard(
            icon: "moon.fill",
            title: "System Shutdown",
            accentColor: isActive ? .orange : AppTheme.secondary,
            primaryValue: timeStr,
            primaryUnit: nil,
            secondaryLine: isActive ? "Active — No food until sleep" : "You can eat normally",
            statusLabel: isActive ? "ACTIVE" : "OK",
            statusColor: isActive ? .orange : AppTheme.primary,
            progress: nil,
            alertIcon: isActive ? "exclamationmark.triangle.fill" : "checkmark.circle.fill",
            alertColor: isActive ? .orange : AppTheme.primary
        )
    }

    // MARK: - Stand Timer Card

    private var standTimerCard: some View {
        let progress = min(1.0, Double(standTimer.todayCompleted) / Double(StandTimerManager.dailyTarget))
        let (primaryVal, statusLabel, statusColor): (String, String, Color) = {
            switch standTimer.state {
            case .idle: return ("Idle", "Inactive", .secondary)
            case .sitting:
                let m = Int(standTimer.sitSecondsRemaining) / 60
                return ("\(m)m", "Sitting", AppTheme.accent)
            case .standAlert:
                return ("!", "Stand Now", .orange)
            case .walking:
                let m = standTimer.walkSecondsRemaining / 60
                let s = standTimer.walkSecondsRemaining % 60
                return (String(format: "%d:%02d", m, s), "Walking", AppTheme.primary)
            }
        }()

        return DashboardCard(
            icon: "figure.stand",
            title: "Stand Timer",
            accentColor: AppTheme.accent,
            primaryValue: primaryVal,
            primaryUnit: nil,
            secondaryLine: "\(standTimer.todayCompleted) / \(StandTimerManager.dailyTarget) sessions",
            statusLabel: statusLabel,
            statusColor: statusColor,
            progress: progress,
            alertIcon: standTimer.state == .standAlert ? "exclamationmark.triangle.fill" : nil,
            alertColor: .orange
        )
    }

    // MARK: - Zepp Card

    private var zeppCard: some View {
        let syncStr = health.zeppMetrics.lastUpdated.map { $0.formatted(.relative(presentation: .named)) } ?? "Never"

        return DashboardCard(
            icon: "scalemass.fill",
            title: "Weight",
            accentColor: AppTheme.primary,
            primaryValue: String(format: "%.1f", health.zeppMetrics.weight),
            primaryUnit: "kg",
            secondaryLine: "Synced \(syncStr)",
            statusLabel: nil,
            statusColor: AppTheme.primary,
            progress: nil
        )
    }

    // MARK: - Sleep Card

    private var sleepCard: some View {
        DashboardCard(
            icon: "bed.double.fill",
            title: "Last Night",
            accentColor: AppTheme.secondary,
            primaryValue: String(format: "%.1f", health.sleepHours),
            primaryUnit: "hrs",
            secondaryLine: "/ 8 hours target",
            statusLabel: sleepQuality.label,
            statusColor: sleepQuality.color,
            progress: min(1.0, health.sleepHours / 8.0)
        )
    }

    private func formatted(_ value: Double) -> String {
        value >= 1000 ? String(format: "%.1fk", value / 1000) : String(format: "%.0f", value)
    }
}

// MARK: - Dashboard Card (Enhanced)

struct DashboardCard: View {
    let icon: String
    let title: LocalizedStringKey
    let accentColor: Color
    let primaryValue: String
    let primaryUnit: String?
    let secondaryLine: String
    let statusLabel: String?
    let statusColor: Color
    let progress: Double?
    var alertIcon: String? = nil
    var alertColor: Color = .orange

    @State private var alertPulse = false

    init(
        icon: String, title: String,
        accentColor: Color,
        primaryValue: String, primaryUnit: String?,
        secondaryLine: String,
        statusLabel: String?,
        statusColor: Color,
        progress: Double?,
        alertIcon: String? = nil,
        alertColor: Color = .orange
    ) {
        self.icon = icon
        self.title = LocalizedStringKey(title)
        self.accentColor = accentColor
        self.primaryValue = primaryValue
        self.primaryUnit = primaryUnit
        self.secondaryLine = secondaryLine
        self.statusLabel = statusLabel
        self.statusColor = statusColor
        self.progress = progress
        self.alertIcon = alertIcon
        self.alertColor = alertColor
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header row
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(accentColor)
                    .frame(width: 36, height: 36)
                    .glassEffect(.regular.tint(accentColor.opacity(0.2)), in: .circle)

                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Spacer()

                // Alert pulse icon
                if let alertIcon {
                    Image(systemName: alertIcon)
                        .font(.subheadline)
                        .foregroundStyle(alertColor)
                        .scaleEffect(alertPulse ? 1.15 : 1.0)
                        .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: alertPulse)
                        .onAppear { alertPulse = true }
                }

                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 10)

            Divider().padding(.horizontal, 16)

            // Metric row
            HStack(alignment: .bottom, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .lastTextBaseline, spacing: 3) {
                        Text(verbatim: primaryValue)
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                        if let unit = primaryUnit {
                            Text(LocalizedStringKey(unit))
                                .font(.callout.bold())
                                .foregroundStyle(.secondary)
                        }
                    }
                    Text(LocalizedStringKey(secondaryLine))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Status pill + optional ring
                VStack(alignment: .trailing, spacing: 8) {
                    if let statusLabel {
                        Text(LocalizedStringKey(statusLabel))
                            .font(.caption2.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .glassEffect(.regular.tint(statusColor.opacity(0.25)), in: Capsule())
                            .foregroundStyle(statusColor)
                    }

                    if let progress {
                        MiniProgressRing(progress: progress, color: accentColor)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 16)

            // Bottom progress bar
            if let progress {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(accentColor.opacity(0.1)).frame(height: 3)
                        Capsule()
                            .fill(accentColor)
                            .frame(width: geo.size.width * progress, height: 3)
                    }
                }
                .frame(height: 3)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.interactive().tint(accentColor.opacity(0.08)), in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
    }
}

// MARK: - Mini Progress Ring

struct MiniProgressRing: View {
    let progress: Double
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.15), lineWidth: 4)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6), value: progress)
        }
        .frame(width: 36, height: 36)
    }
}

// MARK: - Metric Card (small grid cards)

struct MetricCard: View {
    let icon: String
    let title: LocalizedStringKey
    let value: String
    let unit: LocalizedStringKey?
    let subtitle: String
    let progress: Double?
    let color: Color
    var statusColor: Color? = nil
    var pulse: Bool = false

    @State private var isPulsing = false

    init(icon: String, title: String, value: String, unit: String? = nil, subtitle: String = "", progress: Double? = nil, color: Color, statusColor: Color? = nil, pulse: Bool = false) {
        self.icon = icon
        self.title = LocalizedStringKey(title)
        self.value = value
        self.unit = unit.map { LocalizedStringKey($0) }
        self.subtitle = subtitle
        self.progress = progress
        self.color = color
        self.statusColor = statusColor
        self.pulse = pulse
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Icon + title
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(color)
                    .scaleEffect(pulse && isPulsing ? 1.2 : 1.0)
                    .animation(pulse ? .easeInOut(duration: 0.6).repeatForever(autoreverses: true) : .default, value: isPulsing)
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 6)

            // Value
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(verbatim: value)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                if let unit {
                    Text(unit)
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 14)

            // Subtitle / status
            HStack(spacing: 4) {
                Text(LocalizedStringKey(subtitle))
                    .font(.caption2)
                    .foregroundStyle(statusColor ?? .secondary)
                Spacer()
                if let progress {
                    MiniProgressRing(progress: progress, color: color)
                        .frame(width: 26, height: 26)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 4)
            .padding(.bottom, 14)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.interactive().tint(color.opacity(0.1)), in: RoundedRectangle(cornerRadius: 16))
        .onAppear { if pulse { isPulsing = true } }
    }
}

#Preview {
    MainAppView()
}
