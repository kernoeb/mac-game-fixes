#!/usr/bin/env python3
"""Turn on "Increase controller compatibility" (xbox360 mode) for one game.

Does what System Settings > Game Controllers does, without the UI.

Usage:
  enable-compat-mode.py /path/to/Game.app          # all known controllers
  enable-compat-mode.py /path/to/Game.app --off    # turn it off again
  enable-compat-mode.py --list                     # show games and controllers
"""
import argparse
import os
import plistlib
import subprocess
import sys
from datetime import datetime

DOMAIN = "com.apple.GameController"


def load():
    out = subprocess.run(["defaults", "export", DOMAIN, "-"], check=True, capture_output=True).stdout
    return plistlib.loads(out)


def save(prefs):
    # Import through cfprefsd, so the running daemons see the change and do not overwrite it.
    data = plistlib.dumps(prefs, fmt=plistlib.FMT_BINARY)
    subprocess.run(["defaults", "import", DOMAIN, "-"], input=data, check=True)


def app_bundles(app):
    # Repacks wrap the real game in a launcher app. The game runs as the inner app, so it needs the setting too.
    bundles, missing = {}, []
    for path in [app] + [d for d, _, _ in os.walk(app) if d != app and d.endswith(".app")]:
        plist = os.path.join(path, "Contents", "Info.plist")
        if not os.path.isfile(plist):
            continue
        with open(plist, "rb") as f:
            info = plistlib.load(f)
        bundle_id = info.get("CFBundleIdentifier", "")
        if not bundle_id:
            missing.append(path)
            continue
        title = info.get("CFBundleDisplayName") or info.get("CFBundleName") or os.path.basename(path).removesuffix(".app")
        bundles.setdefault(bundle_id, title)
    return bundles, missing


def controllers(prefs):
    return {c["persistentIdentifier"]: c.get("name", "?") for c in prefs.get("controllers", {}).get("data", [])}


def find_game(games, bundle_id):
    return next((g for g in games if g.get("bundleIdentifier") == bundle_id), None)


def turn_on(games, bundle_id, title, known, default_profiles):
    entry = find_game(games, bundle_id)
    if entry is None:
        entry = {"bundleIdentifier": bundle_id, "title": title,
                 "controllerToCompatibilityModeMappings": {}, "controllerToProfileMappings": {}}
        games.append(entry)
    modes = entry.setdefault("controllerToCompatibilityModeMappings", {})
    profiles = entry.setdefault("controllerToProfileMappings", {})
    for pid, name in known.items():
        modes[pid] = "xbox360"
        if pid in default_profiles:
            profiles.setdefault(pid, default_profiles[pid])
        print(f"xbox360  {name} ({pid})")
    return entry


def turn_off(games, bundle_id, known):
    entry = find_game(games, bundle_id)
    modes = entry.get("controllerToCompatibilityModeMappings") if entry else None
    if not modes:
        return None
    # Also clear controllers macOS no longer lists, so none of them keeps the mode.
    for pid in modes:
        print(f"off      {known.get(pid, '?')} ({pid})")
    modes.clear()
    return entry


def show(prefs):
    print("Controllers:")
    for pid, name in controllers(prefs).items():
        print(f"  {name:30} {pid}")
    print("Games:")
    for g in prefs.get("games", {}).get("data", []):
        modes = g.get("controllerToCompatibilityModeMappings", {})
        print(f"  {g.get('title', '?'):30} {g.get('bundleIdentifier') or '(no id)':45} {modes or ''}")


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("app", nargs="?")
    p.add_argument("--off", action="store_true")
    p.add_argument("--list", action="store_true")
    args = p.parse_args()
    if args.off and not args.app:
        p.error("--off needs the path to the game")

    if args.list or not args.app:
        show(load())
        return

    app = os.path.normpath(args.app)
    if not os.path.isfile(os.path.join(app, "Contents", "Info.plist")):
        sys.exit(f"{app} is not an app: Contents/Info.plist is missing.")
    bundles, missing = app_bundles(app)
    if not bundles:
        sys.exit(f"{app} has no CFBundleIdentifier. Run gamemode-plist-fix first.")
    for path in missing:
        print(f"Skipped {path}: no CFBundleIdentifier. Run gamemode-plist-fix if the game runs from it.")

    prefs = load()
    known = controllers(prefs)
    if not known and not args.off:
        sys.exit("macOS knows no controller yet. Connect it, open System Settings > Game Controllers, "
                 "then run this again.")
    games = prefs.setdefault("games", {"data": [], "tombstones": []}).setdefault("data", [])
    default_profiles = (find_game(games, "com.apple.default") or {}).get("controllerToProfileMappings", {})
    now = datetime.now().astimezone().strftime("%Y-%m-%d %H:%M:%S %z")

    changed = []
    for bundle_id, title in bundles.items():
        if args.off:
            entry = turn_off(games, bundle_id, known)
        else:
            entry = turn_on(games, bundle_id, title, known, default_profiles)
        if entry:
            entry["modifiedDate"] = now
            changed.append(f"{title} ({bundle_id})")

    if not changed:
        print(f"Compatibility mode is already off for {app}.")
        return
    save(prefs)
    print(f"Done for {', '.join(changed)}. Quit the game fully and start it again.")


if __name__ == "__main__":
    main()
