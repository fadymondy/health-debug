import Foundation
import SwiftData

/// Centralized ModelContainer creation for all platforms.
///
/// All targets (iOS, macOS, watchOS, Widgets) share the same SQLite file stored in
/// the App Group shared container: group.io.3x1.HealthDebug
/// This gives free, zero-latency cross-target sync without requiring CloudKit.
///
/// CloudKit upgrade path: change `cloudKitDatabase: .none` → `.automatic` once
/// a paid Apple Developer account is active and the iCloud entitlement is provisioned.
public enum ModelContainerFactory {

    public static let appGroupID = "group.io.3x1.HealthDebug"
    public static let storeFileName = "HealthDebug.sqlite"

    public static let allModels: [any PersistentModel.Type] = [
        WaterLog.self,
        MealLog.self,
        PomodoroSession.self,
        CaffeineLog.self,
        SleepConfig.self,
        UserProfile.self,
        NotificationItem.self,
    ]

    public static var schema: Schema {
        Schema(allModels)
    }

    /// The SQLite file URL inside the App Group shared container.
    /// Falls back to the app's own Documents directory if the App Group
    /// container is unavailable (e.g. simulator without entitlements).
    public static var sharedStoreURL: URL {
        if let groupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupID
        ) {
            return groupURL.appendingPathComponent(storeFileName)
        }
        // Fallback: app sandbox Documents (single-target only)
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent(storeFileName)
    }

    /// Creates the shared ModelContainer backed by the App Group SQLite store.
    /// All app targets call this and point at the same file.
    public static func create(inMemory: Bool = false) throws -> ModelContainer {
        if inMemory {
            let config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true,
                cloudKitDatabase: .none
            )
            return try ModelContainer(for: schema, configurations: [config])
        }

        let config = ModelConfiguration(
            schema: schema,
            url: sharedStoreURL,
            cloudKitDatabase: .none
        )
        return try ModelContainer(for: schema, configurations: [config])
    }

    /// Creates an in-memory container for previews and testing.
    public static func preview() throws -> ModelContainer {
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        return try ModelContainer(for: schema, configurations: [config])
    }
}
