#!/bin/bash
# Builds Pine and puts a double-clickable copy at build/Pine.app.
#
#     ./make-app.sh            Release build
#     ./make-app.sh debug      Debug build
#
# The version is the number of builds listed in
# Sources/Pine/App/VersionHistory.swift, counted here and written into the
# bundle, so the app and the bundle can never disagree.
set -euo pipefail
cd "$(dirname "$0")"

case "${1:-release}" in
    debug|Debug) CONFIG=debug ;;
    *) CONFIG=release ;;
esac

VERSION=$(grep -c '^        \.init(date:' Sources/Pine/App/VersionHistory.swift)

LOG=build/swift-build.log
mkdir -p build
if ! swift build -c "$CONFIG" > "$LOG" 2>&1; then
    grep -E "error:" "$LOG" | sort -u || true
    echo "build failed, full log in $LOG"
    exit 1
fi

# Warnings are treated as failures of the milestone, so they are always shown.
grep -E "warning:" "$LOG" | sort -u || true

APP=build/Pine.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp ".build/$CONFIG/Pine" "$APP/Contents/MacOS/Pine"
cp Resources/Info.plist "$APP/Contents/Info.plist"
cp -R Resources/Fonts Resources/Textures Resources/AppIcon.icns Resources/menu-icon.svg "$APP/Contents/Resources/"
plutil -replace CFBundleShortVersionString -string "$VERSION" "$APP/Contents/Info.plist"
plutil -replace CFBundleVersion -string "$VERSION" "$APP/Contents/Info.plist"

# Ad-hoc signed with the Hardened Runtime, as Twine is.
codesign --force --sign - --options runtime "$APP" 2>/dev/null
echo "built $APP (build $VERSION, $CONFIG)"
