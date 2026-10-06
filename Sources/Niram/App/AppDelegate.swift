import AppKit
import SwiftUI
import Carbon

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var hotKey: GlobalHotKey!
    private var pickMenuItem: NSMenuItem!
    private var recentColorItems: [NSMenuItem] = []
    private let maxRecent = 5
    private var recentHexes: [String] = []

    private let compareModel = CompareModel()
    private var compareWindow: ChromelessWindow?
    private var settingsWindow: ChromelessWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppSettings.registerDefaults()
        NSApp.setActivationPolicy(.accessory) // no Dock icon, no app switcher entry

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = Self.menuBarIcon
            button.image?.isTemplate = true
        }

        buildMenu()
        registerHotKey()

        NotificationCenter.default.addObserver(
            forName: AppSettings.shortcutChanged, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.registerHotKey()
            }
        }
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
        hotKey = GlobalHotKey(keyCode: keyCode, modifiers: modifiers) { [weak self] in
            self?.pickColor()
        }
        pickMenuItem?.title = "Pick Color  \(shortcutDescription(keyCode: keyCode, carbonModifiers: modifiers))"
    }

    // MARK: - Menu

    private func buildMenu() {
        let menu = NSMenu()

        pickMenuItem = NSMenuItem(title: "Pick Color", action: #selector(pickColorAction), keyEquivalent: "")
        pickMenuItem.target = self
        menu.addItem(pickMenuItem)

        let compareItem = NSMenuItem(title: "Compare Colors…", action: #selector(compareAction), keyEquivalent: "")
        compareItem.target = self
        menu.addItem(compareItem)

        menu.addItem(NSMenuItem.separator())

        let recentHeader = NSMenuItem(title: "Recent", action: nil, keyEquivalent: "")
        recentHeader.isEnabled = false
        menu.addItem(recentHeader)

        for _ in 0..<maxRecent {
            let item = NSMenuItem(title: "", action: #selector(copyRecentAction(_:)), keyEquivalent: "")
            item.target = self
            item.isHidden = true
            recentColorItems.append(item)
            menu.addItem(item)
        }

        menu.addItem(NSMenuItem.separator())

        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(settingsAction), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        let quitItem = NSMenuItem(title: "Quit Niram", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    // MARK: - Windows

    private func showCompareWindow() {
        if compareWindow == nil {
            let window = makeChromelessWindow(CompareView(model: compareModel))
            window.title = "Niram"
            compareWindow = window
        }
        NSApp.activate(ignoringOtherApps: true)
        compareWindow?.makeKeyAndOrderFront(nil)
        compareWindow?.clearInitialFocus()
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

    // MARK: - Actions

    @objc private func pickColorAction() {
        pickColor()
    }

    @objc private func compareAction() {
        showCompareWindow()
    }

    @objc private func settingsAction() {
        showSettingsWindow()
    }

    private func pickColor() {
        NSColorSampler().show { [weak self] color in
            guard let self, let color else { return }
            DispatchQueue.main.async {
                let hex = AppSettings.formatHex(color)
                self.copyToClipboard(hex)
                self.addRecent(hex)
                self.flashStatusIcon()
            }
        }
    }

    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    private func addRecent(_ hex: String) {
        recentHexes.removeAll { $0 == hex }
        recentHexes.insert(hex, at: 0)
        if recentHexes.count > maxRecent {
            recentHexes.removeLast(recentHexes.count - maxRecent)
        }
        for (index, item) in recentColorItems.enumerated() {
            if index < recentHexes.count {
                let hex = recentHexes[index]
                item.title = hex
                item.isHidden = false
                if let color = NSColor(hexString: hex) {
                    item.image = swatchImage(for: color)
                }
            } else {
                item.isHidden = true
            }
        }
    }

    @objc private func copyRecentAction(_ sender: NSMenuItem) {
        copyToClipboard(sender.title)
        flashStatusIcon()
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

    private func swatchImage(for color: NSColor) -> NSImage {
        let size = NSSize(width: 14, height: 14)
        let image = NSImage(size: size)
        image.lockFocus()
        color.setFill()
        NSBezierPath(roundedRect: NSRect(origin: .zero, size: size), xRadius: 3, yRadius: 3).fill()
        image.unlockFocus()
        image.isTemplate = false
        return image
    }

    private func flashStatusIcon() {
        guard let button = statusItem.button else { return }
        let original = button.image
        button.image = NSImage(systemSymbolName: "checkmark.circle.fill", accessibilityDescription: "Copied")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            button.image = original
        }
    }
}
