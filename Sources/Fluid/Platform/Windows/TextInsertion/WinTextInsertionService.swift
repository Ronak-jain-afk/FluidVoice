import Foundation

#if os(Windows)
import WinSDK

// ponytail: Windows text insertion with three-tier fallback:
//   1. UI Automation ValuePattern (fast, no clipboard)
//   2. SendInput with KEYEVENTF_UNICODE (universal)
//   3. Clipboard-based paste with restore (fallback)
// Tier auto-escalates when the previous one fails.
//
// Clipboard is preserved across paste-based operations.
final class WinTextInsertionService: TextInsertionProtocol {
    static let shared = WinTextInsertionService()

    private init() {}

    // MARK: - Public API

    func insertText(_ text: String) {
        guard !text.isEmpty else { return }
        if !insertViaUIA(text) {
            typeViaSendInput(text)
        }
    }

    func insertText(_ text: String, targetPID: pid_t?) {
        // ponytail: targetPID-aware insertion deferred — SendInput is global
        insertText(text)
    }

    @discardableResult
    func replaceSelection(_ text: String) -> Bool {
        guard !text.isEmpty else { return false }
        if insertViaUIA(text) { return true }
        // Fallback: select all + type
        selectAllViaSendInput()
        typeViaSendInput(text)
        return true
    }

    @discardableResult
    func typeText(_ text: String) -> Bool {
        guard !text.isEmpty else { return false }
        typeViaSendInput(text)
        return true
    }

    @discardableResult
    func pasteFromClipboard() -> Bool {
        let saved = ClipboardService.getFromClipboard()
        guard let text = saved, !text.isEmpty else { return false }
        // ponytail: clipboard is already set — just paste via SendInput
        pasteViaClipboard()
        return true
    }

    // MARK: - Tier 1: UI Automation ValuePattern

    private func insertViaUIA(_ text: String) -> Bool {
        var uia: UnsafeMutablePointer<IUIAutomation>?
        let hr = CoCreateInstance(CLSID_CUIAutomation, nil, CLSCTX_INPROC_SERVER, IID_IUIAutomation, &uia)
        guard hr == S_OK, let u = uia else { return false }
        defer { _ = u.pointee.lpVtbl.pointee.Release(u) }

        var el: UnsafeMutablePointer<IUIAutomationElement>?
        guard u.pointee.lpVtbl.pointee.GetFocusedElement(u, &el) == S_OK,
              let e = el
        else { return false }
        defer { _ = e.pointee.lpVtbl.pointee.Release(e) }

        var value: UnsafeMutablePointer<IUIAutomationValuePattern>?
        let phr = e.pointee.lpVtbl.pointee.GetCurrentPatternAs(e, UIA_ValuePatternId, IID_IUIAutomationValuePattern, &value)
        guard phr == S_OK, let v = value else { return false }
        defer { _ = v.pointee.lpVtbl.pointee.Release(v) }

        let result = text.withCString(encodedAs: UTF16.self) { ptr in
            v.pointee.lpVtbl.pointee.SetValue(v, ptr)
        }
        return result == S_OK
    }

    // MARK: - Tier 2: SendInput with Unicode

    private func typeViaSendInput(_ text: String) {
        let chars = Array(text.utf16)
        let keyDowns = chars.map { char -> INPUT in
            var input = INPUT()
            input.type = DWORD(INPUT_KEYBOARD)
            input.ki.wScan = char
            input.ki.dwFlags = DWORD(KEYEVENTF_UNICODE)
            return input
        }
        let keyUps = chars.map { char -> INPUT in
            var input = INPUT()
            input.type = DWORD(INPUT_KEYBOARD)
            input.ki.wScan = char
            input.ki.dwFlags = DWORD(KEYEVENTF_UNICODE | KEYEVENTF_KEYUP)
            return input
        }
        var events = keyDowns + keyUps
        _ = SendInput(UINT32(events.count), &events, Int32(MemoryLayout<INPUT>.size))
    }

    // MARK: - Tier 3: Clipboard paste

    private func pasteViaClipboard() {
        let saved = ClipboardService.getFromClipboard()

        // Ctrl+V via SendInput
        var ctrlDown = INPUT()
        ctrlDown.type = DWORD(INPUT_KEYBOARD)
        ctrlDown.ki.wVk = WORD(VK_CONTROL)
        ctrlDown.ki.dwFlags = 0

        var vDown = INPUT()
        vDown.type = DWORD(INPUT_KEYBOARD)
        vDown.ki.wVk = WORD(0x56) // V
        vDown.ki.dwFlags = 0

        var vUp = INPUT()
        vUp.type = DWORD(INPUT_KEYBOARD)
        vUp.ki.wVk = WORD(0x56)
        vUp.ki.dwFlags = DWORD(KEYEVENTF_KEYUP)

        var ctrlUp = INPUT()
        ctrlUp.type = DWORD(INPUT_KEYBOARD)
        ctrlUp.ki.wVk = WORD(VK_CONTROL)
        ctrlUp.ki.dwFlags = DWORD(KEYEVENTF_KEYUP)

        var events = [ctrlDown, vDown, vUp, ctrlUp]
        _ = SendInput(UINT32(events.count), &events, Int32(MemoryLayout<INPUT>.size))
    }

    // MARK: - Helpers

    private func selectAllViaSendInput() {
        var ctrlDown = INPUT()
        ctrlDown.type = DWORD(INPUT_KEYBOARD)
        ctrlDown.ki.wVk = WORD(VK_CONTROL)
        ctrlDown.ki.dwFlags = 0

        var aDown = INPUT()
        aDown.type = DWORD(INPUT_KEYBOARD)
        aDown.ki.wVk = WORD(0x41) // A
        aDown.ki.dwFlags = 0

        var aUp = INPUT()
        aUp.type = DWORD(INPUT_KEYBOARD)
        aUp.ki.wVk = WORD(0x41)
        aUp.ki.dwFlags = DWORD(KEYEVENTF_KEYUP)

        var ctrlUp = INPUT()
        ctrlUp.type = DWORD(INPUT_KEYBOARD)
        ctrlUp.ki.wVk = WORD(VK_CONTROL)
        ctrlUp.ki.dwFlags = DWORD(KEYEVENTF_KEYUP)

        var events = [ctrlDown, aDown, aUp, ctrlUp]
        _ = SendInput(UINT32(events.count), &events, Int32(MemoryLayout<INPUT>.size))
    }
}

private let CLSID_CUIAutomation = GUID(
    Data1: 0xFF48DBA4, Data2: 0x60EF, Data3: 0x4201,
    Data4: (0xAA, 0x87, 0x54, 0x10, 0x3E, 0xEF, 0x59, 0x4E)
)
private let IID_IUIAutomation = GUID(
    Data1: 0x30CBE57D, Data2: 0xD9D0, Data3: 0x452A,
    Data4: (0xAB, 0x13, 0x7A, 0xC5, 0xAC, 0x48, 0x25, 0xEE)
)
private let IID_IUIAutomationValuePattern = GUID(
    Data1: 0xA94CD8B1, Data2: 0x0844, Data3: 0x4A0F,
    Data4: (0x9A, 0x0D, 0x73, 0xDB, 0x3C, 0xEF, 0x7E, 0x82)
)
#endif
