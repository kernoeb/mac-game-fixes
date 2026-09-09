# Stale bundled SDL2 — Xbox Controller Over USB

Games that ship their own **SDL2 older than 2.0.18** cannot see an Xbox controller over USB on modern macOS. The pad works in every other app, so the game looks broken.

## Symptom

- The controller works system-wide and in other games.
- The game shows no controller at all — not "Unknown Controller", nothing.
- Bluetooth may work while USB does not, or neither works.

## Why

Over USB, Apple's driver does **not** expose the Xbox pad as a normal HID gamepad. Check what the descriptor actually contains:

```bash
ioreg -c IOHIDDevice -r -d1 | grep -A2 '"Product" = "Controller"'
```

Every element comes back on `"UsagePage" = 65280` — that is `0xFF00`, vendor-defined. There is not a single Generic Desktop axis (`UsagePage 1`) or Button-page entry (`UsagePage 9`). The pad is speaking Microsoft's GIP protocol wrapped in opaque vendor reports.

The only way to read it is Apple's **GameController framework**, which SDL added as the `SDL_JOYSTICK_MFI` backend. Older SDL builds have just the IOKit HID path, get nothing but vendor blobs, and report zero axes and zero buttons.

## How to Check if a Game Is Affected

Find the bundled framework and look for the backend:

```bash
find "Game.app" -name "SDL2" -path "*SDL2.framework*"
strings SDL2 | grep -oE "GCController|SDL_JOYSTICK_MFI" | sort -u
```

No output means no GameController backend — this fix applies.

## Usage

```bash
./install-sdl2.sh "/path/to/Game.app"
```

The script finds the bundled `SDL2.framework`, backs it up as `SDL2.framework.orig`, and drops in a current universal build from libsdl.org.

This is safe because SDL2 keeps a stable ABI, and the official framework's install name is already `@rpath/SDL2.framework/Versions/A/SDL2` — exactly what the game links against, so nothing needs rewriting.

## Tested Games

- Hades (Supergiant, 2022 build — shipped SDL2 with no MFI backend)

## Reverting

```bash
FW="Game.app/Contents/.../MacOS"
rm -rf "$FW/SDL2.framework"
mv "$FW/SDL2.framework.orig" "$FW/SDL2.framework"
```

## Verified on

- macOS 15.7 (Apple Silicon, game running x86_64 under Rosetta)
- SDL2 2.32.10
- Xbox Series X|S controller, USB-C wired (`045e:0b12`)

## Notes

- Use `/usr/bin/xattr`, not bare `xattr`. If you have Homebrew's Python `xattr` on your `PATH` it shadows Apple's and has no `-r` flag.
- The Bluetooth endpoint reports a different product ID (`045e:0b13`) from the USB one (`045e:0b12`). Same pad, two devices.
- This supersedes the "use Bluetooth, USB is unsupported" advice for any game you can patch. USB works fine once SDL can reach the GameController framework.
