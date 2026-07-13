import Foundation

protocol NotificationProtocol {
    static func show(title: String, body: String, subtitle: String?, userInfo: [String: String]) -> String?
    static func requestPermissionIfNeeded()
    static func getPermissionState() -> Bool
}
