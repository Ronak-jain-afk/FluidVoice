import Foundation

protocol TrayProtocol {
    func create() -> Bool
    func updateIcon(name: String)
    func updateMenu()
    func showNotification(title: String, message: String)
    func destroy()
}
