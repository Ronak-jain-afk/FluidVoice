import Foundation

protocol AudioCaptureProtocol {
    func startCapture(deviceID: String?) throws
    func stopCapture()
    func pause() throws
    func resume() throws
    var isRunning: Bool { get }
    var sampleRate: Double { get }
    var audioLevel: Float { get }
}

protocol AudioDeviceProtocol {
    func listInputDevices() -> [AudioDeviceInfo]
    func defaultInputDevice() -> AudioDeviceInfo?
}

struct AudioDeviceInfo {
    let id: String
    let name: String
    let hasInput: Bool
    let hasOutput: Bool
}
