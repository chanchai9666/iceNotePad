#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$DIR"

echo "==> Building iceNotePad (Release mode for Apple Silicon arm64)..."
swift build -c release

BIN_PATH="$(swift build -c release --show-bin-path)/iceNotePad"
APP_DIR="build/iceNotePad.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "==> Preparing App Bundle Structure..."
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

echo "==> Copying executable..."
cp "$BIN_PATH" "$MACOS_DIR/iceNotePad"
chmod +x "$MACOS_DIR/iceNotePad"

echo "==> Generating App Icon..."
mkdir -p build
swift scripts/generate_icon.swift
iconutil -c icns build/iceNotePad.iconset -o "$RESOURCES_DIR/AppIcon.icns"
rm -rf build/iceNotePad.iconset

echo "==> Creating Info.plist..."
cat << 'EOF' > "$CONTENTS_DIR/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>iceNotePad</string>
    <key>CFBundleIdentifier</key>
    <string>com.chanchai.iceNotePad</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>iceNotePad</string>
    <key>CFBundleDisplayName</key>
    <string>iceNotePad</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2026 chanchai (cjiceko@gmail.com). All rights reserved.</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>CFBundleDocumentTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeName</key>
            <string>Plain Text</string>
            <key>CFBundleTypeRole</key>
            <string>Editor</string>
            <key>LSHandlerRank</key>
            <string>Alternate</string>
            <key>LSItemContentTypes</key>
            <array>
                <string>public.plain-text</string>
                <string>public.utf8-plain-text</string>
                <string>public.text</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
EOF

echo "==> Signing App Bundle..."
codesign --force --deep --sign - "$APP_DIR"

echo "==> Done! Application is ready at: $APP_DIR"

