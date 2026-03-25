#!/usr/bin/env bash
# setup.sh — One-time project setup. Run this after cloning.
#
# Usage:
#   ./setup.sh [options]
#
# Options:
#   --itch      Also validate butler is installed
#   --reset     Re-render project.godot from template (use after editing game.cfg)
#   -h, --help  Show this help message

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CFG="$SCRIPT_DIR/game.cfg"

cfg_get() {
  local section="$1" key="$2"
  awk -F= "/^\[$section\]/{f=1} /^\[/{if (!/^\[$section\]/) f=0} f && /^$key=/{gsub(/^[^=]+=/, \"\"); print; exit}" "$CFG"
}

sed_escape() {
  printf '%s' "$1" | sed 's/[\/&]/\\&/g'
}

VALIDATE_ITCH=false
RESET=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --itch)    VALIDATE_ITCH=true; shift ;;
    --reset)   RESET=true; shift ;;
    -h|--help)
      sed -n '/^# Usage/,/^[^#]/p' "$0" | grep '^#' | sed 's/^# \?//'
      exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# ── Validate game.cfg placeholders ───────────────────────────────────────────
warn_placeholder() {
  local section="$1" key="$2" placeholder="$3"
  local val
  val="$(cfg_get "$section" "$key")"
  if [[ -z "$val" || "$val" == "$placeholder" ]]; then
    echo "Warning: [$section] $key is still set to placeholder value '$placeholder'. Edit game.cfg." >&2
  fi
}

warn_placeholder project  name        "Game"
warn_placeholder company  name        "YourCompany"
warn_placeholder company  bundle_id   "com.yourcompany.game"
warn_placeholder itch     user        "your-itch-username"
warn_placeholder itch     game        "your-game-slug"

# ── Validate dependencies ─────────────────────────────────────────────────────
if [[ "$RESET" == false ]] && ! command -v godot &>/dev/null; then
  echo "Error: 'godot' not found in PATH. Install Godot 4.6 and ensure it is on your PATH." >&2
  exit 1
fi

if [[ "$VALIDATE_ITCH" == true ]] && ! command -v butler &>/dev/null; then
  echo "Error: 'butler' not found in PATH. Install itch.io butler to deploy to itch.io." >&2
  exit 1
fi

# ── Submodules ────────────────────────────────────────────────────────────────
if [[ "$RESET" == false ]]; then
  echo "Initialising submodules..."
  git -C "$SCRIPT_DIR" submodule update --init --recursive
fi

# ── Render project.godot from template ───────────────────────────────────────
PROJECT_NAME="$(cfg_get project name)"
sed -e "s/{{PROJECT_NAME}}/$(sed_escape "$PROJECT_NAME")/g" \
  "$SCRIPT_DIR/godot/project.godot.tpl" > "$SCRIPT_DIR/godot/project.godot"
echo "Rendered project.godot"

# ── Export credentials ────────────────────────────────────────────────────────
CREDS_DEFAULT="$SCRIPT_DIR/godot/export_credentials.defaults"
CREDS_DEST="$SCRIPT_DIR/godot/.godot/export_credentials.cfg"
if [[ -f "$CREDS_DEFAULT" && ! -f "$CREDS_DEST" ]]; then
  mkdir -p "$SCRIPT_DIR/godot/.godot"
  cp "$CREDS_DEFAULT" "$CREDS_DEST"
  echo "Copied export_credentials.defaults → godot/.godot/export_credentials.cfg"
fi

echo ""
if [[ "$RESET" == true ]]; then
  echo "Reset complete. project.godot re-rendered from template."
else
  echo "Setup complete. Edit game.cfg, then run ./export.sh to build."
fi
