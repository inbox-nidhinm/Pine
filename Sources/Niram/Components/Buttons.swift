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
