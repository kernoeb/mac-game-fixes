# Mac Game Fixes for Modern macOS

Fixes for old Mac game ports that don't work properly on modern macOS (Apple Silicon, Sonoma/Sequoia).

## Problems Solved

- **Xbox controller not detected** in Feral Interactive ports (Life Is Strange, Tomb Raider, etc.)
- **Xbox controller buttons not working** in Unity games using InControl (OXENFREE, etc.)
- **Xbox controller face buttons not working** in RPCS3 (PS3 emulator)
- **Wrong language** in Russian-repackaged Feral ports
- **Xbox controller not detected over USB** in games bundling an old SDL2 (Hades, other 2022-era ports)
- **Game Mode never activates** for old ports and repacks

## Fixes

### 1. Feral Interactive — Xbox Controller Support

Old Feral ports rely on the `360Controller.kext` which doesn't load on modern macOS. The fix is adding device profile plists that use macOS's native HID support.

See [`feral-controller-fix/`](feral-controller-fix/)

### 2. Unity/InControl — Xbox Controller Button Mapping

Unity games using the InControl library don't recognize macOS's native Xbox controller. The game detects it as "Unknown Controller" and buttons don't work (only stick axes do).

See [`unity-incontrol-fix/`](unity-incontrol-fix/)

### 3. Unity/JoystickMapping — Xbox Wireless Controller Shows PlayStation Glyphs

Some Unity games (e.g. Life is Strange: Before the Storm) do their own joystick-name matching instead of using InControl. A Bluetooth Xbox Wireless Controller reports `"Xbox Wireless Controller"`, which falls into the PlayStation branch because it contains `"wireless"`.

See [`unity-joystickmapping-fix/`](unity-joystickmapping-fix/)

### 4. RPCS3 — Xbox Controller Face Buttons

RPCS3's SDL handler on macOS pre-fills face buttons with legacy SDL2 labels (`A`/`B`/`X`/`Y`) while the runtime now expects SDL3 labels (`South`/`East`/`West`/`North`). Stick and D-Pad work, but A/B/X/Y on an Xbox controller do nothing.

See [`rpcs3-xbox-fix/`](rpcs3-xbox-fix/)

### 5. Feral Interactive — Language Fix

Some repackaged Feral ports have hardcoded Russian language settings.

See [`feral-language-fix/`](feral-language-fix/)

### 6. Stale Bundled SDL2 — Xbox Controller Over USB

Games shipping their own SDL2 older than 2.0.18 have no GameController (`SDL_JOYSTICK_MFI`) backend. Over USB the Xbox pad exposes only vendor-defined HID elements (`UsagePage 0xFF00`), so those builds see zero axes and zero buttons. Dropping in a current SDL2 makes wired play work.

See [`sdl2-usb-controller-fix/`](sdl2-usb-controller-fix/)

### 7. Game Mode Never Activates

Old bundles lack `LSApplicationCategoryType`, and repacks often lack `CFBundleIdentifier` too, so `gamepolicyd` never treats the app as a game.

See [`gamemode-plist-fix/`](gamemode-plist-fix/)

## Prerequisites

- macOS 14+ (Sonoma or later)
- Xbox controller connected via Bluetooth for fixes 1-5 (macOS's native driver doesn't expose standard HID elements over USB, so anything reading raw HID needs Bluetooth)
- USB works for fix 6, which routes the pad through the GameController framework instead of raw HID
- Python 3 (required only for the Unity/InControl fix — install via Xcode Command Line Tools or Homebrew if needed)

## Credits

- Xbox controller plists from [axu2/feral-interactive-mac-controllers](https://github.com/axu2/feral-interactive-mac-controllers)
