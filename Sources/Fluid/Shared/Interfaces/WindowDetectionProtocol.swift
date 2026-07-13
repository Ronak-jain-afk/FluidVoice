import Foundation

struct WindowInfo {
    let pid: pid_t
    let bundleIdentifier: String?
    let windowTitle: String?
}

protocol WindowDetectionProtocol {
    func focusedApplication() -> WindowInfo?
    func activeWindowTitle() -> String?
    func foregroundPID() -> pid_t?
}
