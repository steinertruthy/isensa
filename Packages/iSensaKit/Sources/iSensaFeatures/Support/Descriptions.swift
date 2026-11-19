import iSensaCore

/// Plain-language descriptions of measured states. Each maps a documented, verifiable
/// condition to words — never an arbitrary score.
enum Descriptions {
    static func cpuLoad(_ usage: Double) -> String {
        switch usage {
        case ..<0.3: tr("Lightly used")
        case ..<0.7: tr("Moderately busy")
        default: tr("Working hard")
        }
    }

    static func memoryPressure(_ pressure: MemoryPressure) -> String {
        switch pressure {
        case .normal: tr("Memory is being managed normally")
        case .warning: tr("Memory pressure is elevated")
        case .critical: tr("Memory pressure is critical")
        }
    }

    static func memoryLevel(_ pressure: MemoryPressure) -> HealthLevel {
        switch pressure {
        case .normal: .normal
        case .warning: .attention
        case .critical: .critical
        }
    }

    static func thermal(_ level: ThermalLevel) -> String {
        switch level {
        case .nominal: tr("Temperature is within the expected range")
        case .fair: tr("Slightly warm — no impact on performance")
        case .serious: tr("Hot — macOS is reducing performance")
        case .critical: tr("Critical — performance strongly limited")
        }
    }

    /// One-word state for places where no temperature sensor is identified.
    static func thermalShort(_ level: ThermalLevel) -> String {
        switch level {
        case .nominal: tr("Normal")
        case .fair: tr("Warm")
        case .serious: tr("Hot")
        case .critical: tr("Critical")
        }
    }

    static func thermalLevel(_ level: ThermalLevel) -> HealthLevel {
        switch level {
        case .nominal, .fair: .normal
        case .serious: .attention
        case .critical: .critical
        }
    }

    static func chargeState(_ battery: BatterySnapshot) -> String {
        switch battery.state {
        case .charging: tr("Charging")
        case .discharging: tr("On battery")
        case .charged: tr("Fully charged")
        case .notCharging: tr("Connected, not charging")
        }
    }

    static func fans(_ fans: [FanReading]) -> String {
        if fans.isEmpty { return tr("No fan data") }
        if fans.allSatisfy({ $0.currentRPM < 1 }) { return tr("Stopped — no cooling needed right now") }
        return fans.allSatisfy(\.isAutomatic) ? tr("Spinning under automatic control") : tr("Under manual control")
    }

    static func provenance(_ provenance: Provenance?) -> String? {
        switch provenance {
        case .derived?: tr("Derived")
        case .estimated?: tr("Estimated")
        case .demo?: tr("Demo data")
        default: nil
        }
    }

    static func identification(_ identification: SensorIdentification) -> String {
        switch identification {
        case .verified: tr("Verified on this model")
        case .inferred: tr("Inferred, not verified")
        case .unknown: tr("Unknown")
        }
    }

    static func group(_ group: ComponentGroup) -> String {
        switch group {
        case .cpu: tr("CPU")
        case .gpu: tr("GPU")
        case .memory: tr("Memory")
        case .storage: tr("Storage")
        case .battery: tr("Battery")
        case .power: tr("Power")
        case .system: tr("System")
        case .unknown: tr("Unknown")
        }
    }
}
