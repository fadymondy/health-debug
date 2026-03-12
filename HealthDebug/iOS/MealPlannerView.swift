import SwiftUI
import SwiftData
import HealthDebugKit

// MARK: - Meal Planner View

struct MealPlannerView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var nutrition = NutritionManager.shared
    @StateObject private var rag = HealthRAG.shared
    @Query(UserProfile.currentDescriptor()) private var profiles: [UserProfile]
    @Query(MealLog.todayDescriptor()) private var todayMeals: [MealLog]

    @State private var selectedProtein: String? = nil
    @State private var selectedCarb: String? = nil
    @State private var selectedFat: String? = nil
    @State private var customItem = ""
    @State private var aiAdvice = ""
    @State private var loadingAdvice = false

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Safety score ring
                safetyRing

                // AI Insight
                AIInsightCard(domain: .nutrition)

                // Plate builder
                plateBuilderCard

                // AI advice (shown after plate is built)
                if !aiAdvice.isEmpty {
                    aiAdviceCard
                }

                // Today's meals timeline
                if !todayMeals.isEmpty {
                    mealsTimelineCard
                }
            }
            .padding(.vertical)
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Nutrition")
        .navigationBarTitleDisplayMode(.large)
        .onAppear { nutrition.refresh(context: context) }
    }

    // MARK: - Safety Ring

    private var safetyRing: some View {
        let score = nutrition.safetyScore
        let color: Color = score >= 80 ? AppTheme.primary : score >= 50 ? .orange : .red
        return ZStack {
            Circle()
                .stroke(color.opacity(0.15), lineWidth: 12)
                .frame(width: 140, height: 140)
            Circle()
                .trim(from: 0, to: CGFloat(score / 100))
                .stroke(color.gradient, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .frame(width: 140, height: 140)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: score)
            VStack(spacing: 2) {
                Text(String(format: "%.0f%%", score))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
                Text("Safe Score").font(.caption2).foregroundStyle(.secondary)
                HStack(spacing: 6) {
                    Text("\(nutrition.todaySafeCount)")
                        .foregroundStyle(AppTheme.primary)
                        .font(.caption2)
                    Image(systemName: "checkmark")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.primary)
                    Text("\(nutrition.todayUnsafeCount)")
                        .foregroundStyle(.red)
                        .font(.caption2)
                    Image(systemName: "xmark")
                        .font(.caption2)
                        .foregroundStyle(.red)
                }
            }
        }
    }

    // MARK: - Plate Builder

    private var plateBuilderCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Build Your Plate", systemImage: "fork.knife.circle.fill")
                    .font(.headline).foregroundStyle(AppTheme.primary)
                Spacer()
                if selectedProtein != nil || selectedCarb != nil || selectedFat != nil {
                    Button("Clear") {
                        selectedProtein = nil
                        selectedCarb = nil
                        selectedFat = nil
                        aiAdvice = ""
                    }
                    .font(.caption).foregroundStyle(.secondary)
                    .buttonStyle(.plain)
                }
            }
            Divider()

            // Protein section
            foodPickerRow(
                title: "Protein",
                icon: "fish.fill",
                color: AppTheme.primary,
                items: FoodRegistry.safeProteins,
                selected: $selectedProtein
            )

            // Carb section
            foodPickerRow(
                title: "Carbs",
                icon: "leaf.fill",
                color: AppTheme.accent,
                items: FoodRegistry.safeCarbs,
                selected: $selectedCarb
            )

            // Fat section
            foodPickerRow(
                title: "Healthy Fat",
                icon: "drop.halffull",
                color: AppTheme.secondary,
                items: FoodRegistry.safeFats,
                selected: $selectedFat
            )

            // Custom item
            HStack(spacing: 8) {
                Image(systemName: "plus.circle").foregroundStyle(.secondary).font(.title3)
                TextField("Add custom item...", text: $customItem)
                    .textFieldStyle(.plain)
                    .font(.subheadline)
                    .submitLabel(.done)
                    .onSubmit { addCustomItem() }
            }
            .padding(10)
            .glassEffect(.regular.tint(Color.secondary.opacity(0.08)), in: RoundedRectangle(cornerRadius: 12))

            // Log & AI Advice buttons
            if selectedProtein != nil || selectedCarb != nil || selectedFat != nil || !customItem.isEmpty {
                GlassEffectContainer {
                    HStack(spacing: 10) {
                        Button { logMeal() } label: {
                            Label("Log This Meal", systemImage: "checkmark.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.glassProminent)
                        .tint(AppTheme.primary)

                        Button { getAIAdvice() } label: {
                            Label(loadingAdvice ? "..." : "AI Advice", systemImage: "sparkles")
                        }
                        .buttonStyle(.glass)
                        .disabled(loadingAdvice)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(AppTheme.primary.opacity(0.08)), in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
    }

    private func foodPickerRow(title: String, icon: String, color: Color, items: [String], selected: Binding<String?>) -> some View {
        let header = Label(title, systemImage: icon)
            .font(.caption.bold())
            .foregroundStyle(color)

        return VStack(alignment: .leading, spacing: 6) {
            header
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(items, id: \.self) { item in
                        foodChip(item: item, color: color, selected: selected)
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }

    @ViewBuilder
    private func foodChip(item: String, color: Color, selected: Binding<String?>) -> some View {
        let isSelected = selected.wrappedValue == item
        if isSelected {
            Button {
                withAnimation(.spring(response: 0.3)) {
                    selected.wrappedValue = nil
                }
            } label: {
                Text(LocalizedStringKey(item))
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.glassProminent)
            .tint(color)
        } else {
            Button {
                withAnimation(.spring(response: 0.3)) {
                    selected.wrappedValue = item
                }
            } label: {
                Text(LocalizedStringKey(item))
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.glass)
            .tint(color)
        }
    }

    // MARK: - AI Advice Card

    private var aiAdviceCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("AI Meal Advice", systemImage: "sparkles")
                .font(.headline).foregroundStyle(AppTheme.primary)
            Divider()
            Text(aiAdvice)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(AppTheme.primary.opacity(0.1)), in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
    }

    // MARK: - Meals Timeline

    private var mealsTimelineCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Today's Meals", systemImage: "clock.fill")
                .font(.headline).foregroundStyle(AppTheme.secondary)
            Divider()
            ForEach(todayMeals.prefix(8)) { meal in
                HStack(spacing: 10) {
                    Image(systemName: meal.isSafe ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(meal.isSafe ? AppTheme.primary : .red)
                        .font(.callout)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(meal.name).font(.subheadline)
                        if !meal.triggers.isEmpty {
                            HStack(spacing: 4) {
                                ForEach(meal.triggers, id: \.self) { trigger in
                                    Text(LocalizedStringKey(trigger))
                                        .font(.caption2)
                                        .padding(.horizontal, 5).padding(.vertical, 2)
                                        .glassEffect(.regular.tint(Color.red.opacity(0.2)), in: Capsule())
                                        .foregroundStyle(.red)
                                }
                            }
                        }
                    }
                    Spacer()
                    Text(meal.category.prefix(1).uppercased())
                        .font(.caption2.bold())
                        .foregroundStyle(.tertiary)
                    Text(meal.timestamp.formatted(date: .omitted, time: .shortened))
                        .font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(AppTheme.secondary.opacity(0.1)), in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
    }

    // MARK: - Actions

    private func logMeal() {
        let items = [selectedProtein, selectedCarb, selectedFat].compactMap { $0 }
        let extra = customItem.trimmingCharacters(in: .whitespacesAndNewlines)
        for item in items {
            nutrition.logSafeMeal(item, category: .protein, context: context)
        }
        if !extra.isEmpty {
            nutrition.logMeal(extra, category: .snack, notes: "", context: context)
        }
        selectedProtein = nil
        selectedCarb = nil
        selectedFat = nil
        customItem = ""
    }

    private func addCustomItem() {
        let text = customItem.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        nutrition.logMeal(text, category: .snack, notes: "", context: context)
        customItem = ""
    }

    private func getAIAdvice() {
        let items = [selectedProtein, selectedCarb, selectedFat].compactMap { $0 }
        let extra = customItem.trimmingCharacters(in: .whitespacesAndNewlines)
        let allItems = (items + (extra.isEmpty ? [] : [extra])).joined(separator: ", ")
        loadingAdvice = true
        Task {
            await rag.send(
                "I'm about to eat: \(allItems). Is this safe for GERD, IBS, gout, and fatty liver? Give me a 2-sentence verdict.",
                context: context,
                profile: profile,
                sleepConfig: nil
            )
            await MainActor.run {
                aiAdvice = rag.messages
                    .last(where: { $0.role == .assistant })
                    .map { cleanTags($0.content) } ?? ""
                loadingAdvice = false
            }
        }
    }

    private func cleanTags(_ t: String) -> String {
        t.replacingOccurrences(of: #"\[ACTION:[^\]]+\]"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
