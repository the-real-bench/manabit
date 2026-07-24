# AI PLAYTEST PANEL - 2026-07-21

Method: 4 AI personas + a session-trace harness, grounded in the sim outputs; audio deliberately disregarded; all bugs adversarially verified. AI judgment is a proxy for human playtesting, not a substitute.

Lead designer + producer synthesis. Every number below was pulled from a committed sim artifact (`tools/sim/out/*.json`, `session_transcripts.txt`) or a seeded headless probe on the shipped `combat.gd` path; the load-bearing figures were re-read from source during this write-up, not relayed on trust. Where a persona's phrasing did not survive re-check, the corrected form is used and the discrepancy is noted.

---

## 1. HEADLINE

### Enjoyment (AI judgment, not a human verdict)

| Persona | Score | One-line read |
|---|---|---|
| The Newcomer (first two hours) | 6 / 10 | Cozy toy, unbrickable safety net, but the early combat teaches by punishing - a deploy-legal build can lose the tutorial on turn 1 before you act. |
| The Optimizer (min-maxer) | 5 / 10 | One delicious hidden tech (race the core, never guard) and a real capstone wall (Brassmore), sitting on a shallow tree: the 5-family wheel does not cycle, the legal build space collapses to one greedy answer, target selection has no decisions. |
| The Cozy Collector | 6 / 10 | A genuinely low-stress build/coffer/kit lane that never risks your collection, undercut by deterministic (scummable) coffers, a dead glimmer currency, and a completion endgame that stalls. |
| The QA Hunter (defect-focused) | 6 / 10 | Bulletproof economy and determinism, but half-dead combat stakes: two of six elites cannot kill you, the modal first box is an unwinnable death, and the ladder top is uncappable. Many high-value bugs, none in the plumbing. |

Honest aggregate: **5.75 / 10** (simple mean of 6 / 5 / 6 / 6). Read it as "a charming, mechanically sound toy whose central stakes-and-depth promises are half-delivered," not as a Metacritic proxy. The four lenses agree far more than they diverge: everyone found the floor safe and the toy likeable, and everyone independently hit the same three structural soft spots - combat stakes that only three foes actually enforce, a decision layer thinner than the marketing (no cycling wheel, no target choice, no guard payoff), and a collection/economy endgame that drips too slowly while the moment-to-moment drips just right.

### Verdict (one paragraph)

Manabit has an excellent skeleton and an under-delivered promise. The economy is the strongest system in the build - arbitrage-safe, softlock-free (`hard_softlock_probability` 0.0), gently non-inflating, and impossible to brick - and combat is fully deterministic and seed-reproducible, which makes the whole thing trustworthy and cozy to potter in. But the loop's headline hooks are only partly real. "Elites hunt your core for real stakes" is a bluff for three of six elites (Pindrop cannot kill you at all, Sable is too weak, both by measurement not vibe). "A five-family intransitive wheel" is really a three-way rock-paper-scissors bolted to two dead families, and the entire speed/sniper build direction is inert. "A sliding scale of Box-of-Scrap power" is a step function whose 32%-modal roll is a guaranteed loss. And the finale boss is a pushover under correct play while the earlier boss is the real wall. None of these are plumbing failures - determinism, the satchel firewall, the Gleaner's Due ordering law, and the softlock guarantee all held under adversarial attack. They are stakes, depth, and signposting failures at the heart of the build-fight-wager-loot loop. Fix the stakes (elites, turn cap), the onboarding legibility (fragility + overweight warnings, box floor), and the collection endgame (coffer persistence, glimmer sink, a discovery faucet), and this moves from a likeable 5.75 to a genuinely good 7-8.

---

## 2. DIFFICULTY CURVE

Segment by segment: the sim NUMBER, the panel's felt read, and a verdict. Personas reconciled where they diverged.

### 2a. Tutorial / first fight (Scrap-Pup Rusty, ch0)
- **Numbers:** Rusty aggregate ladder win 0.854. But the build you field decides everything: `sprout_3slot` win vs Rusty 0.229 (survivable-loss 0.771); a deploy-legal minimal core+1-arm build loses on **turn 1** (`newcomer_probe.gd`: Rusty snaps the lone hp10 arm, `has_offensive_move()` false, SURVIVABLE_LOSS before the player acts). The intended 5-slot COMMON kit vs Rusty = 1.0 win; kit node0 asserted >=0.90 win, 0 deaths.
- **Felt read:** Newcomer 5/10 as a blend (2/10 through the intended path, 7/10 through the cheap build a beginner actually fields). Cozy 2/10, Optimizer 2/10, QA 4/10.
- **Verdict: SWINGY, mis-gated by what the game ALLOWS.** The intended path is a fair 2/10 pushover; the trap is that the Workshop lets you deploy a one-weapon build that gets defanged before you move, with no warning. This is a legibility problem masquerading as a difficulty one. ~77% of cheap 3-slot builds lose the tutorial (`sprout_3slot` 0.229), and a real beginner's first build is very likely one of these.

