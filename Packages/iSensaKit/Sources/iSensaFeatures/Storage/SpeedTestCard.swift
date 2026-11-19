import iSensaCore
import iSensaDesign
import SwiftUI

/// A sequential read and write test the person starts on purpose, on a disk they choose.
struct SpeedTestCard: View {
    static let testBytes = 2 << 30

    @Environment(\.services) private var services
    let volumes: [VolumeInfo]
    let formatter: MetricFormatter

    @State private var selection: String?
    @State private var progress: DiskSpeedProgress?
    @State private var results: [String: DiskSpeedResult] = [:]
    @State private var failure: String?
    @State private var running: Task<Void, Never>?
    /// Identifies the run in progress, so a progress update that arrives late is ignored.
    @State private var runID: UUID?

    var body: some View {
        if let tester = services.storage.speedTester {
            Card(tr("Speed test")) {
                Text(Copy.speedTestExplanation)
                    .font(Typography.caption).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: Spacing.medium) {
                    Picker(tr("Disk"), selection: $selection) {
                        ForEach(volumes) { volume in Text(volume.name).tag(Optional(volume.id)) }
                    }
                    .labelsHidden()
                    .fixedSize()
                    .disabled(running != nil)
                    Spacer()
                    if running != nil {
                        Button(tr("Stop")) { running?.cancel() }
                    } else {
                        Button(tr("Test Speed")) { start(tester) }
                            .disabled(selected.map { !Self.hasRoom($0) } ?? true)
                            .accessibilityIdentifier("storage.speed.start")
                    }
                }
                if let progress {
                    ProgressView(value: progress.fraction) {
                        Text(progress.phase == .writing ? tr("Writing…") : tr("Reading…")).font(Typography.caption)
                    }
                } else if let selected, let result = results[selected.id] {
                    resultView(result)
                } else if let selected, !Self.hasRoom(selected) {
                    Text(tr("Not enough free space on this disk for the test.")).font(Typography.caption).foregroundStyle(.secondary)
                }
                if let failure {
                    Label(failure, systemImage: "exclamationmark.triangle").font(Typography.caption).foregroundStyle(.orange)
                }
            }
            .onAppear { if selection == nil { selection = volumes.first(where: \.isRoot)?.id ?? volumes.first?.id } }
            .onDisappear { running?.cancel() }
        }
    }

    private var selected: VolumeInfo? { volumes.first { $0.id == selection } }

    private func resultView(_ result: DiskSpeedResult) -> some View {
        HStack(alignment: .top, spacing: Spacing.xLarge) {
            figure(formatter.rate(result.writeSpeed), caption: tr("Write"))
            figure(formatter.rate(result.readSpeed), caption: tr("Read"))
            if result.isDemo { ProvenanceTag(tr("Demo")) }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("storage.speed.result")
    }

    private func figure(_ value: String, caption: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            Text(value).font(Typography.metric).monospacedDigit()
            Text(caption).font(Typography.caption).foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    static func hasRoom(_ volume: VolumeInfo) -> Bool {
        (volume.freeCapacity ?? volume.availableCapacity) >= UInt64(testBytes) * 2
    }

    private func start(_ tester: any DiskSpeedTesting) {
        guard let volume = selected else { return }
        // The startup disk's temporary folder is on the data volume; other disks get a hidden file at their root.
        let directory = volume.isRoot ? FileManager.default.temporaryDirectory : URL(fileURLWithPath: volume.mountPoint)
        failure = nil
        progress = DiskSpeedProgress(phase: .writing, fraction: 0)
        let id = UUID()
        runID = id
        let report = ProgressRelay { update in if runID == id { progress = update } }
        running = Task {
            do {
                results[volume.id] = try await tester.run(in: directory, bytes: Self.testBytes, progress: report.send)
            } catch is CancellationError {
            } catch DiskSpeedTestError.notEnoughSpace {
                failure = tr("Not enough free space on this disk for the test.")
            } catch let DiskSpeedTestError.failed(reason) {
                failure = tr("The test could not finish: %@", reason)
            } catch {
                failure = tr("The test could not finish: %@", error.localizedDescription)
            }
            runID = nil
            progress = nil
            running = nil
        }
    }
}

/// Hands progress from the test's thread to the main actor.
private struct ProgressRelay: Sendable {
    let apply: @MainActor (DiskSpeedProgress) -> Void

    func send(_ update: DiskSpeedProgress) {
        Task { @MainActor in apply(update) }
    }
}
