import AppKit
import SensaCore
import SensaDesign
import SensaMonitoring
import SwiftUI

/// First-run welcome: short, skippable after the first step, and honest about what this Mac supports.
public struct OnboardingView: View {
    enum Step: Int, CaseIterable {
        case welcome, mac, menuBar, notifications, ready
    }

    @Environment(MetricsStore.self) private var store
    @Environment(AppSettings.self) private var settings
    @Environment(\.services) private var services
    @Environment(\.feedback) private var feedback
    @Environment(\.sensaMotion) private var motion
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var step: Step = .welcome
    private let onFinish: () -> Void

    public init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
    }

    public var body: some View {
        VStack(spacing: 0) {
            ZStack {
                page.id(step)
                    .transition(transition)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 48)
            .padding(.top, 40)
            footer
        }
        .frame(width: 560, height: 520)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    @ViewBuilder private var page: some View {
        switch step {
        case .welcome: welcome
        case .mac: macPage
        case .menuBar: menuBarPage
        case .notifications: notificationsPage
        case .ready: readyPage
        }
    }

    private var welcome: some View {
        VStack(spacing: Spacing.large) {
            Image(nsImage: NSApplication.shared.applicationIconImage).resizable().frame(width: 112, height: 112)
                .accessibilityHidden(true)
            Text(tr("Welcome to Sensa")).font(.system(size: 30, weight: .semibold))
            Text(tr("See how your Mac is doing at a glance: temperatures, memory, battery, fans and more, explained in plain words."))
                .font(Typography.body).foregroundStyle(.secondary).multilineTextAlignment(.center).frame(maxWidth: 400)
        }
    }

    private var macPage: some View {
        let profile = store.profile
        return VStack(alignment: .leading, spacing: Spacing.large) {
            pageTitle(tr("Your Mac"), subtitle: profile.displayModelName)
            Card {
                LabeledContent(tr("Chip"), value: profile.chipName)
                LabeledContent(tr("Memory"), value: profile.physicalMemory.formatted(.byteCount(style: .memory)))
                LabeledContent(tr("macOS"), value: profile.operatingSystem)
            }
            VStack(alignment: .leading, spacing: Spacing.small) {
                capability(tr("Battery"), present: profile.hasBattery)
                capability(tr("Fans"), present: profile.fanCount > 0, detail: profile.fanCount > 0 ? "\(profile.fanCount)" : nil)
                capability(tr("Temperature sensors"), present: store.capabilities.isUsable(.temperatureSensors))
                capability(tr("Clock speeds and power by component"), present: store.capabilities.isUsable(.cpuFrequency))
            }
            Footnote(tr("Sensa shows only what this Mac really has. Nothing is estimated without saying so."))
        }
    }

    private var menuBarPage: some View {
        @Bindable var settings = settings
        return VStack(alignment: .leading, spacing: Spacing.large) {
            pageTitle(tr("In the menu bar"), subtitle: tr("Choose what to keep an eye on. You can change this anytime in Settings."))
            Card {
                ForEach($settings.menuBarItems.filter { Self.suggestedIndicators.contains($0.wrappedValue.indicator) }) { $item in
                    Toggle(isOn: $item.isEnabled) {
                        Label(MenuBarValues.title(for: item.indicator), systemImage: MenuBarValues.symbol(for: item.indicator))
                    }
                    .disabled(item.indicator == .battery && !store.profile.hasBattery)
                }
            }
            Picker(tr("Layout"), selection: $settings.menuBarLayout) {
                Text(tr("Side by side")).tag(MenuBarLayout.inline)
                Text(tr("Stacked (compact)")).tag(MenuBarLayout.stacked)
            }
            .pickerStyle(.segmented)
        }
    }

    private static let suggestedIndicators: Set<MenuBarIndicator> = [.cpuUsage, .cpuTemperature, .memoryUsed, .battery, .power, .network]

    private var notificationsPage: some View {
        VStack(alignment: .leading, spacing: Spacing.large) {
            pageTitle(tr("Stay informed"), subtitle: Copy.onboardingNotifications)
            Card {
                Label(tr("Only when a condition lasts"), systemImage: "timer")
                Label(tr("Never more than once every 30 minutes for the same alert"), systemImage: "bell.slash")
                Label(tr("Everything stays on your Mac"), systemImage: "lock.shield")
            }
            HStack {
                Button(tr("Turn On Notifications")) { enableNotifications() }
                    .buttonStyle(.borderedProminent)
                if settings.alerts.isEnabled {
                    Label(tr("On"), systemImage: "checkmark.circle.fill").foregroundStyle(.green)
                }
            }
        }
    }

    private var readyPage: some View {
        VStack(spacing: Spacing.large) {
            Image(systemName: "checkmark.circle.fill").font(.system(size: 64)).foregroundStyle(.green)
                .symbolEffect(.bounce, value: Motion.effective(motion, reduceMotion: reduceMotion) == .full)
                .accessibilityHidden(true)
            Text(tr("You're all set")).font(.system(size: 28, weight: .semibold))
            Text(tr("Sensa is now in your menu bar. Open it anytime to see how your Mac is doing."))
                .font(Typography.body).foregroundStyle(.secondary).multilineTextAlignment(.center).frame(maxWidth: 380)
        }
    }

    private var footer: some View {
        HStack {
            HStack(spacing: 6) {
                ForEach(Step.allCases, id: \.self) { item in
                    Circle().fill(item == step ? Color.accentColor : Color.secondary.opacity(0.3)).frame(width: 7, height: 7)
                }
            }
            .accessibilityElement()
            .accessibilityLabel(tr("Step %@ of %@", "\(step.rawValue + 1)", "\(Step.allCases.count)"))
            Spacer()
            if step != .welcome && step != .ready {
                Button(tr("Back")) { move(-1) }
            }
            if step == .notifications && !settings.alerts.isEnabled {
                Button(tr("Not Now")) { move(1) }
            }
            Button(step == .ready ? tr("Open Sensa") : tr("Continue")) {
                if step == .ready { finish() } else { move(1) }
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)
            .accessibilityIdentifier("onboarding.continue")
        }
        .padding(.horizontal, Spacing.xLarge)
        .padding(.vertical, Spacing.large)
        .background(.bar)
    }

    private var transition: AnyTransition {
        switch Motion.effective(motion, reduceMotion: reduceMotion) {
        case .full: .asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity))
        case .reduced: .opacity
        case .off: .identity
        }
    }

    private func pageTitle(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            Text(title).font(.system(size: 26, weight: .semibold))
            Text(subtitle).font(Typography.body).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
        }
    }

    private func capability(_ name: String, present: Bool, detail: String? = nil) -> some View {
        Label {
            HStack {
                Text(name)
                if let detail { Text(detail).foregroundStyle(.secondary) }
                Spacer()
                Text(present ? tr("Supported") : tr("Not on this Mac")).font(Typography.caption).foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: present ? "checkmark.circle.fill" : "minus.circle").foregroundStyle(present ? .green : .secondary)
        }
        .accessibilityElement(children: .combine)
    }

    private func move(_ offset: Int) {
        guard let next = Step(rawValue: step.rawValue + offset) else { return }
        withAnimation(Motion.resolve(Motion.standard, preference: motion, reduceMotion: reduceMotion)) { step = next }
    }

    private func enableNotifications() {
        Task {
            let granted = await services.notifications?.requestAuthorization() ?? false
            settings.alerts.isEnabled = granted
            if granted {
                feedback.perform(.confirm)
                move(1)
            }
        }
    }

    private func finish() {
        settings.hasCompletedOnboarding = true
        feedback.perform(.success)
        onFinish()
    }
}
