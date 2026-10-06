import SwiftUI
import AppKit

/// The two colours being compared, top and bottom of the card.
@MainActor @Observable
final class CompareModel {
    var first: NSColor = NSColor(hexString: "#FFFFFF") ?? .white
    var second: NSColor = NSColor(hexString: "#293029") ?? .black

    var ratio: CGFloat { NSColor.contrastRatio(first, second) }
}

/// The Compare window as the user drew it in Figma (Twine file, node 143:21,
/// which replaced 140:2493 on 6 October 2026): three pieces stacked with
/// nothing behind them, the first colour on top (round at the top), the
/// contrast in the middle (round all round), the second colour at the bottom
/// (round at the bottom), each with a faint edge; where their corners curve
/// away, what is behind the window shows. Drawn at half the design's size
/// (`Theme.compareScale`).
///
/// The design shows the card at rest; the rest is ours, as the user asked: a
/// click anywhere on a colour picks a new one, a click on its code types one,
/// the copy button sits after the code at half strength, and a drag anywhere
/// moves the card, which floats above every other app's windows until its
/// close button takes it away. The design's
/// red dot on the top-left corner is drawn as macOS's own red traffic light
/// (the user's earlier request), a little larger than its own size
/// (`Theme.compareClose`), centred on the corner; the
/// window has a clear margin round the card so it can stand out past it.
struct CompareView: View {
    let model: CompareModel
    let recents: RecentColors
    let close: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: Theme.swatchGap) {
            card
            RecentColumn(recents: recents) { hex, intoSecond in
                guard let color = NSColor(hexString: hex) else { return }
                if intoSecond { model.second = color } else { model.first = color }
            }
            .frame(width: Theme.swatchColumn)
        }
        .padding(Theme.compareMargin)
        .ignoresSafeArea()
    }

    private var card: some View {
        VStack(spacing: 0) {
            ColorSection(color: Binding(get: { model.first }, set: { model.first = $0 }),
                         corners: .init(topLeading: Theme.radiusCompareCard, bottomLeading: Theme.radiusCompareColor,
                                        bottomTrailing: Theme.radiusCompareColor, topTrailing: Theme.radiusCompareCard),
                         picked: remember)
            ContrastSection(model: model)
            ColorSection(color: Binding(get: { model.second }, set: { model.second = $0 }),
                         corners: .init(topLeading: Theme.radiusCompareColor, bottomLeading: Theme.radiusCompareCard,
                                        bottomTrailing: Theme.radiusCompareCard, topTrailing: Theme.radiusCompareColor),
                         picked: remember)
        }
        .frame(width: Theme.compareCard.width, height: Theme.compareCard.height)
        .overlay(alignment: .topLeading) {
            TrafficLightClose(action: close)
                .frame(width: Theme.compareClose, height: Theme.compareClose)
                .offset(x: -Theme.compareClose / 2, y: -Theme.compareClose / 2)
        }
    }

    /// A colour picked on the card joins the recent ones, as one picked with
    /// the shortcut does.
    private func remember(_ color: NSColor) {
        recents.add(AppSettings.formatHex(color))
    }
}

/// The recent colours, newest at the top, as round swatches beside the card
/// (node 144:126). A click puts one in the top colour, an Option-click in the
/// bottom one. Nothing shows until a colour has been picked.
private struct RecentColumn: View {
    let recents: RecentColors
    let use: (String, Bool) -> Void

