#!/bin/bash
# Copies the font Pine ships, AA Bridge Slab, from the AA-Bridge project into
# Resources/Fonts.
#
# AA-Bridge is the user's own font project, kept in Vendor/AA-Bridge as a git
# submodule (a link to another repository, pinned at one of its commits). It
# is private, so the files Pine needs are also kept in Resources/Fonts: anyone
# can build Pine from those without the submodule.
#
# To take a newer AA Bridge Slab:
#     git -C Vendor/AA-Bridge pull origin main
#     Tools/update-fonts.sh
#     git add Vendor/AA-Bridge Resources/Fonts
#
# make-app.sh runs this before every build when the submodule is there, and
# builds from the kept copy when it is not.
set -euo pipefail
cd "$(dirname "$0")/.."

SLAB=Vendor/AA-Bridge/slab
VARIABLE="$SLAB/fonts/variable/AABridgeSlab[opsz,wght].ttf"

if [[ ! -f "$VARIABLE" ]]; then
    echo "Vendor/AA-Bridge is not checked out: run 'git submodule update --init' first"
    exit 1
fi

mkdir -p Resources/Fonts
# Copied only when different, so the files keep their dates when nothing changed.
cmp -s "$VARIABLE" Resources/Fonts/AABridgeSlab.ttf || cp "$VARIABLE" Resources/Fonts/AABridgeSlab.ttf
cmp -s "$SLAB/OFL.txt" Resources/Fonts/OFL.txt || cp "$SLAB/OFL.txt" Resources/Fonts/OFL.txt
