# THE WAYSIDE - the Event node (Run wave, encounter lane)

*Design-only spec. Settles open item (1) Event node type. Binds to the frozen laws:
node()/advance()/can_extract semantics untouched, collapse-in-place only, crack-and-see
parity, satchel firewall, resolution determinism, section 13 untouched.*

---

## 1. What it is, in one line

Once in a while the pos1 Tinker's Rest is not a rest - it is **The Wayside**, a warm
roadside vignette with the world's toy-folk: exactly two choices (one safe, one
push-your-luck), a pre-rolled hidden result, small run-local stakes, never a fight,
never a toll you cannot refuse, never lethal.

---

## 2. Placement law (the spine stays 5 nodes)

- **The Wayside only ever stands at pos1**, replacing that road's pos1 REST. The map
  stays exactly 5 steps. No insertion, no graph walker.
- **The pos3 REST is NEVER replaced.** It is the last repair and the boss-retreat valve
  (the asymmetry lane owns that call - this spec hard-reserves the node for them).
- Fights are never replaced (route purse cap 75/37 stays byte-identical by
  construction - EVENT nodes carry **no `tier` key**, so the validator's FIGHT sweep is
  untouched).
- Both templates support it identically. Same label on both roads: **"The Wayside"**.
- Road-level cost, stated honestly: on a Wayside road an own-build run's first extract
  window moves from pos1 to pos3 (`can_extract` requires `at_rest()` - unchanged code,
  and the Wayside is not a rest). That risk bump IS the event's price of admission.

**Frequency:** ASSUMED 50% of roads carry a Wayside (`EVENT_PCT = 50`). Gate 1 below.

## 3. Seeding (crack-and-see parity)

All draws derive from the same `map_seed` `_make_map` already receives. One pure
integer mix (splitmix-style scramble, documented in code), three independent fields:

```
h  = mix(map_seed)              # pure, no RNG object, no state
d1 = h % 100                    # Wayside present if d1 < EVENT_PCT (50)
d2 = (h / 100) % 23             # weighted event pick (total weight 23, section 6)
d3 = (h / 10000) % 100          # the hidden outcome roll, stored on the node
```

- Template pick stays `abs(seed) % TEMPLATES.size()` - untouched, independent via mix.
- Node shape: `{"type": "EVENT", "label": "The Wayside", "event_id": <id>,
  "roll": d3, "resolved": false}`.
- **The push result is decided at map-make and stored.** Choosing only reveals it -
  same seed, same choice, same result, forever. No post-choice RNG feel-bad. Same box =
  same road = same wren.
- Own-build runs seed off `randi()` today (existing behavior) - events are equally
  deterministic given the seed; replay parity is only promised where the game already
  promises it (kit boxes).

## 4. Resolution law (collapse-in-place, event flavor)

New `meta/run_events.gd` (`class_name RunEvents`, table + pure resolve, mirroring
RunMods). `RunEvents.resolve(run, choice_i)`:

- No-op unless the current node is an unresolved EVENT with `choice_i` in {0, 1}
  (exact `choose()` discipline).
- Applies the outcome effects, then stamps the node **in place**: `resolved = true`,
  `chose`, `result_id`, `result_text`. Irreversible. Idempotent on re-call.
- `advance()` untouched - the UI gates "Press on" behind `resolved` (same trust level
  as fights).
- `can_extract()` untouched - returns false at a Wayside because `at_rest()` is false.

## 5. Stakes rails (the run vocabulary, nothing leaks)

Every outcome is built only from these four verbs, with hard rails:

| Verb | Rail | Plumbing |
|---|---|---|
| **scrap +/-N** | N in [-4, +6]; debits floor at 0, pay-what-you-have, never a dead-end | kit run: `satchel_scrap` (spills on DEATH, flushes on safe end - firewall intact); own run: `player.scrap` (the same channel rests already debit) |
| **mend N** | N in [1, 6] | `RunMods._mend` - the shipped helper, worn bits, capped at max_hp |
| **wear N** | total <= 4 HP per event, floor 1 HP, **never CORE, never disables** - events are never lethal by construction | a mirrored `_wear` pool walker in RunEvents, fixed slot order ARM_R, ARM_L, LEGS, BACK, HEAD |
| **foe-worn rider** | next fight only; magnitude 1 or 2 (never above RunMods.WEAR); **max-not-sum vs the lane modifier** (a rusted lane already at 2 gains nothing from a rider of 2) | `run.next_fight_rider` int on RunState, consumed at the same pre-bell seam as `pre_fight_mend`, applied through `Challengers.make` wear path; RunState is session-local so it cannot leak past the run |

