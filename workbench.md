# MANABIT Workbench

Session log - newest at top. Each entry captures what actually happened, decisions made (with reasoning), and what's outstanding. Never rewrite or delete entries; only prepend.

---

## 2026-09-01 (incident 1 + loop iteration 2: the loop learns to notice its own silence)

**What happened:**
- **INCIDENT 1 - the first two unattended runs delivered nothing.** Scheduled 08:17: 19 min, $2.61, pushed nothing. Diagnostic re-fire 08:44: 73 sec, $0.45, pushed nothing. Both exited SUCCEEDED - which only means the session did not crash. Caught only because a session happened to fetch the branch. Root cause of the first is mine: the trigger prompt described the seven phases but never demanded an OUTCOME, so a run could analyse, decide things looked fine, and exit clean. The 73-second second run is the evidence for the structural half: after the prompt was hardened to check the push path first, duration collapsed from 19 minutes, meaning it found it could not deliver and stopped.
- **Fix:** fresh-session Routine deleted; the loop now fires INTO the session that can deliver (trig_01Vk2VwDhqM78UoKBokyGagH, self-bound, every 4 hours). Protocol gained section 2b: verify the loop can DELIVER before trusting it to run.
- **Iteration 2 shipped L-17** (priority 9.0, which outranked the L-16 the Routine prompt named - priority decides, not the prompt): `tools/loop/verdict.sh`. `start` records the head at Phase 0; `check` at Phase 7 refuses any iteration that produced neither a commit nor a `blocked` report naming the exact command and its exact error. Four negative controls run and SEEN TO FAIL, including a malformed blocker (exit 2) - so "BLOCKED" cannot become the new way of delivering nothing. Wired into the protocol and the skill so it is enforced, not remembered.

**Decisions (with reasoning):**
- **A ledger that only holds successes is worthless**, so Incident 1 is recorded in full including its $3.06 cost. The whole apparatus exists to catch false confidence; hiding its own first failure would be the same sin.
- **The delivery path is tested before the engine, the gates, or the backlog.** A run that cannot push should find out in seconds, not after twenty minutes of work it is about to throw away.
- **verdict.sh proves delivery, never worth.** It closes exactly one hole - silence. Judgment stays with the pre-stated criterion, the fun rubric and the revert rule.

**Outstanding / next session:**
- L-16 (hermetic shots, 6.0), then L-15 (brass odds honesty, 4.5, needs the D5 read).
- Owner queue Q1-Q5 unanswered. Two new owner questions: scheduled runs default to Sonnet 5 (the Routine stores no model), and cadence is 6/day against a 5-item backlog while the owner hit a usage limit.

## 2026-09-01 (loop iteration 1: the coffer odds line, and what the negative control found)

**What happened:**
- Owner authorized the loop to run here: schedule every 4 hours (fresh session per fire), push to the working branch ONLY, no PRs, no merges. Routine `trig_012ncu72zSqNfCbyW4ZpqdfD` created; fired sessions carry no MCP connectors (plain git only), which suits a branch-only loop.
- **Iteration 1 ran the full seven phases on L-07 (the coffer odds line).** RECONCILE confirmed the defect live: the odds were a hardcoded literal duplicated at `ui/broker_screen.gd:203` and `ui/chest_screen.gd:307`, untouched since the initial commit, sitting next to four magic numbers in `pack_roller.gd` with nothing holding them together.
- **Shipped:** `PackRoller` names its thresholds and derives the printed line via `odds_line()`; both UI sites ask the roller; the line now reads `5 bits · C70% R22% E8% · rare+ guaranteed` with every figure carrying its own unit. New `smoke_broker` assertions, including an EMPIRICAL one (4,000 tin coffers, realized mix vs printed, 2pp band).
- **The negative control earned the iteration.** The first assertions I wrote were tautological - label and threshold derive from the same constant, so tampering the constant moved both and the gate stayed green. Fixing that meant measuring what the coffers actually roll, and that found a real defect: **brass prints EPIC 8% and rolls 14.8%** (40,000 coffers, `tools/sim/odds_probe.gd`, now committed). Epic-pity at 9 nearly doubles it. Tin is honest to a tenth of a point. Filed as L-15, entangled with D5 (pity is not persisted, so 14.8% is a marathon-session upper bound).
- **The loop caught its own instrument breaking.** Barrow frames before and after showed different scrap and Finds with nothing economy-related in the diff: `shots.sh` restores the save around a run but state persists BETWEEN runs, so the visual baseline drifts. Filed as L-16 at priority 6.0 - now the top pick, ahead of any content work.

**Decisions (with reasoning):**
- **The revert trigger fired once and was honored.** A first format (`C 70% · R 22% · E 8%`) rendered wider than the coffer card. Tightened and re-rendered rather than excused.
- **Criterion 1 is recorded as MISSED by one character, not rounded up.** The line is 41 chars against 40. Fixing the defect costs +2 units and refunds the bare `%`, so +1 is the provable floor and the criterion was unsatisfiable as written. Recording the miss keeps the ledger worth reading.
- **Brass is deliberately excluded from the empirical assertion**, with the reason written at the assertion rather than left as a silent gap.
- **The loop fixes its own instrument first.** L-16 outranks content work because visual review is now a primary verification layer and a drifting baseline hides real regressions.

**Outstanding / next session:**
- L-16 (hermetic shots), then L-15 (brass odds honesty, needs the D5 read).
- Owner queue unchanged and unanswered: Q1 turn-cap ADR, Q2 additive save v5, Q3 speed axis, Q4 Blender, Q5 taste posture. Q6 (cadence) is now answered.

