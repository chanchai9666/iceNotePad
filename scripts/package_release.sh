#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$DIR"

echo "==> 1. Building App Bundle..."
./scripts/build_app.sh

echo "==> 2. Creating ZIP package..."
cd build
rm -f iceNotePad.zip
zip -r -y iceNotePad.zip iceNotePad.app

echo "==> 3. Creating DMG package..."
cd "$DIR"
rm -f build/iceNotePad.dmg
hdiutil create -volname "iceNotePad" -srcfolder build/iceNotePad.app -ov -format UDZO build/iceNotePad.dmg

echo "==> Done! Release packages created at:"
echo "    - build/iceNotePad.dmg"
echo "    - build/iceNotePad.zip"

