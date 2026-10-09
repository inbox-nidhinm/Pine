import AppKit
import SwiftUI
import Carbon

/// The borderless window that holds `MenuBarPanel` under the menu bar icon.
///
/// A non-activating panel, so opening it never pulls the app in front of the
/// one being worked in, yet it can take the keyboard: Escape closes it, ⌘,
/// opens Settings and ⌘Q quits. A click anywhere else closes it, as a menu.
@MainActor
final class StatusPanel: NSObject, NSWindowDelegate {
    private final class Panel: NSPanel {
        override var canBecomeKey: Bool { true }
    }

    private let panel: Panel
    private var clickMonitor: Any?
    private var keyMonitor: Any?
    private weak var button: NSStatusBarButton?
    private var keys: [UInt16: () -> Void] = [:]

    var isShown: Bool { panel.isVisible }

    override init() {
        panel = Panel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: true)
        super.init()
        panel.isOpaque = false
        panel.backgroundColor = .clear
        // The window's own shadow follows the card's rounded shape.
        panel.hasShadow = true
        panel.level = .popUpMenu
        panel.appearance = NSAppearance(named: .darkAqua)
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        panel.delegate = self
    }

    /// Shows `content` just under `button`, its right edge kept on screen.
    /// `keys` are the key codes handled while it shows, with Command held.
    func show<Content: View>(_ content: Content, under button: NSStatusBarButton, keys: [UInt16: () -> Void]) {
        self.button = button
        self.keys = keys
        let hosting = NSHostingView(rootView: content)
        panel.contentView = hosting
        let size = hosting.fittingSize

        guard let buttonWindow = button.window else { return }
        let anchor = buttonWindow.convertToScreen(button.convert(button.bounds, to: nil))
        let screen = (buttonWindow.screen ?? NSScreen.main)?.visibleFrame ?? anchor
        var x = anchor.midX - size.width / 2
        x = min(max(x, screen.minX + Theme.floatInset), screen.maxX - Theme.floatInset - size.width)
        let y = anchor.minY - Theme.menuPanelGap - size.height
        panel.setFrame(NSRect(x: x, y: y, width: size.width, height: size.height), display: true)

        panel.alphaValue = 0
        panel.makeKeyAndOrderFront(nil)
        panel.invalidateShadow()
        NSAnimationContext.runAnimationGroup { context in
            context.duration = Theme.panelFade
            panel.animator().alphaValue = 1
        }
        button.highlight(true)
        watch()
    }

    func close() {
        guard panel.isVisible else { return }
        stopWatching()
        button?.highlight(false)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = Theme.panelFade
            panel.animator().alphaValue = 0
        } completionHandler: { [panel] in
            MainActor.assumeIsolated {
                // Shown again while it faded: leave it up.
                if panel.alphaValue == 0 { panel.orderOut(nil) }
            }
        }
    }

    func windowDidResignKey(_ notification: Notification) {
        close()
    }

    private func watch() {
        stopWatching()
        // Clicks in other apps. A click on the menu bar icon itself reaches its
        // button, which closes the panel by toggling.
        clickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            MainActor.assumeIsolated { self?.close() }
        }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            // Only plain values cross into the main actor: an event is not Sendable.
            let window = event.windowNumber
            let code = event.keyCode
            let commandOnly = event.modifierFlags.intersection(.deviceIndependentFlagsMask) == .command
            let handled = MainActor.assumeIsolated {
                self?.handleKey(code, commandOnly: commandOnly, inWindow: window) ?? false
            }
            return handled ? nil : event
        }
    }

    private func handleKey(_ code: UInt16, commandOnly: Bool, inWindow window: Int) -> Bool {
        guard window == panel.windowNumber else { return false }
        if code == UInt16(kVK_Escape) {
            close()
            return true
        }
        if commandOnly, let action = keys[code] {
            action()
            return true
        }
        return false
    }

    private func stopWatching() {
        if let clickMonitor { NSEvent.removeMonitor(clickMonitor) }
        if let keyMonitor { NSEvent.removeMonitor(keyMonitor) }
        clickMonitor = nil
        keyMonitor = nil
    }
}
