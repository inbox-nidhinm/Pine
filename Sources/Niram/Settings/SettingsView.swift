import SwiftUI
import AppKit
import Carbon
import ServiceManagement

/// The Settings window: the title under the traffic lights, then one vertical
/// list (the user's choice, 6 October 2026, in place of Twine's cards), each
/// kind of setting a heading over its rows, in a tall window; Version History
/// with the build at the foot.
struct SettingsView: View {
    @AppStorage(AppSettings.uppercaseHexKey) private var uppercaseHex = true
    @AppStorage(AppSettings.includeHashKey) private var includeHash = true
    @AppStorage(AppSettings.appearanceKey) private var appearance = AppSettings.Appearance.system.rawValue
    @AppStorage(AppSettings.presenceKey) private var presence = AppSettings.Presence.menuBar.rawValue
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var showsHistory = false

    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 0) {
                Text("Settings")
                    .font(ThemeFont.display(Theme.settingsTitle))
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.horizontal, Theme.settingsMargin)
                    .padding(.bottom, Theme.panelPad)
                    .frame(height: Theme.settingsTitleBlock, alignment: .bottom)

                Rectangle().fill(Theme.border).frame(height: Theme.hairline)

                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.settingsSectionGap) {
                        shortcut
                        hexCodes
                        general
                    }
                    .padding(Theme.settingsMargin)
                }
                .scrollIndicators(.never)

                // Not a setting: nothing here changes what the app does, so it
                // sits apart, at the foot.
                Rectangle().fill(Theme.border).frame(height: Theme.hairline)
                HStack(spacing: Theme.panelPad) {
                    PanelButton(title: "Version History") { showsHistory = true }
                        .frame(width: Theme.settingsButton)
                    Text("Build \(VersionHistory.version) · \(VersionHistory.release)")
                        .font(ThemeFont.caption)
                        .foregroundStyle(Theme.textTertiary)
                }
                .padding(Theme.settingsMargin)
            }
            .frame(width: Theme.settingsWindow.width, height: Theme.settingsWindow.height)

            if showsHistory {
                VersionHistoryCard { showsHistory = false }
            }
        }
        .windowGround()
        // Up under the hidden title bar, so the window is exactly its size;
        // the title block leaves room for the traffic lights.
        .ignoresSafeArea()
    }

    // MARK: Cards

    private var shortcut: some View {
        section("Global Shortcut") {
            row(.eyedropper, "Pick colour") {
                ShortcutField()
            }
        }
    }

    private var hexCodes: some View {
        section("Hex Codes") {
            row(tile: AnyView(Text("A").font(ThemeFont.hex)), "Uppercase") {
                PillToggle(isOn: uppercaseHex) { uppercaseHex.toggle() }
            }
            dashes
            row(tile: AnyView(Text("#").font(ThemeFont.hex)), "Include #") {
                PillToggle(isOn: includeHash) { includeHash.toggle() }
            }
            dashes
            row(tile: AnyView(RoundedRectangle(cornerRadius: Theme.radiusSwatch)
                    .fill(Theme.accent)
                    .frame(width: Theme.swatch, height: Theme.swatch)),
                "Copied as") {
                Text(AppSettings.formatHex(Self.sample, uppercase: uppercaseHex, hash: includeHash))
                    .font(ThemeFont.hex)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    private var general: some View {
        section("General") {
            row(tile: AnyView(AppearanceGlyph()), "Appearance") {
                SegmentRow(options: AppSettings.Appearance.allCases.map { ($0.rawValue, $0.name) },
                           chosen: appearance) { picked in
                    appearance = picked
                    NotificationCenter.default.post(name: AppSettings.appearanceChanged, object: nil)
                }
            }
            dashes
            row(tile: AnyView(IconView(.settings, size: Theme.settingsTileIcon)), "Show Niram in") {
                SegmentRow(options: AppSettings.Presence.allCases.map { ($0.rawValue, $0.name) },
                           chosen: presence) { picked in
                    presence = picked
                    NotificationCenter.default.post(name: AppSettings.presenceChanged, object: nil)
                }
            }
            dashes
            row(.power, "Launch at login") {
                PillToggle(isOn: launchAtLogin) { setLaunchAtLogin(!launchAtLogin) }
            }
        }
    }

    /// The colour the Copied as row shows: Niram's own magenta.
    private static let sample = NSColor(hexString: "#E2387F") ?? .magenta

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            NSLog("Launch at login could not be changed: \(error)")
        }
        // What the system says, whether or not the change took.
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }

    // MARK: Pieces

    /// A kind of setting: its name over its rows, flat on the page.
    private func section<Content: View>(_ title: String, @ViewBuilder _ rows: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(ThemeFont.labelStrong)
                .foregroundStyle(Theme.textSecondary)
                .padding(.bottom, Theme.settingsCardTitleGap)
            VStack(alignment: .leading, spacing: 0) { rows() }
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// The line between two rows of a section.
    private var dashes: some View {
        Rectangle().fill(Theme.border).frame(height: Theme.hairline)
    }

    /// An icon on its tile, a name, and the control at the right.
    private func row<Control: View>(_ icon: Icon, _ label: String,
                                    @ViewBuilder _ control: () -> Control) -> some View {
        row(tile: AnyView(IconView(icon, size: Theme.settingsTileIcon)), label, control)
    }

    private func row<Control: View>(tile: AnyView, _ label: String,
                                    @ViewBuilder _ control: () -> Control) -> some View {
        HStack(spacing: Theme.panelPad) {
            tile
                .foregroundStyle(Theme.textSecondary)
                .frame(width: Theme.settingsTile, height: Theme.settingsTile)
                .background(RoundedRectangle(cornerRadius: Theme.radiusWell).fill(Theme.panelRaised))
            Text(label)
                .font(ThemeFont.label)
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1)
            Spacer(minLength: Theme.panelPad)
            control()
        }
        .frame(height: Theme.settingsRow)
    }

}

