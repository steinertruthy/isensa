import iSensaControl
import SwiftUI

/// Settings › Fans: install, update or remove the privileged fan helper.
struct FanHelperSection: View {
    let coordinator: FanControlCoordinator
    @State private var confirmsRemoval = false

    var body: some View {
        Section(tr("Fan control")) {
            LabeledContent(tr("Helper")) {
                Text(statusText).foregroundStyle(.secondary)
            }
            .accessibilityIdentifier("settings.fans.helper")
            Footnote(FanControlText.helperExplanation)
            if !coordinator.service.isDemo { Footnote(FanControlText.unsignedNote) }
            HStack {
                switch coordinator.helperState {
                case .ready:
                    Button(tr("Remove Helper…"), role: .destructive) { confirmsRemoval = true }
                case .notInstalled:
                    Button(tr("Install Helper…")) { Task { await coordinator.installHelper() } }
                case .needsUpdate:
                    Button(tr("Update Helper…")) { Task { await coordinator.installHelper() } }
                case .unreachable:
                    Button(tr("Install Again…")) { Task { await coordinator.installHelper() } }
                    Button(tr("Remove Helper…"), role: .destructive) { confirmsRemoval = true }
                }
                if coordinator.isInstalling { ProgressView().controlSize(.small) }
            }
            .disabled(coordinator.isInstalling)
            if let problem = coordinator.problem {
                FanProblemView(problem: problem)
            }
            Footnote(FanControlText.safety)
        }
        .task { await coordinator.refreshState() }
        .confirmationDialog(tr("Remove the fan helper?"), isPresented: $confirmsRemoval) {
            Button(tr("Remove"), role: .destructive) { Task { await coordinator.uninstallHelper() } }
        } message: {
            Text(tr("The fans return to automatic and macOS asks for your password to remove the helper."))
        }
    }

    private var statusText: String {
        switch coordinator.helperState {
        case .ready: tr("Installed")
        case .notInstalled: tr("Not installed")
        case .needsUpdate: tr("Needs an update")
        case .unreachable: tr("Not responding")
        }
    }
}
