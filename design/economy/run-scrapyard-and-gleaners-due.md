# THE SCRAPYARD + THE GLEANER'S DUE - Run Economy Design (Venture depth wave)

STATUS: LANE DESIGN, economy designer, 2026-07-19. Settles open items (2) Scrapyard node type
and (3) HP-scaled salvage. Design-only - no code this wave. Implementation is gated on the
measurement gates in section 6; every number below marked ASSUMED stays provisional until its
gate number exists in tools/sim/out/.

Frozen laws honored throughout: node()/advance()/can_extract semantics untouched (junctions
still collapse in place, no graph walker), crack-and-see parity (everything seeds off the run
seed), the satchel firewall (kit runs never bank mid-run, purses flat, Glimmer 0), resolution
determinism, section 13 untouched, save schema untouched (runs stay session-local).

---

## 1. THE SCRAPYARD - what it is

A mid-run economy stop: a heap of honest junk between the elite fight and the pre-boss rest.
It gives satchel scrap a mid-run USE, which is the whole point - today the satchel is dead
weight until flush, so the only run decision is press-or-go-home. The Scrapyard adds
spend-now-on-power vs carry-it-home, at the exact moment the satchel is fattest.

Vignette (warm, 67 chars): "A heap of honest junk. Somebody sorted it once, then wandered off."

### Placement (DECIDED)
- New node type `SCRAPYARD`, inserted in BOTH templates immediately AFTER the elite junction
  and immediately BEFORE the pre-boss rest. Spine becomes 6 steps:
  pos 0 FIGHT - 1 REST - 2 JUNCTION elite - 3 SCRAPYARD - 4 REST - 5 JUNCTION boss.
- Placement is stated RELATIVE (post-elite, pre-rest-2) so it survives producer reconciliation
  if the Event lane also inserts a node.
- Why here: the player arrives holding the run's biggest satchel swing (35 full-rate / 17
  halved) with the boss decision ahead; and the free (kit) / paid (own) mend at the rest stays
  AFTER it, so a bad dig can never strand a damaged build without a repair stop before the boss.
- Both templates, same position: template value parity holds (the Scrapyard is a sink with a
  capped, worse-than-cost gamble return - see stall math), so neither road is richer.
- can_extract is untouched and returns false here by construction (not a REST). The own-build
  walk-away point before the boss is preserved - this design does not touch the boss-retreat
  asymmetry item (4), which is another lane's call.

### Seeding (crack-and-see parity)
- All stall stock and the dig outcome are pure functions of (run seed, stall tag). Kit runs use
  kit_seed. Own runs must STORE the map seed at start() in a session-local var (today
  `_make_map(randi())` throws it away) - zero save impact, runs die with the session.
- Leaving and returning shows the same stock. Nothing re-rolls. Same box = same road = same heap.

### The three stalls (stock 1 each, once per run)

**Stall 1 - RUMMAGE (kit runs only). The gamble dig.**
- Price: 8 satchel scrap (ASSUMED). Button copy: "Rummage the heap  ⚙8"
- Seeded outcome: 55% a LENT COMMON body bit / 30% filings (+4 satchel back) / 15% a LENT RARE
  body bit (ASSUMED odds).
- Lent bits ride the CARRIED box build (install-or-leave choice; installing swaps the socket),
  exactly the box_core lend precedent: never appended to player.bits, never compendium-marked,
  gone at run end whether you win, walk, or die. They return POWER, never money.
- Draw pools: COMMON lends from the player's DISCOVERED commons when >= 5 are discovered, else
  from the 13 base fixtures (starter-known set). RARE lends from discovered RAREs; none
  discovered = the outcome downgrades to filings. Coffers stay the sole discovery channel -
  a lend never previews undiscovered content.
- Outcome copy: bit "Down near the bottom - a %s. The box wants it." / filings "Mostly rust.
  ＋⚙4 in filings, at least." / rare "Buried treasure - a %s! It rides with the box til home."

