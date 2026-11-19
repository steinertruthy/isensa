import iSensaDesign
import SwiftUI

/// Shown in the menu bar popover while a newer version is waiting.
struct UpdateBanner: View {
    let update: AvailableUpdate

    var body: some View {
        Link(destination: update.pageURL) {
            HStack(spacing: Spacing.small) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.accentColor)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 0) {
                    Text(tr("iSensa %@ is available", update.version.description)).font(Typography.callout.weight(.semibold))
                    Text(tr("Download it from GitHub")).font(Typography.caption).foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "arrow.up.right").font(Typography.caption).foregroundStyle(.secondary).accessibilityHidden(true)
            }
            .padding(Spacing.small)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .surface()
        .accessibilityIdentifier("menubar.update")
    }
}

/// The update section of Settings › About iSensa.
struct UpdateSection: View {
    @Environment(AppSettings.self) private var settings
    let checker: UpdateChecker

    var body: some View {
        @Bindable var settings = settings
        Section(tr("Updates")) {
            Toggle(tr("Check for updates automatically"), isOn: $settings.checksForUpdates)
            LabeledContent(tr("Status")) { status }
            if let update = checker.availableUpdate {
                FootnoteAction(update.isPrerelease
                    ? tr("This is a beta version. Download the disk image and drag iSensa to Applications to replace this one.")
                    : tr("Download the disk image and drag iSensa to Applications to replace this one.")) {
                    Link(tr("Download iSensa %@", update.version.description), destination: update.pageURL)
                        .buttonStyle(.borderedProminent)
                }
            } else {
                Button(tr("Check Now")) { Task { await checker.check() } }
                    .disabled(checker.status == .checking)
            }
            Footnote(tr("Once a day iSensa asks GitHub for the number of the latest version. Nothing about you or your Mac is sent."))
        }
    }

    @ViewBuilder private var status: some View {
        switch checker.status {
        case .idle:
            Text(tr("Not checked yet")).foregroundStyle(.secondary)
        case .checking:
            HStack(spacing: Spacing.small) {
                ProgressView().controlSize(.small)
                Text(tr("Checking…"))
            }
        case .upToDate(let date):
            VStack(alignment: .trailing, spacing: 0) {
                Label(tr("iSensa is up to date"), systemImage: "checkmark.circle.fill").foregroundStyle(.green)
                Text(tr("Checked %@", date.formatted(.relative(presentation: .named)))).font(Typography.caption).foregroundStyle(.secondary)
            }
        case .available(let update):
            Label(tr("Version %@ is available", update.version.description), systemImage: "arrow.down.circle.fill")
                .foregroundStyle(Color.accentColor)
        case .failed:
            Text(tr("Could not reach GitHub. Try again later.")).foregroundStyle(.secondary)
        }
    }
}
