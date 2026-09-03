# THE AUTONOMOUS LOOP

*How MANABIT builds itself between owner sessions. Ratified 2026-09-01.*

The studio was never short of capability. Fourteen gates, three sim instruments, a
49-agent scaffold and a measured 11-defect playtest all existed before this document.
What was missing was a way to close the loop without the owner standing in it. This
document is that closure.

---

## 1. What actually blocked autonomy (and what changed)

| The old block | Why it stopped the loop | What replaced it |
|---|---|---|
| **Verification lived on the owner's PC.** Godot was at `G:\Godot`, the project synced by Syncthing, and windowed runs needed a monitor. | "Green" was a claim relayed from a machine no session could reach. The wave-4b silent-audio bug is the proof: every gate was green and the headline layer would have shipped mute. | `tools/loop/bootstrap.sh` fetches and caches Godot 4.7 in the container. **All 16 gates run here in 65 seconds.** |
| **Nothing visual could be checked.** Headless Godot draws nothing, so beauty, fit, contrast and clipping were owner-only judgments. | Every taste question blocked the entire loop, not just itself. | `tools/loop/shots.sh` renders the game under Xvfb with software GL. **The loop can look at the screens it built.** |
| **Priorities lived in prose.** An excellent playtest produced R1-R7 and D1-D11 in markdown that no process consumed. | Routing work was a human act. With the human away the loop had nothing to pick from and drifted toward whatever was most recently discussed. | `loop/backlog.json` - scored, sorted, machine-picked. |
| **"Fun" had no operational definition.** Gates proved correctness only. | The loop could stay green for months while getting less enjoyable. Correctness is not the product. | `design/process/fun-rubric.md` - four persona lenses with scores, plus seven principles derived from this game's own measured defects. |
| **Owner-gated work blocked everything behind it.** | One frozen-contract question stalled the queue. | `loop/owner-queue.md`. Escalation is a *write*, never a *wait*. The loop takes the next item and keeps moving. |

**The honest limit, stated up front:** the loop can see and it can measure, but it
cannot hear (no audio device; audio is verified structurally and by waveform, never
by ear) and it cannot *feel* (AI persona judgment is a proxy for playtesting, not a
substitute). Taste-final calls and section 13 changes stay the owner's. The loop's
job is to arrive at those with the evidence already assembled.

---

## 2. One iteration

Seven phases. Skipping one is how a loop turns into a ratchet of accumulated
regressions.

### Phase 0 - SYNC
```bash
bash tools/loop/bootstrap.sh     # engine, cached
bash tools/loop/verdict.sh start # record the head, so a no-op cannot hide
bash tools/loop/gates.sh         # 16/16, ~65s
```
Establish a **green baseline before touching anything**. If the baseline is red,
the only permitted work this iteration is making it green. No feature work rides
on an unknown starting state.

**Then RECONCILE, before picking anything.** Scan for work that has already landed:

```bash
ls design/balance/*change-order*.md design/*/*.md   # what the studio already answered
git log --oneline -30
```

A backlog item records a defect that was true when it was written. **Evidence
expires.** Re-verify in code that the defect is still live before picking it, and
close it against the change that fixed it if it is not.

> **This rule is written against this backlog's own first draft.** It scored six
> items as live work, and every one of them had already been fixed and measured by
> `design/balance/playtest-fixes-change-order.md` weeks earlier. The miss was
> narrow and specific: the session read the *problem* statement (the playtest
> panel) and never read the *response* to it. Two full iterations would have
> re-implemented shipped work and reported progress for it. Reading the defect list
> is not reconciliation; reading what was done about it is.

### Phase 1 - PICK
Take the highest-`priority` item from `loop/backlog.json` whose `gate` is `loop`.
**Exactly one headline item per iteration.** The scoring is
`lift * evidence / (cost * risk)`; the definitions live in the file's `_scoring`
block.

Three laws govern picking:

- **The staleness law.** No item is picked until its defect is re-verified as still
  live in code. Not in a doc - in code.
- **The evidence law.** An item with `evidence < 2` may not be built, only
  *measured*. Build the instrument, rescore, then build the change. This is the
  rule that would have stopped wave 1 shipping two changes that moved the wrong way.
- **The risk law.** `risk: 5` is never picked. It is mirrored to the owner queue.
  Frozen surfaces: the section 13 contract, `combat.gd` resolution semantics, the
  save schema, and the 13 hardcoded base fixtures.

### Phase 2 - PRE-STATE
Write the success criterion into the ledger entry **before writing any code**, as a
number or as a fact visible in a rendered frame. Stating it afterwards is how a loop
rationalises whatever it happened to produce.

A criterion must be falsifiable and must name its instrument. "Pindrop reaches a
DEATH rate inside the 24/60-to-30/60 elite band, measured by `qa_verify.gd`" is a
criterion. "Pindrop feels more threatening" is not.

### Phase 3 - BUILD
Smallest diff that satisfies the criterion. Do not widen scope mid-iteration; a
discovery becomes a new backlog item, not a bigger commit.

### Phase 4 - PROVE (three layers, all required)
- **L1 gates.** `tools/loop/gates.sh`. 16/16 or the iteration is not done.
- **L2 measurement.** Re-run the instrument named in the criterion. Compare against
  the number written in Phase 2, not against a number invented now.
- **L3 senses.** Anything visible gets `tools/loop/shots.sh` and an actual look at
  the frame. Anything audible gets a manifest-resolution audit plus a live windowed
  probe.

