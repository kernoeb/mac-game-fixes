#!/bin/bash
set -euo pipefail

CATEGORY="${CATEGORY:-public.app-category.action-games}"
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"

if [ $# -lt 1 ]; then
    echo "Usage: $0 <path-to-game.app>"
    echo "Example: $0 '/Applications/Hades.app'"
    echo ""
    echo "Override the category with: CATEGORY=public.app-category.games $0 <app>"
    exit 1
fi

APP_PATH="${1%/}"

if [ ! -d "$APP_PATH" ]; then
    echo "Error: $APP_PATH not found."
    exit 1
fi

# slug for the bundle id, derived from the app name: "Life Is Strange" -> "life-is-strange"
BASE="$(basename "$APP_PATH" .app)"
SLUG="$(echo "$BASE" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/^-//;s/-$//')"

patched=0
suffix=0

# a repack often nests the real app inside the outer bundle; both plists need the keys,
# because the NSApplication belongs to the inner one.
# shallowest path first, so the outer bundle gets the unsuffixed id
while IFS= read -r plist; do
    [ -f "$plist" ] || continue

    [ -e "$plist.orig" ] || cp "$plist" "$plist.orig"

    if ! plutil -extract CFBundleIdentifier raw "$plist" >/dev/null 2>&1; then
        if [ "$suffix" -eq 0 ]; then
            BUNDLE_ID="com.macgamefixes.$SLUG"
        else
            BUNDLE_ID="com.macgamefixes.$SLUG.$suffix"
        fi
        plutil -insert CFBundleIdentifier -string "$BUNDLE_ID" "$plist"
        echo "  added CFBundleIdentifier = $BUNDLE_ID"
        suffix=$((suffix + 1))
    fi

    plutil -replace LSApplicationCategoryType -string "$CATEGORY" "$plist"
    echo "Patched: ${plist#"$APP_PATH"/}"
    patched=$((patched + 1))
done < <(find "$APP_PATH" -name "Info.plist" -path "*/Contents/Info.plist" -not -name "*.orig" \
         | awk '{print gsub("/","/"), $0}' | sort -n | cut -d" " -f2-)

if [ "$patched" -eq 0 ]; then
    echo "Error: no Info.plist found under $APP_PATH."
    exit 1
fi

# LaunchServices caches the old keys, so re-register every bundle we touched
"$LSREGISTER" -f "$APP_PATH" 2>/dev/null || true
while IFS= read -r inner; do
    "$LSREGISTER" -f "$inner" 2>/dev/null || true
done < <(find "$APP_PATH" -type d -name "*.app")

echo ""
echo "Done! $patched plist(s) patched and re-registered."
echo ""
echo "Remember:"
echo "  - Game Mode only activates in FULL SCREEN, never windowed"
echo "  - look for the controller icon in the menu bar to confirm"
echo "  - if 'open' hangs on a black screen, the bundle is unsigned:"
echo "      codesign --force --deep --sign - '$APP_PATH'"
