---
name: loop-iteration
description: "Run one autonomous MANABIT build iteration end to end: establish a green baseline, pick the top-scored backlog item, pre-state a falsifiable criterion, build the smallest diff, prove it across gates plus measurement plus rendered frames, judge keep-or-revert, and record. Use when continuing MANABIT unattended, when asked to 'run the loop' or 'do the next iteration', or when picking up the project with no owner present."
argument-hint: "[item id, e.g. L-02 | blank to pick the top item]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash
agent: producer
---

# One Autonomous Iteration

Full protocol: `design/process/autonomous-loop.md`.
Enjoyment instrument: `design/process/fun-rubric.md`.

Do not improvise the order. Each phase exists because skipping it has already cost
this project something specific.

## Phase 0 - SYNC
```bash
bash tools/loop/bootstrap.sh
bash tools/loop/gates.sh
```
Green baseline first. **If red, fixing it is the whole iteration.** Never start
feature work from an unknown state.

## Phase 1 - PICK
Read `loop/backlog.json`. Take the highest `priority` with `gate: "loop"` (or the id
in the argument). **One headline item.**
- `evidence < 2` -> you may only MEASURE it, not build against it. Build the
  instrument, rescore, stop.
- `risk: 5` -> never pick. Mirror to `loop/owner-queue.md` and take the next item.
- Frozen and off limits: section 13, `combat.gd` resolution, the save schema, the 13
  hardcoded base fixtures.

## Phase 2 - PRE-STATE
Write the criterion into `loop/ledger.md` **before any code**. It must be a number or
a fact visible in a rendered frame, it must name its instrument, and it must name the
persona lens it moves. Stating it afterwards is rationalisation.

## Phase 3 - BUILD
Smallest diff that satisfies the criterion. Discoveries become new backlog items, not
a wider commit.

## Phase 4 - PROVE (all three layers)
1. `bash tools/loop/gates.sh` - 16/16.
2. Re-run the instrument named in Phase 2. Compare to the number written then.
3. `bash tools/loop/shots.sh` and **actually look at the frames** for anything
   visible. For anything audible: audit manifest resolution AND run a live windowed
   probe.

**The silence rule:** a seam that can be silent must be probed live, never inferred
from existence. Eight audio loops once passed every check while loading null.

## Phase 5 - JUDGE
Met -> keep. Missed or wrong-way -> **revert and record why.** Never lower a
criterion after seeing the result. A revert with a real measurement is a success.

## Phase 6 - RECORD
`loop/ledger.md` (result + what the next iteration should know), rescore
`loop/backlog.json`, append to `loop/owner-queue.md` if anything is owner-gated,
prepend to `workbench.md`.

## Phase 7 - PUSH
Commit with the item id in the subject. Push to the working branch. Keep the PR
updated. CI re-runs the same gates so no green depends on this session.

## Never
Skip or disable a gate to get green. Claim a state you did not observe. Trust a
lane's green without re-running it. Leave the branch red. Wait on the owner when you
could write to the queue and take the next item.
