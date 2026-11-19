import Foundation

/// Where the project lives.
public enum ProjectLinks {
    public static let repository = URL(string: "https://github.com/steinertruthy/isensa")!
    public static let author = URL(string: "https://github.com/steinertruthy")!
    public static let website = URL(string: "https://steinertruthy.github.io/isensa/")!
    public static let issues = URL(string: "https://github.com/steinertruthy/isensa/issues")!
    public static let license = URL(string: "https://github.com/steinertruthy/isensa/blob/main/LICENSE")!
    public static let releases = URL(string: "https://github.com/steinertruthy/isensa/releases")!
    /// Public GitHub API: recent releases, newest first. No account or token involved.
    public static let releasesFeed = URL(string: "https://api.github.com/repos/steinertruthy/isensa/releases?per_page=20")!
}

/// A published version newer than the one running.
public struct AvailableUpdate: Equatable, Sendable {
    public let version: AppVersion
    public let title: String
    public let pageURL: URL
    public let isPrerelease: Bool
    public let publishedAt: Date?

    public init(version: AppVersion, title: String, pageURL: URL, isPrerelease: Bool, publishedAt: Date?) {
        self.version = version
        self.title = title
        self.pageURL = pageURL
        self.isPrerelease = isPrerelease
        self.publishedAt = publishedAt
    }
}

/// Reads the GitHub Releases list.
public enum ReleaseFeed {
    private struct Release: Decodable {
        struct Asset: Decodable { let name: String }
        let tagName: String
        let name: String?
        let htmlURL: URL
        let draft: Bool
        let prerelease: Bool
        let publishedAt: Date?
        let assets: [Asset]

        enum CodingKeys: String, CodingKey {
            case tagName = "tag_name", name, htmlURL = "html_url", draft, prerelease, publishedAt = "published_at", assets
        }
    }

    private static let installerExtensions: Set<String> = ["dmg", "pkg", "zip"]

    /// The newest published release that is newer than `current` and already has an installer attached
    /// (so nobody is told to update before the file is there). Drafts are never offered.
    public static func newestUpdate(in data: Data, newerThan current: AppVersion) throws -> AvailableUpdate? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let releases = try decoder.decode([Release].self, from: data)
        return releases
            .filter { !$0.draft && $0.assets.contains { installerExtensions.contains(($0.name as NSString).pathExtension.lowercased()) } }
            .compactMap { release -> AvailableUpdate? in
                guard let version = AppVersion(release.tagName), version > current else { return nil }
                let title = release.name?.trimmingCharacters(in: .whitespaces)
                return AvailableUpdate(
                    version: version, title: title?.isEmpty == false ? title! : "iSensa \(version)",
                    pageURL: release.htmlURL, isPrerelease: release.prerelease, publishedAt: release.publishedAt
                )
            }
            .max { $0.version < $1.version }
    }
}
