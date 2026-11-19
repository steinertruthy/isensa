import Darwin

/// Typed access to `sysctlbyname`. Returns `nil` when a key does not exist on this Mac
/// (e.g. `hw.perflevel1.*` on Intel), which callers treat as "capability absent".
public enum Sysctl {
    public static func string(_ name: String) -> String? {
        var size = 0
        guard sysctlbyname(name, nil, &size, nil, 0) == 0, size > 0 else { return nil }
        var buffer = [CChar](repeating: 0, count: size)
        guard sysctlbyname(name, &buffer, &size, nil, 0) == 0 else { return nil }
        return CString.decode(buffer)
    }

    public static func int32(_ name: String) -> Int32? { value(name) }
    public static func int64(_ name: String) -> Int64? { value(name) }
    public static func uint64(_ name: String) -> UInt64? { value(name) }

    public static func int(_ name: String) -> Int? {
        if let value: Int64 = value(name) { return Int(value) }
        if let value: Int32 = value(name) { return Int(value) }
        return nil
    }

    public static func value<T>(_ name: String) -> T? {
        var size = MemoryLayout<T>.size
        let pointer = UnsafeMutablePointer<T>.allocate(capacity: 1)
        defer { pointer.deallocate() }
        guard sysctlbyname(name, pointer, &size, nil, 0) == 0, size == MemoryLayout<T>.size else { return nil }
        return pointer.pointee
    }

    public static func swapUsage() -> xsw_usage? { value("vm.swapusage") }
}
