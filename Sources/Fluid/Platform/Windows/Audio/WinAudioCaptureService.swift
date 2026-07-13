import Foundation

#if os(Windows)
final class WinAudioCaptureService: AudioCaptureProtocol {
    static let shared = WinAudioCaptureService()
    private init() {}
    var isRunning: Bool { false }
    var sampleRate: Double { 0 }
    var audioLevel: Float { 0 }
    func startCapture(deviceID: String?) throws {
        DebugLogger.shared.info("[Windows] AudioCapture start stub", source: "WinAudioCaptureService")
    }
    func stopCapture() {
        DebugLogger.shared.info("[Windows] AudioCapture stop stub", source: "WinAudioCaptureService")
    }
    func pause() throws {
        DebugLogger.shared.info("[Windows] AudioCapture pause stub", source: "WinAudioCaptureService")
    }
    func resume() throws {
        DebugLogger.shared.info("[Windows] AudioCapture resume stub", source: "WinAudioCaptureService")
    }
}
#endif
