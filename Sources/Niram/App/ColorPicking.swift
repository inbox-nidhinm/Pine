import AppKit
import Darwin

/// Every pick from the screen goes through here: the shortcut, the panel's
/// Pick Colour and Compare's eyedroppers.
///
/// The eyedropper is not Niram's. `NSColorSampler` asks macOS's ColorSampler
/// service, a process of its own, to lay a window over every screen connected
/// at that moment, at a level above everything. It has no way to be
/// cancelled, and it does not clean up after its client: on 6 October 2026 a
/// sampler whose app had quit stayed up, holding every screen it covered,
/// until the service was killed. Before this, Niram dropped each sampler the
/// moment it had started it and would start a second over the first (the
/// shortcut works while picking), and the user was left with a main screen
/// that took no clicks while a screen connected afterwards did.
///
/// So: the sampler is held until it answers; only one runs at a time; the
/// shortcut pressed while picking ends the pick (`end()`), which is always a
/// way out; a sampler still on screen that Niram did not start is ended before
/// a new one; and quitting ends one in progress.
@MainActor
final class ColorPicking {
    static let shared = ColorPicking()

    /// The sampler running now, held until it answers.
    private var sampler: NSColorSampler?
    /// Who asked, and the pick that answers them, so a late answer from an
    /// ended pick is ignored.
    private var completion: ((NSColor?) -> Void)?
    private var session = 0

    var isPicking: Bool { sampler != nil }

    /// Starts the eyedropper unless one is already up. Returns whether it
    /// started.
    @discardableResult
    func pick(_ done: @escaping (NSColor?) -> Void) -> Bool {
        guard sampler == nil else { return false }
        if Self.samplerOnScreen() {
            // Left over from before (another app, or a pick lost before this
            // fix): it would sit on top of the new one.
            Self.endSamplerService()
        }
        session += 1
        let current = session
        let sampler = NSColorSampler()
        self.sampler = sampler
        completion = done
        sampler.show { [weak self] color in
            // Copied before leaving this thread: a colour is not Sendable.
            let picked = color?.copy() as? NSColor
            DispatchQueue.main.async {
                MainActor.assumeIsolated { self?.answer(picked, session: current) }
            }
        }
        return true
    }

    /// The shortcut: starts a pick, or ends the one in progress.
    func toggle(_ done: @escaping (NSColor?) -> Void) {
        if isPicking {
            end()
        } else {
            pick(done)
        }
    }

    /// Ends the pick in progress, as Escape would, by ending the service that
    /// draws it: there is no other way to take its windows down.
    func end() {
        guard isPicking else { return }
        Self.endSamplerService()
        answer(nil, session: session)
    }

    private func answer(_ color: NSColor?, session answered: Int) {
        guard answered == session, let done = completion else { return }
        sampler = nil
        completion = nil
        done(color)
    }

    // MARK: The service

    private static let servicePath = "ColorSampler.xpc/Contents/MacOS/ColorSampler"

    /// Whether ColorSampler has a window on screen: the eyedropper is up,
    /// Niram's or not. Owners and sizes need no screen recording permission.
    static func samplerOnScreen() -> Bool {
        guard let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] else {
            return false
        }
        return list.contains { ($0[kCGWindowOwnerName as String] as? String) == "ColorSampler" }
    }

    /// Ends macOS's ColorSampler service, taking its windows with it. macOS
    /// starts it again when it is next asked for. It ignores a polite request
    /// to quit, so it is killed.
    static func endSamplerService() {
        for pid in servicePIDs() { kill(pid, SIGKILL) }
    }

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

    /// Only the user's own service is ever ended.
    private static func ownerUID(of pid: pid_t) -> uid_t? {
        var info = proc_bsdinfo()
        let size = Int32(MemoryLayout<proc_bsdinfo>.size)
        guard proc_pidinfo(pid, PROC_PIDTBSDINFO, 0, &info, size) == size else { return nil }
        return info.pbi_uid
    }
}
