// swift-tools-version: 6.0
import PackageDescription

/// SensaKit — every layer of Sensa except the app's composition root.
///
/// Dependency rule (enforced by target graph):
///   SensaCore            ← pure domain, Foundation only
///   SensaHardware        ← public macOS APIs (sysctl, Mach, IOKit registry, IOPowerSources)
///   SensaPrivateAPI      ← undocumented interfaces (SMC, HID sensors, IOReport). Isolated on purpose.
///   SensaProviders       ← adapts Hardware/PrivateAPI to Core contracts
///   SensaMonitoring      ← sampling engine and observable store (Core only)
///   SensaPersistence     ← local SQLite history (Core only)
///   SensaInsights        ← health rules (Core only)
///   SensaControl         ← fan control: curves, validation, safety core, helper protocol (Core only)
///   SensaDesign          ← design system (SwiftUI, Core for semantic levels)
///   SensaFeatures        ← screens and view models (never imports hardware layers)
///   SensaDemo            ← clearly-labelled demonstration providers
let package = Package(
    name: "SensaKit",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "SensaCore", targets: ["SensaCore"]),
        .library(name: "SensaProviders", targets: ["SensaProviders"]),
        .library(name: "SensaMonitoring", targets: ["SensaMonitoring"]),
        .library(name: "SensaInsights", targets: ["SensaInsights"]),
        .library(name: "SensaDesign", targets: ["SensaDesign"]),
        .library(name: "SensaFeatures", targets: ["SensaFeatures"]),
        .library(name: "SensaDemo", targets: ["SensaDemo"]),
        .library(name: "SensaPersistence", targets: ["SensaPersistence"]),
        .library(name: "SensaControl", targets: ["SensaControl"]),
        .library(name: "SensaPrivateAPI", targets: ["SensaPrivateAPI"]),
        .executable(name: "sensa-probe", targets: ["SensaProbe"])
    ],
    targets: [
        .target(name: "SensaCore"),

        .target(name: "CSensaHardware", linkerSettings: [.linkedFramework("IOKit"), .linkedFramework("CoreFoundation")]),
        .target(
            name: "SensaHardware",
            dependencies: ["CSensaHardware"],
            linkerSettings: [.linkedFramework("IOKit")]
        ),

        .target(name: "CSensaPrivate"),
        .target(
            name: "SensaPrivateAPI",
            dependencies: ["CSensaPrivate", "SensaHardware"],
            linkerSettings: [.linkedFramework("IOKit")]
        ),

        .target(
            name: "SensaProviders",
            dependencies: ["SensaCore", "SensaHardware", "SensaPrivateAPI"],
            resources: [.process("Resources")],
            linkerSettings: [.linkedFramework("CoreWLAN")]
        ),

        .target(name: "SensaMonitoring", dependencies: ["SensaCore"]),
        .target(name: "SensaPersistence", dependencies: ["SensaCore"], linkerSettings: [.linkedLibrary("sqlite3")]),
        .target(name: "SensaInsights", dependencies: ["SensaCore"]),
        .target(name: "SensaControl", dependencies: ["SensaCore"]),
        .target(name: "SensaDesign", dependencies: ["SensaCore"]),
        .target(name: "SensaDemo", dependencies: ["SensaCore", "SensaControl"]),

        .target(
            name: "SensaFeatures",
            dependencies: ["SensaCore", "SensaMonitoring", "SensaInsights", "SensaDesign", "SensaControl"],
            resources: [.process("Resources")]
        ),

        .executableTarget(
            name: "SensaProbe",
            dependencies: ["SensaCore", "SensaHardware", "SensaPrivateAPI", "SensaProviders"],
            path: "Sources/Tools/SensaProbe"
        ),

        .testTarget(name: "SensaCoreTests", dependencies: ["SensaCore"]),
        .testTarget(name: "SensaHardwareTests", dependencies: ["SensaHardware", "SensaPrivateAPI"]),
        .testTarget(name: "SensaProvidersTests", dependencies: ["SensaProviders", "SensaCore"]),
        .testTarget(name: "SensaMonitoringTests", dependencies: ["SensaMonitoring", "SensaCore"]),
        .testTarget(name: "SensaInsightsTests", dependencies: ["SensaInsights", "SensaCore"]),
        .testTarget(name: "SensaControlTests", dependencies: ["SensaControl", "SensaCore"]),
        .testTarget(name: "SensaPersistenceTests", dependencies: ["SensaPersistence", "SensaCore"]),
        .testTarget(name: "SensaFeaturesTests", dependencies: ["SensaFeatures", "SensaCore", "SensaDemo", "SensaMonitoring", "SensaDesign", "SensaInsights", "SensaControl"])
    ]
)
