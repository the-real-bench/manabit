# MANABIT Balance Wave 1 - Change Order

STATUS: COUNCIL-RATIFIED 2026-07-19, wave 1 of the autonomous depth loop

Producer reconciliation of the three-lane balance council (Lane 0 catalog/roster, Lane 1 economy,
Lane 2 QA verification). Ruling principle, applied without exception: a change ships in wave 1 only
if every number justifying it carries a QA TRUSTWORTHY verdict. Anything resting on a SUSPECT number
is deferred to the wave 2 measurement pass, no matter how convincing the story. Nerfs to measured
over-performers are treated as asymmetric-risk-safe; buffs and structural reworks are not.

Bounded scope honored: `parts/catalog_extra.json` stats, `combat/challengers.gd` loadouts, economy
constants in their existing homes. One explicitly flagged exception: CH-08/CH-09 touch the bout
resolution block of `ui/combat_screen.gd`, ratified because both Lane 1 and Lane 2 marked the
Proving-bout printer as the single highest-severity finding and Lane 2 scoped it as one bounded
edit with zero section 13 impact.

Hard laws restated for the implementer: never touch the 13 base fixture bits, section 13 contract
classes, `combat/combat.gd` resolution, or the save schema. Re-run all 14 fast gates plus
`tests/smoke_kit_sim.gd` plus `sim_roster.gd` and `sim_ladder.gd` on the SAME seeds after landing.

---

## A. SHIPPED CHANGES (10)

### CH-01 - Meteor Knuckle stat shave
- File: `parts/catalog_extra.json`, id `boldheart_arm_meteor`
- Change: `"attack": 9` -> `"attack": 8`; `"max_hp": 9` -> `"max_hp": 8`
- Keep: the p9 SINGLE signature swing and mana 4 cost untouched.
- Justified by: mean_delta +26.4% (n=480-600, direction TRUSTWORTHY, not on QA's magnitude block
  list) plus the TRUSTWORTHY ladder reading that its carrier Brassmore sits at 0.132 player win
  inside a 71.9% boss death rate.
- Success (re-measure): boldheart_arm_meteor mean_delta <= +20% on the same-seed roster re-run;
  Brassmore player win moves 0.132 -> 0.15-0.20 in sim_ladder Part A.

### CH-02 - Regalia Core defense trim
- File: `parts/catalog_extra.json`, id `sovereign_brass_core_regalia`
- Change: `"defense": 4` -> `"defense": 3`
- Justified by: mean_delta +23.1% as the only EPIC core in the swingiest slot (CORE slot mean
  +9.6%), plus its wearer Prince Gildfall at 0.170 player win creating the 0.212 Cogsworth to
  Gildfall difficulty cliff (ladder, TRUSTWORTHY).
- Success: mean_delta <= +18%; Gildfall player win 0.170 -> 0.19-0.25; the Cogsworth to Gildfall
  cliff shrinks to <= 0.18.

### CH-03 - Pistonfist wall-arm trade
- File: `parts/catalog_extra.json`, id `sovereign_brass_arm_pistonfist`
- Change: `"defense": 4` -> `"defense": 2`; `"max_hp": 10` -> `"max_hp": 14`
- Justified by: mean_delta +20.0%; def 4 on an arm is the catalog outlier (an arm should not be a
  wall AND a p7 hammer). Net -2 authoring points, stays inside the RARE band.
- Success: mean_delta <= +15%; contributes 2-3pp of the Gildfall movement in CH-02's criterion.

### CH-04 - Ziptie softened to a real rung-2 regular
- File: `combat/challengers.gd`, Whirl-Kid Ziptie loadout (line 17)
- Change: delete the entry `["ARM_L", "everykit_standard_piston"]` (6-slot build -> 5-slot build)
- Justified by: ladder player win 0.441, out-harding elites Thornlash 0.615, Vance 0.632, Sable
  0.823 (TRUSTWORTHY, large separations); mean 2.73 parts broken vs cheap builds.
