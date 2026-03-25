# godot-project-template

A Godot 4.6 project template with multi-platform export and itch.io deployment.

## Structure

```
game.cfg                        ← edit this first — all project identity lives here
setup.sh                        ← run once after cloning
export.sh                       ← run to build and optionally deploy
godot/
  project.godot.tpl             ← rendered to project.godot by setup.sh
  export_presets.cfg.tpl        ← rendered to export_presets.cfg by export.sh
  export_credentials.defaults   ← copied to .godot/export_credentials.cfg by setup.sh
  main.tscn                     ← empty root node, replace with your own
  assets/                       ← drop game assets here
  modules/                      ← git submodule: brambleborn/godot-modules
```

Generated files (`project.godot`, `export_presets.cfg`, `godot/.godot/`) are gitignored.

## Setup

```sh
./setup.sh          # init submodules, render project.godot, copy credentials
./setup.sh --itch   # also validates that butler is installed
```

## Exporting

```sh
./export.sh                     # Windows, Linux, HTML5, Android
./export.sh --mac --ios         # add macOS and iOS (must run on macOS)
./export.sh --itch              # also push to itch.io (requires ITCHIO_API_KEY env var)
./export.sh --version 1.2.0    # override version (default: latest git tag)
```

Builds are written to `build/` and zipped per platform.

## game.cfg

All project identity is centralised here. `setup.sh` and `export.sh` read from it.

```ini
[project]
name=Game       ← config/name in project.godot
version=1.0     ← used in export presets and itch.io upload

[company]
name=YourCompany
bundle_id=com.yourcompany.game  ← used for Android, macOS, iOS
copyright=2026

[itch]
user=your-itch-username
game=your-game-slug
```

## itch.io deployment

Requires:
- `butler` on PATH
- `ITCHIO_API_KEY` env var set (not stored in game.cfg intentionally)
- `[itch]` user and game set in `game.cfg`

## godot-modules submodule

`godot/modules` tracks [brambleborn/godot-modules](https://github.com/brambleborn/godot-modules).
Each module is self-contained — import only what you need. See `godot/modules/README.md`.

To update to the latest modules:
```sh
git submodule update --remote godot/modules
```

## macOS and iOS

These targets require running on macOS and additional signing configuration.
Update `godot/export_credentials.defaults` with your certificates and provisioning profiles
before exporting. Icon files (`icon.icns`) must be provided manually.
