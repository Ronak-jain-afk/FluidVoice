import Foundation

#if os(Windows)
final class WinWindowDetectionService: WindowDetectionProtocol {
    static let shared = WinWindowDetectionService()
    private init() {}
    func focusedApplication() -> WindowInfo? {
        DebugLogger.shared.info("[Windows] WindowDetection focusedApp stub", source: "WinWindowDetectionService")
        return nil
    }
    func activeWindowTitle() -> String? {
        DebugLogger.shared.info("[Windows] WindowDetection windowTitle stub", source: "WinWindowDetectionService")
        return nil
    }
    func foregroundPID() -> pid_t? {
        DebugLogger.shared.info("[Windows] WindowDetection foregroundPID stub", source: "WinWindowDetectionService")
        return nil
    }
}
#endif
