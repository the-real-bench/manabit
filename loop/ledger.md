# LOOP LEDGER

Append-only. Newest at top. One entry per iteration: what was picked, the criterion
**stated before building**, the measured result, and kept-or-reverted.

A reverted iteration that produced a real measurement is a successful iteration.
Never rewrite an entry.

---

## Iteration 13 - 2026-09-03 - RECONCILE blocked L-21, and caught a hole in iteration 12

**Picked:** L-21 (3.0). **Blocked at reconcile, and the reason invalidates part of the
finding that created it.**

**What reconcile found.** Before touching a single leg stat I listed the legs roster
against its measured deltas. Three of seventeen legs bits came back `nan` -
`larkabout_skyworks_legs_rocketboot`, `larkabout_skyworks_legs_contrail`,
`steadfast_gallant_legs_gantry`. They are wave-2 Hero Shelf bits, added AFTER
`roster-post.json` was generated. Checked across the whole catalog:

    HEAD   18 bits,  4 with NO measured delta
    ARM_L  18 bits,  4
    ARM_R  19 bits,  5
    LEGS   17 bits,  3
    BACK   17 bits,  3
    TOTAL: 19 of 89 non-core bits unmeasured - 21% of the roster

**My probe silently scored every one of them as 0.0.** `deltas.get(id, 0.0)` - a
default that turns "never measured" into "worth nothing" without a word. So
iteration 12's headline numbers were computed with a fifth of the candidates
artificially valued at zero, and I published them yesterday as measurement.

**This is the fifth silent-failure shape this session, and the first one I shipped as
a finding rather than as a bug.** The others were gates and guards that failed
loudly enough to catch. This one produced plausible numbers.

**Whether the LEGS conclusion survives is genuinely open.** Bedrock measures +0.34
against a next-best +0.1198, a 2.8x gap - but one of the three unmeasured legs is
`steadfast_gallant_legs_gantry` (hp 22, def 4, weight 30), a tank leg in Bedrock's own
register and lighter than it. It could plausibly be competitive. LEGS=1 cannot be
trusted until it is measured.

**Re-measurement turned out to be cheap.** `tools/sim/sim_roster.gd` is the real
instrument - 5 templates, 30 seeded opponent variants, deterministic resolver - and it
completes in **112 seconds**: 67,410 fights, ROSTER SIM PASS. There was never a reason
to run on stale data except that nothing checked.

**CRITERION (stated before writing any code):**
1. The probe REFUSES to silently default. Any bit with no measured delta is reported,
   not scored as zero, and the run prints its coverage.
2. Decision density is recomputed against the FRESH full-coverage roster data.
3. The LEGS=1 claim from iteration 12 is re-tested and the ledger states plainly
   whether it survived, whichever way it falls.
4. L-21 is either confirmed on good evidence or withdrawn - no leg stat is touched
   this iteration, because the item that justified touching them is now in doubt.
5. 16/16 gates green.

**Revert trigger:** the fresh data cannot be produced or the probe cannot distinguish
"unmeasured" from "measured at zero".

**Result:** *(pending - filled in at Phase 5)*

---

## Iteration 12 - 2026-09-03 - L-10, the last thing the loop can reach alone

**Picked:** L-10 (1.5), the only live item left. Gate `measure`, evidence 1 - so under
the evidence law it may only be MEASURED, and building the instrument IS the
sanctioned action.

**What it is for.** The Optimizer scores 5/10 because "the legal build collapses to
one greedy answer identical across every core" and "the soul pick is nearly
cosmetic". Those are the loudest enjoyment claims in the playtest and the only
headline ones that are still *reasoned* rather than measured. Every other claim in
this loop's history that was reasoned rather than measured has been wrong at least in
part - three of them mine. This item exists so that one is not built against on faith
either way.

**The value signal, and its honest limit.** `tools/sim/out/roster-post.json` carries a
measured `mean_delta` per bit - each bit's contribution to win rate over 480-600
fights. That is real data, not an invented heuristic. **But it was measured in
ISOLATION**, one bit swapped into a baseline at a time, so summing six of them is an
ADDITIVE APPROXIMATION that ignores every interaction between parts. The probe
therefore measures build diversity *under an additive model*, not under true play.
That limitation goes in the output itself, not just this ledger, so no future reader
mistakes the number for a play-tested one.

It is still decisive in one direction: if even an additive model over 100 bits and
five free slots collapses to a handful of near-optimal builds, the claim is
supported. If it does not collapse, the claim is weakened and needs the real thing.

**CRITERION (stated before writing any code):**
1. A committed probe reports, per core: the optimal additive build under that core's
   weight capacity, and **how many distinct bits appear in ANY build within 5% of
   optimal, per slot**. A slot whose count is 1 is a formality, not a decision.
2. It states its own additive limitation in its printed output.
3. It runs over the real catalog through `Catalog.all()` and the real capacity rule
   (100 + seated core carry), not a reimplementation of either.
4. The finding is recorded whichever way it falls - a refutation of the Optimizer's
   claim is as publishable as a confirmation.
5. 16/16 gates green.

**Revert trigger:** the probe cannot reach the real catalog or the real capacity rule
and would have to approximate them - in which case it measures a fiction and should
not ship.

**Result: KEPT. Probe shipped, and it splits the Optimizer's claim in two.**

    CORE                    CAP    BEST   distinct near-optimal bits per slot
    Ember Core              100   0.731   HEAD:3 ARM:8 ARM:8 LEGS:1 BACK:7
    Bulwark Core            106   0.766   HEAD:3 ARM:8 ARM:8 LEGS:1 BACK:8
    Keystone Core           110   0.791   HEAD:2 ARM:8 ARM:8 LEGS:1 BACK:7
    Steadfast No.7 Gallant  112   0.794   HEAD:3 ARM:10 ARM:10 LEGS:1 BACK:8
    ... (11 cores, all measured)

    slots offering NO choice at 5% tolerance: 11 of 55 - and all 11 are LEGS

**"The legal build collapses to one greedy answer" is REFUTED for four slots of five.**
Arms carry 7 to 10 viable bits each, Back 5 to 8, Head 2 to 3. That is a real
decision space, not a formality. The Optimizer's headline claim, taken literally,
does not survive measurement.

**It is CONFIRMED, completely, for LEGS.** One answer, on every core, without
exception. This corroborates the playtest's separate observation that Bedrock Legs
measures +0.34, "3 to 5x every other legs bit". The general claim was wrong; the
specific slot it was probably built from is exactly right.

**"Identical across every core" is weakened.** The near-optimal sets do shift with the
core - Head 2 vs 3, Arms 7 to 10, Back 5 to 8 - though modestly.

**"The soul pick is nearly cosmetic" is quantified, not settled.** Achievable optimum
ranges 0.731 (Ember, Font, Quickstart) to 0.794 (Gallant), an 8.6% spread. Cores are
not cosmetic, but the ceiling they buy differs by under 9%.

**A bug the output caught, worth naming.** The first run printed 0 near-optimal bits
in every slot - impossible, since the optimal build must count itself. My backward DP
is indexed by REMAINING budget and the forward sweep passed CUMULATIVE weight. The
zeros made it obvious; a subtler indexing error would have printed plausible numbers
and been believed. I added a `push_error` for the empty case so a future silent zero
announces itself rather than reading as "the game has no choices".

