import SwiftUI
import AppKit

/// Every colour, size, radius and type style in Niram, in one place.
///
/// Taken from the "Flip Design System" page of the JUI Figma file
/// (2XErpBfGuIGNU0DkL58Ute, node 171:2055), as Twine's are. The one deliberate
/// difference is the accent: Niram is magenta (#E2387F) where Flip is green and
/// Twine blue, and the tokens derived from the accent (`accentHover`,
/// `rowSelected`) are worked out again to match.
///
/// Views read these and never write a literal. If a view needs a value that is
/// not here, it belongs here first.
public enum Theme {

    // MARK: Surfaces (surface/*, border/*)

    /// #1E1E1E. The window's ground, and the track inside sliders and toggles.
    public static let canvas = Color(red: 0x1E / 255, green: 0x1E / 255, blue: 0x1E / 255)
    /// #2C2C2C. Every floating card.
    public static let panel = Color(red: 0x2C / 255, green: 0x2C / 255, blue: 0x2C / 255)
    /// #383838. Fields, trays, and hover over `panel`.
    public static let panelRaised = Color(red: 0x38 / 255, green: 0x38 / 255, blue: 0x38 / 255)
    /// #484848. Hover over something already on `panelRaised`.
    public static let panelHover = Color(red: 0x48 / 255, green: 0x48 / 255, blue: 0x48 / 255)
    /// #424242. Rules, and the edge of every card.
    public static let border = Color(red: 0x42 / 255, green: 0x42 / 255, blue: 0x42 / 255)
    /// A hairline over colour the theme does not control: a swatch, a well.
    /// Translucent so it reads on anything.
    public static let edge = Color.white.opacity(0.12)
    /// `edge` under the pointer. On a control whose fill *is* a colour, the
    /// hairline is the only part that can answer a hover without lying.
    public static let edgeHover = Color.white.opacity(0.32)

    // MARK: Accent (accent/*, row/*)

    /// #E2387F. What is in hand or about to happen: the main button, the
    /// shortcut being recorded, a field being typed in.
    public static let accent = Color(red: 0xE2 / 255, green: 0x38 / 255, blue: 0x7F / 255)
    /// #E86099, the accent under the pointer: a fifth of the way to white.
    /// Lighter rather than darker, because a step down would read as disabled.
    public static let accentHover = Color(red: 0xE8 / 255, green: 0x60 / 255, blue: 0x99 / 255)
    /// #633045. A selected row: the accent a little under a third of the way
    /// over `panel`, pulled greyer, as Twine's blue row was mixed by eye.
    public static let rowSelected = Color(red: 0x63 / 255, green: 0x30 / 255, blue: 0x45 / 255)
    /// #5C5C5C. What is chosen among settings: a segment, a switch that is on.
    /// Grey rather than the accent, so settings stay one quiet surface.
    public static let chosen = Color(red: 0x5C / 255, green: 0x5C / 255, blue: 0x5C / 255)
    /// `chosen` under the pointer: a step lighter, as `accentHover` is.
    public static let chosenHover = Color(red: 0x68 / 255, green: 0x68 / 255, blue: 0x68 / 255)
    /// A row under the pointer. Translucent so the grain shows through.
    public static let rowHover = Color.white.opacity(0.057)

    // MARK: Text (text/*)

    public static let textPrimary = Color.white
    public static let textSecondary = Color(white: 0.70)
    /// Placeholders, units, readouts, disabled.
    public static let textTertiary = Color(white: 0.50)
    /// Words and glyphs on a coloured fill, such as the main button.
    public static let textOnColor = Color.white

    // MARK: Controls (control/*)

    /// The white pill in sliders and toggles.
    public static let thumb = Color.white
    /// The small bar on a pill that says it can be dragged.
    public static let grip = Color(white: 0.72)
    /// A dividing line, and the header row of a card under which one runs.
    public static let hairline: CGFloat = 1
    public static let cardHeader: CGFloat = 34
    /// The shadow under every floating card.
    public static let shadow = Color.black.opacity(0.4)
    public static let shadowRadius: CGFloat = 12
    public static let shadowY: CGFloat = 4