**Stall 2 - THE PICK OF THE HEAP (kit runs only). One honest purchase.**
- ONE seeded COMMON body bit, 25 satchel scrap (ASSUMED - matches Fettle's COMMON Find, so the
  heap never undercuts the Barrow; paying with pre-flush satchel that can still die makes it
  strictly riskier than buying at Fettle's, so equal price cannot dominate).
- Selection: seeded from DISCOVERED, non-core COMMON ids, 3:1 weighted to ids owned 0 loose
  copies (the Broker's own gap-filler rule).
- It fills `satchel_bit_id` ONLY if empty, and foe loot is refused afterward: the 1-COMMON loot
  cap is one shared slot, held by construction. Flushes on safe end, lost on death, like today.
- Copy: "One clean piece, set aside. ⚙25 - it comes home if you do."
- Self-throttle worth naming: on halved days the max pre-boss satchel is 17 < 25, so the bank
  channel is unaffordable exactly when a grinder would abuse it. Intended.

**Stall 3 - FIELD PATCH (own-build runs only). A rough discount mend.**
- Mend up to HALF your missing HP at 1 scrap per 3 HP (rests are 1 per 2), wallet-priced like
  all own-run repairs. Copy: "A rough patch - 3 HP a filing, half your dents at most."
- Kit runs never see it (their rest mends are already free); own runs never see stalls 1-2
  (no satchel exists, and a wallet-priced lend/buy would open bank-leak seams for zero design
  win while own-venture survival sits at 8-29%).

### Firewall audit - every rule, and why each offer honors it
1. **Satchel never banks mid-run**: every kit purchase DEBITS the satchel; the only credit is
   Rummage filings, which credit the SATCHEL (and spill on death like everything else). No code
   path touches player.scrap during a kit run.
2. **Purses flat / purse-cap invariant**: the Scrapyard pays no purse; the 75/37 route-cap check
   sums FIGHT tiers only and is untouched. The dig's expected scrap return is 0.30 x 4 = 1.2
   per run maximum - a sink that leaks back 15% of its own price, never a faucet.
3. **Glimmer 0**: no Glimmer price, yield, or mention exists at the heap.
4. **Loot cap 1 COMMON**: the Pick shares satchel_bit_id; one slot, buy-or-loot, whichever
   comes first, enforced structurally not by counter.
5. **Kit bits never bank / never melt**: lent bits are fresh instances outside player.bits
   (box_core precedent) and kit runs cannot extract at all (is_kit blocks can_extract).
6. **No discovery leak**: Pick is compendium-gated; lends draw discovered-first and never mark
   the compendium.
7. **Crack parity / no re-roll scum**: all outcomes seed-pure; the nonce still advances only on
   commit.
8. **Death spills**: scrap spent at the heap is simply gone; a lent bit dies with the box; no
   refunds anywhere.
9. **Save schema frozen**: nothing persists - stock derives from the run seed each time.

---

## 2. THE GLEANER'S DUE - HP-scaled death salvage

Today DEATH zeroes the satchel flat. The cozy principle: a brave death at the boss's door
should sting less than a wipeout at the first fork - but never rival walking home.

### The ordering law (named, exact)
**SAFE END > DEEP DEATH > SHALLOW DEATH**, with a guaranteed sting margin:
death NEVER keeps more than half of what a safe end would have flushed.

### The formula shape (kit runs)
```
kept = floor(satchel_scrap * K_tier * (0.5 + 0.5 * H))
```
- `K_tier`: 0.50 if the killing fight's tier is "boss", 0.25 if "elite", 0 otherwise
  (skirmish never aims the core - death is impossible there; 0 is the fail-safe). ASSUMED.
- `H`: remaining-HP fraction of the surviving non-core body bits at the moment of death
  (sum current / sum max; 0 if none survive). The pickers save more from a wreck that still
  has meat on it - this is the "carried build's remaining value" term.
- `satchel_bit_id` is ALWAYS lost on death (the bit was in the wreck). Scrap only.
- Universal bound: max F = 0.50 x 1.0 = 0.50, so kept <= floor(S/2) always. Head-home flushes
  S. The margin Y is therefore >= 50% of the carried satchel, plus the tucked bit, always.
- Worked canon: S=35 (full-rate pre-boss), H=1: boss death keeps 17, elite death keeps 8.
  H=0: boss 8, elite 4. Deep > shallow both fractionally and absolutely.

### The daily-halving loophole (DECIDED, closes economy.json LOW flag)
A death that PAYS (kept > 0) now calls note_kit_run - it counts toward the 2-run full-rate
allotment. Without this, deliberate deep deaths could farm full-rate half-purses after the
halving kicks in. With it, EV(press-and-die on purpose) < EV(Head-home) at every state:
you keep <= S/2, forfeit the bit, and burn the same daily slot. Provable, and spot-checked
in the sim gate below.

### Own-build runs (the wreck)
```
wreck = floor(K_tier * sum_over_surviving_body_bits( Broker.salvage_scrap(bit) * hp_i/max_i ))
```
- Same K_tier. The core pays 0 - consistent with Fettle's law ("won't melt a bound soul").
- Anti-exploit proof: wreck <= 0.5 x the home-melt value of the same bits, so suiciding a
  build is strictly dominated by melting it at home; extract keeps everything at full HP, so
  extract strictly dominates both. The ordering law holds for own builds for free.
- This is a RUN-death credit only. Bouts keep CH-08/CH-09 law: forfeit pays zero. The
  Gleaner's Due must never fire outside The Run.

### Copy (player-facing, warm, honest)
- Kit deep death: "The pickers drag back what they could - ⚙%d of your salvage."
- Kit shallow death: "Scattered where it fell. The pickers glean ⚙%d."
- Kit death, kept 0: keep the current line ("The scrap scatters where it fell...").
- Own-build death: "Word from the gleaners: ⚙%d pulled from the wreck. The core is gone."

---

## 3. Knobs summary (all ASSUMED until gated)

| Knob | Value | Gate |
|---|---|---|
| Rummage price / filings / odds | 8 / +4 @30% / C 55% R 15% | G1, G2 |
| Pick price | 25 satchel | G3 |
| Field patch rate / cap | 1 scrap per 3 HP / 50% of missing | G4 |
| K_boss / K_elite | 0.50 / 0.25 | G5 |
| H blend | 0.5 + 0.5 x hp_frac | G5 |
| Own wreck K | same K_tier | G6 |
| Death counts a run when kept > 0 | yes | G7 |

## 4. Which smoke checks change

**smoke_run.gd** (currently 32 checks incl. the validator):
- "map has 5 steps" becomes "map has 6 steps".
- The deterministic walk re-indexes: rest 2 moves to pos 4, boss junction to pos 5, over at 6.
  "pos 3 is REST + can extract" becomes "pos 3 is SCRAPYARD + cannot extract" plus a new
  "pos 4 is REST + can extract".
- The validator's hardcoded junction pins (`r.pos = 2` / `r.pos = 4`) re-point to 2 / 5. The
  purse-cap sweep (75/37) is UNCHANGED - it sums FIGHT nodes only.
- NEW checks: scrapyard stock is seed-pure (same seed twice = same stock); the Pick respects
  the shared 1-COMMON slot; a lent bit is absent from player.bits after a safe flush; the
  ordering-law block (below); death with kept > 0 increments kit_runs_today.

**smoke_kit_sim.gd**: all existing bands UNCHANGED (the tripwire stands). Structural scans
survive (it finds junctions by scanning, not position). ADD one arm: Dud grade with a forced
best-case RARE lend still wins the boss <= 0.20 - the dig must not launder Duds past the
real-stakes band. If breached, RARE odds drop 15% -> 10% (pre-ratified fallback).

**smoke_kit.gd**: satchel flush tests gain death-keep cases (kept credits wallet on death,
bit always lost).

### The new ordering-law assertion (shape)
```gdscript
# THE GLEANER ORDERING LAW: safe flush > deep death > shallow death, never past half
ok = _c("gleaner: boss death, full wreck, S=35 keeps 17", RunState.death_keep(35, "boss", 1.0) == 17) and ok
ok = _c("gleaner: elite death keeps less (8)", RunState.death_keep(35, "elite", 1.0) == 8) and ok
ok = _c("gleaner: zero satchel gleans zero", RunState.death_keep(0, "boss", 1.0) == 0) and ok
var bound := true
for s in range(0, 76):
    for h in [0.0, 0.5, 1.0]:
        for t in ["elite", "boss"]:
            if RunState.death_keep(s, t, h) > s / 2:
                bound = false
ok = _c("gleaner: kept never exceeds floor(S/2) - death never rivals Head-home", bound) and ok
```

## 5. Wave-1 baselines cited (they exist - tools/sim/out/, 2026-07-19)
- economy.json: 30-day p50 wallet ~90 flat (85-95 band), faucet/sink surplus +1.8%; kit purses
  10/25/40 ratified UNTOUCHED in the wave-1 change order.
- ladder.json part B: own-venture survival 0.082 mid / 0.291 strong; mean net scrap -7.55 mid /
  -5.16 strong; mean repairs paid 8.6 / 7.5.
- smoke_kit_sim bands: node0 win >= 0.90 with 0 deaths; boss Gleaming >= 0.60, Dud <= 0.15,
  Dud dies more than it wins.

## 6. MEASUREMENT GATES (implementation may not lock a value before its number exists)
Economy v2 / ladder v2 must EMIT: kit_flush_mean (by depth), scrapyard_spend / scrapyard_return
counters, pick_take_rate, death_keep_mean, own_wreck_mean. These fields do not exist in wave-1
output - adding them is a precondition, per the change order's instrument-fix pattern.

- **G1 (Rummage economics)**: with the Scrapyard modeled at ASSUMED take-rates (Rummage 60% of
  runs reaching it, Pick 20% of full-rate runs), 30-day p50 wallet stays 85-95 and mean
  scrapyard scrap RETURNED <= 2 per run. Mean kit flush must land at or BELOW the wave-1
  baseline (band: -15% to +0%) - the heap is a sink, never a raise.
- **G2 (dig power)**: smoke_kit_sim new arm - Dud + forced RARE lend boss win <= 0.20; all
  existing bands green. Breach = RARE odds to 10%.
- **G3 (Pick vs the Barrow)**: pick_take_rate <= 40% of eligible runs AND Barrow COMMON Find
  purchase rate stays within +/-50% of wave-1 - the heap must not obsolete Fettle. Re-check the
  halved-day unaffordability (17 < 25) if purses ever retune.
- **G4 (Field patch)**: ladder v2 own-venture survival uplift <= +5pp vs 0.082/0.291; mean
  repairs paid stays in 5-12. The patch is convenience, not a difficulty lever.
- **G5 (Gleaner K + H)**: economy v2 mean death-run scrap <= 60% of mean safe-run scrap at
  equal depth (sting margin Y >= 40%); 30-day p50 wallet 85-95; faucet/sink imbalance < 5%.
  Drift above 95 = K drops to 0.40/0.20 (pre-ratified fallback).
- **G6 (own wreck)**: ladder v2 mean own-venture net scrap in [-10, +5] (wave-1: -7.55/-5.16).
  Above +5 = halve K for own builds. Ventures must never become a scrap faucet.
- **G7 (loophole closed)**: analytic proof in section 2 plus a sim spot check that deliberate
  deep-death EV < Head-home EV at every recorded state.

## 7. Coordination notes for the producer
- Spine collision: the Event lane may also insert a node. This design's placement is relative
  (post-elite, pre-rest-2) and survives a 7-step merge; the smoke_run re-index must happen ONCE,
  jointly, after the merged spine is ratified.
- RouteBed renders 150px chip columns; 6 columns fit (940px), 7 is tight against the 720px-era
  layout budget - flag to the UI lane before implementation.
- The Gleaner's Due changes _resolve_kit_fight's DEATH branch and adds one RunState pure
  function (death_keep) - zero section 13 contact, zero save contact.
