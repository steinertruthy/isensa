import Foundation
import SensaCore

/// Something that usually frees space safely, found in a space analysis. Pure rules, no file access.
public struct CleanupSuggestion: Sendable, Equatable, Identifiable {
    public enum Kind: String, Sendable, CaseIterable {
        case installers, staleDownloads, derivedData, deviceSupport, largeCaches, unusedApps
        /// Managed by another app or tool: Sensa explains where to clean it instead of deleting files underneath.
        case simulators, docker, iPhoneBackups, trash
    }

    public enum Action: Sendable, Equatable {
        case moveToTrash([DiskUsageItem])
        case uninstall([InstalledApp])
        case elsewhere(URL)
    }

    public let kind: Kind
    public let size: UInt64
    public let action: Action

    public var id: Kind { kind }
}

public enum CleanupSuggestions {
    public static let unusedAppAge: TimeInterval = 180 * 86_400

    public static func make(report: DiskUsageReport, apps: [InstalledApp], home: URL, now: Date) -> [CleanupSuggestion] {
        func item(_ path: String) -> DiskUsageItem? { report.item(at: home.appendingPathComponent(path)) }
        func total(_ items: [DiskUsageItem]) -> UInt64 { items.reduce(0) { $0 + $1.size } }
        var suggestions: [CleanupSuggestion] = []
        func trash(_ kind: CleanupSuggestion.Kind, _ items: [DiskUsageItem], minimum: UInt64) {
            let size = total(items)
            if size >= minimum { suggestions.append(.init(kind: kind, size: size, action: .moveToTrash(items))) }
        }
        func elsewhere(_ kind: CleanupSuggestion.Kind, _ path: String, minimum: UInt64) {
            if let found = item(path), found.isReadable, found.size >= minimum {
                suggestions.append(.init(kind: kind, size: found.size, action: .elsewhere(found.url)))
            }
        }
        trash(.installers, report.installers, minimum: 1)
        trash(.staleDownloads, report.staleDownloads, minimum: 1)
        trash(.derivedData, item("Library/Developer/Xcode/DerivedData").map { [$0] } ?? [], minimum: 100_000_000)
        trash(.deviceSupport, item("Library/Developer/Xcode/iOS DeviceSupport").map { [$0] } ?? [], minimum: 100_000_000)
        trash(.largeCaches, item("Library/Caches")?.children.filter { $0.size >= 500_000_000 } ?? [], minimum: 1)
        let unused = apps.filter { app in
            guard let opened = app.lastUsed, !(app.bundleIdentifier?.hasPrefix("com.apple.") ?? false) else { return false }
            return now.timeIntervalSince(opened) >= unusedAppAge && app.size >= 100_000_000
        }
        if !unused.isEmpty {
            suggestions.append(.init(kind: .unusedApps, size: unused.reduce(0) { $0 + $1.size }, action: .uninstall(unused)))
        }
        elsewhere(.simulators, "Library/Developer/CoreSimulator", minimum: 1_000_000_000)
        elsewhere(.docker, "Library/Containers/com.docker.docker", minimum: 1_000_000_000)
        elsewhere(.iPhoneBackups, "Library/Application Support/MobileSync/Backup", minimum: 100_000_000)
        elsewhere(.trash, ".Trash", minimum: 100_000_000)
        return suggestions.sorted { $0.size > $1.size }
    }
}

/// Where the space in the home folder and the Applications folders goes, in plain categories.
public struct SpaceCategory: Sendable, Equatable, Identifiable {
    public enum Kind: String, Sendable, CaseIterable {
        case apps, documents, downloads, media, developer, appData, caches, mailAndMessages, trash, other
    }

    public let kind: Kind
    public let size: UInt64
    /// Folders that make up the category, for "show in Finder" and browsing.
    public let folders: [URL]

    public var id: Kind { kind }

    static let paths: [(Kind, [String])] = [
        (.documents, ["Documents", "Desktop"]),
        (.downloads, ["Downloads"]),
        (.media, ["Pictures", "Movies", "Music"]),
        (.developer, ["Library/Developer"]),
        (.appData, ["Library/Application Support", "Library/Containers", "Library/Group Containers"]),
        (.caches, ["Library/Caches"]),
        (.mailAndMessages, ["Library/Mail", "Library/Messages"]),
        (.trash, [".Trash"])
    ]

    public static func make(report: DiskUsageReport, home: URL, applicationFolders: [URL]) -> [SpaceCategory] {
        var categories: [SpaceCategory] = []
        let appFolders = applicationFolders.compactMap { report.item(at: $0) }
        let appsSize = appFolders.reduce(0) { $0 + $1.size }
        if appsSize > 0 { categories.append(.init(kind: .apps, size: appsSize, folders: appFolders.map(\.url))) }
        var counted: UInt64 = 0
        for (kind, paths) in paths {
            let items = paths.compactMap { report.item(at: home.appendingPathComponent($0)) }
            let size = items.reduce(0) { $0 + $1.size }
            counted += size
            if size > 0 { categories.append(.init(kind: kind, size: size, folders: items.map(\.url))) }
        }
        if let homeItem = report.item(at: home) {
            // ~/Applications is inside the home folder and already counted as apps.
            let homeApps = appFolders.filter { $0.url.path.hasPrefix(home.standardizedFileURL.path + "/") }.reduce(0) { $0 + $1.size }
            let rest = homeItem.size > counted + homeApps ? homeItem.size - counted - homeApps : 0
            if rest > 0 { categories.append(.init(kind: .other, size: rest, folders: [homeItem.url])) }
        }
        return categories.sorted { $0.size > $1.size }
    }
}
