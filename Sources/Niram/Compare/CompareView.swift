import SwiftUI
import AppKit

/// The two colours being compared, top and bottom of the card.
@MainActor @Observable
final class CompareModel {
    var first: NSColor = NSColor(hexString: "#FFFFFF") ?? .white
    var second: NSColor = NSColor(hexString: "#293029") ?? .black

    var ratio: CGFloat { NSColor.contrastRatio(first, second) }

    func swap() {
        (first, second) = (second, first)
    }
}

/// The Compare window as the user drew it in Figma (Twine file, node
/// 140:2493): one tall card, the first colour on top, the contrast in the
/// middle, the second colour at the bottom. Drawn at half the design's size
/// (`Theme.compareScale`). The design shows the card at rest; the eyedropper, copy and swap buttons are ours and show only under
/// the pointer, and a hex code is typed by clicking it.
struct CompareView: View {
    let model: CompareModel

    var body: some View {
        VStack(spacing: 0) {
            ColorSection(color: Binding(get: { model.first }, set: { model.first = $0 }),
                         corners: .init(bottomLeading: Theme.radiusCompareColor, bottomTrailing: Theme.radiusCompareColor))
            ContrastSection(model: model)
            ColorSection(color: Binding(get: { model.second }, set: { model.second = $0 }),
                         corners: .init(topLeading: Theme.radiusCompareColor, topTrailing: Theme.radiusCompareColor))
        }
        .background(Theme.panelHover)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusCompareCard, style: .continuous))
        .frame(width: Theme.compareCard.width, height: Theme.compareCard.height)
        .ignoresSafeArea()
    }
}

/// One colour filling its third of the card, its hex code in the middle. The
/// code is a field; the eyedropper and copy buttons show under it while the
/// pointer is over the colour.
private struct ColorSection: View {
    @Binding var color: NSColor
    let corners: RectangleCornerRadii

    @State private var typed = ""
    @State private var hovering = false
    @State private var copied = false
    @FocusState private var typing: Bool

    /// Dark type on a light colour, white on a dark one.
    private var ink: Color {
        color.relativeLuminance > Theme.lightColor ? Theme.textOnLight : Theme.textPrimary
    }

    var body: some View {
        ZStack {
            UnevenRoundedRectangle(cornerRadii: corners, style: .continuous)
                .fill(Color(nsColor: color))

            TextField("", text: $typed)
                .textFieldStyle(.plain)
                .font(.system(size: Theme.compareHex, weight: .semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(ink)
                .frame(width: Theme.compareHexField)
                .focused($typing)
                .onSubmit(commit)
                .help("Type a hex code. Short forms work: 0, 1a and abc are 000000, 1A1A1A and AABBCC.")
                .overlay(alignment: .top) {
                    HStack(spacing: Theme.rowGap) {
                        OnColorButton(icon: .eyedropper, ink: ink, help: "Pick this colour from anywhere on screen", action: pick)
                        OnColorButton(icon: copied ? .check : .copy, ink: ink, help: "Copy this colour's hex code", action: copy)
                    }
                    .alignmentGuide(.top) { $0[.top] - Theme.compareHex - Theme.hoverGap }
                    .opacity(hovering || copied ? 1 : 0)
                    .allowsHitTesting(hovering)
                }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onHover { over in withAnimation(Theme.hoverFade) { hovering = over } }
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
        NSColorSampler().show { picked in
            guard let picked else { return }
            DispatchQueue.main.async { color = picked }
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
/// each WCAG level, outlined when reached and dimmed when not. The swap button
/// shows under the pills while the pointer is over it.
private struct ContrastSection: View {
    let model: CompareModel

    @State private var hovering = false

    var body: some View {
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
            .overlay(alignment: .bottom) {
                OnColorButton(icon: .swap, ink: Theme.textPrimary, help: "Swap the two colours") { model.swap() }
                    .alignmentGuide(.bottom) { $0[.bottom] - Theme.hoverGap - Theme.hoverButton }
                    .opacity(hovering ? 1 : 0)
                    .allowsHitTesting(hovering)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RoundedRectangle(cornerRadius: Theme.radiusCompareMiddle, style: .continuous).fill(Theme.canvas))
        .contentShape(Rectangle())
        .onHover { over in withAnimation(Theme.hoverFade) { hovering = over } }
    }
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
