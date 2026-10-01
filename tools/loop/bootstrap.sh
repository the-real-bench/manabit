#!/usr/bin/env bash
# MANABIT autonomous loop - phase 0a: make this machine able to test the game.
#
# Acquires a headless-capable Godot 4.7 engine, caches it, and imports the project
# so every `class_name` global registers. Idempotent: safe to run at the top of
# every iteration. Prints the engine path on stdout as ENGINE=<path>.
#
# The point of this script: verification must never depend on the owner's PC.
# Before it existed, "green" was a claim relayed from a machine nobody in the
# loop could reach. Now it is a fact this container can reproduce.
set -euo pipefail

VERSION="${MANABIT_GODOT_VERSION:-4.7-stable}"
CACHE="${MANABIT_GODOT_CACHE:-/opt/godot-cache}"
BIN="$CACHE/Godot_v${VERSION}_linux.x86_64"
URL="https://github.com/godotengine/godot/releases/download/${VERSION}/Godot_v${VERSION}_linux.x86_64.zip"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# An engine already on PATH or pointed at by $GODOT wins - lets the owner's
# Windows checkout reuse this script's callers without a download.
if [ -n "${GODOT:-}" ] && "$GODOT" --version >/dev/null 2>&1; then
  echo "ENGINE=$GODOT"; BIN="$GODOT"
else
  if [ ! -x "$BIN" ]; then
    echo "[bootstrap] fetching Godot $VERSION ..." >&2
    mkdir -p "$CACHE"
    curl -sSL --retry 4 --retry-delay 2 -o "$CACHE/godot.zip" "$URL"
    python3 -c "import zipfile,sys;zipfile.ZipFile(sys.argv[1]).extractall(sys.argv[2])" "$CACHE/godot.zip" "$CACHE"
    chmod +x "$BIN"
    rm -f "$CACHE/godot.zip"
  fi
  echo "ENGINE=$BIN"
fi

"$BIN" --version >&2

# Import registers class_name globals. Required once per fresh checkout, cheap after.
if [ ! -d "$ROOT/.godot" ] || [ "${MANABIT_FORCE_IMPORT:-0}" = "1" ]; then
  echo "[bootstrap] importing project ..." >&2
  "$BIN" --headless --path "$ROOT" --import >/dev/null 2>&1 || true
fi
echo "[bootstrap] ready" >&2
