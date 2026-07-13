import Foundation

#if os(Windows)
final class KeychainService: CredentialStoreProtocol {
    static let shared = KeychainService()
    private init() {}
    func save(key: String, value: String) throws {
        DebugLogger.shared.info("[Windows] Keychain save stub: \(key)", source: "KeychainService")
    }
    func load(key: String) throws -> String? {
        DebugLogger.shared.info("[Windows] Keychain load stub: \(key)", source: "KeychainService")
        return nil
    }
    func delete(key: String) throws {
        DebugLogger.shared.info("[Windows] Keychain delete stub: \(key)", source: "KeychainService")
    }
    func contains(key: String) -> Bool {
        DebugLogger.shared.info("[Windows] Keychain contains stub: \(key)", source: "KeychainService")
        return false
    }
}
#endif
