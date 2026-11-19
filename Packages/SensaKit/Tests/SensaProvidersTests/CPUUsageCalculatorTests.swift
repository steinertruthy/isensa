@testable import SensaProviders
import SensaHardware
import Testing

@Suite("CPU usage calculation")
struct CPUUsageCalculatorTests {
    @Test func computesTotalsAndPerCore() throws {
        let previous = [CPUTicks(user: 0, system: 0, idle: 0, nice: 0), CPUTicks(user: 0, system: 0, idle: 0, nice: 0)]
        let current = [CPUTicks(user: 50, system: 25, idle: 25, nice: 0), CPUTicks(user: 0, system: 0, idle: 100, nice: 0)]
        let usage = try #require(CPUUsageCalculator.usage(previous: previous, current: current))
        #expect(usage.perCore == [0.75, 0])
        #expect(usage.total == 0.375)
        #expect(usage.user == 0.25)
        #expect(usage.system == 0.125)
    }

    @Test func handles32BitCounterWrap() throws {
        let previous = [CPUTicks(user: UInt64(UInt32.max - 9), system: 0, idle: 0, nice: 0)]
        let current = [CPUTicks(user: 10, system: 0, idle: 20, nice: 0)]
        let usage = try #require(CPUUsageCalculator.usage(previous: previous, current: current))
        #expect(usage.total == 0.5)
    }

    @Test func rejectsMismatchedCoreCounts() {
        #expect(CPUUsageCalculator.usage(previous: [], current: [CPUTicks(user: 1, system: 1, idle: 1, nice: 0)]) == nil)
    }
}
