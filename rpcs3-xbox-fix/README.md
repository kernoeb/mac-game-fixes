# RPCS3 — Xbox Controller Face Buttons Fix (macOS)

On macOS, RPCS3's SDL handler pre-fills the face-button mapping with legacy SDL2 labels (`A`, `B`, `X`, `Y`). The handler has migrated to SDL3, which expects `South`, `East`, `West`, `North`. Result: the stick and D-Pad work, but pressing A/B/X/Y on an Xbox controller does nothing.

## Symptom

- `Configuration → Pads → Handlers: SDL` detects the controller (`Xbox Series X Controller 1`).
- Left stick, D-Pad, triggers, shoulders all respond.
- Face buttons (A/B/X/Y) do nothing — Cross/Circle/Square/Triangle stay unbound at runtime.

## Fix

Drop [`Xbox.yml`](Xbox.yml) into:

```
~/Library/Application Support/rpcs3/input_configs/global/
```

Then in RPCS3: `Configuration → Pads → Configuration Files → Xbox`.

The only delta vs `Default.yml` is in the Player 1 face-button block:

```yaml
Square: West      # was: X
Cross:  South     # was: A
Circle: East      # was: B
Triangle: North   # was: Y
```

## Install

```bash
cp Xbox.yml "$HOME/Library/Application Support/rpcs3/input_configs/global/"
```

Then select the `Xbox` profile in RPCS3's pad settings and save.

## Verified on

- macOS 14+ (Apple Silicon)
- RPCS3 0.0.40 (alpha, master)
- Xbox Series X Controller (Bluetooth)

## Notes

- USB-C wired mode is not supported by macOS's native driver for the Xbox Series controller — use Bluetooth.
- The other button strings (`LB`/`RB`/`LT`/`RT`/`LS`/`RS`/`Start`/`Back`/`Guide`, D-Pad, stick axes) are already correct in the default config.
