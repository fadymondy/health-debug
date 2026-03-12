import SwiftUI
import SwiftData
import HealthDebugKit

struct CaffeineView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var caffeine = CaffeineManager.shared
    @Query(UserProfile.currentDescriptor()) private var profiles: [UserProfile]
    @Query(CaffeineLog.todayDescriptor()) private var todayLogs: [CaffeineLog]

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                caffeineBlockCard
                transitionRing
                AIInsightCard(domain: .caffeine)
                quickLogGrid
                fattyLiverCard
                if !todayLogs.isEmpty {
                    historyCard
                }
            }
            .padding(.vertical)
        }
        .navigationTitle(LocalizedStringKey("Caffeine"))
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            caffeine.refresh(context: context)
        }
    }

    // MARK: - Caffeine Block Card

    private var caffeineBlockCard: some View {
        let inBlock = caffeine.isInCaffeineBlock(profile: profile)
        let remaining = caffeine.caffeineBlockMinutesRemaining(profile: profile)

        return VStack(spacing: 8) {
            if inBlock {
                HStack {
                    Image(systemName: "hand.raised.fill")
                        .foregroundStyle(.orange)
                    Text("Caffeine Block Active")
                        .font(.title3.bold())
                        .foregroundStyle(.orange)
                }
                VStack(spacing: 2) {
                    HStack(spacing: 4) {
                        Text("\(remaining)")
                        Text("min left")
                    }
                    Text("Cortisol is naturally high after waking — caffeine won't help yet.")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            } else {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppTheme.primary)
                    Text("Caffeine Window Open")
                        .font(.title3.bold())
                        .foregroundStyle(AppTheme.primary)
                }
                Text("You can have caffeine now. Prefer clean sources.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .glassEffect(.regular.tint((inBlock ? Color.orange : AppTheme.primary).opacity(0.15)), in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
    }

    // MARK: - Transition Ring

    private var transitionRing: some View {
        let progress = caffeine.cleanTransitionPercent / 100.0

        return ZStack {
            Circle()
                .stroke(AppTheme.primary.opacity(0.15), lineWidth: 12)
                .frame(width: 180, height: 180)

            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(transitionGradient, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .frame(width: 180, height: 180)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)

            VStack(spacing: 4) {
                Image(systemName: "cup.and.saucer.fill")
                    .font(.title)
                    .foregroundStyle(transitionColor)

                Text(String(format: "%.0f%%", caffeine.cleanTransitionPercent))
                    .font(.system(size: 32, weight: .bold, design: .rounded))

                Text(LocalizedStringKey(caffeine.transitionStatus.rawValue))
                    .font(.caption.bold())
                    .foregroundStyle(transitionColor)
            }
        }
    }

    private var transitionGradient: AngularGradient {
        AngularGradient(
            colors: [AppTheme.primary, AppTheme.accent],
            center: .center,
            startAngle: .degrees(-90),
            endAngle: .degrees(270)
        )
    }

    private var transitionColor: Color {
        switch caffeine.transitionStatus {
        case .clean, .noIntake: return AppTheme.primary
        case .transitioning: return .orange
        case .redBullDependent: return .red
        }
    }

    // MARK: - Quick Log Grid

    private var quickLogGrid: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Log Caffeine")
                .font(.headline)
                .padding(.horizontal)

            if !caffeine.canLog {
                if caffeine.todayTotal >= CaffeineManager.maxDailyLogs {
                    HStack(spacing: 4) {
                        Text("Daily limit reached")
                        Text("(\(CaffeineManager.maxDailyLogs)")
                        Text("drinks)")
                    }
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .padding(.horizontal)
                } else {
                    Text("Wait a moment before logging again")
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .padding(.horizontal)
                }
            }

            LazyVGrid(columns: [.init(.flexible()), .init(.flexible()), .init(.flexible())], spacing: 10) {
                ForEach(CaffeineType.allCases, id: \.self) { type in
                    Button {
                        caffeine.logCaffeine(type, context: context, profile: profile)
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: iconFor(type))
                                .font(.title2)
                                .foregroundStyle(type.isSugarBased ? .red : AppTheme.primary)
                            Text(LocalizedStringKey(type.rawValue))
                                .font(.caption2)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(.glass)
                    .disabled(!caffeine.canLog)
                    .opacity(caffeine.canLog ? 1 : 0.5)
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Fatty Liver Card

    private var fattyLiverCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Liver Health", systemImage: caffeine.fattyLiverAlert ? "exclamationmark.triangle.fill" : "liver.fill")
                .font(.headline)
                .foregroundStyle(caffeine.fattyLiverAlert ? .red : AppTheme.primary)
            Divider()
            Text(caffeine.fattyLiverMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack {
                VStack(alignment: .leading) {
                    Text("Clean")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(caffeine.todayCleanCount)")
                        .font(.title3.bold())
                        .foregroundStyle(AppTheme.primary)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Sugar")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(caffeine.todaySugarCount)")
                        .font(.title3.bold())
                        .foregroundStyle(caffeine.todaySugarCount > 0 ? .red : .secondary)
                }
            }
            .padding(.top, 4)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint((caffeine.fattyLiverAlert ? Color.red : AppTheme.primary).opacity(0.15)), in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
    }

    // MARK: - History Card

    private var historyCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Today's Intake", systemImage: "list.bullet")
                .font(.headline)
                .foregroundStyle(AppTheme.secondary)
            Divider()
            ForEach(todayLogs.prefix(10)) { log in
                HStack {
                    Image(systemName: log.isSugarBased ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
                        .foregroundStyle(log.isSugarBased ? .red : AppTheme.primary)
                        .font(.caption)
                    Text(LocalizedStringKey(log.type))
                        .font(.subheadline)
                    Spacer()
                    if log.isSugarBased {
                        Text("SUGAR")
                            .font(.caption2.bold())
                            .foregroundStyle(.red)
                    }
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

    // MARK: - Helpers

    private func iconFor(_ type: CaffeineType) -> String {
        switch type {
        case .redBull: return "bolt.fill"
        case .coldBrew: return "cup.and.saucer.fill"
        case .matcha: return "leaf.fill"
        case .greenTea: return "leaf"
        case .espresso: return "cup.and.saucer"
        case .blackCoffee: return "mug.fill"
        case .other: return "ellipsis.circle"
        }
    }
}
