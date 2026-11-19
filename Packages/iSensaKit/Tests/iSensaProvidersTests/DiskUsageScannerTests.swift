import Foundation
import iSensaCore
@testable import iSensaProviders
import Testing

@Suite("Disk usage scanner")
struct DiskUsageScannerTests {
    /// A small home folder on disk, removed after the test.
    private final class Sandbox {
        let home: URL

        init() throws {
            home = FileManager.default.temporaryDirectory.appendingPathComponent("isensa-space-\(UUID().uuidString)")
            try FileManager.default.createDirectory(at: home, withIntermediateDirectories: true)
        }

        deinit { try? FileManager.default.removeItem(at: home) }

        @discardableResult
        func file(_ path: String, bytes: Int, modified: Date? = nil) throws -> URL {
            let url = home.appendingPathComponent(path)
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try Data(count: bytes).write(to: url)
            if let modified { try FileManager.default.setAttributes([.modificationDate: modified], ofItemAtPath: url.path) }
            return url
        }
    }

    @Test func measuresFoldersPackagesAndFindings() async throws {
        let box = try Sandbox()
        let now = Date()
        try box.file("Downloads/Old.dmg", bytes: 3_000_000)
        try box.file("Downloads/Talk.mov", bytes: 120_000_000, modified: now.addingTimeInterval(-200 * 86_400))
        try box.file("Documents/Report.pdf", bytes: 2_000_000)
        try box.file("Applications/Tool.app/Contents/MacOS/Tool", bytes: 5_000_000)
        try box.file("Library/Mobile Documents/com~apple~CloudDocs/Cloud.bin", bytes: 4_000_000)
        let documents = box.home.appendingPathComponent("Documents")
        try FileManager.default.createSymbolicLink(at: box.home.appendingPathComponent("Link"), withDestinationURL: documents)

        let scanner = DiskUsageScanner(home: box.home, minimumListedSize: 1_000_000, now: { now })
        let report = try await scanner.scan(roots: [box.home]) { _ in }
        let root = try #require(report.roots.first)
        let downloads = try #require(report.item(at: box.home.appendingPathComponent("Downloads")))
        #expect(downloads.size >= 123_000_000)
        #expect(root.size >= downloads.size + 7_000_000)
        #expect(root.size < downloads.size + 12_000_000, "Cloud storage and the symbolic link are not counted")
        let app = try #require(report.item(at: box.home.appendingPathComponent("Applications/Tool.app")))
        #expect(app.kind == .package && app.children.isEmpty)
        #expect(report.installers.map(\.name) == ["Old.dmg"])
        #expect(report.staleDownloads.map(\.name) == ["Talk.mov"])
        #expect(report.largestFiles.first?.name == "Talk.mov")
        #expect(!report.largestFiles.contains { $0.name == "Tool" }, "Files inside an app are not listed on their own")
        #expect(report.skipped.map(\.lastPathComponent) == ["Mobile Documents"])
        #expect(report.itemCount >= 4)
    }

    @Test func foldsSmallItems() {
        let scanner = DiskUsageScanner(minimumListedSize: 10, childLimit: 2)
        let children = [5, 50, 40, 30].map { size in
            DiskUsageItem(url: URL(fileURLWithPath: "/x/\(size)"), name: "\(size)", kind: .file, size: UInt64(size))
        }
        let folder = scanner.fold(DiskUsageItem(url: URL(fileURLWithPath: "/x"), name: "x", kind: .folder, size: 0), children: children)
        #expect(folder.size == 125)
        #expect(folder.children.map(\.size) == [50, 40])
        #expect(folder.foldedCount == 2 && folder.foldedSize == 35)
    }

    @Test func leftoverCandidatesUseTheExactBundleIdentifier() {
        let library = URL(fileURLWithPath: "/Users/me/Library")
        let paths = InstalledApps.candidates(bundleIdentifier: "com.example.Tool", name: "Tool", library: library).map(\.path)
        #expect(paths.contains("/Users/me/Library/Caches/com.example.Tool"))
        #expect(paths.contains("/Users/me/Library/Preferences/com.example.Tool.plist"))
        #expect(paths.contains("/Users/me/Library/Application Support/Tool"))
        #expect(InstalledApps.candidates(bundleIdentifier: "com.apple.Pages", name: "Pages", library: library).isEmpty)
        #expect(InstalledApps.candidates(bundleIdentifier: "com.example.X", name: "X", library: library).allSatisfy { !$0.path.hasSuffix("/X") })
    }

    @Test func lastActivityComesFromSettingsAndWindowState() throws {
        let box = try Sandbox()
        let old = Date(timeIntervalSince1970: 1_700_000_000), recent = Date(timeIntervalSince1970: 1_750_000_000)
        try box.file("Library/Preferences/com.example.Tool.plist", bytes: 10, modified: old)
        try box.file("Library/Saved Application State/com.example.Tool.savedState/data", bytes: 10)
        let state = box.home.appendingPathComponent("Library/Saved Application State/com.example.Tool.savedState")
        try FileManager.default.setAttributes([.modificationDate: recent], ofItemAtPath: state.path)
        let library = box.home.appendingPathComponent("Library")
        #expect(InstalledApps.lastActivity(bundleIdentifier: "com.example.Tool", library: library) == recent)
        #expect(InstalledApps.lastActivity(bundleIdentifier: "com.example.None", library: library) == nil)
    }

    // Apps someone has used: CI runners have no Spotlight history and some unreadable bundles.
    @Test(.tags(.hardware), .enabled(if: ProcessInfo.processInfo.environment["CI"] == nil)) func readsInstalledAppsOfThisMac() async {
        let apps = await InstalledApps().apps(in: [URL(fileURLWithPath: "/Applications")])
        #expect(!apps.isEmpty)
        #expect(apps.allSatisfy { $0.size > 0 })
        #expect(apps.contains { $0.lastOpened != nil }, "Spotlight records when apps are opened")
    }

    @Test(.tags(.hardware)) func trashAndPutBack() async throws {
        let box = try Sandbox()
        let file = try box.file("Remove me.txt", bytes: 10)
        let remover = TrashRemover()
        let trashed = try await remover.moveToTrash(file)
        #expect(!FileManager.default.fileExists(atPath: file.path))
        try await remover.putBack(trashed, to: file)
        #expect(FileManager.default.fileExists(atPath: file.path))
    }
}
