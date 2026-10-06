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
/// (the user's earlier request), at its own size, centred on the corner; the
/// window has a clear margin round the card so it can stand out past it.
struct CompareView: View {
    let model: CompareModel
    let close: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ColorSection(color: Binding(get: { model.first }, set: { model.first = $0 }),
                         corners: .init(topLeading: Theme.radiusCompareCard, bottomLeading: Theme.radiusCompareColor,
                                        bottomTrailing: Theme.radiusCompareColor, topTrailing: Theme.radiusCompareCard))
            ContrastSection(model: model)
            ColorSection(color: Binding(get: { model.second }, set: { model.second = $0 }),
                         corners: .init(topLeading: Theme.radiusCompareColor, bottomLeading: Theme.radiusCompareCard,
                                        bottomTrailing: Theme.radiusCompareCard, topTrailing: Theme.radiusCompareColor))
        }
        .frame(width: Theme.compareCard.width, height: Theme.compareCard.height)
        .overlay(alignment: .topLeading) {
            TrafficLightClose(action: close)
                .frame(width: Theme.trafficLight, height: Theme.trafficLight)
                .offset(x: -Theme.trafficLight / 2, y: -Theme.trafficLight / 2)
        }
        .padding(Theme.compareMargin)
        .ignoresSafeArea()
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
            PressSurface(corners: corners, help: "Click to pick a colour from anywhere on screen. Drag to move.",
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
                    .help("Type a hex code. Short forms work: 0, 1a and abc are 000000, 1A1A1A and AABBCC.")
                // Only while the pointer is over this colour (the user's
                // request), and while its tick shows after a copy.
                OnColorButton(icon: copied ? .check : .copy, ink: ink, help: "Copy this colour's hex code", action: copy)
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
        ColorPicking.shared.pick { picked in
            if let picked { color = picked }
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

    private static let corners = RectangleCornerRadii(topLeading: Theme.radiusCompareMiddle,
                                                      bottomLeading: Theme.radiusCompareMiddle,
                                                      bottomTrailing: Theme.radiusCompareMiddle,
                                                      topTrailing: Theme.radiusCompareMiddle)

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Theme.radiusCompareMiddle, style: .continuous)
                .fill(Theme.canvas)
                .overlay(RoundedRectangle(cornerRadius: Theme.radiusCompareMiddle, style: .continuous)
                    .strokeBorder(Theme.compareEdge, lineWidth: Theme.hairline))
            PressSurface(corners: Self.corners)
            VStack(spacing: Theme.readoutGap) {
                HStack(alignment: .lastTextBaseline, spacing: Theme.ratioGap) {
                    Text(shownRatio(model.ratio))
                        .font(ThemeFont.display(Theme.ratioSize, .thin))
                        .foregroundStyle(Theme.textPrimary)
                    Text(": 1")
                        .font(ThemeFont.display(Theme.ratioUnit, .thin))
                        .foregroundStyle(Theme.textTertiary)
                }
                HStack(spacing: Theme.pillGap) {
                    ForEach(ContrastLevel.allCases, id: \.self) { level in
                        LevelPill(level: level, passes: level.passes(model.ratio))
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

private struct LevelPill: View {
    let level: ContrastLevel
    let passes: Bool

    var body: some View {
        let ink = passes ? Theme.textPrimary : Theme.textTertiary
        Text(level.name)
            .font(.system(size: Theme.pillText, weight: .medium))
            .foregroundStyle(ink)
            .padding(.horizontal, Theme.pillPadH)
            .padding(.vertical, Theme.pillPadV)
            .overlay(Capsule().strokeBorder(ink, lineWidth: Theme.hairline))
            .help(level.help)
    }
}

/// A glyph button drawn in the colour of the type it sits beside, so it reads
/// on any colour; its ground shows under the pointer.
private struct OnColorButton: View {
    let icon: Icon
    let ink: Color
    let help: String
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
        .help(help)
    }
}
