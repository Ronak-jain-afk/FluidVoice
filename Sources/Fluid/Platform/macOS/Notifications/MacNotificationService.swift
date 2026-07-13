import Foundation
import UserNotifications

#if os(macOS)

enum NotificationService: NotificationProtocol {
    enum UserInfoKey {
        static let kind = "kind"
    }

    enum Kind {
        static let aiProcessingFallback = "aiProcessingFallback"
        static let commandModeFailure = "commandModeFailure"
    }

    static func show(title: String, body: String, subtitle: String? = nil, userInfo: [String: String] = [:]) -> String? {
        guard SettingsStore.shared.notifyAIProcessingFailures else { return nil }

        let center = UNUserNotificationCenter.current()
        var identifier: String?

        let group = DispatchGroup()
        group.enter()
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                let content = UNMutableNotificationContent()
                content.title = title
                content.body = body
                if let subtitle { content.subtitle = subtitle }
                content.sound = nil
                for (key, value) in userInfo {
                    content.userInfo[key] = value
                }
                let id = UUID().uuidString
                identifier = id
                let request = UNNotificationRequest(identifier: id, content: content, trigger: nil)
                center.add(request) { addError in
                    if let addError {
                        DebugLogger.shared.warning("Failed to show notification: \(addError.localizedDescription)", source: "NotificationService")
                    }
                }
            case .notDetermined:
                center.requestAuthorization(options: [.alert, .sound]) { granted, requestError in
                    if let requestError {
                        DebugLogger.shared.warning("Notification permission request failed: \(requestError.localizedDescription)", source: "NotificationService")
                    }
                }
            case .denied:
                DebugLogger.shared.debug("Skipping notification because permission is denied", source: "NotificationService")
            @unknown default:
                break
            }
            group.leave()
        }
        group.wait()
        return identifier
    }

    static func requestPermissionIfNeeded() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            if settings.authorizationStatus == .notDetermined {
                center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
            }
        }
    }

    static func getPermissionState() -> Bool {
        var granted = false
        let group = DispatchGroup()
        group.enter()
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            granted = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
            group.leave()
        }
        group.wait()
        return granted
    }
}

// ponytail: convenience wrappers preserving existing call API
extension NotificationService {
    static func showAIProcessingFallback(error: String) {
        let id = show(
            title: "AI Enhancement failed",
            body: "Typed raw transcription instead.",
            subtitle: error,
            userInfo: [UserInfoKey.kind: Kind.aiProcessingFallback]
        )
        if id == nil {
            DebugLogger.shared.debug("AI fallback notification not shown (permission or pref)", source: "NotificationService")
        }
    }

    static func showCommandModeFailure(error: String) {
        let id = show(
            title: "Command Mode needs setup",
            body: error,
            userInfo: [UserInfoKey.kind: Kind.commandModeFailure]
        )
        if id == nil {
            DebugLogger.shared.debug("Command mode notification not shown (permission or pref)", source: "NotificationService")
        }
    }
}
#endif
