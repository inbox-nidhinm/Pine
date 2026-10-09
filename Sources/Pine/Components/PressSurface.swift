import SwiftUI
import AppKit

/// Takes a press over a shape and tells a click from a drag: let go without
/// moving past `Theme.dragStart` and it is a click (`onClick`); move further
/// and the window follows the pointer until it is let go.
///
/// The Compare card moves from wherever it is pressed (the user's request, 6
/// October 2026), yet a click on a colour picks a new one. A SwiftUI button
/// takes the whole press, so a drag on it could not move the window, and a
/// drag gesture can miss posted clicks; this is an AppKit view, so both land.
/// It answers clicks only inside its rounded shape, so the corners it leaves
/// clear let clicks through to what is behind the window.
struct PressSurface: NSViewRepresentable {
    var corners: RectangleCornerRadii
    var onClick: (() -> Void)?
    /// Whether the pointer is over the shape, wherever it is: over what lies
    /// on top of the surface (a code, a button) too.
    var onHover: ((Bool) -> Void)?

    func makeNSView(context: Context) -> Surface { Surface() }

    func updateNSView(_ view: Surface, context: Context) {
        view.corners = corners
        view.onClick = onClick
        view.onHover = onHover
    }

    final class Surface: NSView {
        var corners = RectangleCornerRadii()
        var onClick: (() -> Void)?
        var onHover: ((Bool) -> Void)?
        private var inside = false

        override init(frame: NSRect) {
            super.init(frame: frame)
            addTrackingArea(NSTrackingArea(rect: .zero,
                                           options: [.mouseEnteredAndExited, .mouseMoved, .activeAlways, .inVisibleRect],
                                           owner: self))
        }

        required init?(coder: NSCoder) { fatalError("not used") }

        override func mouseEntered(with event: NSEvent) { follow(event) }
        override func mouseMoved(with event: NSEvent) { follow(event) }
        override func mouseExited(with event: NSEvent) { setInside(false) }

        /// Inside the rounded shape, not merely its box.
        private func follow(_ event: NSEvent) {
            setInside(shape.contains(convert(event.locationInWindow, from: nil)))
        }

        private func setInside(_ now: Bool) {
            guard now != inside else { return }
            inside = now
            onHover?(now)
        }

        override var isFlipped: Bool { true }
        override var mouseDownCanMoveWindow: Bool { false }
        /// The card floats over other apps: the first click on it should act,
        /// not only bring it forward.
        override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

        override func hitTest(_ point: NSPoint) -> NSView? {
            let local = convert(point, from: superview)
            return shape.contains(local) ? self : nil
        }

        override func mouseDown(with event: NSEvent) {
            guard let window else { return }
            let startMouse = NSEvent.mouseLocation
            let startOrigin = window.frame.origin
            var dragging = false
            // Follows the press to its end here, as AppKit's own controls do,
            // but never waits for ever: when no event comes, the button's real
            // state decides, so a release that went elsewhere cannot hold the
            // app in this loop.
            while true {
                guard let next = window.nextEvent(matching: [.leftMouseDragged, .leftMouseUp],
                                                  until: Date(timeIntervalSinceNow: Theme.pressPoll),
                                                  inMode: .eventTracking, dequeue: true) else {
                    if NSEvent.pressedMouseButtons & 1 == 0 { break }
                    continue
                }
                if next.type == .leftMouseUp { break }
                let mouse = NSEvent.mouseLocation
                let moved = CGPoint(x: mouse.x - startMouse.x, y: mouse.y - startMouse.y)
                if !dragging, hypot(moved.x, moved.y) >= Theme.dragStart { dragging = true }
                if dragging {
                    window.setFrameOrigin(CGPoint(x: startOrigin.x + moved.x, y: startOrigin.y + moved.y))
                }
            }
            // A click acts once the press is over, outside this event: a pick
            // started from inside it opened the eyedropper mid-click.
            if !dragging, let onClick {
                DispatchQueue.main.async { onClick() }
            }
        }

        /// The view's rounded shape, with each corner's own radius.
        private var shape: CGPath {
            let r = bounds
            let tl = min(corners.topLeading, r.width / 2, r.height / 2)
            let tr = min(corners.topTrailing, r.width / 2, r.height / 2)
            let br = min(corners.bottomTrailing, r.width / 2, r.height / 2)
            let bl = min(corners.bottomLeading, r.width / 2, r.height / 2)
            let path = CGMutablePath()
            path.move(to: CGPoint(x: r.minX + tl, y: r.minY))
            path.addLine(to: CGPoint(x: r.maxX - tr, y: r.minY))
            path.addArc(tangent1End: CGPoint(x: r.maxX, y: r.minY), tangent2End: CGPoint(x: r.maxX, y: r.minY + tr), radius: tr)
            path.addLine(to: CGPoint(x: r.maxX, y: r.maxY - br))
            path.addArc(tangent1End: CGPoint(x: r.maxX, y: r.maxY), tangent2End: CGPoint(x: r.maxX - br, y: r.maxY), radius: br)
            path.addLine(to: CGPoint(x: r.minX + bl, y: r.maxY))
            path.addArc(tangent1End: CGPoint(x: r.minX, y: r.maxY), tangent2End: CGPoint(x: r.minX, y: r.maxY - bl), radius: bl)
            path.addLine(to: CGPoint(x: r.minX, y: r.minY + tl))
            path.addArc(tangent1End: CGPoint(x: r.minX, y: r.minY), tangent2End: CGPoint(x: r.minX + tl, y: r.minY), radius: tl)
            path.closeSubpath()
            return path
        }
    }
}
