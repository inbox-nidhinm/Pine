# Niram: notes for working on it

Niram is a menu bar colour picker (no Dock icon, `LSUIElement`): a global shortcut (⇧⌘C by default, a Carbon hotkey, so no Accessibility permission) picks a colour from the screen with `NSColorSampler` and copies its hex code; the menu bar keeps the last five; a Compare window shows two colours with their WCAG contrast; a Settings window holds the shortcut, hex format and launch at login. Launching it again while it runs opens Compare. Bundle id `com.nidhin.niram`; the GitHub repo is `inbox-nidhinm/Niram` (private).

It is being redesigned the way Flip and Twine were made: `docs/redesign-decisions.md` holds the user's answers. The steps, each ending with screenshots for the user to check before the next: 1 foundations (done), 2 the menu bar dropdown as a custom floating panel (done), 3 the Compare window (done), 4 Settings as cards, as Twine's Settings page (done), 5 an app icon (needs the user's artwork).

## Rules

These follow Twine's (`../Twine/CLAUDE.md`), which has the reasons.

- **No em dashes anywhere**: UI strings, comments, docs, commit messages.
- No third-party dependencies without asking.
- Every milestone ends with: `./make-app.sh` with no warnings, `./test.sh` passing, the change written into the top build of `Sources/Niram/App/VersionHistory.swift`, a commit, and a push to `inbox-nidhinm/Niram`.
- **Builds are releases, not changes**: write each change as a line in the top build's `features`, `fixes` or `misc`; start a new build only when the user says to cut one. Raise `VersionHistory.pushes` by one in every commit you push.
- The user is a designer, not an engineer. Explain in plain terms.
- No help text in the UI. States are shown, not explained. Put explanations in `.help()` tooltips.
- Views never write literals: every colour, size and radius comes from `Theme` (`Sources/Niram/Theme/Theme.swift`), the Flip Design System's values as Twine has them, with magenta (#E2387F) as the accent.
- **Never drive the copy of the app the user is using** (`/Applications/Niram.app`, usually running). For checks, copy `build/Niram.app` to the scratchpad, give the copy the bundle id `com.nidhin.niram.selftest` (`plutil -replace CFBundleIdentifier`, then `codesign --force --sign - --options runtime`), and run its binary directly. Its shortcut will not register while the user's copy holds it. To open a window without clicking, add a temporary environment-variable hook in `AppDelegate.applicationDidFinishLaunching` and remove it before committing; capture windows with `screencapture -o -l<window id>`, the id from `CGWindowListCopyWindowInfo` for the copy's pid, of any layer (the menu bar panel is at the pop-up menu level, 101; a menu bar app also has a small window of its own). Clicks: post `NSEvent` mouse events through the window's `sendEvent` from the hook, then an `.applicationDefined` event through `NSApp.postEvent`, and log with `NSLog` (a `print` is lost when the copy is killed). A posted click into a SwiftUI text field does focus it (the field editor becomes first responder), and posted key events type into it. Never click a recent colour in a test: it copies to the user's real clipboard. Give the test copy sample colours with `defaults write com.nidhin.niram.selftest recentColors -array ...` and delete that domain afterwards. The user's menu bar is full: a second Niram icon goes behind the notch, and its panel then opens mid-screen.

## Building

SwiftPM, no Xcode project. `./make-app.sh` builds release (or `debug`), assembles `build/Niram.app` from the binary and `Resources/` (Info.plist, PP Kyoto in `Fonts`, the grain in `Textures`), writes the version (the count of builds in `VersionHistory`) and signs it ad hoc with the Hardened Runtime. Resources are copied in by the script rather than declared in `Package.swift`, because SwiftPM's resource bundle sits at the app's root, where signing refuses it; code finds them with `Bundle.main` (under `swift run` the fonts fall back to the system face and there is no grain). `./test.sh` runs the unit tests in `Tests/NiramTests` (Swift Testing, `@testable import Niram`). macOS 14 or later.

## Where things are

| Where | What |
|---|---|
| `Sources/Niram/App` | `main.swift`, `AppDelegate` (status item, panel, windows), `ColorPicking` (every pick goes through it: see Picking below), `AppSettings` (defaults, shortcut names), `GlobalHotKey`, `ColorUtils` (hex, WCAG luminance and contrast), `VersionHistory` |
| `Sources/Niram/Theme` | `Theme` and `ThemeFont` (tokens and type), `Grain` (`.grained()`), `IconShape`/`IconView`, `Icons.swift` (generated) |
| `Sources/Niram/Components` | `Floating.swift`: `floatingPanel()`, `windowGround()`, `PopupCard`, `TrafficLights`, `ChromelessWindow` and `makeChromelessWindow(_:)`, the dark window every Niram window uses |
| `Sources/Niram/MenuBar` | `StatusPanel` (the borderless, non-activating panel under the status item: placed under the icon's button, kept on screen, the window's own shadow following the card, closed by Escape, a click in another app (a global monitor) or losing the keyboard; ⌘, and ⌘Q through a local key monitor, so posted keys cannot test them), `MenuBarPanel` (Pick Colour as `PrimaryButton`, recent colours, command rows as Twine's menu rows), `RecentColors` (the last five, newest first, in defaults as `recentColors`) |
| `Sources/Niram/Compare` | `CompareView`: Twine's editor layout, the preview (the background colour, the text colour's samples) under the whole window and `CompareColorsPanel` floating on the left, its top row holding the traffic lights and the swap button. `CompareModel` is `text` and `background`. The view runs under the hidden title bar (`.ignoresSafeArea()`), so the window is made at `Theme.compareWindow` through `makeChromelessWindow(_:size:)`: sized to fit, it counted the title bar on top. Levels and ratio maths are `ContrastLevel` and `shownRatio` in `ColorUtils` (cut, never rounded up), typed hex `NSColor(typedHex:)` |
| `Sources/Niram/Settings` | `SettingsView`: Twine's Settings page in a fixed window, sized to fit (it does not run under the title bar; `settingsTitleBlock` leaves room for the traffic lights). Cards of rows (`card`, `row`, `dashes`, as Twine's) in two columns: Picking and General on the left, Hex Codes on the right; `ShortcutField` records the shortcut through a local key monitor (posted keys skip it, so recording is untested). `VersionHistoryCard` shows over the page from the foot's button. `PillToggle` and `PanelButton` are in `Components/Buttons.swift` |

