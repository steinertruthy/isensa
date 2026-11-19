import Foundation
import iSensaCore
@testable import iSensaInsights
import Testing

@Suite("History patterns")
struct HistoryPatternTests {
    private func series(_ values: [Double]) -> [HistoryPoint] {
        values.enumerated().map { index, value in
            HistoryPoint(date: Date(timeIntervalSince1970: Double(index) * 60), minimum: value, maximum: value, average: value)
        }
    }

    private func ramp(_ count: Int, from: Double, to: Double) -> [Double] {
        (0..<count).map { from + (to - from) * Double($0) / Double(count - 1) }
    }

    @Test func tooLittleDataSaysNothing() {
        let patterns = HistoryPatternFinder.patterns(in: [.cpuTemperature: series([50, 60, 70]), .cpuUsage: series([0.1, 0.5, 0.9])])
        #expect(patterns.isEmpty)
    }

    @Test func temperatureFollowingTheCPUIsReported() {
        let usage = ramp(30, from: 0.05, to: 0.9)
        let temperature = usage.map { 45 + $0 * 40 }
        let patterns = HistoryPatternFinder.patterns(in: [.cpuTemperature: series(temperature), .cpuUsage: series(usage)])
        #expect(patterns.first == .temperatureFollowsCPU)
    }

    @Test func warmWhileIdlePointsElsewhere() {
        let usage = (0..<30).map { $0.isMultiple(of: 2) ? 0.05 : 0.08 }
        let temperature = (0..<30).map { 60 + Double($0) }   // warming independently of usage
        let patterns = HistoryPatternFinder.patterns(in: [.cpuTemperature: series(temperature), .cpuUsage: series(usage)])
        #expect(patterns.first == .warmWhileCPUIdle(peakCelsius: 89))
    }

    @Test func fansThatNeverSpinAreNoted() {
        let patterns = HistoryPatternFinder.patterns(in: [.fanSpeed(0): series(Array(repeating: 0, count: 30))])
        #expect(patterns == [.fansStayedOff])
    }

    @Test func fansFollowingTemperatureReportWhenTheyStart() {
        let temperature = ramp(30, from: 45, to: 90)
        let fan = temperature.map { $0 < 70 ? 0 : 2_300 + ($0 - 70) * 200 }
        let patterns = HistoryPatternFinder.patterns(in: [.cpuTemperature: series(temperature), .fanSpeed(0): series(fan)])
        guard case let .fansFollowTemperature(start)? = patterns.first else {
            Issue.record("Expected fansFollowTemperature, got \(patterns)")
            return
        }
        #expect(start.map { (70...73).contains($0) } == true)
    }

    @Test func thePeakCarriesTheCPUUsageAtThatMoment() {
        var temperature = Array(repeating: 50.0, count: 30)
        temperature[12] = 88
        var usage = Array(repeating: 0.1, count: 30)
        usage[12] = 0.64
        let patterns = HistoryPatternFinder.patterns(in: [.cpuTemperature: series(temperature), .cpuUsage: series(usage)])
        #expect(patterns.contains(.temperaturePeak(celsius: 88, date: Date(timeIntervalSince1970: 720), cpuUsage: 0.64)))
    }

    @Test func atMostThreePatterns() {
        let usage = ramp(30, from: 0.05, to: 0.9)
        let temperature = usage.map { 45 + $0 * 40 }
        let fan = temperature.map { $0 < 65 ? 0 : ($0 - 40) * 100 }
        let patterns = HistoryPatternFinder.patterns(in: [
            .cpuTemperature: series(temperature), .cpuUsage: series(usage), .fanSpeed(0): series(fan)
        ])
        #expect(patterns.count == 3)
    }
}
