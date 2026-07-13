import Foundation
import Security

#if os(macOS)

// ponytail: macOS-specific error type preserved for existing callers
enum KeychainServiceError: Error, LocalizedError {
    case invalidData
    case unhandled(OSStatus)

    var errorDescription: String? {
        switch self {
        case .invalidData:
            return "Failed to convert key data."
        case let .unhandled(status):
            if let message = SecCopyErrorMessageString(status, nil) as String? {
                return "\(message) (OSStatus: \(status))"
            }
            return "Unhandled Keychain error (OSStatus: \(status))"
        }
    }
}

final class KeychainService: CredentialStoreProtocol {
    static let shared = KeychainService()

    private let service = "com.fluidvoice.provider-api-keys"
    private let account = "fluidApiKeys"

    private init() {}

    func save(key: String, value: String) throws {
        try storeKey(value, for: key)
    }

    func load(key: String) throws -> String? {
        try fetchKey(for: key)
    }

    func delete(key: String) throws {
        try deleteKey(for: key)
    }

    func contains(key: String) -> Bool {
        containsKey(for: key)
    }

    func storeKey(_ key: String, for providerID: String) throws {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        var keys = try loadStoredKeys()
        keys[providerID] = trimmed
        try saveStoredKeys(keys)
    }

    func fetchKey(for providerID: String) throws -> String? {
        let keys = try loadStoredKeys()
        return keys[providerID]
    }

    func deleteKey(for providerID: String) throws {
        var keys = try loadStoredKeys()
        guard keys.removeValue(forKey: providerID) != nil else { return }
        try saveStoredKeys(keys)
    }

    func containsKey(for providerID: String) -> Bool {
        guard let keys = try? loadStoredKeys() else { return false }
        return keys[providerID] != nil
    }

    func allProviderIDs() throws -> [String] {
        try loadStoredKeys().keys.sorted()
    }

    func fetchAllKeys() throws -> [String: String] {
        try loadStoredKeys()
    }

    func storeAllKeys(_ values: [String: String]) throws {
        try saveStoredKeys(values)
    }

    func legacyProviderEntries() throws -> [String: String] {
        var result: [String: String] = [:]
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll,
        ]
        var items: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &items)
        switch status {
        case errSecSuccess:
            guard let attributesArray = items as? [[String: Any]] else { return [:] }
            for attributes in attributesArray {
                guard let providerID = attributes[kSecAttrAccount as String] as? String, providerID != account else { continue }
                var dataQuery = legacyQuery(for: providerID)
                dataQuery[kSecReturnData as String] = true
                dataQuery[kSecMatchLimit as String] = kSecMatchLimitOne
                var dataItem: CFTypeRef?
                let dataStatus = SecItemCopyMatching(dataQuery as CFDictionary, &dataItem)
                guard dataStatus == errSecSuccess else {
                    if dataStatus == errSecItemNotFound { continue }
                    throw KeychainServiceError.unhandled(dataStatus)
                }
                guard let data = dataItem as? Data, let key = String(data: data, encoding: .utf8) else { continue }
                result[providerID] = key
            }
            return result
        case errSecItemNotFound:
            return [:]
        default:
            throw KeychainServiceError.unhandled(status)
        }
    }

    func removeLegacyEntries(providerIDs: [String] = []) throws {
        let targets: [String]
        if !providerIDs.isEmpty { targets = providerIDs }
        else { targets = try Array(legacyProviderEntries().keys) }
        for providerID in targets {
            let status = SecItemDelete(legacyQuery(for: providerID) as CFDictionary)
            guard status == errSecSuccess || status == errSecItemNotFound else {
                throw KeychainServiceError.unhandled(status)
            }
        }
    }

    // MARK: - Private

    private func loadStoredKeys() throws -> [String: String] {
        var query = aggregatedQuery()
        query[kSecReturnData as String] = kCFBooleanTrue
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        switch status {
        case errSecSuccess:
            guard let data = item as? Data else { throw KeychainServiceError.invalidData }
            if data.isEmpty { return [:] }
            return try JSONDecoder().decode([String: String].self, from: data)
        case errSecItemNotFound:
            return [:]
        default:
            throw KeychainServiceError.unhandled(status)
        }
    }

    private func saveStoredKeys(_ keys: [String: String]) throws {
        let data = try JSONEncoder().encode(keys)
        var attributes = aggregatedQuery()
        attributes[kSecValueData as String] = data
        let status = SecItemAdd(attributes as CFDictionary, nil)
        switch status {
        case errSecSuccess:
            try removeLegacyEntries()
        case errSecDuplicateItem:
            let updateAttributes: [String: Any] = [kSecValueData as String: data]
            let updateStatus = SecItemUpdate(aggregatedQuery() as CFDictionary, updateAttributes as CFDictionary)
            guard updateStatus == errSecSuccess else {
                throw KeychainServiceError.unhandled(updateStatus)
            }
            try removeLegacyEntries()
        default:
            throw KeychainServiceError.unhandled(status)
        }
    }

    private func aggregatedQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }

    private func legacyQuery(for providerID: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: providerID,
        ]
    }
}
#endif
