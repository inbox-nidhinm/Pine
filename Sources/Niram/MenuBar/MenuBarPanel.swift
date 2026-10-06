import SwiftUI
import AppKit

/// What the panel under the menu bar icon can ask the app to do.
struct MenuBarActions {
    var pick: () -> Void
    var copy: (String) -> Void
    var compare: () -> Void
    var settings: () -> Void
    var quit: () -> Void
}

/// The card under the menu bar icon, in place of the system menu: Pick Colour
/// as the main button, the recent colours as swatches with their hex codes,
/// then the app's commands as Twine's menu rows.
struct MenuBarPanel: View {
    let recents: RecentColors
    let shortcut: String
    let actions: MenuBarActions

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PrimaryButton(title: "Pick Colour", icon: .eyedropper, shortcut: shortcut, action: actions.pick)

            if !recents.hexes.isEmpty {
                Text("Recent")
                    .font(ThemeFont.caption)
                    .foregroundStyle(Theme.textTertiary)
                    .padding(.horizontal, Theme.menuItemPad)
                    .frame(height: Theme.control, alignment: .bottomLeading)
                ForEach(recents.hexes.prefix(RecentColors.inPanel), id: \.self) { hex in
                    RecentColorRow(hex: hex) { actions.copy(hex) }
                }
            }

            Rectangle().fill(Theme.border).frame(height: Theme.hairline).padding(.vertical, Theme.menuPad)

            CommandRow(title: "Compare Colours", icon: .swap, action: actions.compare)
            CommandRow(title: "Settings", icon: .settings, shortcut: "⌘,", action: actions.settings)
            CommandRow(title: "Quit Niram", icon: .close, shortcut: "⌘Q", action: actions.quit)
        }
        .padding(Theme.menuPad)
        .frame(width: Theme.menuPanelWidth, alignment: .leading)
        // The window draws the shadow, from the card's own shape: a shadow
        // drawn here would be cut off at the window's edge.
        .floatingPanel(corner: Theme.radiusMenu, shadow: false)
    }
}

/// A recent colour: its swatch and hex code. A click copies it, and the copy
/// icon at the end becomes a tick.
private struct RecentColorRow: View {
    let hex: String
    let copy: () -> Void

    @State private var hovering = false
    @State private var copied = false

    var body: some View {
        Button {
            copied = true
            copy()
        } label: {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: Theme.radiusSwatch)
                    .fill(Color(nsColor: NSColor(hexString: hex) ?? .clear))
                    .overlay(RoundedRectangle(cornerRadius: Theme.radiusSwatch)
                        .strokeBorder(hovering ? Theme.edgeHover : Theme.edge, lineWidth: Theme.hairline))
                    .frame(width: Theme.swatch, height: Theme.swatch)
                Text(hex)
                    .font(ThemeFont.hex)
                    .foregroundStyle(Theme.textPrimary)
                Spacer(minLength: 0)
                IconView(copied ? .check : .copy, size: Theme.menuIcon)
                    .foregroundStyle(copied ? Theme.textPrimary : Theme.textTertiary)
                    .opacity(hovering || copied ? 1 : 0)
            }
            .padding(.horizontal, Theme.menuItemPad)
            .frame(height: Theme.listRow)
            .background(RoundedRectangle(cornerRadius: Theme.radiusRow)
                .fill(hovering ? Theme.panelRaised : .clear))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}

/// One of the app's commands, as a row of Twine's menus: the accent behind it
/// under the pointer, its shortcut at the end.
private struct CommandRow: View {
    let title: String
    let icon: Icon
    var shortcut: String?
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                IconView(icon, size: Theme.menuIcon)
                Text(title)
                    .font(ThemeFont.label)
                    .lineLimit(1)
                Spacer(minLength: 0)
                if let shortcut {
                    Text(shortcut)
                        .font(ThemeFont.label)
                        .foregroundStyle(hovering ? Theme.textOnColor.opacity(0.75) : Theme.textTertiary)
                }
            }
            .foregroundStyle(Theme.textPrimary)
            .padding(.horizontal, Theme.menuItemPad)
            .frame(height: Theme.control)
            .background(RoundedRectangle(cornerRadius: Theme.radiusRow)
                .fill(hovering ? Theme.accent : .clear))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}
