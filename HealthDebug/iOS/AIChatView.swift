import SwiftUI
import SwiftData
import HealthDebugKit

struct AIChatView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var rag = HealthRAG.shared
    @StateObject private var ai = AIService.shared
    @Query(UserProfile.currentDescriptor()) private var profiles: [UserProfile]
    @Query(SleepConfig.currentDescriptor()) private var sleepConfigs: [SleepConfig]
    @State private var inputText = ""
    @FocusState private var isInputFocused: Bool

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            if rag.messages.isEmpty {
                                welcomeCard
                                    .padding(.top, 20)
                            }
                            ForEach(rag.messages) { message in
                                chatBubble(message)
                                    .id(message.id)
                            }
                            if rag.isProcessing {
                                processingIndicator
                            }
                            if rag.pendingAction != .none {
                                smartActionCard
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                    .onChange(of: rag.messages.count) { _, _ in
                        if let last = rag.messages.last {
                            withAnimation {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }

                Divider()

                // Input bar
                HStack(spacing: 10) {
                    TextField("Ask about your health...", text: $inputText, axis: .vertical)
                        .lineLimit(1...4)
                        .textFieldStyle(.plain)
                        .focused($isInputFocused)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .glassEffect(.regular.tint(AppTheme.secondary.opacity(0.1)), in: RoundedRectangle(cornerRadius: 16))

                    Button {
                        sendMessage()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundStyle(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .secondary : AppTheme.primary)
                    }
                    .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || rag.isProcessing)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .navigationTitle("Health AI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !rag.messages.isEmpty {
                        Button {
                            rag.clearHistory()
                        } label: {
                            Image(systemName: "trash")
                                .font(.caption)
                        }
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 4) {
                        Image(systemName: ai.selectedProvider == .apple ? "apple.intelligence" : "cloud.fill")
                            .font(.caption)
                        Text(ai.selectedProvider.rawValue)
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Welcome Card

    private var welcomeCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "brain.head.profile.fill")
                .font(.system(size: 44))
                .foregroundStyle(AppTheme.gradient)

            Text("Health AI Assistant")
                .font(.title2.bold())

            Text("Ask me anything about your health data. I can analyze trends, suggest improvements, and even log entries for you.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            // Quick prompts
            VStack(spacing: 8) {
                quickPrompt("How's my hydration today?", icon: "drop.fill")
                quickPrompt("Analyze my caffeine habits", icon: "cup.and.saucer.fill")
                quickPrompt("Log 250ml of water", icon: "plus.circle.fill")
                quickPrompt("What should I eat right now?", icon: "fork.knife")
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .glassEffect(.regular.tint(AppTheme.primary.opacity(0.1)), in: RoundedRectangle(cornerRadius: 20))
    }

    private func quickPrompt(_ text: String, icon: String) -> some View {
        Button {
            inputText = text
            sendMessage()
        } label: {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(AppTheme.secondary)
                    .frame(width: 20)
                Text(text)
                    .font(.subheadline)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .buttonStyle(.glass)
    }

    // MARK: - Chat Bubble

    private func chatBubble(_ message: HealthRAG.Message) -> some View {
        HStack {
            if message.role == .user { Spacer(minLength: 60) }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                if message.role == .assistant {
                    // Use MarkdownView for AI responses
                    MarkdownView(content: cleanActionTags(message.content))
                } else {
                    Text(message.content)
                        .font(.subheadline)
                }

                Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(12)
            .glassEffect(
                .regular.tint((message.role == .user ? AppTheme.primary : AppTheme.secondary).opacity(0.15)),
                in: RoundedRectangle(cornerRadius: 16)
            )

            if message.role == .assistant { Spacer(minLength: 60) }
        }
    }

    // Strip [ACTION:...] tags from visible text
    private func cleanActionTags(_ text: String) -> String {
        text.replacingOccurrences(of: #"\[ACTION:[^\]]+\]"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Processing

    private var processingIndicator: some View {
        HStack {
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                Text("Thinking...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .glassEffect(.regular.tint(AppTheme.secondary.opacity(0.1)), in: RoundedRectangle(cornerRadius: 16))
            Spacer()
        }
    }

    // MARK: - Smart Action Card

    private var smartActionCard: some View {
        let actionText: String = {
            switch rag.pendingAction {
            case .logWater(let ml): return "Log \(ml)ml of water"
            case .logMeal(let name, _): return "Log \(name)"
            case .logCaffeine(let type): return "Log \(type)"
            case .startStandTimer: return "Start stand timer"
            case .none: return ""
            }
        }()

        return HStack {
            Image(systemName: "sparkles")
                .foregroundStyle(AppTheme.primary)
            Text(actionText)
                .font(.subheadline)
            Spacer()
            Button("Do it") {
                rag.executeAction(rag.pendingAction, context: context, profile: profile)
            }
            .buttonStyle(.glassProminent)
            .tint(AppTheme.primary)
            .controlSize(.small)
            Button {
                rag.pendingAction = .none
            } label: {
                Image(systemName: "xmark")
                    .font(.caption)
            }
            .buttonStyle(.glass)
            .controlSize(.small)
        }
        .padding(12)
        .glassEffect(.regular.tint(AppTheme.primary.opacity(0.2)), in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Actions

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        inputText = ""
        isInputFocused = false

        Task {
            await rag.send(text, context: context, profile: profile, sleepConfig: sleepConfigs.first)
        }
    }
}