    var body: some View {
        VStack(spacing: Theme.recentSwatchGap) {
            ForEach(recents.hexes, id: \.self) { hex in
                Button {
                    use(hex, NSEvent.modifierFlags.contains(.option))
                } label: {
                    Circle()
                        .fill(Color(nsColor: NSColor(hexString: hex) ?? .clear))
                        .overlay(Circle().strokeBorder(Theme.compareEdge, lineWidth: Theme.hairline))
                        .frame(width: Theme.recentSwatch, height: Theme.recentSwatch)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Theme.swatchColumnPad)
    }
}

/// One colour filling its third of the card, its hex code in the middle. A
/// click anywhere on the colour picks a new one from the screen and a drag
/// moves the card; a click on the code types one. The copy button sits after
/// the code at half strength, only while the pointer is over the colour, with
/// an empty box of its width before the code so the code stays centred.
private struct ColorSection: View {
    @Binding var color: NSColor
    let corners: RectangleCornerRadii
    /// A colour picked from the screen here, to be remembered.
    let picked: (NSColor) -> Void

    @State private var typed = ""
    @State private var copied = false
    @State private var hovering = false
    @FocusState private var typing: Bool

    private var ink: Color { Niram.ink(on: color) }

    var body: some View {
        ZStack {
            UnevenRoundedRectangle(cornerRadii: corners, style: .continuous)
                .fill(Color(nsColor: color))
                .overlay(UnevenRoundedRectangle(cornerRadii: corners, style: .continuous)
                    .strokeBorder(Theme.compareEdge, lineWidth: Theme.hairline))
            // A click on the colour picks a new one; a drag moves the card.
            PressSurface(corners: corners,
                         onClick: pick,
                         onHover: { over in withAnimation(Theme.copyFade) { hovering = over } })

            HStack(spacing: Theme.rowGap) {
                Color.clear.frame(width: Theme.hoverButton, height: Theme.hoverButton)
                TextField("", text: $typed)
                    .textFieldStyle(.plain)
                    .font(.system(size: Theme.compareHex, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(ink)
                    .frame(width: Theme.compareHexField)
                    .focused($typing)
                    .onSubmit(commit)
                // Only while the pointer is over this colour (the user's
                // request), and while its tick shows after a copy.
                OnColorButton(icon: copied ? .check : .copy, ink: ink, action: copy)
                    .opacity(copied ? 1 : hovering ? Theme.quietButton : 0)
                    .allowsHitTesting(hovering || copied)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { typed = Self.shown(color) }
        .onChange(of: color) { _, newValue in typed = Self.shown(newValue) }
        .onChange(of: typing) { _, isTyping in if !isTyping { commit() } }
    }

    /// The card shows a code as the design does: six figures, no hash. What
    /// is copied follows Settings.
    private static func shown(_ color: NSColor) -> String {
        AppSettings.formatHex(color, uppercase: AppSettings.uppercaseHex, hash: false)
    }

    private func commit() {
        if let parsed = NSColor(typedHex: typed) { color = parsed }
        typed = Self.shown(color)
    }

    private func pick() {
        ColorPicking.shared.pick { new in
            guard let new else { return }
            color = new
            picked(new)
        }
    }

    private func copy() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(AppSettings.formatHex(color), forType: .string)
        copied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + Theme.copiedShown) { copied = false }
    }
}

/// The middle of the card: the ratio in the display face, then a pill for
/// each WCAG level, outlined when reached and dimmed when not. A drag on it
/// moves the card.
private struct ContrastSection: View {
    let model: CompareModel

    /// Dark or light, as the card's window is (`AppSettings.appearance`).
    @Environment(\.colorScheme) private var scheme

    private static let corners = RectangleCornerRadii(topLeading: Theme.radiusCompareMiddle,
                                                      bottomLeading: Theme.radiusCompareMiddle,
                                                      bottomTrailing: Theme.radiusCompareMiddle,
                                                      topTrailing: Theme.radiusCompareMiddle)

    var body: some View {
        let dark = scheme == .dark
        let ink = dark ? Theme.middleInkDark : Theme.middleInkLight
        ZStack {
            RoundedRectangle(cornerRadius: Theme.radiusCompareMiddle, style: .continuous)
                .fill(dark ? Theme.middleDark : Theme.middleLight)
                .overlay(RoundedRectangle(cornerRadius: Theme.radiusCompareMiddle, style: .continuous)
                    .strokeBorder(Theme.compareEdge, lineWidth: Theme.hairline))
            PressSurface(corners: Self.corners)
            VStack(spacing: Theme.readoutGap) {
                HStack(alignment: .lastTextBaseline, spacing: Theme.ratioGap) {
                    Text(shownRatio(model.ratio))
                        .font(ThemeFont.display(Theme.ratioSize, .thin))
                        .foregroundStyle(ink)
                    Text(": 1")
                        .font(ThemeFont.display(Theme.ratioUnit, .thin))
                        .foregroundStyle(dark ? Theme.middleUnitDark : Theme.middleUnitLight)
                }
                HStack(spacing: Theme.pillGap) {
                    ForEach(ContrastLevel.allCases, id: \.self) { level in
                        LevelPill(level: level, passes: level.passes(model.ratio), ink: ink)
                    }
                }
            }
            // The words are not pressable, so a drag on them reaches the
            // surface under them.
            .allowsHitTesting(false)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Dark type on a light colour, white on a dark one.
func ink(on color: NSColor) -> Color {
    color.relativeLuminance > Theme.lightColor ? Theme.textOnLight : Theme.textPrimary
}

/// A WCAG level: its name in the middle's type, outlined at 40% of it, as
/// the design draws it; a level not reached is drawn faint.
private struct LevelPill: View {
    let level: ContrastLevel
    let passes: Bool
    let ink: Color

    var body: some View {
        Text(level.name)
            .font(.system(size: Theme.pillText, weight: .medium))
            .foregroundStyle(ink)
            .padding(.horizontal, Theme.pillPadH)
            .padding(.vertical, Theme.pillPadV)
            .overlay(Capsule().strokeBorder(ink.opacity(Theme.pillOutline), lineWidth: Theme.hairline))
            .opacity(passes ? 1 : Theme.missedLevel)
    }
}

/// A glyph button drawn in the colour of the type it sits beside, so it reads
/// on any colour; its ground shows under the pointer.
private struct OnColorButton: View {
    let icon: Icon
    let ink: Color
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            IconView(icon, size: Theme.hoverIcon)
                .foregroundStyle(ink)
                .frame(width: Theme.hoverButton, height: Theme.hoverButton)
                .background(RoundedRectangle(cornerRadius: Theme.radiusControl)
                    .fill(ink.opacity(hovering ? 0.15 : 0)))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}
