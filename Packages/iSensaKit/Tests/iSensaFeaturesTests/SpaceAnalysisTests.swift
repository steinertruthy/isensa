import Foundation
import iSensaCore
import iSensaDemo
@testable import iSensaFeatures
import Testing

@MainActor
@Suite("Space analysis flow")
struct SpaceAnalysisTests {
    private func analysis() -> SpaceAnalysis {
        SpaceAnalysis(dependencies: .init(
            scanner: DemoDiskUsageScanner(), inventory: { _ in DemoAppInventory() }, trash: DemoTrash(),
            home: DemoSpace.home, applicationFolders: [DemoSpace.applications], ownBundle: URL(fileURLWithPath: "/Applications/iSensa.app")
        ))
    }

    private func finish(_ analysis: SpaceAnalysis) async throws {
        analysis.start()
        for _ in 0..<100 where analysis.phase != .finished { try await Task.sleep(for: .milliseconds(20)) }
        #expect(analysis.phase == .finished)
    }

    @Test func analyzesThenMovesToTrashAndUndoes() async throws {
        let analysis = analysis()
        try await finish(analysis)
        #expect(analysis.apps.count == 2)
        #expect(analysis.suggestions.contains { $0.kind == .installers })
        #expect(analysis.suggestions.contains { $0.kind == .unusedApps }, "Demo Game was last opened 300 days ago")
        let before = try #require(analysis.report?.totalSize)
        let installer = URL(fileURLWithPath: "/Users/demo/Downloads/Demo Installer.dmg")
        let removal = await analysis.moveToTrash([RemovalTarget(url: installer, name: "Demo Installer.dmg", size: 1_200_000_000)])
        #expect(removal.freed == 1_200_000_000 && removal.failed.isEmpty)
        #expect(analysis.report?.totalSize == before - 1_200_000_000)
        #expect(!analysis.suggestions.contains { $0.kind == .installers })
        #expect(await analysis.undo().isEmpty)
        #expect(analysis.isOutdated && analysis.lastRemoval == nil)
    }

    @Test func refusesAgainBeforeMoving() async throws {
        let analysis = analysis()
        try await finish(analysis)
        let removal = await analysis.moveToTrash([
            RemovalTarget(url: URL(fileURLWithPath: "/Users/demo/Documents"), name: "Documents", size: 1),
            RemovalTarget(url: URL(fileURLWithPath: "/etc/hosts"), name: "hosts", size: 1)
        ])
        #expect(removal.moved.isEmpty)
        #expect(removal.failed.map(\.name) == ["Documents", "hosts"])
    }
}
