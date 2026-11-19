import Foundation
import SensaCore

/// Composition helper: the real providers for this Mac plus capabilities that are
/// decided by discovery rather than by a provider probe.
public enum ProductionProviders {
    public static func make(for profile: HardwareProfile) -> [any MetricProvider] {
        var providers: [any MetricProvider] = [
            CPUUsageProvider(topology: profile.cpu),
            GPUProvider(),
            MemoryProvider(physicalMemory: profile.physicalMemory),
            ThermalStateProvider(),
            SensorProvider(profile: profile),
            StorageProvider(),
            NetworkProvider(),
            ProcessProvider(),
            WiFiProvider()
        ]
        // IOReport frequency/energy data exists only on Apple silicon.
        if profile.chipFamily.isAppleSilicon {
            providers += [PerformanceProvider(), EnergyProvider()] as [any MetricProvider]
        }
        if profile.hasBattery { providers.append(BatteryProvider()) }
        return providers
    }

    /// Capabilities for features that have no provider of their own.
    public static func staticCapabilities(for profile: HardwareProfile) -> [Feature: CapabilityState] {
        var states: [Feature: CapabilityState] = [:]
        states[.battery] = profile.hasBattery ? nil : .unavailable
        states[.powerAdapter] = profile.hasBattery ? .available : .unavailable
        states[.fans] = profile.fanCount > 0 ? .experimental(.privateInterface) : .unavailable
        // Writing fan speeds goes through undocumented SMC keys and a privileged helper the user installs.
        states[.fanControl] = profile.fanCount > 0 ? .experimental(.privateInterface) : .unavailable
        return states.compactMapValues { $0 }
    }
}
