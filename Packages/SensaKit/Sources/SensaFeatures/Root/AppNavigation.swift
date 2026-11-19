import Observation

/// Which screen the main window shows. Shared so Settings and the menu bar can open a screen.
@MainActor
@Observable
public final class AppNavigation {
    public var selection: Destination?

    public init(selection: Destination = .overview) {
        self.selection = selection
    }
}
