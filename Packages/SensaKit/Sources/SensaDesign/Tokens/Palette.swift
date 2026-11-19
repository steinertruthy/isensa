import AppKit
import SensaCore
import SwiftUI

/// One hue per component, used everywhere that component's data appears (sidebar icon,
/// charts, gauges, popover). Chrome never uses these; status has its own channel.
public enum Hue: String, CaseIterable, Sendable {
    case cpu, gpu, memory, thermal, power, battery, fans, network, storage, neutral

    public var color: Color {
        switch self {
        case .cpu: Color(nsColor: .systemBlue)
        case .gpu: Color(nsColor: .systemPurple)
        case .memory: Color(nsColor: .systemMint)
        case .thermal: Color(nsColor: .systemOrange)
        case .power: Self.amber
        case .battery: Color(nsColor: .systemGreen)
        case .fans: Color(nsColor: .systemCyan)
        case .network: Color(nsColor: .systemIndigo)
        case .storage: Color(nsColor: .systemBrown)
        case .neutral: Color(nsColor: .systemGray)
        }
    }

    /// systemYellow is illegible as a line on white; amber keeps the same identity in light mode.
    private static let amber = Color(nsColor: NSColor(name: "SensaAmber") { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(srgbRed: 1, green: 0.839, blue: 0.039, alpha: 1)
            : NSColor(srgbRed: 0.761, green: 0.486, blue: 0, alpha: 1)
    })
}

public extension ComponentGroup {
    var hue: Hue {
        switch self {
        case .cpu: .cpu
        case .gpu: .gpu
        case .memory: .memory
        case .storage: .storage
        case .battery: .battery
        case .power: .power
        case .system, .unknown: .neutral
        }
    }
}
