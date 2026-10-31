# Unity legacy input — Xbox controller does nothing

Some old Unity games read the controller through Unity's legacy `Input` API. They hardcode the button numbers of the old Mac Xbox 360 driver (`360Controller.kext`). That driver no longer loads on modern macOS, so the pad does nothing in game.

You do not need to patch the game. macOS can fake an Xbox 360 pad for one game at a time.

## Symptom

- The controller works in other apps and games.
- In the game, no button and no stick does anything.

## Why

The game maps its actions to the 360 driver layout. Firewatch, for example, does this in `InputHandler.CreateMacMapping`:

| Action | Button number |
|---|---|
| A, B, X, Y | 16, 17, 18, 19 |
| LB, RB | 13, 14 |
| Start, Back | 9, 10 |
| D-pad up, down, left, right | 5, 6, 7, 8 |

A modern Xbox pad never reports these numbers. Over USB it is worse: Apple's driver exposes only vendor-defined HID elements (`UsagePage 0xFF00`), so Unity sees 0 buttons and 0 axes.

With "Increase controller compatibility" on, macOS creates a synthetic device called `GamePad-1` (Microsoft `045e:028e`, the Xbox 360 IDs). It uses the old 360 driver layout, and it works over USB and Bluetooth.

## How to check if a game is affected

Look for the old 360 button numbers in the game code:

```bash
DLL="Game.app/Contents/Resources/Data/Managed/Assembly-CSharp.dll"
python3 -c 'import sys; d=open(sys.argv[1],"rb").read(); print("joystick button 16".encode("utf-16le") in d)' "$DLL"
```

`True` means the game probably expects the 360 layout and this fix applies.

## Fix

1. Connect the controller (USB or Bluetooth).
2. Open System Settings, then Game Controllers.
3. Click the controller row. USB and Bluetooth show as 2 separate rows, so pick the one you play with.
4. Click "+" at the bottom left and add the game.
5. Select the game and turn on "Increase controller compatibility".
6. Click OK, then quit the game fully and start it again. The game only looks for controllers at launch.

The setting is saved per game and per controller connection. Check it with:

```bash
defaults read com.apple.GameController | grep -A4 '<bundle id>'
```

You should see `controllerToCompatibilityModeMappings` set to `xbox360`.

## Tested games

- Firewatch (Unity 5.6.5, GOG build), Xbox Series controller over USB
