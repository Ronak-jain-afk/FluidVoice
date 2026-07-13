import Foundation

protocol ClipboardProtocol {
    static func copyToClipboard(_ text: String) -> Bool
    static func getFromClipboard() -> String?
}
