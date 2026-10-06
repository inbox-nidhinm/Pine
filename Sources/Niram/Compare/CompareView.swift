import SwiftUI
import AppKit

/// The two colours being compared: one as text on the other.
@MainActor @Observable
final class CompareModel {
    var text: NSColor = NSColor(hexString: "#1D1D1F") ?? .black
    var background: NSColor = NSColor(hexString: "#F5F5F7") ?? .white

    var ratio: CGFloat { NSColor.contrastRatio(text, background) }

    func swap() {
        (text, background) = (background, text)
    }
}

/// The Compare window, laid out as Twine's editor: the preview runs under the
/// whole window, the background colour with the text colour's samples on it,
/// and the colours panel floats over its left side.
struct CompareView: View {
    let model: CompareModel

    var body: some View {
        ZStack(alignment: .topLeading) {
            ComparePreview(model: model)
                .padding(.leading, Theme.panelWidth + Theme.floatInset)
            CompareColorsPanel(model: model)
                .padding(Theme.floatInset)
        }
        .frame(width: Theme.compareWindow.width, height: Theme.compareWindow.height)
        .background(Color(nsColor: model.background))
        // Up under the hidden title bar, so the panel's top row holds the
        // traffic lights.
        .ignoresSafeArea()
    }
}

/// The text colour on the background colour: "Aa" in the display face, then a
/// line at WCAG's large text size and one at body size.
private struct ComparePreview: View {
    let model: CompareModel

    var body: some View {
        VStack(spacing: Theme.sectionGap) {
            Text("Aa")
                .font(ThemeFont.display(Theme.previewLarge))
            Text("Aa")
                .font(.system(size: Theme.previewLargeText))
                .help("Large text in WCAG's sense: 18 pt, or 14 pt bold.")
            Text("Aa")
                .font(.system(size: Theme.previewBodyText))
                .help("Body text.")
        }
        .foregroundStyle(Color(nsColor: model.text))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// The panel down the left: the traffic lights and the swap button at its top,
/// the two colours, then the contrast and the levels it reaches.
private struct CompareColorsPanel: View {
    let model: CompareModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Spacer(minLength: 0)
                IconButton(icon: .swap, help: "Swap the text and background colours") { model.swap() }
            }
            .frame(height: Theme.compareHeader)

            VStack(alignment: .leading, spacing: Theme.sectionGap) {
                ColorEntry(title: "Text", color: Binding(get: { model.text }, set: { model.text = $0 }))
                ColorEntry(title: "Background", color: Binding(get: { model.background }, set: { model.background = $0 }))
            }
            .padding(.horizontal, Theme.panelPad)
            .padding(.bottom, Theme.panelPad)

            Rectangle().fill(Theme.border).frame(height: Theme.hairline)

            ContrastReadout(ratio: model.ratio)
                .padding(Theme.panelPad)

            Spacer(minLength: 0)
        }
        .frame(width: Theme.panelWidth)
        .frame(maxHeight: .infinity)
        .floatingPanel()
    }
}

/// One colour: its name, then its swatch and hex code in a field, the
/// eyedropper and the copy button.
private struct ColorEntry: View {
    let title: String
    @Binding var color: NSColor

    @State private var typed = ""
    @State private var copied = false
    @FocusState private var typing: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.labelGap) {
            Text(title)
                .font(ThemeFont.label)
                .foregroundStyle(Theme.textSecondary)
            HStack(spacing: Theme.rowGap) {
                HStack(spacing: Theme.labelGap) {
                    RoundedRectangle(cornerRadius: Theme.radiusSwatch)
                        .fill(Color(nsColor: color))
                        .overlay(RoundedRectangle(cornerRadius: Theme.radiusSwatch)
                            .strokeBorder(Theme.edge, lineWidth: Theme.hairline))
                        .frame(width: Theme.swatch, height: Theme.swatch)
                    TextField("", text: $typed)
                        .textFieldStyle(.plain)
                        .font(ThemeFont.hex)
                        .foregroundStyle(Theme.textPrimary)
                        .focused($typing)
                        .onSubmit(commit)
                }
                .padding(.horizontal, Theme.menuPad)
                .frame(height: Theme.control)
                .background(RoundedRectangle(cornerRadius: Theme.radiusControl).fill(Theme.panelRaised))
                .overlay(RoundedRectangle(cornerRadius: Theme.radiusControl)
                    .strokeBorder(typing ? Theme.accent : .clear, lineWidth: Theme.hairline))
                .help("Type a hex code. Short forms work: 0, 1a and abc are 000000, 1A1A1A and AABBCC.")

                IconButton(icon: .eyedropper, help: "Pick the \(title.lowercased()) colour from anywhere on screen", action: pick)
                IconButton(icon: copied ? .check : .copy, help: "Copy the \(title.lowercased()) colour's hex code", action: copy)
            }
        }
        .onAppear { typed = AppSettings.formatHex(color) }
        .onChange(of: color) { _, newValue in typed = AppSettings.formatHex(newValue) }
        .onChange(of: typing) { _, isTyping in if !isTyping { commit() } }
    }

    /// Takes what was typed, or puts the colour's own code back when it is not
    /// a colour.
    private func commit() {
        if let parsed = NSColor(typedHex: typed) { color = parsed }
        typed = AppSettings.formatHex(color)
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

/// The contrast ratio in the display face, then each WCAG level: a tick when
/// it is reached, a dimmed cross when not.
private struct ContrastReadout: View {
    let ratio: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.labelGap) {
            Text("Contrast")
                .font(ThemeFont.label)
                .foregroundStyle(Theme.textSecondary)
            HStack(alignment: .firstTextBaseline, spacing: Theme.rowGap) {
                Text(shownRatio(ratio))
                    .font(ThemeFont.display(Theme.ratioSize, .thin))
                    .foregroundStyle(Theme.textPrimary)
                Text(": 1")
                    .font(ThemeFont.display(Theme.ratioUnit, .thin))
                    .foregroundStyle(Theme.textTertiary)
            }
            VStack(spacing: 0) {
                ForEach(ContrastLevel.allCases, id: \.self) { level in
                    let passes = level.passes(ratio)
                    HStack(spacing: Theme.labelGap) {
                        Text(level.name)
                            .font(ThemeFont.label)
                        Spacer(minLength: 0)
                        IconView(passes ? .check : .close, size: Theme.buttonIcon)
                    }
                    .foregroundStyle(passes ? Theme.textPrimary : Theme.textTertiary)
                    .frame(height: Theme.panelRow)
                    .help(level.help)
                }
            }
        }
    }
}
