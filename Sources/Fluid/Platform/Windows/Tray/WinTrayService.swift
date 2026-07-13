import Foundation

#if os(Windows)
final class WinTrayService: TrayProtocol {
    static let shared = WinTrayService()
    private init() {}
    func create() -> Bool {
        DebugLogger.shared.info("[Windows] Tray create stub", source: "WinTrayService")
        return false
    }
    func updateIcon(name: String) {
        DebugLogger.shared.info("[Windows] Tray updateIcon stub: \(name)", source: "WinTrayService")
    }
    func updateMenu() {
        DebugLogger.shared.info("[Windows] Tray updateMenu stub", source: "WinTrayService")
    }
    func showNotification(title: String, message: String) {
        DebugLogger.shared.info("[Windows] Tray notification stub: \(title)", source: "WinTrayService")
    }
    func destroy() {
        DebugLogger.shared.info("[Windows] Tray destroy stub", source: "WinTrayService")
    }
}
#endif
