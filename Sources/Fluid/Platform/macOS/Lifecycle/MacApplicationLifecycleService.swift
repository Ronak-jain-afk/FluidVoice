import Foundation

#if os(macOS)

// ponytail: app lifecycle events. Actual lifecycle is handled by NSApplicationDelegate
// in AppDelegate.swift — this provides a protocol surface for cross-platform code.
final class MacApplicationLifecycleService: ApplicationLifecycleProtocol {
    static let shared = MacApplicationLifecycleService()

    private init() {}

    func onStartup() {
        DebugLogger.shared.info("MacApplicationLifecycleService: onStartup()", source: "MacLifecycle")
    }

    func onShutdown() {
        DebugLogger.shared.info("MacApplicationLifecycleService: onShutdown()", source: "MacLifecycle")
    }

    func onSleep() {
        DebugLogger.shared.info("MacApplicationLifecycleService: onSleep()", source: "MacLifecycle")
    }

    func onWake() {
        DebugLogger.shared.info("MacApplicationLifecycleService: onWake()", source: "MacLifecycle")
    }
}
#endif
