import SensaCore
import SwiftUI

public extension HealthLevel {
    /// Semantic tint. Always paired with a symbol and text — color is never the only signal.
    var tint: Color {
        switch self {
        case .normal: .green
        case .attention: .orange
        case .critical: .red
        }
    }

    var symbolName: String {
        switch self {
        case .normal: "checkmark.circle.fill"
        case .attention: "exclamationmark.circle.fill"
        case .critical: "exclamationmark.triangle.fill"
        }
    }
}

public extension ComponentGroup {
    var symbolName: String {
        switch self {
        case .cpu: "cpu"
        case .gpu: "square.stack.3d.up"
        case .memory: "memorychip"
        case .storage: "internaldrive"
        case .battery: "battery.75percent"
        case .power: "bolt"
        case .system: "desktopcomputer"
        case .unknown: "questionmark.circle"
        }
    }
}
