import Foundation
import Observation

/// The last colours picked, newest first, kept in the defaults so they
/// outlast a restart. Each is kept as it was copied, in the hex format of
/// the moment.
@MainActor @Observable
final class RecentColors {
    /// Nine, for the Compare card's column of swatches; the menu bar panel
    /// shows the newest `inPanel`.
    nonisolated static let limit = 9
    nonisolated static let inPanel = 5
    private static let key = "recentColors"

    private(set) var hexes: [String]

    init() {
        hexes = Array((UserDefaults.standard.stringArray(forKey: Self.key) ?? []).prefix(Self.limit))
    }

    func add(_ hex: String) {
        hexes = Self.adding(hex, to: hexes)
        UserDefaults.standard.set(hexes, forKey: Self.key)
    }

    /// `hex` at the front, any earlier copy of it taken out, at most `limit`.
    nonisolated static func adding(_ hex: String, to list: [String]) -> [String] {
        Array(([hex] + list.filter { $0 != hex }).prefix(limit))
    }
}
