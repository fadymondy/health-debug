import SwiftUI
import SwiftData
import HealthDebugKit

struct IntelligenceView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var ai = AIService.shared
    @StateObject private var analytics = AnalyticsEngine.shared
    @StateObject private var rag = HealthRAG.shared
    @Query(UserProfile.currentDescriptor()) private var profiles: [UserProfile]
    @Query(SleepConfig.currentDescriptor()) private var sleepConfigs: [SleepConfig]

    @State private var showAPISettings = false
    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // AI provider badge
                    providerBadge

                    // AI Chat inline
                    chatSection

                    // Domain insights stack
                    insightsSection

                    // Full analysis
                    if !analytics.lastAnalysis.isEmpty {
                        analysisSection
                    }

                    // Smart analyze button
                    analyzeButton

                    // Export share
                    shareButton
                }
                .padding(.vertical)
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Intelligence")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAPISettings = true
                    } label: {
                        Image(systemName: ai.selectedProvider == .apple ? "apple.intelligence" : "cloud.fill")
                            .font(.subheadline)
                    }
                }
            }
            .sheet(isPresented: $showAPISettings) {
                APISettingsSheet()
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: shareItems)
            }
        }
    }

    // MARK: - Provider Badge

    private var providerBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: ai.selectedProvider == .apple ? "apple.intelligence" : "cloud.fill")
                .foregroundStyle(ai.selectedProvider == .apple ? AppTheme.primary : AppTheme.accent)
            Text(ai.selectedProvider.rawValue)
                .font(.subheadline.bold())
            Spacer()
            if ai.selectedProvider == .apple {
                Text(ai.isAppleAIAvailable ? "Ready" : "Unavailable")
                    .font(.caption2.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .glassEffect(
                        .regular.tint((ai.isAppleAIAvailable ? AppTheme.primary : Color.orange).opacity(0.3)),
                        in: Capsule()
                    )
                    .foregroundStyle(ai.isAppleAIAvailable ? AppTheme.primary : .orange)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .glassEffect(
            .regular.tint((ai.isConfigured ? AppTheme.primary : Color.orange).opacity(0.1)),
            in: RoundedRectangle(cornerRadius: 20)
        )
        .padding(.horizontal)
    }

    // MARK: - Inline Chat

    private var chatSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Messages (last 6, no scroll — tap to open full chat)
            if !rag.messages.isEmpty {
                VStack(spacing: 8) {
                    ForEach(rag.messages.suffix(4)) { message in
                        inlineBubble(message)
                    }
                    if rag.isProcessing {
                        HStack {
                            HStack(spacing: 6) {
                                ProgressView().controlSize(.small)
                                Text("Thinking...")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(10)
                            .glassEffect(.regular.tint(AppTheme.secondary.opacity(0.1)), in: RoundedRectangle(cornerRadius: 14))
                            Spacer()
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 8)
            } else {
                // Smart prompt suggestions
                smartPromptsGrid
                    .padding(.bottom, 8)
            }

            // Input bar
            chatInputBar
        }
        .padding(.vertical, 12)
        .glassEffect(.regular.tint(AppTheme.primary.opacity(0.08)), in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
    }

    private func inlineBubble(_ message: HealthRAG.Message) -> some View {
        HStack(alignment: .top, spacing: 0) {
            if message.role == .user { Spacer(minLength: 40) }
            Text(cleanTags(message.content))
                .font(.subheadline)
                .padding(10)
                .glassEffect(
                    .regular.tint((message.role == .user ? AppTheme.primary : AppTheme.secondary).opacity(0.15)),
                    in: RoundedRectangle(cornerRadius: 14)
                )
                .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)
            if message.role == .assistant { Spacer(minLength: 40) }
        }
        .padding(.horizontal)
    }

    private var smartPromptsGrid: some View {
        LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 8) {
            smartPromptButton("How am I doing today?", icon: "chart.bar.fill")
            smartPromptButton("What should I eat now?", icon: "fork.knife")
            smartPromptButton("Analyze my sleep", icon: "moon.zzz.fill")
            smartPromptButton("Caffeine advice", icon: "cup.and.saucer.fill")
        }
        .padding(.horizontal)
    }

    private func smartPromptButton(_ text: String, icon: String) -> some View {
        Button {
            Task {
                await rag.send(text, context: context, profile: profile, sleepConfig: sleepConfigs.first)
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(AppTheme.primary)
                Text(text)
                    .font(.caption)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                Spacer()
            }
            .padding(10)
        }
        .buttonStyle(.glass)
        .disabled(rag.isProcessing)
    }

    @State private var chatInput = ""
    @FocusState private var chatFocused: Bool

    private var chatInputBar: some View {
        HStack(spacing: 10) {
            TextField("Ask your health AI...", text: $chatInput, axis: .vertical)
                .lineLimit(1...3)
                .textFieldStyle(.plain)
                .focused($chatFocused)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .glassEffect(.regular.tint(AppTheme.secondary.opacity(0.1)), in: RoundedRectangle(cornerRadius: 14))

            Button {
                sendChat()
            } label: {
                Image(systemName: "arrow.up")
                    .font(.subheadline.bold())
                    .padding(10)
            }
            .buttonStyle(.glassProminent)
            .tint(AppTheme.primary)
            .buttonBorderShape(.circle)
            .disabled(chatInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || rag.isProcessing)
        }
        .padding(.horizontal, 12)
    }

    private func sendChat() {
        let text = chatInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        chatInput = ""
        chatFocused = false
        Task {
            await rag.send(text, context: context, profile: profile, sleepConfig: sleepConfigs.first)
        }
    }

    private func cleanTags(_ text: String) -> String {
        text.replacingOccurrences(of: #"\[ACTION:[^\]]+\]"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Domain Insights

    private var insightsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Label("AI Insights", systemImage: "sparkles")
                    .font(.headline)
                    .foregroundStyle(AppTheme.primary)
                Spacer()
            }
            .padding(.horizontal)

            VStack(spacing: 12) {
                AIInsightCard(domain: .dashboard)
                AIInsightCard(domain: .hydration)
                AIInsightCard(domain: .nutrition)
                AIInsightCard(domain: .caffeine)
                AIInsightCard(domain: .shutdown)
            }
        }
    }

    // MARK: - Full Analysis

    private var analysisSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Full Analysis", systemImage: "brain.head.profile.fill")
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

    // MARK: - Analyze Button

    private var analyzeButton: some View {
        GlassEffectContainer {
            Button {
                runAnalysis()
            } label: {
                HStack {
                    if ai.isLoading {
                        ProgressView().controlSize(.small)
                        Text(ai.selectedProvider == .apple ? "Analyzing on-device..." : "Analyzing 72h of data...")
                    } else {
                        Label("Analyze My Health", systemImage: "brain.head.profile.fill")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .tint(AppTheme.primary)
            .controlSize(.large)
            .disabled(ai.isLoading || !ai.isConfigured)
        }
        .padding(.horizontal)
    }

    // MARK: - Share Button

    private var shareButton: some View {
        GlassEffectContainer {
            HStack(spacing: 12) {
                Button {
                    sharePDF()
                } label: {
                    Label("Share PDF", systemImage: "doc.richtext.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .tint(AppTheme.secondary)
                .controlSize(.large)

                Button {
                    shareMarkdown()
                } label: {
                    Label("Markdown", systemImage: "text.badge.star")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glass)
                .controlSize(.large)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    // MARK: - Actions

    private func runAnalysis() {
        let healthContext = analytics.buildContext(context: context, profile: profile, sleepConfig: sleepConfigs.first)
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

    private func sharePDF() {
        let healthContext = analytics.buildContext(context: context, profile: profile, sleepConfig: sleepConfigs.first)
        let pdfData = PDFReportGenerator.shared.generateReport(
            healthContext: healthContext,
            aiAnalysis: analytics.lastAnalysis.isEmpty ? nil : analytics.lastAnalysis,
            profile: profile
        )
        let fileName = "HealthDebug-Report-\(Date.now.formatted(.iso8601.dateSeparator(.dash))).pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try? pdfData.write(to: tempURL)
        shareItems = [tempURL]
        showShareSheet = true
    }

    private func shareMarkdown() {
        let healthContext = analytics.buildContext(context: context, profile: profile, sleepConfig: sleepConfigs.first)
        let md = buildMarkdown(context: healthContext)
        let fileName = "HealthDebug-\(Date.now.formatted(.iso8601.dateSeparator(.dash))).md"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try? md.write(to: tempURL, atomically: true, encoding: .utf8)
        shareItems = [tempURL]
        showShareSheet = true
    }

    private func buildMarkdown(context ctx: HealthContext) -> String {
        let date = Date.now.formatted(date: .abbreviated, time: .shortened)
        var md = """
        # Health Debug Report
        *Generated: \(date)*

        ## Profile
        - Weight: \(String(format: "%.1f", ctx.profile?.weightKg ?? 0)) kg
        - BMI: \(String(format: "%.1f", ctx.profile?.bmi ?? 0))
        - Daily water goal: \(ctx.profile?.dailyWaterGoalMl ?? 0) ml

        ## Hydration (72h)
        - Total: \(ctx.hydration.totalMl) ml / \(ctx.hydration.goalMl) ml goal
        - Logs: \(ctx.hydration.logCount)

        ## Nutrition (72h)
        - Total meals: \(ctx.nutrition.totalMeals) (\(ctx.nutrition.safeMeals) safe, \(ctx.nutrition.unsafeMeals) unsafe)
        """
        if !ctx.nutrition.triggersHit.isEmpty {
            md += "\n- Triggers: \(ctx.nutrition.triggersHit.joined(separator: ", "))"
        }
        md += """

        ## Caffeine (72h)
        - Total: \(ctx.caffeine.totalDrinks) (\(ctx.caffeine.cleanBased) clean, \(ctx.caffeine.sugarBased) sugar)

        ## Movement (72h)
        - Stand sessions: \(ctx.movement.completedWalks) / \(ctx.movement.targetSessions) target

        ## Sleep Config
        - Target: \(String(format: "%02d:%02d", ctx.sleep.targetHour, ctx.sleep.targetMinute))
        - Shutdown window: \(ctx.sleep.shutdownWindowHours)h before sleep
        """
        if !analytics.lastAnalysis.isEmpty {
            md += "\n\n## AI Analysis\n\(analytics.lastAnalysis)"
        }
        return md
    }
}

// MARK: - ShareSheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
