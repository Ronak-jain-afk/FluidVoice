import Foundation

protocol SettingsProtocol {
    func save(key: String, value: Any)
    func load<T>(key: String, type: T.Type) -> T?
    func remove(key: String)
    func contains(key: String) -> Bool
}
