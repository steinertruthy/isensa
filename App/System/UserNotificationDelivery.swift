import AppKit
import iSensaFeatures
import UserNotifications

/// Delivers alerts through Notification Center. Banners also appear while iSensa is in front.
@MainActor
final class UserNotificationDelivery: NSObject, NotificationDelivering, UNUserNotificationCenterDelegate {
    private nonisolated static let linkKey = "link"
    private let center = UNUserNotificationCenter.current()

    override init() {
        super.init()
        center.delegate = self
    }

    func authorization() async -> NotificationAuthorization {
        switch await center.notificationSettings().authorizationStatus {
        case .authorized, .provisional, .ephemeral: .authorized
        case .denied: .denied
        case .notDetermined: .notDetermined
        @unknown default: .notDetermined
        }
    }

    func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
    }

    func deliver(title: String, body: String, identifier: String, link: URL?) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        if let link { content.userInfo = [Self.linkKey: link.absoluteString] }
        // Reusing the kind as identifier replaces an older banner of the same alert instead of stacking.
        center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: nil))
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter, willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    /// Clicking a notification that carries a link (a new version) opens it in the browser.
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        guard response.actionIdentifier == UNNotificationDefaultActionIdentifier,
              let text = response.notification.request.content.userInfo[Self.linkKey] as? String,
              let url = URL(string: text), url.scheme == "https" else { return }
        await MainActor.run { _ = NSWorkspace.shared.open(url) }
    }
}