- One found-bit outcome exists (Milestone). Kit run: fills `satchel_bit_id` only if
  empty (the 1-COMMON loot cap is the same single slot), else pays +5 scrap. Own run:
  always +5 scrap. Never a second bit, never RARE+, never Glimmer.
- Purses, loot counts, Glimmer, the bank, and the bench are never touched. Everything
  an event grants lives and dies with the run state it is written on.

## 6. The launch set - 10 events, weight 23

Rarity: common w3 (5 events), uncommon w2 (3), rare w1 (2). Push odds are printed on
the card in plain words ("2 in 3") - the Barrow's printed-odds ethic. Card text is the
rule, verbatim. Vignettes 2-3 short lines, warm register, hyphens only.

### Common (w3 each)

**wren - The Wind-Up Wren**
> A wind-up wren sits spent on a fencepost, key run all the way down.
> It cheeps once, hopeful, as you pass.
- SAFE "Wind it and set it homeward" - Sure: +2 scrap (a shiny thank-you).
- PUSH "Ask it to sing the road ahead" - 2 in 3 (roll < 67): mend 3.
  Else: it panics and nips - one arm wears 2.

**toll - The Tinker's Toll Bridge**
> A doll no taller than a teacup guards a plank bridge, ledger open, stamp inked.
> "Toll's three," it says, very seriously.
- SAFE "Pay the three and take a stamp" - Sure: -3 scrap. Short? Pay what you have -
  the doll sighs and waves you through anyway.
- PUSH "Offer a juggling show instead" - 2 in 3: toll waived plus a tip, +4 scrap.
  Else: you flop - pay 4 and it stamps your knee: LEGS wear 2.

**coffer - The Rain-Soaked Coffer**
> A little coffer lies in the ditch, lid swollen shut with rain.
> Something inside shifts when you nudge it.
- SAFE "Pry it gently with a stick" - Sure: +2 scrap.
- PUSH "Wrench it open bare-handed" - 1 in 2 (roll < 50): +6 scrap.
  Else: the lid snaps back - both arms wear 2.

**kettle - The Kettle Sprite**
> A dented kettle sits on a cold campfire.
> From inside comes a polite, patient tapping.
- SAFE "Warm it and share a sit" - Sure: mend 2.
- PUSH "Peek under the lid" - 2 in 3: the sprite mends you proper - mend 5.
  Else: a scalding scold - wear 1, and no tea.

**signpost - The Sleepy Signpost**
> The signpost yawns as you reach it. "I spin myself at night," it admits.
> "For fun. Ask me anything."
- SAFE "Ask it plainly for the road" - Sure: next fight - foe bits start 1 HP down.
- PUSH "Ask for the scenic shortcut" - 2 in 3: a berry hedge and a downhill lane -
  mend 3 and +3 scrap. Else: brambles - wear 3.

### Uncommon (w2 each)

**milestone - The Moss-Kept Milestone**
> An old milestone naps under a blanket of moss.
> Between its toes, something glints.
- SAFE "Read the carved directions" - Sure: next fight - foe bits start 1 HP down.
- PUSH "Dig the glint free" - 2 in 3: a sleeping COMMON bit (satchel if there is room,
  else +5 scrap; own runs +5 scrap). Else: beetles - LEGS wear 2.

**button - The Button Merchant**
> A pincushion hedgehog has set up shop on a stump.
> "Buttons," it whispers. "Lucky ones. Probably."
- SAFE "Buy the plain button (2 scrap)" - Sure: -2 scrap, mend 2. A very sturdy button.
- PUSH "Buy the mystery button (4 scrap)" - 2 in 3: lucky - next fight foe bits start
  2 HP down. Else: it is an acorn. A nice acorn. (Nothing else happens.)

