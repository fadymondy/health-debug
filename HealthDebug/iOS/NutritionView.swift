import SwiftUI
import SwiftData
import HealthDebugKit

struct NutritionView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var nutrition = NutritionManager.shared
    @StateObject private var shutdownMgr = ShutdownManager.shared
    @Query(SleepConfig.currentDescriptor()) private var sleepConfigs: [SleepConfig]
    @State private var showCustomLog = false
    @State private var customName = ""
    @State private var customCategory: FoodCategory = .protein

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if shutdownMgr.state == .active {
                        shutdownWarning
                    }
                    safetyScoreCard
                    quickLogSection
                    if !nutrition.todayUnsafe.isEmpty {
                        triggersCard
                    }
                    if !nutrition.todayMeals.isEmpty {
                        historyCard
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Nutrition")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCustomLog = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCustomLog) {
                customLogSheet
            }
            .onAppear {
                nutrition.refresh(context: context)
                shutdownMgr.refresh(config: sleepConfigs.first)
            }
        }
    }

    // MARK: - Shutdown Warning

    private var shutdownWarning: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                Text("System Shutdown Active")
                    .font(.title3.bold())
                    .foregroundStyle(.red)
            }
            Text("No food allowed. Only water, chamomile tea, or anise tea.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .glassEffect(.regular.tint(Color.red.opacity(0.2)), in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
    }

    // MARK: - Safety Score

    private var safetyScoreCard: some View {
        let score = nutrition.safetyScore

        return ZStack {
            Circle()
                .stroke(safetyColor.opacity(0.15), lineWidth: 12)
                .frame(width: 180, height: 180)

            Circle()
                .trim(from: 0, to: CGFloat(score / 100))
                .stroke(safetyColor.gradient, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .frame(width: 180, height: 180)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: score)

            VStack(spacing: 4) {
                Image(systemName: safetyIcon)
                    .font(.title)
                    .foregroundStyle(safetyColor)

                Text(String(format: "%.0f%%", score))
                    .font(.system(size: 32, weight: .bold, design: .rounded))

                Text(nutrition.safetyStatus.rawValue)
                    .font(.caption.bold())
                    .foregroundStyle(safetyColor)

                Text("\(nutrition.todaySafeCount) safe / \(nutrition.todayUnsafeCount) unsafe")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var safetyColor: Color {
        switch nutrition.safetyStatus {
        case .allSafe, .noMeals: return AppTheme.primary
        case .warning: return .orange
        case .critical: return .red
        }
    }

    private var safetyIcon: String {
        switch nutrition.safetyStatus {
        case .allSafe: return "checkmark.shield.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .critical: return "xmark.shield.fill"
        case .noMeals: return "fork.knife"
        }
    }

    // MARK: - Quick Log (Whitelist)

    private var quickLogSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Quick Log (Safe Foods)")
                    .font(.headline)
                Spacer()
                Text("\(nutrition.todayMeals.count)/\(NutritionManager.maxDailyMeals)")
                    .font(.caption)
                    .foregroundStyle(nutrition.todayMeals.count >= NutritionManager.maxDailyMeals ? .red : .secondary)
            }
            .padding(.horizontal)

            // Proteins
            quickLogRow(title: "Proteins", items: FoodRegistry.safeProteins, category: .protein, icon: "fish.fill", color: AppTheme.primary)

            // Carbs
            quickLogRow(title: "Carbs", items: FoodRegistry.safeCarbs, category: .carb, icon: "leaf.fill", color: AppTheme.accent)

            // Fats
            quickLogRow(title: "Fats", items: FoodRegistry.safeFats, category: .fat, icon: "drop.halffull", color: AppTheme.secondary)
        }
    }

    private func quickLogRow(title: String, items: [String], category: FoodCategory, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.subheadline.bold())
                .foregroundStyle(color)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(items, id: \.self) { item in
                        Button {
                            nutrition.logSafeMeal(item, category: category, context: context)
                        } label: {
                            Text(item)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.glass)
                        .disabled(!nutrition.canLog)
                        .opacity(nutrition.canLog ? 1 : 0.5)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Triggers Card

    private var triggersCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Triggers Hit Today", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(.red)
            Divider()
            ForEach(Array(nutrition.todayTriggers).sorted(), id: \.self) { trigger in
                HStack {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.red)
                        .font(.caption)
                    Text(trigger)
                        .font(.subheadline)
                    Spacer()
                }
            }
            ForEach(nutrition.todayUnsafe) { meal in
                HStack {
                    Text(meal.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(meal.triggers.joined(separator: ", "))
                        .font(.caption2)
                        .foregroundStyle(.red)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(Color.red.opacity(0.15)), in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
    }

    // MARK: - History Card

    private var historyCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Today's Meals", systemImage: "list.bullet")
                .font(.headline)
                .foregroundStyle(AppTheme.secondary)
            Divider()
            ForEach(nutrition.todayMeals.prefix(12)) { meal in
                HStack {
                    Image(systemName: meal.isSafe ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(meal.isSafe ? AppTheme.primary : .red)
                        .font(.caption)
                    Text(meal.name)
                        .font(.subheadline)
                    Spacer()
                    Text(meal.category)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Text(meal.timestamp.formatted(date: .omitted, time: .shortened))
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

    // MARK: - Custom Log Sheet

    private var customLogSheet: some View {
        NavigationStack {
            Form {
                Section("Food Name") {
                    TextField("e.g. Grilled Chicken", text: $customName)
                        .onChange(of: customName) { _, newValue in
                            if newValue.count > NutritionManager.maxFoodNameLength {
                                customName = String(newValue.prefix(NutritionManager.maxFoodNameLength))
                            }
                        }
                    Text("\(customName.count)/\(NutritionManager.maxFoodNameLength)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Section("Category") {
                    Picker("Category", selection: $customCategory) {
                        ForEach(FoodCategory.allCases, id: \.self) { cat in
                            Text(cat.rawValue.capitalized).tag(cat)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                if !customName.isEmpty {
                    let result = FoodRegistry.classify(customName)
                    Section("Classification") {
                        HStack {
                            Image(systemName: result.isSafe ? "checkmark.shield.fill" : "xmark.shield.fill")
                                .foregroundStyle(result.isSafe ? AppTheme.primary : .red)
                            Text(result.isSafe ? "Safe" : "Unsafe")
                                .font(.headline)
                                .foregroundStyle(result.isSafe ? AppTheme.primary : .red)
                        }
                        if !result.triggers.isEmpty {
                            ForEach(result.triggers, id: \.self) { trigger in
                                Label(trigger.rawValue, systemImage: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Log Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showCustomLog = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Log") {
                        guard !customName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                        nutrition.logMeal(customName, category: customCategory, context: context)
                        customName = ""
                        showCustomLog = false
                    }
                    .disabled(customName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !nutrition.canLog)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
