# MANABIT LAUNCH LEDGER

The single durable queue for the autonomous refine-to-launch loop. A loop iteration starts
with a cold context: this file IS the memory. Read it first, do ONE item, write the result
back here, stop.

Seeded 2026-09-01 from: `design/playtest/ai-playtest-2026-07-21.md` (D1-D11),
`design/balance/playtest-fixes-change-order.md` (CH-P1..P9 shipped, section C deferred),
`CLAUDE.md` Status, and a verified `run/gates.ps1` sweep (16/16 green at seed time).

---

## LAWS (never violated by the loop)

1. **Gates stay green.** `powershell -ExecutionPolicy Bypass -File run/gates.ps1` must exit 0
   before an item is marked DONE. Red gates outrank every queued item.
2. **Frozen surfaces need an owner ADR, not a patch.** The §13 contract, `combat/combat.gd`
   resolution rules, the save schema, and the 13 base fixtures in `parts/catalog.gd` are frozen.
   An item that requires touching them goes to OWNER-BLOCKED with a written ADR proposal - it is
   never quietly implemented.
3. **Measure, do not assert.** Every balance/economy claim cites a committed artifact
   (`tools/sim/out/*.json`) or a seeded headless probe re-run this pass. No "should be fine".
4. **One commit per item**, message `[ledger] <ID> - <what>`. Clean tree between items so any
   bad iteration is one `git revert` away.
5. **Bounded scope per item.** Name the files up front; if the real fix exceeds them, stop and
   re-queue it as a smaller item rather than widening.
6. **No new markdown docs** except a change order for a shipped balance/design wave.
7. **gate-green != correct.** UI items are proven with `tests/shoot.gd` screenshots, audio with a
   windowed playing-player probe. Headless alone is inert (the wave-4b silent-loop lesson).
8. **RUNNER = THE SECOND PC (ZJEO242) ONLY.** Owner call 2026-09-01: this loop does NOT run on
   GamingComputer. A session on GamingComputer may read this ledger and edit docs, but must not
   execute queue items. ONE PC AT A TIME regardless: this tree lives in the `my-game-dotclaude` Syncthing folder and is shared
   with the second PC, `.git` included. Never run the loop on both machines at once - concurrent
   commits into a file-synced `.git` corrupt it. Before starting, confirm the other machine is idle;
   each DONE LOG line names the machine it ran on.

---

## GATE

```
cd "G:\ClaudeAgents\my-game\.claude\manabit"; powershell -ExecutionPolicy Bypass -File run/gates.ps1
```
16 gates, exit 0 = green. The runner DISCOVERS Godot (`$env:GODOT`, then PATH, then
`~\Downloads` / `G:\Godot` / `Program Files`) because this tree is Syncthing-synced across two PCs
with different usernames and different Godot installs. If it prints `GODOT NOT FOUND`, set
`$env:GODOT` and re-run. GamingComputer has only 4.6.1 against a 4.7 project - the version warning
and the `SpatialMaterial specular` warnings are harmless noise, all 16 gates pass.

---

## QUEUE

Status: `TODO` / `WIP` / `DONE` / `BLOCKED`. Work top-down within a priority band.

### P0 - launch blockers

| ID | Item | Scope | Status |
|---|---|---|---|
| L1 | **Enumerate the rest of this ledger.** Run `/launch-checklist dry-run`, and append every real gap it finds as P0/P1/P2 rows below. The ledger is seeded, not complete. | this file | TODO |
| L2 | **No shippable build exists.** No `export_presets.cfg`, no export templates configured, no app icon, no version string. Produce a Windows export preset + a clean exported build that launches and plays. | `export_presets.cfg`, `project.godot`, `art/icon` | TODO |
| L3 | **No title / pause / options screen.** `root.tscn` boots straight into the Workshop. Needs a title screen, a pause path, and an options panel (audio buses already exist in `ui/sfx.gd`: master/music/sfx/ambience sliders). | `ui/root.gd`, new `ui/title_screen.gd`, `ui/options.gd` | TODO |
| L4 | **Re-run the AI playtest panel post-CH-P1..P9.** The 5.75/10 read predates the nine shipped fixes; the current enjoyment/difficulty shape is unmeasured. Produces the honest remaining-defect list that drives P1. | `tools/sim/*`, new `design/playtest/ai-playtest-<date>.md` | TODO |
| L5 | **Wave-2 meshes: 20 bits still on procedural placeholders.** Catalog is 100 bits / 17 families; only 80 have real glbs. Build per `design/art/wave2-mesh-work-order.md` via blender-mcp + `tools/art/manabit_bit_lib.py`, then re-render icons and re-run `smoke_art`. | `art/bits/`, `art/icons/` | TODO |
| L6 | **No input map / keyboard path.** `project.godot` declares no `[input]` actions; the game is mouse-only with no rebinding and no gamepad. Decide the minimum (at least Escape=pause) and wire it. | `project.godot`, `ui/root.gd` | TODO |