- Success: Ziptie player win 0.55-0.70; regular ordering Rusty > Ziptie > Vance monotonic within
  3pp noise; mean parts broken vs cheap builds <= 2.0.

### CH-05 - Sable gets teeth
- File: `combat/challengers.gd`, Seamstress Sable loadout (line 56)
- Change: `["BACK", "everykit_standard_cell"]` -> `["BACK", "pith_sinew_deep_pulse_sac"]`
- Justified by: 0.823 player win / 0.038 death at n=288 (TRUSTWORTHY, many SE from the 0.38-0.62
  elite band); QA confirmed a Sable buff is lens-safe (the AI floor already reads too easy; human
  play only softens her further). Precedent: the same self-mend pack is on Thornlash and Brassmore.
- Success: Sable player win <= 0.70; death rate >= 0.05.

### CH-06 - Pindrop learns to kill
- File: `combat/challengers.gd`, Quartermaster Pindrop loadout (line 50)
- Change: `["HEAD", "chatterbox_bigeye_dome"]` -> `["HEAD", "grumble_co_anvil_cowl"]`
- Justified by: code-certain finding that his loadout has zero SINGLE moves, so the elite
  core-hunt branch (requires archetype SINGLE) can never fire and his death rate is 0.000 by
  construction. Anvil Cowl is SINGLE p3 cost 1 with can_target_core, HEAD slot compatible.
- Producer note: QA's HEAD swap chosen over Lane 0's ARM_L weefist swap because it preserves both
  MULTI arms (his part-shredding identity) and the warder GUARD bit for any future AI fix.
- Success: Pindrop death rate 0.000 -> >= 0.05 (expected band 0.10-0.38 per comparable core-aiming
  elites); player win stays 0.38-0.50.

### CH-07 - Overgrown lane inversion fix
- File: `combat/challengers.gd`, Thornlash Briar mods (line 44)
- Change: `"mods": {"overgrown": [["BACK", "boldheart_back_rocketspine"]]}` ->
  `"mods": {"overgrown": [["ARM_R", "thicket_fang_arm_flenseclaw"]]}`
- Justified by: paired-seed modifier experiment (QA: cleanest instrument of the wave) showing the
  shipped swap makes the menace lane EASIER by +20.3pp for mid builds because it strips Deep-Pulse
  Sac (self-mend, def). The new swap upgrades gnashmaw to the EPIC Flense-Claw while keeping his
  sac and defense.
- Producer note: with CH-D1 (thicket shave) deferred, Flense-Claw is still hit_count 5, so this
  lane may land harder than Lane 0's -5 to -10pp prediction. Acceptable for a menace lane; bounds
  in the criterion below. Re-point this swap if the wave 2 thicket shave lands.
- Success: overgrown delta for mid builds lands between -20pp and 0pp player win vs the clean
  fight (never again positive).

### CH-08 - Proving bout stake
- File: `meta/player_state.gd` (new consts beside `BIND_CORE_COST`, the economy-constant home) +
  deduction in `ui/combat_screen.gd` `begin_bout` (line 126)
- Change: add `BOUT_STAKE_REGULAR := 5`, `BOUT_STAKE_ELITE := 10`, `BOUT_STAKE_BOSS := 20`;
  charge the stake (non-refundable) when a bout begins; Proving Grounds rows gate on
  affordability using the existing dim + "need N more" cue pattern.
- Justified by: triple code-confirmed riskless-printer shape (TRUSTWORTHY): bouts are fought on a
  clone (combat_screen.gd:133), the foe never aims the core (`_start(false)`, line 135, death
  impossible), zero entry cost, no daily cap - versus a kit purse capped at 75/run full, 37
  halved. Lane 1's EV floor: Brassmore bout >= +22.5 scrap uncapped at a 0.5 win prior, and QA
  notes real win rates are plausibly far above 0.5.
