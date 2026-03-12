import SwiftUI

// MARK: - Widget Card Model

struct WidgetCard: Identifiable {
    let id: String
    let title: LocalizedStringKey
    let icon: String
    let color: Color
    let description: LocalizedStringKey
    let supportsLockScreen: Bool
    let families: [String]
}

// MARK: - Widget Gallery Data

@MainActor private let allWidgetCards: [WidgetCard] = [
    WidgetCard(
        id: "steps",
        title: "Steps",
        icon: "figure.walk",
        color: .green,
        description: "Track your daily step count and goal.",
        supportsLockScreen: true,
        families: ["Small", "Medium", "Large"]
    ),
    WidgetCard(
        id: "energy",
        title: "Energy",
        icon: "flame.fill",
        color: .orange,
        description: "Monitor active energy burned.",
        supportsLockScreen: false,
        families: ["Small", "Medium"]
    ),
    WidgetCard(
        id: "heartRate",
        title: "Heart Rate",
        icon: "heart.fill",
        color: .red,
        description: "View your latest BPM and zone.",
        supportsLockScreen: true,
        families: ["Small", "Medium"]
    ),
    WidgetCard(
        id: "sleep",
        title: "Sleep",
        icon: "moon.stars.fill",
        color: .purple,
        description: "See how many hours you slept.",
        supportsLockScreen: true,
        families: ["Small", "Medium"]
    ),
    WidgetCard(
        id: "hydration",
        title: "Hydration",
        icon: "drop.fill",
        color: .blue,
        description: "Track water intake toward your goal.",
        supportsLockScreen: true,
        families: ["Small", "Medium"]
    ),
    WidgetCard(
        id: "standTimer",
        title: "Stand Timer",
        icon: "timer",
        color: .teal,
        description: "Monitor Pomodoro sessions and phase.",
        supportsLockScreen: true,
        families: ["Small", "Medium"]
    ),
    WidgetCard(
        id: "nutrition",
        title: "Nutrition",
        icon: "fork.knife",
        color: .green,
        description: "View meal safety score and meal count.",
        supportsLockScreen: false,
        families: ["Small", "Medium"]
    ),
    WidgetCard(
        id: "caffeine",
        title: "Caffeine",
        icon: "cup.and.saucer.fill",
        color: .brown,
        description: "Track caffeine and clean drink status.",
        supportsLockScreen: false,
        families: ["Small", "Medium"]
    ),
    WidgetCard(
        id: "shutdown",
        title: "Shutdown",
        icon: "moon.zzz.fill",
        color: .red,
        description: "Monitor GERD shutdown timer.",
        supportsLockScreen: false,
        families: ["Small", "Medium"]
    ),
    WidgetCard(
        id: "weight",
        title: "Weight",
        icon: "scalemass.fill",
        color: .blue,
        description: "View latest weight and body fat.",
        supportsLockScreen: false,
        families: ["Small", "Medium"]
    ),
    WidgetCard(
        id: "dailyFlow",
        title: "Daily Flow",
        icon: "checklist",
        color: .green,
        description: "See your daily health goals score.",
        supportsLockScreen: true,
        families: ["Small", "Medium", "Large"]
    )
]

// MARK: - Widget Gallery View

struct WidgetGalleryView: View {

    @State private var selectedCard: WidgetCard?

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    private var lockScreenCards: [WidgetCard] {
        allWidgetCards.filter { $0.supportsLockScreen }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // MARK: Home Screen Widgets
                sectionHeader(LocalizedStringKey("Home Screen Widgets"))

                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(allWidgetCards) { card in
                        WidgetPreviewCard(card: card)
                            .onTapGesture {
                                selectedCard = card
                            }
                    }
                }

                // MARK: Lock Screen Widgets
                sectionHeader(LocalizedStringKey("Lock Screen Widgets"))

                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(lockScreenCards) { card in
                        WidgetPreviewCard(card: card)
                            .onTapGesture {
                                selectedCard = card
                            }
                    }
                }

                // MARK: How to Add Instructions
                HowToAddCard()
            }
            .padding()
        }
        .navigationTitle(LocalizedStringKey("Widget Gallery"))
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $selectedCard) { card in
            WidgetDetailSheet(card: card)
        }
    }

    @ViewBuilder
    private func sectionHeader(_ title: LocalizedStringKey) -> some View {
        Text(title)
            .font(.title3.bold())
            .padding(.top, 4)
    }
}

// MARK: - Widget Preview Card

