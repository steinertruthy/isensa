import AppKit
import SensaCore
import SensaDesign
import SwiftUI

/// What is about to go to the Trash, with a checkbox per item. Nothing moves until the person confirms.
struct RemovalReview: Identifiable {
    let id = UUID()
    let title: String
    var targets: [RemovalTarget]
    /// Shown while the leftovers of an app are being found.
    var isLoading = false
}

struct RemovalReviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) private var settings
    let review: RemovalReview
    let policy: RemovalPolicy
    let confirm: ([RemovalTarget]) -> Void

    @State private var excluded: Set<URL> = []

    var body: some View {
        let formatter = settings.formatter
        let selected = review.targets.filter { !excluded.contains($0.url) && refusal($0) == nil }
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text(review.title).font(Typography.title)
            Text(SpaceText.trashNote).font(Typography.callout).foregroundStyle(.secondary)
            if review.isLoading {
                ProgressView().frame(maxWidth: .infinity, minHeight: 120)
            } else {
                List(review.targets) { target in row(target, formatter: formatter) }
                    .frame(minHeight: 160, maxHeight: 360)
                    .accessibilityIdentifier("space.review.list")
            }
            HStack {
                Text(tr("%@ selected", formatter.fileBytes(selected.reduce(0) { $0 + $1.size })))
                    .font(Typography.callout).monospacedDigit()
                Spacer()
                Button(tr("Cancel"), role: .cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button(tr("Move to Trash")) {
                    confirm(selected)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(selected.isEmpty || review.isLoading)
                .accessibilityIdentifier("space.review.confirm")
            }
        }
        .padding(Spacing.xLarge)
        .frame(width: 560)
    }

    private func refusal(_ target: RemovalTarget) -> RemovalPolicy.Refusal? {
        policy.refusal(for: target.url, bundleIdentifier: target.bundleIdentifier)
    }

    private func row(_ target: RemovalTarget, formatter: MetricFormatter) -> some View {
        let refusal = refusal(target)
        return HStack(spacing: Spacing.medium) {
            Toggle(isOn: Binding(
                get: { refusal == nil && !excluded.contains(target.url) },
                set: { if $0 { excluded.remove(target.url) } else { excluded.insert(target.url) } }
            )) { EmptyView() }
            .labelsHidden()
            .disabled(refusal != nil)
            Image(nsImage: NSWorkspace.shared.icon(forFile: target.url.path)).resizable().frame(width: 20, height: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(target.name).lineLimit(1).truncationMode(.middle)
                Text(refusal.map(SpaceText.refusal) ?? SpacePaths.display(target.url))
                    .font(Typography.caption).foregroundStyle(refusal == nil ? Color.secondary : Color.orange)
                    .lineLimit(2).truncationMode(.middle)
            }
            Spacer()
            Text(formatter.fileBytes(target.size)).monospacedDigit().foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}

enum SpacePaths {
    /// `/Users/me/Downloads/file.dmg` → `~/Downloads/file.dmg`.
    static func display(_ url: URL) -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let path = url.path
        return path.hasPrefix(home + "/") ? "~" + path.dropFirst(home.count) : path
    }

    static func reveal(_ url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    static func openFullDiskAccessSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
            NSWorkspace.shared.open(url)
        }
    }
}
