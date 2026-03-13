#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build"
APP_DIR="$BUILD_DIR/KK.app"
VERSION="1.0.0"

cd "$PROJECT_DIR"

echo "Building release binary..."
swift build -c release

echo "Assembling .app bundle..."
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# Copy binary
cp .build/release/KK "$APP_DIR/Contents/MacOS/KK"

# Copy resources into Contents/Resources (app code falls back to Bundle.main)
cp "$PROJECT_DIR/Sources/KK/Resources/kkmoggie.jpg" "$APP_DIR/Contents/Resources/kkmoggie.jpg"

# Generate app icon (vanity mirror with bulbs)
echo "Generating app icon..."
TMPICON=$(mktemp -d)
swift "$SCRIPT_DIR/generate-icon.swift" "$TMPICON"
iconutil -c icns "$TMPICON/AppIcon.iconset" -o "$APP_DIR/Contents/Resources/AppIcon.icns"
rm -rf "$TMPICON"

# Write Info.plist
cat > "$APP_DIR/Contents/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>KK</string>
    <key>CFBundleIdentifier</key>
    <string>com.kevincantwell.kk</string>
    <key>CFBundleName</key>
    <string>KK</string>
    <key>CFBundleDisplayName</key>
    <string>K.K's App</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>CFBundleDocumentTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeName</key>
            <string>Media File</string>
            <key>CFBundleTypeRole</key>
            <string>Viewer</string>
            <key>LSItemContentTypes</key>
            <array>
                <string>public.image</string>
                <string>public.audio</string>
                <string>public.movie</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
PLIST

# Ad-hoc code sign
echo "Code signing..."
codesign --force --deep --sign - "$APP_DIR"

echo "Done: $APP_DIR"
