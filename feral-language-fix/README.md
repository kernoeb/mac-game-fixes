# Feral Interactive — Language Fix

## The Problem

Some repackaged Feral ports have `Language=rus` hardcoded in the Unreal Engine config, overriding your system language. The game launches in Russian regardless of macOS locale.

Additionally, the `.lproj` localization folders for the Feral launcher UI may contain Russian text even in the `en.lproj` folder.

## Affected Games

Any Feral Interactive Unreal Engine 3 port, including:
- Life Is Strange

## Fix

```bash
./fix-language.sh "/path/to/Game.app" FRA
```

### Supported Language Codes

| Code  | Language              |
|-------|-----------------------|
| `INT` | English               |
| `FRA` | French                |
| `DEU` | German                |
| `ESN` | Spanish (Spain)       |
| `ESM` | Spanish (Latin Am.)   |
| `ITA` | Italian               |
| `PTB` | Portuguese (Brazil)   |
| `RUS` | Russian               |

The script also fixes the Feral launcher UI by copying the correct `.lproj` strings over the `en.lproj` if it detects Russian content there.
