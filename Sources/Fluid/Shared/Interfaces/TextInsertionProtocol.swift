import Foundation

protocol TextInsertionProtocol {
    func insertText(_ text: String)
    func insertText(_ text: String, targetPID: pid_t?)
    func replaceSelection(_ text: String) -> Bool
    func typeText(_ text: String) -> Bool
    func pasteFromClipboard() -> Bool
}
