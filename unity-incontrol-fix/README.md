# Unity/InControl — Xbox Controller Button Fix

## The Problem

Unity games using the **InControl** input library detect Xbox controllers as "Unknown Controller" on modern macOS. The stick axes work (you can navigate menus up/down), but no buttons register because InControl's built-in Xbox profiles match joystick names from the old `360Controller.kext` that no longer loads.

## How It Works

InControl profiles are compiled into `Assembly-CSharp.dll`. Each profile has:
- **JoystickNames**: exact strings to match (e.g., `""`, `"Microsoft Wireless 360 Controller"`)
- **LastResortRegex**: a regex fallback (e.g., `"360"`)
- **Button mappings**: which Unity joystick button index maps to which game action

The `Xbox360MacProfile` has `LastResortRegex = "360"` which doesn't match macOS's native controller names:
- Bluetooth raw device: `"Xbox Wireless Controller"`
- Synthetic device: `"GamePad-1"`

The fix patches the regex in the DLL's .NET string heap (same byte length, no structural changes).

## The Patch

We change the 3-character `LastResortRegex` from `"360"` to `"b|P"`:
- `b` matches "X**b**ox Wireless Controller" (raw Bluetooth device)
- `P` matches "Game**P**ad-1" (macOS synthetic device)

This makes **both** HID devices match the Xbox360MacProfile, preventing the game from flip-flopping between "XBox 360 Controller" and "Unknown Controller" modes.

## Prerequisites

1. **Enable controller compatibility mode** in macOS:
   - System Settings > Game Controllers
   - Click "+" at bottom left, add the game
   - Toggle on "Increase controller compatibility"

2. **Connect via Bluetooth** (not USB)

## Usage

```bash
./patch-incontrol.sh "/path/to/Game.app"
```

## Tested Games

- OXENFREE

## How to Check if a Game Uses InControl

```bash
strings "Game.app/Contents/Resources/Data/Managed/Assembly-CSharp.dll" | grep "Xbox360MacProfile"
```

If this returns results, the game uses InControl and this fix likely applies.

## Reverting

The script creates a `.bak` backup. To revert:

```bash
DLL="Game.app/Contents/Resources/Data/Managed/Assembly-CSharp.dll"
cp "$DLL.bak" "$DLL"
```
