import Foundation
import SwiftData

/// Persisted notification item — aggregates both system alerts and AI recommendations.
@Model
public final class NotificationItem {

    // MARK: - Stored Properties

    public var id: String
    public var title: String
    public var body: String
    public var category: String      // NotificationCategory rawValue
    public var source: String        // NotificationSource rawValue
    public var isRead: Bool
    public var timestamp: Date
    public var deepLink: String?     // optional route identifier (e.g. "hydration", "nutrition")
    public var aiTip: Bool           // true → also shown in AI/Intelligence feed

    // MARK: - Init

    public init(
        id: String = UUID().uuidString,
        title: String,
        body: String,
        category: NotificationCategory,
        source: NotificationSource,
        isRead: Bool = false,
        timestamp: Date = Date(),
        deepLink: String? = nil,
        aiTip: Bool = false
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.category = category.rawValue
        self.source = source.rawValue
        self.isRead = isRead
        self.timestamp = timestamp
        self.deepLink = deepLink
        self.aiTip = aiTip
    }

    // MARK: - Computed

    public var notificationCategory: NotificationCategory {
        NotificationCategory(rawValue: category) ?? .system
    }

    public var notificationSource: NotificationSource {
        NotificationSource(rawValue: source) ?? .system
    }
}

// MARK: - Supporting Enums

public enum NotificationCategory: String, CaseIterable, Sendable {
    case weight         = "weight"
    case hygiene        = "hygiene"
    case pomodoroStart  = "pomodoro_start"
    case pomodoroEnd    = "pomodoro_end"
    case sleep          = "sleep"
    case heartRate      = "heart_rate"
    case meal           = "meal"
    case coffee         = "coffee"
    case hydration      = "hydration"
    case movement       = "movement"
    case shutdown       = "shutdown"
    case aiTip          = "ai_tip"
    case system         = "system"

    public var displayName: String {
        switch self {
        case .weight:           return String(localized: "Weight")
        case .hygiene:          return String(localized: "Hygiene")
        case .pomodoroStart:    return String(localized: "Work Start")
        case .pomodoroEnd:      return String(localized: "Work End")
        case .sleep:            return String(localized: "Sleep")
        case .heartRate:        return String(localized: "Heart Rate")
        case .meal:             return String(localized: "Meal")
        case .coffee:           return String(localized: "Coffee")
        case .hydration:        return String(localized: "Hydration")
        case .movement:         return String(localized: "Movement")
        case .shutdown:         return String(localized: "Shutdown")
        case .aiTip:            return String(localized: "AI Tip")
        case .system:           return String(localized: "System")
        }
    }

    public var systemImage: String {
        switch self {
        case .weight:           return "scalemass.fill"
        case .hygiene:          return "hand.raised.fill"
        case .pomodoroStart:    return "play.circle.fill"
        case .pomodoroEnd:      return "stop.circle.fill"
        case .sleep:            return "moon.fill"
        case .heartRate:        return "heart.fill"
        case .meal:             return "fork.knife"
        case .coffee:           return "cup.and.heat.waves.fill"
        case .hydration:        return "drop.fill"
        case .movement:         return "figure.walk"
        case .shutdown:         return "exclamationmark.triangle.fill"
        case .aiTip:            return "brain.head.profile.fill"
        case .system:           return "bell.fill"
        }
    }
}

public enum NotificationSource: String, Sendable {
    case system = "system"
    case ai     = "ai"
}

// MARK: - Queries

public extension NotificationItem {
    static func allDescriptor() -> FetchDescriptor<NotificationItem> {
        var d = FetchDescriptor<NotificationItem>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        d.fetchLimit = 200
        return d
    }

    static func unreadDescriptor() -> FetchDescriptor<NotificationItem> {
        var d = FetchDescriptor<NotificationItem>(
            predicate: #Predicate { !$0.isRead },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        d.fetchLimit = 100
        return d
    }

    static func aiTipsDescriptor() -> FetchDescriptor<NotificationItem> {
        var d = FetchDescriptor<NotificationItem>(
            predicate: #Predicate { $0.aiTip },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        d.fetchLimit = 100
        return d
    }
}