> **The silence rule.** A seam that *can* be silent must be probed live, never
> inferred from existence. Gate-green is not audible, and it is not visible either.
> This rule is written in blood: eight audio loops passed every existence check
> while loading null.

### Phase 5 - JUDGE
Criterion met -> keep. Criterion missed or moved the wrong way -> **revert, and
record why.** A reverted iteration that produced a real measurement is a successful
iteration. Never lower a criterion after seeing the result.

### Phase 6 - RECORD
- Append to `loop/ledger.md`: what was picked, the criterion, the measured result,
  kept or reverted, and what the next iteration should know.
- Rescore `loop/backlog.json`; add anything discovered.
- Append any owner-gated finding to `loop/owner-queue.md`.
- Prepend a session entry to `workbench.md` (existing project law: never rewrite,
  only prepend).

### Phase 7 - PUSH
```bash
bash tools/loop/verdict.sh check   # refuses an iteration that delivered nothing,
                                   # OR delivered code with no record
```
It enforces three things, not one: a commit exists (or a BLOCKED report does), the
ledger carries no unfilled Result placeholder, and at least one delivered commit
touched `loop/ledger.md`.

> **Why the second and third exist.** Iteration 9 pushed a tool whose ledger entry
> never got written - the block that writes it died, and the surrounding shell had no
> `set -e`, so the commit and push ran anyway. The guard passed it, correctly: a
> commit existed. Delivery is necessary, not sufficient. Code that ships with no
> record is unreviewable later and is how the record silently drifts from the code.
Commit with the item id in the subject, push to the working branch, keep the PR
updated. CI re-runs the same `gates.sh` on GitHub so no claim of green depends on
the session that made it.

---

## 2b. Verify the loop can DELIVER before trusting it to run

Before scheduling anything, prove the runner can push. Not that it can think, or run
gates, or render frames - that it can land a commit on the branch.

> **Written against Incident 1.** The first two unattended runs exited
> `SUCCEEDED` having pushed nothing: 19 minutes and $2.61, then 73 seconds and $0.45.
> "Succeeded" meant the session exited without crashing. Nothing in the system
> noticed, because a scheduler's status field cannot tell "did the work" from "exited
> cleanly". It was caught only because a human-driven session happened to fetch the
> branch.

Two rules follow:

1. **The delivery path is tested first, before the engine, the gates, or the
   backlog.** A run that cannot push should discover that in seconds and say so, not
   after twenty minutes of work it is about to throw away.
2. **Every run ends in one of exactly two states, and says which:** a pushed SHA, or
   a BLOCKED report naming the exact command and its exact error. This is enforced,
   not merely asked for: `tools/loop/verdict.sh` records the head at Phase 0 and
   refuses the run at Phase 7 if neither a commit nor a `blocked` report exists. "Everything was
   already green" is not an outcome. If the backlog is empty, build the next
   instrument and push that.

A scheduler that reports success while producing nothing is strictly worse than no
scheduler: it manufactures false confidence. That is the wave-4b audio bug one layer
up - a green light with nothing behind it.

---

## 3. Standing rules

1. **Never trust a lane's green.** The coordinating session re-runs the gates itself.
   This is existing project law and it survives contact with automation.
2. **Never skip, disable or quarantine a gate to get green.** If a gate is wrong,
   fix the gate deliberately as its own item and say so in the ledger.
3. **Never claim a state you did not observe this session.**
4. **One headline item per iteration.** Depth over breadth; the ledger is the record
   that depth actually happened.
5. **A gate that goes red and cannot be fixed inside the iteration** means revert to
   the last green commit and log the failure. Do not leave the branch red overnight.
6. **Escalate by writing, never by waiting.**
7. **New capability earns a new gate.** Anything that could regress silently gets an
   assertion the same day, and the assertion must fail when the thing is broken -
   verify that it does by breaking it once.

---

## 4. What still needs the owner

Kept current in `loop/owner-queue.md`. Four standing categories:

- **Section 13 contract changes** - the turn cap (D13) and the speed axis (D11) both
  need ADRs. The resolver is frozen by design and the loop does not get to unfreeze it.
- **Save schema changes** - coffer RNG persistence and the Glimmer sink both need v5.
- **Final taste calls** - the loop can now *see*, which makes it a competent reviewer
  and still not the author of the game's look. Direction gets signed, not inferred.
- **Anything needing hardware the container lacks** - Blender rigs, and ears.

The loop's obligation to that queue is to arrive with the case already built:
the measurement, the options, and a recommendation.

---

## 5. Running it

```bash
bash tools/loop/bootstrap.sh          # engine + import (idempotent)
bash tools/loop/gates.sh              # 16 gates -> loop/out/gates.json
bash tools/loop/gates.sh --fast       # 14 gates, skips the sim tripwires
bash tools/loop/shots.sh              # 6 screens -> loop/out/shots/
bash tools/loop/shots.sh shoot_kit    # any tests/shoot_*.gd harness
```

`shots.sh` backs up and restores `user://manabit_save.json` around every run,
because a windowed harness boots the real game. That used to be a thing a human
remembered. Now it is a thing the script cannot forget.

On the owner's Windows checkout the same gates run through the console exe:
`& "G:\Godot\Godot_v4.7-stable_win64_console.exe" --headless --path . -s "res://tests/<gate>.gd"`.

The protocol is invocable as a skill: `.claude/skills/loop-iteration/`.
