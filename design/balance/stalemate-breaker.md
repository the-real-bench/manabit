# Stalemate Breaker - the mutual-GUARD softlock fix

STATUS: RATIFIED 2026-07-21 - driver-level no-progress breaker; combat.gd/section-13 UNTOUCHED

Owner: combat + systems design. Scope: `ui/combat_screen.gd` (the breaker) + an optional
build-time nudge in `ui/workshop.gd`. NO resolver change, NO new outcome, NO save-schema change.

---

## 0. The bug (grounded, not re-derived)

Owner hit a hard softlock vs the final boss: the fight never ends because BOTH sides can only
GUARD, so no damage ever lands and `Combat.outcome()` sits at `ONGOING` forever.

Confirmed root cause (from the headless repro - build on it, do not re-litigate):

- `combat/combat.gd` is the FROZEN section-13 resolver. `outcome()` returns WIN / DEATH /
  SURVIVABLE_LOSS / ONGOING (combat.gd:167-174). SURVIVABLE_LOSS fires only when the player has
  NO offensive part (`has_offensive_move()==false`).
- `moves_for` only returns moves with `mana_cost <= mana` (combat.gd:45-54). `ai_take_turn` picks
  the first affordable non-GUARD move, else GUARD (combat.gd:141-165).
- Mana: `start_fight` sets `mana = derived().energy`; `begin_turn` regens `mana = min(energy,
  mana + 2)` (manabit_state.gd:52-58). So an attack whose `mana_cost` EXCEEDS the build's total
  energy is NEVER affordable - that fighter can only GUARD, forever.
- `has_offensive_move()` checks part EXISTENCE, not affordability (manabit_state.gd:27-32). A
  player who still HAS an offensive arm but can never afford it keeps `outcome()==ONGOING` while
  only guarding - it never trips SURVIVABLE_LOSS.
- STALEMATE = reachable when BOTH sides are GUARD-only at once: the foe's offensive arms have all
  broken off (only GUARD parts left -> AI guards) AND the player holds an offensive part whose
  cost > energy (never affordable -> guards). No damage lands, `outcome()` stays ONGOING forever.
  The AI-vs-AI sim does not reproduce it (both sides can afford attacks there); a human build +
  broken-arm state hits it. Gildfall himself is fine (energy 21, cheap attacks) - the trigger is
  the player-side unaffordable-attack combined with broken foe arms.

The same freeze also covers the pure hang-back stall (player reduced to core only, a non-core-aiming
foe "hangs back" per combat.gd:161-163, player can not afford a move) and any mend loop.

---

## 1. Why this is a DRIVER fix, not a resolver ADR (the §13 freeze)

`combat/combat.gd` stays BYTE-IDENTICAL. The resolver's `outcome()` never learns about stalemates.
Instead the combat DRIVER (`ui/combat_screen.gd`, which already loops turns) TIMES OUT a no-progress
loop to an EXISTING outcome (SURVIVABLE_LOSS). No new enum value, no new resolver branch, no turn cap
inside the resolver. That is precisely why this is NOT the D7 turn-cap ADR: nothing §13 changes.

HARD LAWS honored: `combat.gd` resolution + the §13 contract classes (`PartData`, `AbilityData`,
`PartInstance`, `ManabitState` + `derived()`) + the three fight outcomes + save schema + the 13 base
fixtures stay byte-untouched. `smoke_contract` must stay green and the resolver diff must be empty.

---

## 2. The no-progress definition (decision 1)

**No-progress turn = a completed turn across which the COMBINED current-HP of both fighters did NOT
decrease.** Damage lowers HP; a landed strike ALWAYS deals `maxi(1, ...) >= 1` (combat.gd:107), so a
decrease means "a blow landed = the fight moved toward a finish." A GUARD leaves HP flat; a mend
(PART_RESTORE) RAISES HP; an idle/wait/hang-back leaves it flat. All three are no-progress. This
single test catches the mutual-GUARD lock, the mend loop, AND the hang-back stall in one rule.

Implementation signal (mandated): snapshot `sum(current_hp)` over every slot of `_me` and `_foe`
immediately BEFORE `action.call()` and again immediately after, inside `_apply`. `progress = (after
< before)`. On `progress` reset the counter to 0; otherwise increment it.

Do NOT key the signal off `combat.last_events` being non-empty alone. `perform()` clears
`last_events` on entry, but the two AI early-return paths (no affordable move, combat.gd:143-144; and
"hangs back", combat.gd:161-163) do NOT call `perform()`, so `last_events` stays STALE-non-empty from
the previous real hit. In a pure hang-back stall that stale array would wrongly read as "damage this
turn" every turn and the breaker would never fire - the softlock would persist. The HP-delta is
staleness-immune and touches nothing frozen (it only reads part HP). Use it.

Mend must count as no-progress (the diagnosis calls this out): a mend heals but deals no damage, so
HP goes up, not down -> `progress=false` -> it correctly counts toward the limit. A mend loop is a
stalemate and is meant to be broken.

