import Foundation

#if os(Windows)
enum NotificationService: NotificationProtocol {
    static func show(title: String, body: String, subtitle: String? = nil, userInfo: [String: String] = [:]) -> String? {
        DebugLogger.shared.info("[Windows] Notification stub: \(title)", source: "NotificationService")
        return nil
    }
    static func requestPermissionIfNeeded() {
        DebugLogger.shared.info("[Windows] Notification permission stub", source: "NotificationService")
    }
    static func getPermissionState() -> Bool { false }
}
#endif
