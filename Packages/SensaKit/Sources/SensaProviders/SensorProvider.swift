import Foundation
import SensaCore
import SensaPrivateAPI

/// ⚠️ Uses PRIVATE interfaces (SMC user client, HID event system) — capability is always
/// reported as experimental. Reads temperatures, fans and total system power.
public actor SensorProvider: MetricProvider {
    public nonisolated let id = "sensors"
    public nonisolated let feature = Feature.temperatureSensors
    public nonisolated let tier = SamplingTier.medium

    private struct SMCSensor {
        let key: SMCKey
        let sensor: Sensor
        let aggregate: SensorCatalog.Aggregate?
    }

    private let profile: HardwareProfile
    private let catalog: SensorCatalog
    private var smc: SMCConnection?
    private var hid: HIDSensorClient?
    private var smcSensors: [SMCSensor] = []
    private var hidIdentities: [String: (sensor: Sensor, aggregate: SensorCatalog.Aggregate?)] = [:]
    private var fanCount = 0
    private var isDiscovered = false
    /// Full sensor list only while someone can see it; otherwise only headline sensors.
    private var readsAllSensors = true

    public init(profile: HardwareProfile) {
        self.profile = profile
        self.catalog = .bundled()
    }

    public func probe() async -> CapabilityState {
        discover()
        return smcSensors.isEmpty && (hid?.serviceCount ?? 0) == 0 ? .unsupported : .experimental(.privateInterface)
    }

    /// Number of fans the SMC reports (0 on fanless Macs).
    public func discoveredFanCount() -> Int {
        discover()
        return fanCount
    }

    public func prepare(for demand: Demand) async {
        readsAllSensors = demand == .interactive
    }

    public func sample() async throws -> any SnapshotFragment {
        discover()
        guard smc != nil || hid != nil else { throw ProviderError.interfaceUnavailable("SMC/HID") }
        var readings: [SensorReading] = []
        var aggregates: [SensorCatalog.Aggregate: [Double]] = [:]

        if let smc {
            for entry in smcSensors where readsAllSensors || entry.aggregate != nil {
                guard let value = smc.number(entry.key), Self.isPlausible(value) else { continue }
                readings.append(SensorReading(sensor: entry.sensor, value: value))
                if let aggregate = entry.aggregate { aggregates[aggregate, default: []].append(value) }
            }
        }
        if readsAllSensors { readings += hidReadings() }

        let fans = smc.map(readFans) ?? []
        let systemPower = smc?.number("PSTR").flatMap { $0 >= 0 && $0 < 1_000 ? $0 : nil }

        return SensorSnapshot(
            timestamp: Date(),
            sensors: readings,
            fans: fans,
            cpuTemperature: Self.mean(aggregates[.cpu]),
            gpuTemperature: Self.mean(aggregates[.gpu]),
            systemPower: systemPower
        )
    }

    // MARK: - Discovery

    private func discover() {
        guard !isDiscovered else { return }
        isDiscovered = true
        smc = try? SMCConnection()
        hid = HIDSensorClient()
        guard let smc else { return }
        fanCount = Int(smc.number("FNum") ?? 0)
        let count = (try? smc.keyCount()) ?? 0
        for index in 0..<count {
            guard let key = try? smc.key(at: index), key.description.hasPrefix("T"),
                  let value = try? smc.read(key), ["flt ", "sp78", "ioft"].contains(value.dataType),
                  let number = value.doubleValue, Self.isPlausible(number) else { continue }
            let identified = catalog.identify(
                SensorID(source: .smc, key: key.description), kind: .temperature,
                model: profile.modelIdentifier, family: profile.chipFamily
            )
            smcSensors.append(SMCSensor(key: key, sensor: identified.sensor, aggregate: identified.aggregate))
        }
    }

    private func hidReadings() -> [SensorReading] {
        guard let hid else { return [] }
        var values = hid.temperatures()
        if values.isEmpty {
            hid.refreshServices()
            values = hid.temperatures()
        }
        var occurrences: [String: Int] = [:]
        return values.map { value in
            // Several PMUs publish identically named sensors; keep them distinct, never merged.
            let occurrence = occurrences[value.name, default: 0] + 1
            occurrences[value.name] = occurrence
            let key = occurrence == 1 ? value.name : "\(value.name) #\(occurrence)"
            return SensorReading(sensor: hidSensor(key: key, baseName: value.name), value: value.value)
        }
    }

    private func hidSensor(key: String, baseName: String) -> Sensor {
        if let cached = hidIdentities[key] { return cached.sensor }
        let identified = catalog.identify(
            SensorID(source: .hid, key: key), kind: .temperature,
            model: profile.modelIdentifier, family: profile.chipFamily
        )
        hidIdentities[key] = identified
        return identified.sensor
    }

    private func readFans(_ smc: SMCConnection) -> [FanReading] {
        (0..<fanCount).compactMap { index in
            guard let current = smc.number(Self.fanKey(index, "Ac")) else { return nil }
            let mode = smc.number(Self.fanKey(index, "Md"))
            return FanReading(
                id: index,
                currentRPM: max(current, 0),
                minimumRPM: smc.number(Self.fanKey(index, "Mn")),
                maximumRPM: smc.number(Self.fanKey(index, "Mx")),
                targetRPM: smc.number(Self.fanKey(index, "Tg")),
                // Mode 1 is "forced/manual" on every SMC generation documented by the community;
                // automatic is 0 on Intel and 3 on M3 Pro (observed on Mac15,6).
                isAutomatic: mode.map { $0 != 1 } ?? true
            )
        }
    }

    static func fanKey(_ index: Int, _ suffix: String) -> SMCKey {
        SMCKey("F\(index)\(suffix)") ?? "F0Ac"
    }

    static func isPlausible(_ celsius: Double) -> Bool { celsius.isFinite && celsius > 0 && celsius < 130 }

    static func mean(_ values: [Double]?) -> Double? {
        guard let values, !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }
}
