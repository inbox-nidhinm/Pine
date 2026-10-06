import SwiftUI

/// What the app has been, as Twine's card: over the Settings page, each build
/// with its title in the display face and its changes under their headings.
struct VersionHistoryCard: View {
    let dismiss: () -> Void

    var body: some View {
        ZStack {
            Theme.scrim
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture(perform: dismiss)

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    HStack(alignment: .firstTextBaseline, spacing: Theme.labelGap) {
                        Text("Version History")
                            .font(ThemeFont.labelStrong)
                            .foregroundStyle(Theme.textPrimary)
                        Text(VersionHistory.release)
                            .font(ThemeFont.caption)
                            .foregroundStyle(Theme.textTertiary)
                    }
                    Spacer(minLength: 0)
                    IconButton(icon: .close, help: "Close (Esc)", action: dismiss)
                        .keyboardShortcut(.cancelAction)
                }
                .padding(.leading, Theme.historyPad)
                .padding(.trailing, (Theme.historyHeader - Theme.control) / 2)
                .frame(height: Theme.historyHeader)
                .overlay(alignment: .bottom) { Rectangle().fill(Theme.border).frame(height: Theme.hairline) }

                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.readingBlockGap) {
                        ForEach(Array(VersionHistory.builds.enumerated()), id: \.element.id) { index, build in
                            buildView(build, number: VersionHistory.builds.count - index)
                        }
                    }
                    .padding(Theme.historyPad)
                }
            }
            .frame(width: Theme.historyWidth)
            .floatingPanel()
            .padding(Theme.settingsMargin)
        }
    }

    private func buildView(_ build: VersionHistory.Build, number: Int) -> some View {
        VStack(alignment: .leading, spacing: Theme.readingTitleGap) {
            HStack(alignment: .firstTextBaseline, spacing: Theme.labelGap) {
                Text(build.title)
                    .font(ThemeFont.display(Theme.buildTitle))
                    .foregroundStyle(Theme.textPrimary)
                Spacer(minLength: 0)
                Text("Build \(number) · \(build.date)")
                    .font(ThemeFont.caption)
                    .foregroundStyle(Theme.textTertiary)
            }
            VStack(alignment: .leading, spacing: Theme.readingSectionGap) {
                ForEach(build.sections, id: \.heading) { section in
                    VStack(alignment: .leading, spacing: Theme.readingItemGap) {
                        Text(section.heading)
                            .font(ThemeFont.labelStrong)
                            .foregroundStyle(Theme.textPrimary)
                        ForEach(section.items, id: \.self) { change in
                            HStack(alignment: .firstTextBaseline, spacing: Theme.labelGap) {
                                Circle().fill(Theme.textTertiary).frame(width: Theme.bullet, height: Theme.bullet)
                                    .alignmentGuide(.firstTextBaseline) { $0[.bottom] + Theme.bullet }
                                Text(change)
                                    .font(ThemeFont.label)
                                    .lineSpacing(Theme.readingLineSpacing)
                                    .foregroundStyle(Theme.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
            }
        }
    }
}
