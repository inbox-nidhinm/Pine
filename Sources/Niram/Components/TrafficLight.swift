import SwiftUI
import AppKit

/// macOS's own red close button, for a window with no title bar of its own
/// (the Compare card). It is the system's button, so it looks and changes as
/// the traffic lights do: grey while the window is not in front, the ✕ under
/// the pointer.
///
/// A traffic light shows its ✕ only while the pointer is over its group, which
/// it learns by asking the view holding it `_mouseInGroup:`, a private method
/// of the title bar's own holder. `Holder` answers it from a tracking area.
/// Niram is internal only, so private methods are fine (as in Twine).
struct TrafficLightClose: NSViewRepresentable {
    let action: () -> Void

    func makeNSView(context: Context) -> Holder {
        let holder = Holder()
        holder.action = action
        return holder
    }

    func updateNSView(_ holder: Holder, context: Context) {
        holder.action = action
    }

    final class Holder: NSView {
        var action: () -> Void = {}
        private var pointerInside = false
        private let button: NSButton?

        override init(frame: NSRect) {
            button = NSWindow.standardWindowButton(.closeButton, for: [.titled, .closable])
            super.init(frame: frame)
            guard let button else { return }
            // The window has no close button of its own, so the system's
            // `performClose:` would only beep: the button calls us instead.
            button.target = self
            button.action = #selector(pressed)
            button.setFrameOrigin(.zero)
            addSubview(button)
            addTrackingArea(NSTrackingArea(rect: .zero,
                                           options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
                                           owner: self))
        }

        required init?(coder: NSCoder) { fatalError("not used") }

        override var intrinsicContentSize: NSSize { button?.frame.size ?? .zero }

        @objc private func pressed() { action() }

        /// Asked by the traffic light while it draws.
        @objc func _mouseInGroup(_ button: NSButton) -> Bool { pointerInside }

        override func mouseEntered(with event: NSEvent) {
            pointerInside = true
            button?.needsDisplay = true
        }

        override func mouseExited(with event: NSEvent) {
            pointerInside = false
            button?.needsDisplay = true
        }

        // Clicks on the button are its own, not a drag of the window.
        override var mouseDownCanMoveWindow: Bool { false }
    }
}
