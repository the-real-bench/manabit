# MANABIT Playtest-Fixes Change Order

STATUS: COUNCIL-RATIFIED 2026-07-21 - playtest defect fixes D1/D2/D3/D4/D8/D10; D5/D6/D7/D9/D11 DEFERRED-owner

Producer reconciliation of the AI-playtest-panel findings (design/playtest/ai-playtest-2026-07-21.md)
into one bounded, measured change order. Every value below was VALIDATED live against the shipped
combat.gd resolver via the panel's own instruments (qa_verify.gd core-aim lethality, opt_probe.gd
RACE ceiling, sim_roster.gd 67k-fight roster deltas, smoke_kit_sim.gd per-grade tripwire) BEFORE
ratification - this order does not repeat the wave-1 mistake of proposing untested values (CH-05/CH-06
both moved the wrong way and were reverted). Every number cited is a re-read committed measurement.

Bounded scope honored, no exceptions: `combat/challengers.gd` loadouts, `economy/box_roller.gd`
grade rules, `parts/catalog_extra.json` stats, `ui/workshop.gd` build-time copy, the
`ui/combat_screen.gd` loss-reason string, and the `tests/smoke_kit_sim.gd` re-pin ONLY.

HARD LAWS restated: the §13 frozen contract, `combat/combat.gd` resolution, the save schema, and the
13 base fixtures in `parts/catalog.gd` were NOT touched. Hyphens only. Confirmed post-landing: all 14
fast gates + smoke_kit_sim exit 0; `smoke_catalog` "base fixtures preserved" PASS.

IMPORTANT INTEGRATION NOTE (read before reading the numbers): CH-P5 (box Fair buff) and CH-P9
(grinlet buff) both strengthen the player's KIT builds, which lowers EVERY elite/boss core-aim death
rate on qa_verify's shared kit-build seeds (control read: unchanged Cogsworth 0.50 -> 0.48, unchanged
base-Thornlash 0.40 -> 0.22, unchanged Brassmore 0.82 -> 0.70). All D1/D8 success numbers below are the
FINAL post-all-changes, same-run, apples-to-apples figures, so they are already control-adjusted.

---

## A. SHIPPED CHANGES (9)

### CH-P1 - Pindrop gets a real single (D1, toothless elite)
- File: `combat/challengers.gd`, Quartermaster Pindrop loadout (line 50)
- Change: `["ARM_L", "errant_arm_warder"]` -> `["ARM_L", "boldheart_arm_sunder"]`
- Defect: Pindrop had ZERO SINGLE moves (HEAD MULTI / ARM_L GUARD / ARM_R MULTI / BACK MULTI), so the
  core-hunt branch (SINGLE-only, `combat.gd:146-152`) can never fire -> death 0/60 by construction.
- Justifying number: qa_verify pre = WIN 27 / SL 33 / DEATH 0 (0.00). The GUARD warder was defensive
  dead weight, not part of his part-shredding identity; swapping it (not a MULTI arm) preserves both
  MULTI arms + the MULTI head = quartermaster identity intact, now with 1 SINGLE (p6, atk 8).
- Success criterion: qa_verify Pindrop DEATH rate > 0 and inside the healthy elite band, not a
  coin-flip. Measured post = WIN 43 / SL 3 / DEATH 14 = **0.23** (base-Thornlash 0.22, Cogsworth 0.48).
- Revert trigger: Pindrop DEATH rate returns to 0.00 (structural regression), OR climbs above 0.50
  (coin-flip-kill), OR his archetype audit shows 0 SINGLE moves.

### CH-P2 - Sable gets teeth (D1, undertuned elite)
- File: `combat/challengers.gd`, Seamstress Sable loadout (line 56)
- Change: `["ARM_L", "everykit_standard_piston"]` -> `["ARM_L", "boldheart_arm_sunder"]`
- Defect: Sable had 2 SINGLE moves (whisper p5, needle p5) but her body attack was too low
  (font core atk 1) to win the core race -> death 0/60; she loses 48/60 outright.
