import Foundation

protocol AccessibilityProtocol {
    func isTrusted() -> Bool
    func requestPermission() -> Bool
    func focusedElement() -> Any?
    func focusedApplication() -> pid_t?
    func selectedText() -> String?
    func textBeforeCursor() -> String
}
