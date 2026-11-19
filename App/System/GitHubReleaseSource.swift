import Foundation
import iSensaFeatures

/// Downloads the public release list from the GitHub API. Sends no token, cookie or identifier:
/// only the app name and version, which GitHub asks every client to state.
enum GitHubReleaseSource {
    static func fetcher(version: String) -> @Sendable () async throws -> Data {
        {
            var request = URLRequest(url: ProjectLinks.releasesFeed, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 20)
            request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
            request.setValue("iSensa/\(version)", forHTTPHeaderField: "User-Agent")
            let configuration = URLSessionConfiguration.ephemeral
            configuration.httpCookieStorage = nil
            let session = URLSession(configuration: configuration)
            defer { session.finishTasksAndInvalidate() }
            let (data, response) = try await session.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
            return data
        }
    }
}