**The limitation, restated because it bounds every number above.** Value is the
measured per-bit `mean_delta` from 480-600 real fights, but each bit was measured IN
ISOLATION, so summing six is an ADDITIVE APPROXIMATION with no interaction terms.
This is diversity under an additive model. It is decisive where it collapses - LEGS at
1 cannot be an artifact of ignoring synergies, since no synergy can make a
strictly-dominated bit competitive on its own axis - and only suggestive where it does
not.

**What this hands the owner.** A concrete, measured, un-blocked target: **LEGS is a
solved slot on every core.** Fixing it is loadout-level work inside
`parts/catalog_extra.json`, not section 13, and it is the one place where "more
decisions" has an unambiguous meaning. Filed as L-21.

**The backlog is now empty of loop-pickable items.**

---

## Iteration 11 - 2026-09-03 - L-19, and my own filed claim was wrong

**Picked:** L-19 (2.0), top live item.

**RECONCILE refuted the item as filed.** I wrote L-19 as "the gem is a hard-edged
rectangle" from a visual impression of a 34px element. Measured, the silhouette is
already tapered: 28 rows, **13 distinct row widths**, ramping 6, 14, 19, 24, 30, 33,
34. Not a rectangle. That is the third time an item of mine has been corrected by
measuring instead of trusting the impression that filed it.

**But something IS wrong, and the measurement names it.**

    gem value          0.451 .. 0.659   median 0.659   <- median EQUALS max
    surrounding brass  0.565 .. 0.914   median 0.655

Two findings in those numbers. The gem's median is its own maximum, so it is mostly a
flat plate with a thin darker fringe rather than a graded surface. And its median
luminance (0.659) is **indistinguishable from the brass it sits on** (0.655), so it
separates from its background by hue alone. At 34 pixels wide that reads as a sticker
laid on the lid, not a seal set into it.

**This is a consequence of my own iteration-8 fix.** I capped the gem at the mana
token's value of 0.66 to stop it out-shouting the screen. That solved the brightness
problem and created a flatness one: 0.66 happens to be exactly the brightness of the
surrounding brass. Fixing one axis without checking the neighbouring one.

**CRITERION (stated before touching a pixel):**
1. The gem's median value sits clearly BELOW the surrounding brass median, so it
   reads as recessed - an inset seal sits in shadow. A stated number, not "darker".
2. Its internal shading has a real gradient: median distinctly below its own max,
   not equal to it.
3. It still reads as a mana seal in a rendered frame - recessed, not a hole.
4. `smoke_art`'s palette gate stays green (hue 155-190, value <= 0.85) and 16/16.

**Revert trigger:** the frame reads worse than it does now, or the seal stops reading
as a seal. Per the item's own criterion: if the honest answer is that this needs real
art rather than a procedural tweak, say so and escalate rather than approximate.

**Result: KEPT. All four criteria met.**

    before   gem 0.451 .. 0.659   median 0.659  (= its own max, = brass 0.655)
    after    gem 0.282 .. 0.655   median 0.502  (brass median 0.655)

1. **Recessed.** Median 0.502 against brass 0.655 - a clear luminance step down, so
   the seal now sits in shadow instead of floating at exactly the brightness of the
   metal around it.
2. **Graded, not flat.** Median 0.502 is well below its own max 0.655, where before
   the two were identical.
3. **Still a seal in the frame.** Reviewed: dark under the upper lip, catching light
   on the lower one. Recessed, not a hole - the bottom edge is plainly teal.
4. **16/16 gates**, including the `smoke_art` palette check: hue held at exactly
   168 degrees and peak value 0.655, both inside the band iteration 8 established.

**The original facet detail was preserved, not discarded.** The old shading was
normalised to 0..1 and re-applied as a small modulation on top of the new gradient,
so the surface keeps its texture instead of becoming a clean ramp.

**What this iteration is really about.** L-19 was filed on an impression - "hard-edged
rectangle" - and the measurement refuted it: 28 rows, 13 distinct widths, already
tapered. The actual defect was invisible to the eye that filed the item and obvious in
two numbers: the gem's median equalled both its own max and the brass median. **And it
was my own doing** - iteration 8 capped the gem at the mana token's 0.66 to stop it
out-shouting the screen, which happens to be exactly the brightness of the brass.
Fixing brightness without checking the neighbouring axis.

Third item in this loop's history refuted by measuring rather than trusting the
impression that filed it. The pattern is consistent enough now to be a rule rather
than a coincidence: **an item filed from a look must be measured before it is built
against.**

**Next iteration picks:** L-10 (1.5) - the only live item left.

---

## Iteration 10 - 2026-09-02 - L-20, the guard that would have caught last iteration

**Picked:** L-20 (9.0), by a clear margin. This is the hole iteration 9 opened.

**RECONCILE:** `grep -n "ledger\|pending" tools/loop/verdict.sh` returns nothing.
The delivery guard has never looked at the bookkeeping at all. Defect live.

**A DELIBERATE CRITERION REFINEMENT, stated rather than slipped in.** The backlog
criterion I wrote in iteration 9 said: *"a record step that fails must stop the
iteration before the commit. Prove it by deliberately breaking the record step and
showing no commit is created."* I am changing where the check sits, and here is why.

Preventing the COMMIT means wrapping every record step in every future iteration in
strict error handling - a discipline that has to be remembered every time, which is
exactly the class of thing that failed last iteration. Checking at Phase 7 is ONE
place that cannot be forgotten, and it is the place that matters: a local commit is
cheap and amendable, while **the push is the harm**. 81f33c0 was not damaging because
it existed; it was damaging because it reached the remote and CI blessed it.

So the guard moves into `verdict.sh check`, which already runs at Phase 7 before
every push.

**CRITERION (stated before writing any code):**
1. `verdict.sh check` FAILS when the ledger's newest entry still contains a
   `(pending` placeholder.
2. `verdict.sh check` FAILS when an iteration delivered commits but none of them
   touched `loop/ledger.md` - code shipped with no record is the exact 81f33c0 shape.
3. Both are proven RED by deliberately reproducing each failure.
4. A BLOCKED report is still a valid outcome and must NOT be caught by either rule -
   a blocked run legitimately has no ledger entry.
5. 16/16 gates green.

**Revert trigger:** either new assertion cannot be made to fail, or rule 2 fires on a
legitimate BLOCKED run.

**Result: KEPT. All five criteria met, after the first version tripped on its own
documentation.**

`verdict.sh check` now enforces three things instead of one: a commit exists (or a
BLOCKED report does), the ledger carries no unfilled Result placeholder, and at least
one delivered commit touched `loop/ledger.md`.

**Four controls, all run:**

| Control | Expected | Actual |
|---|---|---|
| Real `(pending` placeholder in the ledger | FAIL | exit 1, names line 46 |
| Placeholder filled, prose about it still present | PASS | exit 0, no false positive |
| Commit delivered, ledger untouched | FAIL | exit 1, "1 commit(s) delivered but none touched loop/ledger.md" |
| BLOCKED run with no ledger entry | PASS | exit 0, blocker echoed |

**The first version was over-broad and I caught it in the control output.** It
grepped for the bare word `(pending`, which matched this ledger's own prose
describing the rule - line 35, not the real placeholder on line 46. Every future
entry that explained the rule would have failed the gate. **An assertion that fires
on its own documentation is worse than no assertion**, because it teaches people to
ignore it. Tightened to the literal placeholder string and re-proven both ways.

