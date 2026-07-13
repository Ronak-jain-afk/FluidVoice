import Foundation

// ponytail: DI container — supplies the active platform implementations.
// macOS → Mac* services, Windows → Win* services.
// Callers resolve dependencies here instead of importing Apple frameworks directly.
enum PlatformProvider {
    #if os(Windows)
    static var clipboard: ClipboardProtocol.Type { WinClipboardService.self }
    static var notifications: NotificationProtocol.Type { WinNotificationService.self }
    static var keychain: CredentialStoreProtocol { WinKeychainService.shared }
    static var hotkeys: HotkeyProtocol { WinHotkeyService.shared }
    static var accessibility: AccessibilityProtocol { WinAccessibilityService.shared }
    static var textInsertion: TextInsertionProtocol { WinTextInsertionService.shared }
    static var tray: TrayProtocol { WinTrayService.shared }
    static var audioCapture: AudioCaptureProtocol { WinAudioCaptureService.shared }
    static var audioDevice: AudioDeviceProtocol { WinAudioDeviceService.shared }
    static var settings: SettingsProtocol { WinSettingsService.shared }
    static var windowDetection: WindowDetectionProtocol { WinWindowDetectionService.shared }
    static var lifecycle: ApplicationLifecycleProtocol { WinApplicationLifecycleService.shared }
    #elseif os(macOS)
    static var clipboard: ClipboardProtocol.Type { ClipboardService.self }
    static var notifications: NotificationProtocol.Type { NotificationService.self }
    static var keychain: CredentialStoreProtocol { KeychainService.shared }
    static var hotkeys: HotkeyProtocol { MacHotkeyService.shared }
    static var accessibility: AccessibilityProtocol { MacAccessibilityService.shared }
    static var textInsertion: TextInsertionProtocol { MacTextInsertionService.shared }
    static var tray: TrayProtocol { MacTrayService.shared }
    static var audioCapture: AudioCaptureProtocol { MacAudioCaptureService.shared }
    static var audioDevice: AudioDeviceProtocol { MacAudioDeviceService.shared }
    static var settings: SettingsProtocol { MacSettingsService.shared }
    static var windowDetection: WindowDetectionProtocol { MacWindowDetectionService.shared }
    static var lifecycle: ApplicationLifecycleProtocol { MacApplicationLifecycleService.shared }
    #endif
}
