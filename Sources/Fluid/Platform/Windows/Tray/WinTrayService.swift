import Foundation

#if os(Windows)
import WinSDK

// ponytail: Win32 system tray via Shell_NotifyIconW.
// Icon is IDI_APPLICATION as placeholder — real icon loading deferred.
// Menu is basic (Show/Quit) — wire into app's actual menu structure when UI exists.
final class WinTrayService: TrayProtocol {
    static let shared = WinTrayService()

    private let windowClass = "FluidVoiceTrayWindow"
    private let iconID: UINT = 1001
    private let callbackMsg: UINT
    private var hwnd: HWND?
    private var created = false
    private let lock = NSLock()

    private init() {
        callbackMsg = RegisterWindowMessageW("FluidVoiceTrayCallback")
    }

    func create() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard !created else { return true }

        var wc = WNDCLASSW()
        wc.lpfnWndProc = { hwnd, msg, wParam, lParam in
            WinTrayService.shared.wndProc(hwnd, msg, wParam, lParam)
        }
        wc.hInstance = GetModuleHandleW(nil)
        wc.lpszClassName = windowClass
        _ = RegisterClassW(&wc)

        let w = CreateWindowExW(
            0, windowClass, nil, 0,
            CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT,
            HWND_MESSAGE, nil, GetModuleHandleW(nil), nil
        )
        guard let w = w else {
            DebugLogger.shared.error("Tray: failed to create window", source: "WinTrayService")
            return false
        }
        hwnd = w

        var nid = makeNID()
        nid.uFlags = UINT(NIF_MESSAGE | NIF_ICON | NIF_TIP)
        nid.hIcon = LoadIconW(nil, IDI_APPLICATION)
        "FluidVoice".withCString(encodedAs: UTF16.self) { src in
            memcpy(&nid.szTip, src, (min(127, "FluidVoice".utf16.count) + 1) * 2)
        }

        let result = Shell_NotifyIconW(NIM_ADD, &nid)
        created = result != 0
        if !created {
            DebugLogger.shared.error("Tray: NIM_ADD failed: \(GetLastError())", source: "WinTrayService")
        }
        return created
    }

    func updateIcon(name: String) {
        guard created, let w = hwnd else { return }
        var nid = makeNID()
        nid.uFlags = UINT(NIF_ICON)
        // ponytail: icon bundle loading deferred — use generic for now
        nid.hIcon = LoadIconW(nil, IDI_APPLICATION)
        _ = withUnsafePointer(to: &nid) { ptr in
            Shell_NotifyIconW(NIM_MODIFY, UnsafeMutablePointer(mutating: ptr))
        }
    }

    func updateMenu() {
        // ponytail: menu is built lazily on right-click — no pre-build needed
    }

    func showNotification(title: String, message: String) {
        guard created, let w = hwnd else { return }
        var nid = makeNID()
        nid.uFlags = UINT(NIF_INFO)
        nid.dwInfoFlags = UINT(NIIF_INFO)
        title.withCString(encodedAs: UTF16.self) { src in
            memcpy(&nid.szInfoTitle, src, (min(63, title.utf16.count) + 1) * 2)
        }
        message.withCString(encodedAs: UTF16.self) { src in
            memcpy(&nid.szInfo, src, (min(255, message.utf16.count) + 1) * 2)
        }
        _ = withUnsafePointer(to: &nid) { ptr in
            Shell_NotifyIconW(NIM_MODIFY, UnsafeMutablePointer(mutating: ptr))
        }
    }

    func destroy() {
        lock.lock()
        defer { lock.unlock() }
        guard created else { return }
        var nid = makeNID()
        _ = withUnsafePointer(to: &nid) { ptr in
            Shell_NotifyIconW(NIM_DELETE, UnsafeMutablePointer(mutating: ptr))
        }
        if let w = hwnd { DestroyWindow(w); hwnd = nil }
        created = false
    }

    // MARK: - Private

    private func makeNID() -> NOTIFYICONDATAW {
        var nid = NOTIFYICONDATAW()
        nid.cbSize = UINT(MemoryLayout<NOTIFYICONDATAW>.size)
        nid.hWnd = hwnd
        nid.uID = iconID
        nid.uCallbackMessage = callbackMsg
        return nid
    }

    private func wndProc(_ hwnd: HWND?, _ msg: UINT, _ wParam: WPARAM, _ lParam: LPARAM) -> LRESULT {
        if msg == callbackMsg {
            switch lParam {
            case WM_RBUTTONUP:
                showContextMenu(hwnd)
            case WM_LBUTTONUP:
                DebugLogger.shared.info("Tray: left-click (show window)", source: "WinTrayService")
            default:
                break
            }
            return 0
        }
        return DefWindowProcW(hwnd, msg, wParam, lParam)
    }

    private func showContextMenu(_ hwnd: HWND?) {
        let menu = CreatePopupMenu()
        AppendMenuW(menu, UINT(MF_STRING), 1001, "Show FluidVoice")
        AppendMenuW(menu, UINT(MF_SEPARATOR), 0, nil)
        AppendMenuW(menu, UINT(MF_STRING), 1002, "Quit")

        var point = POINT()
        _ = GetCursorPos(&point)
        _ = SetForegroundWindow(hwnd)
        TrackPopupMenu(menu, UINT(TPM_RIGHTBUTTON), point.x, point.y, 0, hwnd, nil)
        DestroyMenu(menu)
    }
}
#endif