## 2026-09-01 (process: the autonomous loop is built, and it can test itself)

**What happened:**
- Owner asked how to refine the process into a loop that builds MANABIT incrementally without their input. Answered by building the machine, not by writing a plan.
- **The blocking constraint turned out to be false.** Verification did not actually need the owner's PC. A cloud Linux session fetched Godot 4.7 stable, imported the project, and ran **all 16 gates green in 65 seconds** (14 fast + smoke_kit_sim + smoke_stalemate; slowest is smoke_stage at 44.9s, everything else under 8s). This is the first time the suite has been run by the same session that reports it.
- **The loop can SEE.** Headless Godot draws nothing, so every visual judgment used to be owner-only. `tools/loop/shots.sh` renders windowed under Xvfb with software GL: all 6 screens captured and reviewed this session. The review produced 3 backlog items no gate could have found (odds string legibility, a saturated cyan panel on the coffer lid to audit against the warm palette, spoils lines that name bits but never their value).
- **Shipped:** `tools/loop/bootstrap.sh` (engine acquisition, cached, idempotent, honours $GODOT so the Windows checkout reuses it) - `tools/loop/gates.sh` (16 gates, JSON report at loop/out/gates.json, a gate with no printed verdict counts as FAIL) - `tools/loop/shots.sh` (Xvfb capture, auto save backup/restore, flags suspiciously small captures) - `loop/backlog.json` (14 scored items) - `loop/ledger.md` - `loop/owner-queue.md` - `design/process/autonomous-loop.md` - `design/process/fun-rubric.md` - `.claude/skills/loop-iteration/` - `.github/workflows/gates.yml` (first CI this project has had).
- **Backlog seeded from evidence already in the repo.** The 2026-07-21 AI playtest panel produced D1-D11 and R1-R7 in markdown that no process consumed; those measurements are now scored and pickable. Top loop-pickable item is L-02 (junction lane labels lie about risk: the menace-flavoured lane measures DEATH 0.00, the gift-flavoured lane DEATH 0.59) at priority 9.0.

**Decisions (with reasoning):**
- **Two laws govern picking, both written against this project's own scars.** The evidence law (`evidence < 2` may only be MEASURED, never built against) exists because wave 1 shipped two changes that moved the wrong way and had to be reverted. The risk law (`risk: 5` is never picked) keeps section 13, the save schema, and the base fixtures owner-gated by construction rather than by memory.
- **Escalation is a write, never a wait.** One frozen-contract question used to stall the queue behind it. The owner queue holds the case already built (measurement, options, recommendation) and the loop takes the next item.
- **Fun got a red light.** Sixteen gates prove the game works and none of them prove it is worth playing; a loop that optimises only what it can assert holds correctness flat while enjoyment drifts. The rubric is built from this build's own measured failures (toothless elites, lying lane labels, the guaranteed-death modal box, inverted rarity, the byte-identical coffer stream) rather than from generic design advice, so each principle carries local proof.
- **The silence rule is now protocol, not lore.** Wave 4b's eight audio loops passed every existence check while loading null. Anything that can be silent gets a live probe; gate-green is neither audible nor visible.
- **Honest limits recorded rather than papered over:** no audio device (audio stays structurally verified, never heard), no human feel (persona scores are a labelled proxy), and Blender/taste/section 13 remain owner work.

**Correction, same session (backlog was stale on arrival):** a peer session flagged L-01/L-02 as already shipped; verified in code, and it was broader - SIX of ten loop-pickable items were already delivered by design/balance/playtest-fixes-change-order.md (ratified 2026-07-21, 9 shipped changes): L-01=CH-P7/P8, L-02=CH-P4, L-03=CH-P1/P2, L-04=CH-P5/P6, L-05=CH-P3, L-06=CH-P9. Root cause is narrow: this session read the playtest PROBLEM statement and never the RESPONSE to it, though the change order sat in a directory it had already listed. Protocol fixed rather than just the data - Phase 0 gains RECONCILE and picking gains a third law (evidence expires; re-verify the defect is still live IN CODE before picking). Closed items kept with their CH mapping as a record of the miss. The signal worth keeping: after reconciliation the only live items are L-07/L-08/L-09/L-10, and three of the four came from the rendered-frame review - the measured-defect backlog was exhausted, the visual one untouched, which argues that SIGHT is the real unlock here, not the gate runner.

**Outstanding / next session:**
- **Run the first unattended iteration:** L-07 or L-09 (both 4.0, copy-only, both found by looking at frames).
- **Owner queue needs six answers** (none blocking): Q1 turn-cap ADR, Q2 permission for an additive save v5, Q3 speed-axis ADR (recommend deciding after Q1), Q4 the Blender mesh batch, Q5 taste sign-off posture, Q6 cadence and per-pass authorisation.
- Everything from the 2026-07-19 entries still stands.

## 2026-07-19 (loop closeout addendum: wave 4b audio structure on Opus + the silent-loop fix)

