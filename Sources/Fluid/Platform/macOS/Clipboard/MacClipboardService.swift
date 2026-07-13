import AppKit
import Foundation

#if os(macOS)

// ponytail: moved from inline #if os(macOS) in old PlatformAbstraction file
enum ClipboardService: ClipboardProtocol {
    @discardableResult
    static func copyToClipboard(_ text: String) -> Bool {
        guard !text.isEmpty else {
            DebugLogger.shared.debug("Attempted to copy empty text to clipboard, skipping", source: "ClipboardService")
            return false
        }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        let success = pasteboard.setString(text, forType: .string)
        if success {
            DebugLogger.shared.info("Copied \(text.count) characters to clipboard", source: "ClipboardService")
        } else {
            DebugLogger.shared.error("Failed to copy text to clipboard", source: "ClipboardService")
        }
        return success
    }

    static func getFromClipboard() -> String? {
        let pasteboard = NSPasteboard.general
        return pasteboard.string(forType: .string)
    }
}
#endif
