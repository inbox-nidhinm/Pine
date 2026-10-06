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
    static let pushes = 7

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
            "Compare is a small card, as drawn in Figma: the first colour on top with its hex code, the contrast in the middle, the second colour at the bottom. It has no title bar: drag it to move it, and Escape or ⌘W closes it. Click a hex code to type a new one; the eyedropper and copy buttons show under it while the pointer is over the colour, and the swap button under the levels while it is over the middle.",
            "The contrast ratio is shown large, in PP Kyoto, with a pill for each of AA, AA Large and AAA, outlined when reached and dimmed when not. Hover over one for the ratio it needs.",
            "Hex codes can be typed in Figma's short forms: 0 is 000000, 1a is 1A1A1A, abc is AABBCC.",
            "Settings is laid out as Twine's Settings page: its title under the traffic lights, then cards of rows, each with its icon: Picking (the shortcut, clicked to record a new one), General (launch at login) and Hex Codes (uppercase, include #, and the hex code a colour would be copied as with those choices). Switches are Twine's own. What each setting does is in its tooltip.",
            "Version History, at the foot of Settings beside the build number, lists every build of Niram and what it changed.",
            "Every window is dark, with no title bar: the window's ground is Twine's canvas grey with its grain, and the traffic lights sit in from the corner as they do in Twine.",
        ], fixes: [
            "After a pick, the eyedropper could be left behind, invisible, over every screen connected at the time: nothing there took a click (not even the menu bar or the Dock) though the pointer and hover still worked. The eyedropper belongs to macOS and outlives the app that asked for it, and Niram let go of each one as it started and could start a second over the first. Now only one runs at a time and Niram holds it until it answers; pressing the pick shortcut while picking ends the pick, so the shortcut is always a way out; one left on screen from before is cleared when you next pick; and quitting Niram ends one in progress.",
            "Changing the shortcut could leave it not working when the new keys were the same as the old.",
            "Turning on launch at login now shows what macOS did: if it refuses, the switch goes back off.",
            "After two copies close together, the menu bar icon could stay a tick. It now always comes back.",
            "A contrast ratio is cut to two places, not rounded, so one just short of a level (4.497) no longer reads as reaching it (4.50).",
            "A hex code typed into Compare is taken when you click away, not only when you press Return.",
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
