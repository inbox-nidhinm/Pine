import Foundation

/// Pine was called Niram until 10 October 2026, with the bundle id
/// `com.nidhin.niram`. On the first launch as Pine this brings Niram's
/// settings across (the recent colours, the Compare card's colours, the
/// shortcut and every choice in Settings) when Pine has none of its own, and
/// moves `~/Library/Logs/Niram` to `Pine` when there is no Pine folder yet.
/// It runs once, and never in the test copy. The only code with the old name.
enum FormerName {
    private static let oldDomain = "com.nidhin.niram"
    private static let oldLogs = "Niram"
    private static let carriedKey = "carriedFromFormerName"

    static func carryOver() {
        guard Bundle.main.bundleIdentifier == "com.nidhin.pine" else { return }
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: carriedKey) else { return }

        let own = defaults.persistentDomain(forName: "com.nidhin.pine") ?? [:]
        if own.isEmpty, let old = defaults.persistentDomain(forName: oldDomain) {
            for (key, value) in old { defaults.set(value, forKey: key) }
        }
        defaults.set(true, forKey: carriedKey)

        let files = FileManager.default
        let logs = files.homeDirectoryForCurrentUser.appendingPathComponent("Library/Logs")
        let from = logs.appendingPathComponent(oldLogs)
        let to = logs.appendingPathComponent("Pine")
        if files.fileExists(atPath: from.path), !files.fileExists(atPath: to.path) {
            try? files.moveItem(at: from, to: to)
        }
    }
}
