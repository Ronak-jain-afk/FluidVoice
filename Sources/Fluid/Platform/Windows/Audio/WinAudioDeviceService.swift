import Foundation

#if os(Windows)
import WinSDK

// ponytail: WASAPI MMDeviceEnumerator for audio device enumeration.
final class WinAudioDeviceService: AudioDeviceProtocol {
    static let shared = WinAudioDeviceService()
    private init() {}

    func listInputDevices() -> [AudioDeviceInfo] {
        guard let enumerator = createEnumerator() else { return [] }
        defer { _ = enumerator.pointee.lpVtbl.pointee.Release(enumerator) }

        var collection: UnsafeMutablePointer<IMMDeviceCollection>?
        let hr = enumerator.pointee.lpVtbl.pointee.EnumAudioEndpoints(enumerator, eCapture, DEVICE_STATE_ACTIVE, &collection)
        guard hr == S_OK, let c = collection else { return [] }
        defer { _ = c.pointee.lpVtbl.pointee.Release(c) }

        var count: UINT = 0
        _ = c.pointee.lpVtbl.pointee.GetCount(c, &count)

        var devices: [AudioDeviceInfo] = []
        for i in 0..<count {
            var device: UnsafeMutablePointer<IMMDevice>?
            guard c.pointee.lpVtbl.pointee.Item(c, i, &device) == S_OK, let d = device else { continue }
            defer { _ = d.pointee.lpVtbl.pointee.Release(d) }

            if let info = deviceInfo(d) {
                devices.append(info)
            }
        }
        return devices
    }

    func defaultInputDevice() -> AudioDeviceInfo? {
        guard let enumerator = createEnumerator() else { return nil }
        defer { _ = enumerator.pointee.lpVtbl.pointee.Release(enumerator) }

        var device: UnsafeMutablePointer<IMMDevice>?
        let hr = enumerator.pointee.lpVtbl.pointee.GetDefaultAudioEndpoint(enumerator, eCapture, eConsole, &device)
        guard hr == S_OK, let d = device else { return nil }
        defer { _ = d.pointee.lpVtbl.pointee.Release(d) }

        return deviceInfo(d)
    }

    // MARK: - Private

    private func createEnumerator() -> UnsafeMutablePointer<IMMDeviceEnumerator>? {
        var enumerator: UnsafeMutablePointer<IMMDeviceEnumerator>?
        let hr = CoCreateInstance(
            CLSID_MMDeviceEnumerator, nil, CLSCTX_INPROC_SERVER,
            IID_IMMDeviceEnumerator, &enumerator
        )
        guard hr == S_OK else {
            DebugLogger.shared.error("WASAPI: CoCreateInstance MMDeviceEnumerator failed: \(hr)", source: "WinAudioDeviceService")
            return nil
        }
        return enumerator
    }

    private func deviceInfo(_ device: UnsafeMutablePointer<IMMDevice>) -> AudioDeviceInfo? {
        var idPtr: UnsafeMutablePointer<WCHAR>?
        guard device.pointee.lpVtbl.pointee.GetId(device, &idPtr) == S_OK else { return nil }
        defer { CoTaskMemFree(idPtr) }
        let deviceID = String(decodingCString: idPtr!, as: UTF16.self)

        var store: UnsafeMutablePointer<IPropertyStore>?
        guard device.pointee.lpVtbl.pointee.OpenPropertyStore(device, STGM_READ, &store) == S_OK,
              let s = store
        else { return AudioDeviceInfo(id: deviceID, name: deviceID, hasInput: true, hasOutput: false) }
        defer { _ = s.pointee.lpVtbl.pointee.Release(s) }

        var propKey = PKEY_Device_FriendlyName
        var propVar: PROPVARIANT = PROPVARIANT()
        let hr = s.pointee.lpVtbl.pointee.GetValue(s, &propKey, &propVar)
        let name: String
        if hr == S_OK, propVar.vt == VT_LPWSTR, let ptr = propVar.Anonymous.Anonymous.pwszVal {
            name = String(decodingCString: ptr, as: UTF16.self)
            PropVariantClear(&propVar)
        } else {
            name = deviceID
        }

        return AudioDeviceInfo(id: deviceID, name: name, hasInput: true, hasOutput: false)
    }
}

// ponytail: CLSID/IID constants from MMDeviceAPI.h
private let CLSID_MMDeviceEnumerator = GUID(
    Data1: 0xBCDE0395, Data2: 0xE52F, Data3: 0x467C,
    Data4: (0x8E, 0x3D, 0xC4, 0x57, 0x92, 0x91, 0x69, 0x2E)
)

private let IID_IMMDeviceEnumerator = GUID(
    Data1: 0xA95664D2, Data2: 0x9614, Data3: 0x4F35,
    Data4: (0xA7, 0x46, 0xDE, 0x8D, 0xB6, 0x36, 0x17, 0xE6)
)
#endif
