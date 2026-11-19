import Darwin
import Foundation
import SensaCore

/// Walks one file or folder tree with `fts` (physical, same device), the way `du` does.
struct TreeWalk {
    let rules: ScanRules
    let findings: ScanFindings

    /// A folder being walked: its own size and the children worth listing.
    private final class Frame {
        let path: String
        let isPackage: Bool
        let insidePackage: Bool
        let modified: Date?
        var size: UInt64 = 0
        var children: [DiskUsageItem] = []
        var foldedCount = 0
        var foldedSize: UInt64 = 0

        init(path: String, isPackage: Bool, insidePackage: Bool, modified: Date?) {
            self.path = path
            self.isPackage = isPackage
            self.insidePackage = insidePackage
            self.modified = modified
        }

        var keepsChildren: Bool { !isPackage && !insidePackage }

        func fold(_ size: UInt64) {
            foldedCount += 1
            foldedSize += size
        }
    }

    private struct State {
        var stack: [Frame] = []
        var result: DiskUsageItem?
        var counted = 0
        var packageExtensions: [String: Bool] = [:]
    }

    func measure(_ url: URL) throws -> DiskUsageItem? {
        let stream = url.path.withCString { path -> UnsafeMutablePointer<FTS>? in
            var paths: [UnsafeMutablePointer<CChar>?] = [strdup(path), nil]
            defer { free(paths[0]) }
            return fts_open(&paths, FTS_PHYSICAL | FTS_XDEV | FTS_NOCHDIR, nil)
        }
        guard let stream else { return nil }
        defer { fts_close(stream) }
        var state = State()
        while let entry = fts_read(stream) {
            if state.counted >= 2_000 {
                findings.count(state.counted)
                state.counted = 0
                if Task.isCancelled { throw CancellationError() }
            }
            handle(entry, stream: stream, state: &state)
        }
        findings.count(state.counted)
        return state.result
    }

    private func handle(_ entry: UnsafeMutablePointer<FTSENT>, stream: UnsafeMutablePointer<FTS>, state: inout State) {
        let info = Int32(entry.pointee.fts_info)
        let path = String(cString: entry.pointee.fts_path)
        let stat = entry.pointee.fts_statp?.pointee
        let size = UInt64(max(stat?.st_blocks ?? 0, 0)) * 512
        let modified = stat.map { Date(timeIntervalSince1970: TimeInterval($0.st_mtimespec.tv_sec)) }
        let insidePackage = state.stack.last.map { $0.isPackage || $0.insidePackage } ?? false
        switch info {
        case FTS_D:
            if rules.skipped.contains(path) {
                findings.skipped(URL(fileURLWithPath: path))
                fts_set(stream, entry, FTS_SKIP)
                return
            }
            if state.stack.count < 2 { findings.entered(path) }
            let isPackage = isPackage(path, cache: &state.packageExtensions)
            state.stack.append(Frame(path: path, isPackage: isPackage, insidePackage: insidePackage, modified: modified))
        case FTS_DP, FTS_DNR:
            if let top = state.stack.last, top.path == path {
                state.stack.removeLast()
                close(top, readable: info == FTS_DP, state: &state)
            } else if info == FTS_DNR {
                close(Frame(path: path, isPackage: false, insidePackage: insidePackage, modified: nil), readable: false, state: &state)
            }
        case FTS_F, FTS_DEFAULT:
            state.counted += 1
            addFile(path, size: size, modified: modified, insidePackage: insidePackage, state: &state)
        default:
            return // Symbolic links, errors on single files, cycles.
        }
    }

    private func addFile(_ path: String, size: UInt64, modified: Date?, insidePackage: Bool, state: inout State) {
        guard let parent = state.stack.last else {
            let item = file(path, size: size, modified: modified)
            findings.listed(item, rules: rules)
            state.result = item
            return
        }
        parent.size += size
        let listable = parent.keepsChildren && size >= rules.minimumListedSize
        let interesting = !insidePackage && (size >= DiskUsageScanner.largestFileMinimum || rules.installerFolders.contains { path.hasPrefix($0 + "/") })
        guard listable || interesting else {
            parent.fold(size)
            return
        }
        let item = file(path, size: size, modified: modified)
        if !insidePackage { findings.listed(item, rules: rules) }
        if listable { parent.children.append(item) } else { parent.fold(size) }
    }