- Success: Brassmore bout EV at the 0.5 prior falls to <= +5 scrap; ladder v2 Part C (below)
  prices the true human-proxy EV before any further tuning; smoke_bout stays green (update the
  fixture wallet if the stake trips an assertion - the assertion is about flow, not the price).

### CH-09 - Bout forfeit pays zero salvage
- File: `ui/combat_screen.gd`, `_forfeit` (lines 1149-1153)
- Change: in BOUT context (`_kit_run == null`, `_stakes == true`), stop paying
  `Broker.salvage_scrap` on the forfeited bit - banner keeps the loss message, scrap line removed.
  The kit-run branch (already pays 0, line 1144: "kills throw-the-fight salvage farming") is the
  in-repo precedent.
- Justified by: QA code-certain finding that a survivable loss forfeits a broken bit AND pays the
  PLAYER its salvage, closing the loss-side floor of the printer (losing a junk bit was strictly
  free melt income plus a free shot at loot).
- Escape clause: if `smoke_contract` (frozen, section 13) rather than `smoke_bout` asserts the
  forfeit salvage payment, DO NOT ship CH-09 - ship CH-08 alone and move this to the deferred
  list. The section 13 freeze outranks this order.
- Success: bout survivable-loss net scrap is <= 0 (stake lost, no salvage); no change to kit-run
  forfeit behavior.

### CH-10 - Honest compendium denominator (80 -> 73)
- File: `meta/player_state.gd`, `compendium_total()` (lines 224-225)
- Change: `return Catalog.all().size()` (evaluates to 80) -> count that excludes cores which are
  neither in `BINDABLE_CORES` nor player-obtainable (evaluates to 73). Implement as a filter on
  `is_core` + obtainability, not a magic number, so future catalog growth stays honest.
- Justified by: code-verified (TRUSTWORTHY): 7 of 10 cores are unobtainable (Fettle never sells
  cores, coffers never roll them, only 3 are bindable), so 100% completion is literally
  impossible and day-30 p50 completion reads 75% when the true ceiling is 82%.
- Success: displayed compendium ceiling is reachable 100%; day-30 p50 completion reads ~82%
  (60/73); zero movement in any economy sim metric (display-only change).

## B. RATIFIED NON-CHANGES (decided, not deferred)

- Kit purses 10/25/40 with hidden halving after 2 runs/day: UNTOUCHED. The flat 30-day scrap curve
  (p50 91 -> 90, faucet/sink surplus 1.8%) is the healthiest number in the audit.
- Melt 8/20/45, Still 1/3, Tin 40, Brass 100: UNTOUCHED. Anti-arbitrage holds (tin floor ~35, the
  4.5-5.0 glimmer-to-scrap leak is one-way and 90% lossy round-trip).
- No buff or nerf to grinlet, slab_pauldron, whisper, or oracle: they are measured at the AI-lens
  floor (the shipped AI never GUARDs while offense is affordable and never core-aims player-side);
  their current numbers are stat-stick floors, not values.
- No rarity-band repricing: COMMON +2.1% / RARE +6.8% / EPIC +8.7% is monotonic and healthy; the
  sickness was per-bit variance, addressed above and in the deferred nerfs.

## C. DEFERRED (blocked on measurement, scope, or frozen schema - wave 2 queue)

1. D1 - Thicket hit-count shave (goreclaw 4 -> 3, flenseclaw 5 -> 4). Pentagon verdict is QA
   SUSPECT (half lens artifact, half undersampled: thicket>boldheart 0.600 and thicket>whirligig
   0.583 are ~1-1.5 SE from a coin flip at n=60; the 0.925/0.850 edges are inflated by the
   GUARD-never-fires and no-core-aim floors on grumble and silksteel). PRE-RATIFIED to ship in
   wave 2 without a new council IF roster v2's 200-seed core-aiming pentagon still shows thicket
   >= 0.75 on 3+ intended-counter edges.
