import iSensaDesign
import SwiftUI

/// Common layout for detail screens: a hued icon, the title, a plain-language summary, then content.
struct ScreenContainer<Content: View>: View {
    let title: String
    let summary: String
    let symbol: String
    let hue: Hue
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.section) {
                HStack(alignment: .center, spacing: Spacing.medium) {
                    SidebarIcon(symbol, hue: hue, size: 40, bouncesOnAppear: true)
                    VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                        Text(title).font(Typography.largeTitle)
                        Text(summary)
                            .font(Typography.body)
                            .foregroundStyle(.secondary)
                            .contentTransition(.opacity)
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("screen.header")
                content
            }
            .padding(Spacing.xxLarge)
            .frame(maxWidth: 1_040, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .scrollContentBackground(.hidden)
        .accessibilityIdentifier("screen.scroll")
    }
}

/// Progressive disclosure for advanced metrics. Expansion is a global preference,
/// so users who want technical depth see it everywhere.
struct TechnicalDetails<Content: View>: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.iSensaMotion) private var motion
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ViewBuilder let content: Content

    var body: some View {
        @Bindable var settings = settings
        let animation = Motion.resolve(Motion.standard, preference: motion, reduceMotion: reduceMotion)
        DisclosureGroup(isExpanded: $settings.showsTechnicalDetails.animation(animation)) {
            VStack(alignment: .leading, spacing: Spacing.xSmall) { content }
                .padding(Spacing.large)
                .frame(maxWidth: .infinity, alignment: .leading)
                .surface()
                .padding(.top, Spacing.small)
        } label: {
            Text(tr("Technical details")).font(Typography.headline)
        }
        .accessibilityIdentifier("technical.details")
    }
}

/// Waiting state shown while the first sample arrives.
struct WaitingView: View {
    var message = tr("Reading sensors…")

    var body: some View {
        ProgressView(message)
            .controlSize(.small)
            .frame(maxWidth: .infinity, minHeight: 120)
    }
}
