# OWNER QUEUE

Decisions the autonomous loop is not allowed to make, with the case already built.
**The loop writes here and keeps moving.** Nothing in this file blocks an iteration.

Answer any of these in a sentence and the loop picks it up on the next pass.

---

## Q1. Turn cap and wall-fight pacing (D13 ADR) - section 13 territory
**The measurement:** `combat.gd outcome()` has no turn counter. 27.2% of all
damaging hits land for exactly 1 (the `maxi(1,...)` DEF floor at `combat.gd:107`).
A Cogsworth mirror resolves at turn 167; GUARD-vs-Brassmore at 221; vs Gildfall 169.
The ladder top is unreachable at every skill tier (`reached_top` 0.00) for the same
reason. Fights provably terminate, so this is a grind, not a lock.

**Why the loop stops:** the resolver is frozen. Any cap needs a tiebreak rule and
that changes fight outcomes.

**Options:** (a) turn cap with a core-HP-percentage tiebreak, (b) rising damage
after turn N, (c) bout-mode change so a core-racer can finish a mending wall.
**Recommendation:** (a) - it is the smallest rule that also uncaps the ladder.

---

## Q2. Save schema v5 - the cozy endgame bundle
**The measurement:** `PlayerState._init` always runs `PackRoller.new(20260711)` and
`SaveManager` persists no roller or pity field, so every boot replays a byte-identical
brass stream (brass #2 is always the EPIC `carillon_cadets_arm_grandpeal`) and pity
resets each launch. Glimmer: 57.2 earned per player over 30 days, **0.0 spent on all
30**. Compendium: 12.6% of players reach 80% in a month.

**Why the loop stops:** all three fixes need new persisted fields. Precedent says
additive fields are safe (v2, v3, v4 all shipped additive), but the schema is listed
as frozen and unfreezing it is the owner's call.

**Ask:** may the loop ship save v5 as strictly additive fields (roller position,
pity counter, plus one Glimmer sink ledger), with v4 migrating clean?
**Recommendation:** yes - the panel estimates this alone moves the Cozy Collector
from 6 to ~8, and it is the single biggest measured hole in the collection pillar.

---

## Q3. Speed axis payoff (D11 ADR) - section 13 territory
**The measurement:** speed buys initiative and nothing else. Sniper attack rates
measure 0.00 / 0.00 / 0.03 / 0.00. The entire silksteel core-sniper family beats
nobody in the pentagon. One of five advertised build directions is inert.

**Why the loop stops:** a real payoff means a resolver hook.
**Recommendation:** decide this after Q1 - a turn cap changes what speed is worth,
and pricing the axis twice would be wasted work.

---

## Q4. Blender work - hardware the container does not have
`design/art/wave2-mesh-work-order.md` is written and waiting. 20 of the 100 catalog
bits ship on procedural placeholders. Needs the second PC's Blender rig. Icons
follow the meshes; `smoke_art` extends to 100 when they land.

---

## Q5. Taste sign-off - the loop can now see, which is not the same as deciding
`tools/loop/shots.sh` renders every screen and the loop reviews the frames, so
visual regressions and fit bugs no longer need the owner. **Direction still does.**
The standing rule from the Workshop reskin holds: the loop proposes a direction with
frames attached, the owner signs it, then it gets built.

---

## Q6. Cadence and authorisation
How often should the loop run unattended, and how much may it ship per pass?
Current default if unanswered: **one headline backlog item per iteration, always on
the working branch, always behind a PR, never merged without you.**

---

## Q2b. The brass coffer's odds cannot be made numerically honest without Q2
**Raised by iteration 4.** Brass prints EPIC 8%% and rolls **14.8%%** measured over
40,000 coffers (`tools/sim/odds_probe.gd`). The cause is pity-at-9, which is real and
generous. The loop shipped what it could without you: the rule is now disclosed in
words on both screens, derived from the constant and gated.

What it could NOT ship: one honest printed number. Pity is not persisted (`grep pity
meta/save_manager.gd` returns nothing), so it resets every launch - 14.8%% is a
marathon-session ceiling and a relaunch-often player sees nearer 8%%. Any single
number would be wrong for one of them.

**This is the same unlock as Q2.** Approving additive save v5 fixes the coffer odds,
the scummable stream (D5), the Glimmer sink (D6) and the discovery faucet (D9) - four
measured holes on one decision.

---

## Q7. The reward ceiling is flat across the last stake step
**Raised by iteration 7, measured (`tools/sim/wager_probe.gd`).** Melt value is a
rarity proxy (EPIC 45 / RARE 20 / COMMON 8, `economy/broker.gd:9-13`). By what a
player actually loots - and they DO choose, one button per bit:

    stake  5    COMMON or RARE
    stake 10    RARE or EPIC       Cogsworth and Thornlash already yield an EPIC
    stake 20    EPIC or EPIC       Brassmore, Gildfall

Grand Warden Cogsworth costs 10 scrap. Sunking Brassmore costs 20, is the hardest
fight in the game by measurement (WIN 0.305 under optimal aggression), and pays the
same reward TIER. The last step of the ladder doubles the price and the difficulty
for no increase in what you can win.

**Why the loop stopped rather than tuning it.** EPIC is the top rarity; there is
nothing above it to drop. Fixing this needs a new reward AXIS, not a number:
a larger purse at boss tier, a choice of two bits instead of one, a unique
boss-only bit, or something non-material. That is a decision about what the top of
the ladder is FOR, and it is yours.

**Recommendation:** the cheapest honest option is a boss-tier purse bump, since the
satchel already exists and it needs no new content. A unique boss-only bit is the
better long-term answer and the more expensive one.

---

## Answered

*(nothing yet - this file starts with the first autonomous pass)*
