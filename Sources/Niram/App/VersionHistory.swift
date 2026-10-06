import Foundation

/// What the app has been, newest first, as Twine's.
///
/// A build is a release: a stretch of work you would install and try, not one
/// change. Each lists what it added (`features`), what it mended (`fixes`) and
/// anything else worth knowing (`misc`, left out when empty). Work goes into the
/// top build's lists as it is done; a new build is put at the top of `builds`
/// only when the user says to cut one. `make-app.sh` counts the list into the
/// bundle's version, so nothing else needs editing.
enum VersionHistory {
    static var version: String { "\(builds.count)" }

    /// How many pushes to GitHub the app has had, this one included. Raise it by
    /// one with every push: the first was v0.0.01, the 100th is v0.1.00.
    static let pushes = 3

    static var release: String { String(format: "v0.%d.%02d", pushes / 100, pushes % 100) }

    struct Build: Identifiable {
        let date: String
        let title: String
        var features: [String] = []
        var fixes: [String] = []
        var misc: [String] = []
        var id: String { title }

        /// The lists that have something in them, under their headings.
        var sections: [(heading: String, items: [String])] {
            [("Feature updates", features), ("Bug fixes", fixes), ("Misc", misc)]
                .filter { !$0.1.isEmpty }
        }
    }

    static let builds: [Build] = [
        .init(date: "6 October 2026", title: "The redesign", features: [
            "The menu bar icon opens a panel in Niram's own look in place of the system menu: Pick Colour as its main button, with its shortcut; the recent colours as swatches with their hex codes, each copied again with a click (a tick shows as it copies); then Compare Colours, Settings (⌘,) and Quit Niram (⌘Q). Escape or a click anywhere else closes it.",
            "Recent colours are kept when Niram quits.",
            "The Compare and Settings windows are dark, with no title bar: the window's ground is Twine's canvas grey with its grain, and the traffic lights sit in from the corner as they do in Twine.",
        ], fixes: [
            "After two copies close together, the menu bar icon could stay a tick. It now always comes back.",
        ], misc: [
            "Niram says colour, as Twine does, in place of color.",
            "The tick the menu bar icon shows after a copy is the designer's.",
            "Niram takes Twine's look: the Flip Design System's colours, sizes and type, with magenta (#E2387F) as its accent, the grain, PP Kyoto for large numbers, and the designer's icons in place of the system's.",
            "Niram needs macOS 14 or later.",
        ]),
        .init(date: "15 July 2026", title: "First version", features: [
            "Pick a colour anywhere on screen with ⇧⌘C (or a shortcut of your own) and its hex code is copied.",
            "The menu bar menu keeps the last five colours picked; choosing one copies it again.",
            "Compare two colours side by side, with their contrast ratio and whether it passes WCAG AA, AA Large and AAA.",
            "Settings: the shortcut, uppercase or lowercase hex, with or without #, and launching at login.",
        ]),
    ]
}