    private func close(_ frame: Frame, readable: Bool, state: inout State) {
        let url = URL(fileURLWithPath: frame.path)
        if !readable { findings.unreadable(url) }
        let base = DiskUsageItem(url: url, name: url.lastPathComponent, kind: frame.isPackage ? .package : .folder, size: 0,
                                 modified: frame.modified, isReadable: readable)
        var item = DiskUsageScanner.fold(base, children: frame.children, rules: rules, alreadyFolded: (frame.foldedCount, frame.foldedSize))
        if frame.isPackage {
            // A package (an app, a library) is one thing to the person: keep its size, not its insides.
            item.children = []
            item.foldedCount = 0
            item.foldedSize = 0
            if !frame.insidePackage, url.pathExtension != "app" { findings.listed(item, rules: rules) }
        }
        guard let parent = state.stack.last else {
            state.result = item
            return
        }
        parent.size += item.size
        if parent.keepsChildren, item.size >= rules.minimumListedSize || !item.isReadable {
            parent.children.append(item)
        } else {
            parent.fold(item.size)
        }
    }

    /// Folders with an extension may be packages; the answer is the same for every folder with that extension.
    private func isPackage(_ path: String, cache: inout [String: Bool]) -> Bool {
        let ext = (path as NSString).pathExtension.lowercased()
        guard !ext.isEmpty else { return false }
        if let known = cache[ext] { return known }
        let isPackage = (try? URL(fileURLWithPath: path).resourceValues(forKeys: [.isPackageKey]).isPackage) == true
        cache[ext] = isPackage
        return isPackage
    }

    private func file(_ path: String, size: UInt64, modified: Date?) -> DiskUsageItem {
        let url = URL(fileURLWithPath: path)
        return DiskUsageItem(url: url, name: url.lastPathComponent, kind: .file, size: size, modified: modified)
    }
}

/// Everything the walks report while they run, behind one lock.
final class ScanFindings: @unchecked Sendable {
    private let lock = NSLock()
    private let progress: @Sendable (DiskScanProgress) -> Void
    private var total = 0
    private var lastReport = Date.distantPast
    private var largest: [DiskUsageItem] = []
    private var installers: [DiskUsageItem] = []
    private var stale: [DiskUsageItem] = []
    private var unreadableFolders: [URL] = []
    private var skippedFolders: [URL] = []

    init(progress: @escaping @Sendable (DiskScanProgress) -> Void) {
        self.progress = progress
    }

    func count(_ files: Int) {
        lock.withLock { total += files }
    }

    func entered(_ folder: String) {
        let update: DiskScanProgress? = lock.withLock {
            guard Date().timeIntervalSince(lastReport) > 0.2 else { return nil }
            lastReport = Date()
            return DiskScanProgress(itemCount: total, currentFolder: folder)
        }
        if let update { progress(update) }
    }

    /// A file or package that may belong in the largest, installer or stale-download lists.
    func listed(_ item: DiskUsageItem, rules: ScanRules) {
        let path = item.url.path
        lock.withLock {
            if item.size >= DiskUsageScanner.largestFileMinimum {
                let index = largest.firstIndex { $0.size < item.size } ?? largest.endIndex
                if index < DiskUsageScanner.largestFileCount {
                    largest.insert(item, at: index)
                    if largest.count > DiskUsageScanner.largestFileCount { largest.removeLast() }
                }
            }
            if DiskUsageScanner.installerExtensions.contains(item.url.pathExtension.lowercased()),
               rules.installerFolders.contains(where: { path.hasPrefix($0 + "/") }) {
                installers.append(item)
            } else if item.kind == .file, item.size >= DiskUsageScanner.staleDownloadSize, path.hasPrefix(rules.downloads + "/"),
                      let modified = item.modified, rules.now.timeIntervalSince(modified) >= DiskUsageScanner.staleDownloadAge {
                stale.append(item)
            }
        }
    }

    func unreadable(_ folder: URL) { lock.withLock { unreadableFolders.append(folder) } }
    func skipped(_ folder: URL) { lock.withLock { skippedFolders.append(folder) } }

    func report(roots: [DiskUsageItem], date: Date, duration: TimeInterval) -> DiskUsageReport {
        lock.withLock {
            DiskUsageReport(
                date: date, roots: roots, largestFiles: largest,
                installers: installers.sorted { $0.size > $1.size }, staleDownloads: stale.sorted { $0.size > $1.size },
                unreadable: unreadableFolders.sorted { $0.path < $1.path }, skipped: skippedFolders, itemCount: total, duration: duration
            )
        }
    }
}
