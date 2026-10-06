import Testing
@testable import Niram

@Suite struct RecentColorsTests {
    @Test func aNewColourGoesFirst() {
        #expect(RecentColors.adding("#111111", to: ["#222222"]) == ["#111111", "#222222"])
    }

    @Test func aColourPickedAgainMovesToTheFrontOnce() {
        #expect(RecentColors.adding("#222222", to: ["#111111", "#222222", "#333333"]) == ["#222222", "#111111", "#333333"])
    }

    @Test func theListKeepsOnlyTheLimit() {
        let full = (1...RecentColors.limit).map { "#00000\($0)" }
        let after = RecentColors.adding("#FFFFFF", to: full)
        #expect(after.count == RecentColors.limit)
        #expect(after.first == "#FFFFFF")
        #expect(!after.contains(full.last!))
    }
}
