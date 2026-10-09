#!/bin/bash
# Puts build/Pine.app in /Applications and starts it, quitting the Pine that
# is running first (the user's request, 6 October 2026: every update is
# installed and launched at once). Run it after ./make-app.sh at the end of
# every change.
#
# Pine is asked to quit, so a pick in progress is ended cleanly, and forced
# only if it is still running after five seconds. The old app is removed
# whole before the copy: copying over it left an old file inside, which broke
# its signature.
set -euo pipefail
cd "$(dirname "$0")"

APP=/Applications/Pine.app
[[ -d build/Pine.app ]] || { echo "no build/Pine.app: run ./make-app.sh first"; exit 1; }

running() { pgrep -f "$APP/Contents/MacOS/Pine" > /dev/null; }

if running; then
    osascript -e 'quit app id "com.nidhin.pine"' > /dev/null 2>&1 || true
    for _ in $(seq 50); do running || break; sleep 0.1; done
    if running; then pkill -9 -f "$APP/Contents/MacOS/Pine" || true; sleep 0.5; fi
fi

rm -rf "$APP"
cp -R build/Pine.app "$APP"
codesign --verify --deep --strict "$APP"
open "$APP"

for _ in $(seq 50); do running && break; sleep 0.1; done
if running; then
    echo "installed and started $APP (build $(plutil -extract CFBundleShortVersionString raw "$APP/Contents/Info.plist"))"
else
    echo "installed $APP, but it did not start"
    exit 1
fi
