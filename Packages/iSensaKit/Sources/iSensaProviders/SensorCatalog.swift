import Foundation
import iSensaCore

/// Rules that turn raw sensor keys into identified sensors, without ever inventing meaning.
///
/// A rule names a sensor only for the chip generations it lists (empty = any generation),
/// and the identification is `.verified` only on model identifiers where it was validated.
struct SensorCatalog: Sendable {
    enum Aggregate: String, Decodable, Sendable { case cpu, gpu }

    struct Rule: Decodable, Sendable {
        let source: SensorSource
        let prefix: String?
        let keys: [String]?
        let kind: SensorKind
        let group: ComponentGroup
        let name: String
        let aggregate: Aggregate?
        let generations: [Int]
        let verifiedOn: [String]

        func matches(_ key: String) -> Bool {
            if let keys { return keys.contains(key) }
            if let prefix { return key.hasPrefix(prefix) }
            return false
        }
    }

    private struct File: Decodable { let rules: [Rule] }

    let rules: [Rule]

    static func bundled() -> SensorCatalog {
        guard let url = Bundle.module.url(forResource: "SensorCatalog", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(File.self, from: data) else { return SensorCatalog(rules: []) }
        return SensorCatalog(rules: file.rules)
    }

    static func decode(_ data: Data) throws -> SensorCatalog {
        SensorCatalog(rules: try JSONDecoder().decode(File.self, from: data).rules)
    }

    /// Identifies a sensor for a given machine. Unmatched keys become `.unknown` with no name.
    func identify(_ id: SensorID, kind fallbackKind: SensorKind, model: String, family: ChipFamily) -> (sensor: Sensor, aggregate: Aggregate?) {
        let generation: Int? = if case let .appleSilicon(generation, _) = family { generation } else { nil }
        let rule = rules.first { rule in
            rule.source == id.source && rule.matches(id.key)
                && (rule.generations.isEmpty || generation.map(rule.generations.contains) == true)
        }
        guard let rule else {
            return (Sensor(id: id, kind: fallbackKind, group: .unknown, name: nil, identification: .unknown), nil)
        }
        let identification: SensorIdentification = rule.verifiedOn.contains(model)
            ? .verified(models: rule.verifiedOn)
            : .inferred
        // Aggregates (headline CPU/GPU temperature) only use mappings verified on this model.
        let aggregate = identification == .inferred ? nil : rule.aggregate
        return (Sensor(id: id, kind: rule.kind, group: rule.group, name: rule.name, identification: identification), aggregate)
    }
}
