# Game Mode Never Activates (macOS 14+)

Old Mac ports and repacks never trigger **Game Mode**, because their `Info.plist` predates Sonoma and does not declare the app as a game.

## Symptom

- The game runs full screen, but no controller icon appears in the menu bar.
- Game Mode is on and works for other games.

## Why

`gamepolicyd` needs two things, and old bundles usually have neither:

- `LSApplicationCategoryType` — the app must declare a games category.
- `CFBundleIdentifier` — without one, LaunchServices cannot register the bundle as a distinct app at all.

Repacks are the worst case. They often wrap the real game in a hand-made outer `.app` whose `CFBundleExecutable` is a shell script, and neither plist carries either key.

## Check a Game

```bash
plutil -p "Game.app/Contents/Info.plist" | grep -E "CFBundleIdentifier|LSApplicationCategoryType"
```

No output for either key means this fix applies.

## Usage

```bash
./enable-gamemode.sh "/path/to/Game.app"
```

The script patches every `Info.plist` in the bundle tree, then re-registers with LaunchServices. It backs each one up as `Info.plist.orig`.

If the bundle nests a second `.app`, both are patched. That matters: when the outer executable is a launcher script, the real `NSApplication` belongs to the inner bundle, and that inner one is what `gamepolicyd` judges.

## The Plist Is Not Enough — You Need a Real Full-Screen Space

This is the part that catches people out. Game Mode requires a macOS full-screen **Space**, the kind the green button creates. A game filling the screen with a borderless window does **not** qualify, and most SDL ports do exactly that.

Check which one you have:

```bash
defaults read com.apple.spaces SpacesDisplayConfiguration | grep -c "type = 4"
```

`0` means no full-screen Space exists, so Game Mode cannot engage no matter how the plist reads. A real one shows as `type = 4`.

If the game has no fullscreen option, or its option is borderless, try the system shortcut with the game focused:

```
Control + Command + F
```

That works when the window is resizable, because SDL then gives it `NSWindowCollectionBehaviorFullScreenPrimary`. Look for a resize event in the game's own log to tell:

```
App.cpp:331  DBG| App.resize 2336x1460
```

If the shortcut does nothing, the window does not accept full-screen Spaces and Game Mode is out of reach for that build without patching how the window is created.

What you get once it does engage: CPU and GPU priority over background work, and doubled Bluetooth sampling rate for wireless pads and audio.

## Gotcha — `open` Hangs on an Unsigned Bundle

Game Mode wants the app launched through LaunchServices, not from a shell. But on an **unsigned** bundle sitting on an **external drive**, `open` can hang forever at a black screen. Sampling the process shows where:

```
main → MTLCopyAllDevices → MTLDeviceArrayInitialize
     → IOSurfaceClientCopyGPUPolicies
       → CFURLCopyResourcePropertyForKey     ← blocked here
```

Metal will not hand over a device until `IOSurfaceClientCopyGPUPolicies` resolves the per-app GPU policy, and that lookup stalls indefinitely against an unsigned bundle the security assessment cannot place. Launching the binary straight from a terminal avoids it, because the responsible app is then your terminal, which is already assessed and cached.

Ad-hoc signing the **outer** bundle fixes `open`:

```bash
codesign --force --deep --sign - "/path/to/Game.app"
```

Signing the outer bundle alone is enough. The lookup needs a resolvable identity, not an approved one — `spctl` still reports `rejected` afterwards, and that is fine.

Two things to know:

- `--deep` does **not** sign a nested `.app` that sits outside the standard locations (`Frameworks`, `PlugIns`, `XPCServices`). A repack's inner app under `Contents/Game/` is sealed as a plain resource and stays unsigned. It does not need signing.
- Budget the time. This hashes the whole bundle, so an 11 GB game on an external HFS+ drive takes about 10 minutes. Do not launch the game while it runs — `codesign` rewrites the Mach-O binaries in place, and the kernel has those pages mapped.

## Reverting

```bash
find "Game.app" -name "Info.plist.orig" -exec sh -c 'mv "$1" "${1%.orig}"' _ {} \;
```

## Verified on

- macOS 15.7 (Apple Silicon)
- Hades (Supergiant 2022 build, repack with a bash-script launcher)

Verified: the plist keys register correctly (`lsregister -dump` shows `category: public.app-category.action-games`), the frontmost-app identity resolves to the patched inner bundle, and ad-hoc signing unblocks `open`.

Not yet verified: Game Mode actually engaging. On the Hades repack the window is borderless and no full-screen Space is ever created, so the last step above is still untested there.
