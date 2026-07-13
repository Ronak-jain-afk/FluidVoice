import Foundation

#if os(Windows)
import WinSDK

// ponytail: Win32 window detection via GetForegroundWindow + GetWindowText.
// bundleIdentifier maps to the process executable name (no bundle concept on Windows).
final class WinWindowDetectionService: WindowDetectionProtocol {
    static let shared = WinWindowDetectionService()
    private init() {}

    func focusedApplication() -> WindowInfo? {
        guard let hwnd = GetForegroundWindow() else { return nil }
        guard hwnd != GetShellWindow() else { return nil }
        var pid: DWORD = 0
        _ = GetWindowThreadProcessId(hwnd, &pid)
        guard pid > 0 else { return nil }
        let title = windowTitle(hwnd)
        let exec = executableName(pid)
        return WindowInfo(pid: pid_t(pid), bundleIdentifier: exec, windowTitle: title)
    }

    func activeWindowTitle() -> String? {
        guard let hwnd = GetForegroundWindow(), hwnd != GetShellWindow() else { return nil }
        return windowTitle(hwnd)
    }

    func foregroundPID() -> pid_t? {
        guard let hwnd = GetForegroundWindow(), hwnd != GetShellWindow() else { return nil }
        var pid: DWORD = 0
        _ = GetWindowThreadProcessId(hwnd, &pid)
        return pid > 0 ? pid_t(pid) : nil
    }

    // MARK: - Private

    private func windowTitle(_ hwnd: HWND) -> String? {
        let len = GetWindowTextLengthW(hwnd)
        guard len > 0 else { return nil }
        let buf = UnsafeMutablePointer<WCHAR>.allocate(capacity: Int(len) + 1)
        defer { buf.deallocate() }
        let actual = GetWindowTextW(hwnd, buf, Int32(len) + 1)
        guard actual > 0 else { return nil }
        return String(decodingCString: buf, as: UTF16.self)
    }

    private func executableName(_ pid: DWORD) -> String? {
        let handle = OpenProcess(DWORD(PROCESS_QUERY_LIMITED_INFORMATION), false, pid)
        guard let h = handle else { return nil }
        defer { CloseHandle(h) }
        let buf = UnsafeMutablePointer<WCHAR>.allocate(capacity: 260)
        defer { buf.deallocate() }
        var size: DWORD = 260
        guard QueryFullProcessImageNameW(h, 0, buf, &size) else { return nil }
        let path = String(decodingCString: buf, as: UTF16.self)
        return URL(fileURLWithPath: path).lastPathComponent
    }
}
#endif
