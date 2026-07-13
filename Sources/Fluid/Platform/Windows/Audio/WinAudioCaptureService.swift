import Foundation

#if os(Windows)
import WinSDK

// ponytail: WASAPI shared-mode audio capture via IAudioCaptureClient.
// Creates a dedicated capture thread with COM initialized for that apartment.
// Audio level = RMS of the last buffer chunk.
final class WinAudioCaptureService: AudioCaptureProtocol {
    static let shared = WinAudioCaptureService()

    private(set) var isRunning = false
    private(set) var sampleRate: Double = 0
    private(set) var audioLevel: Float = 0

    private var audioClient: UnsafeMutablePointer<IAudioClient>?
    private var captureClient: UnsafeMutablePointer<IAudioCaptureClient>?
    private var captureThread: Thread?
    private var paused = false
    private let lock = NSLock()
    private var deviceID: String?
    private var format: UnsafeMutablePointer<WAVEFORMATEX>?

    private init() {}

    func startCapture(deviceID: String?) throws {
        lock.lock()
        defer { lock.unlock() }
        guard !isRunning else { return }
        self.deviceID = deviceID

        var hnsBufferDuration: REFERENCE_TIME = 10000000 // 1s default
        var hnsPeriodicity: REFERENCE_TIME = 0

        guard let device = getDevice(deviceID) else {
            throw AudioCaptureError.deviceNotFound
        }
        defer { _ = device.pointee.lpVtbl.pointee.Release(device) }

        var client: UnsafeMutablePointer<IAudioClient>?
        let hrActivate = device.pointee.lpVtbl.pointee.Activate(device, IID_IAudioClient, CLSCTX_INPROC_SERVER, nil, &client)
        guard hrActivate == S_OK, let ac = client else {
            throw AudioCaptureError.activationFailed(hrActivate)
        }
        audioClient = ac

        var waveFormat: UnsafeMutablePointer<WAVEFORMATEX>?
        guard ac.pointee.lpVtbl.pointee.GetMixFormat(ac, &waveFormat) == S_OK, let wf = waveFormat else {
            throw AudioCaptureError.formatQueryFailed
        }
        format = wf
        sampleRate = Double(wf.pointee.nSamplesPerSec)

        let hrInit = ac.pointee.lpVtbl.pointee.Initialize(ac, AUDCLNT_SHAREMODE_SHARED, 0, hnsBufferDuration, hnsPeriodicity, wf, nil)
        guard hrInit == S_OK else {
            throw AudioCaptureError.initializationFailed(hrInit)
        }

        var cc: UnsafeMutablePointer<IAudioCaptureClient>?
        let hrService = ac.pointee.lpVtbl.pointee.GetService(ac, IID_IAudioCaptureClient, &cc)
        guard hrService == S_OK, let cap = cc else {
            throw AudioCaptureError.captureClientFailed(hrService)
        }
        captureClient = cap

        isRunning = true
        paused = false
        captureThread = Thread { [weak self] in
            _ = CoInitializeEx(nil, COINIT_MULTITHREADED)
            defer { CoUninitialize() }
            guard let self = self, let ac = self.audioClient else { return }
            _ = ac.pointee.lpVtbl.pointee.Start(ac)
            self.captureLoop()
            _ = ac.pointee.lpVtbl.pointee.Stop(ac)
        }
        captureThread?.start()
    }

    func stopCapture() {
        lock.lock()
        defer { lock.unlock() }
        isRunning = false
        paused = false
        captureThread = nil
        if let cap = captureClient {
            _ = cap.pointee.lpVtbl.pointee.Release(cap)
            captureClient = nil
        }
        if let ac = audioClient {
            _ = ac.pointee.lpVtbl.pointee.Release(ac)
            audioClient = nil
        }
        if let wf = format {
            CoTaskMemFree(wf)
            format = nil
        }
        sampleRate = 0
        audioLevel = 0
    }

    func pause() throws {
        lock.lock()
        paused = true
        lock.unlock()
    }

    func resume() throws {
        lock.lock()
        paused = false
        lock.unlock()
    }

    // MARK: - Private