### P1 - quality bar

| ID | Item | Scope | Status |
|---|---|---|---|
| L7 | **D6 - Glimmer is a dead currency** (57.2 earned / 0.0 spent over 30d). Needs a sink. Design it via the economy-designer + producer skills, ADR the shape, then build it. Feature-sized: split into design + build items. | `economy/broker.gd`, `ui/broker_screen.gd` | TODO |
| L8 | **D9 - 80% compendium unreachable in month one** for ~87% of players and the shortfall is invisible in-game. Add one relaxed discovery faucet (an undiscovered-Find slot) + surface the gap. | `economy/broker.gd`, `ui/compendium_screen.gd` | TODO |
| L9 | **Deferred UI backlog:** hex-shaped slot plates, rarity rim + HP pips on plates, coffer glb in a SubViewport (props already exist at `art/props/`). All DESIGN.md-token-grounded. | `ui/socket_rig.gd`, `ui/chest_screen.gd` | TODO |
| L10 | **Challenger loadouts should adopt the sovereign bits.** Brassmore fields mixed EPICs, not his own house set. Balance-measured, not vibes. | `combat/challengers.gd` | TODO |
| L11 | **Onboarding.** No tutorial or first-run guidance exists; D3's fragility cue is a warning, not teaching. Decide the minimum viable first-run path. | `ui/workshop.gd`, `ui/root.gd` | TODO |

### P2 - polish, only after P0+P1 clear

| ID | Item | Scope | Status |
|---|---|---|---|
| L12 | PS1 render stack (vertex-jitter + affine-mapping shaders) - deferred since M0. The art direction names it; verify whether it still earns its place before building. | `ui/manabit_stage.gd`, new shaders | TODO |
| L13 | Accessibility options pass (photosensitivity caps exist in the beat planner; needs a user-facing toggle + text scale). | `ui/options.gd` | TODO |
| L14 | Store-page surface: capsule art, screenshots, trailer capture, description copy. | `production/` | TODO |

---

## OWNER-BLOCKED (loop must NOT decide these)

Each needs an owner ADR. The loop may *draft* the ADR with measured options and a recommendation,
then stop. It may not implement.

| ID | Item | Why blocked |
|---|---|---|
| B1 | **D5 - coffer RNG stream + EPIC pity not persisted** (relaunch-scummable, byte-identical brass for every new player). | Needs save **v5**; save schema is FROZEN. |
| B2 | **D7 / D13 - no turn cap;** defensive fights grind 167-221 turns, ladder top uncappable (`reached_top` 0.00). | A `combat.gd` resolution-rule change; §13 frozen. ADR drafted at `design/balance/wave1-change-order.md`. |
| B3 | **D11 - speed axis is inert** (sniper attacks ~0.00) and `Combat.new()` does not enforce build legality. | Resolver change; §13 frozen. |
| B4 | **BESTED stamps** on challenger rows. | Needs a save-schema field. |
| B5 | **Launch surface decisions:** store (Steam / itch), price, release date, name/trademark clearance. | Business calls, not engineering. |

---

## DONE LOG

Newest first. One line each: ID, date, MACHINE, what shipped, the number that proves it.

- (seed) 2026-09-01 - GamingComputer - ledger created; `run/gates.ps1` added (Godot auto-discovery, portable across both PCs) and verified ALL 16 GATES GREEN.
