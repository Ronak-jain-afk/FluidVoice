import Foundation

protocol HotkeyProtocol {
    func register(shortcuts: [HotkeyShortcut]) -> Bool
    func unregisterAll()
    func start() -> Bool
    func stop()
}
