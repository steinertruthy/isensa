/// Decoding of fixed-size C character buffers returned by system calls.
public enum CString {
    /// Decodes up to the first NUL byte as UTF-8. Invalid sequences yield `nil`.
    public static func decode(_ characters: [CChar]) -> String? {
        decode(bytes: characters.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) })
    }

    public static func decode<Bytes: Sequence<UInt8>>(bytes: Bytes) -> String? {
        String(bytes: Array(bytes.prefix { $0 != 0 }), encoding: .utf8)
    }
}
