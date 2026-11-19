import CoreServices
import Foundation
import SensaCore

/// Apps in the Applications folders, when they were last opened (Spotlight) and the files they
/// keep in the user's Library. Read-only.
public struct InstalledApps: AppInventoryReading {
    let library: URL
    /// Sizes already measured by a space analysis, so large apps are not walked twice.
    let knownSizes: @Sendable (URL) -> UInt64?

    public init(
        home: URL = FileManager.default.homeDirectoryForCurrentUser, knownSizes: @escaping @Sendable (URL) -> UInt64? = { _ in nil }
    ) {
        library = home.appendingPathComponent("Library")
        self.knownSizes = knownSizes
    }

    public func apps(in folders: [URL]) async -> [InstalledApp] {
        folders.flatMap(Self.appBundles).map { url in
            let bundle = Bundle(url: url)
            let info = bundle?.infoDictionary ?? [:]
            let name = (info["CFBundleDisplayName"] as? String) ?? (info["CFBundleName"] as? String) ?? url.deletingPathExtension().lastPathComponent
            return InstalledApp(
                url: url, name: name.isEmpty ? url.deletingPathExtension().lastPathComponent : name,
                bundleIdentifier: bundle?.bundleIdentifier, version: info["CFBundleShortVersionString"] as? String,
                size: knownSizes(url) ?? DirectorySize.allocated(url), lastOpened: Self.lastOpened(url),
                lastActivity: bundle?.bundleIdentifier.flatMap { Self.lastActivity(bundleIdentifier: $0, library: library) }
            )
        }
        .sorted { $0.size > $1.size }
    }

    /// `.app` bundles at the top of a folder and one level down (Utilities, vendor folders).
    static func appBundles(in folder: URL) -> [URL] {
        let fileManager = FileManager.default
        let top = (try? fileManager.contentsOfDirectory(at: folder, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles])) ?? []
        return top.flatMap { url -> [URL] in
            if url.pathExtension == "app" { return [url] }
            guard (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true,
                  (try? url.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink) != true else { return [] }
            return ((try? fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])) ?? [])
                .filter { $0.pathExtension == "app" }
        }
    }

    static func lastOpened(_ url: URL) -> Date? {
        guard let item = MDItemCreateWithURL(nil, url as CFURL) else { return nil }
        return MDItemCopyAttribute(item, kMDItemLastUsedDate) as? Date
    }

    /// Spotlight often has no record for apps opened from the Dock, Terminal or Xcode; their settings and
    /// window state files still change when they run.
    static func lastActivity(bundleIdentifier: String, library: URL) -> Date? {
        ["Preferences/\(bundleIdentifier).plist", "Saved Application State/\(bundleIdentifier).savedState"]
            .compactMap { try? library.appendingPathComponent($0).resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate }
            .max()
    }

    public func leftovers(of app: InstalledApp) async -> [AppLeftover] {
        Self.candidates(bundleIdentifier: app.bundleIdentifier, name: app.url.deletingPathExtension().lastPathComponent, library: library)
            .filter { FileManager.default.fileExists(atPath: $0.path) }
            .map { AppLeftover(url: $0, size: DirectorySize.allocated($0)) }
            .filter { $0.size > 0 }
    }

    /// Where apps keep their files, matched by exact bundle identifier (and app name for the folders
    /// apps usually name after themselves). Apple's apps are never matched: their files belong to macOS.
    static func candidates(bundleIdentifier: String?, name: String, library: URL) -> [URL] {
        guard let id = bundleIdentifier, !id.hasPrefix("com.apple.") else { return [] }
        var paths = [
            "Application Support/\(id)", "Caches/\(id)", "Containers/\(id)", "Preferences/\(id).plist",
            "Saved Application State/\(id).savedState", "Logs/\(id)", "HTTPStorages/\(id)", "HTTPStorages/\(id).binarycookies",
            "WebKit/\(id)"
        ]
        if name.count >= 3 { paths += ["Application Support/\(name)", "Logs/\(name)"] }
        return paths.map { library.appendingPathComponent($0) }
    }
}

/// Allocated size of a file or folder tree, without following symbolic links.
public enum DirectorySize {
    public static func allocated(_ url: URL) -> UInt64 {
        let keys: Set<URLResourceKey> = [.totalFileAllocatedSizeKey, .fileAllocatedSizeKey, .isDirectoryKey]
        if (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) != true {
            let values = try? url.resourceValues(forKeys: keys)
            return UInt64(values?.totalFileAllocatedSize ?? values?.fileAllocatedSize ?? 0)
        }
        guard let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: Array(keys), options: [], errorHandler: { _, _ in true })
        else { return 0 }
        var total: UInt64 = 0
        for case let file as URL in enumerator {
            guard let values = try? file.resourceValues(forKeys: keys), values.isDirectory != true else { continue }
            total += UInt64(values.totalFileAllocatedSize ?? values.fileAllocatedSize ?? 0)
        }
        return total
    }
}

/// Moves items to the Trash with the same call Finder uses, so they can be put back.
public struct TrashRemover: FileTrashing {
    public init() {}

    public func moveToTrash(_ url: URL) async throws -> URL {
        var resulting: NSURL?
        try FileManager.default.trashItem(at: url, resultingItemURL: &resulting)
        return (resulting as URL?) ?? url
    }

    public func putBack(_ trashed: URL, to original: URL) async throws {
        try FileManager.default.moveItem(at: trashed, to: original)
    }
}
