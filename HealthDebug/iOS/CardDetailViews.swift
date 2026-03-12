import SwiftUI
import SwiftData
import HealthDebugKit

// MARK: - Hydration Detail

struct HydrationDetailView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var hydration = HydrationManager.shared
    @StateObject private var rag = HealthRAG.shared
    @Query(UserProfile.currentDescriptor()) private var profiles: [UserProfile]
    @Query(WaterLog.todayDescriptor()) private var todayLogs: [WaterLog]

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                hydrationRing
                AIInsightCard(domain: .hydration)
                smartActionsCard
                logCard
                if !todayLogs.isEmpty { historyCard }
            }
            .padding(.vertical)
        }
        .navigationTitle(LocalizedStringKey("Hydration"))
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            hydration.refresh(context: context)
            if let p = profile { hydration.dailyGoal = p.dailyWaterGoalMl }
        }
    }

    private var hydrationRing: some View {
        let progress = min(1.0, Double(hydration.todayTotal) / Double(max(1, hydration.dailyGoal)))
        return ZStack {
            Circle()
                .stroke(AppTheme.secondary.opacity(0.15), lineWidth: 12)
                .frame(width: 160, height: 160)
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(AppTheme.secondary.gradient, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .frame(width: 160, height: 160)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
            VStack(spacing: 4) {
                Image(systemName: "drop.fill").font(.title).foregroundStyle(AppTheme.secondary)
                Text("\(hydration.todayTotal)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                Text(LocalizedStringKey("ml")).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.top, 8)
    }

    private var smartActionsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(LocalizedStringKey("Smart Actions"), systemImage: "sparkles")
                .font(.headline).foregroundStyle(AppTheme.primary)
            Divider()
            HStack(spacing: 8) {
                Button {
                    Task {
                        await rag.send(
                            "How is my hydration today and what should I do?",
                            context: context,
                            profile: profile,
                            sleepConfig: nil
                        )
                    }
                } label: {
                    Label(LocalizedStringKey("Analyze"), systemImage: "brain")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .tint(AppTheme.secondary)
                .controlSize(.small)

                Button {
                    Task {
                        await rag.send(
                            "Should I drink water now given my health state?",
                            context: context,
                            profile: profile,
                            sleepConfig: nil
                        )
                    }
                } label: {
                    Label(LocalizedStringKey("Should I drink?"), systemImage: "questionmark.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glass)
                .controlSize(.small)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(AppTheme.primary.opacity(0.1)), in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
    }

    private var logCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(LocalizedStringKey("Log Water"), systemImage: "plus.circle.fill")
                .font(.headline).foregroundStyle(AppTheme.secondary)
            Divider()
            LazyVGrid(columns: [.init(.flexible()), .init(.flexible()), .init(.flexible()), .init(.flexible())], spacing: 10) {
                ForEach([150, 250, 350, 500], id: \.self) { ml in
                    Button {
                        hydration.logWater(ml, source: "ios", context: context, profile: profile)
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "drop.fill").font(.title3).foregroundStyle(AppTheme.secondary)
                            Text("\(ml)ml").font(.caption2)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                    }
                    .buttonStyle(.glass)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(AppTheme.secondary.opacity(0.15)), in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
    }

    private var historyCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(LocalizedStringKey("Today's Logs"), systemImage: "list.bullet")
                .font(.headline).foregroundStyle(AppTheme.secondary)
            Divider()
            ForEach(todayLogs.prefix(10)) { log in
                HStack {
                    Image(systemName: "drop.fill").foregroundStyle(AppTheme.secondary).font(.caption)
                    Text("\(log.amount) ml").font(.subheadline)
                    Spacer()
                    Text(log.timestamp.formatted(date: .omitted, time: .shortened))
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(AppTheme.secondary.opacity(0.1)), in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
    }
}

// MARK: - Nutrition Detail

struct NutritionDetailView: View {
    var body: some View {
        NutritionView()
    }
}

// MARK: - Caffeine Detail

struct CaffeineDetailView: View {
    var body: some View {
        CaffeineView()
    }
}

// MARK: - Shutdown Detail

struct ShutdownDetailView: View {
    var body: some View {
        ShutdownView()
    }
}

// MARK: - Stand Timer Detail

struct StandTimerDetailView: View {
    var body: some View {
        StandTimerView()
    }
}

// MARK: - Zepp / Weight Detail

struct ZeppDetailView: View {
    @StateObject private var health = HealthKitManager.shared
    @StateObject private var rag = HealthRAG.shared
    @Environment(\.modelContext) private var context
    @Query(UserProfile.currentDescriptor()) private var profiles: [UserProfile]

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                weightCard
                AIInsightCard(domain: .dashboard)
                smartActionsCard
            }
            .padding(.vertical)
        }
        .navigationTitle(LocalizedStringKey("Weight"))
        .navigationBarTitleDisplayMode(.large)
    }

    private var weightCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "scalemass.fill")
                .font(.system(size: 44))
                .foregroundStyle(AppTheme.primary)
            HStack(spacing: 4) {
                Text(String(format: "%.1f", health.zeppMetrics.weight))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                Text(LocalizedStringKey("kg"))
                    .font(.title2.bold())
                    .foregroundStyle(.secondary)
            }
            if let date = health.zeppMetrics.lastUpdated {
                HStack(spacing: 4) {
                    Text(LocalizedStringKey("Last synced"))
                    Text(date.formatted(.relative(presentation: .named)))
                }
                .font(.caption)
                .foregroundStyle(.tertiary)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .glassEffect(.regular.tint(AppTheme.primary.opacity(0.1)), in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
    }

    private var smartActionsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(LocalizedStringKey("Smart Actions"), systemImage: "sparkles")
                .font(.headline).foregroundStyle(AppTheme.primary)
            Divider()
            Button {
                Task {
                    await rag.send(
                        "Analyze my weight trend and give me health advice",
                        context: context,
                        profile: profile,
                        sleepConfig: nil
                    )
                }
            } label: {
                Label(LocalizedStringKey("Analyze my weight"), systemImage: "brain")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .tint(AppTheme.primary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(AppTheme.primary.opacity(0.1)), in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
    }
}

// MARK: - Sleep Detail

struct SleepDetailView: View {
    @StateObject private var health = HealthKitManager.shared
    @StateObject private var rag = HealthRAG.shared
    @Environment(\.modelContext) private var context
    @Query(UserProfile.currentDescriptor()) private var profiles: [UserProfile]

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                sleepRing
                AIInsightCard(domain: .shutdown)
                smartActionsCard
            }
            .padding(.vertical)
        }
        .navigationTitle(LocalizedStringKey("Sleep"))
        .navigationBarTitleDisplayMode(.large)
    }

    private var sleepRing: some View {
        let hours = health.sleepHours
        let progress = min(1.0, hours / 9.0)
        let color: Color = hours >= 7 ? AppTheme.primary : hours >= 5 ? .orange : .red
        return ZStack {
            Circle()
                .stroke(color.opacity(0.15), lineWidth: 12)
                .frame(width: 160, height: 160)
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(color.gradient, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .frame(width: 160, height: 160)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
            VStack(spacing: 4) {
                Image(systemName: "moon.zzz.fill").font(.title).foregroundStyle(color)
                HStack(spacing: 2) {
                    Text(String(format: "%.1f", hours))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                    Text(LocalizedStringKey("h")).font(.caption.bold()).foregroundStyle(.secondary)
                }
            }
        }
        .padding(.top, 8)
    }

    private var smartActionsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(LocalizedStringKey("Smart Actions"), systemImage: "sparkles")
                .font(.headline).foregroundStyle(AppTheme.primary)
            Divider()
            HStack(spacing: 8) {
                Button {
                    Task {
                        await rag.send(
                            "Analyze my sleep quality and what I can improve",
                            context: context,
                            profile: profile,
                            sleepConfig: nil
                        )
                    }
                } label: {
                    Label(LocalizedStringKey("Analyze sleep"), systemImage: "brain")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .tint(AppTheme.secondary)
                .controlSize(.small)

                Button {
                    Task {
                        await rag.send(
                            "How does my sleep affect my health metrics today?",
                            context: context,
                            profile: profile,
                            sleepConfig: nil
                        )
                    }
                } label: {
                    Label(LocalizedStringKey("Health impact"), systemImage: "waveform.path.ecg")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glass)
                .controlSize(.small)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(AppTheme.primary.opacity(0.1)), in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
    }
}
