# VENTURE DEPTH - WAVE 3 RECONCILED SPEC
## Events, the Scrapyard, HP-scaled salvage, and the boss-retreat ruling

**STATUS: TEAM-RATIFIED 2026-07-19 - IMPLEMENTATION GATED on wave-1 ladder.json + economy.json numbers (gates listed inline)**

Producer reconciliation of three lane specs:
- `design/run/event-node-wayside.md` (encounter lane)
- `design/economy/run-scrapyard-and-gleaners-due.md` (economy lane)
- the Game Director's boss-retreat ruling + run coherence pass (this wave)

The director's road-composition ruling GOVERNS placement. Where a lane spec
conflicts with it, this document is the surviving text. Frozen laws honored
throughout: node()/advance()/can_extract() semantics untouched, junctions
collapse in place, crack-and-see parity, the satchel firewall, resolution
determinism, section 13 untouched. Design-only wave: nothing outside design/.

---

## 0. PRODUCER RULINGS (what survived, what died)

| Lane proposal | Ruling |
|---|---|
| Encounter: new EVENT node TYPE at pos1, 50% presence roll | KILLED as a node type. Events land as a REST FLAVOR (director's coherence ruling). The 50% frequency survives BY CONSTRUCTION: the flavor is template-bound and the template pick is already abs(seed)%2. No presence roll, no d1 draw. |
| Encounter: event scrap outcomes [-4,+6] + found-bit outcome | KILLED. Events are MONEY-NEUTRAL in v1 (director's constraint). Outcome vocabulary is mend / wear / next-fight rider only. This deletes the mid-run wallet faucet risk and keeps the satchel firewall untouched by events entirely. |
| Encounter: extract window moves pos1 to pos3 on event roads | DISSOLVED. A flavored rest is still a REST - can_extract() stays true at pos1 on every road. The event's price of admission is its own push risk, not a deleted exit. |
| Economy: SCRAPYARD node TYPE, 6-step spine | KILLED as a node type. The spine stays 5 steps. The scrapyard lands as the pos1 REST flavor on Template B (Magpie's Heap). smoke_run "map has 5 steps" is unchanged. |
| Economy: Pick of the Heap (25-scrap COMMON buy) | CUT from v1. At the ruled position the kit satchel holds at most 10 (node-0 purse), so a 25 price is structurally dead, and repricing under Fettle's 25 Find is forbidden (the heap must never undercut the Barrow). Revisit only if a future wave adds a post-elite stop. |
| Economy: Field Patch (own-build mend at 1 scrap per 3 HP) | CUT. A flavored rest already sells repair at 1 per 2 HP; a cheaper patch at the same bench makes the plain repair a dominated choice. |
| Director: sell-HP-for-scrap trade at the scrapyard | CUT. At a repairing rest it is a 2HP-to-1-scrap-to-2HP arbitrage loop and a trap option going into the elite. HP-scaled salvage lives in the Gleaner's Due instead (section 4) - death-side, where remaining HP honestly scales what the pickers recover. |
| Economy: Gleaner's Due death salvage + halving-loophole closure | ADOPTED wholesale. This is the ruled answer to open item (3) HP-scaled salvage. |
| Director: all-or-nothing boss retreat, The Last Lantern, honest copy, two-step abandon | ADOPTED wholesale (section 5). |
| Encounter: foe-worn rider, max-not-sum, pre-bell seam | ADOPTED (section 2.5), promoted to a smoke_run check. |

Open items settled: (1) Event = the Wayside Shrine rest flavor. (2) Scrapyard =
the Magpie's Heap rest flavor. (3) HP-scaled salvage = the Gleaner's Due.
(4) Boss-retreat asymmetry = ruled all-or-nothing, no priced retreat.

---

## 1. THE RULED ROAD (both templates, spine unchanged)

The spine stays exactly 5 steps. REST steps gain one new template field:
`flavor` ("camp" | "event" | "scrapyard") plus flavor payload stamped at
map-make. A flavored rest still repairs and still extracts - node(),
advance(), at_rest(), and can_extract() are byte-identical code.

**Template A - "The Old Road"** (shrine stories)
```
pos 0  FIGHT     Skirmish (clean Rusty)
pos 1  REST      flavor=event      "Wayside Shrine"
pos 2  JUNCTION  elite  (Bramble Cut/overgrown vs Wardens Wall/second_wind)
pos 3  REST      flavor=camp       "The Last Lantern"
pos 4  JUNCTION  boss   (Gilded Gate/tailwind vs Heralds Walk/rusted)
```

**Template B - "The Quiet Spiral"** (scrap heaps)
```
pos 0  FIGHT     Skirmish (clean Rusty)
pos 1  REST      flavor=scrapyard  "Magpie's Heap"
pos 2  JUNCTION  elite  (Powder Row/second_wind vs Silk Stair/rusted)
pos 3  REST      flavor=camp       "The Last Lantern"
pos 4  JUNCTION  boss   (Gilded Gate/rusted vs Heralds Walk/tailwind)
```

- Junction positions, lane pairs, challengers, and modifiers are UNCHANGED.
- The pos3 REST is ALWAYS plain camp, both templates, present and future -
  it is the last repair and the final exit, and it never carries a side
  offer that competes with the extract-or-press decision (section 5).
- Purse-cap invariant untouched by construction: no FIGHT step changes, no
  new tier keys, 75 full / 37 halved stays byte-identical. The validator's
  FIGHT-only sweep needs zero edits.
- Session length holds: 3 fights + 2 rest-beats + 2 junction choices + one
  flavor beat, inside the 5-10 minute cozy window.
- Each road reads distinct on the RouteBed at a glance: Old Road carries the
  shrine glyph, Quiet Spiral carries the heap glyph (section 2.6 / 3.4).

---

## 2. THE WAYSIDE SHRINE (Template A pos1 - the Event flavor)

### 2.1 Shape and sequencing (the teeth ruling)

The bench works first, the shrine speaks on the way OUT:

1. Arrive at pos1: normal rest panel - repair (free for kits, scrap for own
   builds), extract / Head home, all unchanged.
2. Press on: instead of advancing, the shrine vignette opens - name, 2-3
   warm lines, two EventCards, two-step commit (exact PathCard discipline).
3. Resolve: outcome applies and is stamped on the node in place. The button
   becomes "Onward ▸", which advances.

Why on departure: rests mend (free for kits), so an arrival-side event has
no stakes - any wear would be erased at the same bench. Resolved at the
gate, wear rides into the elite junction and the next mend chance is The
Last Lantern. That is the push-your-luck the event sells, honestly.

Extraction / Head home never requires resolving the shrine - walking away
from the road is walking away from the wren too. Only the FORWARD verb
passes the shrine.

Known value asymmetry (accepted, gate-watched): a full-HP box gets nothing
from a mend outcome. Mend copy stays honest at full HP ("already hale - it
pats your hull and lets you by"). Safe choices are rider-weighted across
the set so a full box always has a live safe pick. G1/G2 watch the balance.

### 2.2 Seeding (crack-and-see parity)

All shrine draws derive from the map_seed `_make_map` already receives, via
one pure integer mix (splitmix-style, documented in code). No presence
draw - presence IS the template pick (abs(seed)%2, untouched).

```
h  = mix(map_seed)        # pure, stateless
d2 = h % 23               # weighted event pick (total weight 23)
d3 = (h / 100) % 100      # hidden outcome roll, stored on the node
```

- Rest step gains: `{"flavor": "event", "event_id": <id>, "roll": d3,
  "resolved": false}` stamped at map-make.
- The push result is DECIDED at map-make and only REVEALED on choice. Same
  box = same road = same wren. No post-choice RNG feel-bad.
- Static probe `RunEvents.pick(seed) -> {event_id, roll}` so tests can pin
  seeds without walking a map.
- Own-build runs store their map seed session-local at start() (today
  randi() is thrown away) - zero save impact, runs die with the session.

### 2.3 Resolution law

New `meta/run_events.gd` (`class_name RunEvents`, table + pure resolve,
mirroring RunMods). `RunEvents.resolve(run, choice_i)`:

- No-op unless the current node is a REST with flavor "event", unresolved,
  and choice_i in {0, 1} (exact choose() discipline).
- Applies effects, then stamps the node IN PLACE: `resolved = true`,
  `chose`, `result_id`, `result_text`. Irreversible. Idempotent on re-call.
- The safe choice ignores the roll (deterministic by rule, provable in the
  smoke test).
- node()/advance()/can_extract() code untouched. The UI gates the forward
  verb behind resolution (same trust level as fights).

### 2.4 Stakes rails (money-neutral v1)

Every outcome is built only from these three verbs:

| Verb | Rail | Plumbing |
|---|---|---|
| mend N | N in [1, 6] | the shipped `RunMods._mend`, worn bits, capped at max_hp |
| wear N | total <= 4 HP per event, floor 1 HP, NEVER CORE, never disables - events are never lethal by construction | mirrored `_wear` pool walker in RunEvents, fixed slot order ARM_R, ARM_L, LEGS, BACK, HEAD |
| next foe worn N | next fight only; N is 1 (safe tier) or 2 (push tier), never above RunMods.WEAR; MAX-NOT-SUM vs the lane modifier - a rusted lane already at 2 gains nothing from a rider of 2 | `run.next_fight_rider` int on session-local RunState, consumed at the same pre-bell seam as `pre_fight_mend`, applied through the Challengers.make wear path, cleared after the bell |

NO scrap, NO satchel, NO loot, NO purse, NO Glimmer, NO bank, NO bench.
The event table carries no money fields at all - the validator asserts
their absence structurally (T7). Economy toggling events on/off must show
a zero-delta scrap curve (G14).

### 2.5 The rider (the sharpest edge, fenced)

- Magnitude cap 2, equal to RunMods.WEAR - a rider can never out-wear a
  rusted lane.
- MAX-NOT-SUM vs the lane modifier is a smoke_run CHECK (T8), not a code
  comment: rusted(2) + rider(2) = 2, never 4. Summing would start elites
  4 HP down and out-cozy them past the smoke_kit_sim bands without the sim
  ever seeing it (the sim fights lanes in isolation).
- Stored on session-local RunState, consumed at the pre-bell seam, cannot
  leak past the run or into bouts.

### 2.6 Launch set - 10 events, total weight 23

Weights: COMMON 3, UNCOMMON 2, RARE 1 (5x3 + 3x2 + 2x1 = 23). Printed odds
in plain words, Barrow ethic: "2 in 3" = roll < 67, "1 in 2" = roll < 50.
The stakes line IS the rule, verbatim, <= 72 chars. Choice titles <= 28
chars. Vignettes 2-3 lines, 72-char cap per line.

**COMMON (weight 3 each)**

1. **The Clockwork Wren**
   > A brass wren sits on the shrine rail, one wing ticking out of time.
   > It looks at you. It looks at its wing. It looks at you again.
   - Safe - "Wind it gently" - `Sure: mend 2`
     - result: "It chirps twice and taps your hull where it hurts. Better."
   - Push - "Ask for the long song" - `2 in 3: mend 4 - else one arm wears 2`
     - good: "The song winds through your seams and settles them. Mend 4."
     - bad: "The last note snags. Your arm buzzes wrong for miles. Wear 2."

2. **The Toll Doll**
   > A porcelain doll minds a bridge no wider than a plank.
   > It holds out a cup with great ceremony. The cup is empty. So is the toll.
   - Safe - "Bow and pass" - `Sure: next foe steps in worn 1`
     - result: "The doll bows back and whispers a weakness it once saw. Noted."
   - Push - "Juggle for the doll" - `2 in 3: next foe worn 2 - else LEGS wear 2`
     - good: "Delighted, it tells you everything. The next foe is worn 2."
     - bad: "You drop a bolt on your own foot. The doll pretends not to see."

3. **The Kettle Sprite**
   > A copper kettle steams by the shrine, though no one lit a fire.
   > Something small inside hums a tune with two wrong notes.
   - Safe - "Share a sit" - `Sure: mend 3`
     - result: "Warm steam finds the dents. You leave looser than you came."
   - Push - "Peek in the kettle" - `2 in 3: mend 5 - else wear 1`
     - good: "The sprite beams and boils you a proper cure. Mend 5."
     - bad: "It startles and spits a hot bead. Barely a mark. Wear 1."

4. **The Sleepy Signpost**
   > The signpost yawns. Its three arms point three ways to the same road.
   > "Shortcut," it mumbles. "Or the truth. Pick one, I'm napping."
   - Safe - "Ask plainly" - `Sure: next foe steps in worn 1`
     - result: "It names the next brute and where its plating gaps. Worn 1."
   - Push - "Take the shortcut" - `2 in 3: next foe worn 1 + mend 3 - else wear 3`
     - good: "The cut path is soft moss and good news. Mend 3, foe worn 1."
     - bad: "The shortcut was a hedge. The hedge disagreed. Wear 3."

5. **The Rain-Soaked Coffer**
   > A little coffer sits in the ditch, swollen with last night's rain.
   > Something inside knocks, patient as a clock.
   - Safe - "Tip the water out" - `Sure: mend 2`
     - result: "Clean rainwater, good for rinsing grit from joints. Mend 2."
   - Push - "Wrench it open" - `1 in 2: mend 6 - else both arms wear 2`
     - good: "Oil, wadding, and a tinker's kit, bone dry. Mend 6."
     - bad: "The lid snaps back on both your hands. Each arm wears 2."

**UNCOMMON (weight 2 each)**

6. **The Moss-Kept Milestone**
   > An old milestone wears a coat of moss like a favorite jumper.
   > Under the green, carved marks - someone counted more than miles here.
   - Safe - "Read the old miles" - `Sure: next foe steps in worn 1`
     - result: "The marks tally every traveler's scrapes. You know its limp."
   - Push - "Dig at the base" - `2 in 3: next foe worn 2 + mend 2 - else LEGS wear 2`
     - good: "A watcher's cache: notes and balm. Foe worn 2, mend 2."
     - bad: "The stone settles onto your foot. Politely. LEGS wear 2."

7. **The Button Merchant**
   > A vole in a waistcoat has arranged nine buttons on a handkerchief.
   > "Plain button, fair trade. Mystery button - ah. The mystery."
   - Safe - "The plain button" - `Sure: mend 2`
     - result: "It fits a seam you did not know was loose. Solid trade."
   - Push - "The mystery button" - `2 in 3: next foe worn 2 - else nothing`
     - good: "The button hums a warning about the road ahead. Foe worn 2."
     - bad: "It is an acorn. The vole shrugs. You keep the acorn."

8. **The Rust-Rooks**
   > Three rooks with rusted beaks take turns polishing a kettle lid.
   > They eye your seams the way jewelers eye a cracked ring.
   - Safe - "Watch them work" - `Sure: mend 2`
     - result: "You copy their trick on your own plating. Neat. Mend 2."
   - Push - "Borrow the polish rag" - `2 in 3: mend 4 - else wear 2`
     - good: "The rag knows its business better than you do. Mend 4."
     - bad: "The rooks want it back. All three of them. At once. Wear 2."

**RARE (weight 1 each)**

9. **The Gearwright's Ghost-Light**
   > A lantern-glow drifts over the shrine with no lantern in it.
   > It hums an old workshop song. It knows your maker's marks.
   - Safe - "Hum along" - `Sure: mend 3`
     - result: "The glow settles on your shoulder a while. Things sit right."
   - Push - "Follow it" - `1 in 2: mend 6 - else wear 4`
     - good: "It leads you to a gearwright's forgotten bench. Mend 6."
     - bad: "It leads you through a briar and is gone. Wear 4."

10. **The Barrow-Wisp**
    > A pale wisp circles you twice, then tugs your arm toward the dark.
    > It is either very lost or very sure. Possibly both.
    - Safe - "Carry it to the lamppost" - `Sure: next foe steps in worn 1`
      - result: "At the lamp it brightens and spills a secret about the road."
    - Push - "Let it ride" - `1 in 2: next foe worn 2 + mend 3 - else wear 2`
      - good: "It rides your shoulder, mending and muttering. Worth it."
      - bad: "It slips into your seams, tickles, and leaves. Wear 2. It waves."

Set discipline: 4 of 10 safe choices are riders (2, 4, 6, 10) so a full-HP
box always has live safe value somewhere in the rotation; every push-bad is
wear only; wear 4 appears exactly once (ghost-light) and G2 holds its knife.

### 2.7 UI shape (existing furniture only)

- RouteBed: single chip via `_node_chip`, new glyph for the flavored rest -
  shrine ✶ (joins ⚔ ⛺ ★). RouteRail sees kind "single" - zero rail changes.
- Rest panel: unchanged (repair / extract / Head home).
- Shrine panel (on Press on): event name head (LAMP_KEY 18) + vignette
  (PARCHMENT 0.8, the challenger-blurb slot) + two EventCards reusing the
  PathCard pattern exactly (`_card_pnl`, 356px, two-step commit: tap-select
  BRASS_HI border, then brass "Choose ▸" disabled until picked).
- Card = choice title <= 28 chars + one honest stakes line <= 72 chars.
- Resolved: result text + "Onward ▸". Deltas echo in `_status` (the Second
  Wind toast slot).
- The shrine-open state lives on the SCREEN (like `_sel_lane`/`_sel_pos`),
  not on a button - refresh() rebuilds `_action` children every call.
- Sfx from existing seams: fork_reveal on shrine open, ui_tap select,
  switch_throw commit, gift_found good reveal, ui_tap bad reveal. Never a
  punishment buzz.

---

## 3. MAGPIE'S HEAP (Template B pos1 - the Scrapyard flavor)

### 3.1 The offer table (v1)

One stall. Kit runs only. Once per run.

| Stall | Who | Price | Outcome (seeded, revealed on commit) |
|---|---|---|---|
| RUMMAGE the heap | kit runs, once per run | 8 satchel scrap (ASSUMED, G6) | 55% lent COMMON body bit / 30% filings, +4 back to the SATCHEL / 15% lent RARE body bit (ASSUMED, G7) |

- **Lent bits** ride the carried box build (install-or-leave), on the
  box_core lend precedent: fresh instances, never in player.bits, never
  compendium-marked, gone at run end. Cannot be melted, banked, or looted.
- **Draw pools discovered-first**: commons fall back to the 13 base
  fixtures; if no RAREs are discovered the RARE result downgrades to
  filings. Coffers stay the sole discovery channel.
- **Self-throttle by position**: at pos1 the satchel holds at most the
  node-0 purse - 10 full-rate, 5 on a halved day. Rummage at 8 is
  affordable full-rate only; the grinder's halved day prices itself out
  (5 < 8). No code needed, the throttle is structural.
- Own-build runs see the plain rest plus one line of heap flavor - no
  stalls. No satchel exists on an own run, and a wallet lend/buy channel
  would open bank-leak seams for no design win at 8-29% own survival.
  (Known gap, backlogged: own-build heap content waits for a wave with a
  post-elite stop.)
- The heap never touches purses, Glimmer, the bank, the bench, or the
  1-COMMON loot slot (no bit is ever KEPT from the heap in v1 - lends only).

### 3.2 Seeding

Stock and dig outcome are pure functions of (map seed, stall tag):

```
g  = mix2(map_seed)       # second mix round, independent of the shrine mix
r1 = g % 100              # dig outcome band: <55 lend COMMON, <85 filings, else lend RARE
r2 = (g / 100)            # lend pick within the discovered-first pool
```

Leaving and returning shows the identical dig. The kit nonce advances only
on commit (unchanged). Own runs would use the session-local stored map
seed - moot in v1 (no own-run stalls) but the seed storage lands anyway for
the shrine (section 2.2). Crack-and-see parity: same box = same road =
same heap.

### 3.3 Copy (warm, honest, hyphens only)

- Stall line: "The heap shifts when you look at it. Something in there is
  still good."
- Rummage button: `Rummage the heap  ⚙8`
- Filings result: "Mostly rust. ＋⚙4 in filings, at least."
- Lend result: "Buried treasure - a %s! It rides with the box til home."
- Broke (satchel < 8): "The magpie eyes your light satchel and shakes its
  head. Kindly."

### 3.4 UI shape

- RouteBed chip glyph: heap ⚒ (or the closest existing glyph token) on the
  pos1 chip - Template B roads read "scrap heap" at a glance from node 0.
- Rest panel gains one stall row above Press on: stall line + Rummage
  button (disabled with the honest "need ⚙N more" cue below 8, the Barrow
  affordability pattern). Result lands in `_status`.
- Rummage is arrival-side (the bench IS the heap) - no departure gating.
  Press on is never blocked at the heap.

---

## 4. THE GLEANER'S DUE (HP-scaled salvage - the ruled home)

Death was a cliff: safe end keeps everything, death keeps nothing. The
Gleaner's Due makes the pickers honest without blunting the sting.

### 4.1 The ordering law (named, exact)

**SAFE END > DEEP DEATH > SHALLOW DEATH, with a guaranteed sting - death
never keeps more than floor(S/2).**

### 4.2 Kit runs

```
kept = floor(satchel * K_tier * (0.5 + 0.5 * H))
K_boss  = 0.50   (ASSUMED, G8)
K_elite = 0.25   (ASSUMED, G8)
K_else  = 0      (skirmish cannot kill - fail-safe zero)
H = remaining-HP fraction of surviving non-core body bits at death
```

- `satchel_bit_id` is ALWAYS lost on death. The bit never survives the
  pickers.
- Worked canon: S=35, H=1: boss death keeps 17, elite keeps 8. H=0: boss 8,
  elite 4. Margin >= 50% of carried salvage, plus the bit, always.
- **Halving-loophole closure (DECIDED)**: a death that pays (kept > 0)
  calls `note_kit_run` and burns a daily full-rate slot. Deliberate
  deep-death EV is then strictly worse than Head home at every state:
  kept <= floor(S/2), the bit is forfeited, and the same slot burns (G10).

### 4.3 Own-build runs

```
wreck = floor(K_tier * sum(Broker.salvage_scrap(bit) * hp_i / max_i))
        over surviving non-core body bits; the core pays 0
```

- Core pays zero - Fettle "won't melt a bound soul" (consistent with the
  Still/Melt rules).
- Anti-exploit proof: wreck <= 0.5 x home-melt of the same bits, so
  suiciding a build is dominated by melting at home; extraction keeps
  everything, so extraction strictly dominates both.
- **Run-death credit ONLY.** Bouts keep the CH-08/CH-09 forfeit-pays-zero
  law. Implementation must gate the Due to The Run (kit + own venture),
  never the Proving Grounds.

### 4.4 Death copy

- Deep (boss-tier): "The pickers drag back what they could - ⚙%d of your
  salvage."
- Shallow (elite-tier): "Scattered where it fell. The pickers glean ⚙%d."
- kept = 0: current line unchanged ("The scrap scatters where it fell -
  you walk home empty-handed.")
- Own build: "Word from the gleaners: ⚙%d pulled from the wreck. The core
  is gone."

---

## 5. THE BOSS-RETREAT RULING (own builds, all-or-nothing)

### 5.1 The ruling

**Boss retreat stays ALL-OR-NOTHING for own builds. No priced retreat.**

Grounds: the RouteBed renders every lane chip with its modifier strap from
node 0, and advance() from the pos3 rest lands directly on the pos4
junction - zero fights, zero damage, zero new information between the last
exit and the boss commit. A priced retreat would never buy the player
anything a one-click-earlier extract did not; it would only monetize
misclicks and misunderstanding. The wager IS the press from the last rest -
that is the push-your-luck spine.

Kit/own symmetry holds at the verb level: kits keep their anywhere
walk-away because their only stake is the run-local satchel; the own-build
stake is the construct, whose exit verb is extraction, and extraction is a
bench verb. can_extract() untouched (frozen law).

### 5.2 The Last Lantern

The pos3 REST is renamed **"The Last Lantern"** in BOTH templates
(template label change only, render-only, no semantics). It is ALWAYS a
plain camp on every template, present and future - the final exit is a
promise the map makes from node 0.

### 5.3 Honest-information copy (own builds, existing furniture)

a. Pos3 rest vignette replaces the generic bench line:
   "The last lantern. Past this bench, the road only goes to the gate."
b. Press on at pos3: `Press on - no way back after this  ▸`
c. Boss junction panel, one sub-line under "The road forks here":
   "The road only goes forward from here."
d. The per-card core warning stays verbatim:
   "⚠ This one aims for the core - losing here unmakes your Manabit."

Kit copy unchanged everywhere. Copy scope note: the boss-junction line is
deliberately scoped to the construct, not the loot - if a future wave adds
an own-build purse, the copy stays true. Do not tighten it.

### 5.4 Two-step abandon (own builds only - the one mechanical change)

`_on_abandon` currently destroys the construct on one stray tap. Reuse the
PathCard two-step-commit pattern: first press arms the button and swaps
its text to "Leave them behind? Tap again"; a second press while armed
confirms; any other press or interaction disarms back to "Abandon run".
The armed flag lives on the SCREEN (a member var, like _sel_lane), not on
the button instance - refresh() rebuilds children every call, so button
state would be lost. Disarm is interaction-driven, never timer-driven (a
timer races refresh). Kit "Head home  ▸" stays one-tap - it is safe by
construction.

---

## 6. CONSOLIDATED MEASUREMENT GATES

Wave-1 files exist: `tools/sim/out/ladder.json`, `tools/sim/out/economy.json`.
G0 fields do NOT exist yet - G0 blocks every knob below it.

| # | Tunable | ASSUMED value | Number to check (source) | Acceptable band | Out-of-band action |
|---|---|---|---|---|---|
| G0 | (precondition) | - | economy v2 / ladder v2 must EMIT: per-template safe-end + clear rates, event tally (realized push-good per event), kit_flush_mean by depth, rummage_spend / rummage_return, death_keep_mean, own_wreck_mean | fields exist | no knob locks until they do |
| G1 | Event-road frequency (template-bound 50%) | fixed by abs(seed)%2 | kit safe-end rate Template A vs Template B; full-run clear delta (ladder v2) | within 5 pts; clear drop <= 5 pts | frequency is structural - tune event CONTENT (trim wear / buff safe mends), never add a presence roll |
| G2 | Event mend [1,6] / wear cap 4 | as set (2.6) | elite-death rate Template A vs Template B, repair-always policy (ladder v2) | within +3 pts | cut ghost-light wear 4 to 3; raise kettle/wisp safe mends |
| G3 | Foe-worn rider 1 safe / 2 push | 1 / 2 (= RunMods.WEAR) | smoke_kit_sim untouched; elite win rate on rider-carrying runs vs node0 win rate (ladder v2) | sim green; rider runs <= node0 rate (no-lane-out-cozies-node0 law) | rider drops to 1 across the board |
| G4 | Printed odds thresholds 67 / 50 | as printed | realized push-good rate per event over >= 300 seeded runs (event tally) | within +/-5 pts of "2 in 3" / "1 in 2" | the mix is biased - fix the hash, never the copy |
| G5 | Rarity weights 3/2/1 (total 23) | as set | event distribution over >= 300 seeded runs (event tally) | every event >= 3% of event roads, none > 20% | d2 aliasing - re-derive from a second mix round, do not hand-tune weights |
| G6 | Rummage price 8 / filings +4 / 55-30-15 | 8 / +4 | 30-day p50 wallet (economy v2; wave-1 ~90, surplus +1.8%); mean heap scrap return; kit_flush_mean | wallet 85-95; return <= 2 per run; flush in [baseline -15%, +0%] | price 10 if leaky; price 6 if punishing |
| G7 | RARE lend odds 15% | 15% | NEW smoke_kit_sim arm: Dud + forced RARE lend boss win | <= 0.20 with ALL existing bands green (Gleaming >= 0.60, Dud <= 0.15, Dud dies > wins, node0 >= 0.90 / 0 deaths) | pre-ratified drop to 10% |
| G8 | K_boss 0.50 / K_elite 0.25 / H-blend 0.5+0.5H | as set | mean death-run scrap vs safe-run scrap at equal depth; p50 wallet; faucet/sink ratio (economy v2; wave-1 1.018) | death <= 60% of safe (sting >= 40%); wallet 85-95; ratio 0.95-1.10 | pre-ratified K fallback 0.40 / 0.20 |
| G9 | Own wreck (same K) | as G8 | ladder v2 mean own-venture net scrap (wave-1: -7.55 mid / -5.16 strong) | in [-10, +5] | halve K for own builds |
| G10 | Halving-loophole closure | note_kit_run on paid death | analytic proof + economy v2 spot check: deliberate deep-death EV vs Head-home EV at every recorded state | deep-death EV strictly < Head-home EV | tighten K until it holds |
| G11 | All-or-nothing retreat viability | ruling | strong death_ahead_from_rest2 (wave-1: 0.67 PASS); best boss config strong survival (wave-1: 0.453 PASS) | <= 0.75; >= 0.30 | ESCALATION: if mid death_ahead > 0.90 after the balance wave (wave-1: 0.898, on the line), the team revisits a priced retreat |
| G12 | Last Lantern is a live choice | ruling | extract_trigger_rate_rest2, repair-always (wave-1: mid 0.156, strong 0.102 - PASS) | 0.05-0.50 for at least one tier | below: exit is decorative; above: boss unpressable - both route to the balance lane |
| G13 | Rest-flavor replacement safety | - | elite-death rate, repair-always, after flavors land (wave-1: 0.199 mid / 0.117 strong) | <= 0.25 mid / <= 0.15 strong | a flavor implementation gated or removed the pos1 repair - that is a bug, not a knob |
| G14 | Event money-neutrality | structural | economy v2 with events toggled on/off | p50 day-30 scrap within +/-5 of the 90 baseline, zero-delta curve | events leaked money - that is a bug, not a knob |

Conservative default: if v2 numbers are late and the owner wants the wave
shipped, ship the shrine set with ghost-light at wear 3 and rider capped 1 -
the cozy-safe floor - and open the knobs when the numbers land.

---

## 7. TEST-CHANGE LIST

### smoke_run: 32 -> 40 checks

UNCHANGED (all 32): the full deterministic walk passes as-is - a flavored
rest is still a REST, so "pos 1 is REST + can extract" and "pos 3 is REST +
can extract" stay green UNTOUCHED. That is the proof the flavor ruling
preserved the frozen semantics. "map has 5 steps" stays 5. The purse
validator (FIGHT-only sweep, 75/37) is re-RUN, not re-written.

NEW (8):

- T1 "pos 3 rest is The Last Lantern, plain camp, both templates"
  (extend _validate_templates)
- T2 "pos 1 rest carries a flavor and flavors differ across templates
  (event on The Old Road, scrapyard on The Quiet Spiral)"
- T3 "crack-and-see parity: _make_map(s) twice yields identical event_id,
  roll, and heap dig outcome" (two seeds, one per template)
- T4 "event table validator: exactly 2 choices, safe choice deterministic,
  mend in [1,6], wear total <= 4 never CORE never disables, rider <= 2,
  weights positive summing 23, printed odds match thresholds 67/50, and NO
  money fields anywhere in the table"
- T5 "resolve() irreversible + idempotent; safe choice ignores the roll;
  no-op at a non-event node and for choice_i outside {0,1}"
- T6 "rider is MAX-NOT-SUM vs the lane modifier: rusted(2) + rider(2) = 2;
  rider consumed and cleared after one fight"
- T7 "Gleaner's Due ordering law: canonical keeps (S=35 H=1: boss 17,
  elite 8; H=0: boss 8, elite 4); sweep S in 0..75 x H in {0, .5, 1}
  asserting kept <= floor(S/2); satchel_bit_id always lost; paid death
  increments kit_runs_today"
- T8 "Magpie's Heap: dig is seed-pure (leave and return identical);
  Rummage once per run; lent bit absent from player.bits after safe-end
  flush AND after death"

### smoke_kit (13 -> grows)

- Death-with-keep flush cases (kept lands, bit lost).
- Fixture update: existing kit_runs_today assertions must account for
  note_kit_run firing on paid deaths (budgeted - this alters a sim-flagged
  LOW behavior deliberately).

### smoke_kit_sim (the tripwire - bands UNCHANGED)

- ALL existing lane bands stay the authoritative tripwire, untouched.
- ADD one arm: Dud + forced best-case RARE lend, boss win <= 0.20 (G7).
- Re-run after every knob lock. Riders are bounded at rusted's magnitude
  and max-not-sum, so no lane can be pushed past a band the sim guards -
  T6 is the structural proof, the sim is the empirical one.

---

## 8. ORDERED IMPLEMENTATION CHECKLIST

Implementation does not start until G0 fields exist. Order is load-bearing.

1. **Sim first (no game code):** extend `tools/sim/sim_ladder.gd` +
   `tools/sim/economy_sim.py` to emit every G0 field + the event tally.
   Re-anchor economy v2 (the venture appetite priors were QA-marked
   SUSPECT - G6/G8 bands are stated against v2, not wave-1 priors).
2. **RunState:** `flavor` field on REST template steps + `_make_map`
   passthrough; pos3 label "The Last Lantern" both templates; `mix()` +
   event_id/roll stamping on Template A pos1; `mix2()` heap dig stamping
   on Template B pos1; store the own-run map seed session-local in
   `start()`. Re-run the FULL smoke_run after the template edit - the
   purse sweep is re-run, never assumed.
3. **meta/run_events.gd:** RunEvents table (section 2.6) + pure resolve +
   `_wear` walker + `RunEvents.pick(seed)` probe.
4. **Rider plumbing:** `next_fight_rider` on RunState, consumed at the
   pre-bell seam in `_on_fight`, applied through the Challengers.make wear
   path, MAX-NOT-SUM, cleared after the bell.
5. **Gleaner's Due:** kit keep in `_resolve_kit_fight` DEATH path (+
   note_kit_run on kept > 0); own wreck in the run death path only -
   never bouts. Death copy per 4.4.
6. **Magpie's Heap:** Rummage stall row on the Template B pos1 rest panel;
   lent-bit plumbing on the box_core precedent; once-per-run latch on
   session-local RunState.
7. **Shrine UI:** departure-side vignette panel + EventCards + two-step
   commit + "Onward ▸"; shrine-open state on the screen; RouteBed glyphs
   (✶ shrine / heap); sfx seams per 2.7.
8. **Boss-retreat copy + two-step abandon:** section 5.3 lines a-d;
   `_on_abandon` armed state per 5.4.
9. **Tests:** smoke_run T1-T8; smoke_kit fixtures; smoke_kit_sim G7 arm.
   All 14 fast gates + smoke_kit_sim re-run green before the wave closes.
10. **Copy review pass:** hyphens-only sweep, warm-register read of all 10
    vignettes x outcomes + heap + death copy, and stakes lines re-verified
    VERBATIM against final numbers after any gate retune - the lying-label
    anti-pattern re-enters through stale copy, not through code.

---

## 9. RISKS CARRIED FORWARD

- **Mid-build boss death-ahead (0.898) rides the ceiling.** This ruling has
  a hard dependency on the balance wave softening the boss rungs (Brassmore
  0.132, the Cogsworth-to-Gildfall gap 0.212). If it does not, The Last
  Lantern reads as "the road ends here" for mid builds and G11's escalation
  trigger fires.
- **The rider seam is the sharpest edge.** Sum-instead-of-max starts elites
  4 HP down invisibly to the sim. T6 is mandatory in the same change as the
  rider, not a follow-up.
- **note_kit_run on paid deaths trips existing fixtures.** Budgeted in
  step 9; do not "fix" a red fixture by reverting the loophole closure.
- **Flavor implementations must not gate the pos1 repair or extract.** G13
  breach = bug. Any future spec that says "new step type" is a coherence
  violation on sight - flag it to the producer.
- **New-player Rummage lends feel samey in hour one** (13 base fixtures
  until 5 commons are discovered). Accepted - the discovery law is worth it.
- **Two-step abandon vs refresh():** a timer-based disarm will race
  refresh() rebuilding `_action`. The armed flag lives on the screen and
  disarms on any other interaction - no timers.
- **The Gleaner's Due lands right after CH-08/CH-09 closed the bout
  printer.** The Due is Run-only by explicit gate in code review, or the
  forfeit-pays-zero law quietly reopens.
- **Largest prose slab in the run so far** (10 events x 2 choices x 2-3
  outcome texts + heap + death copy). It goes through the same
  hyphens-only / warm-register review as Fettle's barks - step 10 is not
  optional.