---

## 3. STALEMATE_LIMIT (decision 2)

**STALEMATE_LIMIT = 10** consecutive no-progress TURNS (individual fighter actions; = 5 full rounds).

Justification that it will NOT false-fire on a normal winnable fight - the longest LEGITIMATE
no-damage stretch a real fight can produce:

- Opening: `start_fight` seats mana at FULL (`= energy`), so a healthy fighter can afford an attack
  on turn 1. The AI only opens GUARD if it has no affordable non-GUARD move that turn - which, at
  full mana, means its cheapest attack already costs more than its energy (the pathological build
  itself). A healthy fighter draws blood early. Legit opening no-damage stretch: ~0-1 turns.
- Mid-fight mana rebuild: a fighter that just spent a near-full-energy attack sits at ~0 mana and
  regens +2 per ITS OWN turn, needing `ceil(cost/2)` of its turns to refire; while it rebuilds it
  guards. For a realistically expensive attack (cost ~8-10) that is ~4-5 of that fighter's turns.
  BUT the counter tracks EITHER side - the opponent is almost always landing hits in that window,
  which resets it. The counter only climbs when BOTH sides are simultaneously mana-starved and
  rebuilding at once. Even a worst-case fully-overlapped double rebuild bottoms out around 4-6
  consecutive no-damage turns before someone refires.
- Any single 1-damage hit from EITHER side resets the counter to 0, and every affordable attack
  deals >= 1. So a real fight cannot string 10 no-damage turns without both sides being unable to
  attack for 5 straight rounds - the definition of a genuine stall.

10 sits at ~2x the realistic worst-case legit stretch (comfortable margin, no false-fire) while still
ending the softlock within ~1-2 seconds of auto-play. Recommended band was 8-12; 10 is the midpoint
with the strongest safety margin. Tunable via a single `const STALEMATE_LIMIT := 10` next to the
JuiceTuning block; do not scale it by Auto.

---

## 4. The resolution (decision 3)

**Soft "called draw."** The breaker ends the fight with the EXISTING `Combat.Result.SURVIVABLE_LOSS`
so all downstream flow (run advance, root routing, music) stays on a known path - but the driver
SPECIAL-CASES the stalemate to SKIP the normal SURVIVABLE_LOSS consequence (no part forfeit, no
scrap). Both cores are alive by construction (the fight was ONGOING - neither core died). Cozy-fair:
neither Manabit is unmade, nobody loses a bit for a duel nobody won.

Rationale:
- The ordinary SURVIVABLE_LOSS means "you were defanged - the victor earned a broken part of yours"
  (combat_screen.gd:1000-1001, `_fill_outcome` forfeit branch). A stalemate is NOT that: nobody
  landed the finish, nothing was earned, and there may be no broken part at all (a pure guard stall
  breaks nothing). Forcing a forfeit would be arbitrary and punitive, and could hand the "victor" a
  part they never won.
- Not an exploit: a stalemate pays NO purse and NO loot (WIN-only rewards), damage PERSISTS on the
  carried Manabit in a venture (no heal), and forcing a stalemate needs a pathological build that the
  §5 nudge actively discourages. There is nothing to farm.

Driver mechanics:
- Add a member `var _stalemate := false`, reset to `false` in `_start`.
- When the counter reaches the limit while `combat.outcome() == ONGOING`, set `_stalemate = true`
  and call the existing `_finish(Combat.Result.SURVIVABLE_LOSS)`. This reuses the whole existing
  loss choreography (`_loss_slump`) unchanged.
- In `_fill_outcome` (combat_screen.gd:1558): if `_stalemate`, do NOT render the "Forfeit a broken
  part" list - render the called-draw line + the end button only. (Note: when nothing broke, the
  existing `any==false` path already skips the forfeit - the special-case makes it intentional and
  also covers a stalemate that happens to have incidental broken non-weapon parts.)

---

## 5. Player-facing copy + Venture treatment (decision 4)

Banner copy (warm register, hyphens only). Add a `_stalemate` check at the TOP of `_banner_text`:

- Spar (no stakes):
  `The duel is called - neither could land the finish. Back to the bench.`
- Bout / Venture (stakes):
  `The duel is called - neither could land the finish. You both limp off, even.`

`_fill_outcome` called-draw line (in place of the forfeit list):
  `Nobody landed the finish - no bits change hands.`

Venture/run treatment: YES, the Venture/run path treats a stalemate-SL exactly like any
SURVIVABLE_LOSS for FLOW. `root.gd:161` calls `run_screen.resolve_fight(last_result)` and
`run_screen.resolve_fight` (run_screen.gd:812-836) presses on via `run.advance()` on any non-DEATH
result - a stalemate advances the run "even," weaker, damage persisted, no loot, no forfeit. The kit
lane (`_resolve_kit_fight`, run_screen.gd:841-871) already routes non-WIN/non-DEATH to
`_finish_kit(true, "You limp home - but the salvage is safe.")` - a stalemate keeps the satchel,
same as any survivable kit loss. Both are correct as-is; the ONLY driver divergence is skipping the
in-combat forfeit UI. `root.gd:165-166` (`Music.subdue` on SURVIVABLE_LOSS) is fine unchanged.