**The criterion was refined openly, not silently.** The backlog said "stop the
iteration before the commit". I moved the guard to Phase 7 instead, because
preventing the commit means remembering strict error handling in every future record
step - the exact discipline that failed in iteration 9 - whereas Phase 7 is one place
that cannot be forgotten. And the local commit was never the harm: 81f33c0 hurt
because it reached the remote and CI blessed it.

**What this closes.** Iteration 9's failure is now impossible to repeat silently: the
same shell sequence would abort at `verdict.sh check` before the push, with the
reason printed.

**Next iteration picks:** L-19 (2.0), then L-10 (1.5).

---

## Iteration 9 - 2026-09-02 - L-16, a tool that admits what it cannot see

**Picked:** L-16 (2.0), tied with L-19 (2.0). Broke the tie on LIFT (2 vs 1) rather
than cost, because this improves every future visual review while L-19 improves one
asset. Both stay inside the existing scoring - no override.

**RECONCILE.** The three wall-clock seams are still exactly where iteration 6 found
them (`chest_screen.gd:363`, `workshop.gd:650`, `manabit_stage.gd:194`). But the
Barrow also drifted at 0.084% and it is NOT in that list - its source was never
identified. That settles a design question: **the unstable set must be DERIVED by
measurement, not hardcoded.** A hand-maintained list of "animated screens" would have
been wrong the day it was written and would rot silently afterwards.

**CRITERION (stated before writing any code):**
1. The checker returns a PER-SCREEN verdict: SAME, DIFFERENT, or UNVERIFIABLE.
2. The unstable set is measured every run (render twice, no change between), never
   hardcoded.
3. A screen with a non-zero noise floor is NEVER reported SAME. That is the whole
   point: iteration 6 proved a threshold cannot tell a one-character edit from a
   breathing bob, so the honest answer there is "I cannot tell", not a guess.
4. Proven by controls: a one-character change on a ZERO-noise screen reports
   DIFFERENT; the same class of change on a noisy screen reports UNVERIFIABLE and
   never SAME.
5. 16/16 gates green.

**Revert trigger:** the checker reports SAME for any screen with non-zero measured
noise, or cannot detect a one-character change on a zero-noise screen.

**Result: KEPT. All five criteria met, after one real defect found by the controls.**

`tools/loop/framecheck.sh <baseline_dir>`:

    SCREEN                      noise    delta   VERDICT
    shot_barrow.png            0.063%   0.083%   UNVERIFIABLE
    shot_coffer_nook.png       0.066%   0.071%   UNVERIFIABLE
    shot_compendium.png        0.000%   0.000%   SAME
    shot_menagerie.png         0.000%   0.000%   SAME
    shot_proving.png           0.000%   0.000%   SAME
    shot_workshop.png          0.391%   0.778%   UNVERIFIABLE

**The defect the controls caught.** The first version measured each screen's noise
from ONE pair of renders. The Barrow's drift is INTERMITTENT: that pair read 0.000%,
so a 0.070% delta was reported DIFFERENT when nothing had changed - a false positive
on the very first control. One sample is not a floor. Fixed by rendering three times
and taking the worst of the three pairings.

**Three controls, all run:**
1. No change at all -> zero DIFFERENT. Three deterministic screens SAME, three noisy
   screens UNVERIFIABLE.
2. One-character change on Proving (zero noise) -> DIFFERENT at 2.023% against a
   0.000% floor.
3. One-character change on the Workshop (noisy) -> UNVERIFIABLE, never SAME. That is
   the honest answer: iteration 6 proved that edit is indistinguishable from the
   breathing bob.

**The unstable set is derived, not hardcoded** - necessary, since the Barrow drifts
and is not one of the three known `Time.get_ticks_msec()` seams.

**What this buys.** Half the screens get exact automated regression detection; the
other half are explicitly flagged for human eyes instead of silently passed. Strictly
better than byte-identity (iteration 3), which would fail closed on everything, and
than the threshold (iteration 6), which would fail OPEN on everything.

**A PROCESS FAILURE IN THIS ITERATION, recorded because it nearly corrupted the
record.** The Python block that was supposed to write this Result and close L-16 died
on a SyntaxError (an escaped quote inside a single-quoted string). The shell had no
`set -e`, so `git add -A && git commit && push` ran anyway. Commit 81f33c0 therefore
shipped the TOOL with the ledger still saying "pending" and L-16 still open - the
code and its record out of sync, pushed and CI-green.

`verdict.sh` passed it, correctly: a commit existed. The delivery guard proves
something was delivered, never that the bookkeeping was right. This is the fourth
silent-failure shape this session - after the tautological gate, the false-negative
verdict check, and the parse error that printed nothing in iteration 8 - and the
first one to reach the remote. Filed as L-20: the loop's own scripts should not
continue past a failed step.

**Next iteration picks:** L-20 (the process hole this just opened), then L-19, L-10.

---

## Iteration 8 - 2026-09-02 - L-08, the brightest thing on a warm screen

**Picked:** L-08 (2.0), tied with L-16 (2.0); took the cheaper (cost 1). Lens: Cozy
Collector. This was filed from a rendered frame in iteration 0 as a suspicion, with
its criterion set to MEASURE FIRST and not repaint on taste. This is that measurement.

**RECONCILE, including a correction I made mid-measurement.** My first pass sampled
every third pixel and reported the top eight colours: all warm, hues 33-39, no cool
anywhere. I nearly closed the item as "not a defect" on that. It was wrong - a small
region cannot reach a top-eight list. A full scan finds **779 cool pixels of 21,012
(3.7%)**, and the region is real:

    bbox x 70-103, y 49-76  (a 34x28 rectangle on the lid, image 224x168)
    dominant #7be1ff   hue 194   saturation 0.52   value 1.00

**Measured against DESIGN.md, which is the spec:**

    --affinity-mana      #3FA890   h 168   s 0.62   v 0.66
    Glimmer/stat-energy  #3FD0C0   h 172   s 0.70   v 0.82
    --affinity-def-text  #8FB4D9   h 210   s 0.34   v 0.85
    the coffer gem       #7be1ff   h 194   s 0.52   v 1.00   <- matches nothing

It is not a palette colour. Its hue falls between the teals and the def-blue,
matching neither, and its value is 1.00 - **brighter than every token in the
palette**, on a screen whose entire register is warm brass and wood. The project's
identity line is explicit: "etched-rune plastic, soft mana-glow - NOT
cyber-circuitry." A hard-edged, maximum-value sky-cyan rectangle is the opposite of
soft. `tools/art/` has no coffer recipe at all, so there is no documented intent to
weigh this against.

**The verdict is that this is a defect, not a preference** - it is off-spec against
the project's own written palette, not merely to my taste. A gem on the lid is
thematically right; its brightness and hue are what is wrong. So the fix preserves
the gem and brings it to a token.

**CRITERION (stated before touching a pixel):**
1. Every cool pixel in `coffer_face_brass.png` lands on a DESIGN.md palette token,
   with value no greater than the token's.
2. The gem is still visibly a gem in a rendered frame - recoloured, not deleted.
3. A gate asserts no coffer face contains an off-palette max-value cool pixel,
   **shown red against the current asset before the fix**.
4. 16/16 gates, `smoke_art` included.

