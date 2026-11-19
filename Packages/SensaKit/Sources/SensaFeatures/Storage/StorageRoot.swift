import SensaDesign
import SwiftUI

/// Storage has two pages: what the disks are doing, and freeing space. A segmented control in the
/// toolbar switches between them, so cleaning up stays part of Storage instead of a screen of its own.
struct StorageRoot: View {
    @Environment(AppNavigation.self) private var navigation
    @Environment(\.services) private var services

    var body: some View {
        @Bindable var navigation = navigation
        Group {
            if navigation.storagePage == .freeUpSpace, services.storage.spaceAnalysis != nil {
                FreeUpSpaceScreen()
            } else {
                StorageScreen()
            }
        }
        .toolbar {
            if services.storage.spaceAnalysis != nil {
                ToolbarItem(placement: .principal) {
                    Picker(tr("Page"), selection: $navigation.storagePage) {
                        Text(tr("Overview")).tag(StoragePage.overview)
                        Text(tr("Free Up Space")).tag(StoragePage.freeUpSpace)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .accessibilityIdentifier("storage.page")
                }
            }
        }
    }
}
