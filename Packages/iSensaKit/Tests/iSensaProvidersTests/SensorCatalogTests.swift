import Foundation
@testable import iSensaProviders
import iSensaCore
import Testing

@Suite("Sensor catalog")
struct SensorCatalogTests {
    private let m3 = ChipFamily.appleSilicon(generation: 3, tier: .pro)

    @Test func verifiedOnlyOnValidatedModel() {
        let catalog = SensorCatalog.bundled()
        let validated = catalog.identify(SensorID(source: .smc, key: "Tp0D"), kind: .temperature, model: "Mac15,6", family: m3)
        #expect(validated.sensor.identification == .verified(models: ["Mac15,6"]))
        #expect(validated.aggregate == .cpu)

        let otherM3 = catalog.identify(SensorID(source: .smc, key: "Tp0D"), kind: .temperature, model: "Mac15,3", family: m3)
        #expect(otherM3.sensor.identification == .inferred)
        #expect(otherM3.aggregate == nil, "Unverified mappings never feed headline temperatures")
    }

    @Test func otherGenerationsAreUnknown() {
        let catalog = SensorCatalog.bundled()
        let m1 = catalog.identify(
            SensorID(source: .smc, key: "Tp0D"),
            kind: .temperature,
            model: "MacBookPro17,1",
            family: .appleSilicon(generation: 1, tier: .base)
        )
        #expect(m1.sensor.identification == .unknown)
        #expect(m1.sensor.name == nil)
    }

    @Test func unmatchedKeysKeepRawIdentifier() {
        let catalog = SensorCatalog.bundled()
        let result = catalog.identify(SensorID(source: .smc, key: "TVHC"), kind: .temperature, model: "Mac15,6", family: m3)
        #expect(result.sensor.identification == .unknown)
        #expect(result.sensor.id.key == "TVHC")
        #expect(result.sensor.group == .unknown)
    }

    @Test func bundledCatalogDecodes() {
        #expect(!SensorCatalog.bundled().rules.isEmpty)
    }
}
