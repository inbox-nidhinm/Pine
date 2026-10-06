import Testing
import AppKit
@testable import Niram

@Suite struct ColorTests {
    @Test func hexReadsAndWritesTheSameColour() {
        let color = NSColor(hexString: "#E2387F")
        #expect(color?.hexRRGGBB == "E2387F")
        #expect(NSColor(hexString: "e2387f")?.hexRRGGBB == "E2387F")
    }

    @Test func hexRefusesWhatIsNotSixDigits() {
        #expect(NSColor(hexString: "#FFF") == nil)
        #expect(NSColor(hexString: "#GGGGGG") == nil)
    }

    @Test func blackOnWhiteIsTwentyOneToOne() {
        let ratio = NSColor.contrastRatio(.black, .white)
        #expect(abs(ratio - 21) < 0.01)
    }

    @Test func aColourAgainstItselfIsOneToOne() {
        let color = NSColor(hexString: "#E2387F")!
        #expect(abs(NSColor.contrastRatio(color, color) - 1) < 0.0001)
    }
}

@Suite struct TypedHexTests {
    @Test func shortFormsGrowAsInFigma() {
        #expect(NSColor(typedHex: "0")?.hexRRGGBB == "000000")
        #expect(NSColor(typedHex: "1a")?.hexRRGGBB == "1A1A1A")
        #expect(NSColor(typedHex: "#abc")?.hexRRGGBB == "AABBCC")
        #expect(NSColor(typedHex: " e2387f ")?.hexRRGGBB == "E2387F")
    }

    @Test func nonsenseIsRefused() {
        #expect(NSColor(typedHex: "") == nil)
        #expect(NSColor(typedHex: "#zz") == nil)
        #expect(NSColor(typedHex: "12345") == nil)
    }

    @Test func aRatioJustShortOfALevelNeverReadsAsReachingIt() {
        #expect(shownRatio(4.4999) == "4.49")
        #expect(shownRatio(21) == "21.00")
        #expect(!ContrastLevel.aa.passes(4.4999))
        #expect(ContrastLevel.aaLarge.passes(3))
    }
}

@Suite struct HexFormatTests {
    @Test func eachFormatAsTheSettingsSay() {
        let color = NSColor(hexString: "#E2387F")!
        #expect(AppSettings.formatHex(color, uppercase: true, hash: true) == "#E2387F")
        #expect(AppSettings.formatHex(color, uppercase: false, hash: true) == "#e2387f")
        #expect(AppSettings.formatHex(color, uppercase: true, hash: false) == "E2387F")
    }
}
