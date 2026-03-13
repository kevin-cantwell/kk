#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build"
APP_DIR="$BUILD_DIR/KK.app"
VERSION="1.0.1"
DMG_NAME="KK-${VERSION}.dmg"
DMG_PATH="$BUILD_DIR/$DMG_NAME"

if [ ! -d "$APP_DIR" ]; then
    echo "Error: KK.app not found. Run build-app.sh first."
    exit 1
fi

echo "Creating DMG..."
rm -f "$DMG_PATH"

# Stage DMG contents with Applications symlink for drag-to-install
STAGING=$(mktemp -d)
cp -R "$APP_DIR" "$STAGING/"
ln -s /Applications "$STAGING/Applications"

hdiutil create -volname "KK" \
    -srcfolder "$STAGING" \
    -ov -format UDZO \
    "$DMG_PATH"

rm -rf "$STAGING"

# Notarize the DMG
echo "Submitting for notarization..."
xcrun notarytool submit "$DMG_PATH" --keychain-profile "notary" --wait

echo "Stapling notarization ticket..."
xcrun stapler staple "$DMG_PATH"

echo "Done: $DMG_PATH"
