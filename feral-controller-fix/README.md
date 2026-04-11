# Feral Interactive — Xbox Controller Fix

## The Problem

Feral Interactive Mac ports (2014–2018 era) use the `360Controller.kext` to detect Xbox controllers. This kernel extension doesn't load on modern macOS (Apple Silicon, SIP enabled). The game shows "No devices" in the controller settings.

## Supported Games

Any Feral Interactive port with an `InputDevices/` folder inside the app bundle, including:
- Life Is Strange
- Tomb Raider (2013)
- BioShock Infinite
- Sleeping Dogs
- XCOM 2
- Rise of the Tomb Raider

## How It Works

macOS 14+ natively supports Xbox controllers via Bluetooth and exposes them as standard HID devices. The fix adds `.plist` device profiles that tell the Feral wrapper how to read the native HID elements.

Key insight: `CGPDeviceType` must be `Standard` (not `Xbox`). Using `Xbox` triggers the old kext code path.

## Installation

```bash
./install.sh "/path/to/Game.app"
```

Or manually: copy the `.plist` files into:
```
Game.app/Contents/Resources/InputDevices/Customer/
```

## Important Notes

- **Use Bluetooth, not USB.** Over USB, macOS's driver captures the controller and only exposes vendor-specific HID elements. Over Bluetooth, standard HID elements are available.
- The plists are from [axu2/feral-interactive-mac-controllers](https://github.com/axu2/feral-interactive-mac-controllers).
