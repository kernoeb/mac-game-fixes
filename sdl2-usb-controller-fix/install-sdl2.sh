#!/bin/bash
set -euo pipefail

SDL_VERSION="${SDL_VERSION:-2.32.10}"
DMG_URL="https://github.com/libsdl-org/SDL/releases/download/release-${SDL_VERSION}/SDL2-${SDL_VERSION}.dmg"

if [ $# -lt 1 ]; then
    echo "Usage: $0 <path-to-game.app>"
    echo "Example: $0 '/Applications/Hades.app'"
    echo ""
    echo "Override the SDL version with: SDL_VERSION=2.30.0 $0 <app>"
    exit 1
fi

APP_PATH="${1%/}"

if [ ! -d "$APP_PATH" ]; then
    echo "Error: $APP_PATH not found."
    exit 1
fi

# a game may nest a second .app inside the outer bundle, so search the whole tree
FRAMEWORK="$(find "$APP_PATH" -type d -name "SDL2.framework" -not -name "*.orig" | head -1)"

if [ -z "$FRAMEWORK" ]; then
    echo "Error: no SDL2.framework found in $APP_PATH."
    echo "       The game may link SDL statically, or not use SDL at all."
    exit 1
fi

echo "Found: $FRAMEWORK"

# grep -c, not grep -q: under pipefail, -q exits early and kills strings with SIGPIPE,
# so a match would read as a failure
MFI_COUNT="$(strings "$FRAMEWORK/Versions/A/SDL2" 2>/dev/null | grep -c "SDL_JOYSTICK_MFI" || true)"

if [ "${MFI_COUNT:-0}" -gt 0 ]; then
    echo ""
    echo "This SDL2 already has the GameController (MFI) backend."
    echo "Your problem is elsewhere — nothing to do here."
    exit 0
fi

echo "No GameController backend present. Patching."

WORK="$(mktemp -d)"
MOUNT="$WORK/mnt"
trap 'hdiutil detach "$MOUNT" -quiet 2>/dev/null || true; rm -rf "$WORK"' EXIT

echo "Downloading SDL2 $SDL_VERSION..."
curl -fsSL -o "$WORK/SDL2.dmg" "$DMG_URL"

mkdir -p "$MOUNT"
hdiutil attach -nobrowse -quiet "$WORK/SDL2.dmg" -mountpoint "$MOUNT"

if [ ! -d "$MOUNT/SDL2.framework" ]; then
    echo "Error: the downloaded image has no SDL2.framework."
    exit 1
fi

if [ ! -e "$FRAMEWORK.orig" ]; then
    cp -R "$FRAMEWORK" "$FRAMEWORK.orig"
    echo "Backed up: $(basename "$FRAMEWORK").orig"
else
    echo "Backup already exists, leaving it alone."
fi

rm -rf "$FRAMEWORK"
cp -R "$MOUNT/SDL2.framework" "$FRAMEWORK"

# Apple's xattr, not Homebrew's Python one, which has no -r
/usr/bin/xattr -cr "$FRAMEWORK"
codesign --force --sign - "$FRAMEWORK" >/dev/null 2>&1

echo ""
echo "Done. SDL2 $SDL_VERSION installed."
echo ""
echo "Check it took:"
echo "  strings '$FRAMEWORK/Versions/A/SDL2' | grep -o SDL_JOYSTICK_MFI | head -1"
echo ""
echo "To revert:"
echo "  rm -rf '$FRAMEWORK' && mv '$FRAMEWORK.orig' '$FRAMEWORK'"
