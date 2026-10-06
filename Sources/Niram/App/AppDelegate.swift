import AppKit
import SwiftUI
import Carbon

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var hotKey: GlobalHotKey?
    private let recents = RecentColors()
    private let panel = StatusPanel()

    private let compareModel = CompareModel()
    private var compareWindow: CardWindow?
    private var settingsWindow: ChromelessWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppSettings.registerDefaults()
        NSApp.setActivationPolicy(.accessory) // no Dock icon, no app switcher entry

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = Self.menuBarIcon
            button.image?.isTemplate = true
            button.target = self
            button.action = #selector(togglePanel)
            // Opens on the press, as a menu does, not on the release.
            button.sendAction(on: [.leftMouseDown, .rightMouseDown])
        }

        registerHotKey()

        NotificationCenter.default.addObserver(
            forName: AppSettings.shortcutChanged, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.registerHotKey()
            }
        }
    }

    // The eyedropper outlives the app that started it, so a pick in progress
    // is ended rather than left over every screen.
    func applicationWillTerminate(_ notification: Notification) {
        ColorPicking.shared.end()
    }

    // Launching the app a second time sends a reopen event to the running
    // instance: that is when the compare window comes up.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showCompareWindow()
        return false
    }

    // MARK: - Hotkey

    private func registerHotKey() {
        let keyCode = AppSettings.hotKeyCode
        let modifiers = AppSettings.hotKeyModifiers
        // Let go of the old one first: while it holds its keys, registering
        // the same keys again fails without a word.
        hotKey = nil
        hotKey = GlobalHotKey(keyCode: keyCode, modifiers: modifiers) { [weak self] in
            self?.pickColor(toggles: true)
        }
    }

    // MARK: - Panel

    @objc private func togglePanel() {
        if panel.isShown {
            panel.close()
            return
        }
        guard let button = statusItem.button else { return }
        let shortcut = shortcutDescription(keyCode: AppSettings.hotKeyCode, carbonModifiers: AppSettings.hotKeyModifiers)
        let actions = MenuBarActions(
            pick: { [weak self] in self?.panel.close(); self?.pickColor() },
            copy: { [weak self] hex in self?.copyRecent(hex) },
            compare: { [weak self] in self?.panel.close(); self?.showCompareWindow() },
            settings: { [weak self] in self?.panel.close(); self?.showSettingsWindow() },
            quit: { NSApp.terminate(nil) }
        )
        panel.show(MenuBarPanel(recents: recents, shortcut: shortcut, actions: actions), under: button, keys: [
            UInt16(kVK_ANSI_Comma): actions.settings,
            UInt16(kVK_ANSI_Q): actions.quit,
        ])
    }

    /// Copies a recent colour again, leaving the list as it is so nothing
    /// moves under the pointer, and closes the panel once its tick has shown.
    private func copyRecent(_ hex: String) {
        copyToClipboard(hex)
        flashStatusIcon()
        DispatchQueue.main.asyncAfter(deadline: .now() + Theme.copiedPause) { [weak self] in
            self?.panel.close()
        }
    }

    // MARK: - Windows

    private func showCompareWindow() {
        if compareWindow == nil {
            let window = makeCardWindow(CompareView(model: compareModel) { [weak self] in self?.compareWindow?.close() }, size: Theme.compareWindow)
            window.title = "Niram"
            compareWindow = window
        }
        NSApp.activate(ignoringOtherApps: true)
        compareWindow?.makeKeyAndOrderFront(nil)
        // Nothing typed in until a code is clicked.
        DispatchQueue.main.async { [weak self] in self?.compareWindow?.makeFirstResponder(nil) }
    }

    private func showSettingsWindow() {
        if settingsWindow == nil {
            let window = makeChromelessWindow(SettingsView())
            window.title = "Niram Settings"
            settingsWindow = window
        }
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
        settingsWindow?.clearInitialFocus()
    }

    // MARK: - Picking

    /// Picks a colour and copies it. From the shortcut, `toggles` ends a pick
    /// already in progress instead, so the shortcut is always a way out.
    private func pickColor(toggles: Bool = false) {
        let done: (NSColor?) -> Void = { [weak self] color in
            guard let self, let color else { return }
            let hex = AppSettings.formatHex(color)
            self.copyToClipboard(hex)
            self.recents.add(hex)
            self.flashStatusIcon()
        }
        if toggles {
            ColorPicking.shared.toggle(done)
        } else {
            ColorPicking.shared.pick(done)
        }
    }

    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    // MARK: - Icons

    private static let menuBarIcon: NSImage = {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            let circleInset: CGFloat = 1.5
            let circleRect = rect.insetBy(dx: circleInset, dy: circleInset)
            let circlePath = NSBezierPath(ovalIn: circleRect)
            circlePath.lineWidth = 1.4
            NSColor.black.setStroke()
            circlePath.stroke()

            let squareSide: CGFloat = 6
            let squareRect = NSRect(
                x: rect.midX - squareSide / 2,
                y: rect.midY - squareSide / 2,
                width: squareSide,
                height: squareSide
            )
            NSColor.black.setFill()
            NSBezierPath(rect: squareRect).fill()

            return true
        }
        image.isTemplate = true
        return image
    }()

    /// The designer's tick, as a template image for the menu bar.
    private static let copiedIcon: NSImage? = {
        let renderer = ImageRenderer(content: AnyView(IconView(.check, size: Theme.icon).foregroundStyle(.black)))
        renderer.scale = 2
        let image = renderer.nsImage
        image?.isTemplate = true
        return image
    }()

    private func flashStatusIcon() {
        guard let button = statusItem.button else { return }
        button.image = Self.copiedIcon
        // Back to the icon itself rather than whatever showed before, which
        // after two copies close together was the tick.
        DispatchQueue.main.asyncAfter(deadline: .now() + Theme.copiedFlash) {
            button.image = Self.menuBarIcon
        }
    }
}
