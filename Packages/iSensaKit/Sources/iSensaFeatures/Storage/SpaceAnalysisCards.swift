import iSensaCore
import iSensaDesign
import iSensaInsights
import SwiftUI

/// Starts an analysis, shows its progress, and says what it could not read.
struct SpaceAnalysisCard: View {
    let analysis: SpaceAnalysis
    let formatter: MetricFormatter

    var body: some View {
        Card {
            switch analysis.phase {
            case .idle:
                Text(SpaceText.permissionsNote).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                analyzeButton(tr("Analyze"))
            case let .scanning(progress):
                HStack(spacing: Spacing.medium) {
                    ProgressView().controlSize(.small)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(tr("Analyzing… %@ files", formatter.integer(progress?.itemCount ?? 0))).monospacedDigit()
                        Text(progress.map { SpacePaths.display(URL(fileURLWithPath: $0.currentFolder)) } ?? " ")
                            .font(Typography.caption).foregroundStyle(.secondary).lineLimit(1).truncationMode(.middle)
                    }
                    Spacer()
                    Button(tr("Stop")) { analysis.cancel() }
                }
                .accessibilityIdentifier("space.progress")
            case .finished:
                if let report = analysis.report { summary(report) }
            case let .failed(reason):
                Label(tr("The analysis could not finish: %@", reason), systemImage: "exclamationmark.triangle").foregroundStyle(.orange)
                analyzeButton(tr("Try Again"))
            }
        }
    }

    private func analyzeButton(_ title: String) -> some View {
        Button(title) { analysis.start() }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("space.analyze")
    }

    @ViewBuilder private func summary(_ report: DiskUsageReport) -> some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(tr("%@ in your home folder and apps", formatter.fileBytes(report.totalSize))).font(Typography.headline)
                Text(tr("%@ files analyzed %@", formatter.integer(report.itemCount), report.date.formatted(.relative(presentation: .named))))
                    .font(Typography.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button(tr("Analyze Again")) { analysis.start() }.accessibilityIdentifier("space.analyze")
        }
        if analysis.isOutdated {
            Text(tr("Items were put back from the Trash. Analyze again to update the sizes.")).font(Typography.caption).foregroundStyle(.orange)
        }
        if !report.unreadable.isEmpty {
            Divider()
            HStack(alignment: .top, spacing: Spacing.medium) {
                Image(systemName: "lock").foregroundStyle(.secondary)
                Text(SpaceText.fullDiskAccessNote).font(Typography.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                Spacer()
                Button(tr("Open Privacy Settings")) { SpacePaths.openFullDiskAccessSettings() }.controlSize(.small)
            }
        }
        if !report.skipped.isEmpty {
            Text(SpaceText.cloudNote).font(Typography.caption).foregroundStyle(.secondary)
        }
    }
}

/// Where the space goes, in plain categories.
struct SpaceCategoriesCard: View {
    let categories: [SpaceCategory]
    let formatter: MetricFormatter

    var body: some View {
        Card(tr("By category")) {
            SegmentedMeter(
                segments: categories.enumerated().map { index, category in
                    .init(id: category.kind.rawValue, label: SpaceText.category(category.kind), value: Double(category.size),
                          color: Self.color(index), detail: formatter.fileBytes(category.size))
                },
                total: Double(categories.reduce(0) { $0 + $1.size })
            )
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("space.categories")
        }
    }

    private static let palette: [Hue] = [.storage, .cpu, .gpu, .memory, .network, .power, .battery, .fans, .thermal, .neutral]

    static func color(_ index: Int) -> Color { palette[index % palette.count].color }
}

/// The analysis' suggestions, largest first.
struct SuggestionsList: View {
    let suggestions: [CleanupSuggestion]
    let formatter: MetricFormatter
    let review: (CleanupSuggestion) -> Void

    var body: some View {
        if suggestions.isEmpty {
            Card { Text(tr("Nothing obvious to clean up. The Folders and Large files tabs show what takes the most space.")).foregroundStyle(.secondary) }
        } else {
            Card {
                ForEach(Array(suggestions.enumerated()), id: \.element.id) { index, suggestion in
                    if index > 0 { Divider() }
                    row(suggestion)
                }
            }
            .accessibilityElement(children: .contain)
        .accessibilityIdentifier("space.suggestions")
        }
    }

    private func row(_ suggestion: CleanupSuggestion) -> some View {
        HStack(alignment: .top, spacing: Spacing.medium) {
            VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                Text(SpaceText.suggestionTitle(suggestion.kind)).font(Typography.body.weight(.medium))
                Text(SpaceText.suggestionDetail(suggestion.kind)).font(Typography.caption).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: Spacing.large)
            Text(formatter.fileBytes(suggestion.size)).monospacedDigit().font(Typography.body.weight(.semibold))
            switch suggestion.action {
            case .moveToTrash, .uninstall:
                Button(tr("Review…")) { review(suggestion) }.accessibilityIdentifier("space.suggestion.\(suggestion.kind.rawValue)")
            case let .elsewhere(url):
                Button(tr("Show in Finder")) { SpacePaths.reveal(url) }
            }
        }
        .padding(.vertical, Spacing.xxSmall)
    }
}
