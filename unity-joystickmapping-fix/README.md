# Unity/JoystickMapping — Xbox Controller Button Fix

## The Problem

Some Unity games ship with a hand-written `JoystickInputManager` / `JoystickMapping` class instead of using a library like InControl or Rewired. Detection is done by substring-matching `Input.GetJoystickNames()` against hardcoded names like `"360"` and `"wireless"`.

On modern macOS, a Bluetooth Xbox Wireless Controller (Xbox Series / recent Xbox One) reports its Unity name as `"Xbox Wireless Controller"`. That string:

- does **not** contain `"360"` → the Xbox 360 branch misses
- does **not** contain `"one"` → the Xbox One branch misses
- **does** contain `"wireless"` → the game falls into the PlayStation branch

Result: the game shows PlayStation button glyphs (X/Square/Triangle) and the A button doesn't behave like A because it's wired to the PS mapping.

## How It Works

The detection code is roughly:

```csharp
foreach (var name in Input.GetJoystickNames()) {
    if (name.Contains("360"))                               // → Xbox 360 profile
    else if (name.ToLower().Contains("one"))                // → Xbox One profile
    else if (name.ToLower().Contains("playstation") && ...) // → PS3 profile
    else if (name.ToLower().Contains("sony")
         || name.ToLower().Contains("wireless"))            // → PS4 profile  ← wrong branch
}
```

## The Patch

Change the first-branch literal `"360"` → `"box"` in the DLL's .NET `#US` string heap. `"box"` is a case-sensitive substring of:

- `"Microsoft X-Box 360 pad"` — legacy 360 names still match
- `"Xbox Wireless Controller"` — new Series / Xbox One BT controllers match
- `"Xbox One Controller"` — also matches (harmless, goes to Xbox 360 profile, which is what macOS compat mode emulates anyway)

All Xbox-family controllers now take the first branch, so the incorrect `"wireless"` → PlayStation fall-through is bypassed.

Same byte length, no structural changes to the assembly.

## Prerequisites

1. **Enable controller compatibility mode** in macOS:
   - System Settings → Game Controllers
   - Click "+" at bottom left, add the game
   - Toggle on "Increase controller compatibility"
   - Pick **Xbox 360** mode from the dropdown

2. **Connect via Bluetooth** (not USB)

## Usage

```bash
./patch-joystickmapping.sh "/path/to/Game.app"
```

## Tested Games

- Life is Strange: Before the Storm (Feral Interactive port, 2018)

## How to Check if a Game Uses This Pattern

```bash
strings "Game.app/Contents/Resources/Data/Managed/Assembly-CSharp.dll" | grep -E "^(JoystickInputManager|JoystickMapping)$"
```

If both strings are present and the game shows PS glyphs with an Xbox Wireless Controller, this fix likely applies.

## Reverting

The script creates a `.bak` backup. To revert:

```bash
DLL="Game.app/Contents/Resources/Data/Managed/Assembly-CSharp.dll"
cp "$DLL.bak" "$DLL"
```
