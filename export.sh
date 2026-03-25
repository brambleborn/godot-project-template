#!/usr/bin/env bash
# export.sh — Export a Godot 4.6 project for multiple platforms and optionally push to itch.io
#
# Usage:
#   ./export.sh [options]
#
# Options:
#   --project <path>    Path to the Godot project directory (default: ./godot)
#   --output <path>     Output directory for builds (default: ./build)
#   --itch              Push builds to itch.io via butler
#   --mac               Include macOS export (requires running on macOS)
#   --ios               Include iOS export (requires running on macOS)
#   --version <tag>     Version string for itch.io upload (default: git describe)
#   -h, --help          Show this help message
#
# itch.io credentials are read from game.cfg [itch] section.
# Override with env vars: ITCHIO_API_KEY, ITCHIO_USER, ITCHIO_GAME

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CFG="$SCRIPT_DIR/game.cfg"

# ── Read game.cfg ─────────────────────────────────────────────────────────────
cfg_get() {
  local section="$1" key="$2"
  awk -F= "/^\[$section\]/{f=1} f && /^$key=/{gsub(/^[^=]+=/, \"\"); print; exit}" "$CFG"
}

PROJECT_NAME="$(cfg_get project name)"
VERSION_DEFAULT="$(cfg_get project version)"
COMPANY_NAME="$(cfg_get company name)"
BUNDLE_ID="$(cfg_get company bundle_id)"
COPYRIGHT="$(cfg_get company copyright)"
ITCH_USER="${ITCHIO_USER:-$(cfg_get itch user)}"
ITCH_GAME="${ITCHIO_GAME:-$(cfg_get itch game)}"

# ── Defaults ─────────────────────────────────────────────────────────────────
PROJECT_PATH="$SCRIPT_DIR/godot"
OUTPUT_DIR="$SCRIPT_DIR/build"
PUSH_ITCH=false
INCLUDE_MAC=false
INCLUDE_IOS=false
VERSION=""

# ── Argument parsing ──────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --project) PROJECT_PATH="$2"; shift 2 ;;
    --output)  OUTPUT_DIR="$2";   shift 2 ;;
    --itch)    PUSH_ITCH=true;    shift ;;
    --mac)     INCLUDE_MAC=true;  shift ;;
    --ios)     INCLUDE_IOS=true;  shift ;;
    --version) VERSION="$2";      shift 2 ;;
    -h|--help)
      sed -n '/^# Usage/,/^[^#]/p' "$0" | grep '^#' | sed 's/^# \?//'
      exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# ── Validation ────────────────────────────────────────────────────────────────
if [[ "$INCLUDE_MAC" == true || "$INCLUDE_IOS" == true ]]; then
  if [[ "$(uname)" != "Darwin" ]]; then
    echo "Error: --mac and --ios require running on macOS." >&2
    exit 1
  fi
fi

if [[ "$PUSH_ITCH" == true ]]; then
  if ! command -v butler &>/dev/null; then
    echo "Error: 'butler' not found in PATH." >&2; exit 1
  fi
  : "${ITCHIO_API_KEY:?ITCHIO_API_KEY env var is required for --itch}"
  if [[ -z "$ITCH_USER" || "$ITCH_USER" == "your-itch-username" ]]; then
    echo "Error: Set [itch] user in game.cfg or ITCHIO_USER env var." >&2; exit 1
  fi
  if [[ -z "$ITCH_GAME" || "$ITCH_GAME" == "your-game-slug" ]]; then
    echo "Error: Set [itch] game in game.cfg or ITCHIO_GAME env var." >&2; exit 1
  fi
fi

if [[ -z "$VERSION" ]]; then
  VERSION=$(git -C "$SCRIPT_DIR" describe --tags --abbrev=0 2>/dev/null || echo "${VERSION_DEFAULT:-dev}")
fi

