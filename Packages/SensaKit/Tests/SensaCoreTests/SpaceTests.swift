import Foundation
import SensaCore
import Testing

@Suite("Space analysis model")
struct DiskUsageModelTests {
    private func item(_ path: String, _ size: UInt64, _ children: [DiskUsageItem] = []) -> DiskUsageItem {
        let url = URL(fileURLWithPath: path)
        return DiskUsageItem(url: url, name: url.lastPathComponent, kind: children.isEmpty ? .file : .folder, size: size, children: children)
    }

    private var tree: DiskUsageItem {
        item("/Users/me", 100, [
            item("/Users/me/Downloads", 70, [item("/Users/me/Downloads/a.dmg", 50), item("/Users/me/Downloads/b.zip", 20)]),
            item("/Users/me/Documents", 30)
        ])
    }

    @Test func findsItemsByPath() {
        #expect(tree.item(at: URL(fileURLWithPath: "/Users/me/Downloads/b.zip"))?.size == 20)
        #expect(tree.item(at: URL(fileURLWithPath: "/Users/me/Downloads/missing")) == nil)
        #expect(tree.item(at: URL(fileURLWithPath: "/Users/meh")) == nil, "A sibling with a common prefix is not inside")
    }

    @Test func removingShrinksEveryEnclosingFolder() {
        let report = DiskUsageReport(date: Date(), roots: [tree], largestFiles: [item("/Users/me/Downloads/a.dmg", 50)],
                                     installers: [item("/Users/me/Downloads/a.dmg", 50)])
        let after = report.removing([URL(fileURLWithPath: "/Users/me/Downloads/a.dmg")])
        #expect(after.totalSize == 50)
        #expect(after.item(at: URL(fileURLWithPath: "/Users/me/Downloads"))?.size == 20)
        #expect(after.item(at: URL(fileURLWithPath: "/Users/me/Downloads/a.dmg")) == nil)
        #expect(after.largestFiles.isEmpty && after.installers.isEmpty)
        let folderGone = report.removing([URL(fileURLWithPath: "/Users/me/Downloads")])
        #expect(folderGone.totalSize == 30)
        #expect(folderGone.installers.isEmpty, "Items inside a removed folder leave the lists too")
    }
}

@Suite("Removal policy")
struct RemovalPolicyTests {
    private let policy = RemovalPolicy(
        home: URL(fileURLWithPath: "/Users/me"),
        applicationFolders: [URL(fileURLWithPath: "/Applications"), URL(fileURLWithPath: "/Users/me/Applications")],
        ownBundle: URL(fileURLWithPath: "/Applications/Sensa.app"),
        runningApps: ["com.example.Open": "Open App", "Open App": "Open App"]
    )

    private func refusal(_ path: String, id: String? = nil) -> RemovalPolicy.Refusal? {
        policy.refusal(for: URL(fileURLWithPath: path), bundleIdentifier: id)
    }

    @Test func allowsOrdinaryFilesAndApps() {
        #expect(refusal("/Users/me/Downloads/Installer.dmg") == nil)
        #expect(refusal("/Users/me/Library/Developer/Xcode/DerivedData") == nil)
        #expect(refusal("/Users/me/Library/Caches/com.example.Closed") == nil)
        #expect(refusal("/Users/me/Library/Preferences/com.example.Closed.plist") == nil)
        #expect(refusal("/Applications/Game.app", id: "com.example.Game") == nil)
        #expect(refusal("/Users/me/Applications/Tool.app", id: "com.example.Tool") == nil)
    }

    @Test func refusesWhatMacOSAndThePersonRelyOn() {
        #expect(refusal("/System/Library/Fonts") == .outsideHomeAndApplications)
        #expect(refusal("/Users/other/file") == .outsideHomeAndApplications)
        #expect(refusal("/Users/me") == .outsideHomeAndApplications)
        #expect(refusal("/Users/me/Documents") == .essentialFolder)
        #expect(refusal("/Users/me/Library") == .essentialFolder)
        #expect(refusal("/Users/me/Library/Caches") == .essentialFolder)
        #expect(refusal("/Applications") == .outsideHomeAndApplications)
        #expect(refusal("/Users/me/.ssh") == .configuration)
        #expect(refusal("/Users/me/.zshrc") == .configuration)
        #expect(refusal("/Users/me/Library/Keychains/login.keychain-db") == .managedByAnotherApp)
        #expect(refusal("/Users/me/Library/Mail/V10") == .managedByAnotherApp)
        #expect(refusal("/Users/me/Pictures/Photos Library.photoslibrary") == .managedByAnotherApp)
        #expect(refusal("/Applications/Game.app/Contents/Resources/big.pak") == .insideAnApp)
        #expect(refusal("/Applications/Safari.app", id: "com.apple.Safari") == .systemApp)
        #expect(refusal("/Applications/Sensa.app", id: "app.sensa.Sensa") == .sensa)
    }

    @Test func refusesOpenAppsAndTheirFiles() {
        #expect(refusal("/Applications/Open App.app", id: "com.example.Open") == .open("Open App"))
        #expect(refusal("/Users/me/Library/Caches/com.example.Open") == .open("Open App"))
        #expect(refusal("/Users/me/Library/Preferences/com.example.Open.plist") == .open("Open App"))
        #expect(refusal("/Users/me/Library/Application Support/Open App") == .open("Open App"))
    }
}
