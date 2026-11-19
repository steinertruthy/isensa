import Foundation

public struct VolumeRecord: Sendable, Equatable {
    public var url: URL
    public var name: String
    public var identifier: String
    public var totalCapacity: UInt64
    /// Available for important usage: what Finder shows, including purgeable space.
    public var availableCapacity: UInt64
    /// Free right now.
    public var freeCapacity: UInt64?
    public var isInternal: Bool
    public var isRemovable: Bool
    public var isEjectable: Bool
    public var isReadOnly: Bool
    public var isRoot: Bool
    public var formatName: String?
}

/// Mounted, browsable volumes with capacities (public Foundation API).
public enum Volumes {
    private static let keys: [URLResourceKey] = [
        .volumeNameKey, .volumeUUIDStringKey, .volumeTotalCapacityKey,
        .volumeAvailableCapacityForImportantUsageKey, .volumeAvailableCapacityKey,
        .volumeIsInternalKey, .volumeIsRemovableKey, .volumeIsEjectableKey, .volumeIsBrowsableKey,
        .volumeIsRootFileSystemKey, .volumeIsReadOnlyKey, .volumeLocalizedFormatDescriptionKey
    ]

    public static func mounted() -> [VolumeRecord] {
        let urls = FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: keys, options: [.skipHiddenVolumes]) ?? []
        return urls.compactMap { url in
            guard let values = try? url.resourceValues(forKeys: Set(keys)),
                  values.volumeIsBrowsable != false,
                  let total = values.volumeTotalCapacity, total > 0 else { return nil }
            let important = values.volumeAvailableCapacityForImportantUsage.map { UInt64(max($0, 0)) }
            let plain = values.volumeAvailableCapacity.map { UInt64(max($0, 0)) }
            // Read-only volumes report 0 for important usage; their free space is the plain value.
            let available = important.flatMap { $0 > 0 ? $0 : nil } ?? plain ?? 0
            return VolumeRecord(
                url: url,
                name: values.volumeName ?? url.lastPathComponent,
                identifier: values.volumeUUIDString ?? url.path,
                totalCapacity: UInt64(total),
                availableCapacity: available,
                freeCapacity: plain,
                isInternal: values.volumeIsInternal ?? false,
                isRemovable: values.volumeIsRemovable ?? false,
                isEjectable: values.volumeIsEjectable ?? false,
                isReadOnly: values.volumeIsReadOnly ?? false,
                isRoot: values.volumeIsRootFileSystem ?? (url.path == "/"),
                formatName: values.volumeLocalizedFormatDescription
            )
        }
    }
}
