#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ $# -lt 1 ]; then
    echo "Usage: $0 <path-to-game.app>"
    echo "Example: $0 '/Applications/Life Is Strange.app'"
    exit 1
fi

APP_PATH="$1"
TARGET_DIR="$APP_PATH/Contents/Resources/InputDevices/Customer"

if [ ! -d "$APP_PATH/Contents/Resources/InputDevices" ]; then
    echo "Error: $APP_PATH doesn't look like a Feral Interactive game."
    echo "       No InputDevices/ folder found."
    exit 1
fi

mkdir -p "$TARGET_DIR"

installed=0
for plist in "$SCRIPT_DIR"/plists/*.plist; do
    [ -f "$plist" ] || continue
    cp "$plist" "$TARGET_DIR/${plist##*/}"
    echo "Installed: ${plist##*/}"
    installed=$((installed + 1))
done

if [ "$installed" -eq 0 ]; then
    echo "Error: No .plist files found in $SCRIPT_DIR/plists/"
    exit 1
fi

echo ""
echo "Done! $installed plist(s) installed to:"
echo "  $TARGET_DIR"
echo ""
echo "Remember:"
echo "  - Connect your Xbox controller via Bluetooth (not USB)"
echo "  - If using Steam, disable 'Xbox Configuration Support' in Steam controller settings"