---

## 6. Build-time affordability nudge (decision 5)

**YES - ship it**, in `ui/workshop.gd`, reusing the D3 fragility-cue pattern in `_refresh_bank`
(workshop.gd:896-920). It makes the stalemate STATE rare and self-evident at build time; the breaker
remains the actual softlock fix (a build can still DEGRADE into the state mid-fight when arms break,
or when a lent/box core changes energy).

Condition: the build has at least one offensive bit (SINGLE/MULTI) but NONE is affordable at full
mana - i.e. `min(mana_cost over offensive bits) > derived().energy`. That bit can never swing.

- Add a read-only helper mirroring `_offensive_count()`, e.g. `_min_attack_cost()` returning the
  cheapest SINGLE/MULTI `mana_cost` among seated, enabled, ability-bearing bits (or -1 if none).
- In the `ok` branch of `_refresh_bank`, add a tier that RANKS ABOVE `lone_weapon` (a never-affordable
  weapon is a guaranteed stall, strictly worse than a fragile one):
  `Ready to bind, but it can not swing: its cheapest weapon costs ✦N mana and it can only hold ✦M.`
  (N = min attack cost, M = energy; use `Tokens.STRAIN_TEXT`.)
- Read-only, mirrors the resolver's notion exactly like the existing D3 cue comment
  (workshop.gd:939-941). No resolver dependency.

---

## 7. Insertion map (for the implementer - all in ui/combat_screen.gd unless noted)

- `const STALEMATE_LIMIT := 10` near the JuiceTuning block.
- `var _noprog_turns := 0` and `var _stalemate := false` with the director state (~line 104-118).
- `_start` (combat_screen.gd:164): reset `_noprog_turns = 0`, `_stalemate = false`.
- `_apply` (combat_screen.gd:326): around `action.call()`, snapshot combined HP before/after; if HP
  decreased set `_noprog_turns = 0`, else `_noprog_turns += 1`.
- The player-Wait button (combat_screen.gd:1546, `w.pressed.connect(_after)`): route it through a
  wrapper that does `_noprog_turns += 1` before `_after()` - a wait is a no-progress turn that
  bypasses `_apply`.
- `_after` (combat_screen.gd:354): BEFORE the normal outcome check, if `combat.outcome() == ONGOING`
  and `_noprog_turns >= STALEMATE_LIMIT`, set `_stalemate = true` and `_finish(SURVIVABLE_LOSS)`;
  return.
- `_banner_text` (combat_screen.gd:991): top-of-function `if _stalemate` -> the §5 called-draw copy.
- `_fill_outcome` (combat_screen.gd:1558): `if _stalemate`, render the called-draw line + end
  button, skip the forfeit list.
- `ui/workshop.gd` `_refresh_bank`: the §6 nudge.

Nothing above touches `combat/combat.gd`, the contract classes, the save schema, or the 13 fixtures.

---

## 8. Verify lane (forced repro)

New headless test `tests/smoke_stalemate.gd` (hyphens only, seeded/deterministic), run with:
`& "G:\Godot\Godot_v4.7-stable_win64_console.exe" --headless --path G:\ClaudeApps\manabit -s "res://tests/smoke_stalemate.gd"`

Forced recipe (from the diagnosis): player build with an offensive arm whose `mana_cost > energy`
(a low-energy core + an expensive nuke arm) vs a foe that has ONLY GUARD parts (foe AI can only
guard). Assert, driving turns through the combat driver:
1. `combat.outcome()` stays ONGOING and combined HP never decreases (the resolver alone never ends
   it) - baseline confirmation the stalemate is real.
2. Within STALEMATE_LIMIT no-progress turns the driver fires the breaker and `last_result ==
   Combat.Result.SURVIVABLE_LOSS` with `_stalemate == true` and `_state == "over"`.
3. No part was forfeited and no scrap changed (soft called-draw), and neither core died.

Regression gate (unchanged, must stay green after the change): `smoke_contract` (empty resolver
diff), plus the full 14 fast gates and `smoke_kit_sim`. A resolver `git diff --stat` on
`combat/combat.gd` must be EMPTY.

---

## 9. Return summary

- Spec: `design/balance/stalemate-breaker.md`
- STALEMATE_LIMIT: 10 consecutive no-progress turns (5 rounds)
- Resolution: soft called-draw -> existing SURVIVABLE_LOSS outcome, forfeit + scrap SKIPPED, both
  cores survive; run/venture presses on "even" like any SURVIVABLE_LOSS
- No-progress signal: combined-HP-did-not-decrease across the turn (HP-delta, not last_events)
- Nudge: shipped in ui/workshop.gd (cheapest attack cost > energy), D3 pattern