struct WidgetPreviewCard: View {
    let card: WidgetCard

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            // Icon in glass circle
            ZStack {
                Circle()
                    .fill(card.color.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: card.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(card.color)
            }

            // Title
            Text(card.title)
                .font(.headline)
                .foregroundStyle(.primary)

            // Description
            Text(card.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            // Chips row
            familyChipsRow
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(card.color.opacity(0.08)), in: RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private var familyChipsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 5) {
                ForEach(card.families, id: \.self) { family in
                    SizeChip(label: LocalizedStringKey(family), color: card.color)
                }
                if card.supportsLockScreen {
                    SizeChip(label: LocalizedStringKey("Lock Screen"), color: .purple)
                }
            }
        }
    }
}

// MARK: - Size Chip

struct SizeChip: View {
    let label: LocalizedStringKey
    let color: Color

    var body: some View {
        Text(label)
            .font(.caption2.bold())
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .glassEffect(.regular.tint(color.opacity(0.15)), in: Capsule())
    }
}

// MARK: - How to Add Card

struct HowToAddCard: View {

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(AppTheme.primary)
                Text(LocalizedStringKey("How to Add"))
                    .font(.headline)
            }

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                InstructionRow(number: 1, text: LocalizedStringKey("Long-press your home screen, then tap the + button"))
                InstructionRow(number: 2, text: LocalizedStringKey("Search for Health Debug"))
                InstructionRow(number: 3, text: LocalizedStringKey("Choose this widget and size"))
                InstructionRow(number: 4, text: LocalizedStringKey("Tap Add Widget, then Done"))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(AppTheme.primary.opacity(0.08)), in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Instruction Row

struct InstructionRow: View {
    let number: Int
    let text: LocalizedStringKey

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppTheme.primary.opacity(0.15))
                    .frame(width: 24, height: 24)
                Text("\(number)")
                    .font(.caption.bold())
                    .foregroundStyle(AppTheme.primary)
            }

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
    }
}

// MARK: - Widget Detail Sheet

struct WidgetDetailSheet: View {
    let card: WidgetCard

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // Hero icon + title
                    VStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(card.color.opacity(0.15))
                                .frame(width: 72, height: 72)
                            Image(systemName: card.icon)
                                .font(.system(size: 34, weight: .semibold))
                                .foregroundStyle(card.color)
                        }

                        Text(card.title)
                            .font(.title2.bold())

                        Text(card.description)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)

                    // Sizes supported
                    sizesSection

                    // Home screen steps
                    homeScreenStepsCard

                    // Lock screen steps (conditionally shown)
                    if card.supportsLockScreen {
                        lockScreenStepsCard
                    }

                    // Open widget picker button
                    // Note: `widgetkit://add` is a placeholder custom scheme.
                    // iOS does not natively support this URL — it will silently fail,
                    // but is kept here as a deep-link hook for future implementation
                    // (e.g. a custom URL scheme registered by a companion app or
                    // a WidgetKit intent extension).
                    Button {
                        openURL(URL(string: "widgetkit://add")!)
                    } label: {
                        Label(LocalizedStringKey("Open Widget Picker"), systemImage: "plus.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(card.color)
                }
                .padding()
            }
            .navigationTitle(card.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(LocalizedStringKey("Done")) {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: Sizes Section

    @ViewBuilder
    private var sizesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(LocalizedStringKey("Sizes Supported"))
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                ForEach(card.families, id: \.self) { family in
                    SizeChip(label: LocalizedStringKey(family), color: card.color)
                }
                if card.supportsLockScreen {
                    SizeChip(label: LocalizedStringKey("Lock Screen"), color: .purple)
                }
                Spacer()
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(card.color.opacity(0.08)), in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: Home Screen Steps

    @ViewBuilder
    private var homeScreenStepsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "iphone")
                    .foregroundStyle(card.color)
                Text(LocalizedStringKey("Add to Home Screen"))
                    .font(.headline)
            }

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                InstructionRow(number: 1, text: LocalizedStringKey("Long-press your home screen, then tap the + button"))
                InstructionRow(number: 2, text: LocalizedStringKey("Search for Health Debug"))
                InstructionRow(number: 3, text: LocalizedStringKey("Choose this widget and size"))
                InstructionRow(number: 4, text: LocalizedStringKey("Tap Add Widget, then Done"))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(card.color.opacity(0.08)), in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: Lock Screen Steps

    @ViewBuilder
    private var lockScreenStepsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "lock.rectangle")
                    .foregroundStyle(.purple)
                Text(LocalizedStringKey("Add to Lock Screen"))
                    .font(.headline)
            }

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                InstructionRow(number: 1, text: LocalizedStringKey("For lock screen, swipe up on your lock screen and tap Customize"))
                InstructionRow(number: 2, text: LocalizedStringKey("Search for Health Debug"))
                InstructionRow(number: 3, text: LocalizedStringKey("Choose this widget and size"))
                InstructionRow(number: 4, text: LocalizedStringKey("Tap Add Widget, then Done"))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(Color.purple.opacity(0.08)), in: RoundedRectangle(cornerRadius: 16))
    }
}
