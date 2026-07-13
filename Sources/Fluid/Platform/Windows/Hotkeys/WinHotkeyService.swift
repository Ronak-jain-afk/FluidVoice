import Foundation

#if os(Windows)
import WinSDK

// ponytail: Win32 RegisterHotKey API for global keyboard shortcuts.
// Creates a hidden message-only window that receives WM_HOTKEY.
// Mouse shortcuts not supported by RegisterHotKey — would need LL hook.
final class WinHotkeyService: HotkeyProtocol {
    static let shared = WinHotkeyService()

    private let windowClass = "FluidVoiceHotkeyWindow"
    private var hotkeyWindow: HWND?
    private var nextID: Int = 1
    private var activeIDs: Set<Int> = []
    private var running = false
    private var messageThread: Thread?
    private let lock = NSLock()

    private init() {}

    func start() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard !running else { return true }

        var wc = WNDCLASSW()
        wc.lpfnWndProc = { hwnd, msg, wParam, lParam in
            if msg == WM_HOTKEY {
                let _ = lParam // HIWORD = repeat, LOWORD = modifiers
                DebugLogger.shared.info("Hotkey triggered: id=\(wParam)", source: "WinHotkeyService")
                // ponytail: callback wiring for app-level handlers goes here
                return 0
            }
            return DefWindowProcW(hwnd, msg, wParam, lParam)
        }
        wc.hInstance = GetModuleHandleW(nil)
        wc.lpszClassName = windowClass
        _ = RegisterClassW(&wc)

        let hwnd = CreateWindowExW(
            0, windowClass, nil, 0,
            CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT,
            HWND_MESSAGE, nil, GetModuleHandleW(nil), nil
        )
        guard let hwnd = hwnd else {
            DebugLogger.shared.error("WinHotkey: failed to create message window", source: "WinHotkeyService")
            return false
        }
        hotkeyWindow = hwnd
        running = true

        // ponytail: message pump runs on background thread — keeps UI responsive
        messageThread = Thread { [weak self] in
            guard let hwnd = self?.hotkeyWindow else { return }
            var msg = MSG()
            while self?.running == true {
                let result = GetMessageW(&msg, hwnd, 0, 0)
                if result == 0 { break } // WM_QUIT
                TranslateMessage(&msg)
                DispatchMessageW(&msg)
            }
        }
        messageThread?.start()

