import SwiftUI
import SwiftData
import HealthDebugKit

// MARK: - Daily Flow Card

struct DailyFlowCard: View {
    @StateObject private var hydration = HydrationManager.shared
    @StateObject private var nutrition = NutritionManager.shared
    @StateObject private var caffeine = CaffeineManager.shared
    @StateObject private var stand = StandTimerManager.shared
    @StateObject private var shutdown = ShutdownManager.shared
    @StateObject private var health = HealthKitManager.shared
    @StateObject private var rag = HealthRAG.shared
    @Environment(\.modelContext) private var context
    @Query(UserProfile.currentDescriptor()) private var profiles: [UserProfile]
    @Query(SleepConfig.currentDescriptor()) private var sleepConfigs: [SleepConfig]

    @State private var expanded = true
    @State private var briefing = ""
    @State private var loadingBriefing = false

    private var profile: UserProfile? { profiles.first }

    // Checklist items computed from real data
    // (title, detail, isComplete, color)
    private var items: [(String, String, Bool, Color)] {
        let waterOk = hydration.todayTotal >= 500
        let mealsLogged = nutrition.todayMeals.count >= 1
        let standOk = stand.todayCompleted >= 2
        let caffeineOk = !caffeine.fattyLiverAlert
        let shutdownOk = shutdown.state != .violated
        let sleepOk = health.sleepHours >= 6

        return [
            ("Morning Hydration", "\(hydration.todayTotal) ml logged", waterOk, AppTheme.secondary),
            ("Meals Logged", "\(nutrition.todayMeals.count) meals today", mealsLogged, AppTheme.primary),
            ("Stand Sessions", "\(stand.todayCompleted)/\(StandTimerManager.dailyTarget) complete", standOk, AppTheme.accent),
            ("Caffeine Clean", caffeine.fattyLiverAlert ? "Sugar-based detected" : "\(caffeine.todayCleanCount) clean drinks", caffeineOk, AppTheme.primary),
            ("Shutdown Compliant", shutdown.state == .violated ? "Rule broken" : "On track", shutdownOk, .orange),
            ("Sleep Quality", String(format: "%.1fh last night", health.sleepHours), sleepOk, AppTheme.secondary),
        ]
    }

    private var completedCount: Int { items.filter(\.2).count }
    private var totalCount: Int { items.count }
    private var overallScore: Double { Double(completedCount) / Double(totalCount) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header row — always visible
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    expanded.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    // Mini progress ring
                    ZStack {
                        Circle()
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 4)
                            .frame(width: 36, height: 36)
                        Circle()
                            .trim(from: 0, to: CGFloat(overallScore))
                            .stroke(scoreColor.gradient, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .frame(width: 36, height: 36)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 0.4), value: overallScore)
                        Text("\(completedCount)")
                            .font(.caption2.bold())
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Daily Flow")
                            .font(.headline)
                        Text("\(completedCount) of \(totalCount) goals met")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .buttonStyle(.plain)

            if expanded {
                Divider().padding(.horizontal)

                // AI morning briefing
                if !briefing.isEmpty {
                    Text(briefing)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                        .padding(.top, 8)
                }

                // Checklist rows
                VStack(spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                        HStack(spacing: 12) {
                            Image(systemName: item.2 ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(item.2 ? item.3 : Color.secondary)
                                .font(.title3)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(LocalizedStringKey(item.0)).font(.subheadline)
                                Text(item.1).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                }

                // Smart briefing button
                if briefing.isEmpty {
                    Button {
                        loadBriefing()
                    } label: {
                        Label(
                            loadingBriefing ? "Loading..." : "Get AI Daily Briefing",
                            systemImage: "sparkles"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(AppTheme.primary)
                    .controlSize(.small)
                    .disabled(loadingBriefing)
                    .padding(.horizontal)
                    .padding(.bottom, 12)
                }
            }
        }
        .glassEffect(
            .regular.tint(scoreColor.opacity(0.1)),
            in: RoundedRectangle(cornerRadius: 20)
        )
        .padding(.horizontal)
    }

    private var scoreColor: Color {
        overallScore >= 0.8 ? AppTheme.primary : overallScore >= 0.5 ? .orange : .red
    }

    private func loadBriefing() {
        loadingBriefing = true
        let summary = "Daily flow: \(completedCount)/\(totalCount) goals met. Water: \(hydration.todayTotal)ml. Meals: \(nutrition.todayMeals.count). Stand: \(stand.todayCompleted) sessions. Sleep: \(String(format: "%.1f", health.sleepHours))h."
        Task {
            await rag.send(
                "Give me a brief 2-sentence morning health briefing based on this data: \(summary)",
                context: context,
                profile: profile,
                sleepConfig: sleepConfigs.first
            )
            await MainActor.run {
                briefing = rag.messages.last?.content ?? ""
                loadingBriefing = false
            }
        }
    }
}
