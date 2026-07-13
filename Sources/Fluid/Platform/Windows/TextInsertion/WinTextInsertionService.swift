import Foundation

#if os(Windows)
final class WinTextInsertionService: TextInsertionProtocol {
    static let shared = WinTextInsertionService()
    private init() {}
    func insertText(_ text: String) {
        DebugLogger.shared.info("[Windows] TextInsertion stub (\(text.count) chars)", source: "WinTextInsertionService")
    }
    func insertText(_ text: String, targetPID: pid_t?) {
        DebugLogger.shared.info("[Windows] TextInsertion stub pid=\(targetPID ?? 0) (\(text.count) chars)", source: "WinTextInsertionService")
    }
    func replaceSelection(_ text: String) -> Bool {
        DebugLogger.shared.info("[Windows] TextInsertion replaceSelection stub", source: "WinTextInsertionService")
        return false
    }
    func typeText(_ text: String) -> Bool {
        DebugLogger.shared.info("[Windows] TextInsertion typeText stub", source: "WinTextInsertionService")
        return false
    }
    func pasteFromClipboard() -> Bool {
        DebugLogger.shared.info("[Windows] TextInsertion paste stub", source: "WinTextInsertionService")
        return false
    }
}
#endif
