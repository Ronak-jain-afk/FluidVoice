import Foundation

#if os(Windows)
final class WinApplicationLifecycleService: ApplicationLifecycleProtocol {
    static let shared = WinApplicationLifecycleService()
    private init() {}
    func onStartup() {
        DebugLogger.shared.info("[Windows] Lifecycle onStartup stub", source: "WinLifecycle")
    }
    func onShutdown() {
        DebugLogger.shared.info("[Windows] Lifecycle onShutdown stub", source: "WinLifecycle")
    }
    func onSleep() {
        DebugLogger.shared.info("[Windows] Lifecycle onSleep stub", source: "WinLifecycle")
    }
    func onWake() {
        DebugLogger.shared.info("[Windows] Lifecycle onWake stub", source: "WinLifecycle")
    }
}
#endif