2. D2 - Bedrock Legs trade (def 6 -> 5, hp 26 -> 28). QA explicitly blocked tuning to the +34.0%
   magnitude (floor-repair inflation on dead templates: +0.60/+0.56 on Sniper/Tempo vs +0.05 on
   Wall). Unblocks on roster v2 template-conditioned deltas + the greatest-hits build row.
3. D3 - Girder Fist def 2 -> 1. Same block as D2 (+19.1% is a SUSPECT magnitude). The commons-
   never-dominate law violation is real in direction; size it from roster v2.
4. D4 - Light-axis HP floors (weefist 8 -> 12, slip 10 -> 12, needle 8 -> 10). QA blocked all
   silksteel buff-nerfs and the bottom-10 dead list until the core-aiming + GUARD player lens
   runs; weefist also just joined Pindrop-adjacent scrutiny. Palliative only regardless - the
   real fix is D11.
5. D5 - BIND_CORE_COST 60 -> 45 (`meta/player_state.gd:25`). The justifying numbers (binding =
   69% of sinks, 37.6% core-locked players) are linear in economy_sim's 0.5 ventures/session
   appetite, which QA marked SUSPECT (contradicted 1.5-4x by ladder lane_observational rates).
   Unblocks on economy v2 re-anchored priors.
6. D6 - Own-build venture purse 5/12/20 at half kit rate. Built on SUSPECT economy.json venture
   numbers AND a new payout path (beyond constants-in-existing-homes). Unblocks on economy v2.
7. D7 - Daily bout-win loot cap (2-3 wins/day then zero loot). The load-bearing half of the bout
   throttle, but a persisted daily counter touches the FROZEN save schema. Bundle with save v5;
   size from ladder v2 Part C. Until then CH-08/CH-09 are the throttle.
8. D8 - Fettle's Special (4th daily shelf slot, unowned-weighted, 6/15 glimmer + 30 scrap).
   Evidence TRUSTWORTHY (glimmer: 57 earned / 0 spendable, code-verified dead currency) but it is
   a new shop feature, out of wave 1 bounded scope. Queue as the headline of the next feature
   wave; melt-back check already passed (3.0 scrap/glimmer < the existing 4.5 leak).
9. D9 - PackRoller per-save seed + pity persistence (save v5, additive). Save schema is FROZEN -
   OWNER escalation. Until then every player shares one deterministic coffer stream (seed
   20260711, `meta/player_state.gd:35`), relaunch-scummable, pity resets every boot.
10. D10 - Sable/Rusty ordering (0.854 vs 0.823): inside noise, no action ever ratified.
11. D11 - ESCALATION to the combat lane: speed needs a resolver payoff beyond initiative. The
    Sniper row at 0.00/0.00/0.03/0.00 and Tempo at 0.0/0.0/0.0/0.6 are TRUSTWORTHY and
    structural; no catalog nudge can fix a dead axis. Needs an ADR against the section 13 freeze.
12. D12 - ESCALATION to the run/encounter team: tailwind (+0.0pp in all cells) and second_wind
    (worth 1.3-2.0 scrap) are dead RunMods rules; junction choice is currently two nothings, a
    trap-label, and a discount. Lives in RunMods, outside this order's scope.
13. D13 - ESCALATION to the combat lane: shipped combat.gd has no turn cap and wall-vs-wall
    fights ran 155-166 mean actor turns with 66 cap-600-insensitive stalemates in the ladder.
    Resolution-rule change = frozen; needs the same ADR pass as D11.

## D. INSTRUMENT FIXES (QA-ordered, run BEFORE the wave 2 council)

- ROSTER v2 (`tools/sim/sim_roster.gd`): (a) player-side core-aiming policy toggle (take the best
  affordable can_target_core SINGLE when it out-damages the part-break line) plus a
  GUARD-when-behind heuristic; (b) per-pair stall counts emitted in family_matrix and
  baseline_matrix (resolves the suspicious exact-0.500 grumble cells); (c) 200 seeds on the 20
  pentagon cells; (d) one cross-family greatest-hits row (Regalia Core + Bedrock Legs +
  Pistonfist + Girder Fist + Herald Crown). Unblocks D1-D4.