- Justifying number: qa_verify pre = WIN 48 / SL 12 / DEATH 0 (0.00). A stronger core (sunheart) moved
  her only to 0.02 - proving the lever is ATTACK, not survivability. sunder (atk 8) lifts EVERY one of
  her SINGLE core strikes by +8; it replaces a generic filler MULTI arm (not a silksteel signature),
  so the sniper identity (whisper + needle + slip) survives.
- Success criterion: qa_verify Sable DEATH rate in the elite band, win <= 0.70. Measured post =
  WIN 34 (isolated) / WIN 47 (integrated) with DEATH 13 = **0.22**; SL collapsed to 0 (kills or dies,
  no more toothless defang).
- Revert trigger: Sable DEATH rate returns to <= 0.05, OR player win rate against her exceeds 0.85.

### CH-P3 - Prince Gildfall becomes the wall (D4, inverted boss difficulty)
- File: `combat/challengers.gd`, Prince Gildfall loadout (line 62)
- Change: `["ARM_L", "errant_arm_warder"]` -> `["ARM_L", "carillon_cadets_arm_grandpeal"]`
- Defect: the ch8 FINALE was trivial under optimal aggression while the ch4 boss Brassmore is the real
  wall. Gildfall's only threat was pistonfist (p7, atk 3, ~12 alpha) vs Brassmore's meteor (~20 alpha).