## Picking

The eyedropper is macOS's, not Niram's: `NSColorSampler` asks the ColorSampler service (`/System/Library/Frameworks/AppKit.framework/Versions/C/XPCServices/ColorSampler.xpc`), its own process, to put a window over every screen connected at that moment, at level 2147483631, plus a 153-point magnifier that follows the pointer. It cannot be cancelled through the API, it outlives its client, and it ignores a polite quit (`SIGKILL` ends it; macOS starts it again when next asked). Twice on 6 October 2026 the user's screens took no clicks at all, the Dock and menu bar included, with no way out but forcing the Mac off; the second time the shortcut did not help either, so nothing may rely on the user reaching Niram.

- `ColorPicking` (main actor): one pick at a time, the sampler held until it answers. A new pick waits (`prepare`) for the screen to be clear of any eyedropper; one still up after `fadeWait` (1 s) is ended, then it waits for the service to be gone and `restartPause` before asking. Asking at once after ending the service (the first fix did) gave a pick that never appeared and never answered, and a killed service can show a pick seconds late. `toggle` (the shortcut) ends a pick under way; quitting ends one.
- `SamplerWatchdog` (its own queue, every 0.5 s, started first thing at launch) reads `PickState` (a lock, not the main actor) and `SamplerService.snapshot()` and ends the service when the screen is covered with no magnifier for 1.5 s (the stuck state: plain pointer, hover working, no click landing), when covers outstay Niram's pick by 2 s (within 60 s of it; later ones are taken to be another app's), or when a pick passes 2 minutes; and lets go of a pick with nothing on screen for 1.5 s. It does not need the main thread: with the main thread frozen for 5 s it ended a stuck eyedropper at 2.5 s.
- `SamplerService`: the snapshot (covers and magnifiers by window owner and size, no screen recording permission needed) and `end(because:)`. `EyedropperLog` writes every ending and let-go to `~/Library/Logs/Niram/eyedropper.log`: read it first when the user reports a stuck screen.
- A covered screen with no magnifier has not been reproduced on purpose; the rule for it is from the user's description. A completed pick needs a real click.

**Testing a pick takes over the user's real pointer and screen**, and the user may be clicking (a test pick was once completed by their click): warn them first, keep every run under a hard limit (`perl -e 'alarm 15; exec @ARGV' ...`), leave three seconds between runs (a pick asked just after the service was ended never shows), and check the screen afterwards with a window list, ending the service by hand if anything is left. Run the test copy outside the command sandbox, which blocks the signal.

## Icons

SVGs in `Icons/`, 24x24, stroked, `M L H V C Z` only, drawn at `Theme.iconStroke`. All but `copy.svg` are the designer's, copied from Twine's set; `copy.svg` is a placeholder of ours. Regenerate after editing:

```bash
python3 Tools/svg_to_swift.py --icons Icons --out Sources/Niram/Theme/Icons.swift
```
