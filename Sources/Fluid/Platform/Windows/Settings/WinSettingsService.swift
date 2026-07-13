import Foundation

#if os(Windows)
final class WinSettingsService: SettingsProtocol {
    static let shared = WinSettingsService()
    private init() {}
    func save(key: String, value: Any) {
        DebugLogger.shared.info("[Windows] Settings save stub: \(key)", source: "WinSettingsService")
    }
    func load<T>(key: String, type: T.Type) -> T? {
        DebugLogger.shared.info("[Windows] Settings load stub: \(key)", source: "WinSettingsService")
        return nil
    }
    func remove(key: String) {
        DebugLogger.shared.info("[Windows] Settings remove stub: \(key)", source: "WinSettingsService")
    }
    func contains(key: String) -> Bool {
        DebugLogger.shared.info("[Windows] Settings contains stub: \(key)", source: "WinSettingsService")
        return false
    }
}
#endif
