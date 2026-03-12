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
                    }
                    .buttonStyle(.plain)
                    NavigationLink(destination: NutritionDetailView()) {
                        nutritionCard
                    }
                    .buttonStyle(.plain)
                    NavigationLink(destination: CaffeineDetailView()) {
                        caffeineCard
                    }
                    .buttonStyle(.plain)
                    NavigationLink(destination: ShutdownDetailView()) {
                        shutdownCard
                    }
                    .buttonStyle(.plain)
                    NavigationLink(destination: StandTimerDetailView()) {
                        standTimerCard
                    }
                    .buttonStyle(.plain)
                    NavigationLink(destination: ZeppDetailView()) {
                        zeppCard
                    }
                    .buttonStyle(.plain)
                    NavigationLink(destination: SleepDetailView()) {
                        sleepCard
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical)
        }
        .refreshable {
            await health.refreshAll()
        }
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
            if let profile = profiles.first {
                hydration.dailyGoal = profile.dailyWaterGoalMl
            }
            nutritionMgr.refresh(context: context)
            caffeineMgr.refresh(context: context)
            shutdownMgr.startCountdown(config: sleepConfigs.first)
            standTimer.refreshTodayCount(context: context)
        }
        } // end NavigationStack
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
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button(action: {
                Task {
                    try? await health.requestAuthorization()
                    await health.refreshAll()
                }
            }) {
                Text(LocalizedStringKey("Authorize HealthKit"))
            }
            .buttonStyle(.glassProminent)
            .tint(AppTheme.primary)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .glassEffect(.regular.tint(AppTheme.secondary.opacity(0.3)), in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
    }

    // MARK: - Metrics Grid

    private var metricsGrid: some View {
        LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 12) {
            NavigationLink(destination: StepsDetailView()) {
                MetricCard(icon: "figure.walk", title: "Steps", value: formatted(health.stepCount), color: AppTheme.primary)
            }
            .buttonStyle(.plain)

            NavigationLink(destination: EnergyDetailView()) {
                MetricCard(icon: "flame.fill", title: "Active Energy", value: formatted(health.activeEnergy), unit: "kcal", color: .orange)
            }
            .buttonStyle(.plain)

            NavigationLink(destination: HeartRateDetailView()) {
                MetricCard(icon: "heart.fill", title: "Heart Rate", value: formatted(health.heartRate), unit: "bpm", color: .red)
            }
            .buttonStyle(.plain)

            NavigationLink(destination: SleepDetailView()) {
                MetricCard(icon: "moon.zzz.fill", title: "Sleep", value: String(format: "%.1f", health.sleepHours), unit: "hours", color: AppTheme.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
    }

    // MARK: - Hydration Card

    private var hydrationCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(LocalizedStringKey("Hydration"), systemImage: "drop.fill")
                .font(.headline)
                .foregroundStyle(AppTheme.secondary)
            Divider()
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(hydration.todayTotal) ml")
                        .font(.title3.bold())
                    Text("/ \(hydration.dailyGoal) ml")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let profile = profiles.first {
                    let status = hydration.status(profile: profile)
                    let color: Color = {
                        switch status {
                        case .onTrack, .goalReached: return AppTheme.primary
                        case .slightlyBehind: return .orange
                        case .dehydrated: return .red
                        }
                    }()
                    Text(LocalizedStringKey(status.rawValue))
                        .font(.caption.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .glassEffect(.regular.tint(color.opacity(0.3)), in: Capsule())
                        .foregroundStyle(color)
                }
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            ProgressView(value: min(1.0, Double(hydration.todayTotal) / Double(max(1, hydration.dailyGoal))))
                .tint(AppTheme.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(AppTheme.secondary.opacity(0.15)), in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
    }

    // MARK: - Nutrition Card

    private var nutritionCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(LocalizedStringKey("Nutrition"), systemImage: "fork.knife")
                .font(.headline)
                .foregroundStyle(nutritionStatusColor)
            Divider()
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(LocalizedStringKey(nutritionMgr.safetyStatus.rawValue))
                        .font(.title3.bold())
                        .foregroundStyle(nutritionStatusColor)
                    HStack(spacing: 4) {
                        Text("\(nutritionMgr.todaySafeCount)")
                            .foregroundStyle(AppTheme.primary)
                        Text(LocalizedStringKey("safe"))
                        Text("·").foregroundStyle(.tertiary)
                        Text("\(nutritionMgr.todayUnsafeCount)")
                            .foregroundStyle(nutritionMgr.todayUnsafeCount > 0 ? .red : .secondary)
                        Text(LocalizedStringKey("unsafe"))
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                Spacer()
                Text(String(format: "%.0f%%", nutritionMgr.safetyScore))
                    .font(.title2.bold())
                    .foregroundStyle(nutritionStatusColor)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            if !nutritionMgr.todayTriggers.isEmpty {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                        .font(.caption)
                    HStack(spacing: 4) {
                        ForEach(nutritionMgr.todayTriggers.sorted(), id: \.self) { trigger in
                            Text(LocalizedStringKey(trigger))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.red.opacity(0.1), in: Capsule())
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.red)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(nutritionStatusColor.opacity(0.15)), in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
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
        VStack(alignment: .leading, spacing: 8) {
            Label(LocalizedStringKey("Caffeine"), systemImage: "cup.and.saucer.fill")
                .font(.headline)
                .foregroundStyle(caffeineMgr.fattyLiverAlert ? .red : AppTheme.primary)
            Divider()
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(LocalizedStringKey(caffeineMgr.transitionStatus.rawValue))
                        .font(.title3.bold())
                        .foregroundStyle(caffeineStatusColor)
                    HStack(spacing: 4) {
                        Text("\(caffeineMgr.todayCleanCount)")
                            .foregroundStyle(AppTheme.primary)
                        Text(LocalizedStringKey("clean"))
                        Text("·").foregroundStyle(.tertiary)
                        Text("\(caffeineMgr.todaySugarCount)")
                            .foregroundStyle(caffeineMgr.todaySugarCount > 0 ? .red : .secondary)
                        Text(LocalizedStringKey("sugar"))
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                Spacer()
                Text(String(format: "%.0f%%", caffeineMgr.cleanTransitionPercent))
                    .font(.title2.bold())
                    .foregroundStyle(caffeineStatusColor)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint((caffeineMgr.fattyLiverAlert ? Color.red : AppTheme.primary).opacity(0.15)), in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
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
        VStack(alignment: .leading, spacing: 8) {
            Label(LocalizedStringKey("System Shutdown"), systemImage: "moon.fill")
                .font(.headline)
                .foregroundStyle(shutdownMgr.state == .active ? .orange : AppTheme.secondary)
            Divider()
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if shutdownMgr.state == .active {
                        Text(LocalizedStringKey("ACTIVE — No Food"))
                            .font(.title3.bold())
                            .foregroundStyle(.orange)
                        HStack(spacing: 4) {
                            Text(ShutdownManager.formatCountdown(shutdownMgr.secondsUntilSleep))
                            Text(LocalizedStringKey("until sleep"))
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    } else {
                        HStack(spacing: 4) {
                            Text(LocalizedStringKey("Shutdown in"))
                            Text(ShutdownManager.formatCountdown(shutdownMgr.secondsUntilShutdown))
                        }
                        .font(.title3.bold())
                        Text(LocalizedStringKey("You can eat normally"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Image(systemName: shutdownMgr.state == .active ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(shutdownMgr.state == .active ? .orange : AppTheme.primary)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint((shutdownMgr.state == .active ? Color.orange : AppTheme.secondary).opacity(0.15)), in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
    }

    // MARK: - Stand Timer Card

    private var standTimerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(LocalizedStringKey("Stand Timer"), systemImage: "figure.stand")
                .font(.headline)
                .foregroundStyle(AppTheme.accent)
            Divider()
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    switch standTimer.state {
                    case .idle:
                        Text(LocalizedStringKey("Inactive"))
                            .font(.title3.bold())
                    case .sitting:
                        let mins = Int(standTimer.sitSecondsRemaining) / 60
                        HStack(spacing: 4) {
                            Text("\(mins)")
                            Text(LocalizedStringKey("min left"))
                        }
                        .font(.title3.bold())
                    case .standAlert:
                        Text(LocalizedStringKey("Stand Now!"))
                            .font(.title3.bold())
                            .foregroundStyle(.orange)
                    case .walking:
                        let mins = standTimer.walkSecondsRemaining / 60
                        let secs = standTimer.walkSecondsRemaining % 60
                        Text(String(format: "%d:%02d", mins, secs))
                            .font(.title3.bold())
                            .foregroundStyle(AppTheme.accent)
                    }
                    HStack(spacing: 4) {
                        Text("\(standTimer.todayCompleted) / \(StandTimerManager.dailyTarget)")
                        Text(LocalizedStringKey("sessions"))
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                Spacer()
                if standTimer.state == .idle {
                    Button {
                        standTimer.startCycle()
                    } label: {
                        Image(systemName: "play.fill")
                    }
                    .buttonStyle(.glass)
                }
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(AppTheme.accent.opacity(0.15)), in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
    }

    // MARK: - Zepp Card

    private var zeppCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(LocalizedStringKey("Zepp Scale"), systemImage: "scalemass.fill")
                .font(.headline)
                .foregroundStyle(AppTheme.primary)
            Divider()
            HStack {
                HStack(spacing: 4) {
                    Text(String(format: "%.1f", health.zeppMetrics.weight))
                        .font(.title3.bold())
                    Text(LocalizedStringKey("kg"))
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let date = health.zeppMetrics.lastUpdated {
                    HStack(spacing: 4) {
                        Text(LocalizedStringKey("Last synced"))
                        Text(date.formatted(.relative(presentation: .named)))
                    }
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                }
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(AppTheme.primary.opacity(0.15)), in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
    }

    // MARK: - Sleep Card

    private var sleepCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(LocalizedStringKey("Last Night"), systemImage: "bed.double.fill")
                .font(.headline)
                .foregroundStyle(AppTheme.secondary)
            Divider()
            HStack {
                HStack(spacing: 4) {
                    Text(String(format: "%.1f", health.sleepHours))
                    Text(LocalizedStringKey("hours"))
                }
                .font(.title3.bold())
                Spacer()
                sleepQualityBadge
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(AppTheme.secondary.opacity(0.15)), in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
    }

    private var sleepQualityBadge: some View {
        let (label, color): (String, Color) = {
            switch health.sleepHours {
            case 7...: return ("Good", AppTheme.primary)
            case 5..<7: return ("Low", .orange)
            default: return ("Critical", .red)
            }
        }()
        return Text(LocalizedStringKey(label))
            .font(.caption.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .glassEffect(.regular.tint(color.opacity(0.3)), in: Capsule())
            .foregroundStyle(color)
    }

    private func formatted(_ value: Double) -> String {
        value >= 1000
            ? String(format: "%.1fk", value / 1000)
            : String(format: "%.0f", value)
    }
}

// MARK: - Metric Card

struct MetricCard: View {
    let icon: String
    let title: LocalizedStringKey
    let value: String
    let unit: LocalizedStringKey?
    let color: Color

    init(icon: String, title: LocalizedStringKey, value: String, unit: LocalizedStringKey? = nil, color: Color) {
        self.icon = icon
        self.title = title
        self.value = value
        self.unit = unit
        self.color = color
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 2) {
                Text(verbatim: value)
                    .font(.title2.bold())
                if let unit {
                    Text(unit)
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 16))
        .overlay(alignment: .topTrailing) {
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(8)
        }
    }
}

#Preview {
    MainAppView()
}
