# godot-project-template

An opinionated Godot 4.6 project template with multi-platform export and itch.io deployment.

## Quick start

```sh
# 1. Clone and enter
git clone <this-repo> my-game && cd my-game

# 2. Edit project identity
$EDITOR game.cfg

# 3. Set up (initialises submodules, renders project.godot)
./setup.sh

# 4. Open in Godot and build your game, then export
./export.sh
```

## game.cfg

All project identity lives here. Both `setup.sh` and `export.sh` read from it.

```ini
[project]
name=Game           # config/name in project.godot
version=1.0         # fallback version if no git tag exists

[company]
name=YourCompany
bundle_id=com.yourcompany.game  # used for Android, macOS, iOS
copyright=2026

[itch]
user=your-itch-username
game=your-game-slug
```

## setup.sh

Run once after cloning, and again with `--reset` after editing `game.cfg`.

```sh
./setup.sh           # init submodules, render project.godot, copy export credentials
./setup.sh --reset   # re-render project.godot from template (skips submodule init)
./setup.sh --itch    # also validate that butler is installed
```

## export.sh

Exports Windows, Linux, HTML5, and Android by default.

```sh
./export.sh                      # build all default platforms
./export.sh --mac --ios          # add macOS and iOS (must run on macOS)
./export.sh --itch               # also push to itch.io (requires ITCHIO_API_KEY)
./export.sh --version 1.2.0      # override version (default: latest git tag)
./export.sh --dry-run            # print what would be exported/pushed, do nothing
./export.sh --output ./dist      # write builds to a custom directory
```

Builds are written to `build/` and zipped per platform. The HTML5 build has
[coi-serviceworker](https://github.com/gzuidhof/coi-serviceworker) injected
automatically for SharedArrayBuffer support.

### itch.io deployment

Requires:
- `butler` on PATH
- `ITCHIO_API_KEY` env var set
- `[itch]` user and game set in `game.cfg` (or `ITCHIO_USER` / `ITCHIO_GAME` env vars)

### macOS and iOS

Untested. Requires running on macOS. Update `godot/export_credentials.defaults` with your
certificates and provisioning profiles before exporting. `icon.icns` must be
provided manually at `godot/icon.icns`.

## godot-modules submodule

`godot/modules` tracks [brambleborn/godot-modules](https://github.com/brambleborn/godot-modules).
Each module is self-contained — import only what you need.

```sh
git submodule update --remote godot/modules   # update to latest
```
