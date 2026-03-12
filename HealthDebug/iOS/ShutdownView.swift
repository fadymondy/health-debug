import SwiftUI
import SwiftData
import HealthDebugKit

struct ShutdownView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var shutdown = ShutdownManager.shared
    @Query(SleepConfig.currentDescriptor()) private var sleepConfigs: [SleepConfig]

    private var config: SleepConfig? { sleepConfigs.first }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                shutdownRing
                statusCard
                AIInsightCard(domain: .shutdown)
                allowedItemsCard
                infoCard
            }
            .padding(.vertical)
        }
        .navigationTitle(LocalizedStringKey("Shutdown"))
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            shutdown.startCountdown(config: config)
        }
        .onDisappear {
            shutdown.stopCountdown()
        }
    }

    // MARK: - Shutdown Ring

    private var shutdownRing: some View {
        ZStack {
            Circle()
                .stroke(ringColor.opacity(0.15), lineWidth: 12)
                .frame(width: 220, height: 220)

            Circle()
                .trim(from: 0, to: ringProgress)
                .stroke(ringColor.gradient, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .frame(width: 220, height: 220)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: ringProgress)

            VStack(spacing: 6) {
                Image(systemName: shutdownIcon)
                    .font(.system(size: 28))
                    .foregroundStyle(ringColor)
                    .symbolEffect(.pulse, isActive: shutdown.state == .active)

                Text(countdownText)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .monospacedDigit()

                Text(subtitleText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Status Card

    private var statusCard: some View {
        VStack(spacing: 12) {
            switch shutdown.state {
            case .inactive:
                VStack(spacing: 8) {
                    Text("System Active")
                        .font(.title2.bold())
                        .foregroundStyle(AppTheme.primary)
                    VStack(spacing: 2) {
                        Text("You can eat normally. Shutdown begins at")
                        Text(shutdownTimeString)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .glassEffect(.regular.tint(AppTheme.primary.opacity(0.15)), in: RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal)

            case .active:
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("System Shutdown Active")
                            .font(.title3.bold())
                            .foregroundStyle(.orange)
                    }
                    Text("No food until tomorrow. Only water, chamomile tea, or anise tea.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .glassEffect(.regular.tint(Color.orange.opacity(0.2)), in: RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal)

            case .violated:
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "xmark.octagon.fill")
                            .foregroundStyle(.red)
                        Text("Shutdown Violated")
                            .font(.title3.bold())
                            .foregroundStyle(.red)
                    }
                    Text("GERD/Sinus flare-up risk elevated. Avoid lying down for at least 3 hours after eating.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .glassEffect(.regular.tint(Color.red.opacity(0.2)), in: RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Allowed Items

    private var allowedItemsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(shutdown.state == .active ? "Allowed Now" : "Allowed During Shutdown", systemImage: "checkmark.shield.fill")
                .font(.headline)
                .foregroundStyle(AppTheme.accent)
            Divider()
            ForEach(ShutdownManager.allowedDrinks, id: \.self) { drink in
                HStack {
                    Image(systemName: iconForDrink(drink))
                        .foregroundStyle(AppTheme.accent)
                        .frame(width: 24)
                    Text(LocalizedStringKey(drink))
                        .font(.subheadline)
                    Spacer()
                    Image(systemName: "checkmark")
                        .foregroundStyle(AppTheme.primary)
                        .font(.caption)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(AppTheme.accent.opacity(0.15)), in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
    }

    // MARK: - Info Card

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Why Shutdown?", systemImage: "info.circle.fill")
                .font(.headline)
                .foregroundStyle(AppTheme.secondary)
            Divider()
            Text("Eating within 4 hours of sleep increases gastric acid reflux (GERD) and can trigger sinus inflammation. The shutdown window gives your digestive system time to clear before lying down.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Chamomile and anise teas are anti-inflammatory and safe for the digestive tract before sleep.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.top, 2)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(AppTheme.secondary.opacity(0.1)), in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
    }

    // MARK: - Computed Properties

    private var ringProgress: CGFloat {
        guard let config else { return 0 }
        let totalWindow = TimeInterval(config.shutdownWindowHours * 3600)
        switch shutdown.state {
        case .inactive:
            return 0
        case .active, .violated:
            let elapsed = totalWindow - shutdown.secondsUntilSleep
            return min(1.0, max(0, CGFloat(elapsed / totalWindow)))
        }
    }

    private var ringColor: Color {
        switch shutdown.state {
        case .inactive: return AppTheme.primary
        case .active: return .orange
        case .violated: return .red
        }
    }

    private var shutdownIcon: String {
        switch shutdown.state {
        case .inactive: return "sun.max.fill"
        case .active: return "moon.fill"
        case .violated: return "exclamationmark.triangle.fill"
        }
    }

    private var countdownText: String {
        switch shutdown.state {
        case .inactive:
            return ShutdownManager.formatCountdown(shutdown.secondsUntilShutdown)
        case .active, .violated:
            return ShutdownManager.formatCountdown(shutdown.secondsUntilSleep)
        }
    }

    private var subtitleText: String {
        switch shutdown.state {
        case .inactive: return NSLocalizedString("Until shutdown", comment: "")
        case .active: return NSLocalizedString("Until sleep", comment: "")
        case .violated: return NSLocalizedString("Until sleep (violated)", comment: "")
        }
    }

    private var shutdownTimeString: String {
        guard let time = shutdown.shutdownStartTime else { return "--:--" }
        return time.formatted(date: .omitted, time: .shortened)
    }

    private func iconForDrink(_ drink: String) -> String {
        if drink.contains("Water") { return "drop.fill" }
        if drink.contains("Chamomile") { return "leaf.fill" }
        if drink.contains("Anise") { return "cup.and.saucer.fill" }
        return "cup.and.saucer"
    }
}
