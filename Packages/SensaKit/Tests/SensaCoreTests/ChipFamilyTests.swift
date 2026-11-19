import SensaCore
import Testing

@Suite("Chip family parsing")
struct ChipFamilyTests {
    @Test(arguments: [
        ("Apple M3 Pro", ChipFamily.appleSilicon(generation: 3, tier: .pro)),
        ("Apple M1", .appleSilicon(generation: 1, tier: .base)),
        ("Apple M4 Max", .appleSilicon(generation: 4, tier: .max)),
        ("Apple M2 Ultra", .appleSilicon(generation: 2, tier: .ultra)),
        ("Apple M5", .appleSilicon(generation: 5, tier: .base)),
        ("Intel(R) Core(TM) i9-9880H CPU @ 2.30GHz", .intel),
        ("Mystery Processor", .unknown)
    ])
    func parses(brand: String, expected: ChipFamily) {
        #expect(ChipFamily(brandString: brand) == expected)
    }
}

@Suite("CPU topology")
struct CPUTopologyTests {
    @Test func appleSiliconNumbersEfficiencyCoresFirst() {
        let topology = CPUTopology(physicalCores: 11, logicalCores: 11, performanceCores: 5, efficiencyCores: 6)
        #expect(topology.kind(ofCore: 0) == .efficiency)
        #expect(topology.kind(ofCore: 5) == .efficiency)
        #expect(topology.kind(ofCore: 6) == .performance)
        #expect(topology.kind(ofCore: 10) == .performance)
    }

    @Test func uniformWhenLevelsUnknown() {
        let topology = CPUTopology(physicalCores: 8, logicalCores: 16, performanceCores: nil, efficiencyCores: nil)
        #expect(topology.kind(ofCore: 3) == .uniform)
    }
}
