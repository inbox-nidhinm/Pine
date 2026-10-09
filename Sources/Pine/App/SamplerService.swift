import AppKit
import Darwin

/// macOS's ColorSampler service, which draws the eyedropper: what it has on
/// screen, and ending it. Everything here is safe from any thread, so the
/// watchdog can use it while the main thread is busy.
///
/// While it picks, the service lays one window over every screen connected
/// at that moment, at a level above everything, and a magnifier (153 points
/// square) that follows the pointer. It cannot be cancelled through the API,
/// does not clean up after its client, and ignores a polite request to quit.
enum SamplerService {
    /// What the service has on screen now.
    struct Snapshot: Sendable {
        /// Windows covering a whole screen: they take every click there.
        var covers: [CGRect] = []
        /// The magnifier that follows the pointer while it really picks.
        var magnifiers = 0

        var isClear: Bool { covers.isEmpty && magnifiers == 0 }
        var description: String {
            isClear ? "nothing on screen"
                : "\(covers.count) screen cover(s) \(covers.map { "\(Int($0.width))x\(Int($0.height))" }), \(magnifiers) magnifier(s)"
        }
    }

    /// A window narrower than this is the magnifier; anything wider covers a
    /// screen.
    private static let magnifierLimit: CGFloat = 400
    private static let owner = "ColorSampler"
    private static let servicePath = "ColorSampler.xpc/Contents/MacOS/ColorSampler"

    /// Owners and sizes need no screen recording permission.
    static func snapshot() -> Snapshot {
        var shot = Snapshot()
        guard let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] else {
            return shot
        }
        for window in list where (window[kCGWindowOwnerName as String] as? String) == owner {
            guard let bounds = window[kCGWindowBounds as String] as? [String: Any],
                  let width = bounds["Width"] as? Double, let height = bounds["Height"] as? Double else { continue }
            if width < magnifierLimit {
                shot.magnifiers += 1
            } else {
                shot.covers.append(CGRect(x: bounds["X"] as? Double ?? 0, y: bounds["Y"] as? Double ?? 0,
                                          width: width, height: height))
            }
        }
        return shot
    }

    /// Ends the service, taking its windows with it; macOS starts it again
    /// when it is next asked for. Only the user's own service is ended.
    static func end(because reason: String) {
        let pids = servicePIDs()
        EyedropperLog.write("ending the eyedropper service (\(pids.isEmpty ? "not running" : "pid \(pids)")): \(reason); before: \(snapshot().description)")
        for pid in pids { kill(pid, SIGKILL) }
    }

    static var isRunning: Bool { !servicePIDs().isEmpty }

    private static func servicePIDs() -> [pid_t] {
        let count = proc_listallpids(nil, 0)
        guard count > 0 else { return [] }
        var pids = [pid_t](repeating: 0, count: Int(count) * 2)
        let found = proc_listallpids(&pids, Int32(pids.count * MemoryLayout<pid_t>.size))
        guard found > 0 else { return [] }
        var path = [CChar](repeating: 0, count: Int(MAXPATHLEN) * 4)
        return pids.prefix(Int(found)).filter { pid in
            guard pid > 0, proc_pidpath(pid, &path, UInt32(path.count)) > 0 else { return false }
            let bytes = path.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) }
            return String(decoding: bytes, as: UTF8.self).hasSuffix(servicePath) && getuid() == ownerUID(of: pid)
        }
    }

    private static func ownerUID(of pid: pid_t) -> uid_t? {
        var info = proc_bsdinfo()
        let size = Int32(MemoryLayout<proc_bsdinfo>.size)
        guard proc_pidinfo(pid, PROC_PIDTBSDINFO, 0, &info, size) == size else { return nil }
        return info.pbi_uid
    }
}

/// What happens with the eyedropper, written to
/// `~/Library/Logs/Pine/eyedropper.log`, so a stuck screen leaves evidence:
/// on 6 October 2026 the user had to shut the Mac down by force and nothing
/// was left to say why. Kept short: it starts again past 256 KB.
enum EyedropperLog {
    private static let queue = DispatchQueue(label: "pine.eyedropper-log")
    private static let limit = 256 * 1024

    static var url: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Logs/Pine/eyedropper.log")
    }

    static func write(_ line: String) {
        let stamp = ISO8601DateFormatter().string(from: Date())
        let text = "\(stamp) \(line)\n"
        queue.async {
            let fm = FileManager.default
            try? fm.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            if let size = (try? fm.attributesOfItem(atPath: url.path))?[.size] as? Int, size > limit {
                try? fm.removeItem(at: url)
            }
            if let handle = try? FileHandle(forWritingTo: url) {
                handle.seekToEndOfFile()
                handle.write(Data(text.utf8))
                try? handle.close()
            } else {
                try? Data(text.utf8).write(to: url)
            }
        }
    }
}
