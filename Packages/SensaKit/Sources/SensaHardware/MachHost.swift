import Darwin

/// Raw cumulative tick counters for one logical CPU.
public struct CPUTicks: Sendable, Equatable {
    public var user: UInt64
    public var system: UInt64
    public var idle: UInt64
    public var nice: UInt64

    public init(user: UInt64, system: UInt64, idle: UInt64, nice: UInt64) {
        self.user = user
        self.system = system
        self.idle = idle
        self.nice = nice
    }

    public var total: UInt64 { user + system + idle + nice }
}

/// Page-based VM counters from `host_statistics64`, converted to bytes.
public struct VMStatistics: Sendable, Equatable {
    public var pageSize: UInt64
    public var free: UInt64
    public var active: UInt64
    public var inactive: UInt64
    public var speculative: UInt64
    public var wired: UInt64
    public var compressed: UInt64
    public var purgeable: UInt64
    public var external: UInt64
    public var internalPages: UInt64

    public init(
        pageSize: UInt64, free: UInt64, active: UInt64, inactive: UInt64, speculative: UInt64,
        wired: UInt64, compressed: UInt64, purgeable: UInt64, external: UInt64, internalPages: UInt64
    ) {
        self.pageSize = pageSize
        self.free = free
        self.active = active
        self.inactive = inactive
        self.speculative = speculative
        self.wired = wired
        self.compressed = compressed
        self.purgeable = purgeable
        self.external = external
        self.internalPages = internalPages
    }
}

public enum MachHost {
    /// Per-CPU cumulative ticks via `host_processor_info`.
    public static func cpuTicks() -> [CPUTicks]? {
        var processorCount: natural_t = 0
        var info: processor_info_array_t?
        var infoCount: mach_msg_type_number_t = 0
        let result = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &processorCount, &info, &infoCount)
        guard result == KERN_SUCCESS, let info else { return nil }
        defer {
            let size = vm_size_t(Int(infoCount) * MemoryLayout<integer_t>.stride)
            vm_deallocate(mach_task_self_, vm_address_t(UInt(bitPattern: info)), size)
        }
        let stride = Int(CPU_STATE_MAX)
        return (0..<Int(processorCount)).map { cpu in
            func ticks(_ state: Int32) -> UInt64 {
                // Counters are 32-bit and wrap; callers compute deltas with wrapping arithmetic.
                UInt64(UInt32(bitPattern: info[cpu * stride + Int(state)]))
            }
            return CPUTicks(
                user: ticks(CPU_STATE_USER),
                system: ticks(CPU_STATE_SYSTEM),
                idle: ticks(CPU_STATE_IDLE),
                nice: ticks(CPU_STATE_NICE)
            )
        }
    }

    public static func vmStatistics() -> VMStatistics? {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return nil }
        var pageSize: vm_size_t = 0
        host_page_size(mach_host_self(), &pageSize)
        let page = UInt64(pageSize)
        return VMStatistics(
            pageSize: page,
            free: UInt64(stats.free_count) * page,
            active: UInt64(stats.active_count) * page,
            inactive: UInt64(stats.inactive_count) * page,
            speculative: UInt64(stats.speculative_count) * page,
            wired: UInt64(stats.wire_count) * page,
            compressed: UInt64(stats.compressor_page_count) * page,
            purgeable: UInt64(stats.purgeable_count) * page,
            external: UInt64(stats.external_page_count) * page,
            internalPages: UInt64(stats.internal_page_count) * page
        )
    }

    public static func loadAverage() -> [Double] {
        var loads = [Double](repeating: 0, count: 3)
        let count = getloadavg(&loads, 3)
        return count == 3 ? loads : []
    }
}
