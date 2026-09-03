#!/usr/bin/env bash
# Per-screen visual verdict, with the tool admitting what it cannot see.
#
#   tools/loop/framecheck.sh <baseline_dir>
#
# Iteration 6 proved a whole-frame threshold cannot tell a one-character label change
# (0.376%) from the Workshop's breathing bob (0.291%). Rather than guess, this
# reports UNVERIFIABLE for any screen that cannot hold still.
#
# The unstable set is MEASURED every run, never hardcoded: the Barrow drifts at
# ~0.084% from a source that is not one of the three known Time.get_ticks_msec()
# seams, so a hand-written list would have been wrong from the start and would rot.
#
#   noise[s]  = the WORST difference across three consecutive renders of the CURRENT
#               code. Three, not two: the Barrow's drift is intermittent, and a
#               single pair measured it at 0.000% and then reported a 0.070% delta
#               as DIFFERENT when nothing had changed. One sample is not a floor.
#   delta[s]  = difference between the baseline and the current render
#
#   noise == 0 : the screen is deterministic, so the verdict is exact.
#                delta == 0 -> SAME, otherwise DIFFERENT.
#   noise  > 0 : never SAME. DIFFERENT only when delta clears noise by 3x, which is
#                a claim the measurement supports; otherwise UNVERIFIABLE.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"; cd "$ROOT"
BASE="${1:-}"
[ -d "$BASE" ] || { echo "usage: framecheck.sh <baseline_dir>"; exit 2; }
ENGINE="$(bash tools/loop/bootstrap.sh 2>/dev/null | sed -n 's/^ENGINE=//p')"
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/r1" "$WORK/r2" "$WORK/r3"

for r in r1 r2 r3; do
  bash tools/loop/shots.sh >/dev/null 2>&1; cp loop/out/shots/*.png "$WORK/$r/"
done

pcts() { "$ENGINE" --headless --path . -s res://tools/loop/framediff.gd -- "$1" "$2" 2>/dev/null \
         | sed -n 's/^  \(shot_[a-z_]*\.png\) *\([0-9.]*\)% pixels changed$/\1 \2/p'; }

{ pcts "$WORK/r1" "$WORK/r2"; pcts "$WORK/r1" "$WORK/r3"; pcts "$WORK/r2" "$WORK/r3"; } > "$WORK/noise.txt"
pcts "$BASE" "$WORK/r1" > "$WORK/delta.txt"

python3 - "$WORK/noise.txt" "$WORK/delta.txt" <<'PY'
import sys
def load(p):
    # keep the WORST reading per screen - the noise file holds three pairings
    d={}
    for line in open(p):
        parts=line.split()
        if len(parts)==2:
            d[parts[0]]=max(d.get(parts[0],0.0), float(parts[1]))
    return d
noise, delta = load(sys.argv[1]), load(sys.argv[2])
if not delta:
    print("FRAMECHECK FAIL: no comparable screens"); sys.exit(1)
verdicts={}
print("%-24s %8s %8s   %s" % ("SCREEN","noise","delta","VERDICT"))
for s in sorted(delta):
    n=noise.get(s,0.0); d=delta[s]
    if n == 0.0:
        v = "SAME" if d == 0.0 else "DIFFERENT"
    elif d > n*3.0:
        v = "DIFFERENT"
    else:
        v = "UNVERIFIABLE"          # never SAME: the screen cannot hold still
    verdicts[s]=v
    print("%-24s %7.3f%% %7.3f%%   %s" % (s,n,d,v))
diff=[s for s,v in verdicts.items() if v=="DIFFERENT"]
unk =[s for s,v in verdicts.items() if v=="UNVERIFIABLE"]
print()
print("changed: %d   unverifiable: %d   same: %d" % (len(diff),len(unk),len(verdicts)-len(diff)-len(unk)))
if unk: print("NOTE: %d screen(s) cannot be verified automatically - look at them." % len(unk))
sys.exit(1 if diff else 0)
PY