/// Half a circle filled: the usual mark for light and dark.
private struct AppearanceGlyph: View {
    var body: some View {
        ZStack {
            Circle().strokeBorder(lineWidth: Theme.glyphLine)
            Circle().trim(from: 0.25, to: 0.75).fill()
        }
        .frame(width: Theme.settingsTileIcon, height: Theme.settingsTileIcon)
    }
}

/// The pick shortcut as a field: a click records a new one. It needs at least
/// one of ⌘, ⌥ or ⌃, so it never takes ordinary typing; Escape stops without
/// changing it.
private struct ShortcutField: View {
    @State private var isRecording = false
    @State private var monitor: Any?
    @State private var hovering = false
    @State private var display = shortcutDescription(
        keyCode: AppSettings.hotKeyCode,
        carbonModifiers: AppSettings.hotKeyModifiers
    )

    var body: some View {
        Button {
            isRecording ? stopRecording() : startRecording()
        } label: {
            Text(isRecording ? "Press keys" : display)
                .font(ThemeFont.label)
                .foregroundStyle(isRecording ? Theme.textTertiary : Theme.textPrimary)
                .frame(width: Theme.settingsControl, height: Theme.control)
                .background(RoundedRectangle(cornerRadius: Theme.radiusControl)
                    .fill(hovering && !isRecording ? Theme.panelHover : Theme.panelRaised))
                .overlay(RoundedRectangle(cornerRadius: Theme.radiusControl)
                    .strokeBorder(isRecording ? Theme.accent : .clear, lineWidth: Theme.hairline))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .onDisappear { stopRecording() }
    }

    private func startRecording() {
        isRecording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            handle(event)
            return nil // swallow the keystroke while recording
        }
    }

    private func stopRecording() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        isRecording = false
    }

    private func handle(_ event: NSEvent) {
        if event.keyCode == UInt16(kVK_Escape) {
            stopRecording()
            return
        }
        let mods = carbonFlags(from: event.modifierFlags)
        let required = UInt32(cmdKey) | UInt32(optionKey) | UInt32(controlKey)
        guard mods & required != 0 else {
            NSSound.beep()
            return
        }
        AppSettings.hotKeyCode = UInt32(event.keyCode)
        AppSettings.hotKeyModifiers = mods
        display = shortcutDescription(keyCode: UInt32(event.keyCode), carbonModifiers: mods)
        stopRecording()
        NotificationCenter.default.post(name: AppSettings.shortcutChanged, object: nil)
    }
}
