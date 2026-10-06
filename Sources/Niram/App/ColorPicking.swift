import AppKit

/// Every pick from the screen goes through here: the shortcut, the panel's
/// Pick Colour and the Compare card's colours.
///
/// The eyedropper is macOS's (`SamplerService`). Twice on 6 October 2026 the
/// user was left with screens that took no click at all, the menu bar and
/// Dock included, with no way out but forcing the Mac off: the service's
/// windows stayed up after a pick, and while they did, neither Niram's
/// shortcut nor anything else reached Niram. So nothing here relies on the
/// user being able to reach Niram:
///
/// - one pick at a time, the sampler held until it answers;
/// - a new pick waits until the last eyedropper has gone from the screen.
///   Ending the service and asking again at once (which the first fix did on
///   finding windows still fading) left a pick that never appeared and never
///   answered; now one still up after a second is ended, and the new pick waits
///   for the service to be gone before asking;
/// - `SamplerWatchdog` watches the screen from its own thread and ends the
///   service when its windows are up with no magnifier, when they outstay
///   Niram's pick, or when a pick runs past two minutes, and lets go of a pick
///   that has silently died;
/// - the shortcut pressed while picking ends the pick, and quitting ends one;
/// - every step that matters is written to `EyedropperLog`.
@MainActor
final class ColorPicking {
    static let shared = ColorPicking()

    /// What the watchdog reads from its own thread.
    nonisolated let state = PickState()

    /// The sampler running now, held until it answers.
    private var sampler: NSColorSampler?
    private var completion: ((NSColor?) -> Void)?
    /// Each pick's number, so a late answer from an ended one is ignored.
    private var session = 0
    /// Waiting for the screen to clear before asking.
    private var waiting = false

    var isPicking: Bool { sampler != nil || waiting }

    /// How long a new pick waits for the last eyedropper to go before ending
    /// it, how long it then waits for the service to be gone, and the pause
    /// before asking again.
    private static let fadeWait: TimeInterval = 1
    private static let restartWait: TimeInterval = 3
    private static let restartPause: TimeInterval = 0.4
    private static let poll: TimeInterval = 0.05

    /// Starts a pick unless one is under way. Returns whether it was taken.
    @discardableResult
    func pick(_ done: @escaping (NSColor?) -> Void) -> Bool {
        guard !isPicking else { return false }
        session += 1
        waiting = true
        completion = done
        state.set(waiting: true)
        prepare(session: session, since: Date(), ended: false)
        return true
    }

    /// The shortcut: starts a pick, or ends the one under way.
    func toggle(_ done: @escaping (NSColor?) -> Void) {
        if isPicking { end(because: "the pick shortcut was pressed again") } else { pick(done) }
    }

    /// Ends the pick under way, taking the eyedropper off the screen.
    func end(because reason: String = "Niram is quitting") {
        guard isPicking else { return }
        SamplerService.end(because: reason)
        answer(nil, session: session)
    }

    /// From the watchdog, which has ended the service or found the pick dead.
    func watchdogLetGo() {
        guard isPicking else { return }
        answer(nil, session: session)
    }

    /// Waits for the screen to be clear of any eyedropper, ending one that
    /// will not go, then asks.
    private func prepare(session current: Int, since: Date, ended: Bool) {
        guard current == session, waiting else { return }
        let shot = SamplerService.snapshot()
        let waited = Date().timeIntervalSince(since)
        if shot.isClear && (!ended || !SamplerService.isRunning) {
            if ended {
                after(Self.restartPause) { self.start(session: current) }
            } else {
                start(session: current)
            }
            return
        }
        if !ended && waited >= Self.fadeWait {
            SamplerService.end(because: "an eyedropper was still on screen a second after a new pick was asked")
            after(Self.poll) { self.prepare(session: current, since: Date(), ended: true) }
            return
        }
        if ended && waited >= Self.restartWait {
            EyedropperLog.write("gave up on a pick: the screen did not clear (\(shot.description))")
            answer(nil, session: current)
            return
        }
        after(Self.poll) { self.prepare(session: current, since: since, ended: ended) }
    }

    private func start(session current: Int) {
        guard current == session, waiting else { return }
        waiting = false
        let sampler = NSColorSampler()
        self.sampler = sampler
        state.set(picking: true)
        sampler.show { [weak self] color in
            // Copied before leaving this thread: a colour is not Sendable.
            let picked = color?.copy() as? NSColor
            DispatchQueue.main.async {
                MainActor.assumeIsolated { self?.answer(picked, session: current) }
            }
        }
    }

