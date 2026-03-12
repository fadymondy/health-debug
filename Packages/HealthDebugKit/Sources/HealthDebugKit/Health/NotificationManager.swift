import Foundation
import UserNotifications
import SwiftData
import BackgroundTasks

#if canImport(UIKit)
import UIKit
#endif

/// Central notification service for Health Debug.
///
/// Responsibilities:
/// - APNs push registration & delegate
/// - Local notification scheduling via UNUserNotificationCenter
/// - Background task registration via BGTaskScheduler
/// - Persisting all delivered notifications as NotificationItem in SwiftData
@MainActor
public final class NotificationManager: NSObject, ObservableObject {

    // MARK: - Singleton

    public static let shared = NotificationManager()

    // MARK: - Published State

    @Published public var isAuthorized: Bool = false
    @Published public var unreadCount: Int = 0

    // MARK: - Background Task Identifiers

    public enum BGTaskID {
        public static let healthCheck    = "io.threex1.HealthDebug.bg.healthCheck"
        public static let aiTips         = "io.threex1.HealthDebug.bg.aiTips"
        public static let hydrationCheck = "io.threex1.HealthDebug.bg.hydrationCheck"
    }

    // MARK: - Notification Categories

    private enum CategoryID {
        static let general  = "io.threex1.HealthDebug.general"
        static let aiTip    = "io.threex1.HealthDebug.aiTip"
        static let reminder = "io.threex1.HealthDebug.reminder"
    }

    // MARK: - Init

    private var modelContext: ModelContext?

