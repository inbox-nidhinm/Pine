import SwiftUI
import AppKit
import Carbon
import ServiceManagement

/// The Settings window, laid out as Twine's Settings page: the title under the
/// traffic lights, each kind of setting as a card of rows in two columns, and
/// Version History with the build at the foot.
struct SettingsView: View {
    @AppStorage(AppSettings.uppercaseHexKey) private var uppercaseHex = true
    @AppStorage(AppSettings.includeHashKey) private var includeHash = true
    @AppStorage(AppSettings.appearanceKey) private var appearance = AppSettings.Appearance.system.rawValue
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

                HStack(alignment: .top, spacing: Theme.settingsCardGap) {
                    VStack(spacing: Theme.settingsCardGap) {
                        picking
                        general
                    }
                    .frame(width: Theme.settingsColumn)
                    hexCodes
                        .frame(width: Theme.settingsColumn)
                }
                .padding(Theme.settingsMargin)

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
            .fixedSize()

            if showsHistory {
                VersionHistoryCard { showsHistory = false }
            }
        }
        .windowGround(grain: false)
    }

    // MARK: Cards

    private var picking: some View {
        card("Picking") {
            row(.eyedropper, "Pick colour",
                help: "The shortcut that picks a colour from anywhere on screen and copies its hex code. Click it and press a new one: it needs ⌘, ⌥ or ⌃. Escape keeps the old one.") {
                ShortcutField()
            }
        }
    }

    private var hexCodes: some View {
        card("Hex Codes") {
            row(tile: AnyView(Text("A").font(ThemeFont.hex)), "Uppercase",
                help: "Copy hex codes in capitals (#FFAA00) rather than small letters (#ffaa00).") {
                PillToggle(isOn: uppercaseHex) { uppercaseHex.toggle() }
            }
            dashes
            row(tile: AnyView(Text("#").font(ThemeFont.hex)), "Include #",
                help: "Start copied hex codes with #.") {
                PillToggle(isOn: includeHash) { includeHash.toggle() }
            }
            dashes
            row(tile: AnyView(RoundedRectangle(cornerRadius: Theme.radiusSwatch)
                    .fill(Theme.accent)
                    .frame(width: Theme.swatch, height: Theme.swatch)),
                "Copied as", help: "How a colour's hex code is copied with these settings.") {
                Text(AppSettings.formatHex(Self.sample, uppercase: uppercaseHex, hash: includeHash))
                    .font(ThemeFont.hex)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    private var general: some View {
        card("General") {
            row(tile: AnyView(AppearanceGlyph()), "Appearance",
                help: "Light or dark for the Compare card. System follows your Mac.") {
                SegmentRow(options: AppSettings.Appearance.allCases.map { ($0.rawValue, $0.name) },
                           chosen: appearance) { picked in
                    appearance = picked
                    NotificationCenter.default.post(name: AppSettings.appearanceChanged, object: nil)
                }
            }
            dashes
            row(.power, "Launch at login", help: "Start Niram when you log in, so the shortcut is always ready.") {
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

    /// A kind of setting: its name over a card holding its rows.
    private func card<Content: View>(_ title: String, @ViewBuilder _ rows: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Theme.settingsCardTitleGap) {
            Text(title)
                .font(ThemeFont.labelStrong)
                .foregroundStyle(Theme.textSecondary)
                .padding(.leading, Theme.rowGap)
            // As far in at the top and bottom as at the sides: a row already
            // leaves `rowInset` round its tile, so the card adds the rest.
            VStack(alignment: .leading, spacing: 0) { rows() }
                .padding(.horizontal, Theme.panelPad)
                .padding(.vertical, Theme.panelPad - Self.rowInset)
                .frame(maxWidth: .infinity, alignment: .leading)
                // Flat on the page, with no shadow, as Twine's.
                .floatingPanel(shadow: false, grain: false)
        }
    }

    /// The dashed line between two rows of a card.
    private var dashes: some View {
        DashedLine()
            .stroke(Theme.border, style: StrokeStyle(lineWidth: Theme.hairline, dash: Theme.settingsDash))
            .frame(height: Theme.hairline)
    }

    /// An icon on its tile, a name, and the control at the right. The
    /// explanation is the row's tooltip.
    private func row<Control: View>(_ icon: Icon, _ label: String, help: String,
                                    @ViewBuilder _ control: () -> Control) -> some View {
        row(tile: AnyView(IconView(icon, size: Theme.settingsTileIcon)), label, help: help, control)
    }

    private func row<Control: View>(tile: AnyView, _ label: String, help: String,
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
        .help(help)
    }

    /// The room a row leaves above and below its tile.
    private static let rowInset = (Theme.settingsRow - Theme.settingsTile) / 2
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

private struct DashedLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
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