    private func answer(_ color: NSColor?, session answered: Int) {
        guard answered == session, let done = completion else { return }
        sampler = nil
        waiting = false
        completion = nil
        state.set(picking: false)
        done(color)
    }

    private func after(_ seconds: TimeInterval, _ work: @escaping @MainActor () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) { MainActor.assumeIsolated(work) }
    }
}

/// Whether Niram is picking, and since when, for the watchdog's thread.
final class PickState: @unchecked Sendable {
    struct Value {
        /// The sampler has been asked and has not answered.
        var picking = false
        /// Waiting for the screen to clear before asking.
        var waiting = false
        var startedAt: Date?
        var endedAt: Date?
    }

    private let lock = NSLock()
    private var value = Value()

    var current: Value { lock.withLock { value } }

    func set(picking: Bool) {
        lock.withLock {
            if picking { value.startedAt = Date() } else if value.picking || value.waiting { value.endedAt = Date() }
            value.picking = picking
            value.waiting = false
        }
    }

    func set(waiting: Bool) {
        lock.withLock { value.waiting = waiting }
    }
}

/// Watches the eyedropper from its own thread, twice a second, and ends it
/// when it is stuck, whatever state Niram's main thread is in. See
/// `ColorPicking` for why.
enum SamplerWatchdog {
    /// How often it looks, and how long each sign must last before it acts.
    static let interval: TimeInterval = 0.5
    /// Screen covers with no magnifier: the stuck state the user saw (a plain
    /// pointer, hover working, no click landing).
    static let noMagnifierLimit: TimeInterval = 1.5
    /// Covers still up after Niram's pick ended, within `afterPickWindow` of it
    /// (beyond that they are taken to be another app's eyedropper).
    static let outstayLimit: TimeInterval = 2
    static let afterPickWindow: TimeInterval = 60
    /// A pick longer than this is ended.
    static let longestPick: TimeInterval = 120
    /// A pick with nothing on screen for this long has died.
    static let deadLimit: TimeInterval = 1.5

    private static let queue = DispatchQueue(label: "niram.sampler-watchdog", qos: .userInitiated)
    nonisolated(unsafe) private static var timer: DispatchSourceTimer?

    @MainActor static func start(watching state: PickState) {
        guard timer == nil else { return }
        let source = DispatchSource.makeTimerSource(queue: queue)
        var noMagnifier: TimeInterval = 0
        var outstayed: TimeInterval = 0
        var dead: TimeInterval = 0
        source.schedule(deadline: .now() + interval, repeating: interval)
        source.setEventHandler {
            let shot = SamplerService.snapshot()
            let pick = state.current
            let now = Date()

            noMagnifier = !shot.covers.isEmpty && shot.magnifiers == 0 ? noMagnifier + interval : 0
            let recentlyPicked = pick.endedAt.map { now.timeIntervalSince($0) < afterPickWindow } ?? false
            outstayed = !shot.covers.isEmpty && !pick.picking && !pick.waiting && recentlyPicked ? outstayed + interval : 0
            let pickAge = pick.startedAt.map { now.timeIntervalSince($0) } ?? 0
            dead = pick.picking && shot.isClear && pickAge > deadLimit ? dead + interval : 0

            var ended = false
            if noMagnifier >= noMagnifierLimit {
                SamplerService.end(because: "watchdog: the screen was covered with no magnifier for \(noMagnifierLimit) s")
                ended = true
            } else if outstayed >= outstayLimit {
                SamplerService.end(because: "watchdog: the eyedropper stayed on screen \(outstayLimit) s after Niram's pick ended")
                ended = true
            } else if pick.picking && pickAge >= longestPick {
                SamplerService.end(because: "watchdog: a pick ran past \(Int(longestPick)) s")
                ended = true
            } else if dead >= deadLimit {
                EyedropperLog.write("watchdog: a pick showed nothing on screen for \(deadLimit) s, so Niram let go of it")
                ended = true
            }
            if ended {
                noMagnifier = 0
                outstayed = 0
                dead = 0
                DispatchQueue.main.async { MainActor.assumeIsolated { ColorPicking.shared.watchdogLetGo() } }
            }
        }
        source.resume()
        timer = source
    }
}
