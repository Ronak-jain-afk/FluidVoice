import Foundation

// ponytail: DI container — supplies the active platform implementations.
// macOS → Mac* services, Windows → Win* services.
// Callers resolve dependencies here instead of importing Apple frameworks directly.
enum PlatformProvider {
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
}
