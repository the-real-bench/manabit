# LOOP LEDGER

Append-only. Newest at top. One entry per iteration: what was picked, the criterion
**stated before building**, the measured result, and kept-or-reverted.

A reverted iteration that produced a real measurement is a successful iteration.
Never rewrite an entry.

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