**Revert trigger:** the recoloured gem stops reading as a gem in the frame, or the
new gate cannot be made to fail.

**Result: KEPT. All four criteria met.**

1. **On-palette.** All 779 cool pixels remapped onto `--affinity-mana #3FA890`, the
   mana-core glow tint, which is the thematic match for a seal you channel mana into.
   Internal shading preserved by scaling value proportionally rather than flattening,
   so it stays a faceted gem instead of becoming a sticker. Peak value 1.00 -> 0.66.
2. **Still a gem in the frame.** Rendered and reviewed: it now reads as a teal mana
   seal against brass, visible by HUE contrast rather than by out-shouting everything
   else on the screen.
3. **Gate proven both ways.** `smoke_art` gained a coffer-face palette check.
   Against the fixed asset: `[PASS] 0 off-palette cool pixels`. Against the original,
   restored on purpose: `[FAIL] coffer face brass: 779 off-palette cool pixels,
   first #91c9ff h209 v1.00 at 72,49`, `ART AUDIT FAIL`.
4. **16/16 gates green.**

**Two mistakes I made inside this iteration, both caught before they shipped:**
- My first colour sample read every third pixel and reported only the top eight
  colours, all warm. I nearly closed L-08 as "not a defect" on that. A 34x28 region
  in a 224x168 image cannot reach a top-eight list. A full scan found it.
- My first gate insertion used spaces in a tab-indented file and referenced `ok` when
  this test's accumulator is `proven`. It failed to parse, and the run printed
  nothing at all - which is exactly the silent-success shape this loop keeps having
  to catch. It was caught because the expected assertion lines were absent from the
  output, not because anything went red.

**Out of scope, noted not fixed:** the gem is still a hard-edged rectangle. That is a
SHAPE problem and it predates this change; the criterion was palette compliance.
Filed as L-19 at low priority rather than widened into here.

**Next iteration picks:** L-16 (2.0) or L-10 (1.5).

---

## Iteration 7 - 2026-09-02 - L-18 refuted at RECONCILE, and a sharper finding underneath

**Picked:** L-18 (3.0). **Closed as REFUTED before any code was written**, by the
Phase 0 reconcile step doing its job.

**What the reconcile found.** L-18 said the stake-10 tier is "a lottery: spoils range
8-45 for a fixed price". Before treating that as live I checked how the looted bit is
actually chosen. `ui/combat_screen.gd:1626-1638` builds **one button per non-core
bit** under the label `"Loot a part:"`. **The player chooses.** The range is a MENU,
not a draw. A rational player always takes the top, so the minimum is a number nobody
ever receives.

**This also corrects iteration 5's own framing, which I got wrong.** I reported the
gradient as ranges (8-8, 8-45, 45-45) and reasoned about floors and ceilings. Half of
that was noise: the floor is never taken. Recomputed by what a player actually
receives:

    stake  5   ->   8, 20, 8          COMMON / RARE
    stake 10   ->  45, 45, 20, 20     RARE / EPIC
    stake 20   ->  45, 45             EPIC / EPIC

Still monotonic non-decreasing, so the panel's "inverted gradient" stays refuted -
more cleanly than before, on the numbers that matter.

**THE REAL FINDING, which is sharper than the item it replaces.** Melt value is a
rarity proxy: 45 = EPIC, 20 = RARE, 8 = COMMON (`economy/broker.gd:9-13`). So the
reward TIER is:

    stake  5   COMMON or RARE
    stake 10   RARE or EPIC     <- already reaches the top rarity
    stake 20   EPIC or EPIC

**The reward ceiling is flat across the last stake step.** Cogsworth costs 10 and
yields an EPIC. Brassmore costs 20, is the measured wall (WIN 0.305 under optimal
play), and yields... an EPIC. Double the price and a far harder fight for the same
reward tier.

**Why this is not a tuning fix.** EPIC is the top rarity - there is nothing above it
to drop. Raising the boss ceiling needs a different reward AXIS (a larger purse, a
choice of two bits, a unique drop, a cosmetic), which is a design decision about what
the top of the ladder is FOR. That is not a number I get to pick. Escalated to the
owner queue as Q7 with the measurement attached.

**No code changed. That is the correct outcome here** - the defect was not real, and
the protocol's answer to "not still live" is to close it, not to build something
anyway to have shipped a diff. The instrument was corrected to print what is actually
taken, so the next reader is not misled the way I was.

**Next iteration picks:** L-08 (2.0) or L-16 (2.0).

---

## Iteration 6 - 2026-09-02 - L-16, the right criterion instead of the ambitious one

**Picked:** L-16 (3.0), tied with L-18 (3.0); broke the tie toward the instrument,
because L-18's own criterion says to state design intent before tuning and that is
owner territory, while this one is the loop's own tooling and fully in scope.

**Why this is a criterion change, not a retry.** Iteration 3 demanded byte-identical
frames and missed. The measured cause was wall-clock animation phase
(`chest_screen.gd:341`, `workshop.gd:650`, `manabit_stage.gd:194`, all sampling
`Time.get_ticks_msec()`). `Time.get_ticks_msec()` is engine-provided real elapsed
time - it cannot be frozen from a harness, and it does not follow frame count, so no
amount of fixed-timestep capture makes it repeat. The only way to byte-freeze it is
to put a test-only branch inside three shipped UI files, which is the tail wagging
the dog: changing how the game animates so a screenshot tool can diff cleanly.

The backlog entry written in iteration 3 anticipated exactly this and sanctioned the
fallback in advance: *"If no harness-side freeze is possible, the honest alternative
is to change the criterion to a perceptual threshold and say so explicitly."* This is
that, said explicitly. **Byte-identity is abandoned as the goal.** The PURPOSE was
never byte equality - it was trustworthy visual diffs. A comparator with a threshold
serves the purpose; byte-identity was an over-strict proxy for it.

**CRITERION (stated before writing any code):**
1. A frame comparator exists that reports SAME or DIFFERENT for two shot sets.
2. **Two consecutive unchanged runs compare SAME.**
3. **A real visual change is detected as DIFFERENT** - proven by making one on
   purpose, not asserted.
4. The threshold is DERIVED from the measured animation-only drift between two
   unchanged runs, with headroom stated as a number. It is not to be picked to make
   the test pass, and the measured drift goes in this ledger either way.
5. 16/16 gates green.

**Revert trigger:** the comparator cannot distinguish animation drift from a real
change - that is, the measured drift and a genuine edit overlap - in which case the
threshold approach is refuted and this gets reverted rather than tuned into
looking successful.

No PIL and no numpy in this container, so the comparator is written in GDScript and
run through the engine that is already a dependency, rather than adding one.

**Result: CRITERION 3 MISSED. The threshold approach is REFUTED by measurement. The
gate is reverted; only the instrument is kept.**

Measured animation-only drift between two unchanged runs:

    barrow 0.084%   coffer_nook 0.069%   workshop 0.291%
    compendium 0.000%   menagerie 0.000%   proving 0.000%

Then a deliberately small real change - `"THE LEDGER"` to `"THE LEDGERS"`, one
character - on the noisiest screen:

    workshop  0.376%   against 0.291% of animation noise

**They overlap.** A 1.0% threshold with sensible headroom would have called that
change SAME. My revert trigger named this exact outcome in advance.