    private func captureLoop() {
        guard let cap = captureClient else { return }
        var padFrames: UINT32 = 0

        while isRunning {
            if paused {
                Thread.sleep(forTimeInterval: 0.05)
                continue
            }

            guard let ac = audioClient,
                  ac.pointee.lpVtbl.pointee.GetCurrentPadding(ac, &padFrames) == S_OK,
                  padFrames > 0
            else {
                Thread.sleep(forTimeInterval: 0.01)
                continue
            }

            var data: UnsafeMutablePointer<UInt8>?
            var frames: UINT32 = 0
            var flags: DWORD = 0
            var devIndex: UINT64 = 0

            let hr = cap.pointee.lpVtbl.pointee.GetBuffer(cap, &data, &frames, &flags, &devIndex, nil)
            guard hr == S_OK, let buf = data, frames > 0 else {
                if hr != AUDCLNT_E_DEVICE_INVALIDATED {
                    Thread.sleep(forTimeInterval: 0.01)
                } else {
                    DebugLogger.shared.error("WASAPI: device invalidated", source: "WinAudioCaptureService")
                    isRunning = false
                }
                continue
            }

            let byteCount = Int(frames) * Int(format?.pointee.nBlockAlign ?? 2)
            if byteCount > 0 {
                audioLevel = computeRMS(buf, count: byteCount)
            }

            _ = cap.pointee.lpVtbl.pointee.ReleaseBuffer(cap, frames)
        }
    }

    private func computeRMS(_ data: UnsafeMutablePointer<UInt8>, count: Int) -> Float {
        let sampleCount = count / 2 // assume 16-bit PCM
        guard sampleCount > 0 else { return 0 }
        var sum: Float = 0
        let samples = UnsafeMutableRawPointer(data).assumingMemoryBound(to: Int16.self)
        for i in 0..<min(sampleCount, 4096) {
            let s = Float(samples[i]) / Float(Int16.max)
            sum += s * s
        }
        return sqrt(sum / Float(min(sampleCount, 4096)))
    }

    private func getDevice(_ deviceID: String?) -> UnsafeMutablePointer<IMMDevice>? {
        var enumerator: UnsafeMutablePointer<IMMDeviceEnumerator>?
        let hr = CoCreateInstance(CLSID_MMDeviceEnumerator, nil, CLSCTX_INPROC_SERVER, IID_IMMDeviceEnumerator, &enumerator)
        guard hr == S_OK, let e = enumerator else { return nil }
        defer { _ = e.pointee.lpVtbl.pointee.Release(e) }

        if let id = deviceID, !id.isEmpty {
            var device: UnsafeMutablePointer<IMMDevice>?
            let hres = id.withCString(encodedAs: UTF16.self) { ptr in
                e.pointee.lpVtbl.pointee.GetDevice(e, ptr, &device)
            }
            guard hres == S_OK else { return nil }
            return device
        }

        var device: UnsafeMutablePointer<IMMDevice>?
        let hres = e.pointee.lpVtbl.pointee.GetDefaultAudioEndpoint(e, eCapture, eConsole, &device)
        guard hres == S_OK else { return nil }
        return device
    }
}

enum AudioCaptureError: Error, LocalizedError {
    case deviceNotFound
    case activationFailed(HRESULT)
    case formatQueryFailed
    case initializationFailed(HRESULT)
    case captureClientFailed(HRESULT)

    var errorDescription: String? {
        switch self {
        case .deviceNotFound: return "Audio device not found"
        case .activationFailed(let hr): return "IAudioClient activation failed: \(hr)"
        case .formatQueryFailed: return "Failed to query audio mix format"
        case .initializationFailed(let hr): return "IAudioClient init failed: \(hr)"
        case .captureClientFailed(let hr): return "IAudioCaptureClient failed: \(hr)"
        }
    }
}

// ponytail: IID/CLSID from MMDeviceAPI.h + AudioClient.h
private let CLSID_MMDeviceEnumerator = GUID(
    Data1: 0xBCDE0395, Data2: 0xE52F, Data3: 0x467C,
    Data4: (0x8E, 0x3D, 0xC4, 0x57, 0x92, 0x91, 0x69, 0x2E)
)
private let IID_IMMDeviceEnumerator = GUID(
    Data1: 0xA95664D2, Data2: 0x9614, Data3: 0x4F35,
    Data4: (0xA7, 0x46, 0xDE, 0x8D, 0xB6, 0x36, 0x17, 0xE6)
)
private let IID_IAudioClient = GUID(
    Data1: 0x1CB9AD4C, Data2: 0xDBFA, Data3: 0x4C32,
    Data4: (0xB1, 0x78, 0xC2, 0xF5, 0x68, 0xA7, 0x03, 0xB2)
)
private let IID_IAudioCaptureClient = GUID(
    Data1: 0xC8ADBD64, Data2: 0xE71E, Data3: 0x48A0,
    Data4: (0xA4, 0xDE, 0x18, 0x5C, 0x39, 0x5C, 0xD8, 0xEE)
)
#endif
