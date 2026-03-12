import SwiftUI
import SwiftData
import HealthDebugKit

// MARK: - Watch Screen

enum WatchScreen: String, CaseIterable, Identifiable {
    var id: String { rawValue }
    case summary    = "Summary"
    case hydration  = "Hydration"
    case focus      = "Focus"
    case caffeine   = "Caffeine"
    case sleep      = "Sleep"
    case aiScore    = "Health Score"
}

// MARK: - Root Content View

struct WatchContentView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var health = HealthKitManager.shared
    @StateObject private var hydration = HydrationManager.shared
    @StateObject private var standTimer = StandTimerManager.shared
    @StateObject private var caffeine = CaffeineManager.shared
    @StateObject private var nutrition = NutritionManager.shared
    @Query(UserProfile.currentDescriptor()) private var profiles: [UserProfile]
    @Query(SleepConfig.currentDescriptor()) private var sleepConfigs: [SleepConfig]

    var body: some View {
        NavigationStack {
            List {
                // Health Score tile
                NavigationLink(destination: WatchHealthScoreView()) {
                    healthScoreTile
                }
                .listRowBackground(Color.clear)

                // Hydration tile
                NavigationLink(destination: WatchHydrationView()) {
                    WatchMetricRow(
                        icon: "drop.fill", color: .blue,
                        title: "Hydration",
                        value: "\(hydration.todayTotal) ml",
                        caption: profiles.first.map { "/ \($0.dailyWaterGoalMl) ml" } ?? "/ 2500 ml"
                    )
                }

                // Focus tile
                NavigationLink(destination: WatchFocusView()) {
                    WatchMetricRow(
                        icon: "timer", color: .orange,
                        title: "Focus",
                        value: "\(standTimer.todayCompleted)/\(StandTimerManager.dailyTarget)",
                        caption: standTimer.phase == .idle ? "Idle" : standTimer.phase.rawValue.capitalized
                    )
                }

                // Caffeine tile
                NavigationLink(destination: WatchCaffeineView()) {
                    WatchMetricRow(
                        icon: "cup.and.saucer.fill", color: .brown,
                        title: "Caffeine",
                        value: String(format: "%.0f%%", caffeine.cleanTransitionPercent),
                        caption: caffeine.transitionStatus.rawValue
                    )
                }

                // Steps tile
                NavigationLink(destination: WatchStepsView()) {
                    WatchMetricRow(
                        icon: "figure.walk", color: .teal,
                        title: "Steps",
                        value: health.stepCount >= 1000 ? String(format: "%.1fk", health.stepCount / 1000) : "\(Int(health.stepCount))",
                        caption: "\(Int(min(100, health.stepCount / 100)))% of goal"
                    )
                }

                // Sleep tile
                WatchMetricRow(
                    icon: "moon.zzz.fill", color: .indigo,
                    title: "Sleep",
                    value: String(format: "%.1f h", health.sleepHours),
                    caption: health.sleepHours >= 7 ? "Good" : "Low"
                )
                .listRowBackground(Color.clear)
            }
            .navigationTitle("Health")
        }
        .onAppear {
            hydration.refresh(context: context)
            if let p = profiles.first { hydration.dailyGoal = p.dailyWaterGoalMl }
            caffeine.refresh(context: context)
            standTimer.refreshTodayCount(context: context)
            nutrition.refresh(context: context)
        }
    }

    private var healthScoreTile: some View {
        let score = computeScore()
        let color: Color = score >= 80 ? .green : score >= 50 ? .orange : .red
        return HStack(spacing: 12) {
            ZStack {
                Circle().stroke(color.opacity(0.2), lineWidth: 4).frame(width: 44, height: 44)
                Circle()
                    .trim(from: 0, to: CGFloat(score) / 100.0)
                    .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 44, height: 44)
                    .rotationEffect(.degrees(-90))
                Text("\(score)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Health Score")
                    .font(.system(size: 14, weight: .semibold))
                Text(score >= 80 ? "Excellent" : score >= 60 ? "Good" : score >= 40 ? "Fair" : "Needs Attention")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private func computeScore() -> Int {
        var s = 0.0; var t = 0.0
        let hydPct = profiles.first.map { min(1.0, Double(hydration.todayTotal) / Double(max(1, $0.dailyWaterGoalMl))) } ?? 0
        s += hydPct * 20; t += 20
        s += (nutrition.safetyScore / 100.0) * 20; t += 20
        s += (caffeine.cleanTransitionPercent / 100.0) * 20; t += 20
        s += min(1.0, Double(standTimer.todayCompleted) / Double(StandTimerManager.dailyTarget)) * 20; t += 20
        s += min(1.0, health.sleepHours / 8.0) * 20; t += 20
        return t > 0 ? Int((s / t) * 100) : 0
    }
}

// MARK: - Shared Row Component

struct WatchMetricRow: View {
    let icon: String; let color: Color
    let title: String; let value: String; let caption: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                Text(caption)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Health Score Detail

struct WatchHealthScoreView: View {
    @StateObject private var health = HealthKitManager.shared
    @StateObject private var hydration = HydrationManager.shared
    @StateObject private var standTimer = StandTimerManager.shared
    @StateObject private var caffeine = CaffeineManager.shared
    @StateObject private var nutrition = NutritionManager.shared
    @Query(UserProfile.currentDescriptor()) private var profiles: [UserProfile]

    private var score: Int {
        var s = 0.0; var t = 0.0
        let h = profiles.first.map { min(1.0, Double(hydration.todayTotal) / Double(max(1, $0.dailyWaterGoalMl))) } ?? 0
        s += h * 20; t += 20
        s += (nutrition.safetyScore / 100.0) * 20; t += 20
        s += (caffeine.cleanTransitionPercent / 100.0) * 20; t += 20
        s += min(1.0, Double(standTimer.todayCompleted) / Double(StandTimerManager.dailyTarget)) * 20; t += 20
        s += min(1.0, health.sleepHours / 8.0) * 20; t += 20
        return t > 0 ? Int((s / t) * 100) : 0
    }

    private var scoreColor: Color { score >= 80 ? .green : score >= 50 ? .orange : .red }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                // Score ring
                ZStack {
                    Circle().stroke(scoreColor.opacity(0.15), lineWidth: 10).frame(width: 80, height: 80)
                    Circle()
                        .trim(from: 0, to: CGFloat(score) / 100.0)
                        .stroke(scoreColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                    Text("\(score)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(scoreColor)
                }

                Text(score >= 80 ? "Excellent" : score >= 60 ? "Good" : score >= 40 ? "Fair" : "Needs Attention")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(scoreColor)

                // Component bars
                VStack(spacing: 8) {
                    watchBar(label: "Hydration", color: .blue,
                        value: profiles.first.map { min(1.0, Double(hydration.todayTotal) / Double(max(1, $0.dailyWaterGoalMl))) } ?? 0)
                    watchBar(label: "Nutrition", color: .green, value: nutrition.safetyScore / 100.0)
                    watchBar(label: "Focus", color: .orange,
                        value: min(1.0, Double(standTimer.todayCompleted) / Double(StandTimerManager.dailyTarget)))
                    watchBar(label: "Sleep", color: .indigo, value: min(1.0, health.sleepHours / 8.0))
                }
            }
            .padding()
        }
        .navigationTitle("Health Score")
    }

    private func watchBar(label: String, color: Color, value: Double) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(label).font(.system(size: 11))
                Spacer()
                Text("\(Int(value * 100))%").font(.system(size: 11, weight: .semibold))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2).fill(color.opacity(0.2)).frame(height: 4)
                    RoundedRectangle(cornerRadius: 2).fill(color)
                        .frame(width: geo.size.width * max(0, min(1, value)), height: 4)
                }
            }.frame(height: 4)
        }
    }
}