        DebugLogger.shared.info("WinHotkey: started", source: "WinHotkeyService")
        return true
    }

    func stop() {
        lock.lock()
        defer { lock.unlock() }
        running = false
        unregisterAll()
        if let hwnd = hotkeyWindow {
            DestroyWindow(hwnd)
            hotkeyWindow = nil
        }
        messageThread = nil
        DebugLogger.shared.info("WinHotkey: stopped", source: "WinHotkeyService")
    }

    func register(shortcuts: [HotkeyShortcut]) -> Bool {
        guard let hwnd = hotkeyWindow else {
            DebugLogger.shared.error("WinHotkey: not started, call start() first", source: "WinHotkeyService")
            return false
        }
        var allSucceeded = true
        for shortcut in shortcuts {
            guard shortcut.kind == .keyboard else {
                DebugLogger.shared.info("WinHotkey: mouse shortcuts not supported, skipping", source: "WinHotkeyService")
                allSucceeded = false
                continue
            }
            let modifiers = mapModifiers(shortcut.modifierFlags.rawValue)
            let vk = carbonKeyCodeToVK(shortcut.keyCode)
            guard vk != 0 else {
                DebugLogger.shared.info("WinHotkey: unmapped key code \(shortcut.keyCode), skipping", source: "WinHotkeyService")
                allSucceeded = false
                continue
            }
            let id = nextID
            nextID += 1
            let result = RegisterHotKey(hwnd, Int32(id), UInt32(modifiers), UInt32(vk))
            if result {
                activeIDs.insert(id)
                DebugLogger.shared.info("WinHotkey: registered id=\(id) vk=\(vk) mods=\(modifiers)", source: "WinHotkeyService")
            } else {
                DebugLogger.shared.error("WinHotkey: RegisterHotKey failed for vk=\(vk) err=\(GetLastError())", source: "WinHotkeyService")
                allSucceeded = false
            }
        }
        return allSucceeded
    }

    func unregisterAll() {
        for id in activeIDs {
            UnregisterHotKey(nil, Int32(id))
        }
        activeIDs.removeAll()
        DebugLogger.shared.info("WinHotkey: unregistered all", source: "WinHotkeyService")
    }

    // MARK: - Modifier Mapping

    // ponytail: maps macOS modifier flags raw bits → Win32 MOD_* mask.
    // macOS Command → MOD_WIN, Option → MOD_ALT, Control → MOD_CONTROL, Shift → MOD_SHIFT.
    // Uses hardcoded raw values to avoid AppKit dependency on Windows.
    // NSEvent.ModifierFlags: command=1<<20, option=1<<19, control=1<<18, shift=1<<17
    private func mapModifiers(_ rawFlags: UInt) -> Int {
        var mods = 0
        if rawFlags & (1 << 20) != 0 { mods |= MOD_WIN }  // Command
        if rawFlags & (1 << 19) != 0 { mods |= MOD_ALT }  // Option
        if rawFlags & (1 << 18) != 0 { mods |= MOD_CONTROL } // Control
        if rawFlags & (1 << 17) != 0 { mods |= MOD_SHIFT } // Shift
        return mods
    }

    // ponytail: partial Carbon→VK mapping for common keys.
    // Full mapping in docs/windows-port/phase2_5_audit.md — add as needed.
    private func carbonKeyCodeToVK(_ code: UInt16) -> Int {
        switch code {
        // Numbers row  (Carbon key codes for US keyboard)
        case 18: return 0x31 // 1
        case 19: return 0x32 // 2
        case 20: return 0x33 // 3
        case 21: return 0x34 // 4
        case 23: return 0x35 // 5
        case 22: return 0x36 // 6
        case 26: return 0x37 // 7
        case 28: return 0x38 // 8
        case 25: return 0x39 // 9
        case 29: return 0x30 // 0
        // Common letters (Carbon key codes = key position, not alphabetical)
        case 0:  return 0x41 // A
        case 11: return 0x42 // B
        case 8:  return 0x43 // C
        case 2:  return 0x44 // D
        case 14: return 0x45 // E
        case 3:  return 0x46 // F
        case 5:  return 0x47 // G
        case 4:  return 0x48 // H
        case 34: return 0x49 // I
        case 38: return 0x4A // J
        case 40: return 0x4B // K
        case 37: return 0x4C // L
        case 46: return 0x4D // M
        case 45: return 0x4E // N
        case 31: return 0x4F // O
        case 35: return 0x50 // P
        case 12: return 0x51 // Q
        case 15: return 0x52 // R
        case 1:  return 0x53 // S
        case 17: return 0x54 // T
        case 32: return 0x55 // U
        case 9:  return 0x56 // V
        case 13: return 0x57 // W
        case 7:  return 0x58 // X
        case 16: return 0x59 // Y
        case 6:  return 0x5A // Z
        // Function keys
        case 122: return VK_F1  // F1
        case 120: return VK_F2  // F2
        case 99:  return VK_F3  // F3
        case 118: return VK_F4  // F4
        case 96:  return VK_F5  // F5
        case 97:  return VK_F6  // F6
        case 98:  return VK_F7  // F7
        case 100: return VK_F8  // F8
        case 101: return VK_F9  // F9
        case 109: return VK_F10 // F10
        case 103: return VK_F11 // F11
        case 111: return VK_F12 // F12
        // Special keys
        case 36: return VK_RETURN
        case 48: return VK_TAB
        case 49: return VK_SPACE
        case 51: return VK_BACK   // Delete/Backspace
        case 53: return VK_ESCAPE
        case 123: return VK_LEFT
        case 124: return VK_RIGHT
        case 125: return VK_DOWN
        case 126: return VK_UP
        case 116: return VK_PRIOR // Page Up
        case 121: return VK_NEXT  // Page Down
        case 115: return VK_HOME
        case 119: return VK_END
        case 117: return VK_DELETE // Forward delete
        case 76:  return VK_OEM_PLUS // +/= on some layouts
        case 27:  return VK_OEM_MINUS // -/_
        default:  return 0 // unmapped
        }
    }
}
#endif
