import SwiftUI
import AppKit

extension View {
    /// The card every panel and popup is drawn on, as Twine's. Each needs its
    /// own edge: a border alone reads as a seam and a shadow alone as a
    /// smudge. A card lying flat on a page takes no shadow.
    func floatingPanel(corner: CGFloat = Theme.radiusPanel, shadow: Bool = true) -> some View {
        // Grained inside the background rather than over the finished card,
        // so the texture stays under the labels and glyphs.
        background(RoundedRectangle(cornerRadius: corner)
            .fill(Theme.panel)
            .grained()
            .clipShape(RoundedRectangle(cornerRadius: corner)))
            .overlay(RoundedRectangle(cornerRadius: corner)
                .strokeBorder(Theme.border, lineWidth: Theme.hairline))
            .clipShape(RoundedRectangle(cornerRadius: corner))
            .shadow(color: shadow ? Theme.shadow : .clear, radius: shadow ? Theme.shadowRadius : 0, y: shadow ? Theme.shadowY : 0)
    }

    /// A window's whole ground: the canvas colour with the grain over it.
    func windowGround() -> some View {
        background(Theme.canvas.grained().ignoresSafeArea())
    }
}

/// A titled card raised by a control, built from the panel's own parts rather
/// than `NSPopover`, which always draws an arrow and a light backing.
struct PopupCard<Accessory: View, Content: View>: View {
    let title: String
    var width: CGFloat
    @ViewBuilder var accessory: () -> Accessory
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Text(title)
                    .font(ThemeFont.labelStrong)
                    .foregroundStyle(Theme.textPrimary)
                Spacer(minLength: 0)
                accessory()
            }
            .padding(.horizontal, Theme.panelPad)
            .frame(height: Theme.cardHeader)
            .overlay(alignment: .bottom) { Rectangle().fill(Theme.border).frame(height: Theme.hairline) }

            VStack(alignment: .leading, spacing: 8) { content() }
                .padding(Theme.panelPad)
        }
        .frame(width: width)
        .floatingPanel()
    }
}

extension PopupCard where Accessory == EmptyView {
    init(title: String, width: CGFloat, @ViewBuilder content: @escaping () -> Content) {
        self.init(title: title, width: width, accessory: { EmptyView() }, content: content)
    }
}

/// Places the window's traffic lights in from the corner by the same inset as
/// the cards' contents, as Twine does.
///
/// AppKit lays the buttons out again whenever the title bar changes (on
/// becoming key, on a title change), so `keepPlaced` watches their frames and
/// puts them back a turn later, once per burst of changes, giving up after a
/// few tries that do not stick. Moving them from inside AppKit's own layout
/// recursed until Twine crashed.
@MainActor
enum TrafficLights {
    static let origin = CGPoint(x: Theme.trafficLightInset, y: Theme.trafficLightInset)

    private static var pending: Set<ObjectIdentifier> = []
    private static var misses: [ObjectIdentifier: Int] = [:]

    static func keepPlaced(in window: NSWindow) {
        for button in buttons(of: window) {
            button.postsFrameChangedNotifications = true
            NotificationCenter.default.addObserver(forName: NSView.frameDidChangeNotification, object: button,
                                                   queue: .main) { [weak window] _ in
                MainActor.assumeIsolated {
                    if let window { schedule(window) }
                }
            }
        }
        schedule(window)
    }

    /// Resets the give-up count, for when the window comes on screen again.
    static func retry(in window: NSWindow) {
        misses[ObjectIdentifier(window)] = 0
        schedule(window)
    }

    private static func buttons(of window: NSWindow) -> [NSButton] {
        [NSWindow.ButtonType.closeButton, .miniaturizeButton, .zoomButton].compactMap { window.standardWindowButton($0) }
    }

    private static func schedule(_ window: NSWindow) {
        let key = ObjectIdentifier(window)
        guard !pending.contains(key), misses[key, default: 0] < 3 else { return }
        pending.insert(key)
        DispatchQueue.main.async { [weak window] in
            pending.remove(key)
            guard let window else { return }
            if place(in: window) { misses[key] = 0 } else { misses[key, default: 0] += 1 }
        }
    }

    /// Returns true if the buttons are where they belong afterwards.
    @discardableResult
    private static func place(in window: NSWindow) -> Bool {
        let buttons = buttons(of: window)
        guard let close = buttons.first, let bar = close.superview, bar.frame.height > origin.y else { return false }
        // The title bar view is not flipped, so further down is a smaller y.
        let wantedMaxY = bar.frame.height - origin.y
        let dy = wantedMaxY - close.frame.maxY
        let dx = origin.x - close.frame.minX
        if abs(dx) <= 0.5 && abs(dy) <= 0.5 { return true }
        for button in buttons {
            button.setFrameOrigin(CGPoint(x: button.frame.minX + dx, y: button.frame.minY + dy))
        }
        return abs(close.frame.minX - origin.x) <= 0.5 && abs(close.frame.maxY - wantedMaxY) <= 0.5
    }
}