- LADDER v2 Part C (`tools/sim/sim_ladder.gd`): bout mode - all 9 challengers with
  aims_core=false vs a core-aiming player proxy, 6 archetypes x 48 seeds; output EV scrap/bout
  and turns/bout. Sizes D7 and audits CH-08/CH-09.
- ECONOMY v2 (`tools/sim/economy_sim.py`): re-anchor venture win/death priors to ladder.json
  lane_observational rates with a +10pp/+20pp human-uplift sensitivity band; add the Part C bout
  module. Unblocks D5-D6; hold total faucet/sink imbalance under 5% on any follow-up.
- All sims: deterministic seeded RNG only, read-only on game state, never touch user:// saves,
  JSON to `G:\ClaudeApps\manabit\tools\sim\out\` plus a printed human summary.

## E. VERIFICATION GATE (wave 1 exit criteria)

Run after landing CH-01..CH-10, same seeds as the council wave:
`sim_roster.gd` + `sim_ladder.gd` + `tests/smoke_kit_sim.gd` + all 14 fast gates, every run exit 0.

PASS requires ALL of:
1. 13 base fixture bits byte-identical; section 13 classes, combat.gd, save schema untouched.
2. Touched bits: meteor mean_delta <= +20%, regalia <= +18%, pistonfist <= +15%; no touched bit
   goes NEGATIVE beyond -5% (over-correction check).
3. Regulars monotonic: Rusty > Ziptie > Vance player win, within 3pp noise; Ziptie 0.55-0.70.
4. Every elite death rate >= 0.05; Pindrop death rate > 0 with win 0.38-0.50; Sable win <= 0.70.
5. Overgrown delta for mid builds between -20pp and 0pp (never easier than the clean lane).
6. Gildfall player win 0.19-0.25; Brassmore 0.14-0.20; tier ordering regular < elite < boss holds.
7. Bout: stake charged, forfeit pays 0 (or CH-09 escape clause invoked and logged), Brassmore
   bout EV at the 0.5 prior <= +5 scrap.
8. Compendium ceiling reachable 100% (denominator 73); zero drift in economy sim headline
   (30-day p50 wallet 85-95, faucet/sink imbalance < 5%).

Any single failure: revert the offending CH, re-run the gate, and log the miss in this file
before the wave 2 council convenes.

---

## F. WAVE 1 IMPLEMENTATION LOG (2026-07-19, implementer pass)

SHIPPED: CH-01, CH-02, CH-03, CH-04, CH-07, CH-08, CH-09, CH-10.
REVERTED: CH-05, CH-06 (both moved their own success criteria the WRONG WAY; details below).
CH-09 escape clause NOT triggered: smoke_contract carries no forfeit-salvage assertion (its
survivable-loss test asserts the disabled-part shape only) and stayed green after the edit.

Gates after landing + reverts: smoke_catalog / smoke_kit / smoke_combat / smoke_bout /
smoke_run / smoke_broker / smoke_contract all SMOKE PASS exit 0; tests/smoke_kit_sim.gd
SMOKE PASS exit 0 (re-run after the reverts); sim_roster + sim_ladder + economy_sim all
exit 0, outputs in tools/sim/out/ (pre in *-pre.json, post in *-post.json).

Instrument v2 work (section D) landed additively: roster v2 (core-aiming + GUARD-when-behind
policy, per-pair stall counts on baseline_matrix + family_matrix, 200-seed pentagon_v2,
greatest-hits row), ladder v2 Part C bout mode (part_c_bout), economy v2 (bout_ev_module +
ladder-anchored venture-prior sensitivity at +0/+10/+20pp; primary headline kept on legacy
priors for this wave's pre/post compare). v1 measurement paths and seeds untouched.

Criteria, pre -> post, verdicts:
1. Fixtures/section 13/combat.gd/save schema untouched - MET (smoke_catalog "base fixtures
   preserved" PASS; no edit touched those files).
2. meteor +26.4% -> +10.8% (<= +20) MET; regalia +23.1% -> +17.4% (<= +18) MET;
   pistonfist +20.0% -> +16.5% vs <= +15 NOT MET (moved the right way, nerf undershot by
   1.5pp; kept - reverting would re-fail the criterion at +20.0%); no touched bit negative
   beyond -5% MET.
3. Regulars monotonic Rusty 0.854 > Ziptie 0.743 > Vance 0.622 MET; Ziptie band 0.55-0.70
   NOT MET (0.743, overshot high from 0.441; kept - revert restores the 0.441 inversion);
   Ziptie parts broken vs cheap builds 2.73 -> 1.60 (<= 2.0) MET.
4. Elite deaths: Cogsworth 0.656, Thornlash 0.392 MET; Pindrop 0.000 NOT MET (CH-06
   REVERTED: the swap made his win rate jump 0.438 -> 0.694, far out of the 0.38-0.50 band -
   the shipped elite AI branch prefers ANY SINGLE into the core, so the p3 Anvil Cowl
   replaced his MULTI identity entirely; post-revert 0.431/0.000); Sable win <= 0.70 NOT MET
   (CH-05 REVERTED: Deep-Pulse Sac swap moved her the WRONG WAY, 0.823 -> 0.875 win /
   0.059 death - losing the Standard Cell's mana starves her needle offense more than the
   mend adds; post-revert 0.823/0.038). Both need a different lever in wave 2.
5. Overgrown mid delta +20.3pp -> -42.2pp: "never again positive" holds, but the -20pp..0
   band is NOT MET (overshot hard; the producer note predicted harder-than-forecast with D1
   deferred - Flense-Claw still hit_count 5. Kept per the menace-lane note; re-point with
   the wave 2 thicket shave).
6. Gildfall 0.170 -> 0.128 vs 0.19-0.25 NOT MET; Brassmore 0.132 -> 0.125 vs 0.14-0.20
   NOT MET; cliff 0.212 -> 0.191 vs <= 0.18 NOT MET (improved). IMPORTANT CONTROL READ:
   Cogsworth, who carries NO changed bit, dropped 0.382 -> 0.319 (-6.3pp) - the player-side
   build generators seat the same nerfed bits (meteor centerpiece, regalia flagship core),
   so ALL hard rungs read harder post-nerf. Control-adjusted, the foe-side effects moved the
   intended way (Brassmore +5.6pp, Gildfall +2.1pp relative). The absolute bands assumed a
   foe-side-only lens; carry this to the wave 2 council rather than reverting nerfs whose
   primary (roster) criteria are MET. Tier ordering: elites > bosses MET; regulars > elites
   still NOT MET (Sable 0.823, pre-existing).
7. Stake charged in begin_bout (5/10/20 by tier), Proving rows gate with dim + "need N
   more"; bout forfeit pays 0; Brassmore EV at the 0.5 prior = 0.5*45 - 20 = +2.5 (<= +5)
   MET; measured (ladder Part C, core-aiming proxy): Brassmore bout win 0.052, EV -17.7.
   Only Ziptie remains bout-EV-positive at +10.8 scrap (flagged for D7 sizing).
8. Compendium denominator 73, 100% reachable MET; day-30 p50 completion 60/73 = 82% MET;
   economy headline day-30 p50 scrap 90 -> 90, faucets 2299 vs sinks 2258 (1.8% < 5%) MET.

Implementation note on CH-09 scope: own-build VENTURE forfeits (run_mode) still pay salvage;
the zero-salvage rule keys on bout context (stakes on, not a run, not a kit run). The order's
parenthetical (_kit_run == null, _stakes == true) would also have caught venture forfeits,
which its own success criterion ("no change to kit-run forfeit behavior", venture salvage
modeled as a live faucet in both sims) contradicts.
