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
    //
    // These follow the window they are drawn in: dark as Twine's, or light
    // (the user's request, 6 October 2026, for Settings), worked out from the
    // light Compare card in the user's Figma (node 144:126): its light grey,
    // #1A1A1A type and #525252 secondary type. The menu bar panel is always
    // dark; Settings and the Compare card follow `AppSettings.appearance`.

    /// The window's ground. #1E1E1E dark, #F2F2F2 light.
    public static let canvas = adaptive(dark: 0x1E1E1E, light: 0xF2F2F2)
    /// Every floating card. #2C2C2C dark, #FFFFFF light.
    public static let panel = adaptive(dark: 0x2C2C2C, light: 0xFFFFFF)
    /// Fields, trays, tiles, and hover over `panel`. #383838 dark, #E4E4E4 light.
    public static let panelRaised = adaptive(dark: 0x383838, light: 0xE4E4E4)
    /// Hover over something already on `panelRaised`. #484848 dark, #D6D6D6 light.
    public static let panelHover = adaptive(dark: 0x484848, light: 0xD6D6D6)
    /// Rules, and the edge of every card. #424242 dark, #D9D9D9 light.
    public static let border = adaptive(dark: 0x424242, light: 0xD9D9D9)
    /// A hairline over colour the theme does not control: a swatch, a well.
    /// Translucent so it reads on anything.
    public static let edge = adaptive(dark: Color.white.opacity(0.12), light: Color.black.opacity(0.10))
    /// `edge` under the pointer. On a control whose fill *is* a colour, the
    /// hairline is the only part that can answer a hover without lying.
    public static let edgeHover = adaptive(dark: Color.white.opacity(0.32), light: Color.black.opacity(0.28))

    /// A colour for each mode, chosen by the appearance of whatever draws it.
    static func adaptive(dark: UInt32, light: UInt32) -> Color {
        adaptive(dark: Color(hex: dark), light: Color(hex: light))
    }

    static func adaptive(dark: Color, light: Color) -> Color {
        let darkColor = NSColor(dark), lightColor = NSColor(light)
        return Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? darkColor : lightColor
        })
    }

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
    /// The chosen segment of a row of choices: #5C5C5C dark, white light (on
    /// its tray), never the accent, so settings stay one quiet surface.
    public static let chosen = adaptive(dark: 0x5C5C5C, light: 0xFFFFFF)
    /// A switch that is on, and under the pointer a step further: grey, never
    /// the accent. #5C5C5C dark, #525252 light, so the white pill shows.
    public static let switchOn = adaptive(dark: 0x5C5C5C, light: 0x525252)
    public static let switchOnHover = adaptive(dark: 0x686868, light: 0x3E3E3E)
    /// A switch that is off. #1E1E1E dark, #D6D6D6 light.
    public static let switchOff = adaptive(dark: 0x1E1E1E, light: 0xD6D6D6)

    // MARK: Text (text/*)

    /// White dark, #1A1A1A light.
    public static let textPrimary = adaptive(dark: Color.white, light: Color(hex: 0x1A1A1A))
    /// #B3B3B3 dark, #525252 light.
    public static let textSecondary = adaptive(dark: Color(white: 0.70), light: Color(hex: 0x525252))
    /// Placeholders, units, readouts, disabled. #808080 dark, #8C8C8C light.
    public static let textTertiary = adaptive(dark: Color(white: 0.50), light: Color(hex: 0x8C8C8C))
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
    /// The box an icon is drawn in.
    public static let icon: CGFloat = 20
    /// An icon's line, on its 24-unit grid: it scales with the icon, so a
    /// 20 pt icon draws a 1.6 pt line. The artwork is drawn at 1.5; the app
    /// draws it heavier, as Twine does.
    public static let iconStroke: CGFloat = 1.92
    /// Switch tracks.
    public static let track: CGFloat = 26

    // MARK: Radii (radius/*)

    public static let radiusPanel: CGFloat = 10
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
    /// A panel to the screen's or window's edge.
    public static let floatInset: CGFloat = 8
    /// Round a menu's items.
    public static let menuPad: CGFloat = 4
    public static let rowGap: CGFloat = 4

    // MARK: Menu bar panel

    /// The panel under the menu bar icon: its width, and its gap below the
    /// menu bar.
    public static let menuPanelWidth: CGFloat = 240
    public static let menuPanelGap: CGFloat = 6
    /// The menu bar icon's size.
    public static let menuBarIcon: CGFloat = 18
    /// Every option of the panel is this tall.
    public static let panelOption: CGFloat = 30
    /// The side inset of a row's contents inside its hover ground.
    public static let menuItemPad: CGFloat = 6
    /// A recent colour's swatch, and its corner.
    public static let swatch: CGFloat = 16
    public static let radiusSwatch: CGFloat = 4
    /// How long the menu bar icon shows its tick after a copy.
    public static let copiedFlash: Double = 0.6
    /// The panel fading in and out.
    public static let panelFade: Double = 0.12

    // MARK: Windows

    // MARK: Compare

    /// The Compare card (the user's Figma, Twine file, node 143:21): the
    /// first colour, the contrast, the second colour, stacked with nothing
    /// behind them. Every measure is the design's times `compareScale` (half,
    /// the user's choice on 6 October 2026: the design's 320 by 840 was too
    /// big), type no smaller than `smallestType`.
    public static let compareScale: CGFloat = 0.5
    public static let smallestType: CGFloat = 10
    private static func compare(_ design: CGFloat) -> CGFloat { design * compareScale }
    private static func compareType(_ design: CGFloat) -> CGFloat { max(design * compareScale, smallestType) }

    public static let compareCard = CGSize(width: compare(320), height: compare(840))
    /// The clear margin round the card in its window, so the close button can
    /// stand out past the corner it sits on, whole, with a little room; and
    /// the window's size with it.
    public static let compareMargin = (compareClose / 2).rounded(.up) + 2
    public static let compareWindow = CGSize(width: compareCard.width + swatchGap + swatchColumn + compareMargin * 2,
                                             height: compareCard.height + compareMargin * 2)
    /// The column of recent colours beside the card (node 144:126): its gap
    /// from the card, a swatch (round), the gap between swatches, the
    /// column's own inset, and its width.
    public static let swatchGap = compare(19)
    public static let recentSwatch = compare(48)
    public static let recentSwatchGap = compare(12)
    public static let swatchColumnPad = compare(8)
    public static let swatchColumn = recentSwatch + swatchColumnPad * 2
    /// The card's outer corners, at its top and bottom.
    public static let radiusCompareCard = compare(88)
    /// A piece's faint edge: black at 7%.
    public static let compareEdge = Color.black.opacity(0.07)
    /// The colours' corners where they meet the middle, and the middle's own.
    public static let radiusCompareColor = compare(12)
    public static let radiusCompareMiddle = compare(31)
    /// #1A1A1A. A hex code on a light colour; on a dark one it is
    /// `textOnDark`. Fixed, whatever the window's mode: they are read against
    /// the colour itself.
    public static let textOnLight = Color(hex: 0x1A1A1A)
    public static let textOnDark = Color.white
    /// Above this WCAG luminance a colour takes `textOnLight`.
    public static let lightColor: CGFloat = 0.4
    /// A colour's hex code, and how wide its field is.
    public static let compareHex = compareType(20)
    public static let compareHexField = compare(84)
    /// The middle piece in each appearance (node 144:126): its ground, its
    /// figures and pills, and its ": 1". A pill's outline is its type at 40%;
    /// a level not reached is drawn at `missedLevel` of that.
    public static let middleDark = Color(hex: 0x1E1E1E)
    public static let middleLight = Color(white: 0xDB / 255.0)
    public static let middleInkDark = Color.white
    public static let middleInkLight = textOnLight
    public static let middleUnitDark = Color(white: 0x80 / 255.0)
    public static let middleUnitLight = Color(white: 0x52 / 255.0)
    public static let pillOutline: Double = 0.4
    public static let missedLevel: Double = 0.35
    /// The contrast ratio's figures in the display face, and the ": 1".
    public static let ratioSize = compareType(64)
    public static let ratioUnit = compareType(32)
    public static let ratioGap = compare(8)
    /// The ratio over the level pills, and the pills' gap, inset and type.
    public static let readoutGap = compare(32)
    public static let pillGap = compare(12)
    public static let pillText = compareType(13)
    /// Round the pill's word: the design's 10 and 4 round 13 pt type, kept to
    /// the type's own size, since the type stops shrinking at `smallestType`.
    public static let pillPadH = pillText * 10 / 13 * 0.8
    public static let pillPadV = pillText * 4 / 13
    /// The copy button beside a code: its box and icon.
    public static let hoverButton: CGFloat = 20
    /// How far a press must move before it drags the card rather than clicks.
    public static let dragStart: CGFloat = 3
    /// While a press is held on the card, how often it checks that the
    /// button is still down when no event comes.
    public static let pressPoll: TimeInterval = 0.1
    /// macOS's close button: its own size (14 points, a 12 point dot), and the
    /// size the card draws it, scaled so the dot is 14 points (the user's
    /// choice on 6 October 2026, "a bit bigger", between macOS's 12 and the
    /// design's 16).
    public static let trafficLight: CGFloat = 14
    public static let trafficLightDot: CGFloat = 12
    public static let compareCloseDot: CGFloat = 14
    public static let compareClose = trafficLight * compareCloseDot / trafficLightDot
    /// The copy button beside a hex code, at half strength so it stays quiet,
    /// and its fade as the pointer comes onto its colour and leaves.
    public static let quietButton: Double = 0.5
    public static let copyFade = Animation.easeOut(duration: 0.15)
    public static let hoverIcon: CGFloat = 13
    /// The small icon in a square glyph button.
    public static let buttonIcon: CGFloat = 15
    /// Between a colour's name and its row, used by the history card.
    public static let labelGap: CGFloat = 6
    /// How long the copy button shows its tick.
    public static let copiedShown: Double = 1

    // MARK: Settings

    /// The Settings window: the page's margin, its title's size and the block
    /// it sits at the foot of (under the traffic lights).
    public static let settingsMargin: CGFloat = 24
    public static let settingsTitle: CGFloat = 21
    public static let settingsTitleBlock: CGFloat = 104
    /// The window, much taller than wide (the user's choice: one vertical
    /// list), and the room between its sections.
    public static let settingsWindow = CGSize(width: 460, height: 720)
    public static let settingsSectionGap: CGFloat = 28
    /// A section's name and its first row.
    public static let settingsCardTitleGap: CGFloat = 8
    /// As Twine's Settings page: a row's height, the icon tile at its left
    /// and the icon on it, the width of the control at its right, and the
    /// Version History button.
    public static let settingsRow: CGFloat = 48
    public static let settingsTile: CGFloat = 32
    public static let settingsTileIcon: CGFloat = 16
    public static let settingsControl: CGFloat = 120
    /// The room either side of a segment row option's word, the tray's inset
    /// round its options, and
    /// the line of a drawn glyph (the Appearance tile's circle).
    public static let segmentPad: CGFloat = 8
    public static let trayPad: CGFloat = 2
    public static let glyphLine: CGFloat = 1.5
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

extension Color {
    /// A colour from its hex code, as 0xRRGGBB.
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}
