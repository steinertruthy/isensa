import Darwin
import Foundation

/// 64-bit byte counters and addresses per network interface.
public struct InterfaceCounters: Sendable, Equatable {
    public var name: String
    public var isUp: Bool
    public var isLoopback: Bool
    public var interfaceType: UInt8
    public var bytesIn: UInt64
    public var bytesOut: UInt64
    public var ipv4: [String]
    public var ipv6: [String]
}

public enum NetworkCounters {
    /// Uses `NET_RT_IFLIST2` because `getifaddrs`' `if_data` counters are 32-bit and wrap at 4 GB.
    public static func interfaces() -> [InterfaceCounters] {
        var result: [String: InterfaceCounters] = [:]
        var order: [String] = []

        for entry in linkCounters() {
            result[entry.name] = entry
            order.append(entry.name)
        }
        for (name, addresses) in addresses() {
            result[name]?.ipv4 = addresses.v4
            result[name]?.ipv6 = addresses.v6
        }
        return order.compactMap { result[$0] }
    }

    private static func linkCounters() -> [InterfaceCounters] {
        var mib: [Int32] = [CTL_NET, PF_ROUTE, 0, 0, NET_RT_IFLIST2, 0]
        var length = 0
        guard sysctl(&mib, UInt32(mib.count), nil, &length, nil, 0) == 0, length > 0 else { return [] }
        var buffer = [UInt8](repeating: 0, count: length)
        guard sysctl(&mib, UInt32(mib.count), &buffer, &length, nil, 0) == 0 else { return [] }

        var interfaces: [InterfaceCounters] = []
        buffer.withUnsafeBytes { raw in
            var offset = 0
            while offset + MemoryLayout<if_msghdr>.size <= length {
                let header = raw.loadUnaligned(fromByteOffset: offset, as: if_msghdr.self)
                defer { offset += Int(header.ifm_msglen) }
                guard header.ifm_msglen > 0 else { break }
                guard Int32(header.ifm_type) == RTM_IFINFO2 else { continue }
                let message = raw.loadUnaligned(fromByteOffset: offset, as: if_msghdr2.self)
                var nameBuffer = [CChar](repeating: 0, count: Int(IF_NAMESIZE) + 1)
                guard if_indextoname(UInt32(message.ifm_index), &nameBuffer) != nil else { continue }
                guard let name = CString.decode(nameBuffer) else { continue }
                let flags = Int32(message.ifm_flags)
                interfaces.append(InterfaceCounters(
                    name: name,
                    isUp: flags & IFF_UP != 0 && flags & IFF_RUNNING != 0,
                    isLoopback: flags & IFF_LOOPBACK != 0,
                    interfaceType: message.ifm_data.ifi_type,
                    bytesIn: message.ifm_data.ifi_ibytes,
                    bytesOut: message.ifm_data.ifi_obytes,
                    ipv4: [],
                    ipv6: []
                ))
            }
        }
        return interfaces
    }

    private static func addresses() -> [String: (v4: [String], v6: [String])] {
        var head: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&head) == 0, let first = head else { return [:] }
        defer { freeifaddrs(head) }
        var result: [String: (v4: [String], v6: [String])] = [:]
        for pointer in sequence(first: first, next: { $0.pointee.ifa_next }) {
            guard let address = pointer.pointee.ifa_addr else { continue }
            let family = Int32(address.pointee.sa_family)
            guard family == AF_INET || family == AF_INET6 else { continue }
            var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            let length = socklen_t(address.pointee.sa_len)
            guard getnameinfo(address, length, &host, socklen_t(host.count), nil, 0, NI_NUMERICHOST) == 0 else { continue }
            let name = String(cString: pointer.pointee.ifa_name)
            guard let text = CString.decode(host) else { continue }
            var entry = result[name] ?? ([], [])
            if family == AF_INET { entry.v4.append(text) } else { entry.v6.append(text) }
            result[name] = entry
        }
        return result
    }
}