// MARK: - Hydration Detail

struct WatchHydrationView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var hydration = HydrationManager.shared
    @Query(UserProfile.currentDescriptor()) private var profiles: [UserProfile]

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                // Current value
                VStack(spacing: 2) {
                    Text("\(hydration.todayTotal)")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.blue)
                    Text("ml today")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    if let p = profiles.first {
                        Text(hydration.status(profile: p).rawValue)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(hydration.status(profile: p) == .goalReached ? .green : .orange)
                    }
                }

                // Quick log buttons
                VStack(spacing: 8) {
                    Button {
                        hydration.logWater(150, source: "watch", context: context, profile: profiles.first)
                    } label: {
                        Label("+150ml", systemImage: "drop.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent).tint(.blue)

                    Button {
                        hydration.logWater(250, source: "watch", context: context, profile: profiles.first)
                    } label: {
                        Label("+250ml", systemImage: "drop.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent).tint(.blue)

                    Button {
                        hydration.logWater(500, source: "watch", context: context, profile: profiles.first)
                    } label: {
                        Label("+500ml", systemImage: "drop.degreesign.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
        }
        .navigationTitle("Hydration")
        .onAppear { hydration.refresh(context: context) }
    }
}

// MARK: - Focus Detail

struct WatchFocusView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var timer = StandTimerManager.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                // Session count
                VStack(spacing: 2) {
                    Text("\(timer.todayCompleted)")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.orange)
                    Text("of \(StandTimerManager.dailyTarget) sessions")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                // Timer if active
                if timer.phase != .idle {
                    Text(String(format: "%02d:%02d",
                                Int(timer.secondsRemaining) / 60,
                                Int(timer.secondsRemaining) % 60))
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundStyle(.orange)
                    Text(timer.phase.rawValue.capitalized)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                // Action buttons
                if timer.phase == .idle {
                    Button {
                        timer.startCycle()
                    } label: {
                        Label("Start Focus", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent).tint(.orange)
                } else if timer.phase == .work {
                    Button {
                        timer.startBreak()
                    } label: {
                        Label("Take Break", systemImage: "pause.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
        }
        .navigationTitle("Focus")
        .onAppear { timer.refreshTodayCount(context: context) }
    }
}

// MARK: - Caffeine Detail

struct WatchCaffeineView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var caffeine = CaffeineManager.shared
    @Query(UserProfile.currentDescriptor()) private var profiles: [UserProfile]

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                VStack(spacing: 2) {
                    Text(String(format: "%.0f%%", caffeine.cleanTransitionPercent))
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(caffeine.cleanTransitionPercent >= 70 ? .green : .orange)
                    Text("clean transition")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Text(caffeine.transitionStatus.rawValue)
                        .font(.system(size: 10, weight: .semibold))
                }

                Text("\(caffeine.todayCleanCount) clean · \(caffeine.todaySugarCount) sugar")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)

                Button {
                    _ = caffeine.logCaffeine(.espresso, context: context, profile: profiles.first)
                } label: {
                    Label("Log Espresso", systemImage: "cup.and.saucer.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent).tint(.brown)

                Button {
                    _ = caffeine.logCaffeine(.blackCoffee, context: context, profile: profiles.first)
                } label: {
                    Label("Log Coffee", systemImage: "mug.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
        .navigationTitle("Caffeine")
        .onAppear { caffeine.refresh(context: context) }
    }
}

// MARK: - Steps Detail

struct WatchStepsView: View {
    @StateObject private var health = HealthKitManager.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                VStack(spacing: 2) {
                    Text(health.stepCount >= 1000 ? String(format: "%.1fk", health.stepCount / 1000) : "\(Int(health.stepCount))")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.teal)
                    Text("steps today")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.0f%% of goal", min(100, health.stepCount / 100)))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(health.stepCount >= 10000 ? .green : .orange)
                }

                VStack(spacing: 6) {
                    HStack {
                        Image(systemName: "flame.fill").foregroundStyle(.orange)
                        Text(String(format: "%.0f kcal", health.activeEnergy))
                            .font(.system(size: 13, weight: .semibold))
                    }
                    HStack {
                        Image(systemName: "heart.fill").foregroundStyle(.red)
                        Text("\(Int(health.heartRate)) BPM")
                            .font(.system(size: 13, weight: .semibold))
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Movement")
    }
}

#Preview {
    WatchContentView()
}
