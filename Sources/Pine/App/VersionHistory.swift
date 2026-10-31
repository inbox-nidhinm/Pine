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
    static let pushes = 32

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
            "Niram is now called Pine. The first time Pine opens it brings across your recent colours, the Compare card's two colours, your shortcut and your Settings, and moves the eyedropper log to ~/Library/Logs/Pine.",
            "A colour picked with the shortcut or from the menu bar panel also goes into the Compare card, alternating: each pick replaces whichever of the two colours was changed longer ago, so changing the top one on the card yourself sends the next pick to the bottom. This happens even while the card is closed, and the card keeps its two colours when Pine quits.",
            "The menu bar icon opens a panel in Pine's own look in place of the system menu, every option the same row with no icons: Pick Colour with its shortcut, the recent colours with their hex codes (a click copies one again), then Show App, Settings (⌘,) and Quit Pine (⌘Q). Escape or a click anywhere else closes it.",
            "Pine has its own icons, the designer's: the app icon, and a new menu bar icon that follows the menu bar's colour.",
            "Show Pine in, under General in Settings: Menu Bar (as before), Dock, or Both. In the Dock Pine is an ordinary app, in ⌘Tab, with an app menu (Pick Colour, Show App, Settings, Quit), an Edit menu so copy and paste work while typing a hex code, and a Dock menu; clicking its Dock icon shows the app.",
            "Recent colours are kept when Pine quits.",
            "Compare is a small stack of three pieces, as drawn in Figma: the first colour on top with its hex code, the contrast in the middle, the second colour at the bottom, each with its own rounded corners and a faint edge, nothing behind them. Click anywhere on a colour to pick a new one from the screen, or click its hex code to type one; the copy button shows beside a code, quietly, while the pointer is over its colour. Press anywhere on the stack and drag to move it. It stays above every other app's windows until you close it with the red button on its top-left corner (macOS's own, drawn a little larger) or ⌘W.",
            "The Compare card follows your Mac's light or dark mode, as drawn in Figma: in light mode its middle is a light grey with dark figures. Settings has an Appearance choice under General: System (the default), Light or Dark.",
            "Settings has a light mode too, following the same Appearance choice as the Compare card: a light grey page with its grain, dark type, grey switches, and tiles, fields and lines that stand out from the page as much as they do in dark mode. The menu bar panel stays dark.",
            "Your recent colours stand in a column of round swatches beside the Compare card, newest at the top. Click one to put it in the top colour, Option-click for the bottom one. Pine now keeps your last nine colours (the menu bar panel shows the latest five), and colours picked on the card join them.",
            "Opening Settings while the Compare card is open puts the card away; closing Settings brings it back. If the card was not open, it stays closed.",
            "The contrast ratio is shown large, in the display face, with a pill for each of AA, AA Large and AAA, outlined when reached and dimmed when not.",
            "Hex codes can be typed in Figma's short forms: 0 is 000000, 1a is 1A1A1A, abc is AABBCC.",
            "Settings is one vertical list in a tall window: Global Shortcut (click it to record a new one), Hex Codes (uppercase, include #, and the hex code a colour would be copied as with those choices) and General (Appearance, Show Pine in, launch at login), each row with its icon. Switches are Twine's own.",
            "Version History, at the foot of Settings beside the build number, lists every build of Pine and what it changed.",
            "The Compare card's middle carries Twine's grain, in light and dark; the colours stay flat.",
            "Nothing in Pine shows a hint when the pointer rests on it.",
            "Every window is dark, with no title bar: the window's ground is Twine's canvas grey with its grain, and the traffic lights sit in from the corner as they do in Twine.",
        ], fixes: [
            "Picking several colours in a row could still leave the screen taking no clicks at all, with no way out but forcing the Mac off. Pine now watches the eyedropper from a thread of its own, twice a second, and clears it whatever state Pine is in, even with its keys and clicks not getting through: when it covers the screen with no magnifier, when it is still up two seconds after Pine's pick ended, or when a pick has run for two minutes. A new pick waits for the last eyedropper to leave the screen rather than ending it and asking again at once, which left picks that never appeared, and a pick that silently dies is let go of so the next one works. What happens is written to ~/Library/Logs/Pine/eyedropper.log.",
            "After a pick, the eyedropper could be left behind, invisible, over every screen connected at the time: nothing there took a click (not even the menu bar or the Dock) though the pointer and hover still worked. The eyedropper belongs to macOS and outlives the app that asked for it, and Pine let go of each one as it started and could start a second over the first. Now only one runs at a time and Pine holds it until it answers; pressing the pick shortcut while picking ends the pick, so the shortcut is always a way out; one left on screen from before is cleared when you next pick; and quitting Pine ends one in progress.",
            "Changing the shortcut could leave it not working when the new keys were the same as the old.",
            "Turning on launch at login now shows what macOS did: if it refuses, the switch goes back off.",
            "After two copies close together, the menu bar icon could stay a tick. It now always comes back.",
            "A contrast ratio is cut to two places, not rounded, so one just short of a level (4.497) no longer reads as reaching it (4.50).",
            "A hex code typed into Compare is taken when you click away, not only when you press Return.",
        ], misc: [
            "Pine says colour, as Twine does, in place of color.",
            "The tick the menu bar icon shows after a copy is the designer's.",
            "Pine takes Twine's look: the Flip Design System's colours, sizes and type, with magenta (#E2387F) as its accent, the grain, a display face for titles and large numbers, and the designer's icons in place of the system's.",
            "The titles and the large contrast ratio are set in AA Bridge Slab, the designer's own font, each at the weight it had and in the cut drawn for its size.",
            "Pine needs macOS 14 or later.",
            "Pine's code is under the MIT License.",
        ]),
        .init(date: "15 July 2026", title: "First version", features: [
            "Pick a colour anywhere on screen with ⇧⌘C (or a shortcut of your own) and its hex code is copied.",
            "The menu bar menu keeps the last five colours picked; choosing one copies it again.",
            "Compare two colours side by side, with their contrast ratio and whether it passes WCAG AA, AA Large and AAA.",
            "Settings: the shortcut, uppercase or lowercase hex, with or without #, and launching at login.",
        ]),
    ]
}
