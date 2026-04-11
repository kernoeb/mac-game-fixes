#!/bin/bash
set -euo pipefail

VALID_CODES="INT FRA DEU ESN ESM ITA PTB RUS"

if [ $# -lt 2 ]; then
    echo "Usage: $0 <path-to-game.app> <language-code>"
    echo "Example: $0 '/Applications/Life Is Strange.app' FRA"
    echo ""
    echo "Language codes: $VALID_CODES"
    exit 1
fi

APP_PATH="$1"
LANG_CODE="$2"

# Validate language code
if ! echo "$VALID_CODES" | grep -qw "$LANG_CODE"; then
    echo "Error: Unknown language code '$LANG_CODE'"
    echo "Valid codes: $VALID_CODES"
    exit 1
fi

# Map UE3 language codes to lproj folder names
lproj_for_code() {
    case "$1" in
        INT) echo "en" ;; FRA) echo "fr" ;; DEU) echo "de" ;;
        ESN) echo "es" ;; ESM) echo "es_419" ;; ITA) echo "it" ;;
        PTB) echo "pt_BR" ;; RUS) echo "ru" ;;
    esac
}

# Find the defaultengine.ini
ENGINE_INI=$(find "$APP_PATH/Contents/Resources/Data" -name "defaultengine.ini" -path "*/config/*" 2>/dev/null | head -1)

if [ -z "$ENGINE_INI" ]; then
    echo "Error: Could not find defaultengine.ini"
    echo "Is this a Feral Interactive Unreal Engine port?"
    exit 1
fi

get_language() { grep "^Language=" "$1" 2>/dev/null | head -1 | cut -d= -f2; }

CURRENT=$(get_language "$ENGINE_INI")
echo "Current language: $CURRENT"
echo "Target language:  $LANG_CODE"

if [ "$CURRENT" = "$LANG_CODE" ]; then
    echo "Already set to $LANG_CODE, nothing to change."
else
    sed -i '' "s/^Language=.*/Language=$LANG_CODE/" "$ENGINE_INI"
    echo "Patched: $ENGINE_INI"
fi

# Check for user-level engine config override
SUPPORT_DIR="$HOME/Library/Application Support/Feral Interactive"
GAME_NAME=$(basename "$APP_PATH" .app)
USER_INI=$(find "$SUPPORT_DIR/$GAME_NAME" -name "*Engine.ini" 2>/dev/null | head -1)

if [ -n "$USER_INI" ]; then
    USER_CURRENT=$(get_language "$USER_INI")
    if [ -n "$USER_CURRENT" ] && [ "$USER_CURRENT" != "$LANG_CODE" ]; then
        sed -i '' "s/^Language=.*/Language=$LANG_CODE/" "$USER_INI"
        echo "Patched user config: $USER_INI"
    fi
fi

# Fix Feral launcher strings if en.lproj contains Russian
EN_STRINGS="$APP_PATH/Contents/Resources/en.lproj/Localizable.strings"
if [ -f "$EN_STRINGS" ]; then
    LPROJ_NAME=$(lproj_for_code "$LANG_CODE")
    TARGET_STRINGS="$APP_PATH/Contents/Resources/${LPROJ_NAME}.lproj/Localizable.strings"

    if iconv -f UTF-16 -t UTF-8 "$EN_STRINGS" 2>/dev/null | perl -ne 'exit 0 if /\p{Cyrillic}/; END { exit 1 }' 2>/dev/null; then
        echo ""
        echo "Warning: en.lproj contains Russian text (repackaged build)."

        if [ -n "$LPROJ_NAME" ] && [ -f "$TARGET_STRINGS" ] && [ "$LPROJ_NAME" != "en" ]; then
            cp "$TARGET_STRINGS" "$EN_STRINGS"
            echo "Fixed: copied ${LPROJ_NAME}.lproj strings over en.lproj"
        else
            echo "Could not auto-fix launcher strings."
            echo "Manually copy the correct .lproj/Localizable.strings over en.lproj/"
        fi
    fi
fi

echo ""
echo "Done! Language set to $LANG_CODE."
