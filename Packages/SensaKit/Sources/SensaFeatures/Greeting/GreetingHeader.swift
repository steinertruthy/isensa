import AppKit
import SensaDesign
import SwiftUI

/// Time-aware greeting. Re-evaluated on minute boundaries, so the period switches
/// exactly at 12:00 / 18:00 / 05:00 even if the app stays open.
struct GreetingHeader: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.everyMinute) { context in
            let greeting = Greeting.make(date: context.date, firstName: firstName)
            HStack(alignment: .center, spacing: Spacing.medium) {
                Image(systemName: greeting.period.symbolName)
                    .font(.system(size: 30))
                    .symbolRenderingMode(.multicolor)
                    .symbolEffect(.bounce, options: .nonRepeating, value: reduceMotion ? nil : greeting.period)
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

    private var firstName: String? {
        settings.greetingUsesName ? Greeting.firstName(fromFullName: NSFullUserName()) : nil
    }
}