# ── Export presets ─────────────────────────────────────────────────────────────
# preset name → output file (relative to OUTPUT_DIR)
declare -A PRESETS
PRESETS["Windows Desktop"]="windows/game.exe"
PRESETS["Linux/X11"]="linux/game.x86_64"
PRESETS["HTML5"]="html5/index.html"
PRESETS["Android"]="android/game.apk"

if [[ "$INCLUDE_MAC" == true ]]; then
  PRESETS["Mac OSX"]="macosx/game.zip"
fi
if [[ "$INCLUDE_IOS" == true ]]; then
  PRESETS["iOS"]="ios/game.ipa"
fi

# ── itch.io channel mapping ───────────────────────────────────────────────────
declare -A ITCH_CHANNELS
ITCH_CHANNELS["Windows Desktop"]="windows"
ITCH_CHANNELS["Linux/X11"]="linux"
ITCH_CHANNELS["HTML5"]="html5"
ITCH_CHANNELS["Android"]="android"
ITCH_CHANNELS["Mac OSX"]="mac"
ITCH_CHANNELS["iOS"]="ios"

# ── Render export_presets.cfg from template ───────────────────────────────────
PRESETS_TPL="$PROJECT_PATH/export_presets.cfg.tpl"
PRESETS_OUT="$PROJECT_PATH/export_presets.cfg"
sed \
  -e "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" \
  -e "s/{{COMPANY_NAME}}/$COMPANY_NAME/g" \
  -e "s/{{BUNDLE_ID}}/$BUNDLE_ID/g" \
  -e "s/{{COPYRIGHT}}/$COPYRIGHT/g" \
  -e "s/{{VERSION}}/$VERSION/g" \
  "$PRESETS_TPL" > "$PRESETS_OUT"

# ── Run exports ───────────────────────────────────────────────────────────────
mkdir -p "$OUTPUT_DIR"

for preset in "${!PRESETS[@]}"; do
  out_file="$OUTPUT_DIR/${PRESETS[$preset]}"
  out_dir="$(dirname "$out_file")"
  mkdir -p "$out_dir"

  echo "Exporting: $preset → $out_file"
  godot --headless --path "$PROJECT_PATH" --export-release "$preset" "$(realpath "$out_file")" 2>&1

  # HTML5: inject coi-serviceworker for SharedArrayBuffer support
  if [[ "$preset" == "HTML5" ]]; then
    coi_url="https://github.com/gzuidhof/coi-serviceworker/raw/master/coi-serviceworker.js"
    echo "  Injecting coi-serviceworker..."
    curl -fsSL "$coi_url" -o "$out_dir/coi-serviceworker.js"
    sed -i 's#\(<script src="index.js"></script>\)#<script src="coi-serviceworker.js"></script>\n\1#g' "$out_dir/index.html"
  fi
done

# ── Zip builds ────────────────────────────────────────────────────────────────
echo ""
echo "Zipping builds..."
for preset in "${!PRESETS[@]}"; do
  out_dir="$OUTPUT_DIR/$(dirname "${PRESETS[$preset]}")"
  zip_name="$(basename "$out_dir").zip"
  (cd "$out_dir" && zip -r "$OUTPUT_DIR/$zip_name" .)
  echo "  $OUTPUT_DIR/$zip_name"
done

# ── itch.io deploy ────────────────────────────────────────────────────────────
if [[ "$PUSH_ITCH" == true ]]; then
  echo ""
  echo "Pushing to itch.io ($ITCH_USER/$ITCH_GAME @ $VERSION)..."
  export BUTLER_API_KEY="$ITCHIO_API_KEY"

  for preset in "${!ITCH_CHANNELS[@]}"; do
    [[ -v "PRESETS[$preset]" ]] || continue
    out_dir="$OUTPUT_DIR/$(dirname "${PRESETS[$preset]}")"
    channel="${ITCH_CHANNELS[$preset]}"
    echo "  butler push $out_dir → $channel"
    butler push "$out_dir" "$ITCH_USER/$ITCH_GAME:$channel" --userversion "$VERSION"
  done
fi

echo ""
echo "Done. Builds in $OUTPUT_DIR/"
