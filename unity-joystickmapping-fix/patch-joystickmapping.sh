#!/bin/bash
set -euo pipefail

if [ $# -lt 1 ]; then
    echo "Usage: $0 <path-to-game.app>"
    echo "Example: $0 '/Applications/Life is Strange Before the Storm.app'"
    exit 1
fi

APP_PATH="$1"
DLL="$APP_PATH/Contents/Resources/Data/Managed/Assembly-CSharp.dll"

if [ ! -f "$DLL" ]; then
    echo "Error: Assembly-CSharp.dll not found at:"
    echo "  $DLL"
    echo "Is this a Unity game?"
    exit 1
fi

echo "Checking Assembly-CSharp.dll..."
RESULT=$(python3 - "$DLL" <<'PYEOF'
import sys

dll_path = sys.argv[1]
with open(dll_path, 'rb') as f:
    data = bytearray(f.read())

if b"JoystickInputManager" not in data or b"JoystickMapping" not in data:
    print("NO_JOYSTICKMAPPING")
    sys.exit(0)

# '360' in UTF-16LE with .NET #US heap framing (length prefix + null terminator)
orig = b'\x07\x33\x00\x36\x00\x30\x00\x00'
# 'box' — matches 'Xbox 360', 'Xbox Wireless Controller', 'Xbox One Controller'
patched = b'\x07\x62\x00\x6F\x00\x78\x00\x00'

if data.find(patched) != -1:
    print("ALREADY_PATCHED")
    sys.exit(0)

pos = data.find(orig)
if pos == -1:
    print("UNKNOWN")
    sys.exit(0)

# Ensure it's unique, otherwise we risk touching another literal
if data.count(orig) > 1:
    print("MULTIPLE")
    sys.exit(0)

print(f"NEEDS_PATCH:{pos}")
PYEOF
)

case "$RESULT" in
    NO_JOYSTICKMAPPING)
        echo "Error: This game doesn't use the JoystickInputManager/JoystickMapping classes."
        echo "This fix won't help."
        exit 1
        ;;
    ALREADY_PATCHED)
        echo "Already patched! Nothing to do."
        exit 0
        ;;
    UNKNOWN)
        echo "Warning: Could not find the expected '360' literal."
        echo "The DLL may be a different build."
        exit 1
        ;;
    MULTIPLE)
        echo "Error: Found multiple '360' literals. Aborting to avoid touching the wrong one."
        exit 1
        ;;
esac

if [ ! -f "$DLL.bak" ]; then
    cp "$DLL" "$DLL.bak"
    echo "Backup created: Assembly-CSharp.dll.bak"
else
    echo "Backup already exists, skipping."
fi

echo "Patching JoystickInputManager detection: '360' -> 'box' ..."
python3 - "$DLL" <<'PYEOF'
import sys

dll_path = sys.argv[1]
with open(dll_path, 'rb') as f:
    data = bytearray(f.read())

old = b'\x07\x33\x00\x36\x00\x30\x00\x00'
new = b'\x07\x62\x00\x6F\x00\x78\x00\x00'

pos = data.find(old)
if pos == -1:
    print("ERROR: Pattern not found")
    sys.exit(1)

data[pos:pos+len(old)] = new

with open(dll_path, 'wb') as f:
    f.write(data)

print(f"Patched at offset 0x{pos:x}")
PYEOF

echo ""
echo "Done! Now:"
echo "  1. Open System Settings > Game Controllers"
echo "  2. Click '+' at bottom left, add this game"
echo "  3. Enable 'Increase controller compatibility' (Xbox 360 mode)"
echo "  4. Connect your Xbox controller via Bluetooth"
echo "  5. Fully quit the game (Cmd+Q) and relaunch"
