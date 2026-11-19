import Foundation
import SensaCore

/// Demo mode: a made-up home folder and apps, clearly named "Demo". Nothing on disk is read or moved.
public enum DemoSpace {
    public static let home = URL(fileURLWithPath: "/Users/demo")
    public static let applications = URL(fileURLWithPath: "/Applications")

    static func file(_ path: String, _ size: UInt64, daysAgo: Double = 3) -> DiskUsageItem {
        let url = URL(fileURLWithPath: path)
        return DiskUsageItem(url: url, name: url.lastPathComponent, kind: path.hasSuffix(".app") ? .package : .file, size: size,
                             modified: Date().addingTimeInterval(-daysAgo * 86_400))
    }

    static func folder(_ path: String, _ children: [DiskUsageItem], readable: Bool = true) -> DiskUsageItem {
        let url = URL(fileURLWithPath: path)
        return DiskUsageItem(url: url, name: url.lastPathComponent, kind: .folder, size: children.reduce(0) { $0 + $1.size },
                             children: children.sorted { $0.size > $1.size }, isReadable: readable)
    }

    static var report: DiskUsageReport {
        let installer = file("/Users/demo/Downloads/Demo Installer.dmg", 1_200_000_000)
        let oldVideo = file("/Users/demo/Downloads/Demo Talk.mov", 4_800_000_000, daysAgo: 200)
        let derived = folder("/Users/demo/Library/Developer/Xcode/DerivedData", [
            file("/Users/demo/Library/Developer/Xcode/DerivedData/Demo-abc", 8_000_000_000)
        ])
        let browserCache = folder("/Users/demo/Library/Caches/com.demo.browser", [file("/Users/demo/Library/Caches/com.demo.browser/Cache.db", 1_500_000_000)])
        let home = folder("/Users/demo", [
            folder("/Users/demo/Downloads", [installer, oldVideo, file("/Users/demo/Downloads/Demo Notes.pdf", 40_000_000)]),
            folder("/Users/demo/Documents", [file("/Users/demo/Documents/Demo Project.zip", 30_000_000_000)]),
            folder("/Users/demo/Movies", [file("/Users/demo/Movies/Demo Holiday.mov", 20_000_000_000)]),
            folder("/Users/demo/Library", [
                folder("/Users/demo/Library/Developer", [folder("/Users/demo/Library/Developer/Xcode", [derived])]),
                folder("/Users/demo/Library/Caches", [browserCache]),
                folder("/Users/demo/Library/Mail", [], readable: false)
            ])
        ])
        let apps = folder("/Applications", [
            file("/Applications/Demo Game.app", 15_000_000_000), file("/Applications/Demo Editor.app", 2_000_000_000)
        ])
        return DiskUsageReport(
            date: Date(), roots: [home, apps],
            largestFiles: [file("/Users/demo/Documents/Demo Project.zip", 30_000_000_000), file("/Users/demo/Movies/Demo Holiday.mov", 20_000_000_000),
                           oldVideo, installer],
            installers: [installer], staleDownloads: [oldVideo], unreadable: [URL(fileURLWithPath: "/Users/demo/Library/Mail")],
            itemCount: 182_340, duration: 1
        )
    }
}

public struct DemoDiskUsageScanner: DiskUsageScanning {
    public init() {}

    public func scan(roots: [URL], progress: @escaping @Sendable (DiskScanProgress) -> Void) async throws -> DiskUsageReport {
        for step in 1...5 {
            try await Task.sleep(for: .milliseconds(120))
            progress(DiskScanProgress(itemCount: step * 36_000, currentFolder: "/Users/demo/Library"))
        }
        return DemoSpace.report
    }
}

public struct DemoAppInventory: AppInventoryReading {
    public init() {}

    public func apps(in folders: [URL]) async -> [InstalledApp] {
        [
            InstalledApp(url: URL(fileURLWithPath: "/Applications/Demo Game.app"), name: "Demo Game", bundleIdentifier: "com.demo.game",
                         version: "1.0", size: 15_000_000_000, lastOpened: Date().addingTimeInterval(-300 * 86_400)),
            InstalledApp(url: URL(fileURLWithPath: "/Applications/Demo Editor.app"), name: "Demo Editor", bundleIdentifier: "com.demo.editor",
                         version: "2.1", size: 2_000_000_000, lastOpened: Date().addingTimeInterval(-86_400))
        ]
    }

    public func leftovers(of app: InstalledApp) async -> [AppLeftover] {
        guard let id = app.bundleIdentifier else { return [] }
        return [AppLeftover(url: URL(fileURLWithPath: "/Users/demo/Library/Application Support/\(id)"), size: 640_000_000)]
    }
}

/// Demo "Trash": pretends to move items and to put them back.
public struct DemoTrash: FileTrashing {
    public init() {}

    public func moveToTrash(_ url: URL) async throws -> URL { url }
    public func putBack(_ trashed: URL, to original: URL) async throws {}
}
