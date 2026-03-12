import Foundation
import SwiftData

/// Centralized ModelContainer creation for all platforms.
/// Uses CloudKit on device, local-only on simulator.
public enum ModelContainerFactory {

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

    /// Creates the shared ModelContainer.
    /// CloudKit is disabled until paid Apple Developer account is active.
    /// Change `.none` to `.automatic` once iCloud entitlement is available.
    public static func create(inMemory: Bool = false) throws -> ModelContainer {
        let cloudKit: ModelConfiguration.CloudKitDatabase = .none

        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            cloudKitDatabase: cloudKit
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
