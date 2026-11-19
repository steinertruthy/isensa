import SensaCore
import SensaDesign
import SensaInsights
import SwiftUI

/// What takes space in the home folder and the Applications folders, and a safe way to free it:
/// everything goes to the Trash, after a review, and the last removal can be undone.
struct FreeUpSpaceScreen: View {
    enum Tab: String, CaseIterable { case suggestions, folders, apps, files }

    @Environment(AppSettings.self) private var settings
    @Environment(\.services) private var services
    @State private var tab = Tab.suggestions
    @State private var folderPath: [URL] = []
    @State private var review: RemovalReview?
    @State private var result: String?

    var body: some View {
        let formatter = settings.formatter
        ScreenContainer(title: tr("Free Up Space"), summary: summary(formatter), symbol: "sparkles", hue: .storage) {
            if let analysis = services.storage.spaceAnalysis {
                SpaceAnalysisCard(analysis: analysis, formatter: formatter)
                if let removal = analysis.lastRemoval { removalBanner(removal, analysis: analysis, formatter: formatter) }
                if let report = analysis.report {
                    if !analysis.categories.isEmpty { SpaceCategoriesCard(categories: analysis.categories, formatter: formatter) }
                    Picker(tr("Show"), selection: $tab) {
                        Text(tr("Suggestions")).tag(Tab.suggestions)
                        Text(tr("Folders")).tag(Tab.folders)
                        Text(tr("Apps")).tag(Tab.apps)
                        Text(tr("Large files")).tag(Tab.files)
                    }
                    .pickerStyle(.segmented).labelsHidden()
                    .accessibilityIdentifier("space.tabs")
                    content(report: report, analysis: analysis, formatter: formatter)
                }
            }
        }
        .sheet(item: $review) { request in
            if let analysis = services.storage.spaceAnalysis {
                RemovalReviewSheet(review: request, policy: analysis.policy()) { targets in
                    Task { await remove(targets, analysis: analysis, formatter: formatter) }
                }
            }
        }
    }

    @ViewBuilder
    private func content(report: DiskUsageReport, analysis: SpaceAnalysis, formatter: MetricFormatter) -> some View {
        let policy = analysis.policy()
        switch tab {
        case .suggestions:
            SuggestionsList(suggestions: analysis.suggestions, formatter: formatter) { suggestion in open(suggestion, analysis: analysis) }
        case .folders:
            FolderBrowser(report: report, formatter: formatter, policy: policy, remove: { item in review(items: [item]) }, path: $folderPath)
        case .apps:
            AppsList(apps: analysis.apps, formatter: formatter, policy: policy) { app in uninstall([app], analysis: analysis) }
        case .files:
            Card {
                ForEach(report.largestFiles) { file in
                    ItemRow(item: file, parentSize: report.largestFiles.first?.size ?? 1, formatter: formatter, refusal: policy.refusal(for: file.url),
                            subtitle: subtitle(file), remove: { review(items: [file]) })
                }
                if report.largestFiles.isEmpty { Text(tr("No file over 10 MB.")).foregroundStyle(.secondary) }
            }
            .accessibilityElement(children: .contain)
        .accessibilityIdentifier("space.files")
        }
    }

    private func subtitle(_ file: DiskUsageItem) -> String {
        let folder = SpacePaths.display(file.url.deletingLastPathComponent())
        guard let modified = file.modified else { return folder }
        return "\(folder) — \(tr("changed %@", modified.formatted(date: .abbreviated, time: .omitted)))"
    }

    private func removalBanner(_ removal: SpaceAnalysis.Removal, analysis: SpaceAnalysis, formatter: MetricFormatter) -> some View {
        Card {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: Spacing.xSmall) {
                    if !removal.moved.isEmpty {
                        Label(tr("%@ items moved to the Trash, %@ freed", formatter.integer(removal.moved.count), formatter.fileBytes(removal.freed)),
                              systemImage: "trash")
                    }
                    ForEach(removal.failed, id: \.name) { failure in
                        HStack(alignment: .firstTextBaseline) {
                            Label(tr("Could not move %@: %@", failure.name, failure.reason), systemImage: "exclamationmark.triangle")
                                .font(Typography.caption).foregroundStyle(.orange)
                                .fixedSize(horizontal: false, vertical: true)
                            if let url = failure.url {
                                Button(tr("Show in Finder")) { SpacePaths.reveal(url) }.buttonStyle(.link).font(Typography.caption)
                            }
                        }
                    }
                    if let result { Text(result).font(Typography.caption).foregroundStyle(.secondary) }
                }
                Spacer()
                if !removal.moved.isEmpty {
                    Button(tr("Undo")) {
                        Task {
                            let failures = await analysis.undo()
                            result = failures.isEmpty ? nil : failures.map { "\($0.name): \($0.reason)" }.joined(separator: "\n")
                        }
                    }
                    .accessibilityIdentifier("space.undo")
                }
                Button {
                    result = nil
                    analysis.dismissRemoval()
                } label: { Image(systemName: "xmark") }
                .buttonStyle(.borderless)
                .help(tr("Close"))
                .accessibilityLabel(tr("Close"))
                .accessibilityIdentifier("space.removal.close")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("space.removal")
    }

    private func summary(_ formatter: MetricFormatter) -> String {
        guard let analysis = services.storage.spaceAnalysis, let report = analysis.report else {
            return tr("Find what takes space and move what you no longer need to the Trash.")
        }
        let reclaimable = analysis.suggestions.reduce(0) { $0 + $1.size }
        return reclaimable > 0 ? tr("Up to %@ could be freed.", formatter.fileBytes(reclaimable))
            : tr("%@ in your home folder and apps", formatter.fileBytes(report.totalSize))
    }

    private func open(_ suggestion: CleanupSuggestion, analysis: SpaceAnalysis) {
        switch suggestion.action {
        case let .moveToTrash(items): review(items: items, title: SpaceText.suggestionTitle(suggestion.kind))
        case let .uninstall(apps): uninstall(apps, analysis: analysis)
        case .elsewhere: break
        }
    }

    private func review(items: [DiskUsageItem], title: String? = nil) {
        let targets = items.map { RemovalTarget(url: $0.url, name: $0.name, size: $0.size) }
        review = RemovalReview(title: title ?? tr("Move to Trash?"), targets: targets)
    }

    /// Opens the review at once, then adds each app's leftovers as they are found.
    private func uninstall(_ apps: [InstalledApp], analysis: SpaceAnalysis) {
        let title = apps.count == 1 ? tr("Remove %@?", apps[0].name) : tr("Remove %@ apps?", settings.formatter.integer(apps.count))
        var request = RemovalReview(
            title: title, targets: apps.map { RemovalTarget(url: $0.url, name: $0.name, size: $0.size, bundleIdentifier: $0.bundleIdentifier) },
            isLoading: true
        )
        review = request
        Task {
            for app in apps {
                let leftovers = await analysis.leftovers(of: app)
                request.targets += leftovers.map { RemovalTarget(url: $0.url, name: SpacePaths.display($0.url), size: $0.size) }
            }
            request.isLoading = false
            if review?.id == request.id { review = request }
        }
    }

    private func remove(_ targets: [RemovalTarget], analysis: SpaceAnalysis, formatter: MetricFormatter) async {
        result = nil
        await analysis.moveToTrash(targets)
    }
}
