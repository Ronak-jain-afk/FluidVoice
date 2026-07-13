import Foundation

#if os(Windows)
final class WinAccessibilityService: AccessibilityProtocol {
    static let shared = WinAccessibilityService()
    private init() {}
    func isTrusted() -> Bool { false }
    func requestPermission() -> Bool {
        DebugLogger.shared.info("[Windows] Accessibility permission request stub", source: "WinAccessibilityService")
        return false
    }
    func focusedElement() -> Any? {
        DebugLogger.shared.info("[Windows] Accessibility focusedElement stub", source: "WinAccessibilityService")
        return nil
    }
    func focusedApplication() -> pid_t? {
        DebugLogger.shared.info("[Windows] Accessibility focusedApplication stub", source: "WinAccessibilityService")
        return nil
    }
    func selectedText() -> String? {
        DebugLogger.shared.info("[Windows] Accessibility selectedText stub", source: "WinAccessibilityService")
        return nil
    }
    func textBeforeCursor() -> String {
        DebugLogger.shared.info("[Windows] Accessibility textBeforeCursor stub", source: "WinAccessibilityService")
        return ""
    }
}
#endif
