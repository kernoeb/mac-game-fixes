# Mac Game Fixes for Modern macOS

Fixes for old Mac game ports that don't work properly on modern macOS (Apple Silicon, Sonoma/Sequoia).

## Problems Solved

- **Xbox controller not detected** in Feral Interactive ports (Life Is Strange, Tomb Raider, etc.)
- **Xbox controller buttons not working** in Unity games using InControl (OXENFREE, etc.)
- **Wrong language** in Russian-repackaged Feral ports

## Fixes

### 1. Feral Interactive — Xbox Controller Support

Old Feral ports rely on the `360Controller.kext` which doesn't load on modern macOS. The fix is adding device profile plists that use macOS's native HID support.

See [`feral-controller-fix/`](feral-controller-fix/)

### 2. Unity/InControl — Xbox Controller Button Mapping

Unity games using the InControl library don't recognize macOS's native Xbox controller. The game detects it as "Unknown Controller" and buttons don't work (only stick axes do).

See [`unity-incontrol-fix/`](unity-incontrol-fix/)

### 3. Feral Interactive — Language Fix

Some repackaged Feral ports have hardcoded Russian language settings.

See [`feral-language-fix/`](feral-language-fix/)

## Prerequisites

- macOS 14+ (Sonoma or later)
- Xbox controller connected via Bluetooth (USB has limited support — macOS's native driver doesn't expose standard HID elements over USB)
- Python 3 (pre-installed on macOS)

## Credits

- Xbox controller plists from [axu2/feral-interactive-mac-controllers](https://github.com/axu2/feral-interactive-mac-controllers)