**What happened:**
- Fable 5 quota ran out mid-wave-4b (all 6 lanes errored). Owner had pre-authorized the Opus 4.8 fallback; re-ran wave 4b on Opus. Before relaunch, verified the project clean at 15/15 gates - the only Fable-era residue was a partially-edited-but-parsing make_sfx.py (a build tool, not loaded by the game). (Self-caught error: a `make_sfx.py --help` probe backfired because the script has no argparser and ran a full render against the real audio dir - harmless, seeded/byte-reproducible, and the Opus lane-C verifier later confirmed the 59 legacy wavs sha256-identical.)
- **Wave 4b on Opus DELIVERED the structural audio layer:** four-bus tree (Master > Music/Ambience/SFX, Ui under SFX) + the stillness gate (priority-claimed bus mute that refuses every seam except the death-channel allowlist during THE UNMAKING, released only by the beat-gated parts_settle) + four ref-counted duckings, all in ui/sfx.gd (additive; Sfx.play API unchanged, headless-inert intact). tools/audio/make_sfx.py gained wave_4b(): 4 ambience beds + soul_hum + the core_hum pair + peril_bed (exact loop frame counts, smpl chunks) + The Wound Spring 4 bench stems (note-data, C major/A minor, 80 BPM, 16 bars, 48.000s sample-locked). Combat presence in ui/combat_screen.gd (core hums whose gain rides display-HP, peril bed state, and the accessibility-REQUIRED R1 sustained peril visual - a static WAX PERIL core-row tag that is reduce-motion-safe so the bed never carries information alone, verified by windowed capture). New ui/music_box.gd plays the stems via AudioStreamSynchronized with per-screen stem mixes + punctuation rules; wired into root.
- **The verifier earned its keep:** it reported RED on a CONFIRMED ship-blocking defect that all 8 gates were falsely green on - every ambience/hum/peril loop_start resolved res://audio/sfx/<manifest-basename> but Lane C rendered those files to res://audio/ambience/ under different basenames, so every loop loaded null and no-opped (the wave's headline layer would ship SILENT). It correctly refused to fix cross-lane (sfx.gd is Lane-A-owned) and flagged the false-green root cause (smoke_audio only checked audio/sfx/ and printed [PENDING] without asserting).
- **I fixed it (diagnosis was already adversarially verified):** threaded a per-row `dir` key through Sfx._load_stream + its 3 callers (AMB_DIR/MUS_DIR consts declared before MANIFEST for const-resolution safety); corrected the 8 loop rows (real basenames + AMB_DIR); resolved the core_hum single-vs-pair mismatch by pointing me/foe at the pre-detuned core_hum_0/core_hum_1 files panned L/R (dropping the now-redundant runtime pitch detune); set amb_nook gain -44->-38 because measurement showed the -6 dB is baked into the file (peak -24 vs workshop -18). **Hardened the false-green gate:** smoke_audio now asserts EVERY manifest file resolves at its declared dir (no pending tolerance) AND that Sfx.stream_for loads a non-null AudioStream for every seam - so a dir/basename drift fails the same day. Corrected 3 stale stage-A3 assertions that had encoded the old broken design (pending-tolerant, core-hums-share-one-file, core-hums-different-pitch).
- **Proven audible-path, not just gate-green** (the lesson of this bug): a windowed non-inert probe confirmed all 8 loop seams create live .playing AudioStreamPlayers with correct streams/buses/levels (amb_workshop.wav @ -38, core_hum_0 on AmbDuckPanL @ -32, core_hum_1 on AmbDuckPanR @ -32, peril_bed @ -26, etc). All 15 gates + smoke_kit_sim green after the fix. Save backed up + restored around every windowed run. Game relaunched windowed for the owner.

