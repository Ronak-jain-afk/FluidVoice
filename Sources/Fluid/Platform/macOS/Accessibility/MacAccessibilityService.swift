import ApplicationServices
import Foundation

#if os(macOS)

// ponytail: wraps macOS Accessibility API behind a protocol.
// Heavier callers (TypingService, TextSelectionService) still use AX directly
// internally; this provides a protocol surface for cross-platform code.
final class MacAccessibilityService: AccessibilityProtocol {
    static let shared = MacAccessibilityService()

    private init() {}

    func isTrusted() -> Bool {
        AXIsProcessTrusted()
    }

    func requestPermission() -> Bool {
        // ponytail: On macOS, a11y permission is system-controlled.
        // AXIsProcessTrusted() returns false until the user grants it in
        // System Settings. We can prompt via the special prefs URL.
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    func focusedElement() -> Any? {
        let systemWide = AXUIElementCreateSystemWide()
        var focused: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(systemWide, kAXFocusedUIElementAttribute as CFString, &focused)
        guard result == .success, let focused else { return nil }
        guard CFGetTypeID(focused) == AXUIElementGetTypeID() else { return nil }
        return focused
    }

    func focusedApplication() -> pid_t? {
        guard let element = focusedElement() else { return nil }
        let axElement = unsafeBitCast(element, to: AXUIElement.self)
        var pid: pid_t = 0
        AXUIElementGetPid(axElement, &pid)
        return pid > 0 ? pid : nil
    }

    func selectedText() -> String? {
        guard isTrusted() else { return nil }
        let systemWide = AXUIElementCreateSystemWide()
        var focused: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(systemWide, kAXFocusedUIElementAttribute as CFString, &focused)
        guard result == .success, let focused else { return nil }
        guard CFGetTypeID(focused) == AXUIElementGetTypeID() else { return nil }

        let element = unsafeBitCast(focused, to: AXUIElement.self)
        var value: CFTypeRef?
        let selResult = AXUIElementCopyAttributeValue(element, kAXSelectedTextAttribute as CFString, &value)
        guard selResult == .success, let text = value as? String else { return nil }
        return text
    }

    func textBeforeCursor() -> String {
        TypingService.textBeforeCursorInFocusedField()
    }
}
#endif
