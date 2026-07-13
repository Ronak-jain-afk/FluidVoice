import Foundation

#if os(macOS)

// ponytail: adapter over the existing TypingService.
// The actual insertion pipeline (CGEvent, AX, clipboard fallback) lives in
// TypingService.swift — this class exposes a protocol-conforming surface.
final class MacTextInsertionService: TextInsertionProtocol {
    static let shared = MacTextInsertionService()
    private let typingService = TypingService()

    private init() {}

    func insertText(_ text: String) {
        typingService.typeTextInstantly(text)
    }

    func insertText(_ text: String, targetPID: pid_t?) {
        typingService.typeTextInstantly(text, preferredTargetPID: targetPID)
    }

    func replaceSelection(_ text: String) -> Bool {
        // ponytail: fall back to insertText since TypingService handles
        // selection replacement internally via AX when focused.
        typingService.typeTextInstantly(text)
        return true
    }

    func typeText(_ text: String) -> Bool {
        typingService.typeTextInstantly(text)
        return true
    }

    func pasteFromClipboard() -> Bool {
        guard let text = ClipboardService.getFromClipboard() else { return false }
        typingService.typeTextInstantly(text)
        return true
    }
}
#endif
