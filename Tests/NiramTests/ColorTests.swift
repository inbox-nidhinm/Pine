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
