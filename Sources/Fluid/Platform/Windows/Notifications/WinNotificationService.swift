import Foundation

#if os(Windows)
import WinSDK

// ponytail: Win32 tray balloon notifications via Shell_NotifyIconW(NIF_INFO).
// Creates a hidden message-only window to own the notification icon.
// Proper WinRT Toast interop is the long-term upgrade path.
enum NotificationService: NotificationProtocol {
    private static let iconID: UINT = 1001
    private static let windowClass = "FluidVoiceNotificationWindow"
    private static var notifWindow: HWND?
    private static var ready = false
    private static let lock = NSLock()

    private static func ensureReady() {
        lock.lock()
        defer { lock.unlock() }
        guard !ready else { return }

        var wc = WNDCLASSW()
        wc.lpfnWndProc = { hwnd, msg, wParam, lParam in
            DefWindowProcW(hwnd, msg, wParam, lParam)
        }
        wc.hInstance = GetModuleHandleW(nil)
        wc.lpszClassName = windowClass
        _ = RegisterClassW(&wc)

        let hwnd = CreateWindowExW(
            0, windowClass, nil, 0,
            CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT,
            HWND_MESSAGE, nil, GetModuleHandleW(nil), nil
        )
        guard let hwnd = hwnd else { return }
        notifWindow = hwnd

        var nid = NOTIFYICONDATAW()
        nid.cbSize = UINT(MemoryLayout<NOTIFYICONDATAW>.size)
        nid.hWnd = hwnd
        nid.uID = iconID
        nid.uFlags = UINT(NIF_MESSAGE)
        nid.uCallbackMessage = WM_APP + 100
        ready = Shell_NotifyIconW(NIM_ADD, &nid) != 0
    }

    static func show(title: String, body: String, subtitle: String? = nil, userInfo: [String: String] = [:]) -> String? {
        ensureReady()
        guard let hwnd = notifWindow else {
            DebugLogger.shared.error("Notification window not available", source: "NotificationService")
            return nil
        }

        let identifier = UUID().uuidString

        var nid = NOTIFYICONDATAW()
        nid.cbSize = UINT(MemoryLayout<NOTIFYICONDATAW>.size)
        nid.hWnd = hwnd
        nid.uID = iconID
        nid.uFlags = UINT(NIF_INFO)
        nid.dwInfoFlags = UINT(NIIF_INFO)

        let titleLen = min(title.utf16.count, 63)
        title.withCString(encodedAs: UTF16.self) { src in
            memcpy(&nid.szInfoTitle, src, (titleLen + 1) * 2)
        }

        let message: String
        if let subtitle, !subtitle.isEmpty {
            message = "\(subtitle)\n\n\(body)"
        } else {
            message = body
        }

        let msgLen = min(message.utf16.count, 255)
        message.withCString(encodedAs: UTF16.self) { src in
            memcpy(&nid.szInfo, src, (msgLen + 1) * 2)
        }

        // ponytail: timeout matches macOS (no sound on desktop balloon)
        nid.uTimeoutOrVersion = UINT(10000)

        let result = Shell_NotifyIconW(NIM_MODIFY, &nid)
        if result == 0 {
            DebugLogger.shared.error("Shell_NotifyIcon failed: \(GetLastError())", source: "NotificationService")
            return nil
        }

        DebugLogger.shared.info("Notification shown: \(title)", source: "NotificationService")
        return identifier
    }

    static func requestPermissionIfNeeded() {
        // ponytail: desktop Win32 apps always have notification capability via tray.
        // No explicit permission prompt needed — unlike UWP Toast or macOS UNCenter.
        DebugLogger.shared.info("Notification permission not required for desktop Win32", source: "NotificationService")
    }

    static func getPermissionState() -> Bool {
        // ponytail: always available for desktop apps using Shell_NotifyIcon
        true
    }
}
#endif
