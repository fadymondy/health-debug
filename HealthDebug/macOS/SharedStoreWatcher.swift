import Foundation
import Combine
import SwiftData
import HealthDebugKit

/// Watches the shared App Group store for changes written by iOS/watchOS.
/// - Observes UserDefaults (widget snapshot) for HealthKit metrics (steps, HR, sleep, energy)
/// - Observes SQLite WAL writes + NSPersistentStoreRemoteChange for SwiftData records
///
/// On macOS, HealthKit is unavailable — this is the source of truth for those metrics.
@MainActor
final class SharedStoreWatcher: ObservableObject {

    static let shared = SharedStoreWatcher()

    // MARK: - Published snapshot (HealthKit metrics from iOS)

    @Published var snapshot: WidgetSnapshot = WidgetDataStore.shared.read()

    // MARK: - Change signal for SwiftData refresh

    let didChange = PassthroughSubject<Void, Never>()

    private var fileSource: DispatchSourceFileSystemObject?
    private var fd: Int32 = -1
    nonisolated(unsafe) private var tokens: [NSObjectProtocol] = []

    private init() {
        startUserDefaultsObserver()   // HealthKit metrics (UserDefaults)
        startFileWatcher()            // SQLite WAL writes
        startRemoteChangeObserver()   // NSPersistentStoreRemoteChange
    }

    // MARK: - UserDefaults observer (widget_snapshot_v1 key)

    private func startUserDefaultsObserver() {
        let token = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: UserDefaults(suiteName: "group.io.3x1.HealthDebug"),
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            let fresh = WidgetDataStore.shared.read()
            // Only update if the snapshot is actually newer
            if fresh.updatedAt > self.snapshot.updatedAt {
                self.snapshot = fresh
                self.didChange.send()
            }
        }
        tokens.append(token)
    }

    // MARK: - File-system watcher (SQLite WAL)

    private func startFileWatcher() {
        // SQLite WAL file path: HealthDebug.sqlite-wal
        let base = ModelContainerFactory.sharedStoreURL.path   // …/HealthDebug.sqlite
        let walPath = base + "-wal"
        let watchPath = FileManager.default.fileExists(atPath: walPath) ? walPath : base

        fd = open(watchPath, O_EVTONLY)
        guard fd >= 0 else { return }

        let src = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .extend],
            queue: .main
        )
        src.setEventHandler { [weak self] in
            self?.didChange.send()
        }
        src.setCancelHandler { [weak self] in
            if let fd = self?.fd, fd >= 0 { close(fd) }
        }
        src.resume()
        fileSource = src
    }

    // MARK: - NSPersistentStoreRemoteChange (WAL checkpoint)

    private func startRemoteChangeObserver() {
        let token = NotificationCenter.default.addObserver(
            forName: .NSPersistentStoreRemoteChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.didChange.send()
        }
        tokens.append(token)
    }

    // MARK: - Manual refresh

    func refreshSnapshot() {
        let fresh = WidgetDataStore.shared.read()
        snapshot = fresh
    }

    deinit {
        fileSource?.cancel()
        // tokens are NSObjectProtocol — removeObserver is safe to call from deinit
        for token in tokens { NotificationCenter.default.removeObserver(token) }
    }
}
