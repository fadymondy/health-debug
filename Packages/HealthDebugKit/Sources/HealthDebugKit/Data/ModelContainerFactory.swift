import Foundation
import SwiftData

/// Centralized ModelContainer creation for all platforms.
/// Uses CloudKit on device, local-only on simulator.
public enum ModelContainerFactory {

    public static let allModels: [any PersistentModel.Type] = [
        WaterLog.self,
        MealLog.self,
        StandSession.self,
        CaffeineLog.self,
        SleepConfig.self,
        UserProfile.self,
    ]

    public static var schema: Schema {
        Schema(allModels)
    }

    /// Creates the shared ModelContainer with CloudKit support (disabled on simulator).
    public static func create(inMemory: Bool = false) throws -> ModelContainer {
        #if targetEnvironment(simulator)
        let cloudKit: ModelConfiguration.CloudKitDatabase = .none
        #else
        let cloudKit: ModelConfiguration.CloudKitDatabase = .automatic
        #endif

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
