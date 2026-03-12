import SwiftUI
import SwiftData
import HealthDebugKit

// MARK: - Drink Builder View

struct DrinkBuilderView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var hydration = HydrationManager.shared
    @StateObject private var rag = HealthRAG.shared
    @Query(UserProfile.currentDescriptor()) private var profiles: [UserProfile]
    @Query(SleepConfig.currentDescriptor()) private var sleepConfigs: [SleepConfig]

    @State private var selectedCategory: DrinkCategory = .water
    @State private var selectedDrink = ""
    @State private var volume: Double = 250
    @State private var aiSuggestion = ""
    @State private var loadingSuggestion = false

    private var profile: UserProfile? { profiles.first }

    enum DrinkCategory: String, CaseIterable {
        case water = "Water"
        case herbalTea = "Herbal Tea"
        case supplement = "Supplement"

        var icon: String {
            switch self {
            case .water: return "drop.fill"
            case .herbalTea: return "leaf.fill"
            case .supplement: return "pill.fill"
            }
        }

        var color: Color {
            switch self {
            case .water: return AppTheme.secondary
            case .herbalTea: return AppTheme.accent
            case .supplement: return AppTheme.primary
            }
        }

        var items: [String] {
            switch self {
            case .water: return ["Still Water", "Sparkling Water", "Lemon Water"]
            case .herbalTea: return ["Chamomile Tea", "Anise Tea", "Peppermint Tea", "Ginger Tea", "Green Tea"]
            case .supplement: return ["Creatine", "Magnesium", "Vitamin C", "Zinc"]
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Hydration progress ring
                hydrationRing

                AIInsightCard(domain: .hydration)

                // Drink builder card
                builderCard

                // AI suggestion
                if !aiSuggestion.isEmpty {
                    aiSuggestionCard
                }

                // AI recommend next drink
                recommendButton

                // Today's quick water log
                waterSummaryCard
            }
            .padding(.vertical)
        }
        .navigationTitle("Hydration")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            hydration.refresh(context: context)
            if let p = profile { hydration.dailyGoal = p.dailyWaterGoalMl }
        }
    }

    // MARK: - Hydration Ring

    private var hydrationRing: some View {
        let progress = min(1.0, Double(hydration.todayTotal) / Double(max(1, hydration.dailyGoal)))
        return ZStack {
            Circle()
                .stroke(AppTheme.secondary.opacity(0.15), lineWidth: 14)
                .frame(width: 160, height: 160)
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(AppTheme.secondary.gradient, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .frame(width: 160, height: 160)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
            VStack(spacing: 4) {
                Image(systemName: "drop.fill").font(.title2).foregroundStyle(AppTheme.secondary)
                Text("\(hydration.todayTotal)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                Text("/ \(hydration.dailyGoal) ml").font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Builder Card

    private var builderCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Log a Drink", systemImage: "plus.circle.fill")
                .font(.headline).foregroundStyle(AppTheme.primary)
            Divider()

            // Category picker
            GlassEffectContainer {
                HStack(spacing: 6) {
                    ForEach(DrinkCategory.allCases, id: \.self) { cat in
                        categoryChip(cat: cat)
                    }
                }
            }

            // Drink items
            LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 8) {
                ForEach(selectedCategory.items, id: \.self) { drink in
                    drinkChip(drink: drink)
                }
            }

            // Volume picker
            if !selectedDrink.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Volume")
                            .font(.caption.bold()).foregroundStyle(.secondary)
                        Spacer()
                        Text("\(Int(volume)) ml")
                            .font(.caption.bold()).foregroundStyle(selectedCategory.color)
                    }
                    Slider(value: $volume, in: 100...1000, step: 50)
                        .tint(selectedCategory.color)
                }

                GlassEffectContainer {
                    HStack(spacing: 10) {
                        Button { logDrink() } label: {
                            Label("Log \(Int(volume))ml", systemImage: "checkmark.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.glassProminent)
                        .tint(selectedCategory.color)

                        Button { getDrinkAdvice() } label: {
                            Label(loadingSuggestion ? "..." : "AI Tip", systemImage: "sparkles")
                        }
                        .buttonStyle(.glass)
                        .disabled(loadingSuggestion)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(selectedCategory.color.opacity(0.08)), in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
    }

    // MARK: - AI Cards

    private var aiSuggestionCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("AI Drink Tip", systemImage: "sparkles")
                .font(.headline).foregroundStyle(AppTheme.primary)
            Divider()
            Text(aiSuggestion)
                .font(.subheadline).foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(AppTheme.primary.opacity(0.1)), in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
    }

    private var recommendButton: some View {
        Button {
            getRecommendation()
        } label: {
            Label(
                loadingSuggestion ? "Thinking..." : "What should I drink now?",
                systemImage: "brain"
            )
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.glassProminent)
        .tint(AppTheme.secondary)
        .controlSize(.large)
        .disabled(loadingSuggestion)
        .padding(.horizontal)
    }

    private var waterSummaryCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Quick Water Log", systemImage: "drop.fill")
                .font(.headline).foregroundStyle(AppTheme.secondary)
            Divider()
            GlassEffectContainer {
                HStack(spacing: 8) {
                    ForEach([150, 250, 350, 500], id: \.self) { ml in
                        Button {
                            hydration.logWater(ml, source: "ios", context: context, profile: profile)
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: "drop.fill")
                                    .font(.callout).foregroundStyle(AppTheme.secondary)
                                Text("\(ml)").font(.caption.bold())
                                Text("ml").font(.caption2).foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, 8)
                        }
                        .buttonStyle(.glass)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(AppTheme.secondary.opacity(0.1)), in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
    }

    // MARK: - Chip Helpers

    @ViewBuilder
    private func categoryChip(cat: DrinkCategory) -> some View {
        let isSelected = selectedCategory == cat
        if isSelected {
            Button {
                // already selected — no-op animation
            } label: {
                Label(LocalizedStringKey(cat.rawValue), systemImage: cat.icon)
                    .font(.caption.bold())
                    .padding(.horizontal, 10).padding(.vertical, 6)
            }
            .buttonStyle(.glassProminent)
            .tint(cat.color)
        } else {
            Button {
                withAnimation(.spring(response: 0.3)) {
                    selectedCategory = cat
                    selectedDrink = ""
                }
            } label: {
                Label(LocalizedStringKey(cat.rawValue), systemImage: cat.icon)
                    .font(.caption.bold())
                    .padding(.horizontal, 10).padding(.vertical, 6)
            }
            .buttonStyle(.glass)
            .tint(cat.color)
        }
    }

    @ViewBuilder
    private func drinkChip(drink: String) -> some View {
        let isSelected = selectedDrink == drink
        if isSelected {
            Button {
                withAnimation(.spring(response: 0.3)) {
                    selectedDrink = ""
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: selectedCategory.icon)
                        .font(.caption).foregroundStyle(selectedCategory.color)
                    Text(LocalizedStringKey(drink))
                        .font(.caption)
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: "checkmark")
                        .font(.caption2).foregroundStyle(selectedCategory.color)
                }
                .padding(10)
            }
            .buttonStyle(.glassProminent)
            .tint(selectedCategory.color)
        } else {
            Button {
                withAnimation(.spring(response: 0.3)) {
                    selectedDrink = drink
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: selectedCategory.icon)
                        .font(.caption).foregroundStyle(selectedCategory.color)
                    Text(LocalizedStringKey(drink))
                        .font(.caption)
                        .lineLimit(1)
                    Spacer()
                }
                .padding(10)
            }
            .buttonStyle(.glass)
            .tint(selectedCategory.color)
        }
    }

    // MARK: - Actions

    private func logDrink() {
        guard !selectedDrink.isEmpty else { return }
        let isWater = selectedCategory == .water
        hydration.logWater(Int(volume), source: isWater ? "ios" : "tea", context: context, profile: profile)
        selectedDrink = ""
        volume = 250
    }

    private func getDrinkAdvice() {
        let hour = Calendar.current.component(.hour, from: Date())
        loadingSuggestion = true
        Task {
            await rag.send(
                "I'm about to drink \(selectedDrink) (\(Int(volume))ml) at \(hour):00. Is this a good choice for my health right now? 1-2 sentences.",
                context: context,
                profile: profile,
                sleepConfig: sleepConfigs.first
            )
            await MainActor.run {
                aiSuggestion = rag.messages
                    .last(where: { $0.role == .assistant })
                    .map { cleanTags($0.content) } ?? ""
                loadingSuggestion = false
            }
        }
    }

    private func getRecommendation() {
        let hour = Calendar.current.component(.hour, from: Date())
        let water = hydration.todayTotal
        loadingSuggestion = true
        Task {
            await rag.send(
                "It's \(hour):00 and I've had \(water)ml of fluids today. What should I drink next for optimal health? Be specific and brief.",
                context: context,
                profile: profile,
                sleepConfig: sleepConfigs.first
            )
            await MainActor.run {
                aiSuggestion = rag.messages
                    .last(where: { $0.role == .assistant })
                    .map { cleanTags($0.content) } ?? ""
                loadingSuggestion = false
            }
        }
    }

    private func cleanTags(_ t: String) -> String {
        t.replacingOccurrences(of: #"\[ACTION:[^\]]+\]"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
