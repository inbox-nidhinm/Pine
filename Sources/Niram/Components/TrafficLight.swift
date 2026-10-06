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

        /// Drawn larger by `Theme.compareCloseDot / Theme.trafficLightDot`, the
        /// same both ways, centred in whatever box the holder is given: the
        /// bounds are the frame shrunk by that scale, set again on every change
        /// of frame. The standalone button is 14 by 16 points round a 12 point
        /// dot; fitting that box to a square stretched it across and not down
        /// (6 October 2026), so the scale comes from the dot, never the box.
        override func setFrameSize(_ newSize: NSSize) {
            super.setFrameSize(newSize)
            fitBounds()
        }

        override func layout() {
            super.layout()
            fitBounds()
        }

        private func fitBounds() {
            guard let own = button?.frame.size, frame.width > 0, frame.height > 0 else { return }
            let scale = Theme.compareCloseDot / Theme.trafficLightDot
            let wanted = NSSize(width: frame.width / scale, height: frame.height / scale)
            if bounds.size != wanted { setBoundsSize(wanted) }
            button?.setFrameOrigin(NSPoint(x: (wanted.width - own.width) / 2, y: (wanted.height - own.height) / 2))
        }

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
