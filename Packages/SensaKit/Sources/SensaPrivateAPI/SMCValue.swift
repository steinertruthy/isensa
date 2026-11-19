import Foundation

/// Raw SMC value with its data type, plus decoding of the formats used by
/// Intel and Apple Silicon SMC firmware.
public struct SMCValue: Sendable, Equatable {
    public let key: SMCKey
    /// Four-character type, e.g. `flt `, `sp78`, `ui16`.
    public let dataType: String
    public let bytes: [UInt8]

    public init(key: SMCKey, dataType: String, bytes: [UInt8]) {
        self.key = key
        self.dataType = dataType
        self.bytes = bytes
    }

    /// Numeric interpretation, or `nil` for non-numeric/unknown types.
    public var doubleValue: Double? {
        switch dataType {
        case "flt ":
            guard bytes.count >= 4 else { return nil }
            // Apple Silicon SMC stores IEEE-754 floats little-endian.
            let raw = UInt32(bytes[0]) | UInt32(bytes[1]) << 8 | UInt32(bytes[2]) << 16 | UInt32(bytes[3]) << 24
            return Double(Float(bitPattern: raw))
        case "ui8 ", "flag":
            return bytes.first.map { Double($0) }
        case "ui16":
            return bigEndianUnsigned(2).map { Double($0) }
        case "ui32":
            return bigEndianUnsigned(4).map { Double($0) }
        case "si8 ":
            return bytes.first.map { Double(Int8(bitPattern: $0)) }
        case "si16":
            return bigEndianUnsigned(2).map { Double(Int16(truncatingIfNeeded: $0)) }
        case "sp78":
            return bigEndianUnsigned(2).map { Double(Int16(truncatingIfNeeded: $0)) / 256 }
        case "fpe2":
            return bigEndianUnsigned(2).map { Double($0) / 4 }
        case "fp88":
            return bigEndianUnsigned(2).map { Double($0) / 256 }
        case "ioft":
            // Unsigned 48.16 fixed point, little-endian, 8 bytes.
            guard bytes.count >= 8 else { return nil }
            let raw = bytes.prefix(8).enumerated().reduce(UInt64(0)) { $0 | UInt64($1.element) << (8 * UInt64($1.offset)) }
            return Double(raw) / 65_536
        default:
            return nil
        }
    }

    private func bigEndianUnsigned(_ count: Int) -> UInt64? {
        guard bytes.count >= count else { return nil }
        return bytes.prefix(count).reduce(0) { $0 << 8 | UInt64($1) }
    }
}
