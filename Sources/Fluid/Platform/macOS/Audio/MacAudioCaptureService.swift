import CoreAudio
import Foundation

#if os(macOS)

// ponytail: adapter over DirectCoreAudioInput + ASRService audio pipeline.
final class MacAudioCaptureService: AudioCaptureProtocol {
    static let shared = MacAudioCaptureService()

    private var capture: DirectCoreAudioInput?

    private init() {}

    var isRunning: Bool { capture != nil }
    var sampleRate: Double { capture?.sampleRate ?? 0 }
    var audioLevel: Float { 0 }

    func startCapture(deviceID: String?) throws {
        // ponytail: actual capture is initiated by ASRService.
        // DirectCoreAudioInput wraps the CoreAudio C bridge.
        DebugLogger.shared.info("MacAudioCaptureService: startCapture() — delegated to ASRService pipeline", source: "MacAudioCaptureService")
    }

    func stopCapture() {
        capture = nil
        DebugLogger.shared.info("MacAudioCaptureService: stopCapture()", source: "MacAudioCaptureService")
    }

    func pause() throws {
        DebugLogger.shared.info("MacAudioCaptureService: pause()", source: "MacAudioCaptureService")
    }

    func resume() throws {
        DebugLogger.shared.info("MacAudioCaptureService: resume()", source: "MacAudioCaptureService")
    }
}
#endif
