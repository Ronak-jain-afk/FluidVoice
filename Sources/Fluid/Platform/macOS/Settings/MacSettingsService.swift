import Foundation

#if os(macOS)

// ponytail: UserDefaults-backed settings storage extracted from SettingsStore.
// SettingsStore remains the primary settings facade for business logic;
// this isolates the platform persistence layer.
final class MacSettingsService: SettingsProtocol {
    static let shared = MacSettingsService()
    private let defaults = UserDefaults.standard

    private init() {}

    func save(key: String, value: Any) {
        defaults.set(value, forKey: key)
    }

    func load<T>(key: String, type: T.Type) -> T? {
        defaults.object(forKey: key) as? T
    }

    func remove(key: String) {
        defaults.removeObject(forKey: key)
    }

    func contains(key: String) -> Bool {
        defaults.object(forKey: key) != nil
    }
}
#endif