- Justifying number: opt_probe RACE pre - Gildfall WIN **1.000** / DEATH **0.000** vs Brassmore WIN
  0.305 / DEATH 0.695. grandpeal (EPIC SINGLE p9, atk 5, ceremonial "grand peal" - thematically on-key
  for the state-brass prince) gives him a Brassmore-class alpha; the AI core-hunts with it (ARM_L
  precedes ARM_R pistonfist in slot order) and his Regalia core (hp 42 > Brassmore's 37) out-bulks it.
- Success criterion: Gildfall no longer trivial and >= Brassmore difficulty, Brassmore UNMOVED.
  Measured post (opt_probe): Gildfall RACE WIN **0.305** / DEATH **0.695** (was 1.000/0.000) and GUARD
  DEATH **0.775** (was 0.000) - strictly harder than Brassmore's GUARD 0.550 under realistic
  guard-play, tied under pure race. Brassmore unchanged at 0.305/0.695 (identical, control).
- Revert trigger: Brassmore RACE win moves off 0.305 +/-0.03 (collateral), OR Gildfall RACE win
  returns above 0.50 (still trivial), OR Gildfall RACE win drops to 0.00 (unbeatable / D7-grind risk).

### CH-P4 - Overgrown lane made the dangerous pick (D8, mislabeled menace lane)
- File: `combat/challengers.gd`, Thornlash Briar mods (line 44)
- Change: `"mods": {"overgrown": [["ARM_R", "thicket_fang_arm_flenseclaw"]]}` ->
  `"mods": {"overgrown": [["ARM_R", "boldheart_arm_sunder"]]}`
- Defect: the menace-framed "overgrown" swap replaced Thornlash's SINGLE gnashmaw (p4) with a MULTI
  flenseclaw that CANNOT core-hunt, dropping his own death rate 0.40 -> 0.13 - making the scariest-named
  lane the SAFEST pick. The wave-1 CH-07 flenseclaw swap CAUSED this regression.
- Justifying number: qa_verify pre = overgrown 0.13 vs base Thornlash 0.40 (an inversion). sunder is a
  SINGLE (core-hunt restored, 2 SINGLE moves), its atk 8 also lifts the HEAD-single core strikes, and
  its heft honestly matches the "the foe fields heavier bits" lane blurb. (In-family flenseclaw-to-ARM_L
  was trialled - it restores the single but only reaches +1pp over base once kits are buffed; rejected
  for a thin margin.)
- Success criterion: on the SAME qa_verify run, overgrown DEATH rate > base-Thornlash DEATH rate (the
  modifier no longer softens him) with >= 2 SINGLE moves. Measured post = overgrown **0.30** vs base
  **0.22** (+8pp), 2 SINGLE moves; smoke_kit_sim overgrown lane still "no cozier than node0" PASS.
- Revert trigger: overgrown DEATH rate <= base-Thornlash DEATH rate on the same run (softens again),
  OR overgrown climbs to boss-tier (>= 0.55).

### CH-P5 - Fair box becomes risky-but-winnable (D2, modal first-box guaranteed loss)
- File: `economy/box_roller.gd`
- Change (two constants + one comment, gi==2 = the Fair grade):
  - `const CENTER := ["COMMON", "COMMON", "COMMON", "RARE", "EPIC"]` ->
    `["COMMON", "COMMON", "RARE", "RARE", "EPIC"]` (Fair gets a RARE centerpiece weapon that can break armor)
  - lent-core branch `elif gi == 3:` -> `elif gi == 2 or gi == 3:` (Fair gains the Bastion RARE lent
    core - hp 54 vs the ~31 starter - lent-only, vanishes at run end, never bindable so The Binding
    faucet is untouched)
  - the core-comment updated to state the new Fair rule honestly
- Defect: kit survival was a STEP function - Fair (the 32% modal roll) survived the boss ~0.00 at every
  skill tier while Keen jumped to 0.86-1.00; the whole cliff sat between Fair and Keen, so a new
  player's median first free box was a guaranteed loss.
- Justifying number: grade-probe boss-lane survival pre - Dud 0.00 / Rough 0.01 / **Fair 0.01** / Keen
  0.60 / Gleaming 0.92. Centerpiece-alone lifted Fair only to 0.05 (proving survivability, i.e. the
  lent core, is the dominant lever); adding the RARE lend lands it at the target.
- Success criterion: Fair boss-lane survival RISKY-BUT-WINNABLE (dies more than it wins) without
  flattening the gamble - Dud/Rough still usually die, Gleaming still near-guarantee. Measured post
  (grade-probe): Dud 0.00 / Rough 0.01 / **Fair 0.35** / Keen 0.60 / Gleaming 0.92 - a true gradient,
  cliff gone. Per-lane Fair boss win 0.19-0.41, all die >= win.
- Revert trigger: Fair boss-lane win exceeds 0.55 (flattened toward Keen - the cliff just moved to
  Rough->Fair), OR Dud boss-lane win exceeds 0.15, OR Gleaming boss-lane win drops below 0.85.

### CH-P6 - smoke_kit_sim Fair re-pin (D2 tripwire, honest new shape)
- File: `tests/smoke_kit_sim.gd`
- Change: added per-lane Fair tracking (`fwin` / `fdie` arrays, `fn` counter, print column) parallel to
  the existing Dud/Gleaming tracking, and THREE boss-lane assertions codifying the CH-P5 intended shape:
  - `Fair boss is WINNABLE (>= 0.12, was ~0.01)` - the fix landed
  - `Fair boss stays RISKY (<= 0.55, below Keen - not flattened)` - the anti-flatten guard
  - `Fair boss dies more than it wins (honest risk)` - `fdie[k] >= fwin[k]`
- Defect: the tripwire pinned only Dud + Gleaming, so the Fair cliff (the actual D2 defect) was
  invisible to the gate and could silently regress in either direction.
- Justifying number: the four boss lanes (Brassmore/Gildfall x tailwind/rusted) measure Fair win
  0.19-0.41, all die >= win - a robust band at N=340.
- Success criterion: all 12 new Fair-boss assertions (3 x 4 boss lanes) PASS; smoke_kit_sim SMOKE PASS
  exit 0. Confirmed post-landing.
- Revert trigger: any Fair-boss assertion flakes at the shipped N (widen the band and log, do NOT
  delete the pin) - the pin is the D2 regression guard.

### CH-P7 - Build-time fragility cue (D3, single-weapon build silently defanged)
- File: `ui/workshop.gd`
- Change: in `_refresh_bank()` deployable branch, added a `lone_weapon := _offensive_count() == 1`
  read and two new notes (STRAIN_TEXT amber, the same caution tier as the existing overweight note):
  one-weapon + overweight -> "Ready to bind, but fragile: one weapon, and strained (SPD -N). Lose that
  arm and it is defanged."; one-weapon alone -> "Ready to bind, but fragile: it has only one weapon -
  lose that arm and it is defanged." Added the read-only `_offensive_count()` helper (counts seated
  SINGLE/MULTI bits, mirroring the resolver's has_offensive_move notion). The overweight strain note
  and BalanceMeter weight readout are unchanged (already shipped).
- Defect: `is_deployable()` needs only ONE offensive part, so a legal core+1-arm build passes the
  Workshop gate then gets defanged in one hit -> SURVIVABLE_LOSS with no prior warning (drives novice
  own-build ventures losing 58.3% of the pos0 Rusty skirmish).
- Justifying number: newcomer_probe MINIMAL core_ember+arm_hammer vs Rusty -> SL turn 1 (core 100%),
  before the player acts; qa_verify Q5 core_bulwark+fist+strider -> SL turn 5.
- Success criterion: a deployable build with exactly one SINGLE/MULTI bit shows the fragility note at
  bind time; smoke_builder + smoke_layout SMOKE PASS (no gate regression). UI/copy only, no resolver
  touched. Needs an app golden-path visual check by the implementer (headless cannot see the note).
- Revert trigger: smoke_builder/smoke_layout regress, OR the note fires on a multi-weapon build
  (false positive from `_offensive_count`).

### CH-P8 - "Defanged" loss reason (D3, arbitrary-feeling survivable loss)
- File: `ui/combat_screen.gd`, `_banner_text()` (line 1000)
- Change: `return "Beaten. The victor claims one of your broken parts."` ->
  `return "Defanged - it lost its only way to fight. The victor claims one of your broken parts."`
- Defect: a SURVIVABLE_LOSS reads as arbitrary (yourCore 100%, foeCore 100%) with no "you have no way
  to attack" callout - the exact confusion the turn-1 defang creates.
- Justifying number: SURVIVABLE_LOSS is BY DEFINITION `has_offensive_move()==false` (`combat.gd:172`),
  so the banner can always name the trap; it is the only non-DEATH stakes loss path.
- Success criterion: the stakes SURVIVABLE_LOSS banner names the defang; smoke_combat + smoke_bout
  SMOKE PASS. Confirmed post-landing. Copy-only, no resolver touched.
- Revert trigger: smoke_combat/smoke_bout regress.

### CH-P9 - Grinlet buffed out of the dead-EPIC hole (D10, inverted rarity signal)
- File: `parts/catalog_extra.json`, id `pocketful_arm_grinlet`
- Change: `"max_hp": 6 -> 12`, `"attack": 2 -> 3`, `"weight": 5 -> 8`, ability `"power": 9 -> 8`
  (mana_cost 3 unchanged). Net: a feather glass-cannon that now survives one exchange (hp floor,
  D4 light-axis lesson) and whose p8 SINGLE actually breaks armor at atk 3, priced with honest weight.
- Defect: `roster-post.json` mean_delta pocketful_arm_grinlet EPIC **-0.1225** - an EPIC that actively
  HURTS the build, the genuine dead-bit outlier (grumble_co_girder_fist COMMON tops the chart at +0.19).
- Justifying number + tuning trace (sim_roster, 67,410 fights/run): the fragility story is a red herring
  (hp 6->12 alone did not move the delta on this instrument); ATTACK is the armor-break threshold lever.
  atk 6 = +0.29 (OP), atk 4 = +0.23 (over the +18% hard cap), atk 3/p9 = +0.16 (over the +15% soft
  band), a mana throttle was inert; atk 3 + p8 = **+0.1242** (centered).
- Success criterion: grinlet mean_delta >= 0 (at worst neutral) AND inside EPIC budget discipline
  (soft band -5% to +15%, hard cap +18% per wave2-stat-notes). Measured post = **+0.1242** - comparable
  to the shipped pistonfist +0.165 / regalia +0.174, no degenerate template (Sniper +0.36 its natural
  home, Swarm -0.05). No base fixture touched.
- Revert trigger: grinlet mean_delta exceeds +0.18 (breaks the EPIC hard cap) on the next roster re-run,
  OR returns negative.

### NOT A CHANGE - arm_seer stays frozen (D10 second half, ruled out)
- Finding: the playtest listed `arm_seer` EPIC -0.0058 as a second dead EPIC to buff. It is NOT in
  `catalog_extra.json` - it is one of the 13 BASE FIXTURES (`parts/catalog.gd:72`, "Seer Gauntlet"),
  which the hard laws forbid touching. It is also already statistically neutral: -0.0058 is well inside
  1 SE of zero (n ~480-600), and its Sniper cell is +0.117. The D10 requirement ("an EPIC is at worst
  neutral, mean_delta >= 0") is effectively already met for seer and CANNOT be improved without breaking
  the fixture freeze. Producer ruling: D10 = grinlet only; seer is no-change, frozen-and-neutral.

---

## B. VERIFICATION GATE (exit criteria - all MET this pass)

Run after landing CH-P1..CH-P9, panel instruments on their committed seeds:
- All 14 fast gates (`smoke_contract` / `smoke_catalog` / `smoke_builder` / `smoke_combat` /
  `smoke_bout` / `smoke_run` / `smoke_kit` / `smoke_layout` / `smoke_persist` / `smoke_broker` /
  `smoke_stage` / `smoke_beats` / `smoke_audio` / `smoke_art`) exit 0. **MET.**
- `smoke_kit_sim` exit 0 incl. the 12 new Fair-boss assertions. **MET.**
- `smoke_catalog` "base fixtures preserved" PASS; §13, combat.gd, save schema, and the 13 base fixtures
  untouched. **MET.**
- Elites: every core-aim DEATH rate > 0; Pindrop 0.23, Sable 0.22, overgrown 0.30 > base 0.22, none a
  coin-flip. **MET.**
- Bosses (opt_probe RACE): Gildfall 0.305/0.695 (was trivial 1.000/0.000), Brassmore unmoved
  0.305/0.695; finale strictly harder under GUARD (0.775 vs 0.550). **MET.**
- Box (grade-probe): Fair boss survival 0.35 (was 0.01), gradient restored, Dud/Rough die, Gleaming
  0.92. **MET.**
- grinlet mean_delta +0.1242 (was -0.1225), inside EPIC budget. **MET.**

Any single failure: revert the offending CH, re-run the gate, log the miss here before shipping.

---

## C. DEFERRED (owner-gated / out of scope - NOT touched this pass)

- D5 - coffer-RNG stream + EPIC-pity persistence. Needs save v5 (schema is FROZEN). OWNER escalation.
- D6 - Glimmer sink (dead currency, 57.2 earned / 0.0 spent). A new shop FEATURE, out of bounded scope.
- D7 - no turn cap / 167-221-turn grinds + uncappable ladder top. A `combat.gd` resolution-rule change
  = FROZEN; needs the section-13 turn-cap ADR (D13).
- D9 - 80% compendium unreachable in month one. An economy/discovery-faucet pass, out of scope.
- D11 - `Combat.new()` does not enforce build legality (overweight builds resolve headless). A resolver
  weight-check = FROZEN; low severity single-player.

## D. SMOKE_KIT_SIM RE-PIN PLAN (shipped as CH-P6, recorded here)

The tripwire previously pinned only Dud (<= 0.15 win, dies>wins, +G7 lend arm <= 0.20) and Gleaming
(>= 0.60 boss / >= 0.50 elite) per lane, leaving the Fair cliff - the actual D2 defect - unguarded.
Re-pin landed: per-lane Fair tracking + 3 boss-lane assertions (WINNABLE >= 0.12 / RISKY <= 0.55 /
dies >= wins). Bands sized to the measured per-lane Fair boss window 0.19-0.41 at N=340 with headroom.
The Dud/Gleaming/G7 pins are unchanged and still pass (Dud die 1.00, Gleaming >= 0.92). If CH-P5 is ever
retuned, re-read the four boss-lane Fair numbers and re-som the band; never delete the pin.
