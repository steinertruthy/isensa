import Foundation

public enum TemperatureUnitPreference: String, CaseIterable, Codable, Sendable {
    case celsius, fahrenheit
}

/// Locale-aware formatting of every unit Sensa displays.
public struct MetricFormatter: Sendable {
    public var locale: Locale
    public var temperatureUnit: TemperatureUnitPreference

    public init(locale: Locale = .autoupdatingCurrent, temperatureUnit: TemperatureUnitPreference = .celsius) {
        self.locale = locale
        self.temperatureUnit = temperatureUnit
    }

    public func percent(_ fraction: Double, fractionDigits: Int = 0) -> String {
        fraction.formatted(.percent.precision(.fractionLength(fractionDigits)).locale(locale))
    }

    public func bytes<T: BinaryInteger>(_ value: T) -> String {
        Int64(clamping: value).formatted(.byteCount(style: .memory).locale(locale))
    }

    public func fileBytes<T: BinaryInteger>(_ value: T) -> String {
        Int64(clamping: value).formatted(.byteCount(style: .file).locale(locale))
    }

    public func rate(_ bytesPerSecond: Double) -> String {
        "\(Int64(max(bytesPerSecond, 0)).formatted(.byteCount(style: .file, spellsOutZero: false).locale(locale)))/s"
    }

    public func temperature(_ celsius: Double, fractionDigits: Int = 0) -> String {
        let measurement = Measurement(value: celsius, unit: UnitTemperature.celsius)
        let target: UnitTemperature = temperatureUnit == .celsius ? .celsius : .fahrenheit
        return measurement.converted(to: target).formatted(
            .measurement(width: .narrow, usage: .asProvided, numberFormatStyle: .number.precision(.fractionLength(fractionDigits)))
                .locale(locale)
        ).replacingOccurrences(of: "°", with: " °").replacingOccurrences(of: "  °", with: " °")
    }

    public func rpm(_ value: Double) -> String {
        "\(Int(value.rounded()).formatted(.number.locale(locale))) rpm"
    }

    public func watts(_ value: Double, fractionDigits: Int = 1) -> String {
        "\(value.formatted(.number.precision(.fractionLength(fractionDigits)).locale(locale))) W"
    }

    public func volts(_ value: Double) -> String {
        "\(value.formatted(.number.precision(.fractionLength(2)).locale(locale))) V"
    }

    public func amperes(_ value: Double) -> String {
        "\(value.formatted(.number.precision(.fractionLength(2)).locale(locale))) A"
    }

    public func milliampereHours(_ value: Int) -> String {
        "\(value.formatted(.number.locale(locale))) mAh"
    }

    public func number(_ value: Double, fractionDigits: Int = 0) -> String {
        value.formatted(.number.precision(.fractionLength(fractionDigits)).locale(locale))
    }

    public func integer(_ value: Int) -> String {
        value.formatted(.number.locale(locale))
    }

    public func duration(minutes: Int) -> String {
        Duration.seconds(minutes * 60).formatted(.units(allowed: [.hours, .minutes], width: .abbreviated))
    }
}
