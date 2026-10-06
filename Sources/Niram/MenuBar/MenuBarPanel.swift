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

/// The card under the menu bar icon, in place of the system menu: Pick Colour,
/// the recent colours with their hex codes, then Show App, Settings and Quit.
/// Every option is the same row (the user's choice, 6 October 2026): no
/// icons, one height, the accent under the pointer; a recent colour keeps its
/// swatch, which is the colour itself.
struct MenuBarPanel: View {
    let recents: RecentColors
    let shortcut: String
    let actions: MenuBarActions

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PanelRow(title: "Pick Colour", shortcut: shortcut, action: actions.pick)

            if !recents.hexes.isEmpty {
                Text("Recent")
                    .font(ThemeFont.caption)
                    .foregroundStyle(Theme.textTertiary)
                    .padding(.horizontal, Theme.menuItemPad)
                    .frame(height: Theme.control, alignment: .bottomLeading)
                ForEach(recents.hexes.prefix(RecentColors.inPanel), id: \.self) { hex in
                    PanelRow(title: hex, swatch: NSColor(hexString: hex), action: { actions.copy(hex) })
                }
            }

            Rectangle().fill(Theme.border).frame(height: Theme.hairline).padding(.vertical, Theme.menuPad)

            PanelRow(title: "Show App", action: actions.compare)
            PanelRow(title: "Settings", shortcut: "⌘,", action: actions.settings)
            PanelRow(title: "Quit Niram", shortcut: "⌘Q", action: actions.quit)
        }
        .padding(Theme.menuPad)
        .frame(width: Theme.menuPanelWidth, alignment: .leading)
        // The window draws the shadow, from the card's own shape: a shadow
        // drawn here would be cut off at the window's edge.
        .floatingPanel(corner: Theme.radiusMenu, shadow: false)
    }
}

/// One option of the panel: a colour's swatch when it is one, its name (a hex
/// code in the code face), and its shortcut at the end; the accent under the
/// pointer.
private struct PanelRow: View {
    let title: String
    var swatch: NSColor?
    var shortcut: String?
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.labelGap) {
                if let swatch {
                    RoundedRectangle(cornerRadius: Theme.radiusSwatch)
                        .fill(Color(nsColor: swatch))
                        .overlay(RoundedRectangle(cornerRadius: Theme.radiusSwatch)
                            .strokeBorder(Theme.edge, lineWidth: Theme.hairline))
                        .frame(width: Theme.swatch, height: Theme.swatch)
                }
                Text(title)
                    .font(swatch == nil ? ThemeFont.label : ThemeFont.hex)
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
            .frame(height: Theme.panelOption)
            .background(RoundedRectangle(cornerRadius: Theme.radiusRow)
                .fill(hovering ? Theme.accent : .clear))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}
