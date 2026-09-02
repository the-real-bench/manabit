#!/usr/bin/env bash
# MANABIT autonomous loop - the delivery check.
#
#   tools/loop/verdict.sh start    # at Phase 0, records the branch head
#   tools/loop/verdict.sh check    # at Phase 7, proves the run delivered something
#   tools/loop/verdict.sh blocked "cmd" "error text"   # record a real blocker
#
# WHY THIS EXISTS (Incident 1, 2026-09-01): two unattended runs exited
# ROUTINE_RUN_STATUS_SUCCEEDED having pushed nothing - 19 minutes and $2.61, then
# 73 seconds and $0.45. A scheduler's status field cannot tell "did the work" from
# "exited cleanly", so nothing noticed. It was caught only because a human-driven
# session happened to fetch the branch.
#
# An iteration has exactly two honest endings: a new commit, or a BLOCKED report
# naming the exact command and its exact error. This script refuses the third one.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
mkdir -p loop/out
STATE="loop/out/iteration_start"
BLOCKED="loop/out/BLOCKED"

case "${1:-check}" in

  start)
    git rev-parse HEAD > "$STATE"
    rm -f "$BLOCKED"
    echo "verdict: iteration starts at $(cat "$STATE")"
    ;;

  blocked)
    # A blocker is only a real outcome if it names what was tried and what happened.
    cmd="${2:-}"; err="${3:-}"
    if [ -z "$cmd" ] || [ -z "$err" ]; then
      echo "verdict: a BLOCKED report needs both the command and its error." >&2
      echo "  usage: tools/loop/verdict.sh blocked '<command>' '<exact error>'" >&2
      exit 2
    fi
    { echo "BLOCKED at $(date -u +%FT%TZ)"; echo "command: $cmd"; echo "error: $err"; } > "$BLOCKED"
    echo "verdict: blocker recorded -> $BLOCKED"
    ;;

  check)
    if [ -f "$STATE" ]; then
      start="$(cat "$STATE")"
    else
      # No Phase-0 baseline: fall back to the remote-tracking ref. check runs BEFORE
      # push, so commits ahead of origin are exactly this run's delivery. This keeps a
      # session that forgot `start` - or a fresh container with no loop/out/ - from
      # being told it delivered nothing when it plainly did. Found the honest way:
      # this check failed at the real Phase 7 of the iteration that built it.
      br="$(git rev-parse --abbrev-ref HEAD)"
      if start="$(git rev-parse --verify -q "origin/$br")"; then
        echo "verdict: no Phase-0 baseline, comparing against origin/$br" >&2
      else
        echo "VERDICT: FAIL - no iteration start recorded and no origin/$br to fall back to." >&2
        echo "  Run 'tools/loop/verdict.sh start' at Phase 0." >&2
        exit 1
      fi
    fi
    head="$(git rev-parse HEAD)"
    n=$(git rev-list --count "$start..$head" 2>/dev/null || echo 0)

    if [ "$n" -gt 0 ]; then
      # Delivery is necessary, not sufficient. Iteration 9 pushed 81f33c0 carrying a
      # tool whose ledger entry never got written: the Python block that writes it
      # died and the shell had no `set -e`, so the commit and push ran anyway. This
      # guard passed it, correctly - a commit existed. So the guard now also checks
      # that the bookkeeping actually happened.
      local_fail=0

      # (1) No placeholder left behind. Match the LITERAL placeholder line, not any
      #     mention of the word - the first version matched this file's own prose
      #     describing the rule, so every future entry that explained it would have
      #     failed the gate. An assertion that fires on its own documentation is
      #     worse than none.
      if grep -qF "*(pending - filled in at Phase 5)*" loop/ledger.md 2>/dev/null; then
        echo "VERDICT: FAIL - loop/ledger.md still has an unfilled Result placeholder." >&2
        grep -nF "*(pending - filled in at Phase 5)*" loop/ledger.md | head -3 >&2
        echo "  The iteration produced commits but its Result was never filled in." >&2
        local_fail=1
      fi

      # (2) Code without a record is the 81f33c0 shape exactly.
      if ! git diff --name-only "$start..$head" | grep -q "^loop/ledger.md$"; then
        echo "VERDICT: FAIL - $n commit(s) delivered but none touched loop/ledger.md." >&2
        echo "  Every iteration records what it did and why. A change with no entry is" >&2
        echo "  unreviewable later, and it is how the record silently drifts from the code." >&2
        local_fail=1
      fi

      if [ "$local_fail" -ne 0 ]; then
        echo "  Fix the record, amend or add a commit, then re-run this check." >&2
        exit 1
      fi

      echo "VERDICT: DELIVERED - $n new commit(s) since $start"
      git --no-pager log --oneline "$start..$head"
      exit 0
    fi

    if [ -s "$BLOCKED" ]; then
      echo "VERDICT: BLOCKED - no commit, but the blocker is reported:"
      sed 's/^/  /' "$BLOCKED"
      exit 0
    fi

    # The third ending, refused.
    echo "VERDICT: FAIL - this iteration delivered NOTHING." >&2
    echo "  head is still $start: no commit was made, and no BLOCKED report was" >&2
    echo "  written. 'I looked at it and things seemed fine' is not an outcome." >&2
    echo "  Either commit the work, or run:" >&2
    echo "    tools/loop/verdict.sh blocked '<command>' '<exact error>'" >&2
    exit 1
    ;;

  *)
    echo "usage: verdict.sh {start|check|blocked <cmd> <error>}" >&2; exit 2 ;;
esac
