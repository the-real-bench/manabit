# LOOP LEDGER

Append-only. Newest at top. One entry per iteration: what was picked, the criterion
**stated before building**, the measured result, and kept-or-reverted.

A reverted iteration that produced a real measurement is a successful iteration.
Never rewrite an entry.

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
