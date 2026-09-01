# LOOP LEDGER

Append-only. Newest at top. One entry per iteration: what was picked, the criterion
**stated before building**, the measured result, and kept-or-reverted.

A reverted iteration that produced a real measurement is a successful iteration.
Never rewrite an entry.

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
