#!/usr/bin/env bash
# MANABIT autonomous loop - phase 4 L3: render the game and LOOK at it.
#
#   tools/loop/shots.sh                 # all 6 screens via tests/shoot.gd
#   tools/loop/shots.sh shoot_kit       # any tests/shoot_*.gd harness
#
# Renders windowed under a virtual display (Xvfb + software GL) and copies the
# PNGs to loop/out/shots/. Headless Godot draws nothing, so this is the ONLY way
# the loop can review anything visual - beauty, fit, contrast, clipping - without
# the owner at a monitor.
#
# The save is backed up and restored around the run: a windowed harness boots the
# real game and writes to user://. That discipline used to be a thing a human
# remembered to do. Here it is a thing the script cannot forget.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
HARNESS="${1:-shoot}"
ENGINE="$(bash tools/loop/bootstrap.sh 2>/dev/null | sed -n 's/^ENGINE=//p')"
[ -x "$ENGINE" ] || { echo "shots: no engine"; exit 2; }

USERDIR="$HOME/.local/share/godot/app_userdata/MANABIT"
SAVE="$USERDIR/manabit_save.json"
OUT="$ROOT/loop/out/shots"
mkdir -p "$OUT" "$USERDIR"

# HERMETIC (L-16). The save is backed up, then REMOVED, so every capture boots from
# the same fresh state instead of inheriting whatever the last run left behind.
# Without this, run N+1 renders a different wallet, a different shelf and a different
# tray than run N with no code change between them - measured at d8a6b41 vs 028a158 -
# which makes frame-to-frame comparison meaningless. Visual review is a primary
# verification layer; a baseline that drifts on its own hides real regressions and
# invents fake ones.
#
# A save present before the run is restored byte-identical afterwards, including when
# the run dies partway: the trap fires on EXIT.
[ -f "$SAVE" ] && cp "$SAVE" "$SAVE.loopbak"
rm -f "$SAVE"
restore() {
  if [ -f "$SAVE.loopbak" ]; then mv -f "$SAVE.loopbak" "$SAVE"; else rm -f "$SAVE"; fi
}
trap restore EXIT

DISP=":$(( (RANDOM % 400) + 99 ))"
Xvfb "$DISP" -screen 0 1280x720x24 >/dev/null 2>&1 &
XPID=$!
trap 'kill $XPID 2>/dev/null; restore' EXIT
sleep 2

rm -f "$USERDIR"/shot_*.png
DISPLAY="$DISP" timeout 600 "$ENGINE" --path . --rendering-driver opengl3 \
  --script "res://tests/${HARNESS}.gd" 2>&1 | grep -Ei "SHOTS SAVED|SCRIPT ERROR|Parse Error" | tail -5
rc=${PIPESTATUS[0]}

n=0
for f in "$USERDIR"/shot_*.png; do
  [ -e "$f" ] || continue
  cp "$f" "$OUT/"; n=$((n+1))
done

# A zero-byte or single-colour capture means the renderer failed silently.
python3 - "$OUT" <<'PY'
import sys,os,struct,zlib
d=sys.argv[1]; bad=[]
for f in sorted(os.listdir(d)):
    if not f.endswith(".png"): continue
    p=os.path.join(d,f); sz=os.path.getsize(p)
    if sz < 5000: bad.append((f,f"{sz}B - suspiciously small"))
if bad:
    print("SUSPECT CAPTURES:"); [print(" ",f,r) for f,r in bad]
PY

echo "captured $n shot(s) -> loop/out/shots/ (engine rc=$rc)"
[ "$n" -gt 0 ] || exit 1
