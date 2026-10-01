#!/usr/bin/env bash
# MANABIT autonomous loop - phase 0b / phase 4 L1: the gate suite, run for real.
#
#   tools/loop/gates.sh          # 16 gates (the full suite - all of them are fast)
#   tools/loop/gates.sh --fast   # 14 fast gates, skips the two sim tripwires
#   tools/loop/gates.sh smoke_run smoke_kit   # named subset
#
# Writes a machine-readable report to loop/out/gates.json and prints a table.
# Exit 0 only if EVERY gate ran and passed. A gate that times out, crashes, or
# prints no verdict is a FAIL - silence is never green (see the AUDIO LESSON in
# CLAUDE.md: a seam can pass an existence check and still no-op).
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
ENGINE="$(bash tools/loop/bootstrap.sh 2>/dev/null | sed -n 's/^ENGINE=//p')"
[ -x "$ENGINE" ] || { echo "gates: no engine"; exit 2; }

FAST=(smoke_contract smoke_builder smoke_persist smoke_broker smoke_combat
      smoke_bout smoke_run smoke_catalog smoke_kit smoke_layout smoke_stage
      smoke_beats smoke_audio smoke_art)
SIM=(smoke_kit_sim smoke_stalemate)

case "${1:-}" in
  --fast) GATES=("${FAST[@]}") ;;
  "")     GATES=("${FAST[@]}" "${SIM[@]}") ;;
  *)      GATES=("$@") ;;
esac

mkdir -p loop/out
JSON="loop/out/gates.json"
: > "$JSON.tmp"
fails=0; total=0
printf "%-18s %-5s %-7s %s\n" GATE RC TIME VERDICT
for g in "${GATES[@]}"; do
  total=$((total+1))
  s=$(date +%s%3N)
  out=$(timeout 900 "$ENGINE" --headless --path . -s "res://tests/$g.gd" 2>&1); rc=$?
  e=$(date +%s%3N); ms=$((e-s))
  verdict=$(printf '%s' "$out" | grep -Eio "SMOKE (PASS|FAIL)|ART AUDIT (PASS|FAIL)" | tail -1)
  # A pass requires BOTH a zero exit AND an explicit printed PASS verdict.
  if [ $rc -eq 0 ] && printf '%s' "$verdict" | grep -qi PASS; then
    status=PASS
  else
    status=FAIL; fails=$((fails+1))
    printf '%s\n' "$out" | tail -30 > "loop/out/fail_$g.log"
  fi
  printf "%-18s %-5s %-7s %s\n" "$g" "$rc" "${ms}ms" "${verdict:-<no verdict>} [$status]"
  printf '{"gate":"%s","rc":%d,"ms":%d,"status":"%s","verdict":"%s"}\n' \
    "$g" "$rc" "$ms" "$status" "${verdict:-none}" >> "$JSON.tmp"
done

python3 - "$JSON.tmp" "$JSON" "$total" "$fails" <<'PY'
import json,sys,datetime
rows=[json.loads(l) for l in open(sys.argv[1]) if l.strip()]
json.dump({"ts":datetime.datetime.now(datetime.timezone.utc).isoformat(),
           "total":int(sys.argv[3]),"failed":int(sys.argv[4]),
           "green":int(sys.argv[4])==0,"gates":rows},
          open(sys.argv[2],"w"),indent=1)
PY
rm -f "$JSON.tmp"

echo
if [ $fails -eq 0 ]; then echo "ALL GREEN ($total/$total) -> $JSON"; exit 0; fi
echo "RED: $fails/$total failed (logs in loop/out/fail_*.log) -> $JSON"; exit 1
