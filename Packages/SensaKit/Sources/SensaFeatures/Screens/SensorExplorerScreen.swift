import SensaCore
import SensaDesign
import SensaMonitoring
import SwiftUI

/// Every sensor Sensa can read, with its raw key, source and identification status.
/// Unknown sensors keep their original key — Sensa never invents names.
struct SensorExplorerScreen: View {
    @Environment(MetricsStore.self) private var store
    @Environment(AppSettings.self) private var settings
    @Environment(\.feedback) private var feedback
    @State private var query = ""
    @State private var group: ComponentGroup?
    @State private var favoritesOnly = false
    @State private var renaming: SensorRow?

    var body: some View {
        let rows = SensorRow.rows(store: store, settings: settings, query: query, group: group, favoritesOnly: favoritesOnly)
        VStack(spacing: 0) {
            Table(rows) {
                TableColumn("") { row in
                    Button { toggleFavorite(row.id) } label: {
                        Image(systemName: row.isFavorite ? "star.fill" : "star").foregroundStyle(row.isFavorite ? .yellow : .secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(row.isFavorite ? tr("Remove from favorites") : tr("Add to favorites"))
                }
                .width(24)
                TableColumn(tr("Name")) { row in
                    Text(row.name).foregroundStyle(row.isUnknown ? .secondary : .primary).help(row.name)
                }
                .width(min: 120, ideal: 200)
                TableColumn(tr("Key")) { row in Text(row.key).font(Typography.technical) }
                TableColumn(tr("Group")) { row in Text(row.groupName) }.width(min: 60, ideal: 80)
                TableColumn(tr("Value")) { row in Text(row.value).monospacedDigit() }.width(min: 60, ideal: 80)
                TableColumn(tr("Min")) { row in Text(row.minimum).monospacedDigit().foregroundStyle(.secondary) }.width(min: 50, ideal: 70)
                TableColumn(tr("Max")) { row in Text(row.maximum).monospacedDigit().foregroundStyle(.secondary) }.width(min: 50, ideal: 70)
                TableColumn(tr("Average")) { row in Text(row.average).monospacedDigit().foregroundStyle(.secondary) }.width(min: 50, ideal: 70)
                TableColumn(tr("Source")) { row in Text(row.source).font(Typography.caption) }.width(min: 40, ideal: 50)
                TableColumn(tr("Identification")) { row in
                    Text(row.identification).font(Typography.caption).foregroundStyle(.secondary).help(row.identification)
                }
                .width(min: 120, ideal: 170)
            }
            .contextMenu(forSelectionType: SensorRow.ID.self) { ids in
                if let id = ids.first, let row = rows.first(where: { $0.id == id }) {
                    Button(tr("Rename…")) { renaming = row }
                    Button(row.isFavorite ? tr("Remove from favorites") : tr("Add to favorites")) { toggleFavorite(id) }
                }
            }
            .overlay {
                if rows.isEmpty {
                    ContentUnavailableView(
                        query.isEmpty ? tr("No sensors") : tr("No results"),
                        systemImage: "sensor",
                        description: Text(query.isEmpty ? tr("Sensors appear here as soon as they are read.") : tr("Try another search."))
                    )
                }
            }
            Divider()
            Text(tr("Values from undocumented interfaces (SMC, HID). Min, max and average cover the last two minutes."))
                .font(Typography.caption).foregroundStyle(.secondary)
                .padding(Spacing.small)
        }
        .navigationTitle(tr("Sensors"))
        .searchable(text: $query, prompt: tr("Search sensors"))
        .toolbar {
            ToolbarItemGroup {
                Picker(tr("Group"), selection: $group) {
                    Text(tr("All groups")).tag(ComponentGroup?.none)
                    ForEach(ComponentGroup.allCases, id: \.self) { group in
                        Text(Descriptions.group(group)).tag(ComponentGroup?.some(group))
                    }
                }
                Toggle(isOn: $favoritesOnly) { Label(tr("Favorites"), systemImage: "star") }
                    .help(tr("Show favorites only"))
            }
        }
        .sheet(item: $renaming) { row in
            RenameSensorSheet(row: row)
        }
    }

    private func toggleFavorite(_ id: String) {
        feedback.perform(.selection)
        if settings.favoriteSensors.contains(id) {
            settings.favoriteSensors.remove(id)
        } else {
            settings.favoriteSensors.insert(id)
        }
    }
}

struct SensorRow: Identifiable, Hashable {
    let id: String
    let name: String
    let key: String
    let groupName: String
    let value: String
    let minimum: String
    let maximum: String
    let average: String
    let source: String
    let identification: String
    let isFavorite: Bool
    let isUnknown: Bool
    let originalName: String

    @MainActor
    static func rows(store: MetricsStore, settings: AppSettings, query: String, group: ComponentGroup?, favoritesOnly: Bool) -> [SensorRow] {
        let formatter = settings.formatter
        let readings = store.snapshot.sensors?.sensors ?? []
        return readings
            .filter { group == nil || $0.sensor.group == group }
            .filter { settings.showsUnknownSensors || $0.sensor.identification != .unknown || settings.favoriteSensors.contains($0.sensor.id.rawValue) }
            .map { reading in
                let sensor = reading.sensor
                let id = sensor.id.rawValue
                let statistics = store.series(for: .sensor(sensor.id), unit: sensor.unit).statistics
                func format(_ value: Double?) -> String { value.map { formatter.temperature($0, fractionDigits: 1) } ?? "–" }
                let original = sensor.name.map(SensorNames.localized) ?? tr("Unknown")
                return SensorRow(
                    id: id,
                    name: settings.sensorNicknames[id] ?? original,
                    key: sensor.id.key,
                    groupName: Descriptions.group(sensor.group),
                    value: format(reading.value),
                    minimum: format(statistics?.minimum),
                    maximum: format(statistics?.maximum),
                    average: format(statistics?.mean),
                    source: sensor.id.source.rawValue.uppercased(),
                    identification: Descriptions.identification(sensor.identification),
                    isFavorite: settings.favoriteSensors.contains(id),
                    isUnknown: sensor.identification == .unknown && settings.sensorNicknames[id] == nil,
                    originalName: original
                )
            }
            .filter { !favoritesOnly || $0.isFavorite }
            .filter { query.isEmpty || $0.name.localizedCaseInsensitiveContains(query) || $0.key.localizedCaseInsensitiveContains(query) }
            .sorted { ($0.isFavorite ? 0 : 1, $0.isUnknown ? 1 : 0, $0.key) < ($1.isFavorite ? 0 : 1, $1.isUnknown ? 1 : 0, $1.key) }
    }
}

private struct RenameSensorSheet: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss
    @Environment(\.feedback) private var feedback
    let row: SensorRow
    @State private var name = ""

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text(tr("Rename sensor")).font(Typography.headline)
            Text(tr("Original: %@ · %@", row.originalName, row.key)).font(Typography.caption).foregroundStyle(.secondary)
            TextField(tr("Name"), text: $name)
                .textFieldStyle(.roundedBorder)
                .onSubmit(save)
            HStack {
                Button(tr("Restore original")) {
                    settings.sensorNicknames[row.id] = nil
                    dismiss()
                }
                Spacer()
                Button(tr("Cancel"), role: .cancel) { dismiss() }.keyboardShortcut(.cancelAction)
                Button(tr("Save"), action: save).keyboardShortcut(.defaultAction).disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(Spacing.xLarge)
        .frame(width: 380)
        .onAppear { name = row.name }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        settings.sensorNicknames[row.id] = trimmed
        feedback.perform(.confirm)
        dismiss()
    }
}
