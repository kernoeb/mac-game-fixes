#!/bin/bash
set -euo pipefail

if [ $# -lt 1 ]; then
    echo "Usage: $0 <path-to-game.app>"
    echo "Example: $0 '/Applications/OXENFREE.app'"
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

# Check if InControl Xbox360MacProfile exists
if ! strings "$DLL" | grep -q "Xbox360MacProfile"; then
    echo "Error: This game doesn't use InControl's Xbox360MacProfile."
    echo "This fix won't help."
    exit 1
fi

# Check current state
echo "Checking current LastResortRegex..."
CURRENT=$(python3 -c "
with open('$DLL', 'rb') as f:
    data = f.read()

# Check for original '360'
orig = b'\x07\x33\x00\x36\x00\x30\x00\x00'
# Check for patched 'b|P'
patched = b'\x07\x62\x00\x7C\x00\x50\x00\x00'

if data.find(patched) != -1:
    print('ALREADY_PATCHED')
elif data.find(orig) != -1:
    print('ORIGINAL')
else:
    print('UNKNOWN')
")

if [ "$CURRENT" = "ALREADY_PATCHED" ]; then
    echo "Already patched! Nothing to do."
    exit 0
fi

if [ "$CURRENT" = "UNKNOWN" ]; then
    echo "Warning: Could not find the expected '360' regex string."
    echo "The DLL may have been modified or uses a different InControl version."
    echo ""
    read -p "Try to patch anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Backup
if [ ! -f "$DLL.bak" ]; then
    cp "$DLL" "$DLL.bak"
    echo "Backup created: Assembly-CSharp.dll.bak"
else
    echo "Backup already exists, skipping."
fi

# Patch
echo "Patching LastResortRegex: '360' -> 'b|P' ..."
python3 -c "
with open('$DLL', 'rb') as f:
    data = bytearray(f.read())

# '360' in UTF-16LE with .NET #US heap framing
old = b'\x07\x33\x00\x36\x00\x30\x00\x00'
# 'b|P' in UTF-16LE — regex: match 'b' (in 'Xbox') or 'P' (in 'GamePad')
new = b'\x07\x62\x00\x7C\x00\x50\x00\x00'

pos = data.find(old)
if pos == -1:
    print('ERROR: Pattern not found')
    exit(1)

data[pos:pos+len(old)] = new

with open('$DLL', 'wb') as f:
    f.write(data)

print(f'Patched at offset 0x{pos:x}')
"

echo ""
echo "Done! Now:"
echo "  1. Open System Settings > Game Controllers"
echo "  2. Click '+' at bottom left, add this game"
echo "  3. Enable 'Increase controller compatibility'"
echo "  4. Connect your Xbox controller via Bluetooth"
echo "  5. Launch the game"
