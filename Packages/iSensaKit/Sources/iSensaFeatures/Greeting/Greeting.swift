import Foundation

/// Part of the day, derived from the local clock.
public enum DayPeriod: String, CaseIterable, Sendable {
    case morning, afternoon, evening

    /// Morning 05:00–11:59, afternoon 12:00–17:59, evening 18:00–04:59.
    public init(date: Date, calendar: Calendar = .autoupdatingCurrent) {
        switch calendar.component(.hour, from: date) {
        case 5..<12: self = .morning
        case 12..<18: self = .afternoon
        default: self = .evening
        }
    }

    public var symbolName: String {
        switch self {
        case .morning: "sun.max.fill"
        case .afternoon: "cloud.sun.fill"
        case .evening: "moon.stars.fill"
        }
    }
}

/// Builds the dashboard greeting. Subtitles rotate once per day to avoid repetition.
public struct Greeting: Equatable, Sendable {
    public let period: DayPeriod
    public let title: String
    public let subtitle: String

    public static func make(date: Date, firstName: String?, calendar: Calendar = .autoupdatingCurrent) -> Greeting {
        let period = DayPeriod(date: date, calendar: calendar)
        let salutation = switch period {
        case .morning: tr("Good morning")
        case .afternoon: tr("Good afternoon")
        case .evening: tr("Good evening")
        }
        let title = firstName.map { tr("%@, %@.", salutation, $0) } ?? "\(salutation)!"
        let subtitles = switch period {
        case .morning: [tr("Your Mac is ready for another day."), tr("Here is how your Mac is starting the day.")]
        case .afternoon: [tr("Shall we check on your Mac?"), tr("Here is how your Mac is doing this afternoon.")]
        case .evening: [tr("See how your Mac is behaving."), tr("Here is how your Mac is doing tonight.")]
        }
        let day = calendar.ordinality(of: .day, in: .year, for: date) ?? 0
        return Greeting(period: period, title: title, subtitle: subtitles[day % subtitles.count])
    }

    /// First name from the account's full name, only used when the user opts in.
    public static func firstName(fromFullName fullName: String) -> String? {
        let first = fullName.split(separator: " ").first.map(String.init)
        return first?.isEmpty == false ? first : nil
    }
}
