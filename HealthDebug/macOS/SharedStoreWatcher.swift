import Foundation
import Combine
import SwiftData
import HealthDebugKit

/// Detects writes to the shared App Group SQLite file made by other processes (iOS, watchOS).
/// Uses two complementary mechanisms:
///   1. `NSPersistentStoreRemoteChangeNotification` — fires when SQLite WAL checkpoints
///   2. `DispatchSource` file-system watcher on the WAL file — catches writes before checkpoint
///
/// Both publish via `didChange` on the main queue so views can call `refreshAll()`.
final class SharedStoreWatcher: ObservableObject, @unchecked Sendable {

    static let shared = SharedStoreWatcher()

    let didChange = PassthroughSubject<Void, Never>()

    private var fileSource: DispatchSourceFileSystemObject?
    private var fd: Int32 = -1
    private var notificationToken: NSObjectProtocol?

    private init() {
        startFileWatcher()
        startRemoteChangeObserver()
    }

    // MARK: - File-system watcher (WAL writes)

    private func startFileWatcher() {
        let walURL = ModelContainerFactory.sharedStoreURL
            .deletingPathExtension()
            .appendingPathExtension("sqlite-wal")

        // Open whichever file exists; WAL is created on first write
        let watchURL = FileManager.default.fileExists(atPath: walURL.path)
            ? walURL : ModelContainerFactory.sharedStoreURL

        fd = open(watchURL.path, O_EVTONLY)
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
        notificationToken = NotificationCenter.default.addObserver(
            forName: .NSPersistentStoreRemoteChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.didChange.send()
        }
    }

    deinit {
        fileSource?.cancel()
        if let token = notificationToken {
            NotificationCenter.default.removeObserver(token)
        }
    }
}
