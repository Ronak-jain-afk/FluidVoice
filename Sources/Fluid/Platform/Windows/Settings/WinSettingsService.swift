import Foundation

#if os(Windows)

// ponytail: JSON file in %APPDATA%/FluidVoice/settings.json.
// Thread-safe via NSLock. Registry would be more "native" but JSON is
// portable across Swift on Windows and keeps values inspectable/debuggable.
// Upgrade to Registry if perf or roaming-profile requirements emerge.
final class WinSettingsService: SettingsProtocol {
    static let shared = WinSettingsService()
    private let lock = NSLock()
    private var cache: [String: Any] = [:]
    private let fileURL: URL
    private let queue = DispatchQueue(label: "com.fluidvoice.winsettings", qos: .utility)

    private init() {
        let appData = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("FluidVoice", isDirectory: true)
        fileURL = appData.appendingPathComponent("settings.json")
        try? FileManager.default.createDirectory(at: appData, withIntermediateDirectories: true)
        loadFromDisk()
    }

    func save(key: String, value: Any) {
        lock.withLock {
            cache[key] = value
        }
        saveToDisk()
    }

    func load<T>(key: String, type: T.Type) -> T? {
        lock.withLock {
            cache[key] as? T
        }
    }

    func remove(key: String) {
        lock.withLock {
            cache.removeValue(forKey: key)
        }
        saveToDisk()
    }

    func contains(key: String) -> Bool {
        lock.withLock {
            cache.keys.contains(key)
        }
    }

    // ponytail: file write on every save. Batch-friendly: debounce coalescing
    // can be added if single-session bulk writes become a hotspot.
    private func saveToDisk() {
        queue.async { [weak self] in
            guard let self = self else { return }
            let data: Data
            do {
                let dict = self.lock.withLock { self.cache }
                data = try JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted])
            } catch {
                DebugLogger.shared.error("WinSettings save serialization failed: \(error)", source: "WinSettingsService")
                return
            }
            do {
                try data.write(to: self.fileURL, options: .atomic)
            } catch {
                DebugLogger.shared.error("WinSettings save write failed: \(error)", source: "WinSettingsService")
            }
        }
    }

    private func loadFromDisk() {
        let data: Data
        do {
            data = try Data(contentsOf: fileURL)
        } catch {
            // ponytail: first launch or corrupted — start fresh
            return
        }
        do {
            guard let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                DebugLogger.shared.info("WinSettings load: unexpected format, starting fresh", source: "WinSettingsService")
                return
            }
            lock.withLock {
                cache = dict
            }
        } catch {
            DebugLogger.shared.info("WinSettings load deserialization failed: \(error)", source: "WinSettingsService")
        }
    }
}
#endif
