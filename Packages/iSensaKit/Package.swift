// swift-tools-version: 6.0
import PackageDescription

/// iSensaKit — every layer of iSensa except the app's composition root.
///
/// Dependency rule (enforced by target graph):
///   iSensaCore            ← pure domain, Foundation only
///   iSensaHardware        ← public macOS APIs (sysctl, Mach, IOKit registry, IOPowerSources)
///   iSensaPrivateAPI      ← undocumented interfaces (SMC, HID sensors, IOReport). Isolated on purpose.
///   iSensaProviders       ← adapts Hardware/PrivateAPI to Core contracts
///   iSensaMonitoring      ← sampling engine and observable store (Core only)
///   iSensaPersistence     ← local SQLite history (Core only)
///   iSensaInsights        ← health rules (Core only)
///   iSensaControl         ← fan control: curves, validation, safety core, helper protocol (Core only)
///   iSensaDesign          ← design system (SwiftUI, Core for semantic levels)
///   iSensaFeatures        ← screens and view models (never imports hardware layers)
///   iSensaDemo            ← clearly-labelled demonstration providers
let package = Package(
    name: "iSensaKit",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "iSensaCore", targets: ["iSensaCore"]),
        .library(name: "iSensaProviders", targets: ["iSensaProviders"]),
        .library(name: "iSensaMonitoring", targets: ["iSensaMonitoring"]),
        .library(name: "iSensaInsights", targets: ["iSensaInsights"]),
        .library(name: "iSensaDesign", targets: ["iSensaDesign"]),
        .library(name: "iSensaFeatures", targets: ["iSensaFeatures"]),
        .library(name: "iSensaDemo", targets: ["iSensaDemo"]),
        .library(name: "iSensaPersistence", targets: ["iSensaPersistence"]),
        .library(name: "iSensaControl", targets: ["iSensaControl"]),
        .library(name: "iSensaPrivateAPI", targets: ["iSensaPrivateAPI"]),
        .executable(name: "isensa-probe", targets: ["iSensaProbe"])
    ],
    targets: [
        .target(name: "iSensaCore"),

        .target(name: "CiSensaHardware", linkerSettings: [.linkedFramework("IOKit"), .linkedFramework("CoreFoundation")]),
        .target(
            name: "iSensaHardware",
            dependencies: ["CiSensaHardware"],
            linkerSettings: [.linkedFramework("IOKit")]
        ),

        .target(name: "CiSensaPrivate"),
        .target(
            name: "iSensaPrivateAPI",
            dependencies: ["CiSensaPrivate", "iSensaHardware"],
            linkerSettings: [.linkedFramework("IOKit")]
        ),

        .target(
            name: "iSensaProviders",
            dependencies: ["iSensaCore", "iSensaHardware", "iSensaPrivateAPI"],
            resources: [.process("Resources")],
            linkerSettings: [.linkedFramework("CoreWLAN")]
        ),

        .target(name: "iSensaMonitoring", dependencies: ["iSensaCore"]),
        .target(name: "iSensaPersistence", dependencies: ["iSensaCore"], linkerSettings: [.linkedLibrary("sqlite3")]),
        .target(name: "iSensaInsights", dependencies: ["iSensaCore"]),
        .target(name: "iSensaControl", dependencies: ["iSensaCore"]),
        .target(name: "iSensaDesign", dependencies: ["iSensaCore"]),
        .target(name: "iSensaDemo", dependencies: ["iSensaCore", "iSensaControl"]),

        .target(
            name: "iSensaFeatures",
            dependencies: ["iSensaCore", "iSensaMonitoring", "iSensaInsights", "iSensaDesign", "iSensaControl"],
            resources: [.process("Resources")]
        ),

        .executableTarget(
            name: "iSensaProbe",
            dependencies: ["iSensaCore", "iSensaHardware", "iSensaPrivateAPI", "iSensaProviders"],
            path: "Sources/Tools/iSensaProbe"
        ),

        .testTarget(name: "iSensaCoreTests", dependencies: ["iSensaCore"]),
        .testTarget(name: "iSensaHardwareTests", dependencies: ["iSensaHardware", "iSensaPrivateAPI"]),
        .testTarget(name: "iSensaProvidersTests", dependencies: ["iSensaProviders", "iSensaCore"]),
        .testTarget(name: "iSensaMonitoringTests", dependencies: ["iSensaMonitoring", "iSensaCore"]),
        .testTarget(name: "iSensaInsightsTests", dependencies: ["iSensaInsights", "iSensaCore"]),
        .testTarget(name: "iSensaControlTests", dependencies: ["iSensaControl", "iSensaCore"]),
        .testTarget(name: "iSensaPersistenceTests", dependencies: ["iSensaPersistence", "iSensaCore"]),
        .testTarget(name: "iSensaFeaturesTests", dependencies: ["iSensaFeatures", "iSensaCore", "iSensaDemo", "iSensaMonitoring", "iSensaDesign", "iSensaInsights", "iSensaControl"])
    ]
)
