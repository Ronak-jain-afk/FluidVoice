import Foundation

#if os(Windows)
final class WinHotkeyService: HotkeyProtocol {
    static let shared = WinHotkeyService()
    private init() {}
    func register(shortcuts: [HotkeyShortcut]) -> Bool {
        DebugLogger.shared.info("[Windows] Hotkey register stub", source: "WinHotkeyService")
        return false
    }
    func unregisterAll() {
        DebugLogger.shared.info("[Windows] Hotkey unregister stub", source: "WinHotkeyService")
    }
    func start() -> Bool {
        DebugLogger.shared.info("[Windows] Hotkey start stub", source: "WinHotkeyService")
        return false
    }
    func stop() {
        DebugLogger.shared.info("[Windows] Hotkey stop stub", source: "WinHotkeyService")
    }
}
#endif
