# Niram: notes for working on it

Niram is a menu bar colour picker (no Dock icon, `LSUIElement`): a global shortcut (⇧⌘C by default, a Carbon hotkey, so no Accessibility permission) picks a colour from the screen with `NSColorSampler` and copies its hex code; the menu bar keeps the last five; a Compare window shows two colours with their WCAG contrast; a Settings window holds the shortcut, hex format and launch at login. Launching it again while it runs opens Compare. Bundle id `com.nidhin.niram`; the GitHub repo is `inbox-nidhinm/Niram` (private).

It is being redesigned the way Flip and Twine were made: `docs/redesign-decisions.md` holds the user's answers. The steps, each ending with screenshots for the user to check before the next: 1 foundations (done), 2 the menu bar dropdown as a custom floating panel, 3 the Compare window, 4 Settings as cards, as Twine's Settings page, 5 an app icon (needs the user's artwork).

## Rules

These follow Twine's (`../Twine/CLAUDE.md`), which has the reasons.

- **No em dashes anywhere**: UI strings, comments, docs, commit messages.
- No third-party dependencies without asking.
- Every milestone ends with: `./make-app.sh` with no warnings, `./test.sh` passing, the change written into the top build of `Sources/Niram/App/VersionHistory.swift`, a commit, and a push to `inbox-nidhinm/Niram`.
- **Builds are releases, not changes**: write each change as a line in the top build's `features`, `fixes` or `misc`; start a new build only when the user says to cut one. Raise `VersionHistory.pushes` by one in every commit you push.
- The user is a designer, not an engineer. Explain in plain terms.
- No help text in the UI. States are shown, not explained. Put explanations in `.help()` tooltips.
- Views never write literals: every colour, size and radius comes from `Theme` (`Sources/Niram/Theme/Theme.swift`), the Flip Design System's values as Twine has them, with magenta (#E2387F) as the accent.
- **Never drive the copy of the app the user is using** (`/Applications/Niram.app`, usually running). For checks, copy `build/Niram.app` to the scratchpad, give the copy the bundle id `com.nidhin.niram.selftest` (`plutil -replace CFBundleIdentifier`, then `codesign --force --sign - --options runtime`), and run its binary directly. Its shortcut will not register while the user's copy holds it. To open a window without clicking, add a temporary environment-variable hook in `AppDelegate.applicationDidFinishLaunching` and remove it before committing; capture windows with `screencapture -o -l<window id>`, the id from `CGWindowListCopyWindowInfo` for the copy's pid (take the largest window: a menu bar app has a small one too).

## Building

SwiftPM, no Xcode project. `./make-app.sh` builds release (or `debug`), assembles `build/Niram.app` from the binary and `Resources/` (Info.plist, PP Kyoto in `Fonts`, the grain in `Textures`), writes the version (the count of builds in `VersionHistory`) and signs it ad hoc with the Hardened Runtime. Resources are copied in by the script rather than declared in `Package.swift`, because SwiftPM's resource bundle sits at the app's root, where signing refuses it; code finds them with `Bundle.main` (under `swift run` the fonts fall back to the system face and there is no grain). `./test.sh` runs the unit tests in `Tests/NiramTests` (Swift Testing, `@testable import Niram`). macOS 14 or later.

## Where things are

| Where | What |
|---|---|
| `Sources/Niram/App` | `main.swift`, `AppDelegate` (status item, menu, windows, picking), `AppSettings` (defaults, shortcut names), `GlobalHotKey`, `ColorUtils` (hex, WCAG luminance and contrast), `VersionHistory` |
| `Sources/Niram/Theme` | `Theme` and `ThemeFont` (tokens and type), `Grain` (`.grained()`), `IconShape`/`IconView`, `Icons.swift` (generated) |
| `Sources/Niram/Components` | `Floating.swift`: `floatingPanel()`, `windowGround()`, `PopupCard`, `TrafficLights`, `ChromelessWindow` and `makeChromelessWindow(_:)`, the dark window every Niram window uses |
| `Sources/Niram/Compare`, `Settings` | The two windows' views |

## Icons

SVGs in `Icons/`, 24x24, stroked, `M L H V C Z` only, drawn at `Theme.iconStroke`. All but `copy.svg` are the designer's, copied from Twine's set; `copy.svg` is a placeholder of ours. Regenerate after editing:

```bash
python3 Tools/svg_to_swift.py --icons Icons --out Sources/Niram/Theme/Icons.swift
```
