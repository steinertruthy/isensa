import Foundation
import Testing
@testable import iSensaFeatures

@Suite("Migration from the Sensa name")
struct LegacyMigrationTests {
    @Test func carriesOverPreferencesAndDataFolderOnce() throws {
        let suite = "isensa.tests.\(UUID().uuidString)"
        let legacy = "isensa.tests.legacy.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defaults.setPersistentDomain(["fanMode": "balanced", "NSWindow Frame SensaMainWindow": "0 0 800 600", "kept": 1], forName: legacy)
        defaults.set(2, forKey: "kept")
        let support = FileManager.default.temporaryDirectory.appendingPathComponent("isensa-migration-\(UUID().uuidString)")
        let old = support.appendingPathComponent("Sensa")
        try FileManager.default.createDirectory(at: old, withIntermediateDirectories: true)
        try Data("history".utf8).write(to: old.appendingPathComponent("history.sqlite"))
        defer {
            try? FileManager.default.removeItem(at: support)
            defaults.removePersistentDomain(forName: suite)
            defaults.removePersistentDomain(forName: legacy)
        }

        LegacyMigration.run(defaults: defaults, legacyDomain: legacy, applicationSupport: support)

        #expect(defaults.string(forKey: "fanMode") == "balanced")
        #expect(defaults.string(forKey: "NSWindow Frame iSensaMainWindow") == "0 0 800 600")
        #expect(defaults.integer(forKey: "kept") == 2, "A value already set under the new name wins")
        let copied = support.appendingPathComponent("iSensa/history.sqlite")
        #expect(FileManager.default.fileExists(atPath: copied.path))
        #expect(FileManager.default.fileExists(atPath: old.appendingPathComponent("history.sqlite").path), "The old folder is kept")

        defaults.set("quiet", forKey: "fanMode")
        LegacyMigration.run(defaults: defaults, legacyDomain: legacy, applicationSupport: support)
        #expect(defaults.string(forKey: "fanMode") == "quiet", "It runs only once")
    }
}