**The rescue attempt also failed, and was measured rather than assumed.** The
hypothesis was that animation is low-amplitude and text is high-amplitude, so raising
the per-pixel cutoff would separate them:

    NOISE   animation-only   one-character change   ratio
       12       0.291%            0.376%            1.29x
       40       0.144%            0.195%            1.35x
       80       0.104%            0.137%            1.32x
      120       0.081%            0.109%            1.35x

Flat at ~1.3x. The hypothesis is wrong: the Workshop's breathing bob moves a 3D
model, so its drift is high-amplitude AND spread over a large area. A one-word label
is genuinely the same order of magnitude as the toy breathing.

**What was reverted:** the SAME/DIFFERENT verdict and the threshold. Shipping a gate
that silently cannot see a changed label on half the screens would be a
false-confidence machine - precisely the failure this apparatus exists to catch, and
the third time this session that shape has come up.

**What was kept, and why it is not the same thing smuggled through:**
`tools/loop/framediff.gd` stays as a MEASUREMENT instrument with the verdict removed
and the refutation table written into its header. It is what produced the numbers
above; instruments that disprove a plan have earned their place. It cannot be
mistaken for a gate because it no longer returns one.

**A real finding worth keeping:** the three static screens measure **0.000%** between
runs. Frame comparison is exact there. The problem is entirely confined to the three
screens with wall-clock animation.

**L-16 is not closed and its shape has changed.** Re-filed with the constraint proven
rather than suspected, and with the honest design the next attempt should take:
per-screen verdicts, where animated screens are reported UNVERIFIABLE rather than
SAME. A tool that admits what it cannot see is worth more than one that guesses.

**Next iteration picks:** L-18 (3.0) or L-08 (2.0). L-16 stays open at reduced
priority - the cheap version is refuted and the honest version costs more.

---

## Iteration 5 - 2026-09-02 - L-09, an informed wager needs both numbers

**Picked:** L-09 (priority 4.0), top live item. Lens: Optimizer + Newcomer.
Principle: P1 (a choice needs a legible difference) and P5 (reward must track
difficulty).

**A note on the scoring critique.** I told the owner this loop has been grinding
polish rather than the gameplay loop, proposed reweighting the scoring, and asked
for their word. **They have not answered, so this iteration runs under the existing
rules.** Acting on my own un-approved proposal would be exactly the quiet widening
the protocol forbids. On re-reading, L-09 is also less peripheral than I implied:
"wager" is one of the four core verbs, and the player currently cannot see what they
are wagering FOR.

**RECONCILE - defect confirmed live.** `ui/proving_screen.gd:163` builds
`"Spoils: " + " - ".join(loot)` from display names only. No value anywhere on the
row. The stake IS shown (`Stake: scrap N to enter`), so the player is asked to weigh
a number against a list of nouns. Not touched by CH-P1..P9 - a grep of the change
order for loot/spoil/stake finds nothing, consistent with the panel filing it under
R7, outside that pass's bounded scope.

**CRITERION (stated before writing any code):**
1. Every challenger row shows what the spoils are WORTH in scrap, alongside the
   stake, verified in a rendered frame.
2. The worth is DERIVED from `Broker.salvage_scrap`, never hand-typed, so it cannot
   drift from what the bit actually melts for.
3. A gate assertion proves the derivation, **shown red when worth and rule disagree**.
4. `smoke_layout` green and 16/16 gates. The Proving rows are already dense, so the
   worth must not push a row out of its budget.

**Revert trigger:** a row clips or overflows in a rendered frame, or the assertion
cannot be made to fail.

**Expected side effect, stated up front:** the panel measured the loot gradient
INVERTED (stake-10 Cogsworth loots a melt-45 EPIC; stake-20 Gildfall loots melt-20).
Surfacing worth will make that inversion VISIBLE rather than fix it. That is the
honest order of operations - you cannot balance a gradient the player cannot see -
but it means this iteration may make the game look worse before it is better. The
measured gradient will be filed as its own balance item rather than quietly patched
inside a UI change.

**Result: KEPT. All four criteria met - and the expected side effect did not happen,
because the claim behind it was wrong.**

1. **Worth on every row, verified in frame.** Each Spoils line now ends
   `(melts for scrap N)` or `(melts for scrap N-M)`. The range, not a total: you loot
   exactly ONE bit on a win, so a sum would advertise money the player never receives.
2. **Derived** from `Broker.salvage_scrap`, the same rule the Melt pays out.
3. **The gate is genuinely independent, and was seen red.** It does not restate the
   display call - it melts a real `PartInstance` through `PlayerState.melt_bit` and
   compares the scrap actually received. Negative control: make the payout pay 3 less
   than advertised -> `[FAIL] spoils worth is honest: everykit_standard_cowl
   advertises 8, melts for 5`, `SMOKE FAIL`. Restored -> PASS. This is the first
   assertion this loop has written that compares two INDEPENDENT paths rather than a
   value against its own source.
4. **16/16 green**, `smoke_layout` included, no row clipped.

**THE INVERTED GRADIENT IS REFUTED AS STATED.** I pre-stated that surfacing worth
would make a measured inversion visible. Then I measured it
(`tools/sim/wager_probe.gd`, committed):

    stake  5   8-8    8-20   8-8
    stake 10   8-45   8-45   8-20   8-20
    stake 20   45-45  20-45

Both ends rise with the stake: the floor goes 8 -> 8 -> 20/45, the ceiling goes
20 -> 45 -> 45. That is monotonic non-decreasing, not inverted. The panel's line -
"stake-10 Cogsworth loots a melt-45 EPIC while stake-20 Gildfall loots melt-20" - is
true only as a cherry-pick of Cogsworth's BEST case against Gildfall's WORST. It is
not a gradient inversion.

I was one step from filing "fix the inverted loot gradient" as a balance item on a
relayed claim. The measurement stopped it. That is the evidence law doing exactly its
job, and it is worth noting that the bad claim came from the project's own respected
playtest document, not from a careless source.

**The real finding, which is different:** the stake-10 tier has enormous variance
(8-45). A Cogsworth win is a lottery between a common and an EPIC while the stake is
fixed. Whether that is a defect or intended texture is a design call, not a bug -
filed as L-18 at low priority with the measurement attached, not smuggled in here.

**Next iteration picks:** L-16 (3.0), then L-08 (2.0), L-10 (1.5).

---

## Iteration 4 - 2026-09-01 - L-15, the brass coffer tells you about its pity

**Picked:** L-15 (priority 4.5), top live item. Lens: Cozy Collector (surprise you
cannot see the shape of) and QA Hunter (P3, labels never lie).

**RECONCILE - defect re-measured this iteration, not carried over.** 40,000 brass
coffers: printed C70 / R22 / E8, realized **C 63.3 / R 21.9 / E 14.8**. Tin printed
C85 / R12 / E3, realized 85.1 / 11.9 / 3.0 - honest to a tenth of a point.

**The D5 dependency is real and was checked, not assumed:** `grep pity
meta/save_manager.gd meta/player_state.gd` returns NOTHING. The pity counter is not
persisted, so it resets every launch. That means **14.8% is a marathon-session upper
bound**, and a relaunch-often player sees something closer to the printed 8%.
Printing a single number would be true for neither player. Owner Q2 (additive save
v5) gates the version of this fix that makes one number honest.

