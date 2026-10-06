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
    /// The card was open when Settings opened, so it comes back when Settings
    /// closes (the user's request, 6 October 2026).
    private var compareAfterSettings = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppSettings.registerDefaults()
        // Before anything can pick: it watches for a stuck eyedropper from its
        // own thread for as long as Niram runs.
        SamplerWatchdog.start(watching: ColorPicking.shared.state)
        NSApp.mainMenu = AppMenu.make(target: self)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = Self.menuBarIcon
            button.image?.isTemplate = true
            button.target = self
            button.action = #selector(togglePanel)
            // Opens on the press, as a menu does, not on the release.
            button.sendAction(on: [.leftMouseDown, .rightMouseDown])
        }
        applyPresence()

        registerHotKey()

        NotificationCenter.default.addObserver(
            forName: AppSettings.shortcutChanged, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.registerHotKey()
            }
        }

        NotificationCenter.default.addObserver(
            forName: AppSettings.presenceChanged, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.applyPresence() }
        }

        NotificationCenter.default.addObserver(
            forName: AppSettings.appearanceChanged, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.compareWindow?.appearance = AppSettings.appearance.window
                self?.settingsWindow?.appearance = AppSettings.appearance.window
            }
        }
    }

    /// Shows Niram in the menu bar, the Dock or both, as Settings says. In the
    /// Dock it is an ordinary app: in ⌘Tab, with its menu bar menus.
    private func applyPresence() {
        let presence = AppSettings.presence
        statusItem.isVisible = presence.inMenuBar
        if !presence.inMenuBar { panel.close() }
        let policy: NSApplication.ActivationPolicy = presence.inDock ? .regular : .accessory
        guard NSApp.activationPolicy() != policy else { return }
        // Whatever was in front stays in front: changing policy can hide an
        // accessory app's windows behind others.
        let front = NSApp.windows.filter { $0.isVisible && $0.canBecomeMain }
        NSApp.setActivationPolicy(policy)
        NSApp.activate(ignoringOtherApps: true)
        front.forEach { $0.orderFrontRegardless() }
    }

    /// The Dock icon's menu.
    func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
        AppMenu.dock(target: self)
    }

    @objc func menuPickColour() { pickColor() }
    @objc func menuShowApp() { showCompareWindow() }
    @objc func menuSettings() { showSettingsWindow() }

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

    /// Copies a recent colour again, leaving the list as it is, and closes
    /// the panel; the menu bar icon's tick says it was copied.
    private func copyRecent(_ hex: String) {
        copyToClipboard(hex)
        flashStatusIcon()
        panel.close()
    }

    // MARK: - Windows

    private func showCompareWindow() {
        // Opened by hand: Settings closing has nothing left to bring back.
        compareAfterSettings = false
        if compareWindow == nil {
            let window = makeCardWindow(CompareView(model: compareModel, recents: recents) { [weak self] in
                self?.compareWindow?.close()
            }, size: Theme.compareWindow)
            window.title = "Niram"
            window.appearance = AppSettings.appearance.window
            compareWindow = window
        }
        NSApp.activate(ignoringOtherApps: true)
        compareWindow?.makeKeyAndOrderFront(nil)
        // Nothing typed in until a code is clicked.
        DispatchQueue.main.async { [weak self] in self?.compareWindow?.makeFirstResponder(nil) }
    }

    /// Settings shows alone: an open card is put away, and comes back when
    /// Settings closes. A card that was not open stays closed.
    private func showSettingsWindow() {
        if compareWindow?.isVisible == true {
            compareWindow?.orderOut(nil)
            compareAfterSettings = true
        }
        if settingsWindow == nil {
            let window = makeChromelessWindow(SettingsView(), size: Theme.settingsWindow)
            window.title = "Niram Settings"
            // Light or dark as the Appearance setting says, as the card is.
            window.appearance = AppSettings.appearance.window
            NotificationCenter.default.addObserver(
                forName: NSWindow.willCloseNotification, object: window, queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated { self?.settingsClosed() }
            }
            settingsWindow = window
        }
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
        settingsWindow?.clearInitialFocus()
    }

    private func settingsClosed() {
        guard compareAfterSettings else { return }
        // A turn later, once Settings has gone.
        DispatchQueue.main.async { [weak self] in self?.showCompareWindow() }
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

    /// The designer's menu bar icon (`Resources/menu-icon.svg`, 6 October
    /// 2026), drawn by macOS from the SVG, as a template so it follows the
    /// menu bar's colour.
    private static let menuBarIcon: NSImage = {
        let image = Bundle.main.url(forResource: "menu-icon", withExtension: "svg").flatMap(NSImage.init(contentsOf:))
            ?? NSImage(size: NSSize(width: Theme.menuBarIcon, height: Theme.menuBarIcon))
        image.size = NSSize(width: Theme.menuBarIcon, height: Theme.menuBarIcon)
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
