import SwiftUI
import SwiftData
import HealthDebugKit

// MARK: - Search View

struct SearchView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var health = HealthKitManager.shared
    @StateObject private var hydration = HydrationManager.shared
    @StateObject private var nutrition = NutritionManager.shared
    @StateObject private var caffeine = CaffeineManager.shared
    @State private var query = ""
    @State private var navigationPath = NavigationPath()

    // MARK: - Search Result Model

    struct SearchResult: Identifiable {
        let id = UUID()
        let title: String
        let subtitle: String
        let icon: String
        let color: Color
        let destination: HealthScreen?
    }

    // MARK: - Static screen index

    private let screenIndex: [(id: String, title: String, keywords: [String], icon: String, color: Color, destination: HealthScreen)] = [
        ("steps", "Steps", ["steps", "walk", "walking", "fitness", "activity"], "figure.walk", AppTheme.primary, .steps),
        ("energy", "Active Energy", ["energy", "calories", "kcal", "burn", "active"], "flame.fill", .orange, .energy),
        ("heartRate", "Heart Rate", ["heart", "bpm", "pulse", "hr", "cardio"], "heart.fill", .red, .heartRate),
        ("sleep", "Sleep", ["sleep", "rest", "hours", "night", "bed"], "moon.zzz.fill", AppTheme.secondary, .sleep),
        ("hydration", "Hydration", ["water", "hydration", "drink", "ml", "gout"], "drop.fill", AppTheme.secondary, .hydration),
        ("standTimer", "Stand Timer", ["stand", "timer", "walk", "session", "pomodoro"], "figure.stand", AppTheme.accent, .standTimer),
        ("nutrition", "Nutrition", ["food", "meal", "nutrition", "eat", "safe", "unsafe"], "fork.knife", AppTheme.primary, .nutrition),
        ("caffeine", "Caffeine", ["caffeine", "coffee", "red bull", "redbull", "clean"], "cup.and.saucer.fill", .brown, .caffeine),
        ("shutdown", "System Shutdown", ["shutdown", "gerd", "sleep", "no food", "window"], "moon.fill", AppTheme.secondary, .shutdown),
        ("weight", "Weight", ["weight", "kg", "zepp", "scale", "bmi"], "scalemass.fill", AppTheme.primary, .weight),
    ]

    // MARK: - Computed Results

    var results: [SearchResult] {
        let q = query.lowercased().trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return [] }

        var out: [SearchResult] = []

        // Screen matches
        for screen in screenIndex {
            let matches = screen.title.lowercased().contains(q) ||
                screen.keywords.contains(where: { $0.contains(q) })
            if matches {
                out.append(SearchResult(
                    title: screen.title,
                    subtitle: NSLocalizedString("Open screen", comment: ""),
                    icon: screen.icon,
                    color: screen.color,
                    destination: screen.destination
                ))
            }
        }

        // Live metrics
        if "steps".contains(q) || q.contains("step") {
            out.append(SearchResult(
                title: NSLocalizedString("Steps Today", comment: ""),
                subtitle: formatDouble(health.stepCount) + " " + NSLocalizedString("steps", comment: ""),
                icon: "figure.walk",
                color: AppTheme.primary,
                destination: .steps
            ))
        }
        if "energy".contains(q) || "calories".contains(q) || q.contains("kcal") {
            out.append(SearchResult(
                title: NSLocalizedString("Active Energy Today", comment: ""),
                subtitle: String(format: "%.0f kcal", health.activeEnergy),
                icon: "flame.fill",
                color: .orange,
                destination: .energy
            ))
        }
        if "heart".contains(q) || q.contains("bpm") || q.contains("heart") {
            out.append(SearchResult(
                title: NSLocalizedString("Heart Rate", comment: ""),
                subtitle: "\(formatDouble(health.heartRate)) BPM",
                icon: "heart.fill",
                color: .red,
                destination: .heartRate
            ))
        }
        if "sleep".contains(q) || q.contains("sleep") {
            out.append(SearchResult(
                title: NSLocalizedString("Sleep Last Night", comment: ""),
                subtitle: String(format: "%.1f hrs", health.sleepHours),
                icon: "moon.zzz.fill",
                color: AppTheme.secondary,
                destination: .sleep
            ))
        }

        // Water logs
        if "water".contains(q) || "hydration".contains(q) || q.contains("ml") || q.contains("water") {
            for log in hydration.logs.suffix(5) {
                out.append(SearchResult(
                    title: NSLocalizedString("Water Log", comment: ""),
                    subtitle: "\(log.amount) ml — \(log.timestamp.formatted(date: .omitted, time: .shortened))",
                    icon: "drop.fill",
                    color: AppTheme.secondary,
                    destination: .hydration
                ))
            }
        }

        // Meal logs
        if "meal".contains(q) || "food".contains(q) || "nutrition".contains(q) ||
            q.contains("meal") || q.contains("food") || q.contains("eat") {
            for meal in nutrition.todayMeals.suffix(5) {
                let safeLabel = meal.isSafe
                    ? NSLocalizedString("Safe", comment: "")
                    : NSLocalizedString("Unsafe", comment: "")
                out.append(SearchResult(
                    title: meal.name,
                    subtitle: safeLabel + " · " + meal.timestamp.formatted(date: .omitted, time: .shortened),
                    icon: "fork.knife",
                    color: meal.isSafe ? AppTheme.primary : .red,
                    destination: .nutrition
                ))
            }
        }

        // Caffeine logs
        if "caffeine".contains(q) || "coffee".contains(q) || q.contains("caffeine") || q.contains("coffee") {
            out.append(SearchResult(
                title: NSLocalizedString("Caffeine Today", comment: ""),
                subtitle: "\(caffeine.todayCleanCount) \(NSLocalizedString("clean", comment: "")) · \(caffeine.todaySugarCount) \(NSLocalizedString("sugar", comment: ""))",
                icon: "cup.and.saucer.fill",
                color: .brown,
                destination: .caffeine
            ))
        }

        // Deduplicate by title+subtitle
        var seen = Set<String>()
        return out.filter { seen.insert($0.title + $0.subtitle).inserted }
    }

    // MARK: - Suggestions (empty query)

    private var suggestions: [SearchResult] {
        [
            SearchResult(title: NSLocalizedString("Hydration", comment: ""), subtitle: NSLocalizedString("Recent", comment: ""), icon: "drop.fill", color: AppTheme.secondary, destination: .hydration),
            SearchResult(title: NSLocalizedString("Steps", comment: ""), subtitle: NSLocalizedString("Recent", comment: ""), icon: "figure.walk", color: AppTheme.primary, destination: .steps),
            SearchResult(title: NSLocalizedString("Nutrition", comment: ""), subtitle: NSLocalizedString("Recent", comment: ""), icon: "fork.knife", color: AppTheme.primary, destination: .nutrition),
            SearchResult(title: NSLocalizedString("Sleep", comment: ""), subtitle: NSLocalizedString("Recent", comment: ""), icon: "moon.zzz.fill", color: AppTheme.secondary, destination: .sleep),
        ]
    }

    private var quickActions: [SearchResult] {
        [
            SearchResult(title: NSLocalizedString("Log 250ml Water", comment: ""), subtitle: NSLocalizedString("Quick action", comment: ""), icon: "plus.circle.fill", color: AppTheme.secondary, destination: .hydration),
            SearchResult(title: NSLocalizedString("Log Meal", comment: ""), subtitle: NSLocalizedString("Quick action", comment: ""), icon: "fork.knife.circle.fill", color: AppTheme.primary, destination: .nutrition),
            SearchResult(title: NSLocalizedString("Start Stand Timer", comment: ""), subtitle: NSLocalizedString("Quick action", comment: ""), icon: "play.circle.fill", color: AppTheme.accent, destination: .standTimer),
        ]
    }

    // MARK: - Body

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if query.isEmpty {
                    suggestionsBody
                } else if results.isEmpty {
                    emptyState
                } else {
                    resultsList
                }
            }
            .navigationTitle(LocalizedStringKey("Search"))
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: LocalizedStringKey("Screens, metrics, logs…"))
            .navigationDestination(for: HealthScreen.self) { screen in
                switch screen {
                case .steps: StepsDetailView()
                case .energy: EnergyDetailView()
                case .heartRate: HeartRateDetailView()
                case .sleep: SleepDetailView()
                case .hydration: HydrationDetailView()
                case .standTimer: StandTimerDetailView()
                case .nutrition: NutritionDetailView()
                case .caffeine: CaffeineDetailView()
                case .shutdown: ShutdownDetailView()
                case .weight: ZeppDetailView()
                case .dailyFlow: DailyFlowDetailView()
                }
            }
        }
        .onAppear {
            hydration.refresh(context: context)
            nutrition.refresh(context: context)
            caffeine.refresh(context: context)
        }
    }

    // MARK: - Results List

    private var resultsList: some View {
        List {
            Section(header: Text(LocalizedStringKey("Results"))) {
                ForEach(results) { result in
                    resultRow(result)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Suggestions

    private var suggestionsBody: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Today's summary card
                todaySummaryCard

                // Recent screens
                VStack(alignment: .leading, spacing: 10) {
                    Text(LocalizedStringKey("Recent Screens"))
                        .font(.headline)
                        .padding(.horizontal)
                    VStack(spacing: 8) {
                        ForEach(suggestions) { result in
                            resultRow(result)
                                .padding(.horizontal)
                        }
                    }
                }

                // Quick actions
                VStack(alignment: .leading, spacing: 10) {
                    Text(LocalizedStringKey("Quick Actions"))
                        .font(.headline)
                        .padding(.horizontal)
                    VStack(spacing: 8) {
                        ForEach(quickActions) { action in
                            resultRow(action)
                                .padding(.horizontal)
                        }
                    }
                }
            }
            .padding(.vertical)
        }
    }

    // MARK: - Today Summary Card

    private var todaySummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(LocalizedStringKey("Today's Summary"), systemImage: "chart.bar.fill")
                .font(.headline)
                .foregroundStyle(AppTheme.primary)

            LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 10) {
                summaryChip(icon: "figure.walk", value: formatDouble(health.stepCount), label: "Steps", color: AppTheme.primary)
                summaryChip(icon: "drop.fill", value: "\(hydration.todayTotal) ml", label: "Water", color: AppTheme.secondary)
                summaryChip(icon: "moon.zzz.fill", value: String(format: "%.1fh", health.sleepHours), label: "Sleep", color: AppTheme.secondary)
                summaryChip(icon: "fork.knife", value: "\(nutrition.todayMeals.count)", label: "Meals", color: AppTheme.primary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(AppTheme.primary.opacity(0.08)), in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
    }

    private func summaryChip(icon: String, value: String, label: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon).foregroundStyle(color).font(.subheadline)
            VStack(alignment: .leading, spacing: 1) {
                Text(verbatim: value).font(.subheadline.bold())
                Text(LocalizedStringKey(label)).font(.caption2).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(10)
        .glassEffect(.regular.tint(color.opacity(0.08)), in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text(LocalizedStringKey("No Results"))
                .font(.title3.bold())
            Text(LocalizedStringKey("Try searching for a screen name, metric, or health topic."))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
    }

    // MARK: - Result Row

    @ViewBuilder
    private func resultRow(_ result: SearchResult) -> some View {
        if let destination = result.destination {
            Button {
                navigationPath.append(destination)
            } label: {
                resultRowContent(result)
            }
            .buttonStyle(.plain)
        } else {
            resultRowContent(result)
        }
    }

    private func resultRowContent(_ result: SearchResult) -> some View {
        HStack(spacing: 14) {
            Image(systemName: result.icon)
                .font(.subheadline)
                .foregroundStyle(result.color)
                .frame(width: 32, height: 32)
                .glassEffect(.regular.tint(result.color.opacity(0.15)), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizedStringKey(result.title))
                    .font(.subheadline.weight(.medium))
                Text(LocalizedStringKey(result.subtitle))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(result.color.opacity(0.06)), in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Helpers

    private func formatDouble(_ value: Double) -> String {
        value >= 1000 ? String(format: "%.1fk", value / 1000) : String(format: "%.0f", value)
    }
}
