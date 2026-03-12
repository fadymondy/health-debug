import SwiftUI
import SwiftData
import AppKit
import HealthDebugKit
import FirebaseCore
import FirebaseCrashlytics
import FirebaseAnalytics
import FirebaseMessaging
import GoogleSignIn

// Configure Firebase as a file-level once — guaranteed before any Auth.auth() access,
// even before @main struct init or any SwiftUI WindowGroup rendering.
private let _firebaseConfigured: Void = {
    FirebaseApp.configure()
    Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
}()

// Shared container — created once at process start, reused by all windows.
private let sharedContainer: ModelContainer = {
    do { return try ModelContainerFactory.create() }
    catch { fatalError("Could not create ModelContainer: \(error)") }
}()

@main
struct HealthDebugMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        _ = _firebaseConfigured  // force evaluation before any scene renders
    }

    var body: some Scene {
        // Window is managed entirely by AppDelegate/NSWindowController.
        // Settings scene satisfies the @main App requirement without rendering views early.
        Settings { EmptyView() }
    }
}

// MARK: - App Delegate

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var mainWindowController: NSWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Firebase already configured by _firebaseConfigured at file scope.
        // AuthManager.shared is safe to access here.
        openMainWindow()
        setupStatusBarItem()
    }

    // MARK: - Main Window

    @MainActor
    private func openMainWindow() {
        let contentView = MacContentView()
            .modelContainer(sharedContainer)
            .environmentObject(AuthManager.shared)
            .environmentObject(BiometricAuth.shared)
        let hostingView = NSHostingView(rootView: contentView)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1100, height: 720),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "Health Debug"
        window.contentView = hostingView
        window.minSize = NSSize(width: 900, height: 640)
        window.center()
        window.setFrameAutosaveName("MainWindow")
        window.makeKeyAndOrderFront(nil)

        let wc = NSWindowController(window: window)
        wc.showWindow(nil)
        mainWindowController = wc

        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Status Bar

    @MainActor
    private func setupStatusBarItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = NSImage(systemSymbolName: "heart.text.clipboard", accessibilityDescription: "Health Debug")
        item.button?.image?.isTemplate = true
        item.button?.action = #selector(togglePopover)
        item.button?.target = self
        self.statusItem = item

        let popover = NSPopover()
        popover.contentSize = NSSize(width: 320, height: 420)
        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = NSHostingController(
            rootView: MenuBarView()
                .modelContainer(sharedContainer)
                .environmentObject(AuthManager.shared)
        )
        self.popover = popover
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            if let window = mainWindowController?.window {
                window.makeKeyAndOrderFront(nil)
            } else {
                openMainWindow()
            }
        }
        return true
    }

    @objc private func togglePopover() {
        guard let button = statusItem?.button, let popover else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
}
