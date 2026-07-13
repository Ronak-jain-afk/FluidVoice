import Foundation

#if os(Windows)
final class WinAudioDeviceService: AudioDeviceProtocol {
    static let shared = WinAudioDeviceService()
    private init() {}
    func listInputDevices() -> [AudioDeviceInfo] {
        DebugLogger.shared.info("[Windows] AudioDevice list stub", source: "WinAudioDeviceService")
        return []
    }
    func defaultInputDevice() -> AudioDeviceInfo? {
        DebugLogger.shared.info("[Windows] AudioDevice default stub", source: "WinAudioDeviceService")
        return nil
    }
}
#endif
