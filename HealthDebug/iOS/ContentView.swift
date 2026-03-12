import SwiftUI
import SwiftData
import HealthDebugKit

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var health = HealthKitManager.shared
    @StateObject private var standTimer = StandTimerManager.shared
    @StateObject private var hydration = HydrationManager.shared
    @StateObject private var shutdownMgr = ShutdownManager.shared
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
                        metricsGrid
                        hydrationCard
                        shutdownCard
                        standTimerCard
                        zeppCard
                        sleepCard
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                if let profile = profiles.first {
                    ProfileSettingsView(profile: profile, sleepConfig: sleepConfigs.first)
                }
            }
            .refreshable {
                await health.refreshAll()
            }
        }
    }

    // MARK: - Auth Card

    private var authCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "lock.shield")
                .font(.system(size: 40))
                .foregroundStyle(AppTheme.secondary)
            Text("HealthKit Access Required")
                .font(.headline)
            Text("Tap to authorize reading your health data.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Authorize HealthKit") {
                Task {
                    try? await health.requestAuthorization()
                    await health.refreshAll()
                }
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
            MetricCard(icon: "figure.walk", title: "Steps", value: formatted(health.stepCount), color: AppTheme.primary)
            MetricCard(icon: "flame.fill", title: "Active Energy", value: "\(formatted(health.activeEnergy)) kcal", color: .orange)
            MetricCard(icon: "heart.fill", title: "Heart Rate", value: "\(formatted(health.heartRate)) bpm", color: .red)
            MetricCard(icon: "moon.zzz.fill", title: "Sleep", value: String(format: "%.1fh", health.sleepHours), color: AppTheme.secondary)
        }
        .padding(.horizontal)
    }

    // MARK: - Hydration Card

    private var hydrationCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Hydration", systemImage: "drop.fill")
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
                    Text(status.rawValue)
                        .font(.caption.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .glassEffect(.regular.tint(color.opacity(0.3)), in: Capsule())
                        .foregroundStyle(color)
                }
            }
            ProgressView(value: min(1.0, Double(hydration.todayTotal) / Double(max(1, hydration.dailyGoal))))
                .tint(AppTheme.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(AppTheme.secondary.opacity(0.15)), in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
        .onAppear {
            hydration.refresh(context: context)
            if let profile = profiles.first {
                hydration.dailyGoal = profile.dailyWaterGoalMl
            }
        }
    }

    // MARK: - Shutdown Card

    private var shutdownCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("System Shutdown", systemImage: "moon.fill")
                .font(.headline)
                .foregroundStyle(shutdownMgr.state == .active ? .orange : AppTheme.secondary)
            Divider()
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if shutdownMgr.state == .active {
                        Text("ACTIVE — No Food")
                            .font(.title3.bold())
                            .foregroundStyle(.orange)
                        Text(ShutdownManager.formatCountdown(shutdownMgr.secondsUntilSleep) + " until sleep")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Shutdown in " + ShutdownManager.formatCountdown(shutdownMgr.secondsUntilShutdown))
                            .font(.title3.bold())
                        Text("You can eat normally")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Image(systemName: shutdownMgr.state == .active ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(shutdownMgr.state == .active ? .orange : AppTheme.primary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint((shutdownMgr.state == .active ? Color.orange : AppTheme.secondary).opacity(0.15)), in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
        .onAppear {
            shutdownMgr.startCountdown(config: sleepConfigs.first)
        }
    }

    // MARK: - Stand Timer Card

    private var standTimerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Stand Timer", systemImage: "figure.stand")
                .font(.headline)
                .foregroundStyle(AppTheme.accent)
            Divider()
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    switch standTimer.state {
                    case .idle:
                        Text("Inactive")
                            .font(.title3.bold())
                    case .sitting:
                        let mins = Int(standTimer.sitSecondsRemaining) / 60
                        Text("\(mins) min left")
                            .font(.title3.bold())
                    case .standAlert:
                        Text("Stand Now!")
                            .font(.title3.bold())
                            .foregroundStyle(.orange)
                    case .walking:
                        let mins = standTimer.walkSecondsRemaining / 60
                        let secs = standTimer.walkSecondsRemaining % 60
                        Text(String(format: "%d:%02d", mins, secs))
                            .font(.title3.bold())
                            .foregroundStyle(AppTheme.accent)
                    }
                    Text("\(standTimer.todayCompleted) / \(StandTimerManager.dailyTarget) sessions")
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
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(AppTheme.accent.opacity(0.15)), in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
        .onAppear {
            standTimer.refreshTodayCount(context: context)
        }
    }

    // MARK: - Zepp Card

    private var zeppCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Zepp Scale", systemImage: "scalemass.fill")
                .font(.headline)
                .foregroundStyle(AppTheme.primary)
            Divider()
            HStack {
                VStack(alignment: .leading) {
                    Text("Weight")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.1f kg", health.zeppMetrics.weight))
                        .font(.title3.bold())
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Body Fat")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.1f%%", health.zeppMetrics.bodyFatPercent))
                        .font(.title3.bold())
                }
            }
            if let date = health.zeppMetrics.lastUpdated {
                Text("Last synced: \(date.formatted(.relative(presentation: .named)))")
                    .font(.caption2)
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
            Label("Last Night", systemImage: "bed.double.fill")
                .font(.headline)
                .foregroundStyle(AppTheme.secondary)
            Divider()
            HStack {
                Text(String(format: "%.1f hours", health.sleepHours))
                    .font(.title3.bold())
                Spacer()
                sleepQualityBadge
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
        return Text(label)
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
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .glassEffect(.regular.tint(color.opacity(0.15)), in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    ContentView()
}
