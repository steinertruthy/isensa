import SensaDesign
import SwiftUI

/// Common layout for component screens: title, plain-language summary, then content.
struct ScreenContainer<Content: View>: View {
    let title: String
    let summary: String
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xLarge) {
                VStack(alignment: .leading, spacing: Spacing.xSmall) {
                    Text(title).font(Typography.largeTitle)
                    Text(summary)
                        .font(Typography.body)
                        .foregroundStyle(.secondary)
                        .contentTransition(.opacity)
                }
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("screen.header")
                content
            }
            .padding(Spacing.xxLarge)
            .frame(maxWidth: 980, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .scrollContentBackground(.hidden)
    }
}

/// Progressive disclosure for advanced metrics. Expansion is a global preference,
/// so users who want technical depth see it everywhere.
struct TechnicalDetails<Content: View>: View {
    @Environment(AppSettings.self) private var settings
    @ViewBuilder let content: Content

    var body: some View {
        @Bindable var settings = settings
        Card {
            DisclosureGroup(isExpanded: $settings.showsTechnicalDetails.animation(Motion.standard)) {
                VStack(alignment: .leading, spacing: Spacing.xSmall) { content }
                    .padding(.top, Spacing.medium)
            } label: {
                Label(tr("Technical details"), systemImage: "wrench.and.screwdriver")
                    .font(Typography.headline)
            }
        }
    }
}

/// Empty / waiting state shown while the first sample arrives or when data is unavailable.
struct WaitingView: View {
    var message = tr("Reading sensors…")

    var body: some View {
        ProgressView(message)
            .controlSize(.small)
            .frame(maxWidth: .infinity, minHeight: 160)
    }
}
