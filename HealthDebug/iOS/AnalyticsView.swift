import SwiftUI
import SwiftData
import HealthDebugKit

struct AnalyticsView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var analytics = AnalyticsEngine.shared
    @StateObject private var ai = AIService.shared
    @Query(UserProfile.currentDescriptor()) private var profiles: [UserProfile]
    @Query(SleepConfig.currentDescriptor()) private var sleepConfigs: [SleepConfig]
    @State private var showAPISettings = false

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    providerCard
                    analyzeButton

                    if ai.isLoading {
                        loadingCard
                    }

                    if !analytics.lastAnalysis.isEmpty {
                        analysisCard
                    }

                    contextSummaryCard
                    exportCard
                }
                .padding(.vertical)
            }
            .navigationTitle("Analytics")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAPISettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                }
            }
            .sheet(isPresented: $showAPISettings) {
                APISettingsSheet()
            }
        }
    }

    // MARK: - Provider Card

    private var providerCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: ai.selectedProvider == .apple ? "apple.intelligence" : "cloud.fill")
                    .font(.title2)
                    .foregroundStyle(ai.selectedProvider == .apple ? AppTheme.primary : AppTheme.accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text(ai.selectedProvider.rawValue)
                        .font(.headline)
                    Text(ai.selectedProvider == .apple ? "Private, on-device, free" : ai.selectedProvider.modelName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if ai.selectedProvider == .apple {
                    statusBadge
                }
            }

            if ai.selectedProvider == .apple, case .unavailable(let reason) = ai.appleAIStatus {
                Text(reason)
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint((ai.isConfigured ? AppTheme.primary : Color.orange).opacity(0.15)), in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
    }

    private var statusBadge: some View {
        let available = ai.isAppleAIAvailable
        return Text(available ? "Ready" : "Unavailable")
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .glassEffect(.regular.tint((available ? AppTheme.primary : Color.orange).opacity(0.3)), in: Capsule())
            .foregroundStyle(available ? AppTheme.primary : .orange)
    }

    // MARK: - Analyze Button

    private var analyzeButton: some View {
        GlassEffectContainer {
            Button {
                runAnalysis()
            } label: {
                Label("Analyze My Health", systemImage: "brain.head.profile.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .tint(AppTheme.primary)
            .controlSize(.large)
            .disabled(ai.isLoading || !ai.isConfigured)
        }
        .padding(.horizontal)
    }

    // MARK: - Loading

    private var loadingCard: some View {
        VStack(spacing: 12) {
            ProgressView()
                .controlSize(.large)
            Text(ai.selectedProvider == .apple ? "Analyzing on-device..." : "Analyzing 72 hours of health data...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .glassEffect(.regular.tint(AppTheme.primary.opacity(0.1)), in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
    }

    // MARK: - Analysis Result

    private var analysisCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("AI Insights", systemImage: "sparkles")
                    .font(.headline)
                    .foregroundStyle(AppTheme.primary)
                Spacer()
                Text(ai.selectedProvider.rawValue)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Divider()
            MarkdownView(content: analytics.lastAnalysis)
                .textSelection(.enabled)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(AppTheme.primary.opacity(0.1)), in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
    }

    // MARK: - Context Summary

    private var contextSummaryCard: some View {
        let ctx = analytics.buildContext(
            context: context,
            profile: profile,
            sleepConfig: sleepConfigs.first
        )

        return VStack(alignment: .leading, spacing: 8) {
            Label("72-Hour Context", systemImage: "clock.arrow.circlepath")
                .font(.headline)
                .foregroundStyle(AppTheme.secondary)
            Divider()

            LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 8) {
                contextItem("Water", "\(ctx.hydration.totalMl) ml", icon: "drop.fill")
                contextItem("Meals", "\(ctx.nutrition.totalMeals) (\(ctx.nutrition.unsafeMeals) unsafe)", icon: "fork.knife")
                contextItem("Caffeine", "\(ctx.caffeine.totalDrinks) (\(ctx.caffeine.sugarBased) sugar)", icon: "cup.and.saucer.fill")
                contextItem("Walks", "\(ctx.movement.completedWalks) / \(ctx.movement.standSessions)", icon: "figure.walk")
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(AppTheme.secondary.opacity(0.1)), in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
    }

    private func contextItem(_ title: String, _ value: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(AppTheme.secondary)
                .font(.caption)
                .frame(width: 16)
            VStack(alignment: .leading) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.caption.bold())
            }
            Spacer()
        }
    }

    // MARK: - Export Card

    private var exportCard: some View {
        GlassEffectContainer {
            HStack(spacing: 12) {
                Button {
                    exportPDF()
                } label: {
                    Label("Export PDF", systemImage: "doc.richtext.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .tint(AppTheme.primary)
                .controlSize(.large)

                Button {
                    exportJSON()
                } label: {
                    Label("JSON", systemImage: "curlybraces")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glass)
                .controlSize(.large)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Actions

    private func runAnalysis() {
        let healthContext = analytics.buildContext(
            context: context,
            profile: profile,
            sleepConfig: sleepConfigs.first
        )
        let prompt = analytics.buildPrompt(healthContext: healthContext)

        Task {
            do {
                analytics.isAnalyzing = true
                let result = try await ai.analyze(prompt: prompt)
                analytics.lastAnalysis = result
                analytics.isAnalyzing = false
            } catch {
                analytics.lastAnalysis = "Error: \(error.localizedDescription)"
                analytics.isAnalyzing = false
            }
        }
    }

    private func exportPDF() {
        let healthContext = analytics.buildContext(
            context: context,
            profile: profile,
            sleepConfig: sleepConfigs.first
        )
        let pdfData = PDFReportGenerator.shared.generateReport(
            healthContext: healthContext,
            aiAnalysis: analytics.lastAnalysis.isEmpty ? nil : analytics.lastAnalysis,
            profile: profile
        )
        let fileName = "HealthDebug-Report-\(Date.now.formatted(.iso8601.dateSeparator(.dash))).pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try? pdfData.write(to: tempURL)

        let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }

    private func exportJSON() {
        guard let data = analytics.exportJSON(
            context: context,
            profile: profile,
            sleepConfig: sleepConfigs.first
        ) else { return }

        let fileName = "health-debug-\(Date.now.formatted(.iso8601.dateSeparator(.dash))).json"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try? data.write(to: tempURL)

        let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

// MARK: - API Settings Sheet

struct APISettingsSheet: View {
    @StateObject private var ai = AIService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var apiKey = ""
    @State private var selectedCloudProvider: AIService.Provider = .claude

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    // Apple Intelligence option
                    Button {
                        ai.selectedProvider = .apple
                    } label: {
                        HStack {
                            Image(systemName: "apple.intelligence")
                                .foregroundStyle(AppTheme.primary)
                                .frame(width: 24)
                            VStack(alignment: .leading) {
                                Text("Apple Intelligence")
                                    .font(.body)
                                Text("On-device, private, free")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if ai.selectedProvider == .apple {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(AppTheme.primary)
                            }
                        }
                    }
                    .tint(.primary)
                } header: {
                    Text("Default")
                } footer: {
                    if !ai.isAppleAIAvailable {
                        Text("Apple Intelligence is not available on this device. Enable it in Settings > Apple Intelligence & Siri.")
                    }
                }

                Section("Cloud Providers (Optional)") {
                    ForEach(AIService.Provider.cloudProviders, id: \.self) { provider in
                        Button {
                            ai.selectedProvider = provider
                            selectedCloudProvider = provider
                        } label: {
                            HStack {
                                Image(systemName: "cloud.fill")
                                    .foregroundStyle(AppTheme.accent)
                                    .frame(width: 24)
                                VStack(alignment: .leading) {
                                    Text(provider.rawValue)
                                        .font(.body)
                                    Text(provider.modelName)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if ai.hasAPIKey(for: provider) {
                                    Image(systemName: "key.fill")
                                        .font(.caption)
                                        .foregroundStyle(.green)
                                }
                                if ai.selectedProvider == provider {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(AppTheme.primary)
                                }
                            }
                        }
                        .tint(.primary)
                    }
                }

                if !ai.selectedProvider.isOnDevice {
                    Section("API Key — \(ai.selectedProvider.rawValue)") {
                        SecureField("Enter \(ai.selectedProvider.rawValue) API Key", text: $apiKey)
                            .textContentType(.password)

                        if ai.hasAPIKey(for: ai.selectedProvider) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text("Key configured")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Button("Remove", role: .destructive) {
                                    ai.deleteAPIKey(for: ai.selectedProvider)
                                }
                                .font(.caption)
                            }
                        }

                        Button("Save Key") {
                            guard !apiKey.isEmpty else { return }
                            ai.saveAPIKey(apiKey, for: ai.selectedProvider)
                            apiKey = ""
                        }
                        .disabled(apiKey.isEmpty)
                    }
                }
            }
            .navigationTitle("AI Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
