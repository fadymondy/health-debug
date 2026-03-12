import SwiftUI
import SwiftData
import HealthDebugKit

// MARK: - Notification Center View

struct NotificationCenterView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(NotificationItem.allDescriptor()) private var notifications: [NotificationItem]

    @StateObject private var manager = NotificationManager.shared
    @State private var selectedFilter: NotificationCategory? = nil

    private var filtered: [NotificationItem] {
        guard let filter = selectedFilter else { return notifications }
        return notifications.filter { $0.notificationCategory == filter }
    }

    private var unread: [NotificationItem] { filtered.filter { !$0.isRead } }
    private var read: [NotificationItem] { filtered.filter { $0.isRead } }

    var body: some View {
        NavigationStack {
            Group {
                if notifications.isEmpty {
                    emptyState
                } else {
                    notificationList
                }
            }
            .navigationTitle(String(localized: "Notifications"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(String(localized: "Done")) { dismiss() }
                }
                if !notifications.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button {
                                manager.markAllRead()
                            } label: {
                                Label(String(localized: "Mark All Read"), systemImage: "checkmark.circle")
                            }
                            Button(role: .destructive) {
                                clearAll()
                            } label: {
                                Label(String(localized: "Clear All"), systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
        }
        .onAppear {
            manager.configure(modelContext: context)
        }
    }

    // MARK: - List

    private var notificationList: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                // Category filter chips
                filterChips
                    .padding(.horizontal)
                    .padding(.vertical, 8)

                // Unread section
                if !unread.isEmpty {
                    Section {
                        ForEach(unread) { item in
                            NotificationRow(item: item)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        manager.delete(item: item)
                                    } label: {
                                        Label(String(localized: "Delete"), systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .leading) {
                                    Button {
                                        manager.markRead(item: item)
                                    } label: {
                                        Label(String(localized: "Mark Read"), systemImage: "envelope.open")
                                    }
                                    .tint(.blue)
                                }
                        }
                    } header: {
                        sectionHeader(title: String(localized: "New"), count: unread.count)
                    }
                }

                // Read / earlier section
                if !read.isEmpty {
                    Section {
                        ForEach(read) { item in
                            NotificationRow(item: item)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        manager.delete(item: item)
                                    } label: {
                                        Label(String(localized: "Delete"), systemImage: "trash")
                                    }
                                }
                        }
                    } header: {
                        sectionHeader(title: String(localized: "Earlier"), count: read.count)
                    }
                }
            }
        }
    }

    // MARK: - Filter Chips

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(title: String(localized: "All"), isSelected: selectedFilter == nil) {
                    selectedFilter = nil
                }
                ForEach(NotificationCategory.allCases, id: \.rawValue) { cat in
                    let count = notifications.filter { $0.notificationCategory == cat }.count
                    if count > 0 {
                        chip(
                            title: cat.displayName,
                            systemImage: cat.systemImage,
                            isSelected: selectedFilter == cat
                        ) {
                            selectedFilter = selectedFilter == cat ? nil : cat
                        }
                    }
                }
            }
        }
    }

    private func chip(
        title: String,
        systemImage: String? = nil,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let img = systemImage {
                    Image(systemName: img)
                        .font(.caption2)
                }
                Text(title)
                    .font(.caption.weight(.medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                isSelected
                    ? AppTheme.primary.opacity(0.15)
                    : Color(.secondarySystemBackground)
            )
            .foregroundStyle(isSelected ? AppTheme.primary : .primary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(isSelected ? AppTheme.primary.opacity(0.4) : .clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Section Header

    private func sectionHeader(title: String, count: Int) -> some View {
        HStack {
            Text(title)
                .font(.subheadline.weight(.semibold))
            Text("\(count)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color(.tertiarySystemBackground))
                .clipShape(Capsule())
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "bell.slash.fill")
                .font(.system(size: 52))
                .foregroundStyle(.tertiary)
            Text(String(localized: "No Notifications"))
                .font(.title3.bold())
            Text(String(localized: "Your health alerts and AI tips will appear here."))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }

    // MARK: - Actions

    private func clearAll() {
        let all = (try? context.fetch(NotificationItem.allDescriptor())) ?? []
        for item in all { context.delete(item) }
        try? context.save()
    }
}

// MARK: - Notification Row

struct NotificationRow: View {
    @Bindable var item: NotificationItem
    @StateObject private var manager = NotificationManager.shared
    @State private var isRead: Bool

    init(item: NotificationItem) {
        self.item = item
        self._isRead = State(initialValue: item.isRead)
    }

    var body: some View {
        Button {
            if !item.isRead {
                manager.markRead(item: item)
                isRead = true
            }
        } label: {
            HStack(alignment: .top, spacing: 12) {
                // Category icon
                ZStack {
                    Circle()
                        .fill(categoryColor.opacity(isRead ? 0.08 : 0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: item.notificationCategory.systemImage)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(categoryColor.opacity(isRead ? 0.5 : 1.0))
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(item.title)
                            .font(.subheadline.weight(isRead ? .regular : .semibold))
                            .foregroundStyle(isRead ? .secondary : .primary)
                            .lineLimit(1)
                        Spacer()
                        Text(item.timestamp.formatted(.relative(presentation: .named)))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    Text(item.body)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                // Unread dot
                if !isRead {
                    Circle()
                        .fill(AppTheme.primary)
                        .frame(width: 8, height: 8)
                        .padding(.top, 4)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(
                isRead
                    ? Color.clear
                    : AppTheme.primary.opacity(0.04)
            )
        }
        .buttonStyle(.plain)
        Divider().padding(.leading, 64)
    }

    private var categoryColor: Color {
        switch item.notificationCategory {
        case .weight:           return .blue
        case .hygiene:          return .teal
        case .pomodoroStart:    return .green
        case .pomodoroEnd:      return .orange
        case .sleep:            return .indigo
        case .heartRate:        return .red
        case .meal:             return .orange
        case .coffee:           return .brown
        case .hydration:        return .cyan
        case .movement:         return .green
        case .shutdown:         return .red
        case .aiTip:            return AppTheme.primary
        case .system:           return .gray
        }
    }
}

// MARK: - Bell Button (for toolbar use)

struct NotificationBellButton: View {
    @StateObject private var manager = NotificationManager.shared
    @State private var showCenter = false

    var body: some View {
        Button {
            showCenter = true
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: manager.unreadCount > 0 ? "bell.badge.fill" : "bell.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(manager.unreadCount > 0 ? AppTheme.primary : .primary)

                if manager.unreadCount > 0 {
                    Text(manager.unreadCount > 99 ? "99+" : "\(manager.unreadCount)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(AppTheme.primary)
                        .clipShape(Capsule())
                        .offset(x: 8, y: -8)
                }
            }
        }
        .sheet(isPresented: $showCenter) {
            NotificationCenterView()
        }
    }
}
