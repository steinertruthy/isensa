import Foundation
@testable import SensaHardware
import Testing

@Suite("Storage tools")
struct StorageToolsTests {
    private func plist(_ object: Any) throws -> Data {
        try PropertyListSerialization.data(fromPropertyList: object, format: .xml, options: 0)
    }

    @Test func parsesDiskInfoOfTheStartupDisk() throws {
        // Fields of `diskutil info -plist /` on Mac15,6, macOS 26.
        let data = try plist(["BusProtocol": "Apple Fabric", "APFSContainerReference": "disk3", "SolidState": true, "FileVault": true])
        let details = try #require(DiskUtility.parseDetails(data))
        #expect(details.busProtocol == "Apple Fabric")
        #expect(details.apfsContainer == "disk3")
        #expect(details.isSolidState == true)
    }

    @Test func parsesTheAPFSContainer() throws {
        let volume: (String, String, String, Int64, Bool) -> [String: Any] = { id, name, role, used, fileVault in
            ["DeviceIdentifier": id, "Name": name, "Roles": [role], "CapacityInUse": used, "FileVault": fileVault]
        }
        let data = try plist(["Containers": [[
            "ContainerReference": "disk3", "CapacityCeiling": Int64(494_384_795_648), "CapacityFree": Int64(14_615_810_048),
            "Volumes": [
                volume("disk3s1", "Macintosh HD", "System", 16_616_349_696, true),
                volume("disk3s5", "Macintosh HD - Data", "Data", 429_118_124_032, true),
                volume("disk3s6", "VM", "VM", 13_958_979_584, false)
            ]
        ]]])
        let container = try #require(DiskUtility.parseContainer(data, identifier: "disk3"))
        #expect(container.capacity == 494_384_795_648)
        #expect(container.free == 14_615_810_048)
        #expect(container.volumes.map(\.roles) == [["System"], ["Data"], ["VM"]])
        #expect(container.volumes[1].fileVault)
        #expect(DiskUtility.parseContainer(Data("not a plist".utf8), identifier: "disk3") == nil)
    }

    @Test func classifiesLocalSnapshots() throws {
        let output = """
        Snapshots for volume group containing disk /:
        com.apple.TimeMachine.2026-11-19-091500.local
        com.apple.TimeMachine.2026-11-19-101500.local
        com.apple.os.update-60587424F5399FC05D957DF05B4D2F65543462495C77AEF520F790FBB57CB212
        com.apple.os.update-MSUPrepareUpdate
        com.example.other
        """
        let summary = LocalSnapshots.parse(output)
        #expect(summary.timeMachine.count == 2)
        #expect(summary.systemUpdate == 2)
        #expect(summary.other == 1)
        let newest = try #require(summary.timeMachine.max())
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: newest)
        #expect(components.year == 2026 && components.day == 19 && components.hour == 10 && components.minute == 15)
        #expect(LocalSnapshots.parse("Snapshots for volume group containing disk /:\n").timeMachine.isEmpty)
    }

    @Test func sumsDriverStatistics() {
        let total = BlockStorageStatistics.sum([
            ["Bytes (Read)": NSNumber(value: 100), "Operations (Read)": NSNumber(value: 4), "Total Time (Read)": NSNumber(value: 4_000)],
            ["Bytes (Write)": NSNumber(value: 50), "Operations (Write)": NSNumber(value: 2), "Total Time (Write)": NSNumber(value: 300)]
        ])
        #expect(total == BlockStorageCounters(bytesRead: 100, bytesWritten: 50, readOperations: 4, writeOperations: 2, readTime: 4_000, writeTime: 300))
    }

    @Test(.tags(.hardware)) func runsSystemToolsWithoutPrivileges() throws {
        let details = try #require(DiskUtility.details(forMountPoint: "/"))
        #expect(details.apfsContainer != nil)
        #expect(LocalSnapshots.list() != nil)
        #expect(CommandRunner.run("/usr/bin/false", []) == nil, "A failing tool yields nothing")
    }
}
