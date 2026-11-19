import AppKit
import SensaDesign
import SwiftUI

/// Time-aware greeting. Re-evaluated on minute boundaries, so the period switches
/// exactly at 12:00 / 18:00 / 05:00 even if the app stays open.
struct GreetingHeader: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.sensaMotion) private var motion

    var body: some View {
        TimelineView(.everyMinute) { context in
            let greeting = Greeting.make(date: context.date, firstName: firstName)
            HStack(alignment: .center, spacing: Spacing.medium) {
                Image(systemName: greeting.period.symbolName)
                    .font(.system(size: 30))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Self.tint(greeting.period))
                    .symbolEffect(.bounce, options: .nonRepeating, value: Motion.effective(motion, reduceMotion: reduceMotion) == .full ? greeting.period : nil)
                    .frame(width: 40)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                    Text(greeting.title).font(Typography.largeTitle)
                    Text(greeting.subtitle).font(Typography.body).foregroundStyle(.secondary)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
        }
    }

    private static func tint(_ period: DayPeriod) -> Color {
        switch period {
        case .morning: .orange
        case .afternoon: Hue.power.color
        case .evening: .indigo
        }
    }

    private var firstName: String? {
        settings.greetingUsesName ? Greeting.firstName(fromFullName: NSFullUserName()) : nil
    }
}
