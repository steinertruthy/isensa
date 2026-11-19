import Foundation

/// An app in /Applications or ~/Applications.
public struct InstalledApp: Sendable, Hashable, Identifiable {
    public let url: URL
    public let name: String
    public let bundleIdentifier: String?
    public let version: String?
    public let size: UInt64
    /// When Spotlight last saw it opened; `nil` when never recorded.
    public let lastOpened: Date?
    /// When the app last saved its settings or window state: a sign of use when Spotlight has no record.
    public let lastActivity: Date?

    public init(
        url: URL, name: String, bundleIdentifier: String?, version: String?, size: UInt64, lastOpened: Date?, lastActivity: Date? = nil
    ) {
        self.url = url
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.version = version
        self.size = size
        self.lastOpened = lastOpened
        self.lastActivity = lastActivity
    }

    /// The best sign of when the app was last used.
    public var lastUsed: Date? { lastOpened ?? lastActivity }

    public var id: URL { url }
}

/// A file or folder an app leaves in the user's Library (support files, caches, preferences).
public struct AppLeftover: Sendable, Hashable, Identifiable {
    public let url: URL
    public let size: UInt64

    public init(url: URL, size: UInt64) {
        self.url = url
        self.size = size
    }

    public var id: URL { url }
}

public protocol AppInventoryReading: Sendable {
    func apps(in folders: [URL]) async -> [InstalledApp]
    /// Files the app left in `~/Library`, matched by its exact bundle identifier.
    func leftovers(of app: InstalledApp) async -> [AppLeftover]
}

/// Moves items to the Trash (never deletes them) and can put them back.
public protocol FileTrashing: Sendable {
    /// Returns where the item went in the Trash.
    func moveToTrash(_ url: URL) async throws -> URL
    func putBack(_ trashed: URL, to original: URL) async throws
}
