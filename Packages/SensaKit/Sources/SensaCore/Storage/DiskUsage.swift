import Foundation

/// One file, package or folder found by a space analysis, with the space it takes on disk.
public struct DiskUsageItem: Sendable, Hashable, Identifiable {
    public enum Kind: Sendable, Hashable { case file, package, folder }

    public let url: URL
    public let name: String
    public let kind: Kind
    /// Allocated bytes, folders and packages included.
    public var size: UInt64
    public let modified: Date?
    /// Largest first. Folders only; small items are folded into `foldedCount`/`foldedSize`.
    public var children: [DiskUsageItem]
    public var foldedCount: Int
    public var foldedSize: UInt64
    /// `false` when macOS did not let Sensa read the folder (privacy protection, permissions).
    public let isReadable: Bool

    public init(
        url: URL, name: String, kind: Kind, size: UInt64, modified: Date? = nil, children: [DiskUsageItem] = [],
        foldedCount: Int = 0, foldedSize: UInt64 = 0, isReadable: Bool = true
    ) {
        self.url = url
        self.name = name
        self.kind = kind
        self.size = size
        self.modified = modified
        self.children = children
        self.foldedCount = foldedCount
        self.foldedSize = foldedSize
        self.isReadable = isReadable
    }

    public var id: URL { url }

    /// The item at `url` inside this one, following the path one level at a time.
    public func item(at url: URL) -> DiskUsageItem? {
        let target = url.standardizedFileURL.path
        let own = self.url.standardizedFileURL.path
        if target == own { return self }
        guard target.hasPrefix(own.hasSuffix("/") ? own : own + "/") else { return nil }
        return children.lazy.compactMap { $0.item(at: url) }.first
    }

    /// This item with `url` taken out and every enclosing folder made smaller by its size.
    public func removing(_ url: URL) -> (item: DiskUsageItem, removed: UInt64) {
        let target = url.standardizedFileURL.path
        var copy = self
        if let index = copy.children.firstIndex(where: { $0.url.standardizedFileURL.path == target }) {
            let removed = copy.children.remove(at: index).size
            copy.size -= min(removed, copy.size)
            return (copy, removed)
        }
        for index in copy.children.indices {
            let result = copy.children[index].removing(url)
            if result.removed > 0 {
                copy.children[index] = result.item
                copy.children.sort { $0.size > $1.size }
                copy.size -= min(result.removed, copy.size)
                return (copy, result.removed)
            }
        }
        return (copy, 0)
    }
}

/// The result of one space analysis.
public struct DiskUsageReport: Sendable, Equatable {
    public var date: Date
    public var roots: [DiskUsageItem]
    /// The largest files found anywhere, largest first.
    public var largestFiles: [DiskUsageItem]
    /// Installer images and packages (.dmg, .pkg…) in Downloads and on the Desktop.
    public var installers: [DiskUsageItem]
    /// Large files in Downloads not modified for a long time.
    public var staleDownloads: [DiskUsageItem]
    /// Folders macOS did not let Sensa read.
    public var unreadable: [URL]
    /// Folders deliberately not analyzed (cloud storage), with their reason.
    public var skipped: [URL]
    public var itemCount: Int
    public var duration: TimeInterval

    public init(
        date: Date, roots: [DiskUsageItem], largestFiles: [DiskUsageItem] = [], installers: [DiskUsageItem] = [],
        staleDownloads: [DiskUsageItem] = [], unreadable: [URL] = [], skipped: [URL] = [], itemCount: Int = 0, duration: TimeInterval = 0
    ) {
        self.date = date
        self.roots = roots
        self.largestFiles = largestFiles
        self.installers = installers
        self.staleDownloads = staleDownloads
        self.unreadable = unreadable
        self.skipped = skipped
        self.itemCount = itemCount
        self.duration = duration
    }

    public var totalSize: UInt64 { roots.reduce(0) { $0 + $1.size } }

    public func item(at url: URL) -> DiskUsageItem? {
        roots.lazy.compactMap { $0.item(at: url) }.first
    }

    /// The report after items went to the Trash: sizes shrink and the items disappear from every list.
    public func removing(_ urls: [URL]) -> DiskUsageReport {
        var copy = self
        let removed = Set(urls.map { $0.standardizedFileURL.path })
        func isRemoved(_ item: DiskUsageItem) -> Bool {
            let path = item.url.standardizedFileURL.path
            return removed.contains { path == $0 || path.hasPrefix($0 + "/") }
        }
        for url in urls {
            copy.roots = copy.roots.map { $0.removing(url).item }
        }
        copy.largestFiles.removeAll(where: isRemoved)
        copy.installers.removeAll(where: isRemoved)
        copy.staleDownloads.removeAll(where: isRemoved)
        return copy
    }
}

public struct DiskScanProgress: Sendable, Equatable {
    public let itemCount: Int
    public let currentFolder: String

    public init(itemCount: Int, currentFolder: String) {
        self.itemCount = itemCount
        self.currentFolder = currentFolder
    }
}

/// Walks folders and measures what takes space. Read-only.
public protocol DiskUsageScanning: Sendable {
    func scan(roots: [URL], progress: @escaping @Sendable (DiskScanProgress) -> Void) async throws -> DiskUsageReport
}
