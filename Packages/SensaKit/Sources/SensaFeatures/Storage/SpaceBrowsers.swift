import AppKit
import SensaCore
import SensaDesign
import SwiftUI

/// Folder by folder, largest first, with a breadcrumb to go back up.
struct FolderBrowser: View {
    let report: DiskUsageReport
    let formatter: MetricFormatter
    let policy: RemovalPolicy
    let remove: (DiskUsageItem) -> Void
    @Binding var path: [URL]

    var body: some View {
        let current = path.last.flatMap(report.item(at:))
        Card {
            breadcrumb
            if let current {
                ForEach(current.children) { child in
                    ItemRow(item: child, parentSize: current.size, formatter: formatter, refusal: policy.refusal(for: child.url),
                            open: child.kind == .folder && child.isReadable ? { path.append(child.url) } : nil,
                            remove: { remove(child) })
                }
                if current.foldedCount > 0 {
                    Text(tr("%@ smaller items, %@", formatter.integer(current.foldedCount), formatter.fileBytes(current.foldedSize)))
                        .font(Typography.caption).foregroundStyle(.secondary)
                }
            } else {
                ForEach(report.roots) { root in
                    ItemRow(item: root, parentSize: report.totalSize, formatter: formatter, refusal: policy.refusal(for: root.url),
                            open: { path.append(root.url) }, remove: {})
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("space.folders")
    }

    private var breadcrumb: some View {
        HStack(spacing: Spacing.xSmall) {
            Button(tr("All")) { path.removeAll() }.buttonStyle(.link).disabled(path.isEmpty)
            ForEach(Array(path.enumerated()), id: \.offset) { index, url in
                Image(systemName: "chevron.right").font(.caption2).foregroundStyle(.tertiary)
                Button(index == 0 ? SpacePaths.display(url) : url.lastPathComponent) { path.removeLast(path.count - index - 1) }
                    .buttonStyle(.link).disabled(index == path.count - 1).lineLimit(1)
            }
            Spacer()
        }
        .font(Typography.callout)
    }
}

/// One file, package or folder: icon, name, share of its folder, size, and what can be done with it.
struct ItemRow: View {
    let item: DiskUsageItem
    let parentSize: UInt64
    let formatter: MetricFormatter
    let refusal: RemovalPolicy.Refusal?
    var subtitle: String?
    var open: (() -> Void)?
    let remove: () -> Void

    var body: some View {
        HStack(spacing: Spacing.medium) {
            Image(nsImage: NSWorkspace.shared.icon(forFile: item.url.path)).resizable().frame(width: 22, height: 22)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: Spacing.xSmall) {
                    Text(item.name).lineLimit(1).truncationMode(.middle)
                    if !item.isReadable { Image(systemName: "lock").font(.caption).foregroundStyle(.secondary).help(tr("No access")) }
                }
                if let subtitle {
                    Text(subtitle).font(Typography.caption).foregroundStyle(.secondary).lineLimit(1).truncationMode(.middle)
                } else {
                    MeterBar(value: parentSize > 0 ? Double(item.size) / Double(parentSize) : 0, tint: Hue.storage.color).frame(maxWidth: 220)
                }
            }
            Spacer(minLength: Spacing.medium)
            Text(item.isReadable ? formatter.fileBytes(item.size) : tr("No access")).monospacedDigit().foregroundStyle(.secondary)
            Menu {
                Button(tr("Show in Finder")) { SpacePaths.reveal(item.url) }
                Button(tr("Move to Trash…")) { remove() }.disabled(refusal != nil)
                if let refusal { Text(SpaceText.refusal(refusal)) }
            } label: { Image(systemName: "ellipsis.circle") }
            .menuStyle(.borderlessButton).menuIndicator(.hidden).fixedSize()
            .accessibilityLabel(tr("Actions for %@", item.name))
            if let open {
                Button(action: open) { Image(systemName: "chevron.right") }.buttonStyle(.borderless).accessibilityLabel(tr("Open %@", item.name))
            } else {
                Image(systemName: "chevron.right").hidden()
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(count: 2) { open?() }
        .padding(.vertical, 2)
    }
}

/// Installed apps, largest first, with when each was last opened.
struct AppsList: View {
    let apps: [InstalledApp]
    let formatter: MetricFormatter
    let policy: RemovalPolicy
    let remove: (InstalledApp) -> Void

    var body: some View {
        Card {
            ForEach(apps) { app in
                let refusal = policy.refusal(for: app.url, bundleIdentifier: app.bundleIdentifier)
                HStack(spacing: Spacing.medium) {
                    Image(nsImage: NSWorkspace.shared.icon(forFile: app.url.path)).resizable().frame(width: 28, height: 28)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(app.name).lineLimit(1)
                        Text(lastOpened(app)).font(Typography.caption).foregroundStyle(.secondary)
                        if let refusal {
                            Text(SpaceText.refusal(refusal)).font(Typography.caption).foregroundStyle(.orange)
                        }
                    }
                    Spacer()
                    Text(formatter.fileBytes(app.size)).monospacedDigit().foregroundStyle(.secondary)
                    Button(tr("Remove…")) { remove(app) }
                        .disabled(refusal != nil)
                        .help(refusal.map(SpaceText.refusal) ?? tr("Moves the app and the files it left to the Trash, after you review them."))
                }
                .padding(.vertical, 2)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("space.apps")
    }

    private func lastOpened(_ app: InstalledApp) -> String {
        if let date = app.lastOpened { return tr("Last opened %@", date.formatted(.relative(presentation: .named))) }
        if let date = app.lastActivity { return tr("Last used %@", date.formatted(.relative(presentation: .named))) }
        return tr("No record of use")
    }
}
