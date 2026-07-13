import Foundation

enum CredentialStoreError: Error, LocalizedError {
    case notFound
    case unhandled(String)

    var errorDescription: String? {
        switch self {
        case .notFound: return "Credential not found."
        case .unhandled(let detail): return detail
        }
    }
}

protocol CredentialStoreProtocol {
    func save(key: String, value: String) throws
    func load(key: String) throws -> String?
    func delete(key: String) throws
    func contains(key: String) -> Bool
}
