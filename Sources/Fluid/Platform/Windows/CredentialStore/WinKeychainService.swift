import Foundation

#if os(Windows)
import WinSDK

// ponytail: Windows Credential Manager API via CredWriteW/CredReadW/CredDeleteW.
// Stores a JSON [String: String] dict as a single generic credential blob.
// Data is encrypted at rest by the OS using the user's login credentials.
final class KeychainService: CredentialStoreProtocol {
    static let shared = KeychainService()

    private let targetName = "FluidVoice_ProviderApiKeys"
    private let type: UInt32 = CRED_TYPE_GENERIC

    private init() {}

    func save(key: String, value: String) throws {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        var keys = try loadAllKeys()
        keys[key] = trimmed
        try writeAllKeys(keys)
    }

    func load(key: String) throws -> String? {
        let keys = try loadAllKeys()
        return keys[key]
    }

    func delete(key: String) throws {
        var keys = try loadAllKeys()
        guard keys.removeValue(forKey: key) != nil else { return }
        try writeAllKeys(keys)
    }

    func contains(key: String) -> Bool {
        guard let keys = try? loadAllKeys() else { return false }
        return keys[key] != nil
    }

    // MARK: - Private

    private func loadAllKeys() throws -> [String: String] {
        var pCredential: UnsafeMutablePointer<CREDENTIALW>?
        let ok = CredReadW(targetName, type, 0, &pCredential)
        guard ok else {
            let err = GetLastError()
            if err == ERROR_NOT_FOUND { return [:] }
            throw CredentialStoreError.unhandled("CredRead failed: \(err)")
        }
        defer { CredFree(pCredential) }

        guard let cred = pCredential?.pointee,
              let blob = cred.CredentialBlob,
              cred.CredentialBlobSize > 0
        else { return [:] }

        let data = Data(bytes: blob, count: Int(cred.CredentialBlobSize))
        if data.isEmpty { return [:] }
        return try JSONDecoder().decode([String: String].self, from: data)
    }

    private func writeAllKeys(_ keys: [String: String]) throws {
        let data = try JSONEncoder().encode(keys)

        // Delete existing so we can write fresh (CredWriteW upserts but clean is safer)
        _ = CredDeleteW(targetName, type, 0)

        var blob = CREDENTIALW()
        blob.Type = type
        blob.TargetName = UnsafeMutablePointer<UInt16>(mutating: (targetName as NSString).utf16String)
        blob.CredentialBlobSize = DWORD(data.count)
        blob.Persist = DWORD(CRED_PERSIST_LOCAL_MACHINE)
        blob.UserName = UnsafeMutablePointer<UInt16>(mutating: (ProcessInfo.processInfo.fullUserName as NSString).utf16String)

        let ok = data.withUnsafeBytes { rawBuf in
            let ptr = rawBuf.bindMemory(to: UInt8.self).baseAddress
            blob.CredentialBlob = ptr
            return CredWriteW(&blob, 0)
        }

        guard ok else {
            throw CredentialStoreError.unhandled("CredWrite failed: \(GetLastError())")
        }
    }
}
#endif
