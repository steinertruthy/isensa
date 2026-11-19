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
        // Writing fan speeds needs the privileged helper, which macOS only registers for a
        // Developer ID–signed app. Until then, control stays explicitly locked.
        states[.fanControl] = profile.fanCount > 0 ? .requiresAuthorization(.signedPrivilegedHelper) : .unavailable
        return states.compactMapValues { $0 }
    }
}
