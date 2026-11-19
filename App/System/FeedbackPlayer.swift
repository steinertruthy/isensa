import AppKit
import iSensaFeatures

/// Turns feedback events into subtle system sounds and trackpad haptics, honouring the
/// user's preferences and macOS' own "Play user interface sound effects" setting.
@MainActor
final class FeedbackPlayer {
    private let settings: AppSettings
    private var sounds: [String: NSSound] = [:]

    init(settings: AppSettings) {
        self.settings = settings
    }

    var feedback: Feedback {
        Feedback { [weak self] event in self?.perform(event) }
    }

    func perform(_ event: FeedbackEvent) {
        if settings.hapticsEnabled {
            NSHapticFeedbackManager.defaultPerformer.perform(Self.haptic(for: event), performanceTime: .now)
        }
        guard settings.soundsEnabled, Self.systemInterfaceSoundsEnabled, let name = Self.soundName(for: event) else { return }
        let sound = sounds[name] ?? NSSound(named: NSSound.Name(name))
        sounds[name] = sound
        sound?.stop()
        sound?.volume = Float(settings.soundVolume)
        sound?.play()
    }

    /// Built-in macOS sounds, chosen for being short and soft. Selection is haptic only.
    static func soundName(for event: FeedbackEvent) -> String? {
        switch event {
        case .selection: nil
        case .confirm: "Pop"
        case .success: "Glass"
        case .warning: "Purr"
        }
    }

    private static func haptic(for event: FeedbackEvent) -> NSHapticFeedbackManager.FeedbackPattern {
        switch event {
        case .selection: .alignment
        case .confirm, .success: .levelChange
        case .warning: .generic
        }
    }

    /// System Settings › Sound › "Play user interface sound effects" (on when never set).
    static var systemInterfaceSoundsEnabled: Bool {
        let value = CFPreferencesCopyAppValue("com.apple.sound.uiaudio.enabled" as CFString, "com.apple.systemsound" as CFString)
        return (value as? NSNumber)?.boolValue ?? true
    }
}
