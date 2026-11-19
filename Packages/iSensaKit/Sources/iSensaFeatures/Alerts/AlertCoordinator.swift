import Foundation
import iSensaCore
import iSensaInsights
import iSensaMonitoring

public enum NotificationAuthorization: Sendable {
    case notDetermined, denied, authorized
}

/// System notification delivery, implemented by the app layer (UserNotifications).
@MainActor
public protocol NotificationDelivering: AnyObject {
    func authorization() async -> NotificationAuthorization
    func requestAuthorization() async -> Bool
    /// `link` opens when the user clicks the notification.
    func deliver(title: String, body: String, identifier: String, link: URL?)
}

public extension NotificationDelivering {
    func deliver(title: String, body: String, identifier: String) {
        deliver(title: title, body: body, identifier: identifier, link: nil)
    }
}

/// Evaluates alert rules as data arrives, delivers notifications, records alerts in history
/// and gives in-app feedback. Evaluation is throttled; the engine itself enforces durations,
/// hysteresis and repeat intervals.
@MainActor
public final class AlertCoordinator {
    private let store: MetricsStore
    private let settings: AppSettings
    private let delivery: NotificationDelivering
    private let log: @MainActor (AlertEvent) -> Void
    private let feedback: Feedback
    private var engine = AlertEngine()
    private var lastEvaluation = Date.distantPast
    private let minimumInterval: TimeInterval

    public init(
        store: MetricsStore, settings: AppSettings, delivery: NotificationDelivering, feedback: Feedback,
        minimumInterval: TimeInterval = 2, log: @escaping @MainActor (AlertEvent) -> Void
    ) {
        self.store = store
        self.settings = settings
        self.delivery = delivery
        self.feedback = feedback
        self.minimumInterval = minimumInterval
        self.log = log
    }

    public func start() {
        store.addReadingObserver { [weak self] _ in self?.evaluateIfDue() }
    }

    /// Exposed for tests and for the "send a test" path.
    public func evaluate(now: Date = Date()) -> [AlertEvent] {
        lastEvaluation = now
        let events = engine.evaluate(store.snapshot, capabilities: store.capabilities, configuration: settings.alerts, now: now)
        let text = AlertText(formatter: settings.formatter)
        for event in events {
            delivery.deliver(title: text.title(event.kind), body: text.body(event.kind, value: event.value), identifier: event.kind.rawValue)
            log(event)
            if event.level != .normal { feedback.perform(.warning) }
        }
        return events
    }

    public func sendTestNotification() {
        delivery.deliver(
            title: tr("Notifications are on"),
            body: tr("iSensa will let you know when something needs your attention."),
            identifier: "test"
        )
        feedback.perform(.confirm)
    }

    private func evaluateIfDue() {
        let now = Date()
        guard settings.alerts.isEnabled, now.timeIntervalSince(lastEvaluation) >= minimumInterval else { return }
        _ = evaluate(now: now)
    }
}
