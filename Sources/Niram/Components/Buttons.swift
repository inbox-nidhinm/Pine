import SwiftUI

/// The accent button that does a card's main thing, as Twine's, with an icon
/// before its name and, when it has one, its shortcut at the far end.
struct PrimaryButton: View {
    let title: String
    var icon: Icon?
    var shortcut: String?
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon { IconView(icon, size: Theme.menuIcon) }
                Text(title).font(ThemeFont.labelStrong)
                Spacer(minLength: 0)
                if let shortcut {
                    Text(shortcut)
                        .font(ThemeFont.label)
                        .opacity(0.75)
                }
            }
            .foregroundStyle(Theme.textOnColor)
            .padding(.horizontal, Theme.panelPad - Theme.menuPad)
            .frame(height: Theme.primaryButton)
            .background(RoundedRectangle(cornerRadius: Theme.radiusControl)
                .fill(hovering ? Theme.accentHover : Theme.accent))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}

/// A small square glyph button for panel headers and rows, as Twine's: it
/// lights its ground only under the pointer, and is dimmed only when it
/// cannot be used.
struct IconButton: View {
    let icon: Icon
    var help: String
    var size: CGFloat = Theme.control
    var iconBox: CGFloat = Theme.buttonIcon
    let action: () -> Void

    @State private var hovering = false
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(action: action) {
            IconView(icon, size: iconBox)
                .foregroundStyle(!isEnabled ? Theme.textTertiary : hovering ? Theme.textPrimary : Theme.textSecondary)
                .opacity(isEnabled ? 1 : 0.4)
                .frame(width: size, height: size)
                .background(RoundedRectangle(cornerRadius: Theme.radiusControl)
                    .fill(hovering && isEnabled ? Theme.panelRaised : .clear))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .help(help)
    }
}

/// A plain button for what is not a card's main thing, as Twine's.
struct PanelButton: View {
    let title: String
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(ThemeFont.label)
                .foregroundStyle(Theme.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: Theme.button)
                .background(RoundedRectangle(cornerRadius: Theme.radiusControl)
                    .fill(hovering ? Theme.panelRaised : Theme.panelRaised.opacity(0.5)))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}

/// An on and off switch, as Twine's: grey when on rather than the accent, so
/// settings stay one quiet surface.
struct PillToggle: View {
    let isOn: Bool
    let toggle: () -> Void

    @State private var hovering = false

    var body: some View {
        let thumb = Theme.track - Theme.switchInset * 2
        Button(action: toggle) {
            ZStack(alignment: isOn ? .trailing : .leading) {
                RoundedRectangle(cornerRadius: Theme.radiusTrack)
                    .fill(isOn ? (hovering ? Theme.chosenHover : Theme.chosen) : Theme.canvas)
                    .overlay(RoundedRectangle(cornerRadius: Theme.radiusTrack)
                        .strokeBorder(hovering ? Theme.edgeHover : Theme.edge, lineWidth: Theme.hairline))
                RoundedRectangle(cornerRadius: Theme.radiusTrack - 1)
                    .fill(Theme.thumb)
                    .frame(width: thumb, height: thumb)
                    .overlay(RoundedRectangle(cornerRadius: Theme.radiusGrip).fill(Theme.grip)
                        .frame(width: Theme.gripWidth, height: Theme.gripHeight))
                    .padding(.horizontal, Theme.switchInset)
            }
            .frame(width: Theme.switchWidth, height: Theme.track)
            .animation(Theme.switchSlide, value: isOn)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}
