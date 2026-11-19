import Darwin
import Foundation
import SensaCore

/// Measures folders on demand: reads only file metadata (never contents), stays on the root's
/// volume, does not follow symbolic links and leaves cloud storage alone (listing it could make
/// the provider download files). Sizes are allocated blocks, as `du` counts them.
///
/// The top two folder levels fan out in parallel; below that each folder is walked with `fts`,
/// and only items large enough to be listed become objects — the rest are counted.
public struct DiskUsageScanner: DiskUsageScanning {
    /// Items smaller than this are folded into their folder's "other items".
    let minimumListedSize: UInt64
    /// At most this many children are kept per folder.
    let childLimit: Int
    let home: URL
    let now: @Sendable () -> Date

    static let installerExtensions: Set<String> = ["dmg", "pkg", "mpkg", "iso", "xip"]
    static let staleDownloadSize: UInt64 = 100_000_000
    static let staleDownloadAge: TimeInterval = 90 * 86_400
    static let largestFileCount = 50
    static let largestFileMinimum: UInt64 = 10_000_000
    static let parallelDepth = 2
    static let parallelism = 8

    public init(
        home: URL = FileManager.default.homeDirectoryForCurrentUser, minimumListedSize: UInt64 = 1_000_000, childLimit: Int = 100,
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.home = home.standardizedFileURL
        self.minimumListedSize = minimumListedSize
        self.childLimit = childLimit
        self.now = now
    }

    public func scan(roots: [URL], progress: @escaping @Sendable (DiskScanProgress) -> Void) async throws -> DiskUsageReport {
        let started = Date()
        let findings = ScanFindings(progress: progress)
        let rules = ScanRules(
            minimumListedSize: minimumListedSize, childLimit: childLimit,
            skipped: Set(["Library/Mobile Documents", "Library/CloudStorage"].map { home.appendingPathComponent($0).path }),
            downloads: home.appendingPathComponent("Downloads").path,
            installerFolders: ["Downloads", "Desktop"].map { home.appendingPathComponent($0).path },
            now: now()
        )
        var items: [DiskUsageItem] = []
        for root in roots {
            try Task.checkCancellation()
            items.append(try await Self.measureFolder(root.standardizedFileURL, rules: rules, findings: findings, depth: 0))
        }
        try Task.checkCancellation()
        return findings.report(roots: items, date: now(), duration: Date().timeIntervalSince(started))
    }

    /// A folder near the top: its entries are measured in parallel.
    private static func measureFolder(_ folder: URL, rules: ScanRules, findings: ScanFindings, depth: Int) async throws -> DiskUsageItem {
        let keys: [URLResourceKey] = [.isDirectoryKey, .isSymbolicLinkKey, .isPackageKey]
        guard let urls = try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: keys, options: []) else {
            findings.unreadable(folder)
            return DiskUsageItem(url: folder, name: folder.lastPathComponent, kind: .folder, size: 0, isReadable: false)
        }
        findings.entered(folder.path)
        let children = try await withThrowingTaskGroup(of: DiskUsageItem?.self) { group in
            var running = 0
            var results: [DiskUsageItem] = []
            for found in urls {
                // Keep the folder's spelling of the path (macOS may answer `/private/var` for `/var`).
                let url = folder.appendingPathComponent(found.lastPathComponent)
                let values = try? found.resourceValues(forKeys: Set(keys))
                if values?.isSymbolicLink == true { continue }
                if rules.skipped.contains(url.path) {
                    findings.skipped(url)
                    continue
                }
                if running >= parallelism, let next = try await group.next() {
                    running -= 1
                    if let next { results.append(next) }
                }
                let fansOut = depth + 1 < parallelDepth && values?.isDirectory == true && values?.isPackage != true
                group.addTask {
                    try Task.checkCancellation()
                    if fansOut { return try await measureFolder(url, rules: rules, findings: findings, depth: depth + 1) }
                    return try TreeWalk(rules: rules, findings: findings).measure(url)
                }
                running += 1
            }
            for try await next in group { if let next { results.append(next) } }
            return results
        }
        return fold(DiskUsageItem(url: folder, name: folder.lastPathComponent, kind: .folder, size: 0), children: children, rules: rules)
    }

    /// Keeps the largest children and folds the rest into a count and a size.
    static func fold(
        _ folder: DiskUsageItem, children: [DiskUsageItem], rules: ScanRules, alreadyFolded: (count: Int, size: UInt64) = (0, 0)
    ) -> DiskUsageItem {
        var item = folder
        let sorted = children.sorted { $0.size > $1.size }
        let kept = sorted.prefix(rules.childLimit).filter { $0.size >= rules.minimumListedSize || !$0.isReadable }
        item.size = sorted.reduce(0) { $0 + $1.size } + alreadyFolded.size
        item.children = Array(kept)
        item.foldedCount = sorted.count - kept.count + alreadyFolded.count
        item.foldedSize = item.size - kept.reduce(0) { $0 + $1.size }
        return item
    }

    func fold(_ folder: DiskUsageItem, children: [DiskUsageItem]) -> DiskUsageItem {
        Self.fold(folder, children: children, rules: ScanRules(minimumListedSize: minimumListedSize, childLimit: childLimit))
    }
}

/// What a scan keeps, skips and looks for.
struct ScanRules: Sendable {
    var minimumListedSize: UInt64
    var childLimit: Int
    var skipped: Set<String> = []
    var downloads = ""
    var installerFolders: [String] = []
    var now = Date()
}
