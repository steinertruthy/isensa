import Darwin
import Foundation

/// Cumulative resource counters of one process (public `libproc`).
public struct ProcessCounters: Sendable, Equatable {
    public var pid: Int32
    /// Identifies this process instance (guards against PID reuse).
    public var startTime: UInt64
    /// User + system CPU time, nanoseconds.
    public var cpuTime: UInt64
    public var physicalFootprint: UInt64
    /// Bytes this process has read from and written to storage (Activity Monitor's Disk tab).
    public var diskBytesRead: UInt64
    public var diskBytesWritten: UInt64
    // `ri_billed_energy` is not read: on macOS 26 (Mac15,6) it stays 0 for every process.

    public init(
        pid: Int32, startTime: UInt64, cpuTime: UInt64, physicalFootprint: UInt64, diskBytesRead: UInt64 = 0, diskBytesWritten: UInt64 = 0
    ) {
        self.pid = pid
        self.startTime = startTime
        self.cpuTime = cpuTime
        self.physicalFootprint = physicalFootprint
        self.diskBytesRead = diskBytesRead
        self.diskBytesWritten = diskBytesWritten
    }
}

public enum ProcessTable {
    /// All PIDs currently known to the kernel.
    public static func allPIDs() -> [Int32] {
        let capacity = Int(proc_listallpids(nil, 0)) + 64
        guard capacity > 64 else { return [] }
        var pids = [Int32](repeating: 0, count: capacity)
        let count = Int(proc_listallpids(&pids, Int32(capacity * MemoryLayout<Int32>.size)))
        return Array(pids.prefix(max(count, 0))).filter { $0 > 0 }
    }

    /// Resource usage, or `nil` for processes this user may not inspect (other users, root).
    public static func counters(pid: Int32) -> ProcessCounters? {
        var info = rusage_info_v4()
        let result = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(to: rusage_info_t?.self, capacity: 1) {
                proc_pid_rusage(pid, RUSAGE_INFO_V4, $0)
            }
        }
        guard result == 0 else { return nil }
        let timebase = Self.timebase
        let machTime = info.ri_user_time &+ info.ri_system_time
        return ProcessCounters(
            pid: pid,
            startTime: info.ri_proc_start_abstime,
            cpuTime: machTime.multipliedReportingOverflow(by: UInt64(timebase.numer)).partialValue / UInt64(max(timebase.denom, 1)),
            physicalFootprint: info.ri_phys_footprint,
            diskBytesRead: info.ri_diskio_bytesread,
            diskBytesWritten: info.ri_diskio_byteswritten
        )
    }

    /// Display name: the `.app` bundle name when the executable lives in one, else the process name.
    public static func name(pid: Int32) -> String {
        var path = [CChar](repeating: 0, count: Int(MAXPATHLEN) * 4)
        if proc_pidpath(pid, &path, UInt32(path.count)) > 0, let full = CString.decode(path) {
            return displayName(forExecutablePath: full)
        }
        var name = [CChar](repeating: 0, count: 2 * Int(MAXCOMLEN) + 1)
        proc_name(pid, &name, UInt32(name.count))
        return CString.decode(name).flatMap { $0.isEmpty ? nil : $0 } ?? "\(pid)"
    }

    /// `/Applications/Safari.app/Contents/MacOS/Safari` → `Safari`; helpers keep their own bundle name.
    public static func displayName(forExecutablePath path: String) -> String {
        let components = path.split(separator: "/")
        if let bundle = components.last(where: { $0.hasSuffix(".app") }) {
            return String(bundle.dropLast(4))
        }
        return components.last.map(String.init) ?? path
    }

    private static let timebase: mach_timebase_info_data_t = {
        var info = mach_timebase_info_data_t()
        mach_timebase_info(&info)
        return info
    }()
}