**rooks - The Rust-Rooks**
> Three clockwork rooks line the fence rail, trading shiny for shiny.
> One eyes your satchel with open admiration.
- SAFE "Trade them a spare bolt" - Sure: +3 scrap.
- PUSH "Hold out your polish rag" - 2 in 3: they groom your seams - mend 4, and one
  tucks a gift in your pack: +2 scrap. Else: they pluck - -4 scrap and wear 1.

### Rare (w1 each)

**ghostlight - The Gearwright's Ghost-Light**
> A pale lantern bobs just off the road, humming a workshop tune you almost know.
> It pauses, waiting to see if you follow.
- SAFE "Hum along from the road" - Sure: +3 scrap (a little dish of filings).
- PUSH "Follow it into the hedge" - 1 in 2: the old gearwright's cache - mend 6 and
  +4 scrap. Else: it winks out - the long way back wears 4.

**wisp - The Barrow-Wisp**
> A tiny cart-lantern wisp flickers at the roadside, far from any cart.
> It looks exactly as lost as it is.
- SAFE "Carry it to the next lamppost" - Sure: mend 3 (it glows warm the whole way).
- PUSH "Let it ride in your satchel" - 1 in 2: it steadies and lights your work -
  next fight foe bits start 2 HP down, and +4 scrap (it pays its way).
  Else: it burrows into your filings to nap - -3 scrap. It waves goodbye anyway.

## 7. UI shape (existing furniture only)

- **RouteBed chip:** the standard single chip via `_node_chip`, new glyph `✶` for
  EVENT (joins `⚔ ⛺ ★`). Resolved Waysides show the normal passed `✓`. RouteRail sees
  kind "single" - zero rail changes.
- **Action panel, unresolved:** head label = event name (LAMP_KEY 18), vignette label
  (autowrap, PARCHMENT 0.8 - the challenger-blurb slot), then **two EventCards reusing
  the PathCard pattern exactly** - `_card_pnl` styleboxes, 356px wide, two-step commit:
  tap to select (BRASS_HI border), then a brass "Choose ▸" button (disabled "Pick one
  first" until selected). Card contents: choice title (max 28 chars), one honest
  stakes line (max 72 chars) - "Sure: +2 scrap" or "2 in 3: mend 5 - else wear 1".
- **Action panel, resolved:** result text (LAMP_KEY), scrap/mend/wear deltas echoed in
  `_status` (the Second Wind toast slot), then "Press on ▸". No modifier banner.
- **Sfx (existing seams only):** arrival `fork_reveal`, select `ui_tap`, commit
  `switch_throw`, good reveal `gift_found`, bad reveal `ui_tap` - cozy, never a
  punishment buzz.

## 8. Test contract - what changes in smoke_run (32 checks today)

Unchanged: "map has 5 steps" (still 5), the whole FIGHT-sweep purse validator (EVENT
carries no tier and is skipped by the existing type filter), all junction checks.

Repinned: the deterministic walk ("pos 1 is REST + can extract", line 40) pins a
documented event-free seed via a new static probe `RunState.wayside_roll(seed)` so the
existing rest walk stays byte-stable.

New checks (+6, 32 -> 38):
1. A pinned Wayside seed yields pos1 EVENT with a valid event_id and roll in [0, 99].
2. `can_extract()` is false at a Wayside.
3. Parity: `_make_map(s)` twice yields identical event_id and roll.
4. pos3 is REST on every template with event-on and event-off seeds (never replaced).
5. Event table validator: every event has exactly 2 choices, the safe choice is
   deterministic, scrap deltas in [-4, +6], mends in [1, 6], wear totals <= 4 and never
   target CORE, riders <= 2, weights positive, printed odds match the threshold.
6. Resolve determinism: resolve is irreversible and idempotent; re-resolve is a no-op;
   safe choice ignores the roll.

**smoke_kit_sim: zero changes** - lane bands are fought in isolation and stay the
authoritative tripwire. The rider is bounded at rusted's own magnitude and applies
max-not-sum, so no lane can be pushed past a band the sim already guards.

## 9. Numbers discipline - every tunable gated on wave-1

See the wave sheet: EVENT_PCT, scrap rails, mend/wear rails, rider magnitude, printed
odds honesty, and rarity weights each carry a measurement gate against
`tools/sim/out/ladder.json` + `economy.json` before implementation locks a value.
