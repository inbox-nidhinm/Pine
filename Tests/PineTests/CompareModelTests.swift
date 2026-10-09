import AppKit
import Testing
@testable import Pine

@MainActor @Suite(.serialized) struct CompareModelTests {
    /// One defaults domain for these tests, emptied before and after each
    /// (a domain per test left a file behind for each).
    private func withDefaults(_ body: (UserDefaults) -> Void) {
        let name = "com.nidhin.pine.tests"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        defer { defaults.removePersistentDomain(forName: name) }
        body(defaults)
    }

    private func color(_ hex: String) -> NSColor { NSColor(hexString: hex)! }

    @Test func picksAlternateTopThenBottom() {
        withDefaults { defaults in
            let model = CompareModel(defaults: defaults)
            model.take(color("#111111"))
            model.take(color("#222222"))
            model.take(color("#333333"))
            #expect(model.first.hexRRGGBB == "333333")
            #expect(model.second.hexRRGGBB == "222222")
        }
    }

    @Test func aChangeOnTheCardSendsTheNextPickToTheOtherColour() {
        withDefaults { defaults in
            let model = CompareModel(defaults: defaults)
            model.first = color("#AA0000")
            model.take(color("#00AA00"))
            #expect(model.first.hexRRGGBB == "AA0000")
            #expect(model.second.hexRRGGBB == "00AA00")
        }
    }

    @Test func settingTheSameColourAgainDoesNotCount() {
        withDefaults { defaults in
            let model = CompareModel(defaults: defaults)
            model.first = color("#FFFFFF")
            model.take(color("#123456"))
            #expect(model.first.hexRRGGBB == "123456")
        }
    }

    @Test func theColoursAndTheTurnOutlastARestart() {
        withDefaults { defaults in
            let model = CompareModel(defaults: defaults)
            model.take(color("#C7BCD4"))
            let again = CompareModel(defaults: defaults)
            #expect(again.first.hexRRGGBB == "C7BCD4")
            #expect(again.second.hexRRGGBB == "293029")
            #expect(again.next == .second)
        }
    }
}
