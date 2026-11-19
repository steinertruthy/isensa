import AppKit
import iSensaCore
import iSensaInsights

/// Something the person chose to move to the Trash.
public struct RemovalTarget: Sendable, Hashable, Identifiable {
    public let url: URL
    public let name: String
    public let size: UInt64
    public let bundleIdentifier: String?

    public init(url: URL, name: String, size: UInt64, bundleIdentifier: String? = nil) {
        self.url = url
        self.name = name
        self.size = size
        self.bundleIdentifier = bundleIdentifier
    }

    public var id: URL { url }
}

/// Runs space analyses on demand and moves what the person confirms to the Trash. Lives for the
/// whole session, so a finished analysis is still there after visiting other screens.
@MainActor @Observable
public final class SpaceAnalysis {
    public struct Dependencies: Sendable {
        public var scanner: any DiskUsageScanning
        /// Makes an inventory that reuses the sizes the analysis measured.
        public var inventory: @Sendable (_ knownSizes: @escaping @Sendable (URL) -> UInt64?) -> any AppInventoryReading
        public var trash: any FileTrashing
        public var home: URL
        public var applicationFolders: [URL]
        public var ownBundle: URL

        public init(
            scanner: any DiskUsageScanning, inventory: @escaping @Sendable (@escaping @Sendable (URL) -> UInt64?) -> any AppInventoryReading,
            trash: any FileTrashing, home: URL, applicationFolders: [URL], ownBundle: URL
        ) {
            self.scanner = scanner
            self.inventory = inventory
            self.trash = trash
            self.home = home
            self.applicationFolders = applicationFolders
            self.ownBundle = ownBundle
        }
    }

    public enum Phase: Equatable {
        case idle, scanning(DiskScanProgress?), finished, failed(String)
    }

    public struct Removal: Equatable {
        public struct Moved: Equatable {
            let original: URL
            let trashed: URL
            let size: UInt64
        }

        public struct Failure: Equatable {
            public let name: String
            public let reason: String
            /// Where the item is, so the person can deal with it in Finder.
            public var url: URL?
        }

        public var moved: [Moved] = []
        public var failed: [Failure] = []
        public var freed: UInt64 { moved.reduce(0) { $0 + $1.size } }
    }

    let dependencies: Dependencies
    public private(set) var phase: Phase = .idle
    public private(set) var report: DiskUsageReport?
    public private(set) var apps: [InstalledApp] = []
    public private(set) var suggestions: [CleanupSuggestion] = []
    public private(set) var categories: [SpaceCategory] = []
    /// The last removal, which can be undone until the next one.
    public private(set) var lastRemoval: Removal?
    /// Sizes no longer match the disk (items were put back from the Trash).
    public private(set) var isOutdated = false
    private var task: Task<Void, Never>?

    public init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    public var roots: [URL] { [dependencies.home] + dependencies.applicationFolders.filter { !$0.path.hasPrefix(dependencies.home.path + "/") } }

    public func start() {
        task?.cancel()
        phase = .scanning(nil)
        let dependencies = dependencies
        let roots = roots
        task = Task {
            let relay = ScanProgressRelay { [weak self] update in
                if case .scanning = self?.phase { self?.phase = .scanning(update) }
            }
            do {
                let report = try await dependencies.scanner.scan(roots: roots, progress: relay.send)
                let sizes = Dictionary(report.roots.flatMap(\.children).flatMap { [$0] + $0.children }.map { ($0.url.standardizedFileURL, $0.size) },
                                       uniquingKeysWith: { first, _ in first })
                let apps = await dependencies.inventory { sizes[$0.standardizedFileURL] }.apps(in: dependencies.applicationFolders)
                guard !Task.isCancelled else { return }
                self.apps = apps
                apply(report)
                isOutdated = false
                lastRemoval = nil
                phase = .finished
            } catch is CancellationError {
                phase = report == nil ? .idle : .finished
            } catch {
                phase = .failed(error.localizedDescription)
            }
        }
    }

    public func cancel() {
        task?.cancel()
    }

    private func apply(_ report: DiskUsageReport) {
        self.report = report
        suggestions = CleanupSuggestions.make(report: report, apps: apps, home: dependencies.home, now: Date())
        categories = SpaceCategory.make(report: report, home: dependencies.home, applicationFolders: dependencies.applicationFolders)
    }

    /// The rules in force right now (they depend on which apps are open).
    public func policy() -> RemovalPolicy {
        var running: [String: String] = [:]
        for app in NSWorkspace.shared.runningApplications {
            let name = app.localizedName ?? app.bundleIdentifier ?? ""
            if let id = app.bundleIdentifier { running[id] = name }
            if let localized = app.localizedName { running[localized] = name }
        }
        return RemovalPolicy(home: dependencies.home, applicationFolders: dependencies.applicationFolders, ownBundle: dependencies.ownBundle,
                             runningApps: running)
    }

    public func leftovers(of app: InstalledApp) async -> [AppLeftover] {
        await dependencies.inventory { _ in nil }.leftovers(of: app)
    }

    /// Moves each target to the Trash after checking it against the removal rules again.
    @discardableResult
    public func moveToTrash(_ targets: [RemovalTarget]) async -> Removal {
        let policy = policy()
        var removal = Removal()
        for target in targets {
            if let refusal = policy.refusal(for: target.url, bundleIdentifier: target.bundleIdentifier) {
                removal.failed.append(.init(name: target.name, reason: SpaceText.refusal(refusal), url: target.url))
                continue
            }
            do {
                let trashed = try await dependencies.trash.moveToTrash(target.url)
                removal.moved.append(.init(original: target.url, trashed: trashed, size: target.size))
            } catch is CancellationError {
                continue // The person cancelled the password prompt: nothing to report.
            } catch {
                removal.failed.append(.init(name: target.name, reason: error.localizedDescription, url: target.url))
            }
        }
        if let report, !removal.moved.isEmpty {
            let originals = removal.moved.map(\.original)
            apps.removeAll { app in originals.contains(app.url) }
            apply(report.removing(originals))
        }
        lastRemoval = removal.moved.isEmpty && removal.failed.isEmpty ? nil : removal
        return removal
    }

    /// Hides the result of the last removal (it can no longer be undone).
    public func dismissRemoval() {
        lastRemoval = nil
    }

    /// Puts the last removal back where it was.
    public func undo() async -> [Removal.Failure] {
        guard let removal = lastRemoval else { return [] }
        var failures: [Removal.Failure] = []
        for item in removal.moved {
            do {
                try await dependencies.trash.putBack(item.trashed, to: item.original)
            } catch is CancellationError {
                failures.append(.init(name: item.original.lastPathComponent, reason: tr("Still in the Trash."), url: item.trashed))
            } catch {
                failures.append(.init(name: item.original.lastPathComponent, reason: error.localizedDescription))
            }
        }
        lastRemoval = nil
        isOutdated = true
        return failures
    }
}

/// Hands scan progress from the walking threads to the main actor.
private struct ScanProgressRelay: Sendable {
    let apply: @MainActor (DiskScanProgress) -> Void

    func send(_ update: DiskScanProgress) {
        Task { @MainActor in apply(update) }
    }
}
