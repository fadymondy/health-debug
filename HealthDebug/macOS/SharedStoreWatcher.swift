import Foundation
import Combine
import SwiftData
import HealthDebugKit
import FirebaseFirestore

/// Watches the shared App Group store for changes written by iOS/watchOS.
///
/// Two mechanisms run in parallel:
///  1. `DispatchSource` file watcher on the App Group UserDefaults plist — fires
///     immediately when iOS writes a new `WidgetSnapshot` (cross-process, zero-latency).
///  2. 5-second poll timer — reliable fallback for the window before the plist is created
///     or if the file descriptor races at launch.
///
/// SwiftData cross-process changes are detected via:
///  3. `DispatchSource` on the SQLite WAL file.
///  4. `NSPersistentStoreRemoteChange` notification (post-checkpoint).
///
/// On macOS, HealthKit is unavailable — `snapshot` is the source of truth for metrics.
@MainActor
final class SharedStoreWatcher: ObservableObject {

    static let shared = SharedStoreWatcher()

    // MARK: - Published snapshot (HealthKit metrics from iOS)

    @Published var snapshot: WidgetSnapshot = WidgetDataStore.shared.read()

    // MARK: - Change signal for SwiftData refresh

    let didChange = PassthroughSubject<Void, Never>()

    // MARK: - Privates

    private static let appGroupID = "group.io.3x1.HealthDebug"

    // SQLite WAL watcher
    private var walSource: DispatchSourceFileSystemObject?
    private var walFd: Int32 = -1

    // UserDefaults plist watcher
    private var plistSource: DispatchSourceFileSystemObject?
    private var plistFd: Int32 = -1

    // Poll timer (fallback) — use nonisolated(unsafe) so deinit can access
    private var pollTimer: Timer? {
        get { _pollTimer }
        set { _pollTimer = newValue }
    }

    nonisolated(unsafe) private var tokens: [NSObjectProtocol] = []
    nonisolated(unsafe) private var _pollTimer: Timer?

    private init() {
        startSQLiteWALWatcher()
        startRemoteChangeObserver()
        startPlistWatcher()
        startPollTimer()
    }

    // MARK: - SQLite WAL file watcher (SwiftData cross-process)

    private func startSQLiteWALWatcher() {
        let base = ModelContainerFactory.sharedStoreURL.path
        let walPath = base + "-wal"
        let watchPath = FileManager.default.fileExists(atPath: walPath) ? walPath : base

        walFd = open(watchPath, O_EVTONLY)
        guard walFd >= 0 else { return }

        let src = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: walFd,
            eventMask: [.write, .extend],
            queue: .main
        )
        src.setEventHandler { [weak self] in
            self?.didChange.send()
        }
        src.setCancelHandler { [weak self] in
            if let fd = self?.walFd, fd >= 0 { close(fd) }
        }
        src.resume()
        walSource = src
    }

    // MARK: - NSPersistentStoreRemoteChange (post-WAL checkpoint)

    private func startRemoteChangeObserver() {
        let token = NotificationCenter.default.addObserver(
            forName: .NSPersistentStoreRemoteChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in self?.didChange.send() }
        }
        tokens.append(token)
    }

    // MARK: - App Group UserDefaults plist watcher (cross-process HealthKit metrics)

    /// Path: ~/Library/Group Containers/<groupID>/Library/Preferences/<groupID>.plist
    private static var plistURL: URL? {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupID
        ) else { return nil }
        return containerURL
            .appendingPathComponent("Library/Preferences")
            .appendingPathComponent("\(appGroupID).plist")
    }

    private func startPlistWatcher() {
        guard let url = Self.plistURL else { return }

        // Ensure the directory exists so we can watch even before iOS writes the plist
        let dir = url.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        // Watch the plist file if it exists, otherwise watch its parent directory
        let watchPath: String
        if FileManager.default.fileExists(atPath: url.path) {
            watchPath = url.path
        } else {
            watchPath = dir.path
        }

        plistFd = open(watchPath, O_EVTONLY)
        guard plistFd >= 0 else { return }

        let src = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: plistFd,
            eventMask: [.write, .extend, .attrib],
            queue: .main
        )
        src.setEventHandler { [weak self] in
            self?.reloadSnapshot()
        }
        src.setCancelHandler { [weak self] in
            if let fd = self?.plistFd, fd >= 0 { close(fd) }
        }
        src.resume()
        plistSource = src
    }

    // MARK: - Poll timer (5-second fallback)

    private func startPollTimer() {
        pollTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.reloadSnapshot()
            }
        }
    }

    // MARK: - Snapshot reload

    private func reloadSnapshot() {
        // Force UserDefaults to re-read from disk (cross-process writes aren't auto-synced)
        UserDefaults(suiteName: Self.appGroupID)?.synchronize()
        let fresh = WidgetDataStore.shared.read()
        if fresh.updatedAt > snapshot.updatedAt {
            snapshot = fresh
            didChange.send()
        }
    }

    // MARK: - Manual refresh

    func refreshSnapshot() {
        UserDefaults(suiteName: Self.appGroupID)?.synchronize()
        snapshot = WidgetDataStore.shared.read()
        // Do NOT send didChange here — this is called from the toolbar button
        // and sending during a SwiftUI update causes a render-loop deadlock.
    }

    // MARK: - Firebase real-time listener

    /// Call after Firebase Auth is confirmed. When a new snapshot arrives from
    /// Firestore it replaces the local snapshot and fires `didChange` so all
    /// macOS views re-render immediately.
    func startFirebaseListener(uid: String) {
        guard !uid.isEmpty else { return }
        FirebaseSync.shared.startListening(uid: uid) { [weak self] newSnapshot in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.snapshot = newSnapshot
                self.didChange.send()
            }
        }
    }

    func stopFirebaseListener() {
        FirebaseSync.shared.stopListening()
    }

    deinit {
        walSource?.cancel()
        plistSource?.cancel()
        _pollTimer?.invalidate()
        for token in tokens { NotificationCenter.default.removeObserver(token) }
    }
}
