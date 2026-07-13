import Foundation

#if os(Windows)
import WinSDK

// ponytail: Microsoft UI Automation via IUIAutomation COM API.
// Permission on desktop Windows is always available for running processes
// (no explicit grant prompt). ValuePattern used for input field text;
// TextPattern's DocumentRange provides full document content.
// Selection-aware methods (selectedText, textBeforeCursor) use ValuePattern
// as approximation; TextPattern.GetSelection refinement deferred.
final class WinAccessibilityService: AccessibilityProtocol {
    static let shared = WinAccessibilityService()

    private var uia: UnsafeMutablePointer<IUIAutomation>?

    private init() {
        var ptr: UnsafeMutablePointer<IUIAutomation>?
        let hr = CoCreateInstance(CLSID_CUIAutomation, nil, CLSCTX_INPROC_SERVER, IID_IUIAutomation, &ptr)
        if hr == S_OK { uia = ptr }
    }

    func isTrusted() -> Bool { uia != nil }

    func requestPermission() -> Bool { uia != nil }

    func focusedElement() -> Any? {
        guard let u = uia else { return nil }
        var el: UnsafeMutablePointer<IUIAutomationElement>?
        let hr = u.pointee.lpVtbl.pointee.GetFocusedElement(u, &el)
        guard hr == S_OK, let e = el else { return nil }
        return e
    }

    func focusedApplication() -> pid_t? {
        guard let el = focusedElement() as? UnsafeMutablePointer<IUIAutomationElement> else { return nil }
        defer { _ = el.pointee.lpVtbl.pointee.Release(el) }
        var pid: pid_t = 0
        let hr = el.pointee.lpVtbl.pointee.GetCurrentProcessId(el, &pid)
        return hr == S_OK ? pid : nil
    }

    func selectedText() -> String? {
        // ponytail: TextPattern's GetSelection uses SAFEARRAY (complex from Swift).
        // ValuePattern returns the entire field content as approximation.
        guard let el = focusedElement() as? UnsafeMutablePointer<IUIAutomationElement> else { return nil }
        defer { _ = el.pointee.lpVtbl.pointee.Release(el) }
        return valuePatternText(el)
    }

    func textBeforeCursor() -> String {
        // ponytail: TextPattern.DocumentRange gives full document content.
        // Without GetSelection-based cursor detection, returns entire text.
        // This approximates the macOS textBeforeCursorInFocusedField behaviour.
        guard let el = focusedElement() as? UnsafeMutablePointer<IUIAutomationElement> else { return "" }
        defer { _ = el.pointee.lpVtbl.pointee.Release(el) }
        if let text = documentRangeText(el) { return text }
        return valuePatternText(el) ?? ""
    }

    // MARK: - Private

    private func valuePatternText(_ el: UnsafeMutablePointer<IUIAutomationElement>) -> String? {
        var value: UnsafeMutablePointer<IUIAutomationValuePattern>?
        let hr = el.pointee.lpVtbl.pointee.GetCurrentPatternAs(el, UIA_ValuePatternId, IID_IUIAutomationValuePattern, &value)
        guard hr == S_OK, let v = value else { return nil }
        defer { _ = v.pointee.lpVtbl.pointee.Release(v) }
        var text: UnsafeMutablePointer<WCHAR>?
        guard v.pointee.lpVtbl.pointee.get_CurrentValue(v, &text) == S_OK, let t = text else { return nil }
        defer { SysFreeString(t) }
        return String(decodingCString: t, as: UTF16.self)
    }

    private func documentRangeText(_ el: UnsafeMutablePointer<IUIAutomationElement>) -> String? {
        var pattern: UnsafeMutablePointer<IUIAutomationTextPattern>?
        let hr = el.pointee.lpVtbl.pointee.GetCurrentPatternAs(el, UIA_TextPatternId, IID_IUIAutomationTextPattern, &pattern)
        guard hr == S_OK, let p = pattern else { return nil }
        defer { _ = p.pointee.lpVtbl.pointee.Release(p) }
        var range: UnsafeMutablePointer<IUIAutomationTextRange>?
        guard p.pointee.lpVtbl.pointee.get_DocumentRange(p, &range) == S_OK, let r = range else { return nil }
        defer { _ = r.pointee.lpVtbl.pointee.Release(r) }
        var text: UnsafeMutablePointer<WCHAR>?
        guard r.pointee.lpVtbl.pointee.GetText(r, -1, &text) == S_OK, let t = text else { return nil }
        defer { SysFreeString(t) }
        return String(decodingCString: t, as: UTF16.self)
    }
}

// ponytail: CLSID/IID from UIAutomationClient.h
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
private let IID_IUIAutomationTextPattern = GUID(
    Data1: 0x92CBAA9E, Data2: 0x14A6, Data3: 0x4D3A,
    Data4: (0xBF, 0x5E, 0x17, 0xA1, 0x42, 0xE3, 0xE8, 0xDA)
)
#endif
