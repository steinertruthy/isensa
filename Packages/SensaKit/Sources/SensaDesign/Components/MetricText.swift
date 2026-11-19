import SwiftUI

/// A typeset measurement: the number in the number voice, its unit smaller and secondary.
/// `48 °C` renders as **48** °C. Strings without a leading number render unchanged.
public struct MetricText: View {
    public enum Size {
        case hero, large, medium, small

        var points: CGFloat {
            switch self {
            case .hero: 46
            case .large: 28
            case .medium: 20
            case .small: 15
            }
        }
    }

    private let text: String
    private let size: Size
    private let minimumScale: CGFloat
    private let rolls: Bool

    /// - Parameters:
    ///   - minimumScale: how far a value may shrink before it truncates; lower it only for
    ///     long compound values (e.g. download and upload rates) in narrow places.
    ///   - rolls: digits roll to each new value. Only for values that change rarely (battery charge):
    ///     on a value refreshed every second, the roll redraws its whole surface for most of that
    ///     second — measured at 7 points of CPU on the overview for two numbers.
    public init(_ text: String, size: Size = .large, minimumScale: CGFloat = 0.6, rolls: Bool = false) {
        self.text = text
        self.size = size
        self.minimumScale = minimumScale
        self.rolls = rolls
    }

    public var body: some View {
        let parts = Self.split(text)
        Group {
            if parts.unit.isEmpty {
                Text(parts.number).font(Typography.number(size.points))
            } else {
                Text(parts.number).font(Typography.number(size.points))
                    + Text(verbatim: parts.unit.hasPrefix("%") ? "" : "\u{2009}")
                    + Text(parts.unit).font(Typography.number(size.points * 0.55, weight: .medium)).foregroundStyle(.secondary)
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(minimumScale)
        // Headline digits roll to their new value; with reduced or no motion they crossfade or swap instantly.
        .contentTransition(rolls ? .numericText() : .identity)
        .sensaAnimation(Motion.digits, value: rolls ? text : "")
        .accessibilityLabel(text)
    }

    /// Splits `"13,07 GB"` → (`"13,07"`, `"GB"`), `"7%"` → (`"7"`, `"%"`). Locale-agnostic:
    /// a number is any leading run of digits and their grouping/decimal separators.
    nonisolated static func split(_ text: String) -> (number: String, unit: String) {
        let characters = Array(text.trimmingCharacters(in: .whitespaces))
        let separators: Set<Character> = [".", ",", "\u{00A0}", "\u{202F}", "'", "’", " ", "−", "-", "+"]
        var index = 0
        var sawDigit = false
        while index < characters.count {
            let character = characters[index]
            if character.isNumber {
                sawDigit = true
                index += 1
                continue
            }
            let nextIsDigit = index + 1 < characters.count && characters[index + 1].isNumber
            let isSign = "−-+".contains(character)
            if separators.contains(character), nextIsDigit, sawDigit || isSign {
                index += 1
                continue
            }
            break
        }
        let whole = String(characters)
        guard sawDigit else { return (whole, "") }
        let unit = String(characters[index...]).trimmingCharacters(in: .whitespaces)
        return (String(characters[..<index]).trimmingCharacters(in: .whitespaces), unit)
    }
}
