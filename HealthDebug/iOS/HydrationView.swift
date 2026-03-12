import SwiftUI
import SwiftData
import HealthDebugKit

struct HydrationView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var hydration = HydrationManager.shared
    @Query(UserProfile.currentDescriptor()) private var profiles: [UserProfile]
    @Query(WaterLog.todayDescriptor()) private var todayLogs: [WaterLog]

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    waterRing
                    quickLogButtons
                    if let profile {
                        scheduleCard(profile: profile)
                        goutCard(profile: profile)
                    }
                    if !todayLogs.isEmpty {
                        historyCard
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Hydration")
            .onAppear {
                hydration.refresh(context: context)
                if let profile {
                    hydration.dailyGoal = profile.dailyWaterGoalMl
                }
            }
        }
    }

    // MARK: - Water Ring

    private var waterRing: some View {
        let goal = max(1, hydration.dailyGoal)
        let progress = min(CGFloat(hydration.todayTotal) / CGFloat(goal), 1.0)

        return ZStack {
            Circle()
                .stroke(AppTheme.secondary.opacity(0.15), lineWidth: 14)
                .frame(width: 200, height: 200)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(ringGradient, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .frame(width: 200, height: 200)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)

            VStack(spacing: 4) {
                Image(systemName: "drop.fill")
                    .font(.title)
                    .foregroundStyle(AppTheme.secondary)

                Text("\(hydration.todayTotal)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .monospacedDigit()

                Text("/ \(hydration.dailyGoal) ml")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let profile {
                    statusBadge(profile: profile)
                }
            }
        }
        .padding(.top, 8)
    }

    private var ringGradient: AngularGradient {
        AngularGradient(
            colors: [AppTheme.secondary, AppTheme.primary],
            center: .center,
            startAngle: .degrees(-90),
            endAngle: .degrees(270)
        )
    }

    private func statusBadge(profile: UserProfile) -> some View {
        let status = hydration.status(profile: profile)
        let color: Color = {
            switch status {
            case .onTrack, .goalReached: return AppTheme.primary
            case .slightlyBehind: return .orange
            case .dehydrated: return .red
            }
        }()
        return Text(status.rawValue)
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .glassEffect(.regular.tint(color.opacity(0.3)), in: Capsule())
            .foregroundStyle(color)
    }

    // MARK: - Quick Log Buttons

    private var quickLogButtons: some View {
        GlassEffectContainer {
            HStack(spacing: 12) {
                quickLogButton(amount: 150, label: "Small", icon: "drop")
                quickLogButton(amount: 250, label: "Glass", icon: "drop.fill")
                quickLogButton(amount: 500, label: "Bottle", icon: "waterbottle.fill")
            }
        }
        .padding(.horizontal)
    }

    private func quickLogButton(amount: Int, label: String, icon: String) -> some View {
        Button {
            hydration.logWater(amount, source: "ios", context: context)
        } label: {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title2)
                Text(label)
                    .font(.caption2)
                Text("\(amount)ml")
                    .font(.caption2.bold())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.glass)
    }

    // MARK: - Schedule Card

    private func scheduleCard(profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Hydration Schedule", systemImage: "clock.fill")
                .font(.headline)
                .foregroundStyle(AppTheme.secondary)
            Divider()

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Expected by now")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(hydration.expectedIntakeByNow(profile: profile)) ml")
                        .font(.title3.bold())
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Deficit")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    let gap = hydration.deficit(profile: profile)
                    Text("\(gap) ml")
                        .font(.title3.bold())
                        .foregroundStyle(gap > 500 ? .red : gap > 250 ? .orange : AppTheme.primary)
                }
            }

            if let nextDrink = hydration.minutesUntilNextDrink(profile: profile) {
                HStack {
                    Image(systemName: "timer")
                        .foregroundStyle(AppTheme.secondary)
                    Text("Next glass in ~\(nextDrink) min")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(AppTheme.secondary.opacity(0.15)), in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
    }

    // MARK: - Gout Protocol Card

    private func goutCard(profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Uric Acid Flush", systemImage: "shield.checkered")
                .font(.headline)
                .foregroundStyle(AppTheme.accent)
            Divider()
            Text(hydration.goutFlushRecommendation(profile: profile))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            let remaining = max(0, profile.dailyWaterGoalMl - hydration.todayTotal)
            let flushProgress = min(1.0, Double(hydration.todayTotal) / Double(max(1, profile.dailyWaterGoalMl)))

            ProgressView(value: flushProgress)
                .tint(flushProgress >= 1.0 ? AppTheme.primary : AppTheme.accent)
                .padding(.top, 4)

            Text("Adequate hydration helps flush uric acid crystals from joints, reducing gout flare risk.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.top, 2)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(AppTheme.accent.opacity(0.15)), in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
    }

    // MARK: - History Card

    private var historyCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Today's Log", systemImage: "list.bullet")
                .font(.headline)
                .foregroundStyle(AppTheme.secondary)
            Divider()
            ForEach(todayLogs.prefix(10)) { log in
                HStack {
                    Image(systemName: "drop.fill")
                        .foregroundStyle(AppTheme.secondary.opacity(0.6))
                        .font(.caption)
                    Text("\(log.amount) ml")
                        .font(.subheadline)
                    Spacer()
                    Text(log.source)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Text(log.timestamp.formatted(date: .omitted, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(AppTheme.secondary.opacity(0.1)), in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
    }
}
