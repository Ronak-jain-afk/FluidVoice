import CoreAudio
import Foundation

#if os(macOS)

// ponytail: wraps the existing AudioDevice enum behind AudioDeviceProtocol.
final class MacAudioDeviceService: AudioDeviceProtocol {
    static let shared = MacAudioDeviceService()

    private init() {}

    func listInputDevices() -> [AudioDeviceInfo] {
        AudioDevice.listInputDevices().map { device in
            AudioDeviceInfo(id: device.uid, name: device.name, hasInput: device.hasInput, hasOutput: device.hasOutput)
        }
    }

    func defaultInputDevice() -> AudioDeviceInfo? {
        guard let device = AudioDevice.getDefaultInputDevice() else { return nil }
        return AudioDeviceInfo(id: device.uid, name: device.name, hasInput: device.hasInput, hasOutput: device.hasOutput)
    }
}
#endif
