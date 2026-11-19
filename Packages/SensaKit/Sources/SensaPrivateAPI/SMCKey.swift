import Foundation

/// Four-character SMC key such as `Tp01` or `F0Ac`, encoded as a big-endian `UInt32`.
public struct SMCKey: Hashable, Sendable, CustomStringConvertible, ExpressibleByStringLiteral {
    public let code: UInt32

    public init(code: UInt32) { self.code = code }

    /// Returns `nil` unless `string` is exactly four ASCII characters.
    public init?(_ string: String) {
        let bytes = Array(string.utf8)
        guard bytes.count == 4 else { return nil }
        code = bytes.reduce(0) { ($0 << 8) | UInt32($1) }
    }

    public init(stringLiteral value: String) {
        guard let key = SMCKey(value) else { preconditionFailure("SMC keys are exactly 4 ASCII characters: \(value)") }
        self = key
    }

    public var description: String { Self.fourCharacterString(code) }

    static func fourCharacterString(_ code: UInt32) -> String {
        let bytes = [24, 16, 8, 0].map { UInt8((code >> $0) & 0xFF) }
        return String(bytes: bytes, encoding: .ascii) ?? "????"
    }
}