    /// How strongly surfaces take their grain. 1 is the artwork as drawn.
    public static let grain: Double = 1

    // MARK: Sizes (size/*)

    /// Every pressable thing in a panel is this tall.
    public static let control: CGFloat = 24
    /// A button with a glyph and a word. One step up from `control`.
    public static let button: CGFloat = control + 8
    /// The main button of a card.
    public static let primaryButton: CGFloat = 36
    /// The box an icon is drawn in.
    public static let icon: CGFloat = 20
    /// An icon in a small button or a row.
    public static let smallIcon: CGFloat = 16
    /// An icon's line, on its 24-unit grid: it scales with the icon, so a
    /// 20 pt icon draws a 1.6 pt line. The artwork is drawn at 1.5; the app
    /// draws it heavier, as Twine does.
    public static let iconStroke: CGFloat = 1.92
    public static let panelRow: CGFloat = 24
    public static let listRow: CGFloat = 32
    /// Switch tracks.
    public static let track: CGFloat = 26

    // MARK: Radii (radius/*)

    public static let radiusPanel: CGFloat = 10
    public static let radiusCard: CGFloat = 12
    public static let radiusControl: CGFloat = 5
    public static let radiusTrack: CGFloat = 7
    public static let radiusRow: CGFloat = 4
    public static let radiusMenu: CGFloat = 8
    public static let radiusWell: CGFloat = 8

    /// A button's corner, scaled with its box so buttons of different sizes
    /// still look like one family.
    public static func radius(forButton size: CGFloat) -> CGFloat { max(radiusControl, size * 0.2) }

    // MARK: Spacing (space/*)

    /// What every panel insets its contents by.
    public static let panelPad: CGFloat = 12
    /// Card to window edge.
    public static let floatInset: CGFloat = 8
    /// Card to card.
    public static let floatGap: CGFloat = 8
    /// Round a menu's items.
    public static let menuPad: CGFloat = 4
    public static let rowGap: CGFloat = 4

    // MARK: Menu bar panel

    /// The panel under the menu bar icon: its width, and its gap below the
    /// menu bar.
    public static let menuPanelWidth: CGFloat = 240
    public static let menuPanelGap: CGFloat = 6
    /// The side inset of a row's contents inside its hover ground.
    public static let menuItemPad: CGFloat = 6
    /// An icon in a menu row, and the tick that marks a row as done.
    public static let menuIcon: CGFloat = 15
    /// A recent colour's swatch, and its corner.
    public static let swatch: CGFloat = 16
    public static let radiusSwatch: CGFloat = 4
    /// How long a copied colour shows its tick before the panel goes, and how
    /// long the menu bar icon shows one after a pick.
    public static let copiedPause: Double = 0.35
    public static let copiedFlash: Double = 0.6
    /// The panel fading in and out.
    public static let panelFade: Double = 0.12

    // MARK: Windows

    // MARK: Compare

    /// The Compare window: the preview runs under the whole of it, with the
    /// colours panel floating over its left side.
    public static let compareWindow = CGSize(width: 680, height: 420)
    /// The panel's width, as Twine's layers panel.
    public static let panelWidth: CGFloat = 232
    /// The panel's top row, which holds the traffic lights and the swap button.
    public static let compareHeader: CGFloat = 40
    /// The small icon in a square glyph button.
    public static let buttonIcon: CGFloat = 15
    /// Between a colour's name and its row, and between the two colours.
    public static let labelGap: CGFloat = 6
    public static let sectionGap: CGFloat = 12
    /// The contrast ratio's figures, and the ": 1" after them.
    public static let ratioSize: CGFloat = 56
    public static let ratioUnit: CGFloat = 22
    /// The preview's samples: large "Aa" in the display face, then WCAG's
    /// large text (18 pt) and body text (12 pt) under it.
    public static let previewLarge: CGFloat = 120
    public static let previewLargeText: CGFloat = 18
    public static let previewBodyText: CGFloat = 12
    /// How long the copy button shows its tick.
    public static let copiedShown: Double = 1
    // MARK: Settings