**Outstanding / next session:**
- **Owner LISTEN pass** - the game has a voice for the first time; hear the beds/hums/peril/bench music in play (headless can't audition; the runtime chain is proven, the mix is calibrated to the felt-not-heard table but ears should confirm).
- Audio wave 4b deferred tail (per the plan): shop/run/nook music stem variants, Barrow/Run ambience garnish, the post-death mourning-quiet timing polish, and the settings-menu volume sliders (the Sfx.set_bus_volume seams exist; the UI is the feature-ready milestone's job).
- Everything from the main 2026-07-19 entry's outstanding list still stands (council items, D11/D13 ADRs, save-v5 items, Blender mesh batch).

## 2026-07-19 (owner-present fixes, then the autonomous depth loop: reality engine, balance wave, Hero Shelf, venture depth, audio waves)

**What happened (owner present, morning):**
- Recovered the killed 6-lane style expedition from its on-disk journal/scratchpad, completed it, owner signed the direction (design/builder/workshop-style-direction.md) - then the 14-move Workshop reskin shipped (Tokens.sandwich material system, brass medallion slot rail replacing plates+leader lines, parchment Ledger + steelyard Balance, one hero BIND wax plate, felt drawer tray, dim-and-focus inspect, anatomy inset). Owner feedback drove the calm/onboarding pass (drawer CLOSED at rest with a lip, T1-T6 work-order tag state machine on new additive save field binds_total, Ledger hidden on empty bench, dormant husk sleeps visibly). Owner verdict: "this is MUCH MUCH better."
- Owner-reported bugs fixed with evidence: Spar no longer silently subs a Box (refuses like Bout/Venture); combat first-action TELEPORT killed (2-frame warmup guard - measured via a per-frame motion tracer), beat executor re-anchored to the real clock, combat camera locked per fight (mend-rebuild re-zoom); blind Box reveal under a held inspect (stage z 40) fixed at all three escape points; tag honesty split T6 -> T6/T7/T8 ("Still some empty pegs - Fit the head"); hub-and-spoke OVERSIZE spacing pass (chunky bits earn outward air; heads/legs cap at flush).
- Full-game AUDIO PLAN ratified (design/gdd/audio-full-game.md): direction (danger is subtraction, stillness gate, material palette = the visual tokens made audible), 109-asset inventory, tech plan, accessibility pass, task plan. Owner picked music direction: The Wound Spring (procedural music-box stems, C/Am).

**What happened (autonomous depth loop, owner away - standing orders: depth, studio agents, numbers-grounded, max effort):**
- **Wave 1 Reality Engine:** built 3 measurement instruments (tools/sim/sim_roster.gd 52k seeded fights; sim_ladder.gd ladder + venture Monte Carlo; economy_sim.py 500 players x 30 days, all constants code-cited). Balance council on the numbers -> change order -> 8/10 shipped, 2 REVERTED when criteria moved the wrong way (Sable, Pindrop). Found: pentagon broken under the v1 lens (healthier under the v2 core-aiming policy), wall/DEF dominance, light axis structurally dead (speed only buys initiative - D11 ADR), ladder non-monotonic (Ziptie fixed 0.44->0.74), dead lane modifiers, Glimmer has NO sink, bouts were free (stakes 5/10/20 + forfeit-pays-zero shipped), compendium denominator 73.
- **Wave 2 Hero Shelf:** 3 new families team-designed + ratified in the boy-robot/retro-super-robot register (Carillon Cadets bell-knights / Larkabout Skyworks tin rocket-couriers / Steadfast Gallantworks diecast guardians; legally distinct homage). 20 bits priced on measured comparables (catalog 80 -> 100, 17 branded families); verify lane ran the roster sim: 16/20 in band after one tuning iteration, wheel edges 3/6 pass (3 council items - one unfixable from our side: silksteel is lens-floor dead). Kit-sim tripwire went red on pool dilution -> pre-ratified D1 thicket shave applied (goreclaw 4->3, flenseclaw 5->4; pentagon-v2 condition verified) -> tripwire green. Mesh work order at design/art/wave2-mesh-work-order.md for the owner's Blender rig (this PC has none); bits live on procedural placeholders.
- **Wave 3 venture depth:** director KILLED new node types - Event and Scrapyard land as REST FLAVORS (frozen run contract byte-untouched): Wayside Shrine (10 warm events, resolve-on-departure, money-neutral, pre-rolled seeded outcomes), Magpie's Heap (kit-only rummage, 8 satchel scrap, 55/30/15, lent-instance law), The Last Lantern. Gleaner's Due death salvage (kit K .50/.25 with H-blend; own-build K HALVED per measured G9 overshoot). Boss retreat ruled: stays all-or-nothing + honest-info copy + two-step armed abandon. Dead-modifier fix: second_wind shipped as the measured core-pad rule (+4.2..+12.0pp, 4/4 cells in gate); tailwind HELD (1/4 cells - blocked on boss softening; the escalation's own proposed fix measured +0.0pp and was overridden by measurement). smoke_run 32 -> 40, smoke_kit 13 -> 15, new Dud+RARE-lend sim arm. QA: RNG parity byte-audit (mix/mix2 identical to the certified sim reference), firewall proofs with line cites, 6 windowed screenshots, found+fixed a real RouteRail stale-draw defect.
- **Wave 4a foley:** 45 new procedural wavs (59 total, byte-reproducible), 15 new seams wired (drawer, tag ink/untie, bind press + bound chord, medallion, ui taps, reveal ladder, snap rarity pitch ladder A-C-E live); verifier caught + fixed a 9 dB UI double-attenuation; THE UNMAKING window audited silent.
- **Wave 4b (in flight at writing):** bus architecture + stillness gate + 4 duckings, ambience beds, core-hum pair + peril bed + the accessibility-REQUIRED sustained peril visual, The Wound Spring bench piece (4 stems, 80 BPM, 16 bars).
- **All 14 gates + smoke_kit_sim green at every wave boundary, re-run independently by the coordinating session - never trusted from lane claims.**

**Decisions (with reasoning):**
- Numbers before opinions, enforced structurally: every change carried a measured justification AND a pre-stated success criterion; wrong-way movers were reverted, QA-SUSPECT verdicts blocked action (bedrock/girder nerfs deferred to instrument v2 rather than tuned on inflated deltas).
- Escalations that would touch the section 13 freeze (speed-axis payoff D11, turn cap D13) were NOT forced through - parked for ADRs with the owner.
- New-family identity comes from ability composition, not stat inflation; Larkabout ships real HP floors because the light axis is measured-dead.
- Venture depth as rest flavors = maximum felt depth for zero contract risk; crack-and-see parity extended to events/heap via the splitmix64 mix reference, byte-identical in sim and game.

**Outstanding / next session:**
- Wave 4b verdict + an owner LISTEN pass (first time the game has a voice); owner hands-on shrine -> elite -> Last Lantern -> boss pass (QA recommends).
- Council items: 4 band-miss bits (the D11 light/GUARD floor), 3 wheel edges, Sable/Pindrop elite fixes, strong own-wreck G9 overshoot (accept / quarter K / re-band), tailwind revival behind the boss-softening wave, D2/D3 pending roster-v2 conditions, D5/D6 (economy v2), D7/D9 (need save v5 - owner), D8 Glimmer shelf slot (feature wave - the measured no-sink fix).
- ADR pass needed: D11 speed axis, D13 turn cap (both owner-gated section 13 territory).
- Meshes: wave2-mesh-work-order.md awaits the owner Blender rig; icons after meshes; smoke_art extends to 100 when they land.
- Music beyond the bench piece (shop/run stem variants, the Waltz upgrade path) deferred. Still no git (Syncthing only).

## 2026-07-18 second wrap (first hands-on playtest -> full studio response: UI overhaul, CARRY, branching map, combat juice + AUDIO)

**What happened:**
- **Owner played hands-on for the first time** and fired feedback live; ~45 agents across 4 workflows + implementation/verification agents answered it.
- **UI FIT OVERHAUL (team spec, implemented in full):** root cause found - the Workshop stack was 754px in a 720px window. Rebuilt every row to a ratified budget summing to 720 exactly; layout LAW (one expander per row, capped counts x9+/9999+, squeeze_label ellipsis+tooltip); status-note contract (_set_note, 72-char cap, toast escalation, tappable no-core note opens the Binding); BIND CORE button deleted -> BindCoreCard ghost card in the CORE-filtered tray; NEW gate tests/smoke_layout.gd (row widths, stack height, zero controls off-frame).
- **STAGE (art-director pass):** hub-and-spoke AABB attach with ruled constants (PLUG_Y .06/PLUG_SIDE .05/SHOULDER_DROP .04/BACK_TOP_DROP .10), feet planted on a shelf line + contact shadow, dormant hollow-hex chest cavity, FOV 50 product camera with auto-framing + crop clamp, rim light + awake SOUL OmniLight, drag 0.45 deg/px + inertia exp(-3.2t), 18-deg hero yaw, awake breathing bob. NO auto-rotation ever (owner rule).
- **CARRY RIDER (owner instinct ratified + TD-countersigned):** capacity = WEIGHT_BUDGET(100) + max(0, carry) of the SEATED core; derived() exports "capacity"; PartData.carry additive; values: Bulwark +6, Pledge +4, Heartcore +2, Sunheart +4, Keystone +10 (EN 6->5), Magazine +4 (HP 36->34), Regalia +6 (EN 10->9), lent Bastion +8 / Heirloom +15; Balance meter/strain/cards/Binding copy all read dynamic capacity. smoke_contract untouched-green; smoke_builder boundary moved by design (108/4/106).
- **BRANCHING VENTURE (PokeRogue-inspired, researched then team-designed, agent-implemented):** fixed 5-step spine with JUNCTIONs at elite (pos 2) + boss (pos 4) - 2 lanes each, unique challenger + one honest modifier per lane (tailwind/second_wind/rusted/overgrown; card text = rule verbatim); 2 road templates seeded off the run seed (same box = same road, no scum); collapse-in-place choose(i); purses re-keyed pos->tier (10/25/40); NEW challengers ch[5..8]: Thornlash Briar, Quartermaster Pindrop, Seamstress Sable, Prince Gildfall (2nd boss, full Sovereign Brass); RouteBed map UI. smoke_run rewritten (32 checks), sim rewritten per-lane (24 checks) - all bands hold.
- **COMBAT JUICE + ANIMATIONS (8-lane design + critics, agent-implemented):** stage plumbing rework (world->_rig->turntable->mount/visual graph; sync()/update_damage() never tear down mid-tween; per-slot overlay flash materials - shared glb mats never touched); ms-precise beat system: plan()/play executor, 4-rung escalation ladder (hit < break < core < kill), SINGLE wind-up->lunge->impact-frame->hit-stop->recoil, MULTI as one accelerating flurry, GUARD exhale, core-hunt telegraph (loom + affinity vignette), fight-end beats incl. THE UNMAKING (soul flare->dim, parts release staggered, total stillness); parts visibly detach + tumble on break; photosensitivity caps enforced in the planner. NEW gates smoke_stage (27) / smoke_beats (59, cadence lands 590/740/800/1245ms) / smoke_audio.
- **AUDIO IS LIVE - the silence is over:** procedural synthesis path (tools/audio/make_sfx.py, stdlib, seed 7, byte-reproducible) -> 14 wavs in audio/sfx/; Sfx un-muted with 8-voice pool, pitch/pan sub-buses, ref-counted ducking, headless-inert.
- **Blender FX pack round-trip PROVEN:** work order written to design/art/fx-work-order.md; owner ran it on the second PC via Blender-MCP; 4 glbs (impact star, loose peg, hex ring, socket stub) synced back and lit up in-game exists-gated with zero code changes.
- **Sweep:** Barrow/Menagerie 44px targets, Coffer Nook empty state + cart shortcut, walnut overlay dims, BUILD_BRIEF section 13 rider v1 + 12.6 superseded note, balance-notes CARRY addendum.
- Syncthing verified 100% to GamingComputer (old 99% jam cleared). Fresh launch handed to the owner (save backed up as manabit_save.playtest1.json).
- **Owner set the next milestone: feature-ready for a public internet playtest** (title screen, settings incl. resolution/audio, pause, itch.io web + Windows export, pretty pass) - and judged the Workshop crafting UI "still terrible" aesthetically -> a 6-lane style-research expedition (Gundam Breaker/Custom Robo, Medabots/MMBN, AC6/DXM, Backpack Battles/Stacklands, Balatro/Wildfrost, Moonglow/Unpacking/CotL) is RUNNING, downloading + viewing real screenshots, synthesizing a concrete style direction.

**Decisions (with reasoning):**
- **Fit is enforced by a gate, not care:** the 720 budget has zero slack, so smoke_layout must stay in the fast list or regressions land invisibly.
- **CARRY rides the CORE (hybrid 100+bonus), never maluses:** every capacity >= 100 so the audited 80-bit weight balance survives as a conservative floor; core is the one mandatory slot so capacity there creates archetype pairing, not a must-pick. TD countersign recorded in-session; BUILD_BRIEF rider documents it.
- **Junctions collapse in place (no graph walker):** node()/advance()/can_extract keep their exact semantics - smallest safe diff on a frozen loop; road seeded off the box nonce extends crack-and-see parity to the map for free.
- **Presentation never touches resolution:** combat.perform stays sync + byte-identical (only additive last_action telemetry); the sim is the tripwire - if bands move, the juice broke the resolver.
- **Sequenced implementation agents on shared files** (map agent -> then juice agent on combat_screen.gd) - parallel edits to one file are how merges go wrong.
- **Audio = procedural synthesis over CC0 sourcing:** ships TODAY, byte-reproducible, tone-controlled; CC0 list held as fallback.
- **Owner taste calls stay owner calls:** the style direction from the research expedition gets shown for sign-off BEFORE implementation - beauty is not delegable to gates.

**Outstanding / next session:**
- **Style-research workflow (w7vps45s7 / wf_ab828f57-15f) may still be running or landed - read its synthesis, show the owner the direction summary, get sign-off, THEN implement the Workshop beauty redesign.**
- **Feature-ready milestone queued:** title screen/main menu, settings (audio sliders, reduce-motion, fullscreen/resolution, save management), pause/Escape, itch.io HTML5 + Windows export, pretty pass on all screens. Run it through the team like everything else.
- Windowed death/telegraph screenshot frames left for an owner-visible pass (headless-gated already); fx_loose_peg unwired (procedural WAX burst is the shipped break look).
- Still no git (Syncthing-only) - unchanged risk, owner go-ahead needed.
- Deferred: own-run boss-retreat asymmetry, consumables, PS1 shaders, Runewood coffer, wave-2 bench foley.

## 2026-07-18 (gameplay line: the free kit + core faucet + tray filter; project-wide dash sweep)

**What happened:**
- Loaded the real `.glb` bit meshes in - the drop-in pipeline picked up all 77/78 with zero code changes; confirmed rendering + Fettle's painted portrait.
- **THE BINDING (fixed the no-core bottleneck).** Found the smoking gun: the game had NO core faucet at all (coffers/shelf/loot are all non-core), so the 3 one-time starter cores were the only cores a save would ever see - burn them (venture/bank/death) and you were permanently locked out. Added a hold-to-bind Workshop station that mints a COMMON starter core (Ember/Bulwark/Font) for **⚙60**. Team-designed (economy + game-designer + producer).
- **TRAY FILTER/SORT (TrayToolbar).** Slot chips (All/Head/Core/Arms/Legs/Back) + Rarity + Sort (Newest/Rarity/Weight/Attack/Name); **tap a socket -> filter the tray to what fits it** (the interaction the owner asked for); warm empty states; sorts a COPY, never `player.bits`; state persists across equips.
- **THE FREE KIT, built twice.** First "Trundle" (fixed loaner + earn model). Then the owner redesigned it into the **BOX OF SCRAP** - a ROLLED gamble (`economy/box_roller.gd`): grade Dud/Rough/Fair/Keen/Gleaming, power from real catalog rarity + socket coverage + a top-power centerpiece weapon; a crack-and-see reveal panel (grade ribbon + stat sheet + bits + verdict); **seed-locked to `PlayerState.kit_box_nonce`** which advances only on commit -> same box until you run it (no free re-roll, no save-scum). Save schema **v3 -> v4** (kit counters + nonce, additive). Retired the Trundle character.
- **EARN MODEL (kept through the redesign):** WIN purses ride a run-local **satchel** (⚙10/25/40 by node; HIDDEN halving to 5/12/20 after 2 runs/day - never shown); loot capped 1 COMMON bit/run; flush only on a safe end ("Head home" replaces Extract for the kit); DEATH **spills** it; free mends; never banks; spar pays zero + auto-substitutes when the bench isn't deployable.
- **Owner-calibrated the gamble (AskUserQuestion):** (1) NEAR-GUARANTEE - Keen/Gleaming lend a stronger run-only core (`Catalog.box_core`: Bastion RARE / **Heirloom EPIC HP80**, outside the registry, gone at run end) + a guaranteed hard weapon; (2) REAL STAKES - elite/boss now **HUNT THE CORE** (`combat.ai_take_turn`: an `aims_core` foe drives a SINGLE into the core -> WIN-or-DEATH race). Sim-tuned (`tests/smoke_kit_sim.gd`, 340 seeds): **Gleaming clears elite 88% / boss 83%**, a **Dud dies**, node0 Rusty stays cozy (99% win, 0 deaths).
- **Confirmed the run-exit design** (owner asked "can players dip out?"): YES - the two Rest nodes are cash-out points that keep everything earned; only the boss is a deliberate all-or-nothing. Flagged one asymmetry (own-runs can't safely retreat AT the boss node, only at the rest before it) - owner's call, offered.
- Added `tests/smoke_kit.gd` (12 invariants) + `tests/smoke_kit_sim.gd` (power-band sim, separate from the fast list); **all 9 fast gates green** throughout.
- **Removed EVERY em-dash + en-dash project-wide** (owner directive): 4736 dashes -> hyphens across 201 files (game code, UI strings, docs, `.claude` scaffold), UTF-8 no-BOM; verified 0 remain; gates green.

**Decisions (with reasoning):**
- **Box of Scrap = roll the BITS, not a §13 stat-scale:** the catalog's COMMON->EPIC range already spans the challenger ladder, so a stronger loadout raises the derived sheet with ZERO frozen-contract impact; only new persisted field is `kit_box_nonce`.
- **No re-roll / seed-lock** (over the game-designer's diminishing-odds idea): the only path to a new box is to actually run + risk the current one - kills the scrap-printer and save-scum outright, needs no hidden UI.
- **Core-hunter AI unifies both owner calls:** a fragile box loses the core race (DEATH + spill), a beefy-core god-roll out-races it (survives + wins), node0 (no aim) stays a cozy floor. Also makes the boss deadlier for OWN-Manabit runs (owner accepted).
- **Lent "Heirloom Core", NOT the catalog's "Regalia Core":** the parallel art line added a "Regalia Core" (EPIC) on 07-16; I invented a distinct lent-only Heirloom to avoid a duplicate display name + touching parallel work. A god-roll lends a lucky salvaged soul, not the king's own. (Future: could reconcile to lend the canonical Regalia.)
- **Firewall preserved by construction:** the box builds fresh instances and never touches `player.bits`, so its bits + lent cores can't be melted/looted/banked/kept; purses stay flat; ✦0 Glimmer from kit play.
- **THE BINDING, not a shop pull:** cores are crafted souls (GDD canon) - Fettle refuses to sell them; a pure ⚙ sink (cores still melt/distill for 0 = no arbitrage), which also gives Scrap a permanent purpose.

**Outstanding / next session:**
- **Play it end-to-end** - no human playtest yet; the sim only proves combat bands. (Owner too tired tonight; this is the top next step.)
- **Audio still SILENT** - biggest felt-quality gap (seams wired, cozy palette specced in DESIGN.md).
- **No git** - Syncthing-only, zero history; `git init` is the cheapest risk reduction (needs owner go-ahead - never commit unasked).
- **Reconcile the two parallel lines** (art/Sovereign Brass vs gameplay) in the catalog; settle the Heirloom-vs-Regalia core coherence.
- Deferred design calls: own-run boss-retreat asymmetry; in-combat consumables; PS1 shaders; Runewood coffer / branching maps / more node types.
- **Convention now in force: NO em-dashes or en-dashes anywhere - hyphens only.**

## 2026-07-16 (covers 2026-07-15 + 07-16 sessions)

**What happened:**
- **Built the entire 3D art library: 80/80 bits real, ART AUDIT PASS, off-spec 0.** Blender-MCP procedural pipeline (no AI-gen service): `tools/art/manabit_bit_lib.py` (Art-Bible-as-code: family palette, rarity ladder, greebles, gloss/metal map, global bevel + weighted normals, socket collar, 1-material palette atlas, origin=socket, tri validation, glb export) + `RECIPE_GUIDE.md` + `manabit_bits_workflow.js` (agent batch runner) + `tests/smoke_art.gd` (headless per-bit audit: tris 300-2400, ≤2 draws, atlas ≤256px, origin on socket, coverage %).
- Production mix: agents built ~2 families (missed silhouettes ~half the time - hand-fixed), owner switched to **hand-build**; all remaining families hand-built with per-family ortho contact-sheet verification.
- **Gunpla quality bar** (owner feedback "flat color palettes"): grounded in `G:\Git\blender-modeling-kit\docs\MODELING.md` §2-3 + downloaded real gunpla refs; added greeble vocabulary (nozzle/bolt/fin/scribe/layer/vent_cut/mirror), edge-bevel+weighted-normals in finalize, gloss map for plated colors, tri cap 800→2400.
- **77 card icons rendered** (transparent 128px, auto-framed) - `part_card.gd` already had the drop-in hook; every card/ware/challenger row got a face with zero code.
- **Non-bit assets:** Fettle 3D portrait rendered + wired into `fettle_portrait.gd` (base image + live glow overlay kept, safe fallback); 3 coffer props + coffer-face renders wired into the Coffer Nook.
- **Studio-persona review cycle** (owner-ordered): 6-persona panel (AD/CD/UX/A11Y/GD + producer synthesis) over 15 contact sheets + 6 UI screenshots → 63 findings → applied → 4-persona re-gate confirmed 40 resolved → remaining P1s applied too.
- **UI overhaul (all DESIGN.md-token-grounded):** Warmth layer (`ui/warmth.gd`: lamp glow + walnut vignette + grain, all 7 screens); honest BalanceMeter (budget tick, hatched overflow, "SPD 14 → 4 (−10)", strain-aware bind status); brass primary buttons; ≥44px targets; perimeter slot plates (owner rule: tags never cover the toy) + stage camera z 3.7→3.05; coffer face + printed C/R/E odds + wax-seal target + honest tab states; affordability ("need ⚙N more" + dimmed BUY) on FindCard AND CofferWare; Proving = informed wager (challenger face icons, ATK/DEF/SPD/MANA rows, per-row stakes, YOUR-Manabit strip via `proving.session = workshop.session`); menagerie empty-state CTA; contrast text-tier tokens; `Tokens.slot_word()` (no ARM_L leaks); "Wake Coffers" vocabulary; parchment BarkRibbon.
- **Display font: Baloo 2** (OFL) at `art/fonts/`, applied via `Tokens.display()` to titles/nameplate/Fettle/archetype; recorded in DESIGN.md §2.
- **Sovereign Brass +3 bits (catalog 77→80):** Herald Crown (HEAD RARE GUARD), Regalia Core (CORE EPIC defense - first EPIC core), Colonnade Greaves (LEGS RARE); stats budgeted against printed peers; manifest entries added.
- **Mesh surgery (16 rebuilds):** visible socket collars on 13 flagged bits; chatterbox notion-pack → faceless satchel + pod feet-nubs + chunky skitter legs; pith warmer + bigger rose-within + rim bands (SSS approximation); whirligig cobalt rune separated from cyan (line-vs-dot); silksteel heads tapered + filigree lines; grinlet face de-creeped (dot eyes + smile).
- **Verified throughout:** 8/8 smoke gates green after every change wave; final 80/80 audit PASS; `tests/shoot.gd` extended to screenshot all 6 screens (windowed) for visual verification; Syncthing confirmed pushing everything to NewPC (folder `my-game-dotclaude`, 100% complete).

**Decisions (with reasoning):**
- **Blender-MCP procedural over AI text-to-3D:** bits are deliberately chunky/boxy (procedural's sweet spot); free, deterministic, spec-legal by construction; the modeling kit's own ladder parks AI-gen for organics.
- **Hand-build over agent fan-out for meshes:** cold agents nailed detail but missed the overall silhouette ~50% (arm→totem, back→figurine); the form IS the product.
- **Gloss-not-metal for plated colors:** true metallic reflects a dim environment → dark bronze; glossy-dielectric keeps bright toy-gold under any lighting.
- **"Fix the rig, not 77 atlases":** the panel's palette-drift findings were the contact-sheet render rig (dim world + filmic tonemap); bright rig + Standard view transform shows bible-true colors. Atlases bake literal bible hexes.
- **Baked look in the glb; material still named `mana_glow`:** the live loader instances glbs RAW (the docs' re-tint seam is planned, not built) - naming keeps the future seam free.
- **Rejected 2 panel findings with citation:** tinbox blue knee band (manifest spec'd cornflower); "phantom equipped duplicates" (tray only shows loose inventory).
- **Baloo 2 as display face:** chunky/rounded = "collectible toy box", legible at header sizes, OFL.
- **Regalia Core is the catalog's only EPIC core on purpose:** gives Brassmore's house a crown piece without inflating every family.
- **GDScript indentation:** never mix tabs into a space-indented file - a parse error silently blanks the whole UI; smoke gates don't instantiate root.tscn, only shoot.gd catches it.

**Outstanding / next session:**
- **Audio still SILENT** (seams wired, no foley) - now the biggest polish gap.
- Deferred UI: BESTED stamps (needs save-schema), hex-shaped slot plates, rarity rim + HP pips on slot plates, coffer glb-in-SubViewport (props exist, 2D face used instead).
- Balance/playtest pass on the now-80-bit roster; PS1 render shaders (vertex-jitter/affine) still deferred.
- Challenger loadouts could adopt the new sovereign bits (Brassmore currently fields mixed EPICs, not his house set).

## 2026-07-14

**What happened:**
- Reviewed the downloaded GDD (`BUILD_BRIEF.md`) via multi-agent adversarial review; wrote + **Godot-verified the §13 Frozen Contract** (`PartData`/`AbilityData`/`PartInstance`/`ManabitState`+`derived()` + the 3 fight outcomes + save schema; `smoke_contract` green).
- Stood up the project at `G:\ClaudeApps\manabit` as a Godot 4.7 project with the studio `.claude/` team (49 agents, 72 skills copied from Hollowmere).
- Built the **M0 builder**: Workshop (anatomical socket rig + mana-thread leader lines + composite low-poly bit meshes + core-wake glow; drag/tap, live Ledger deltas + Balance/strain + auto-archetype, snap juice) · Coffer Nook (Tin/Brass + press-hold "Waking" ritual) · Menagerie (+ click-to-inspect detail view) · Compendium (bit-dex %). Persistence via `SaveManager` (JSON, v2 + v1 migration).
- Built the **economy - The Barrow / Fettle's Cart** (team-designed): two currencies (Scrap/Glimmer firewall), Melt/Still/Doorstep faucets, Today's Finds; then juiced it (odometer, wax stamp, toasts, Fettle reactions).
- Built **M1 combat** (turn-based part-targeted resolver + combat screen with 3D fighters) + **M2 consequences** (Proving Grounds bouts: win-loot / loss-forfeit) + **M3 run** (Venture → 5-node map, no-auto-heal, repair, extraction, DEATH stakes). Added **combat juice** (damage numbers, recoil, flash, BROKEN! burst).
- Expanded the catalog to **77 bits across 15 pop-culture-mecha style-families** (team-authored, balanced to a stat-budget model), loaded from `parts/catalog_extra.json`; kept 13 base fixtures. Added 5 challengers (Scrap-Pup→Cogsworth→Brassmore). Applied **family-palette tinting** to placeholders.
- Built the **drop-in art pipeline** (`art/bits/<id>.glb` + `art/icons/<id>.png` by filename, procedural fallback - proven live) + landing zone; team produced the **art bible + 77-prompt asset manifest + 12-batch priority** (`design/art/`).
- **8 headless smoke gates all green** (contract/builder/persist/broker/combat/bout/run/catalog).
- Mirrored the design docs + 19 screenshots into the Obsidian vault at `Projects\MANABIT\`.

**Decisions (with reasoning):**
- **Base 13 bits stay hardcoded (base wins id collisions), team's 64 load from JSON:** keeps smoke-test / demo / dummy fixtures deterministic against a growing catalog.
- **Spar/bout fight a CLONE; a run fights the REAL carried Manabit:** M2 gets stakes without needing a repair economy; M3 delivers real persistent-damage push-your-luck.
- **Fettle = "the first Manabit":** makes the shop cozy AND diegetically enforces the combat-loot firewall (refuses spoils torn off a living Manabit).
- **Two currencies (Scrap + Glimmer), firewalled:** stops grinding from buying the exact missing EPIC - protects the collection chase.
- **Art = drop-in-by-filename + permanent procedural fallback:** real art lands one bit at a time, zero code edits.
- **Terminology (owner):** bit = piece, Manabit = whole robot; opening chests is a SEPARATE screen from assembly.

**Outstanding / next session:**
- Actual **art production** (meshes/textures per the manifest prompts) - external to code.
- **Audio**: SFX seams wired but SILENT (no foley assets).
- Hands-on **balance/playtest** pass on the 77-bit roster.
- Optional: PS1 render shaders; the designed-but-deferred Runewood coffer; in-combat consumables.
- **No git** - project is Syncthing-only (backup/history risk); consider `git init`.