### 2b. Early regulars (Ziptie ch1, Sir Vance ch2)
- **Numbers:** Ziptie ladder win 0.743, Vance 0.622. Vshigh-attrition: the transcript novice-vs-Vance fight (SESSION #15 rung 3) runs 30+ turns of 1-damage chip into repeated foe GUARDs.
- **Felt read:** Optimizer 2/10 (no threat), Newcomer flags Vance as a tedium wall for a low-attack build.
- **Verdict: RIGHT on paper, but the GUARD-spam/1-damage grind (see 2f and Defect 7) turns a weak-build regular into a slog rather than a tense fight.**

### 2c. Elites (Cogsworth ch3, Thornlash ch5, Sable ch7, Pindrop ch6)
- **Numbers:** Wide and lumpy ladder win spread - Cogsworth 0.319, Pindrop 0.431, Thornlash 0.604, Sable 0.823. Cogsworth is the true wall: the climb-ending rung in 24/36 average and 22/36 expert ladder runs. But the DEATH stakes are broken for half the roster: core-aim death rate Cogsworth 0.419, Gildfall 0.517, Brassmore 0.433 vs **Pindrop 0.000** (n=82 trace, 0/60 live probe) and **Sable 0.000** (n=26 trace, 0/60 live probe). A COMMON build makes zero progress: all 8 cheap `newcomer_probe.gd` builds DIED to Cogsworth and Thornlash with the foe core at 100%.
- **Felt read:** Newcomer 9/10 (zero-progress wall), Cozy 6/10, Optimizer 4/10 skilled / 7/10 cautious, QA 6/10.
- **Verdict: TOO HARD for a starter build (intended gating, folds into the box curve) but STRUCTURALLY TOOTHLESS for two of six.** The elite difficulty is carried entirely by the three SINGLE-move core-hunters (Cogsworth, Thornlash-base, Brassmore/Gildfall on the boss tier). Pindrop and Sable are difficulty theatre - scary blurbs the mechanics do not back. This is Defect 1.

### 2d. Bosses (Sunking Brassmore ch4, Prince Gildfall ch8)
- **Numbers:** Ladder shipped-AI win Brassmore 0.125, Gildfall 0.128 - they LOOK identically hard. Under optimal RACE play on a strong build (`opt_probe.gd`, 200 jittered seeds, foe hunts core): **Gildfall WIN 1.000 / DEATH 0.000** (trivial), **Brassmore WIN 0.305 / DEATH 0.695** (a real knife-edge). Own-build venture boss death 0.596 (strong) / 0.746 (mid); ~55 of 65 venture deaths land at the boss (pos4), zero at skirmish/rest.
- **Felt read:** Cozy 9/10, Newcomer 10/10 wall (a first-hour build never wins - `common_kit_5slot` vs both = 0.00), Optimizer Brassmore 8/10 (the one real capstone) vs Gildfall 3/10 mis-tiered pushover, QA 8/10.
- **Verdict: INVERTED and mis-signposted.** Brassmore (the earlier boss, ch4) is the genuine capstone wall; Gildfall (the ch8 finale) folds under correct aggression. The ladder's identical ~0.12 win rates are a shipped-greedy-AI artifact that hides the inversion. Nobody in 324 sessions reached the top of the ladder (`reached_top_rate` 0.00). This is Defect 5.

### 2e. Kit-run grades (Box of Scrap, Dud -> Gleaming)
- **Numbers:** NOT a sliding scale - a step function. Venture survive_rate by grade in `sessions.json` aggregate: Dud 0.00-0.25 / Rough 0.00-0.14 / **Fair 0.0 at ALL three tiers** / Keen 0.86-1.00 / Gleaming 1.00. Fair is the 32% modal `BoxRoller` roll. Weighted by shipped odds (Dud .12 / Rough .28 / Fair .32 / Keen .20 / Gleaming .08), P(survive first box) ~= 0.25.
- **Felt read:** Newcomer 7/10 (harsh), Cozy Dud 9/10 down to Gleaming 1/10, QA Dud 9/10 / Fair 9/10 / Gleaming 1/10, Optimizer "grade IS the difficulty, ~1/10 decision depth."
- **Verdict: TOO HARD at the modal roll, and the difficulty is decided at crack time, not played out.** 72% of boxes (Dud+Rough+Fair) are near-guaranteed death; 28% near-guaranteed clear; the entire jump sits between Fair and Keen with nothing in between. The "sliding scale of power" the design promises is a coin-flip disguised as a gradient. This is Defect 4.

### 2f. Own-build venture (your toy down the 5-node road)
- **Numbers:** Full-road survival novice 0.58 / average 0.25 / expert 0.36 (average is the HARDEST - build+policy confound). Close-call rate rises with skill (0.00 / 0.06 / 0.19); expert stall_rate 0.111. Deaths concentrate at the boss (13-22 boss vs 2-9 elite per tier, zero skirmish/rest). Expert net scrap +18.6 vs average +6.8 (EV, loot-melt not auto-realized). Consumes the seated core (~60 scrap) every run regardless of outcome (`root.gd:82-87`).
- **Felt read:** Newcomer 6/10, Cozy 7/10 (expression is punished), Optimizer 7/10 punishing, QA 7/10.
- **Verdict: TOO HARD / punishing relative to the cozy framing, and non-monotonic with skill** (the average tier is worse than novice because the greedy-race policy grinds mending walls). The road nudges players toward disposable kit boxes over their own creations. Note: the tier numbers bundle build quality AND move policy, so these are not pure play-skill deltas.

### 2g. Economy pacing
- **Numbers:** `hard_softlock_probability` 0.0 (by construction - the Box needs no core/scrap/bits, kit rests mend free). Core-lock: 37.6% of players ever locked, but only 1.77% of player-days, episode p50 1 day / p95 2 days, 7 players still locked at day 30. 30-day faucet 2298.9 vs sink 2258.4 (+1.8%), imbalance 1.8%, scrap p50 ~90 flat all 30 days. First EPIC: 100% of players, p50 day 1. 80% compendium: 12.6% reached, p50 dex 60/73 at day 30.
- **Felt read:** Newcomer 2/10 (very forgiving = good), Cozy 2/10, QA 3/10 (healthy), Optimizer "soft on money, hard on weight."
- **Verdict: RIGHT, and the soundest system in the build** - with two design-glance caveats: first EPIC on day 1 may undercut the rarity ramp (pacing, not defect), and the 80%-compendium tail is unreachable in month one for ~87% of players (Defect 9). The real endgame constraint for a min-maxer is the weight cap (~106-110), not scrap.

### Difficulty verdict (one line)
**SWINGY and mis-signposted, not uniformly too easy or too hard: a safe, forgiving economy floor under a combat layer whose stakes are real for only half the elite roster, whose bosses are tiered backwards, and whose "sliding" box-power scale is a step function decided at crack time.**

---

## 3. ENJOYMENT: what creates fun, what kills it

### What creates fun (grounded, by player type)

- **Newcomer - instant, unbrickable collection payoff.** First EPIC p50 = day 1 ("day 0 = an EPIC in the starter brass roll"), `hard_softlock_probability` 0.0, losses are soft (a lost bout forfeits a broken bit + scrap, core stays 100%; a kit/venture death still keeps ~9 scrap via Gleaner's Due). You truly cannot get stuck.
- **Optimizer - the hidden RACE-the-core tech.** `opt_probe.gd` proves guard-when-behind is a turtle-trap and pure aggression is mathematically dominant: Cogsworth 0.345 -> 1.000, Gildfall 0.550 -> 1.000, Brassmore rescued from 0.000 to 0.305 win. Cracking "guarding is a trap, always race" feels like solving the game. Brassmore is a worthy knife-edge capstone (0.305 even played perfectly). The weight-budget puzzle has real teeth (top-delta bits sum to 156 weight vs ~110 cap - you genuinely choose which heavy hitters to afford). Bedrock Legs (+0.34, 3-5x every other legs bit) is a clean best-in-slot chase target.
- **Cozy - a true no-risk gamble lane.** The Box of Scrap is a readable crack-and-see (probe over 5000 seeds: Dud 11.8% / Rough 28.9% / Fair 31.2% / Keen 20.2% / Gleaming 8.0%) that NEVER touches `player.bits` (`box_roller.gd:5-6`) - a death only spills the run-local satchel and still pays Gleaner's Due (a Dud died at the boss and still banked +5, transcript #216; a Gleaming walked the whole road for +75, transcript #220). The scrap wallet is a calm ~90-flat pass-through, no feast-or-famine.
- **QA - the invariants hold.** Determinism is exact (same seed -> identical turns + outcome), the satchel firewall is intact (all 63 kit deaths net gleaners-only, max 17), the Gleaner's Due ordering law holds (death-kept <=17 = floor(35/2) strictly dominated by safe-end mean 66.9), and no scrap printer exists. When the three SINGLE-move killers are in play the stakes land hard and honestly (Gildfall 47/60 core-aim kills; session 181 = expert dies with the boss core at 5% after a dead-even 8-vs-9 core race).

### What kills fun (grounded, by player type)

- **Newcomer - teaching by punishment.** A deploy-legal core+1-weapon build loses the tutorial on turn 1 before you act ("I lost and I never even moved"). The free Box of Scrap blows you out ~75% of the time and the modal Fair roll dies 100% at the boss ("outclassed" - novice kit flag_mix 23 outclassed / 12 clean_win). Overweight silently drops SPD to 1 while chasing attack. The "defanged but core-full" loss (yourCore 100%, foeCore 100%) reads as arbitrary with no "you have no way to attack" callout.
- **Optimizer - the depth is mostly invisible and quickly exhausted.** The 5-family wheel does not cycle (pentagon_v2 cell win rates: boldheart beats grumble/thicket/silksteel 0.92-0.955 but loses to whirligig 0.105 - a 3-cycle plus two dominated families; silksteel, the whole core-sniper pillar, beats nobody). The speed/sniper axis is dead. The legal build collapses to one greedy answer identical across every core (the "soul" pick is nearly cosmetic). Target selection has no decisions (MULTI auto-picks lowest-HP, SINGLE-core is fixed). Rarity lies (EPIC Seer -0.006, EPIC Grinlet -0.1225 vs COMMON Girder +0.19) with no in-game counter-data.
- **Cozy - the collection dopamine leaks where it should peak.** Coffers are deterministic and scummable (every fresh boot replays the identical brass stream; first EPIC is always `carillon_cadets_arm_grandpeal` in brass #2). Glimmer is a dead score counter (57.2 earned / 0.0 spent over 30 days). Completion stalls (12.6% reach 80% in a month). Sending your OWN toy down the road is punished, not cozy, and burns the ~60-scrap core every run.
- **QA - the stakes are a bluff for half the roster.** Two of six "core-hunting" elites cannot kill you; the 1-damage DEF floor turns wall fights into 167-221-turn grinds (27.2% of all damaging hits land for exactly 1); junction risk labels are inverted (the menace-flavored lane is the SAFE pick).

### The single biggest lever to raise enjoyment

There is no one lever that lifts all four personas - the report surfaces one per lens, ranked in Section 6. But the **highest-leverage single change is restoring elite core-hunt stakes (re-apply the reverted CH-05/CH-06)**: it is the only fix that touches the loop's central promise ("wager your build, elites hunt your core") for three personas at once - the QA Hunter's top defect, the Cozy Collector's "where a cozy toy dies" tension, and the difficulty curve's biggest hole. Two of six elites being toothless is a measured 0/60 + 0/60, not a feel note, and it silently drains the run's whole stakes pillar. Close behind for the Newcomer specifically: build-time fragility + overweight warnings plus a "defanged - no way to attack" loss reason, which target the exact confusion the turn-1 loss creates and touch no frozen contract.

---

## 4. CONFIRMED DEFECTS (verified list only, ranked by severity)

All eleven were reconstructed as seeded headless probes on the shipped `combat.gd` resolver and adversarially stress-tested by the QA lead. Outcome enum: 1=WIN, 2=SURVIVABLE_LOSS, 3=DEATH.

**D1. [CORRECTNESS / balance - HIGH] Toothless elites break the core-stakes promise.** Two of six elites have a 0% DEATH rate even with `aims_core=true`. Pindrop (ch6) is STRUCTURAL: loadout = HEAD MULTI / ARM_L GUARD / ARM_R MULTI / BACK MULTI = zero SINGLE moves, and the core-hunt branch (`combat.gd:146-152`) only fires for archetype==SINGLE, so it can never land a killing blow (0/60 DEATH; WIN 27 / SL 33). Sable (ch7) is UNDERTUNED not structural: 2 SINGLE moves but too weak (0/60 DEATH; WIN 48 / SL 12). Contrast confirms it is not a probe artifact - same probe gives Cogsworth 30/60, Thornlash-base 24/60, Brassmore 49/60, Gildfall 47/60. Matches the D-list "Pindrop zero-death / Sable paper-elite"; CH-05/CH-06 were the intended fixes and were reverted (`wave1-change-order.md:257-263`). **Repro:** `tools/sim/qa_verify.gd` (archetype audit + 60 kit-build core-aim lethality).

**D2. [BALANCE - HIGH] Modal first Box of Scrap is a guaranteed loss.** Kit survival by grade is a step function: Dud/Rough/Fair all ~0.00 survive at every skill tier, Keen 0.86-1.00, Gleaming 1.00 - the entire jump is between Fair and Keen. Fair is the 32% modal `BoxRoller` roll, so P(survive first box) ~= 0.25 at shipped odds and the median first free kit dies 100% regardless of play, at the boss with the foe core ~97% ("outclassed"). Real stakes are intended, but the modal outcome of a FIRST free kit being an unwinnable death is a new-player cliff. **Repro:** `sessions.json` aggregate `kit/{novice,average,expert}.by_grade` (dedup of the panel's N2 + Q4).

**D3. [CORRECTNESS / UX trap - HIGH] Single-offensive-part Manabit instantly forfeits with no fragility cue.** `outcome()` returns SURVIVABLE_LOSS the moment `has_offensive_move()` is false (`combat.gd:172`, `manabit_state.gd:27-32`), and `is_deployable()` only requires ONE offensive part - so a deploy-legal core+1-arm build passes the Workshop gate then gets defanged in one hit. `newcomer_probe.gd` MINIMAL core_ember+arm_hammer vs Rusty -> SL turn 1 (Rusty is faster, one-shots the hp10 hammer before the player acts, core 100%); `qa_verify.gd` core_bulwark+standard_fist+strider vs Rusty -> SL turn 5. Drives novice own-build ventures losing 58.3% of the pos0 Rusty skirmish. Reachable through the shipped Workshop; the builder gives no warning. **Repro:** `newcomer_probe.gd`, `qa_verify.gd`.

**D4. [BALANCE - MEDIUM/HIGH] Inverted boss difficulty.** Prince Gildfall (ch8 finale) is trivial under optimal aggression (`opt_probe.gd` RACE, 200 jittered strong builds, foe hunts core: WIN 1.000 / DEATH 0.000; fixed builds WIN t83) while Sunking Brassmore (ch4, earlier boss) is the real wall (WIN 0.305 / DEATH 0.695). The `ladder-post.json` identical ~0.12 win rates are a shipped-greedy-AI artifact that hides a skilled player facing a harder EARLIER boss than the finale. **Repro:** `opt_probe.gd` Q3, `opt_probe2.gd`.

**D5. [EXPLOIT / correctness - MEDIUM] Coffer RNG stream + EPIC pity are not persisted; the seed is a compile-time constant.** `PlayerState._init` always runs `PackRoller.new(20260711)` (`player_state.gd:50`) and `SaveManager` writes no roller/pity field (`save_manager.gd` only persists `kit_box_nonce`). Two fresh PlayerStates produce byte-identical brass: brass#1 = [pith_sinew_marrow_legs, boldheart_arm_sunder(RARE), cobble_sons_arm_mendclaw, everykit_standard_piston, pith_sinew_caul_hood]; brass#2 = EPIC carillon_cadets_arm_grandpeal; brass#3 = EPIC cobble_sons_legs_bedrock. Every relaunch replays from position 0 and pity resets each boot, so coffers are relaunch-scummable and every new player cracks the identical "surprises." `economy-post.json` flags this MEDIUM independently. **Repro:** `qa_cozy.gd`.

**D6. [ECONOMY / design - MEDIUM] Glimmer is a dead currency for a keep-1 collector in month one.** `economy-post.json`: glimmer earned 57.2/player over 30d, `finds_glimmer` spent 0.0 on every one of the 30 days; p50 wallet climbs to 56 with nothing to buy. RARE/EPIC Finds are the only glimmer sink (`broker.gd:23-27`) but the shelf is discovered-gated and those bits are never consumed by any loop, so every Find offered is a dupe. Minor firewall note: buy EPIC Find (10 glimmer) then Melt (45 scrap) = 4.5 scrap/glimmer, so "no conversion" is not literally true, though no profitable round-trip exists. **Repro:** `economy-post.json` `results.faucet_sink_daily_mean_per_player` + flags.

**D7. [POLISH / tedium - MEDIUM] No turn cap: defensive/mending fights grind 167-221 turns.** `combat.gd` `outcome()` has no turn counter; ~27.2% of all damaging actions land for exactly 1 (the `maxi(1,...)` DEF floor at `combat.gd:107`). Cogsworth-mirror bout resolves WIN at turn 167 (`qa_verify.gd`); GUARD-when-behind flagship vs Brassmore resolves WIN at 221 and vs Gildfall at 169 (`qa_stall.gd`, 1,000,000-turn cap). The ladder "unbeatable top" (reached_top 0.00 at all tiers) is the same grind exceeding the turn/patience budget, since bouts set `aims_core=false` so the player core can never die. This is a GRIND, not a hard lock - every fight provably terminates (damage floored >=1, PART_RESTORE capped at max_hp). The `sessions.json` 27/962 STALLs and `opt_probe`'s STALL@100 are harness-cap artifacts. **Repro:** `qa_verify.gd`, `qa_stall.gd`.

**D8. [POLISH / balance - MEDIUM] Junction lane modifiers are mislabeled - the menace label is the safe pick.** Per-mod fight outcomes over `sessions.json`: overgrown ("the foe fields heavier bits") n=15 -> WIN 0.07 / SL 0.93 / DEATH 0.00 (SAFEST); tailwind ("mended 4 HP", sounds helpful) n=102 -> DEATH 0.59 (DEADLIEST - it rides boss lanes); second_wind DEATH 0.22; rusted DEATH 0.29. Cause: the overgrown swap replaces Thornlash's pow4 SINGLE gnashmaw with MULTI flenseclaw, which cannot core-hunt, dropping his own death rate 0.40 -> 0.13. Compounds with D12 (tailwind pre-mend + second_wind near-inert). **Repro:** `sessions.json` per-mod aggregate + `qa_verify.gd`. (See the completeness note in Section 5: this holds for the ELITE fork the panel tested; the BOSS fork rusted lane is genuinely the correct pick, so junctions ARE a meaningful decision at the boss.)

**D9. [PROGRESSION / design - MEDIUM] 80% compendium is unreachable in month one for ~87% of players, and the shortfall is invisible in-game.** `economy-post.json` `days_to_80pct_compendium`: reached_pct 12.6%, p50 dex 60/73 at day 30, 437/500 not reached in 30d. Finds cannot sell undiscovered bits and loot only covers the 9 challenger loadouts, so the last-mile dex is a coupon-collector on the tin/brass coffer stream alone - which compounds with D5 (a completionist can never discover a bit the constant stream does not roll). **Repro:** `economy-post.json` `results.days_to_80pct_compendium`.

**D10. [BALANCE / polish - LOW/MEDIUM] Rarity is an inverted value signal for specific bits, with no in-game counter-data.** `roster-post.json` mean win-rate deltas (n=480-600 fights each, re-read this pass): arm_seer EPIC **-0.0058** and pocketful_arm_grinlet EPIC **-0.1225** are both negative, while grumble_co_girder_fist COMMON **+0.191** and errant_core_pledge COMMON core **+0.165** are the strongest positive contributors (and cobble_sons_legs_bedrock EPIC +0.34 confirms rarity is not uniformly wrong - it is unreliable). Two EPICs actively hurt the build; players see only rarity + raw stats. Grinlet at -0.1225 is a genuine dead-bit outlier. **Repro:** `roster-post.json` `bits[].mean_delta`.

**D11. [CORRECTNESS - LOW] `Combat.new()` does not enforce build legality - overweight builds resolve fine headless.** `start()` (`combat.gd:21-28`) takes two ManabitStates with no weight<=capacity check; `opt_probe2.gd` ran a 156/110 build to completion. The weight cap lives only in the derived() SPD penalty + UI, so a save-edited/modded overweight build would still fight. Low severity single-player (overweight is intended fieldable-but-slow), but the resolver trusts the caller. **Repro:** `opt_probe2.gd` build B.

### Refuted / downgraded (do NOT re-report as bugs)
- **Pure-defense build = silent turn-0 loss (O3):** REFUTED as player-reachable. The resolver does return SL at turn 0 when `has_offensive_move()` is false, but the Workshop BLOCKS deploying a zero-offensive build (`workshop.gd:897,1056,1076` gate on `is_deployable()`; deploy_block_reason surfaces "Give it a way to fight"). Only reachable by bypassing the gate. The reachable single-weapon variant IS shipped as D3.
- **GUARD-when-behind runs unbounded / can hang (O2):** REFUTED (overstated). Resolves WIN at 221 (Brassmore) / 169 (Gildfall) at a 1M-turn cap. Combat is provably terminating. The real issue is the D7 no-cap grind.
- **Kit DEATH does not burn a daily purse slot (C3):** REFUTED as stated. A paying kit death (kept>0) DOES burn a full-rate slot (`run_screen.gd:862-863` -> `gleaners_pay` -> `note_kit_run`). Only a zero-kept death skips it, which nets nothing and is harmless.
- **Silent overweight SPD penalty (N4):** PARTIAL. The penalty is real (5-slot common kit wt 114/100 -> SPD 1), but "silent / no cue" is contradicted by the shipped BalanceMeter ("SPD x -> y (-N)" + hatched overflow). Penalty confirmed; no-feedback characterization not supported. (Still worth a stronger nudge - see R3.)
- **Measured-best bit set un-fieldable under weight cap (O4):** CONFIRMED-as-fact, NOT a defect - the intended weight-budget tradeoff.
- **Elite = zero-progress wall for a first-hour build (N3):** CONFIRMED-as-fact, INTENDED gating, not a bug.
- **Own-build venture DEATH net +81 inverts Gleaner's Due (Q8):** NON-DEFECT. The +81 is two separate legitimate events (prior elite SL forfeit-salvage + boss own-wreck + loot-melt EV); realized-cash ordering holds. Own-venture net is not directly comparable safe-vs-death (harness convention).

---

## 5. COVERAGE + LIMITS

### What was tested (well-grounded)
- Ladder climb (108 climbs), own-build venture (Monte Carlo + 108 sessions), kit runs across even Dud-Gleaming grade coverage (324 sessions, 962 fights, 17,421 turn records).
- Economy softlock / firewall / arbitrage (500 players x 30d), coffer determinism, the satchel firewall, the Gleaner's Due ordering law - all actively attacked and held.
- The toothless-elite, no-turn-cap, Fair-box, boss-inversion, rarity-inversion, glimmer, and compendium defects, each re-verified against the shipped resolver with contrast controls.

### What was NOT tested (from the completeness critic)
- **SPAR (zero-stakes practice) - untested and structurally cannot be the onboarding fix it looks like.** `combat_screen.gd:134-135`: SPAR fights a clone of your OWN build (Tinker's Dummy), not Rusty or the challengers. A mirror match hides the exact failure mode a newcomer needs to learn (a one-arm build gets defanged), so SPAR cannot rehearse the matchups that actually kill new players. Never fought once across 324 sessions.
- **BOSS junction - under-tested and MIS-GENERALIZED by the panel.** The QA Hunter/Optimizer tested only the ELITE fork and concluded "junctions don't matter." At the BOSS fork (where ~55 of 65 venture deaths occur) the rusted lane is the correct pick at BOTH junctions: `ladder-post` lane_observational T0 rusted-Gildfall win 0.270 / death 0.702 vs tailwind-Brassmore 0.096 / 0.893; T1 rusted-Brassmore 0.203 / 0.730 vs tailwind-Gildfall 0.090 / 0.844 - ~2.3-2.8x more wins, 14-19pp fewer deaths. `modifier_experiments.rusted` isolates rust at +0.141 win for a strong core-racer; `crit_probe.gd` reproduces the correct SIGN at mid strength (Brassmore 0.158->0.175, Gildfall 0.208->0.225), so the benefit scales with skill and is never negative. **Net: D8's "junctions are inert" is true for the elite fork only; the boss junction IS a real decision.**
- **Proving-bout WAGER/LOOT economy - the reward half of the loop was never scored.** All four personas measured win RATES; none scored payoff. `crit_probe.gd` loot scan surfaces an INVERTED reward gradient: elite Cogsworth (stake 10) loots a melt-45 EPIC Bedrock Legs (the Optimizer's named BiS chase target, and its ONLY combat acquisition path), while the HARDER boss Gildfall (stake 20) loots only melt-20 (his single EPIC is the unsalvageable Regalia core). At regular tier, identical stake 5 buys 2.5x-spread loot (Ziptie melt-20 RARE turbine vs Rusty/Vance melt-8 commons) with no in-game signposting. Reward does not track difficulty or stake.
- **Lower-priority untested:** the Binding core-recovery loop (60-scrap COMMON mint as the actual post-death recovery path), the glimmer distill faucet + Find-shelf dupe logic (asserted, not driven), Ziptie's tempo/flurry threat turn-by-turn, per-node REST repair drain in own-build ventures.

### Honest limits of AI playtesting here
- **AI judgment is a proxy, not a substitute.** Enjoyment scores are structured inference from mechanics + data, not felt human experience. Treat the difficulty and defect numbers as solid and the enjoyment scores as directional.
- **Tier confound:** on ladder/venture the three tiers bundle build quality AND move policy (as a real player would), so tier deltas are NOT pure play-skill. Only the kit journey isolates skill (box fixed) - which is why the Fair cliff (0.0 at every tier) reads as box design, not skill.
- **Instrument lenses:** the average/expert move policies are sim lenses (same as sim_roster/sim_ladder v2), not the shipped combat AI. Novice IS the shipped greedy AI; all opponents use the shipped foe AI. Combat is fully deterministic - variance is seeded build/box generation only.
- **Save-schema-blocked:** D5's pity-reset and the daily bout-win loot cap could only be verified via fresh PlayerStates, not a persisted save; probes were barred from `user://`. A dedicated pass is warranted when the save schema unfreezes.
- **Coverage verdict (critic):** difficulty/defect coverage is strong; DECISION-DEPTH and REWARD coverage has real holes - the panel measured how hard fights are far better than what choices and payoffs surround them.

---

## 6. PRIORITIZED RECOMMENDATIONS

Ranked by (enjoyment + stakes lift) / (cost + contract risk). Each tagged balance / design / bug, with the frozen-contract caveat where it applies.

**R1. Restore elite core-hunt stakes: re-apply CH-05 / CH-06 (Pindrop + Sable). [BUG + BALANCE]**
Evidence: D1 - Pindrop 0/60 and Sable 0/60 core-aim deaths vs Cogsworth 30/60, Brassmore 49/60. Pindrop needs a SINGLE-archetype move added to its loadout (structural - it currently has none, so `combat.gd:146-152` never fires); Sable needs her SINGLE power raised to win the core race. This is the single highest-leverage change: it restores the loop's central "elites hunt your core" promise for three personas at once. Loadout data lives outside the frozen resolver - do not touch `combat.gd` resolution or the base fixtures; adjust the challenger loadouts / move powers that CH-05/CH-06 originally targeted.

**R2. Author the turn-cap ADR (D13) and a wall-fight pacing pass. [DESIGN, resolver-frozen -> ADR-gated]**
Evidence: D7 - Cogsworth-mirror 167 turns, GUARD-vs-Brassmore 221 turns, 27.2% of damaging hits land for exactly 1, ladder reached_top 0.00 (uncappable). `combat.gd` `outcome()` has no turn counter. The resolver is frozen, so this is an ADR decision, not a direct edit: either a turn cap with a tiebreak (core-HP %), a rising-damage or stalemate-break rule, or a bout-mode fix so a core-racer can finish a mending wall. Without it the ladder cannot be completed and defensive fights are 5-10 minute slogs. Highest structural value alongside R1.

**R3. New-player legibility bundle: fragility + overweight warnings, a "defanged" loss reason, and a Fair-box floor rethink. [DESIGN + BALANCE]**
Evidence: D3 (turn-1 defang, novice ventures lose 58.3% of the Rusty skirmish), D2 (modal Fair box survives 0.0 at every tier), N4-partial (overweight SPD-1). Add a build-time BalanceMeter nudge when a Manabit has only one offensive bit or is overweight, and a clear "no way to attack - you were defanged" loss reason. Separately, soften or telegraph the Fair-box floor so the modal FIRST free box is not a guaranteed unwinnable death (e.g. a pity floor on a player's first N boxes, or a clearer grade-power read at crack time). Note: SPAR cannot substitute for this - it is a mirror match that hides the defang failure (Section 5). None of this touches the frozen combat/economy contracts.

**R4. Re-tier the bosses or fix Gildfall's core defense. [BALANCE]**
Evidence: D4 - Gildfall WIN 1.000 / DEATH 0.000 under RACE vs Brassmore 0.305 / 0.695. The ch8 finale should not fold under the tech that a skilled player will have found by the ch4 boss. Give Gildfall smarter core-defense (guard/mend when his core is threatened) or swap the boss order so difficulty rises monotonically. Loadout/AI-behaviour tuning, not resolver.

**R5. Coffer persistence + a glimmer sink + one discovery faucet (the cozy endgame bundle). [BUG (D5) + DESIGN (D6, D9)]**
Evidence: D5 (byte-identical scummable brass stream, pity resets each boot), D6 (glimmer 57.2 earned / 0.0 spent), D9 (12.6% reach 80% compendium). Persist a per-save roller seed + pity in `save_manager.gd` (currently only `kit_box_nonce`); add a glimmer sink (dyes/enchants/a glimmer coffer or a distill-to-discovery path); add one undiscovered-Find slot as a relaxed discovery faucet so the last ~13 compendium bits are not gated solely on the constant coffer stream. Moves the Cozy Collector from 6 to ~8 by their own estimate. Save-schema work - coordinate with the frozen save-schema unfreeze.

**R6. Signpost bit value and fix the speed/wheel depth (the Optimizer bundle). [BALANCE + DESIGN]**
Evidence: D10 (EPIC Seer -0.006, EPIC Grinlet -0.1225 vs COMMON Girder +0.19), the non-cycling wheel (pentagon cells), the dead speed axis (Sniper attacks 0.00/0.00/0.03/0.00). Buff or repurpose the two dead EPICs so rarity is not an inverted signal; give the speed/sniper axis a resolver-independent payoff (the D11 speed-axis ADR is already queued); make two of the five families actually counter something so the advertised wheel cycles. Lowest urgency (only the min-maxer feels it) but it is what caps that persona at 5.

**R7. Junction and loot-reward signposting. [POLISH / BALANCE]**
Evidence: D8 (inverted elite-lane labels), plus the completeness findings - the BOSS junction rusted lane is genuinely correct (so keep it, but label it honestly) and the proving-bout loot gradient is inverted (stake-10 Cogsworth loots melt-45 EPIC, stake-20 Gildfall loots melt-20). Align lane flavour with actual risk, and surface loot value so the wager loop's reward tracks its difficulty. Lowest priority; addresses the decision-depth/reward coverage holes.

---

*Prepared by the AI playtest panel (4 personas + session-trace harness) as lead-designer + producer synthesis. All numbers re-grounded in the committed sim artifacts this pass. Read-only throughout: no base fixture, section-13 contract, `combat.gd` resolution, save schema, or `user://` save was touched. Audio deliberately disregarded per mandate.*
