import Foundation
@testable import iSensaFeatures
import Testing

@Suite("App version")
struct AppVersionTests {
    private func version(_ text: String) -> AppVersion { AppVersion(text)! }

    @Test func readsTagsWithOrWithoutPrefix() {
        #expect(version("v1.2.3") == version("1.2.3"))
        #expect(version("1.2") == version("1.2.0"))
        #expect(version("1.0.0+build.7") == version("1.0.0"))
        #expect(version("0.2.0-beta.1").description == "0.2.0-beta.1")
    }

    @Test func rejectsWhatIsNotAVersion() {
        #expect(AppVersion("latest") == nil)
        #expect(AppVersion("1..2") == nil)
        #expect(AppVersion("1.0-") == nil)
        #expect(AppVersion("") == nil)
    }

    @Test func ordersLikeSemanticVersioning() {
        let ordered = [
            "0.1.0", "0.1.1", "0.2.0-alpha", "0.2.0-alpha.1", "0.2.0-beta", "0.2.0-beta.2", "0.2.0-beta.11", "0.2.0-rc.1", "0.2.0", "1.0.0", "1.10.0"
        ]
        for (lower, higher) in zip(ordered, ordered.dropFirst()) {
            #expect(version(lower) < version(higher), "\(lower) < \(higher)")
            #expect(!(version(higher) < version(lower)))
        }
    }
}

@Suite("Release feed")
struct ReleaseFeedTests {
    private func feed(_ releases: [[String: Any]]) throws -> Data {
        try JSONSerialization.data(withJSONObject: releases)
    }

    private func release(_ tag: String, draft: Bool = false, prerelease: Bool = false, assets: [String] = ["iSensa-\(UUID()).dmg"]) -> [String: Any] {
        [
            "tag_name": tag, "name": "iSensa \(tag)", "html_url": "https://github.com/steinertruthy/isensa/releases/tag/\(tag)",
            "draft": draft, "prerelease": prerelease, "published_at": "2026-11-19T12:00:00Z",
            "assets": assets.map { ["name": $0] }
        ]
    }

    @Test func offersTheNewestPublishedVersion() throws {
        let data = try feed([release("v0.2.0"), release("v0.3.0", prerelease: true), release("v0.1.0")])
        let update = try ReleaseFeed.newestUpdate(in: data, newerThan: AppVersion("0.1.0")!)
        #expect(update?.version == AppVersion("0.3.0"))
        #expect(update?.isPrerelease == true)
        #expect(update?.pageURL.absoluteString.hasSuffix("/v0.3.0") == true)
    }

    @Test func ignoresDraftsReleasesWithoutAnInstallerAndOlderVersions() throws {
        let data = try feed([
            release("v0.9.0", draft: true), release("v0.8.0", assets: ["notes.txt"]), release("nightly"), release("v0.1.0")
        ])
        #expect(try ReleaseFeed.newestUpdate(in: data, newerThan: AppVersion("0.1.0")!) == nil)
    }

    @Test func failsOnSomethingThatIsNotAReleaseList() {
        #expect(throws: (any Error).self) { try ReleaseFeed.newestUpdate(in: Data("{\"message\":\"rate limited\"}".utf8), newerThan: AppVersion("1")!) }
    }
}

@MainActor
private final class UpdateDelivery: NotificationDelivering {
    var authorizationState = NotificationAuthorization.notDetermined
    var requests = 0
    var delivered: [(title: String, link: URL?)] = []
    func authorization() async -> NotificationAuthorization { authorizationState }
    func requestAuthorization() async -> Bool {
        requests += 1
        authorizationState = .authorized
        return true
    }
    func deliver(title: String, body: String, identifier: String, link: URL?) { delivered.append((title, link)) }
}

@MainActor
@Suite("Update checker")
struct UpdateCheckerTests {
    private func defaults() -> UserDefaults { UserDefaults(suiteName: "isensa.tests.\(UUID().uuidString)")! }

    private nonisolated static let feed = Data("""
    [{"tag_name":"v0.2.0","name":"iSensa 0.2.0","html_url":"https://github.com/steinertruthy/isensa/releases/tag/v0.2.0",
      "draft":false,"prerelease":false,"published_at":"2026-11-19T12:00:00Z","assets":[{"name":"iSensa-0.2.0.dmg"}]}]
    """.utf8)

    @Test func announcesANewVersionOnce() async {
        let store = defaults()
        let delivery = UpdateDelivery()
        let checker = UpdateChecker(currentVersion: "0.1.0", settings: AppSettings(defaults: store), delivery: delivery, defaults: store) { Self.feed }
        await checker.check()
        await checker.check()
        #expect(checker.availableUpdate?.version == AppVersion("0.2.0"))
        #expect(delivery.delivered.count == 1)
        #expect(delivery.delivered.first?.link?.absoluteString == "https://github.com/steinertruthy/isensa/releases/tag/v0.2.0")
        #expect(delivery.requests == 1)
        #expect(checker.lastCheck != nil)
    }

    @Test func reportsUpToDateAndFailures() async {
        let store = defaults()
        let current = UpdateChecker(currentVersion: "0.2.0", settings: AppSettings(defaults: store), delivery: nil, defaults: store) { Self.feed }
        await current.check()
        #expect({ if case .upToDate = current.status { true } else { false } }())

        let offline = UpdateChecker(currentVersion: "0.1.0", settings: AppSettings(defaults: store), delivery: nil, defaults: store) {
            throw URLError(.notConnectedToInternet)
        }
        await offline.check()
        #expect(offline.status == .failed)
    }

    @Test func checksAgainOnlyAfterADay() async {
        let store = defaults()
        var clock = Date(timeIntervalSince1970: 1_000_000)
        let checker = UpdateChecker(
            currentVersion: "0.2.0", settings: AppSettings(defaults: store), delivery: nil, defaults: store, now: { clock }
        ) { Self.feed }
        #expect(checker.isDue)
        await checker.check()
        #expect(!checker.isDue)
        clock += 86_400
        #expect(checker.isDue)
    }
}