/// A window with no visible title bar: the content runs to the top edge and
/// the traffic lights float over it.
///
/// A click anywhere that is not the text field being edited ends the edit, the
/// way clicking away from a field does in Figma. AppKit's default keeps a
/// field focused through clicks on anything that cannot itself take focus.
final class ChromelessWindow: NSWindow {
    override func sendEvent(_ event: NSEvent) {
        if event.type == .leftMouseDown || event.type == .rightMouseDown,
           let fieldEditor = firstResponder as? NSText,
           let field = fieldEditor.delegate as? NSView {
            let hit = viewUnder(event.locationInWindow)
            if hit.map({ !$0.isDescendant(of: field) }) ?? true {
                // Resigning commits the field, the same as pressing Return.
                makeFirstResponder(nil)
            }
        }
        super.sendEvent(event)
    }

    /// The frontmost view at a point in window coordinates, as a click there
    /// would find it. `hitTest` takes its point in the superview's coordinates:
    /// for the content view that is the frame view, which runs upward, whereas
    /// the content view runs downward. Converting into the content view instead
    /// mirrors the point top to bottom.
    func viewUnder(_ locationInWindow: NSPoint) -> NSView? {
        guard let content = contentView else { return nil }
        return content.hitTest(content.superview?.convert(locationInWindow, from: nil) ?? locationInWindow)
    }

    /// Nothing is focused when a window opens. Left alone, AppKit hands the
    /// keyboard to the first text field it finds.
    func clearInitialFocus() {
        DispatchQueue.main.async { [weak self] in self?.makeFirstResponder(nil) }
    }
}

/// A dark, chromeless window holding a SwiftUI view, sized to the view or to
/// `size`. A view that runs up under the hidden title bar passes its size:
/// left to fit, the window counts the title bar's height on top of it.
@MainActor
func makeChromelessWindow<Content: View>(_ root: Content, size: CGSize? = nil) -> ChromelessWindow {
    let hosting = NSHostingView(rootView: root)
    if size != nil { hosting.sizingOptions = [] }
    let window = ChromelessWindow(contentRect: NSRect(origin: .zero, size: size ?? hosting.fittingSize),
                                  styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
                                  backing: .buffered, defer: false)
    window.contentView = hosting
    window.titlebarAppearsTransparent = true
    window.titleVisibility = .hidden
    window.isMovableByWindowBackground = true
    window.appearance = NSAppearance(named: .darkAqua)
    window.backgroundColor = NSColor(Theme.canvas)
    window.isReleasedWhenClosed = false
    window.isRestorable = false
    window.center()
    TrafficLights.keepPlaced(in: window)
    return window
}

/// A window that is only its content's shape, as the Compare card: no title
/// bar and no traffic lights, see-through round the card, with the window's
/// own shadow following it. It floats above other apps' windows, so it never
/// goes behind them, and leaves the screen only by its close button or ⌘W
/// (the user's choice, 6 October 2026: Escape no longer closes it).
final class CardWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    /// Escape ends typing in a code, and nothing else.
    override func cancelOperation(_ sender: Any?) {
        if firstResponder is NSText { makeFirstResponder(nil) }
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.modifierFlags.intersection(.deviceIndependentFlagsMask) == .command,
           event.charactersIgnoringModifiers == "w" {
            close()
            return true
        }
        return super.performKeyEquivalent(with: event)
    }

    /// A click outside the field being typed in ends the typing, as in
    /// `ChromelessWindow`.
    override func sendEvent(_ event: NSEvent) {
        if event.type == .leftMouseDown,
           let fieldEditor = firstResponder as? NSText,
           let field = fieldEditor.delegate as? NSView,
           let content = contentView {
            let hit = content.hitTest(content.superview?.convert(event.locationInWindow, from: nil) ?? event.locationInWindow)
            if hit.map({ !$0.isDescendant(of: field) }) ?? true { makeFirstResponder(nil) }
        }
        super.sendEvent(event)
    }
}

@MainActor
func makeCardWindow<Content: View>(_ root: Content, size: CGSize) -> CardWindow {
    let hosting = NSHostingView(rootView: root)
    hosting.sizingOptions = []
    let window = CardWindow(contentRect: NSRect(origin: .zero, size: size),
                            styleMask: [.borderless], backing: .buffered, defer: false)
    window.contentView = hosting
    window.isOpaque = false
    window.backgroundColor = .clear
    window.hasShadow = true
    window.isMovableByWindowBackground = true
    window.appearance = NSAppearance(named: .darkAqua)
    window.isReleasedWhenClosed = false
    window.isRestorable = false
    // Above every other app's windows, and still there when Niram is not
    // the app in front.
    window.level = .floating
    window.hidesOnDeactivate = false
    window.center()
    return window
}