**The exact rule, read from `_roll` rather than from the header comment:** pity
counts BITS since the last EPIC, brass only (`guarantee_rare`), incremented on each
non-EPIC bit, and forces an EPIC at `pity >= 9`. So the tenth consecutive non-EPIC
bit is always an Epic. Tin never touches this path, which is precisely why tin
measures honest.

**CRITERION (stated before writing any code):**
1. The brass coffer discloses its pity rule in words, verbatim-true to the code, on
   BOTH the Coffer Nook and the Barrow cartboard. Verified in a rendered frame.
2. Tin makes no pity claim, because tin genuinely has none.
3. The disclosure is DERIVED from a named constant, not hand-typed, and a gate
   assertion proves it - **shown red when the constant and the text disagree**.
4. `smoke_layout` green and all 16 gates green. The Nook odds line already sits at
   the edge of its card, so the disclosure must not ride on that line.

**Revert trigger:** the disclosure overflows its card in a rendered frame, or the
new assertion cannot be made to fail on purpose.

**Explicitly NOT claimed:** this does not close the 8-versus-14.8 gap numerically.
It discloses the mechanism that causes it. The numeric fix stays owner-gated on Q2,
and the ledger will say so rather than implying the gap is resolved.

**Result: KEPT. All four criteria met.**

1. **Disclosed on both screens, verified in frames.** Coffer Nook and Barrow
   cartboard both read `never more than 9 bits without an Epic` under the odds.
2. **Tin claims nothing**, because tin has no pity and no guarantee. `pity_line`
   returns "" for it, and a gate asserts that rather than trusting it.
3. **Derived, and the gate was seen red.** `BRASS_PITY` is now a named constant,
   `_roll` uses it, and `pity_line` formats it. Negative control: change the constant
   to 12 and hand-type "9" in the copy -> `[FAIL] brass discloses its pity at the
   real threshold`, `SMOKE FAIL`. Restored -> PASS.
4. **16/16 gates green**, `smoke_layout` included.

**One placement correction inside Phase 4.** The first render put the footnote at
offset -34, which landed it across the chest lid and the wax strap - legible, and
wrong for the register. Text over illustration is not cozy-craft. Moved to the clear
band below the card, above the seal instruction, and re-rendered to confirm. The
literal revert trigger ("overflows its card") had not fired; I moved it because the
frame looked bad, which is the entire reason the loop renders frames at all.

**What this does NOT do, restated so the ledger cannot be misread later:** the
printed 8% still does not equal the realized ~14.8%. This discloses the mechanism
that causes the gap; it does not close it. Closing it needs one honest number, which
needs the pity counter to survive a relaunch, which needs save v5 - **owner Q2**.
Until then a player can at least see that a pity rule exists and what it promises.

**L-15 closed as DISCLOSED, not as resolved.** The numeric half is re-filed under
the owner queue rather than left implied.

**Next iteration picks:** L-09 (4.0, Proving spoils show no value), then L-16 (3.0).

---

## Iteration 3 - 2026-09-01 - L-16, make the visual baseline hermetic

**Picked:** L-16 (priority 6.0), the top live item now that L-17 is closed. Lens:
none directly - this is the loop's own instrument, and it is load-bearing, because
rendered frames are a primary verification layer (L3) and a baseline that drifts on
its own produces false diffs and hides real ones.

**RECONCILE - defect reproduced, not assumed.** Two consecutive `shots.sh` runs with
no code change between them:

    run 1  d8a6b41b45eb08ee372cd41c51681a04
    run 2  028a158b5f9e175fdedde20f37e31c7b

Different. Cause confirmed by reading the path rather than guessing: `demo_varied()`
(ui/workshop.gd:2204) is fully deterministic - six fixed family picks, and `grep`
finds no `randi`/`randf`/`randomize`/`RandomNumberGenerator` anywhere in
workshop.gd. So the variance is not in the render, it is the persisted save.
`shots.sh` backs up and restores `user://manabit_save.json` around a run, but the
save PERSISTS BETWEEN runs, so each capture boots from whatever the last one left
behind.

**CRITERION (stated before writing any code):**
1. Two consecutive `shots.sh` runs with no code change produce **byte-identical
   PNGs for all six screens** (per-file md5 equal, not just the aggregate).
   Instrument: `md5sum loop/out/shots/*.png` across two runs.
2. The player's real save is still protected: a save present before the run is
   byte-identical after it.
3. All 16 gates green.

**Revert trigger:** frames still differ after the fix, or the real save is altered
by a capture run.

**Known limit to state up front, not to discover later:** the Barrow shelf and the
Doorstep gift are keyed to the calendar day, so frames are reproducible *within* a
day and may legitimately differ across a date boundary. That is a property of the
game, not a defect in the harness, and it will be recorded rather than engineered
around.

**Result: CRITERION 1 MISSED. L-16 stays OPEN. The save fix is kept, and I am
overriding my own revert trigger deliberately - saying so rather than quietly
keeping it.**

After booting each capture from a fresh save, 3 of 6 screens became byte-stable and
3 did not:

    stable    compendium, menagerie, proving
    drifting  barrow, coffer_nook, workshop

**Root cause of the residual, measured not guessed.** It is not state at all - it is
wall-clock animation phase, sampled at capture time:
- `ui/chest_screen.gd:341` - the coffer rune pulses on `sin(Time.get_ticks_msec() / 480.0)`
- `ui/workshop.gd:650` and `ui/manabit_stage.gd:194` - the soul hum and the medallion
  invite ring, both sampling `Time.get_ticks_msec()`
Exactly the three screens that drift. The warmth grain was a suspect and is exonerated:
`ui/warmth.gd:48` seeds it at `rng.seed = 7`, so it is deterministic.

**Why the save fix is kept anyway.** The revert trigger exists to stop me keeping a
change that did not achieve its purpose. This one achieved a provable sub-goal with
its own evidence, independent of the byte-identity goal: a capture no longer inherits
the previous capture's wallet, shelf and tray, and a real save is byte-identical
before and after a run (verified with a sentinel: `1db6fad3...` both sides). That is
a genuine defect fixed. Reverting it would restore a bug I have now proven exists,
purely because a more ambitious criterion was not met. So it stays - stated openly,
not smuggled through as a pass.

**What I did NOT do, and why.** Byte-identity now requires freezing animation clocks
in three shipped UI files. Changing how the game animates for the benefit of a
screenshot tool is the tail wagging the dog, and it touches player-facing feel to
serve a test. That decision deserves its own criterion and its own iteration, not a
quiet widening of this one.

**Honest correction during this iteration:** my first comparison reported PASS on all
six. It was wrong - a greedy `sed 's|.*/||'` stripped the md5 hash along with the
path, so it compared filenames to filenames. Caught by re-reading the command, not by
the output looking suspicious. It would have closed L-16 on a fabricated pass.

**L-16 rescored and left open** with the root cause attached, so the next iteration
starts from the diagnosis rather than repeating it.

---

## Iteration 2 - 2026-09-01 - L-17, make an empty run loud

**Picked:** L-17 (priority 9.0). It outranks L-16 (6.0), which the Routine prompt
listed first - that prompt was written before L-17 existed, and priority decides, not
the prompt. Lens: none, this is the loop's own accountability. It is the direct guard
against Incident 1.

**RECONCILE:** baseline 14/14 fast gates green, tree clean, head 6974b95. L-17 was
filed one commit ago from a failure observed this session, so its evidence cannot be
stale.