    override private init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        setupNotificationCategories()
    }

    // MARK: - Setup

    /// Call once at app launch to inject the SwiftData context.
    public func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        Task { await refreshUnreadCount() }
    }

    /// Request authorization and register for remote (push) notifications.
    public func requestAuthorization() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge, .provisional])
            isAuthorized = granted
            if granted {
                await registerForRemoteNotifications()
            }
        } catch {
            isAuthorized = false
        }
    }

    /// Check current authorization status without prompting.
    public func checkAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
            || settings.authorizationStatus == .provisional
    }

    @MainActor
    private func registerForRemoteNotifications() async {
        #if canImport(UIKit)
        UIApplication.shared.registerForRemoteNotifications()
        #endif
    }

    private func setupNotificationCategories() {
        let dismissAction = UNNotificationAction(
            identifier: "DISMISS",
            title: String(localized: "Dismiss"),
            options: []
        )
        let openAction = UNNotificationAction(
            identifier: "OPEN",
            title: String(localized: "Open"),
            options: [.foreground]
        )

        let generalCategory = UNNotificationCategory(
            identifier: CategoryID.general,
            actions: [dismissAction, openAction],
            intentIdentifiers: [],
            options: []
        )
        let aiCategory = UNNotificationCategory(
            identifier: CategoryID.aiTip,
            actions: [dismissAction, openAction],
            intentIdentifiers: [],
            options: []
        )
        let reminderCategory = UNNotificationCategory(
            identifier: CategoryID.reminder,
            actions: [dismissAction, openAction],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([
            generalCategory, aiCategory, reminderCategory
        ])
    }

    // MARK: - Schedule Local Notification

    /// Schedule a local notification and persist it to SwiftData.
    @discardableResult
    public func schedule(
        id: String = UUID().uuidString,
        title: String,
        body: String,
        category: NotificationCategory,
        source: NotificationSource = .system,
        triggerDate: Date? = nil,   // nil = fire immediately
        deepLink: String? = nil,
        aiTip: Bool = false
    ) async -> String {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = aiTip ? CategoryID.aiTip : CategoryID.reminder
        content.userInfo = [
            "notificationId": id,
            "category": category.rawValue,
            "deepLink": deepLink ?? "",
            "aiTip": aiTip
        ]

        let trigger: UNNotificationTrigger?
        if let date = triggerDate, date > Date() {
            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: date
            )
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        } else {
            trigger = nil
        }

        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            // Notification scheduling failed — still persist for in-app inbox
        }

        await persistNotification(
            id: id,
            title: title,
            body: body,
            category: category,
            source: source,
            deepLink: deepLink,
            aiTip: aiTip
        )

        return id
    }

    /// Cancel a pending local notification.
    public func cancel(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }

    /// Cancel all pending notifications for a given category prefix.
    public func cancelAll(prefix: String) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let ids = requests
                .filter { $0.identifier.hasPrefix(prefix) }
                .map(\.identifier)
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    // MARK: - Daily Repeating Notification

    /// Schedule a daily repeating notification at a fixed hour/minute.
    @discardableResult
    public func scheduleDaily(
        id: String,
        title: String,
        body: String,
        category: NotificationCategory,
        hour: Int,
        minute: Int,
        deepLink: String? = nil
    ) async -> String {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = CategoryID.reminder
        content.userInfo = [
            "notificationId": id,
            "category": category.rawValue,
            "deepLink": deepLink ?? ""
        ]

        var components = DateComponents()
        components.hour = hour
        components.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {}

        return id
    }

    // MARK: - SwiftData Persistence

    private func persistNotification(
        id: String,
        title: String,
        body: String,
        category: NotificationCategory,
        source: NotificationSource,
        deepLink: String?,
        aiTip: Bool
    ) async {
        guard let ctx = modelContext else { return }
        let item = NotificationItem(
            id: id,
            title: title,
            body: body,
            category: category,
            source: source,
            isRead: false,
            timestamp: Date(),
            deepLink: deepLink,
            aiTip: aiTip
        )
        ctx.insert(item)
        try? ctx.save()
        await refreshUnreadCount()
    }

    // MARK: - Read / Unread

    public func markRead(item: NotificationItem) {
        item.isRead = true
        try? modelContext?.save()
        Task { await refreshUnreadCount() }
    }

    public func markAllRead() {
        guard let ctx = modelContext else { return }
        let all = (try? ctx.fetch(NotificationItem.unreadDescriptor())) ?? []
        for item in all { item.isRead = true }
        try? ctx.save()
        Task { await refreshUnreadCount() }
    }

    public func delete(item: NotificationItem) {
        modelContext?.delete(item)
        try? modelContext?.save()
        Task { await refreshUnreadCount() }
    }

    private func refreshUnreadCount() async {
        guard let ctx = modelContext else { return }
        let unread = (try? ctx.fetch(NotificationItem.unreadDescriptor())) ?? []
        unreadCount = unread.count
        await updateBadge(count: unreadCount)
    }

    @MainActor
    private func updateBadge(count: Int) async {
        do {
            try await UNUserNotificationCenter.current().setBadgeCount(count)
        } catch {}
    }

    // MARK: - Background Tasks

    /// Register background task identifiers — call from AppDelegate / App init before the app finishes launching.
    public static func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: BGTaskID.healthCheck,
            using: nil
        ) { task in
            NotificationManager.handleHealthCheckTask(task as! BGAppRefreshTask)
        }

        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: BGTaskID.aiTips,
            using: nil
        ) { task in
            NotificationManager.handleAITipsTask(task as! BGProcessingTask)
        }

        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: BGTaskID.hydrationCheck,
            using: nil
        ) { task in
            NotificationManager.handleHydrationCheckTask(task as! BGAppRefreshTask)
        }
    }

    /// Schedule the next background health check (call after each execution).
    public static func scheduleBackgroundHealthCheck() {
        let request = BGAppRefreshTaskRequest(identifier: BGTaskID.healthCheck)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 min
        try? BGTaskScheduler.shared.submit(request)
    }

    /// Schedule the next AI tips processing task.
    public static func scheduleAITipsTask() {
        let request = BGProcessingTaskRequest(identifier: BGTaskID.aiTips)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 60) // 1 hour
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false
        try? BGTaskScheduler.shared.submit(request)
    }

    /// Schedule the next hydration background check.
    public static func scheduleHydrationCheck() {
        let request = BGAppRefreshTaskRequest(identifier: BGTaskID.hydrationCheck)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 30 * 60) // 30 min
        try? BGTaskScheduler.shared.submit(request)
    }

    // MARK: - Background Task Handlers (static — no MainActor context in background)

    private static func handleHealthCheckTask(_ task: BGAppRefreshTask) {
        scheduleBackgroundHealthCheck() // reschedule immediately

        let op = Task {
            // Individual alert features will hook into this via NotificationScheduler
            // This task fires the "check all health conditions" pass
            NotificationScheduler.shared.runHealthCheckPass()
            task.setTaskCompleted(success: true)
        }

        task.expirationHandler = {
            op.cancel()
            task.setTaskCompleted(success: false)
        }
    }

    private static func handleAITipsTask(_ task: BGProcessingTask) {
        scheduleAITipsTask()

        let op = Task {
            await NotificationScheduler.shared.generateAITips()
            task.setTaskCompleted(success: true)
        }

        task.expirationHandler = {
            op.cancel()
            task.setTaskCompleted(success: false)
        }
    }

    private static func handleHydrationCheckTask(_ task: BGAppRefreshTask) {
        scheduleHydrationCheck()

        let op = Task {
            NotificationScheduler.shared.runHydrationCheck()
            task.setTaskCompleted(success: true)
        }

        task.expirationHandler = {
            op.cancel()
            task.setTaskCompleted(success: false)
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {

    /// Show notification banner even when app is in foreground.
    public nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }

    /// Handle tap on notification — mark as read and navigate via deepLink.
    public nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let notificationId = userInfo["notificationId"] as? String ?? ""

        Task { @MainActor in
            if let ctx = NotificationManager.shared.modelContext,
               !notificationId.isEmpty {
                let id = notificationId
                let items = (try? ctx.fetch(NotificationItem.allDescriptor())) ?? []
                if let item = items.first(where: { $0.id == id }) {
                    item.isRead = true
                    try? ctx.save()
                    await NotificationManager.shared.refreshUnreadCount()
                }
            }
        }

        completionHandler()
    }

    /// Handle incoming APNs remote notification payload.
    public nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive notification: UNNotification
    ) {
        // Remote push handling — persist if not already in DB
        let userInfo = notification.request.content.userInfo
        guard let categoryRaw = userInfo["category"] as? String,
              let category = NotificationCategory(rawValue: categoryRaw) else { return }

        let title = notification.request.content.title
        let body = notification.request.content.body
        let deepLink = userInfo["deepLink"] as? String
        let aiTip = userInfo["aiTip"] as? Bool ?? false
        let notifId = userInfo["notificationId"] as? String ?? UUID().uuidString

        Task { @MainActor in
            await NotificationManager.shared.persistNotification(
                id: notifId,
                title: title,
                body: body,
                category: category,
                source: .system,
                deepLink: deepLink,
                aiTip: aiTip
            )
        }
    }
}
