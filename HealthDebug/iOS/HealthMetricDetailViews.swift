import SwiftUI
import SwiftData
import HealthDebugKit

// MARK: - Steps Detail View

struct StepsDetailView: View {
    @StateObject private var health = HealthKitManager.shared
    @StateObject private var rag = HealthRAG.shared
    @Environment(\.modelContext) private var context
    @Query(UserProfile.currentDescriptor()) private var profiles: [UserProfile]
    @Query(SleepConfig.currentDescriptor()) private var sleepConfigs: [SleepConfig]

    private var profile: UserProfile? { profiles.first }
    private let stepGoal: Double = 10_000

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Hero ring
                stepsRing

                AIInsightCard(domain: .dashboard)

                // Stats grid
                statsGrid

                // Smart actions
                smartActionsCard
            }
            .padding(.vertical)
        }
        .navigationTitle("Steps")
        .navigationBarTitleDisplayMode(.large)
        .onAppear { Task { await health.refreshAll() } }
    }

    private var stepsRing: some View {
        let progress = min(1.0, health.stepCount / stepGoal)
        let color = AppTheme.primary
        return ZStack {
            Circle()
                .stroke(color.opacity(0.15), lineWidth: 14)
                .frame(width: 160, height: 160)
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(color.gradient, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .frame(width: 160, height: 160)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.6), value: progress)
            VStack(spacing: 4) {
                Text(formatted(health.stepCount))
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
                Text("steps")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.top, 8)
    }

    private var statsGrid: some View {
        let distance = String(format: "%.2f km", health.stepCount * 0.0008)
        let activeMinutes = Int(health.stepCount / 100)
        let statusText: String = {
            let pct = health.stepCount / stepGoal
            if pct >= 1.0 { return "Goal Met" }
            if pct >= 0.5 { return "On Track" }
            return "Behind"
        }()
        let statusColor: Color = {
            let pct = health.stepCount / stepGoal
            if pct >= 1.0 { return AppTheme.primary }
            if pct >= 0.5 { return .orange }
            return .red
        }()

        return LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 12) {
            statCell(title: "Distance", value: distance, icon: "map.fill", color: AppTheme.primary)
            statCell(title: "Active Minutes", value: "\(activeMinutes) min", icon: "clock.fill", color: .orange)
            statCell(title: "Daily Goal", value: "10,000", icon: "flag.fill", color: AppTheme.secondary)
            statCellStatus(title: "Status", value: statusText, color: statusColor)
        }
        .padding(.horizontal)
    }

    private var smartActionsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Smart Actions", systemImage: "sparkles")
                .font(.headline).foregroundStyle(AppTheme.primary)
            Divider()
            GlassEffectContainer {
                VStack(spacing: 8) {
                    Button {
                        Task {
                            await rag.send(
                                "Why am I behind on steps today? My current count is \(Int(health.stepCount)).",
                                context: context, profile: profile, sleepConfig: sleepConfigs.first
                            )
                        }
                    } label: {
                        Label("Why am I behind on steps?", systemImage: "questionmark.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(AppTheme.primary)
                    .controlSize(.small)

                    Button {
                        Task {
                            await rag.send(
                                "What's a good walk target for me right now given \(Int(health.stepCount)) steps today?",
                                context: context, profile: profile, sleepConfig: sleepConfigs.first
                            )
                        }
                    } label: {
                        Label("What's a good walk target now?", systemImage: "figure.walk")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glass)
                    .controlSize(.small)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(AppTheme.primary.opacity(0.1)), in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
    }

    private func statCell(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.caption.bold())
                .foregroundStyle(color)
            Text(value)
                .font(.title3.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .glassEffect(.regular.tint(color.opacity(0.1)), in: RoundedRectangle(cornerRadius: 16))
    }

    private func statCellStatus(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: "chart.bar.fill")
                .font(.caption.bold())
                .foregroundStyle(color)
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .glassEffect(.regular.tint(color.opacity(0.1)), in: RoundedRectangle(cornerRadius: 16))
    }

    private func formatted(_ value: Double) -> String {
        value >= 1000
            ? String(format: "%.1fk", value / 1000)
            : String(format: "%.0f", value)
    }
}

// MARK: - Energy Detail View

struct EnergyDetailView: View {
    @StateObject private var health = HealthKitManager.shared
    @StateObject private var rag = HealthRAG.shared
    @Environment(\.modelContext) private var context
    @Query(UserProfile.currentDescriptor()) private var profiles: [UserProfile]
    @Query(SleepConfig.currentDescriptor()) private var sleepConfigs: [SleepConfig]

    private var profile: UserProfile? { profiles.first }
    private let kcalGoal: Double = 600

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                energyRing
                AIInsightCard(domain: .dashboard)
                statsGrid
                smartActionsCard
            }
            .padding(.vertical)
        }
        .navigationTitle("Active Energy")
        .navigationBarTitleDisplayMode(.large)
        .onAppear { Task { await health.refreshAll() } }
    }

    private var energyRing: some View {
        let progress = min(1.0, health.activeEnergy / kcalGoal)
        let color: Color = .orange
        return ZStack {
            Circle()
                .stroke(color.opacity(0.15), lineWidth: 14)
                .frame(width: 160, height: 160)
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(color.gradient, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .frame(width: 160, height: 160)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.6), value: progress)
            VStack(spacing: 4) {
                Text(String(format: "%.0f", health.activeEnergy))
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
                Text("kcal")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.top, 8)
    }

    private var statsGrid: some View {
        let burnRate = health.activeEnergy / 16.0 // rough kcal/hr over typical waking hours
        let bmr = (profile?.weightKg ?? 90) * 24.0
        let statusText: String = {
            let pct = health.activeEnergy / kcalGoal
            if pct >= 1.0 { return "Goal Met" }
            if pct >= 0.5 { return "On Track" }
            return "Behind"
        }()
        let statusColor: Color = {
            let pct = health.activeEnergy / kcalGoal
            if pct >= 1.0 { return AppTheme.primary }
            if pct >= 0.5 { return .orange }
            return .red
        }()

        return LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 12) {
            statCell(title: "Burn Rate", value: String(format: "%.0f kcal/hr", burnRate), icon: "flame.fill", color: .orange)
            statCell(title: "Daily Goal", value: "600 kcal", icon: "flag.fill", color: AppTheme.primary)
            statCellStatus(title: "Status", value: statusText, color: statusColor)
            statCell(title: "BMR Estimate", value: String(format: "%.0f kcal", bmr), icon: "person.fill", color: AppTheme.secondary)
        }
        .padding(.horizontal)
    }

    private var smartActionsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Smart Actions", systemImage: "sparkles")
                .font(.headline).foregroundStyle(AppTheme.primary)
            Divider()
            GlassEffectContainer {
                VStack(spacing: 8) {
                    Button {
                        Task {
                            await rag.send(
                                "Is my calorie burn of \(Int(health.activeEnergy)) kcal today healthy for my goals?",
                                context: context, profile: profile, sleepConfig: sleepConfigs.first
                            )
                        }
                    } label: {
                        Label("Is my calorie burn healthy?", systemImage: "heart.text.clipboard")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(.orange)
                    .controlSize(.small)

                    Button {
                        Task {
                            await rag.send(
                                "How can I increase my activity level today to burn more calories?",
                                context: context, profile: profile, sleepConfig: sleepConfigs.first
                            )
                        }
                    } label: {
                        Label("How can I increase activity?", systemImage: "figure.run")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glass)
                    .controlSize(.small)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(Color.orange.opacity(0.1)), in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
    }

    private func statCell(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.caption.bold())
                .foregroundStyle(color)
            Text(value)
                .font(.title3.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .glassEffect(.regular.tint(color.opacity(0.1)), in: RoundedRectangle(cornerRadius: 16))
    }

    private func statCellStatus(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: "chart.bar.fill")
                .font(.caption.bold())
                .foregroundStyle(color)
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .glassEffect(.regular.tint(color.opacity(0.1)), in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Heart Rate Detail View

struct HeartRateDetailView: View {
    @StateObject private var health = HealthKitManager.shared
    @StateObject private var rag = HealthRAG.shared
    @Environment(\.modelContext) private var context
    @Query(UserProfile.currentDescriptor()) private var profiles: [UserProfile]
    @Query(SleepConfig.currentDescriptor()) private var sleepConfigs: [SleepConfig]

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                heartHero
                AIInsightCard(domain: .dashboard)
                statsGrid
                smartActionsCard
            }
            .padding(.vertical)
        }
        .navigationTitle("Heart Rate")
        .navigationBarTitleDisplayMode(.large)
        .onAppear { Task { await health.refreshAll() } }
    }

    private var zoneInfo: (label: String, color: Color) {
        let bpm = health.heartRate
        if bpm < 60 { return ("Low", AppTheme.secondary) }
        if bpm <= 100 { return ("Normal", AppTheme.primary) }
        if bpm <= 120 { return ("Elevated", .orange) }
        return ("High", .red)
    }

    private var heartHero: some View {
        let (_, zoneColor) = zoneInfo
        return VStack(spacing: 12) {
            Image(systemName: "heart.fill")
                .font(.system(size: 56))
                .foregroundStyle(zoneColor)
                .symbolEffect(.pulse, isActive: true)

            HStack(spacing: 6) {
                Text(String(format: "%.0f", health.heartRate))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(zoneColor)
                Text("bpm")
                    .font(.title2.bold())
                    .foregroundStyle(.secondary)
            }

            // Zone badge
            Text(zoneInfo.label)
                .font(.caption.bold())
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .glassEffect(.regular.tint(zoneColor.opacity(0.3)), in: Capsule())
                .foregroundStyle(zoneColor)
        }
        .padding(.top, 16)
    }

    private var statsGrid: some View {
        let restingEst = health.heartRate * 0.85
        let (zoneName, zoneColor) = zoneInfo

        return LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 12) {
            statCell(title: "Current BPM", value: String(format: "%.0f", health.heartRate), icon: "heart.fill", color: .red)
            statCellColored(title: "Zone", value: zoneName, icon: "waveform.path.ecg", color: zoneColor)
            statCell(title: "Resting Est.", value: String(format: "%.0f bpm", restingEst), icon: "bed.double.fill", color: AppTheme.secondary)
            statCell(title: "HRV", value: "Varies", icon: "chart.xyaxis.line", color: AppTheme.accent)
        }
        .padding(.horizontal)
    }

    private var smartActionsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Smart Actions", systemImage: "sparkles")
                .font(.headline).foregroundStyle(AppTheme.primary)
            Divider()
            GlassEffectContainer {
                VStack(spacing: 8) {
                    Button {
                        Task {
                            await rag.send(
                                "Is my heart rate of \(Int(health.heartRate)) bpm normal for my age and health status?",
                                context: context, profile: profile, sleepConfig: sleepConfigs.first
                            )
                        }
                    } label: {
                        Label("Is my heart rate normal?", systemImage: "heart.text.clipboard")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(.red)
                    .controlSize(.small)

                    Button {
                        Task {
                            await rag.send(
                                "What factors affect heart rate and how can I optimize mine?",
                                context: context, profile: profile, sleepConfig: sleepConfigs.first
                            )
                        }
                    } label: {
                        Label("What affects heart rate?", systemImage: "questionmark.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glass)
                    .controlSize(.small)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(Color.red.opacity(0.1)), in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
    }

    private func statCell(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.caption.bold())
                .foregroundStyle(color)
            Text(value)
                .font(.title3.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .glassEffect(.regular.tint(color.opacity(0.1)), in: RoundedRectangle(cornerRadius: 16))
    }

    private func statCellColored(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.caption.bold())
                .foregroundStyle(color)
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .glassEffect(.regular.tint(color.opacity(0.1)), in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Sleep Detail View (replaces the one in CardDetailViews)

struct SleepDetailView: View {
    @StateObject private var health = HealthKitManager.shared
    @StateObject private var rag = HealthRAG.shared
    @Environment(\.modelContext) private var context
    @Query(UserProfile.currentDescriptor()) private var profiles: [UserProfile]
    @Query(SleepConfig.currentDescriptor()) private var sleepConfigs: [SleepConfig]

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                sleepRing
                AIInsightCard(domain: .shutdown)
                statsGrid
                smartActionsCard
            }
            .padding(.vertical)
        }
        .navigationTitle("Sleep")
        .navigationBarTitleDisplayMode(.large)
        .onAppear { Task { await health.refreshAll() } }
    }

    private var qualityInfo: (label: String, color: Color) {
        let h = health.sleepHours
        if h >= 7 { return ("Good", AppTheme.primary) }
        if h >= 5 { return ("Low", .orange) }
        return ("Critical", .red)
    }

    private var sleepRing: some View {
        let progress = min(1.0, health.sleepHours / 8.0)
        let (_, qualityColor) = qualityInfo
        return ZStack {
            Circle()
                .stroke(AppTheme.secondary.opacity(0.15), lineWidth: 14)
                .frame(width: 160, height: 160)
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(AppTheme.secondary.gradient, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .frame(width: 160, height: 160)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.6), value: progress)
            VStack(spacing: 6) {
                HStack(spacing: 2) {
                    Text(String(format: "%.1f", health.sleepHours))
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                    Text("h")
                        .font(.title2.bold())
                        .foregroundStyle(.secondary)
                }
                Text(qualityInfo.label)
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .glassEffect(.regular.tint(qualityColor.opacity(0.3)), in: Capsule())
                    .foregroundStyle(qualityColor)
            }
        }
        .padding(.top, 8)
    }

    private var statsGrid: some View {
        let qualityScore = min(100.0, (health.sleepHours / 8.0) * 100)
        let (qualityLabel, qualityColor) = qualityInfo

        return LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 12) {
            statCell(title: "Hours Slept", value: String(format: "%.1f h", health.sleepHours), icon: "moon.zzz.fill", color: AppTheme.secondary)
            statCell(title: "Target", value: "8 h", icon: "flag.fill", color: AppTheme.primary)
            statCell(title: "Quality Score", value: String(format: "%.0f%%", qualityScore), icon: "chart.bar.fill", color: qualityColor)
            statCell(title: "Consistency", value: qualityLabel, icon: "repeat", color: qualityColor)
        }
        .padding(.horizontal)
    }

    private var smartActionsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Smart Actions", systemImage: "sparkles")
                .font(.headline).foregroundStyle(AppTheme.primary)
            Divider()
            GlassEffectContainer {
                VStack(spacing: 8) {
                    Button {
                        Task {
                            await rag.send(
                                "How can I improve my sleep? I got \(String(format: "%.1f", health.sleepHours)) hours last night.",
                                context: context, profile: profile, sleepConfig: sleepConfigs.first
                            )
                        }
                    } label: {
                        Label("How to improve my sleep?", systemImage: "moon.stars.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(AppTheme.secondary)
                    .controlSize(.small)

                    Button {
                        Task {
                            await rag.send(
                                "How does my \(String(format: "%.1f", health.sleepHours)) hours of sleep affect my health metrics today?",
                                context: context, profile: profile, sleepConfig: sleepConfigs.first
                            )
                        }
                    } label: {
                        Label("How does sleep affect my health today?", systemImage: "waveform.path.ecg")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glass)
                    .controlSize(.small)

                    Button {
                        Task {
                            await rag.send(
                                "Based on my sleep patterns and health, what time should I sleep tonight?",
                                context: context, profile: profile, sleepConfig: sleepConfigs.first
                            )
                        }
                    } label: {
                        Label("What time should I sleep tonight?", systemImage: "clock.badge.questionmark")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glass)
                    .controlSize(.small)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(AppTheme.secondary.opacity(0.1)), in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
    }

    private func statCell(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.caption.bold())
                .foregroundStyle(color)
            Text(value)
                .font(.title3.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .glassEffect(.regular.tint(color.opacity(0.1)), in: RoundedRectangle(cornerRadius: 16))
    }
}