**CRITERION (stated before writing any code):**
1. A check exists that compares the branch head across an iteration and **exits
   non-zero with a loud message** when the iteration ends with no new commit and no
   BLOCKED report. **Proven by running it on a deliberately empty iteration** - an
   assertion never seen red is not evidence, which is the lesson iteration 1 learned
   the hard way.
2. It exits 0 when a commit was made (proven on this iteration's own commit).
3. It exits 0 when a BLOCKED report was written (proven by writing one).
4. All 16 gates green.

**Revert trigger:** the check cannot be made to fail on a deliberately empty run, or
it reports success in any case where nothing was delivered.

**Result: KEPT. All four criteria met, each proven by a control that was seen to fail.**

`tools/loop/verdict.sh` records the head at Phase 0 and refuses the run at Phase 7
unless it delivered. Four controls, all run:

| Control | Expected | Actual |
|---|---|---|
| Empty run, no commit, no blocker | loud FAIL | `VERDICT: FAIL - this iteration delivered NOTHING`, exit 1 |
| BLOCKED report written | PASS, echoes it | exit 0, prints the command and error |
| Blocker missing its error text | refused | exit 2, "needs both the command and its error" |
| No Phase-0 baseline recorded | FAIL | exit 1, "no iteration start recorded" |
| A commit was made | PASS | exit 0 (this iteration's own commit, below) |

The third control matters more than it looks: a blocker that does not name the exact
command and the exact error is not a report, it is a shrug. The script refuses to
accept one, so "BLOCKED" cannot become the new way of delivering nothing.

Wired into Phase 0 and Phase 7 of the protocol and the skill, so it is enforced
rather than remembered. 16/16 gates green.

**Not a substitute for judgment.** This proves an iteration produced a commit; it
cannot prove the commit was worth making. That is what the criterion, the fun rubric
and the revert rule are for. It closes exactly one hole: silence.

**Addendum, found by using it.** At this iteration's own Phase 7 the check reported
FAIL on a run that had plainly delivered - negative control 4 had deleted the
baseline and it was never re-recorded. A false negative: a fresh container has no
`loop/out/` at all, so an unattended run could be told it delivered nothing right
after committing. Fixed by falling back to `origin/<branch>` when no baseline exists
- `check` runs before push, so commits ahead of origin are exactly this run's
delivery. Re-proven both ways: FAIL when HEAD equals origin and nothing was written,
DELIVERED via the fallback and via an explicit baseline.

That is the second time this session that a control caught a defect in the thing
built to catch defects. Worth stating plainly: the instruments are not above the
protocol they enforce, and the only reason both were caught is that the criterion
demanded the check be seen to fail rather than assumed to work.

**Next iteration picks:** L-16 (hermetic shots, 6.0), then L-15 (4.5).

---

## Incident 1 - 2026-09-01 - The loop's first two unattended runs delivered nothing

**Not an iteration. A failure of the delivery mechanism, recorded because a ledger
that only holds successes is worthless.**

| Run | Fired | Duration | Cost | Model | Pushed |
|---|---|---|---|---|---|
| Scheduled | 08:17:40 | 19 min | $2.61 | Sonnet 5 | nothing |
| Diagnostic re-fire | 08:44:46 | **73 sec** | $0.45 | Sonnet 5 | nothing |

Both exited `ROUTINE_RUN_STATUS_SUCCEEDED`. **"Succeeded" means the session exited
without crashing. It says nothing about whether work landed.** The remote head sat
at 537cd42 through both, exactly where the human-driven session left it.

**What the second run proved.** After the first no-op I hardened the Routine prompt
to demand one of two explicit outcomes - a pushed SHA, or a BLOCKED report with the
exact command and error - and to verify the push path FIRST, before spending twenty
minutes on Godot and gates. The re-fire then finished in **73 seconds** instead of
19 minutes. That collapse in duration is the evidence: it checked whether it could
deliver, found it could not, and stopped as instructed. The failure is structural to
fresh fired sessions in this environment, not a one-off.

**Root cause of the FIRST run, stated separately because it is my error:** the
original Routine prompt described the seven phases but never demanded an outcome. A
run could analyse, conclude things looked fine, and exit clean. I wrote a protocol
whose entire thesis is that gate-green is not delivery, and then wrote a trigger
prompt that accepted "I looked at it" as done.

**Fix applied:** the fresh-session Routine is deleted. The loop now fires INTO THE
SESSION THAT CAN DELIVER (`trig_01Vk2VwDhqM78UoKBokyGagH`, self-bound, every 4
hours). That session has the engine cached, the repo checked out, and a proven push
path - four commits landed with CI green. The outcome rule is carried into the new
prompt.

**Cost of the lesson:** $3.06 and two empty runs. Cheap for discovering that the
delivery path was never verified before the loop was declared running. It should
have been the first thing tested, not the third.

**New standing rule, added to the protocol:** verify the loop can DELIVER before
trusting it to run. A scheduler that reports success while producing no commits is
strictly worse than no scheduler, because it manufactures false confidence - the
same failure shape as the wave-4b audio bug, one layer up.

---

## Iteration 1 - 2026-09-01 - L-07, the coffer odds line

**Picked:** L-07 (priority 4.0), tied with L-09; broke the tie toward the cheaper,
fully self-contained one. Lens: Newcomer + Cozy Collector. Principle: P3 (labels
never lie), applied preventively, plus plain legibility.

**RECONCILE result:** defect confirmed STILL LIVE. The odds line is a hardcoded
string literal duplicated in two places, `ui/broker_screen.gd:203` and
`ui/chest_screen.gd:307`. No change order touched it; `git log` shows the files
untouched since the initial commit.

**What the reconcile also established (and it changes the fix):** the printed
numbers are currently TRUE. `PackRoller.roll_brass` is `_roll(5, true, 0.70, 0.92)`
= C70 / R22 / E8, and `roll_tin` is `_roll(3, false, 0.85, 0.97)` = C85 / R12 / E3.
So this is not a lie today. It is two hand-copied literals sitting next to four
magic numbers in another file, with nothing holding them together - a lie waiting
to happen the first time anyone tunes the roller. The project already has a law for
exactly this shape: `smoke_run.gd:174` asserts that printed event odds match the
threshold verbatim. Coffers have no such assertion.

**CRITERION (stated before writing any code):**
1. In rendered frames of the Coffer Nook and the Barrow, each odds figure carries
   its own percent sign - no trailing bare `%` governing three numbers at a
   distance - at a line width no greater than today's. Instrument:
   `tools/loop/shots.sh`, read the frames.
2. The printed figures are DERIVED from `PackRoller`'s thresholds rather than
   hand-copied, so the label cannot drift from the roll.
3. A new gate assertion proves the printed line matches the thresholds verbatim,
   mirroring `smoke_run.gd:174`. It must be shown to FAIL when the threshold and
   the label disagree - an assertion never seen red is not evidence.
4. All 16 gates green, `smoke_layout` included (the 720px budget has zero slack).

**Revert trigger:** the derived line renders wider than the current one, or
`smoke_layout` goes red, or the new assertion cannot be made to fail on purpose.

**Result: KEPT. Three criteria met, one missed by one character - stated plainly
rather than rounded up.**

- **(1) Legibility - MET. Width - MISSED by 1 character.** The line reads
  `5 bits · C70% R22% E8% · rare+ guaranteed`; every figure carries its own unit and
  the stray trailing `%` is gone. It renders inside the coffer card on both the Nook
  and the Barrow, and `smoke_layout` (the actual fit gate) is green. But it is 41
  characters against the old 40, so the criterion as I wrote it - "no greater than
  today's" - is not literally satisfied. It is also unsatisfiable as written: fixing
  the defect costs two characters for the two added units and refunds one for the
  dropped bare `%`, so +1 is the provable floor. A first draft used
  `C 70% · R 22% · E 8%`, which rendered visibly wider than the card and tripped the
  revert trigger; that was tightened rather than excused, and re-rendered to confirm.
- **(2) Derived, not hand-copied - MET.** `PackRoller` now names its thresholds
  (`BRASS_RARE` etc.) and `odds_line()` formats them. Both call sites ask the roller.
  Two duplicated literals became zero.
- **(3) An assertion that can go red - MET, but only after the first attempt failed
  this test.** The structural assertions I wrote first were tautological: label and
  threshold derive from the same constant, so tampering the constant moved both and
  the gate stayed green. Chasing that added an *empirical* assertion - roll 4,000 tin
  coffers and compare the realized mix to the printed line within 2pp. Negative
  control: tampering only the label's math while leaving the roll alone gives
  `SMOKE FAIL`; restored, green.
- **(4) All 16 gates green - MET.**

**What the negative control turned up, which is worth more than the fix:** chasing a
gate that could actually fail meant measuring what the coffers really roll.
`tools/sim/odds_probe.gd` (committed - it earned its place) over 40,000 brass coffers:
**realized C 63.3% / R 21.9% / E 14.8% against a printed C70 / R22 / E8.** The
epic-pity at 9 nearly doubles the real EPIC rate. Tin is honest to a tenth of a point.
The error is generous, so it is not predatory, but the label still does not match the
roll and the pity - a real kindness - is invisible. Filed as **L-15** with the
measurement, and it is entangled with D5: pity is not persisted, so 14.8% is a
marathon-session upper bound. Brass is deliberately excluded from the empirical
assertion with that reason written at the assertion.

**Also filed: L-16.** The Barrow frame before the change showed 50 scrap and three
Finds; after, 12 scrap and one Find, with nothing in the diff touching the economy.
`shots.sh` restores the save around a run but state persists between runs, so the
visual baseline drifts on its own. Visual review is now a primary verification layer,
and a drifting baseline produces false diffs and hides real ones. That makes L-16
(priority 6.0) the top pick, ahead of any content work - the loop should fix its own
instrument before trusting another frame.

**Next iteration picks:** L-16, then L-15.

---

## Iteration 0b - 2026-09-01 - CORRECTION: the backlog was stale on arrival

**What happened:** a peer session flagged that backlog items L-01 and L-02 were
already shipped. Verified here in code rather than on the peer's word or the
document's own say-so. The claim was true, and broader than reported.

**Six of ten loop-pickable items were already done**, by
`design/balance/playtest-fixes-change-order.md` (COUNCIL-RATIFIED 2026-07-21,
section A, nine shipped changes) - including both of the items iteration 0 named as
the next two picks:

| Item | Shipped as | Verified in code |
|---|---|---|
| L-01 fragility + defanged reason | CH-P7, CH-P8 | `workshop.gd:917,921`, `combat_screen.gd:1042` |
| L-02 junction lane labels | CH-P4 | `challengers.gd:44` swaps in a SINGLE; DEATH 0.30 > base 0.22 |
| L-03 elite core-hunt stakes | CH-P1, CH-P2 | `challengers.gd:50`; Pindrop 0.23, Sable 0.22 |
| L-04 modal Fair box | CH-P5, CH-P6 | Fair boss survival 0.01 -> 0.35 |
| L-05 boss re-tier | CH-P3 | Gildfall RACE WIN 1.000 -> 0.305 |
| L-06 inverted rarity | CH-P9 | grinlet -0.1225 -> +0.1242; seer frozen and ruled neutral |

**Root cause, stated narrowly:** iteration 0 read the *problem* statement
(`design/playtest/ai-playtest-2026-07-21.md`) and never read the *response* to it,
though the change order sat in a directory it had already listed. Reading a defect
list is not reconciliation. Reading what was done about it is.

**Cost had it not been caught:** the first two unattended iterations would have
re-implemented shipped work and reported progress for it. Worse than wasted time -
the ledger would have contained two false successes, which is the failure mode this
whole apparatus exists to prevent.

**Protocol fixed, not just the data.** Phase 0 gains a RECONCILE step and picking
gains a third law: **evidence expires; no item is picked until its defect is
re-verified as still live in code.** Backlog items L-01..L-06 are marked `closed`
with their CH mapping and kept as a record of the miss.

**The signal worth keeping:** after reconciliation the only live items are L-07,
L-08, L-09 and L-10 - and three of those four came from the rendered-frame review,
the capability that did not exist before this session. The measured-defect backlog
was exhausted; the visual one was untouched. That is an argument for the sight
capability being the real unlock, not the gate runner.

**Next iteration picks:** L-07 or L-09 (both 4.0, both copy-only, both from frames).

---

## Iteration 0 - 2026-09-01 - Build the loop, and prove it can test itself

**Picked:** the process itself. No gameplay change.

**Criterion (stated before building):** a cloud session with no access to the owner's
PC can (a) run every gate and get a verdict it produced itself, (b) render every
screen and review the frames, and (c) pick its next task from a scored list rather
than from conversation. All three or the loop is not autonomous.

**Result: MET, measured.**

- **(a) Gates.** Godot 4.7 fetched and cached by `tools/loop/bootstrap.sh`; project
  imported; **16/16 green in 65s** (14 fast gates plus `smoke_kit_sim` and
  `smoke_stalemate`). Report at `loop/out/gates.json`. Slowest gate `smoke_stage` at
  44.9s; every other gate is under 8s. This is the first time the suite has been run
  by the session that reports it.
- **(b) Sight.** `tools/loop/shots.sh` renders windowed under Xvfb with software GL.
  All 6 screens captured and reviewed. The review produced three new backlog items
  that no gate could have found (L-07, L-08, L-09) - which is the point.
- **(c) Picking.** `loop/backlog.json`: 14 items, scored `lift * evidence /
  (cost * risk)`, seeded from the measured D1-D11 / R1-R7 findings of the 2026-07-21
  playtest panel plus the visual review. 10 loop-pickable, 4 owner-gated.

**What this changes:** verification stops being a claim relayed from an unreachable
machine. The wave-4b silent-audio bug - eight loops passing every existence check
while loading null - is the standing proof that relayed green is not green. The
silence rule in the protocol is written against exactly that failure.

**Honest limits recorded, not papered over:** no audio device, so audio stays
structurally verified and never heard. No human feel, so persona scores are a proxy
and are labelled as one every time they are used. Section 13, the save schema, final
taste, and Blender remain owner work; they are now queued with the case built rather
than blocking.

**Next iteration should pick:** L-02 (junction labels, priority 9.0) - cheapest item
that repairs a promise the build is currently breaking by measurement, and it touches
copy only, so the risk of a first unattended pass is minimal. L-01 (priority 6.0,
new-player legibility) is the higher-lift follow-on.
