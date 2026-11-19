import SwiftUI

/// Label/value row for technical details. Values are selectable for copy-paste.
public struct InfoRow: View {
    private let label: String
    private let value: String
    private let help: String?

    public init(_ label: String, value: String, help: String? = nil) {
        self.label = label
        self.value = value
        self.help = help
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label).foregroundStyle(.secondary)
            if let help {
                Image(systemName: "questionmark.circle")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .help(help)
                    .accessibilityHidden(true)
            }
            Spacer(minLength: Spacing.large)
            Text(value)
                .monospacedDigit()
                .multilineTextAlignment(.trailing)
                .textSelection(.enabled)
        }
        .font(Typography.callout)
        .padding(.vertical, Spacing.xxSmall)
        .accessibilityElement(children: .combine)
        .accessibilityHint(help ?? "")
    }
}
