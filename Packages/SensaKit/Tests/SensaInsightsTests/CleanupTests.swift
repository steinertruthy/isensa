import Foundation
import SensaCore
import SensaInsights
import Testing

@Suite("Cleanup suggestions")
struct CleanupTests {
    private let home = URL(fileURLWithPath: "/Users/me")

    private func item(_ path: String, _ size: UInt64, _ children: [DiskUsageItem] = [], readable: Bool = true) -> DiskUsageItem {
        let url = URL(fileURLWithPath: "/Users/me/" + path)
        return DiskUsageItem(url: url, name: url.lastPathComponent, kind: children.isEmpty ? .file : .folder,
                             size: children.isEmpty ? size : children.reduce(0) { $0 + $1.size }, children: children, isReadable: readable)
    }

    private var report: DiskUsageReport {
        let library = item("Library", 0, [
            item("Library/Developer", 0, [
                item("Library/Developer/Xcode", 0, [item("Library/Developer/Xcode/DerivedData", 6_000_000_000)]),
                item("Library/Developer/CoreSimulator", 20_000_000_000)
            ]),
            item("Library/Caches", 0, [item("Library/Caches/com.big", 900_000_000), item("Library/Caches/com.small", 10_000_000)])
        ])
        let installer = item("Downloads/App.dmg", 400_000_000)
        let home = DiskUsageItem(url: home, name: "me", kind: .folder, size: library.size + installer.size, children: [
            library, item("Downloads", 0, [installer])
        ])
        return DiskUsageReport(date: Date(), roots: [home], installers: [installer])
    }

    @Test func suggestsSafeCleanupsAndPointsElsewhereForManagedData() {
        let now = Date()
        let apps = [
            InstalledApp(url: URL(fileURLWithPath: "/Applications/Old.app"), name: "Old", bundleIdentifier: "com.example.old", version: nil,
                         size: 3_000_000_000, lastOpened: now.addingTimeInterval(-400 * 86_400)),
            InstalledApp(url: URL(fileURLWithPath: "/Applications/Pages.app"), name: "Pages", bundleIdentifier: "com.apple.iWork.Pages", version: nil,
                         size: 1_000_000_000, lastOpened: now.addingTimeInterval(-400 * 86_400)),
            InstalledApp(url: URL(fileURLWithPath: "/Applications/New.app"), name: "New", bundleIdentifier: "com.example.new", version: nil,
                         size: 3_000_000_000, lastOpened: nil)
        ]
        let suggestions = CleanupSuggestions.make(report: report, apps: apps, home: home, now: now)
        #expect(suggestions.map(\.kind) == [.simulators, .derivedData, .unusedApps, .largeCaches, .installers], "Largest first")
        #expect(suggestions.first { $0.kind == .unusedApps }?.action == .uninstall([apps[0]]), "Apple's apps and unknown dates are left alone")
        guard case let .moveToTrash(caches)? = suggestions.first(where: { $0.kind == .largeCaches })?.action else {
            Issue.record("Large caches")
            return
        }
        #expect(caches.map(\.name) == ["com.big"])
        #expect(suggestions.first { $0.kind == .simulators }?.action == .elsewhere(home.appendingPathComponent("Library/Developer/CoreSimulator")))
    }

    @Test func categoriesAddUpWithoutCountingTwice() {
        let categories = SpaceCategory.make(report: report, home: home, applicationFolders: [URL(fileURLWithPath: "/Applications")])
        let sizes = Dictionary(uniqueKeysWithValues: categories.map { ($0.kind, $0.size) })
        #expect(sizes[.developer] == 26_000_000_000)
        #expect(sizes[.caches] == 910_000_000)
        #expect(sizes[.downloads] == 400_000_000)
        #expect(sizes[.apps] == nil, "No Applications folder in this report")
        #expect(categories.reduce(0) { $0 + $1.size } == report.totalSize)
    }
}
