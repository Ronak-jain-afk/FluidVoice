import AppKit
import Foundation

#if os(macOS)

// ponytail: adapter over the existing MenuBarManager.
// The real tray implementation (NSStatusItem, NSMenu) lives in
// MenuBarManager.swift — this provides a protocol-conforming surface.
final class MacTrayService: TrayProtocol {
    static let shared = MacTrayService()

    private init() {}

    func create() -> Bool {
        // ponytail: MenuBarManager.initializeMenuBar() is called from
        // ContentView.onAppear. This is a no-op because creation is
        // triggered by the existing startup sequence.
        DebugLogger.shared.info("MacTrayService: create() — MenuBarManager handles creation", source: "MacTrayService")
        return true
    }

    func updateIcon(name: String) {
        // ponytail: MenuBarManager.updateMenuBarIcon() uses NSImage(named:).
        // The icon name is currently hardcoded as "MenuBarIcon".
        DebugLogger.shared.info("MacTrayService: updateIcon(\(name))", source: "MacTrayService")
    }

    func updateMenu() {
        // ponytail: MenuBarManager.updateMenu() refreshes the status item menu.
        DebugLogger.shared.info("MacTrayService: updateMenu()", source: "MacTrayService")
    }

    func showNotification(title: String, message: String) {
        // ponytail: tray-level notifications are separate from UNNotification.
        // On macOS, NSStatusItem can show a balloon — currently unused.
        DebugLogger.shared.info("MacTrayService: showNotification(\(title): \(message))", source: "MacTrayService")
    }

    func destroy() {
        DebugLogger.shared.info("MacTrayService: destroy() — MenuBarManager handles teardown", source: "MacTrayService")
    }
}
#endif
