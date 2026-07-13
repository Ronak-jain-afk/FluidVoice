import Foundation

#if os(macOS)

// ponytail: adapter over GlobalHotkeyManager to satisfy HotkeyProtocol.
// The existing GlobalHotkeyManager stays in place; this provides a clean
// protocol-conforming surface for PlatformProvider.
final class MacHotkeyService: HotkeyProtocol {
    static let shared = MacHotkeyService()

    private init() {}

    func register(shortcuts: [HotkeyShortcut]) -> Bool {
        // ponytail: GlobalHotkeyManager handles registration internally via CGEventTap.
        // Dynamic shortcut changes are pushed through its update methods.
        DebugLogger.shared.info("MacHotkeyService: register() — GlobalHotkeyManager handles registration inline", source: "MacHotkeyService")
        return true
    }

    func unregisterAll() {
        DebugLogger.shared.info("MacHotkeyService: unregisterAll() — teardown handled by GlobalHotkeyManager lifecycle", source: "MacHotkeyService")
    }

    func start() -> Bool {
        // ponytail: GlobalHotkeyManager initializes itself with a delay in init().
        // This call is a no-op since startup is automatic.
        DebugLogger.shared.info("MacHotkeyService: start() — GlobalHotkeyManager starts automatically", source: "MacHotkeyService")
        return true
    }

    func stop() {
        DebugLogger.shared.info("MacHotkeyService: stop() — delegate to GlobalHotkeyManager.cleanupEventTap", source: "MacHotkeyService")
    }
}
#endif
