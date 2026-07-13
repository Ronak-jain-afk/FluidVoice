import Foundation

#if os(Windows)
import WinSDK

// ponytail: Win32 Clipboard API via OpenClipboard/SetClipboardData/GetClipboardData.
// Clipboard owns the global memory after SetClipboardData — no free on success.
enum ClipboardService: ClipboardProtocol {
    @discardableResult
    static func copyToClipboard(_ text: String) -> Bool {
        guard !text.isEmpty else {
            DebugLogger.shared.debug("Attempted to copy empty text to clipboard, skipping", source: "ClipboardService")
            return false
        }
        guard OpenClipboard(nil) else {
            DebugLogger.shared.error("Failed to open clipboard", source: "ClipboardService")
            return false
        }
        defer { CloseClipboard() }

        guard EmptyClipboard() else {
            DebugLogger.shared.error("Failed to empty clipboard", source: "ClipboardService")
            return false
        }

        let utf16 = Array(text.utf16)
        let byteCount = (utf16.count + 1) * MemoryLayout<WCHAR>.stride
        guard let hMem = GlobalAlloc(GMEM_MOVEABLE, byteCount) else {
            DebugLogger.shared.error("GlobalAlloc failed for clipboard data", source: "ClipboardService")
            return false
        }

        guard let locked = GlobalLock(hMem) else {
            GlobalFree(hMem)
            DebugLogger.shared.error("GlobalLock failed for clipboard data", source: "ClipboardService")
            return false
        }

        let ptr = locked.assumingMemoryBound(to: WCHAR.self)
        ptr.initialize(from: utf16, count: utf16.count)
        ptr[utf16.count] = 0
        GlobalUnlock(hMem)

        guard SetClipboardData(CF_UNICODETEXT, hMem) != nil else {
            // ponytail: clipboard didn't take ownership — free it ourselves
            GlobalFree(hMem)
            DebugLogger.shared.error("SetClipboardData failed", source: "ClipboardService")
            return false
        }

        DebugLogger.shared.info("Copied \(text.count) characters to clipboard", source: "ClipboardService")
        return true
    }

    static func getFromClipboard() -> String? {
        guard OpenClipboard(nil) else {
            DebugLogger.shared.error("Failed to open clipboard for reading", source: "ClipboardService")
            return nil
        }
        defer { CloseClipboard() }

        guard IsClipboardFormatAvailable(CF_UNICODETEXT) else { return nil }
        guard let hMem = GetClipboardData(CF_UNICODETEXT) else { return nil }
        guard let locked = GlobalLock(hMem) else { return nil }
        defer { GlobalUnlock(hMem) }

        let ptr = locked.assumingMemoryBound(to: WCHAR.self)
        return String(decodingCString: ptr, as: UTF16.self)
    }
}
#endif
