# THE FUN RUBRIC

*The loop's instrument for "is this more enjoyable", not just "is this correct".*
*Ratified 2026-09-01. Companion to design/process/autonomous-loop.md.*

Sixteen gates prove MANABIT works. None of them prove it is worth playing. A loop
that optimises only what it can assert will hold correctness perfectly flat while
enjoyment drifts, because correctness is the thing with a red light attached.
This document gives fun a red light too.

It is deliberately built from **this game's own measured failures** rather than from
a generic design listicle. Every principle below is followed by the defect in this
build that proves the principle has teeth here.

---

## 1. The three pillars (owner-set, not negotiable)

Every change must serve at least one and damage none:

- **Tactile juice** - the snap, the weight, the thunk. The moment-to-moment.
- **Optimization / theorycraft** - a build space with real decisions in it.
- **Expression / collection** - a shelf of things that are yours and worth having.

Under those sits the identity spine: **Artificer = immortal maker. Manabit = mortal
creation. Mana core = crafted soul and life bar.** You always survive; your
creations do not. A change that makes your creation cheap makes the whole wager
cheap.

---

## 2. The four lenses

Carried forward from the 2026-07-21 AI playtest panel so scores stay comparable
across iterations. Score each 1-10 whenever an iteration touches its territory.

| Lens | Cares about | Baseline 2026-07-21 |
|---|---|---|
| **The Newcomer** (first two hours) | Legibility, forgiveness, the first hour teaching rather than punishing | 6 / 10 |
| **The Optimizer** (min-maxer) | Decision density, build diversity, a wheel that cycles, honest signals | 5 / 10 |
| **The Cozy Collector** | Low-stress accumulation, surprise that stays surprising, a shelf worth filling | 6 / 10 |
| **The QA Hunter** | Promises the build actually keeps | 6 / 10 |

**Aggregate 5.75 / 10.** Read it as "a charming, mechanically sound toy whose
central stakes-and-depth promises are half-delivered." It is a tracking number, not
a review score. **The loop's job is to move it, and to be honest when it does not.**

Every iteration names the lens it moves and the observable that shows the movement.
An iteration that cannot name one is polish, and polish is fine as long as it is
logged as polish and not as progress.

---

## 3. Seven principles, each with its local proof

### P1. A choice needs more than one live option, a legible difference, and a consequence.
Fewer than three and it is not a decision, it is a formality.
> **Proof:** the Optimizer sits at 5/10 because "the legal build collapses to one
> greedy answer identical across every core" and target selection has no decisions at
> all (MULTI auto-picks lowest HP, SINGLE-core is fixed). The build screen looks like
> a decision and measures like a formality.
> **Test:** count distinct near-optimal options. If the count is 1, the screen is
> decoration. (Instrument L-10 exists to make this measurable rather than argued.)

### P2. Stakes must be demonstrated, not labelled.
A threat the numbers cannot deliver is a bluff, and players find bluffs faster than
designers expect.
> **Proof:** two of six "core-hunting" elites have a measured 0% death rate. Pindrop
> literally cannot kill you - it has zero SINGLE moves and the core-hunt branch only
> fires for SINGLE. The game's central promise, "wager your build, elites hunt your
> core", is false for a third of the roster.
> **Test:** for every stated threat, the measured rate of the threatened outcome is
> greater than zero.

### P3. Labels never lie. The card text IS the rule.
Already project law. It is listed here because the law is being broken by
measurement while everyone believes it is held.
> **Proof:** the lane flavoured as menace ("the foe fields heavier bits") is the
> SAFEST at DEATH 0.00; the lane flavoured as a gift ("mended 4 HP") is the
> DEADLIEST at DEATH 0.59.
> **Test:** the ordering a player infers from the copy matches the measured ordering.

### P4. Failure teaches, or it is just punishment.
A loss the player cannot explain is noise. A loss they can explain is a lesson and a
reason to try again.
> **Proof:** a deploy-legal core+1-arm build passes the Workshop gate, then loses on
> turn 1 before the player acts, and the loss screen never says "you had no way to
> attack." The Newcomer's verbatim reaction: "I lost and I never even moved."
> **Test:** every loss state names its cause in the player's vocabulary.

### P5. Reward must track difficulty, and rarity must track power.
An inverted signal is worse than a flat one, because players learn the signal before
they learn it is lying.
> **Proof:** EPIC Grinlet measures -0.1225 and EPIC Seer -0.0058 while COMMON Girder
> Fist measures +0.191. Separately, the stake-10 fight loots a melt-45 EPIC while the
> stake-20 fight loots melt-20.
> **Test:** rank correlation between advertised value and measured value is positive.

### P6. Variance must feel authored. A modal outcome is the real experience.
Designers remember the tails; players live in the mode.
> **Proof:** the free Box of Scrap's modal roll is Fair at 32%, and Fair survives at
> ~0.00 at every skill tier. The median first free box is a guaranteed unwinnable
> death. Nobody designed that; it is what the distribution does.
> **Test:** name the modal outcome of every gamble and ask whether it is the
> experience intended.

### P7. Surprise must survive a second look.
Collection joy is built on the next thing being unknown.
> **Proof:** the coffer RNG stream is a compile-time constant and is not persisted,
> so every fresh boot replays a byte-identical brass stream. Every player alive
> cracks the same "surprises" in the same order, and can scum them by relaunching.
> **Test:** two fresh sessions produce different reveal orders.

---

## 4. Standing anti-patterns

Cheap ways to look like progress that the loop must not take:

- **Numbers going up is not depth.** More bits in a catalog that collapses to one
  greedy answer adds shelf length, not decisions.
- **Juice on a hollow beat.** Animation cannot make a formality feel like a choice.
- **Difficulty as a substitute for stakes.** A longer fight is not a tenser one -
  see the 221-turn wall fights.
- **Content as a substitute for a fix.** A new family does not repair a wheel that
  does not cycle.

---

## 5. How this gets used

At Phase 2 (PRE-STATE), the criterion must name the lens it moves and the principle
it serves. At Phase 5 (JUDGE), the measured result is checked against the criterion,
and the lens score is re-estimated only when there is a measurement behind it.

**Where the loop stops:** it can measure P1-P7 and it can look at a rendered frame.
It cannot feel a control, hear a mix, or tell the owner what the game should be. AI
persona judgment is a proxy for playtesting, and the honest thing to do with a proxy
is to say so every time it is used.
