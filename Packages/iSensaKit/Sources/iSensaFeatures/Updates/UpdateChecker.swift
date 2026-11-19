import Foundation
import Observation

/// Looks for a newer iSensa on GitHub: shortly after launch and then once a day, while the user allows it.
/// A new version is announced once with a notification; Settings › About iSensa and the menu bar keep showing it.
/// The request carries no information about the Mac or the user; only the version numbers are compared.
@MainActor
@Observable
public final class UpdateChecker {
    public enum Status: Equatable {
        case idle
        case checking
        case upToDate(Date)
        case available(AvailableUpdate)
        case failed
    }

    public private(set) var status: Status = .idle
    public let currentVersion: AppVersion?

    public var availableUpdate: AvailableUpdate? {
        if case .available(let update) = status { update } else { nil }
    }

    /// When the last check finished, successful or not.
    public var lastCheck: Date? { defaults.object(forKey: Self.lastCheckKey) as? Date }

    @ObservationIgnored private let settings: AppSettings
    @ObservationIgnored private let delivery: NotificationDelivering?
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let fetch: @Sendable () async throws -> Data
    @ObservationIgnored private let now: () -> Date
    @ObservationIgnored private var loop: Task<Void, Never>?

    static let lastCheckKey = "updates.lastCheck"
    static let announcedKey = "updates.announcedVersion"
    public static let notificationIdentifier = "isensa.update"
    static let interval: TimeInterval = 86_400

    public init(
        currentVersion: String, settings: AppSettings, delivery: NotificationDelivering?, defaults: UserDefaults = .standard,
        now: @escaping () -> Date = Date.init, fetch: @escaping @Sendable () async throws -> Data
    ) {
        self.currentVersion = AppVersion(currentVersion)
        self.settings = settings
        self.delivery = delivery
        self.defaults = defaults
        self.now = now
        self.fetch = fetch
    }

    /// First check a little after launch, so it never competes with startup; then once a day.
    public func start(firstDelay: Duration = .seconds(20)) {
        loop?.cancel()
        loop = Task { [weak self] in
            try? await Task.sleep(for: firstDelay)
            var checkedThisLaunch = false
            while !Task.isCancelled {
                guard let self else { return }
                if settings.checksForUpdates && (!checkedThisLaunch || isDue) {
                    await check()
                    checkedThisLaunch = true
                }
                try? await Task.sleep(for: .seconds(3_600))
            }
        }
    }

    public func stop() {
        loop?.cancel()
        loop = nil
    }

    var isDue: Bool {
        guard let lastCheck else { return true }
        return now().timeIntervalSince(lastCheck) >= Self.interval
    }

    /// Checks right away. Also used by "Check for Updates…".
    public func check() async {
        guard let currentVersion, status != .checking else { return }
        status = .checking
        defer { defaults.set(now(), forKey: Self.lastCheckKey) }
        do {
            let data = try await fetch()
            if let update = try ReleaseFeed.newestUpdate(in: data, newerThan: currentVersion) {
                status = .available(update)
                await announce(update)
            } else {
                status = .upToDate(now())
            }
        } catch {
            status = .failed
        }
    }

    /// One notification per version, however many times the check finds it.
    private func announce(_ update: AvailableUpdate) async {
        let version = update.version.description
        guard defaults.string(forKey: Self.announcedKey) != version, let delivery else { return }
        defaults.set(version, forKey: Self.announcedKey)
        if await delivery.authorization() == .notDetermined {
            _ = await delivery.requestAuthorization()
        }
        delivery.deliver(
            title: tr("iSensa %@ is available", version),
            body: tr("Click to download it from GitHub. You are using version %@.", self.currentVersion?.description ?? "–"),
            identifier: Self.notificationIdentifier, link: update.pageURL
        )
    }
}
