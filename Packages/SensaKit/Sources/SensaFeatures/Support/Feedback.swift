import SensaCore
import SensaDesign
import SensaMonitoring
import SwiftUI

/// Moments that may give sound or haptic feedback. Deliberately few: Sensa is quiet.
public enum FeedbackEvent: Sendable {
    /// A small state change, e.g. marking a favorite (haptic only).
    case selection
    /// An action completed, e.g. saving a name or resetting preferences.
    case confirm
    /// A longer task finished, e.g. exporting history.
    case success
    /// Something needs attention, e.g. an alert while Sensa is in front.
    case warning
}

/// Plays feedback for an event. The app layer decides how (sounds, haptics, preferences).
public struct Feedback: Sendable {
    public var perform: @MainActor @Sendable (FeedbackEvent) -> Void

    public init(perform: @escaping @MainActor @Sendable (FeedbackEvent) -> Void) {
        self.perform = perform
    }

    public static let silent = Feedback { _ in }
}

public extension EnvironmentValues {
    @Entry var feedback: Feedback = .silent
}

/// App-level services the interface talks to through protocols.
public struct SensaServices {
    public var history: (any HistoryReading)?
    public var alerts: AlertCoordinator?
    public var notifications: NotificationDelivering?
    public var launchAtLogin: LaunchAtLoginControlling?
    public var actions: AppActions

    public init(
        history: (any HistoryReading)? = nil, alerts: AlertCoordinator? = nil, notifications: NotificationDelivering? = nil,
        launchAtLogin: LaunchAtLoginControlling? = nil, actions: AppActions = AppActions()
    ) {
        self.history = history
        self.alerts = alerts
        self.notifications = notifications
        self.launchAtLogin = launchAtLogin
        self.actions = actions
    }
}

/// App-level actions views can trigger.
public struct AppActions {
    public var openMainWindow: @MainActor () -> Void
    public var openSettings: @MainActor () -> Void
    public var relaunch: @MainActor () -> Void
    public var showOnboarding: @MainActor () -> Void
    public var revealDataFolder: @MainActor () -> Void

    public init(
        openMainWindow: @escaping @MainActor () -> Void = {}, openSettings: @escaping @MainActor () -> Void = {},
        relaunch: @escaping @MainActor () -> Void = {},
        showOnboarding: @escaping @MainActor () -> Void = {}, revealDataFolder: @escaping @MainActor () -> Void = {}
    ) {
        self.openMainWindow = openMainWindow
        self.openSettings = openSettings
        self.relaunch = relaunch
        self.showOnboarding = showOnboarding
        self.revealDataFolder = revealDataFolder
    }
}

public extension EnvironmentValues {
    @Entry var services = SensaServices()
}

/// Injects everything Sensa's views need, at every root (window, popover, settings).
/// Reading `settings.motion` here makes motion changes apply to all open views at once.
private struct SensaEnvironment: ViewModifier {
    let store: MetricsStore
    let settings: AppSettings
    let feedback: Feedback
    let services: SensaServices

    func body(content: Content) -> some View {
        content
            .environment(store)
            .environment(settings)
            .environment(\.sensaMotion, settings.motion)
            .environment(\.feedback, feedback)
            .environment(\.services, services)
    }
}

public extension View {
    func sensaEnvironment(store: MetricsStore, settings: AppSettings, feedback: Feedback, services: SensaServices = SensaServices()) -> some View {
        modifier(SensaEnvironment(store: store, settings: settings, feedback: feedback, services: services))
    }
}
