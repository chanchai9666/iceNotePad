#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$DIR"

# shellcheck source=scripts/version.sh
source "$DIR/scripts/version.sh"
APP_VERSION="$(resolve_app_version)" || exit 1

DMG_PATH="build/iceNotePad-$APP_VERSION.dmg"
ZIP_PATH="build/iceNotePad-$APP_VERSION.zip"

echo "==> 1. Building App Bundle ($APP_VERSION)..."
./scripts/build_app.sh

echo "==> 2. Creating ZIP package..."
rm -f "$ZIP_PATH"
( cd build && zip -r -y "iceNotePad-$APP_VERSION.zip" iceNotePad.app )

echo "==> 3. Creating DMG package..."
rm -f "$DMG_PATH"
hdiutil create -volname "iceNotePad" -srcfolder build/iceNotePad.app -ov -format UDZO "$DMG_PATH"

echo "==> Done! Release packages created at:"
echo "    - $DMG_PATH"
echo "    - $ZIP_PATH"
