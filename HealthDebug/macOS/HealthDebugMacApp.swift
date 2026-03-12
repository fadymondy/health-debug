import SwiftUI
import SwiftData
import AppKit
import HealthDebugKit

// Shared container — created once at process start, reused by all targets.
private let sharedContainer: ModelContainer = {
    do { return try ModelContainerFactory.create() }
    catch { fatalError("Could not create ModelContainer: \(error)") }
}()

@main
struct HealthDebugMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup(id: "main") {
            MacContentView()
                .modelContainer(sharedContainer)
                .onAppear { NSApp.activate(ignoringOtherApps: true) }
        }
        .modelContainer(sharedContainer)
        .defaultLaunchBehavior(.presented)
        .restorationBehavior(.disabled)
    }
}

// MARK: - App Delegate (owns the status bar item + popover)

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.activate(ignoringOtherApps: true)

        // Status bar item
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = NSImage(systemSymbolName: "heart.text.clipboard", accessibilityDescription: "Health Debug")
        item.button?.image?.isTemplate = true
        item.button?.action = #selector(togglePopover)
        item.button?.target = self
        self.statusItem = item

        // Popover — reuse the shared container (no second create() call)
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 320, height: 420)
        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = NSHostingController(
            rootView: MenuBarView().modelContainer(sharedContainer)
        )
        self.popover = popover
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            NSApp.windows.filter { $0.canBecomeMain }.forEach { $0.makeKeyAndOrderFront(nil) }
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
