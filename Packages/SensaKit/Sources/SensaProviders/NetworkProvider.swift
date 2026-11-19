import Foundation
import SensaCore
import SensaHardware

/// Interface list and throughput from 64-bit routing-socket counters. No packet inspection.
public actor NetworkProvider: MetricProvider {
    public nonisolated let id = "network"
    public nonisolated let feature = Feature.network
    public nonisolated let tier = SamplingTier.fast

    private var previous: (date: Date, received: UInt64, sent: UInt64)?

    public init() {}

    public func probe() async -> CapabilityState {
        NetworkCounters.interfaces().isEmpty ? .unsupported : .available
    }

    public func sample() async throws -> any SnapshotFragment {
        let now = Date()
        let interfaces = NetworkCounters.interfaces().map(Self.interface)
        let counted = interfaces.filter { $0.kind != .loopback && $0.isActive }
        let received = counted.reduce(UInt64(0)) { $0 &+ $1.totalReceived }
        let sent = counted.reduce(UInt64(0)) { $0 &+ $1.totalSent }
        let rates = previous.flatMap { RateCalculator.rates(from: ($0.received, $0.sent), to: (received, sent), over: now.timeIntervalSince($0.date)) }
        previous = (now, received, sent)
        return NetworkSnapshot(timestamp: now, interfaces: interfaces, downloadRate: rates?.first, uploadRate: rates?.second)
    }

    static func interface(_ counters: InterfaceCounters) -> NetworkInterfaceInfo {
        NetworkInterfaceInfo(
            id: counters.name,
            kind: kind(of: counters),
            isActive: counters.isUp,
            ipv4Addresses: counters.ipv4,
            ipv6Addresses: counters.ipv6.filter { !$0.hasPrefix("fe80") },
            totalReceived: counters.bytesIn,
            totalSent: counters.bytesOut
        )
    }

    /// `IFT_*` values from `<net/if_types.h>`. Wi-Fi reports as Ethernet (IFT_ETHER) at this
    /// level, so the BSD name of the built-in Wi-Fi port (`en0` on laptops) is resolved separately.
    static func kind(of counters: InterfaceCounters) -> NetworkInterfaceKind {
        if counters.isLoopback { return .loopback }
        switch Int32(counters.interfaceType) {
        case 0x06 where WiFiInterface.names.contains(counters.name): return .wifi
        case 0x06: return counters.name.hasPrefix("en") ? .ethernet : .other
        case 0xFF: return .cellular
        default: return .other
        }
    }
}