    /// The Settings window: the page's margin, its title's size and the block
    /// it sits at the foot of (under the traffic lights), and the width of
    /// each of its two columns of cards.
    public static let settingsMargin: CGFloat = 24
    public static let settingsTitle: CGFloat = 21
    public static let settingsTitleBlock: CGFloat = 76
    public static let settingsColumn: CGFloat = 300
    /// Between cards, across and down.
    public static let settingsCardGap: CGFloat = 24
    /// A card's name and the card under it.
    public static let settingsCardTitleGap: CGFloat = 8
    /// As Twine's Settings page: a row's height, the icon tile at its left
    /// and the icon on it, the width of the control at its right, the dashes
    /// between rows, and the Version History button.
    public static let settingsRow: CGFloat = 48
    public static let settingsTile: CGFloat = 32
    public static let settingsTileIcon: CGFloat = 16
    public static let settingsControl: CGFloat = 120
    public static let settingsDash: [CGFloat] = [3, 3]
    public static let settingsButton: CGFloat = 140
    /// A switch's track width and the gap round its thumb, and the bar on
    /// the thumb that says it drags.
    public static let switchWidth: CGFloat = 46
    public static let switchInset: CGFloat = 2
    public static let gripWidth: CGFloat = 2
    public static let gripHeight: CGFloat = 10
    public static let radiusGrip: CGFloat = 1
    public static let switchSlide = Animation.easeOut(duration: 0.16)

    // MARK: Version History

    /// The card over the Settings window, its inset and its header row.
    public static let historyWidth: CGFloat = 560
    public static let historyPad: CGFloat = 18
    public static let historyHeader: CGFloat = 38
    /// Behind the card, over the page.
    public static let scrim = Color.black.opacity(0.55)
    /// The steps of running text in the card, from the smallest: between
    /// lines, between two points, between sections, a build's title and what
    /// it says, one build and the next. As Twine's.
    public static let readingLineSpacing: CGFloat = 3
    public static let readingItemGap: CGFloat = 10
    public static let readingSectionGap: CGFloat = 22
    public static let readingTitleGap: CGFloat = 14
    public static let readingBlockGap: CGFloat = 44
    public static let bullet: CGFloat = 3
    public static let buildTitle: CGFloat = 20
    /// How far the traffic lights sit in from the window's corner.
    public static let trafficLightInset: CGFloat = floatInset + panelPad

    // MARK: Motion

    /// Cards appearing and going: cubic-bezier(0.5, 0, 0, 1), as Twine's.
    public static let fade = Animation.timingCurve(0.5, 0, 0, 1, duration: 0.35)
    /// A hover highlight sliding from one item to the next.
    public static let hoverGlide = Animation.timingCurve(0.5, 0, 0, 1, duration: 0.28)
}

// MARK: - Type

/// The type styles, by their names in Figma. SF Pro throughout, except the
/// display face (PP Kyoto) for large numbers and titles.
public enum ThemeFont {
    /// Every label, value and menu row.
    public static let label = Font.system(size: 11)
    /// Section headings and card titles.
    public static let labelStrong = Font.system(size: 11, weight: .semibold)
    /// Secondary lines.
    public static let caption = Font.system(size: 10)
    /// A window's or a card's name.
    public static let title = Font.system(size: 13, weight: .semibold)
    /// A hex code.
    public static let hex = Font.system(size: 12, design: .monospaced)

    /// PP Kyoto, Light for titles and Thin for large numbers.
    public enum DisplayWeight: String, CaseIterable, Sendable {
        case light = "PPKyoto-Light"
        case thin = "PPKyoto-Thin"
    }

    /// The display face. Registered with the process at first use, from the
    /// app's Resources/Fonts. If that fails (as under `swift run`, which has no
    /// app bundle), `Font.custom` falls back to the system face.
    public static func display(_ size: CGFloat, _ weight: DisplayWeight = .light) -> Font {
        _ = registered
        return .custom(weight.rawValue, size: size)
    }

    private static let registered: Bool = {
        DisplayWeight.allCases.map { weight in
            guard let url = Bundle.main.url(forResource: weight.rawValue, withExtension: "otf", subdirectory: "Fonts")
            else { return false }
            return CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }.allSatisfy { $0 }
    }()
}
