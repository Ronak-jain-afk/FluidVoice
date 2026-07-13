import AppKit
import ApplicationServices
import Foundation

#if os(macOS)

// ponytail: window/process detection extracted from TypingService and AppDelegate.
final class MacWindowDetectionService: WindowDetectionProtocol {
    static let shared = MacWindowDetectionService()

    private init() {}

    func focusedApplication() -> WindowInfo? {
        guard let frontApp = NSWorkspace.shared.frontmostApplication else { return nil }
        return WindowInfo(
            pid: frontApp.processIdentifier,
            bundleIdentifier: frontApp.bundleIdentifier,
            windowTitle: frontApp.localizedName
        )
    }

    func activeWindowTitle() -> String? {
        focusedApplication()?.windowTitle
    }

    func foregroundPID() -> pid_t? {
        NSWorkspace.shared.frontmostApplication?.processIdentifier
    }
}
#endif
