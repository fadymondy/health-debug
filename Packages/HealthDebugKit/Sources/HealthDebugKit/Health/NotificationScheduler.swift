import Foundation
import SwiftData

/// Lightweight scheduler that individual alert features hook into.
/// Called from background tasks and foreground lifecycle events.
///
/// Each alert feature (FEAT-YNQ, FEAT-UKM, etc.) will extend this class
/// by adding their scheduling logic. The shell provides the registration point.
public final class NotificationScheduler: @unchecked Sendable {

    // MARK: - Singleton

    public static let shared = NotificationScheduler()
    private init() {}

    // MARK: - Hook Registration

    private var healthCheckHandlers: [@Sendable () -> Void] = []
    private var hydrationCheckHandlers: [@Sendable () -> Void] = []
    private var aiTipHandlers: [@Sendable () async -> Void] = []

    /// Register a handler to be called on each background health check pass.
    public func registerHealthCheckHandler(_ handler: @escaping @Sendable () -> Void) {
        healthCheckHandlers.append(handler)
    }

    /// Register a handler to be called on each background hydration check.
    public func registerHydrationCheckHandler(_ handler: @escaping @Sendable () -> Void) {
        hydrationCheckHandlers.append(handler)
    }

    /// Register a handler for AI tip generation passes.
    public func registerAITipHandler(_ handler: @escaping @Sendable () async -> Void) {
        aiTipHandlers.append(handler)
    }

    // MARK: - Execution

    public func runHealthCheckPass() {
        for handler in healthCheckHandlers {
            handler()
        }
    }

    public func runHydrationCheck() {
        for handler in hydrationCheckHandlers {
            handler()
        }
    }

    public func generateAITips() async {
        for handler in aiTipHandlers {
            await handler()
        }
    }
}
