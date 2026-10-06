import SwiftUI
import AppKit
import Carbon
import ServiceManagement

struct SettingsView: View {
    @AppStorage(AppSettings.uppercaseHexKey) private var uppercaseHex = true
    @AppStorage(AppSettings.includeHashKey) private var includeHash = true
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        Form {
            Section("Shortcut") {
                LabeledContent("Pick color") {
                    ShortcutField()
                }
            }

            Section("Hex format") {
                Toggle("Uppercase (#FFAA00 vs #ffaa00)", isOn: $uppercaseHex)
                Toggle("Include # prefix", isOn: $includeHash)
                LabeledContent("Preview") {
                    Text(AppSettings.formatHex(NSColor(hexString: "#FA5F16")!))
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }

            Section("General") {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { enabled in
                        do {
                            if enabled {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                        } catch {
                            NSLog("Launch at Login toggle failed: \(error)")
                            launchAtLogin = SMAppService.mainApp.status == .enabled
                        }
                    }
            }
        }
        .formStyle(.grouped)
        .frame(width: 400)
        .fixedSize(horizontal: false, vertical: true)
    }
}

// Click to record a new global shortcut. Requires at least one of ⌘⌥⌃ to
// avoid clashing with normal typing; Esc cancels recording.
private struct ShortcutField: View {
    @State private var isRecording = false
    @State private var monitor: Any?
    @State private var display = shortcutDescription(
        keyCode: AppSettings.hotKeyCode,
        carbonModifiers: AppSettings.hotKeyModifiers
    )

    var body: some View {
        Button {
            isRecording ? stopRecording() : startRecording()
        } label: {
            Text(isRecording ? "Press keys…" : display)
                .font(.system(.body, design: .monospaced))
                .frame(minWidth: 90)
        }
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
