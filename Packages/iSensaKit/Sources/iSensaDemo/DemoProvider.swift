import Foundation
import iSensaCore

/// ⚠️ DEMONSTRATION DATA. Synthetic values for previews, screenshots and UI tests.
/// Never registered alongside production providers; the UI labels demo mode explicitly.
struct DemoProvider: MetricProvider {
    let id: String
    let feature: Feature
    let tier: SamplingTier
    let make: @Sendable (_ elapsed: Double) -> any SnapshotFragment
    private let start = Date()

    func probe() async -> CapabilityState { .available }

    func sample() async throws -> any SnapshotFragment {
        make(Date().timeIntervalSince(start))
    }
}

/// Smooth, deterministic pseudo-activity in `0...1`.
func wave(_ t: Double, period: Double, phase: Double = 0, base: Double, amplitude: Double) -> Double {
    min(max(base + amplitude * sin((t / period + phase) * 2 * .pi), 0), 1)
}
