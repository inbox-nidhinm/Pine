#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

swift build -c release

APP="Niram.app"
mkdir -p "$APP/Contents/MacOS"
cp .build/release/Niram "$APP/Contents/MacOS/Niram"

echo "Built $APP"
echo "Move it to /Applications, then double-click to launch:"
echo "  cp -R $APP /Applications/"
echo "  open /Applications/Niram.app"
