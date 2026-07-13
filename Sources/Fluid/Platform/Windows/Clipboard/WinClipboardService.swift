import Foundation

#if os(Windows)
enum ClipboardService: ClipboardProtocol {
    static func copyToClipboard(_ text: String) -> Bool {
        DebugLogger.shared.info("[Windows] Clipboard copy stub (\(text.count) chars)", source: "ClipboardService")
        return false
    }
    static func getFromClipboard() -> String? {
        DebugLogger.shared.info("[Windows] Clipboard read stub", source: "ClipboardService")
        return nil
    }
}
#endif
