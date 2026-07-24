# MANABIT - The Economy & The Broker (Fettle's Barrow) - Unified M0 Design

*Lane C / M0. Binds to the §13 Frozen Contract and the built 4-screen builder. Single source of truth for the economy + Broker build. Player-facing words only in UI; code names in code.*

> This is the fifth screen. It turns the already-stored-but-unused `player.scrap` field live, adds one precious second currency, and gives the "earn some at the Broker" line (already in `chest_screen.gd`) a face, a place, and a ritual. Everything here is grounded in real code: `PlayerState`, `SaveManager` (§13.5 JSON), `PackRoller` (`roll_tin`/`roll_brass`), the `root.gd` screen-swap pattern, and `DESIGN.md` tokens.

---

## 0. The fantasy, in one line

**An old friend wheels a cart of sleeping scrap up to your workshop door. You melt your spares down at their forge-belly, distill the enchanted ones to a bead of soul-light, take home a sealed Coffer to wake at your own bench, and one is always waiting for you on the step - because a maker looks after their own.** No cash register, no gems, no timers-that-punish. Every transaction is a craft gesture with a character you come to love.

---

## 1. The Broker - **Fettle**, the first Manabit

**Who Fettle is (the reconciled fiction - this does four jobs at once).** Fettle is **the very first Manabit ever bound** - a soul so cherished it was never once wagered, so it simply *kept on living*. Too old now to fight and too fond of the craft to leave, Fettle wheels a lamplit clockwork cart between workshops, gathering the orphaned dormant scrap other Artificers leave behind. A squat, pot-bellied brass automaton on a music-box base - a walking cabinet with a glowing **forge-belly**, a copper **distilling-still** strapped to the back, brass drawer-handles across the chest, a single warm glass **loupe-eye**, and a big brass wind-up key turning slow behind. Fettle is a *construct*, so referred to by name (gender-light), and speaks warm, unhurried, a little wheezy - calls you **"maker"** and **"young maker."**

This single fiction earns everything the economy needs:
1. **Fettle can find sleeping scrap but cannot wake it.** A Manabit is not an Artificer - only *you* can wake bound scrap. That is the symbiosis: Fettle has the nose, you have the hands. Trade becomes a **rescue**, cozy by construction.
2. **It is the game's aspirational end-state made flesh** - a creation that got to keep living instead of being wagered away. Exactly what the player chases when they bank a Manabit into the Menagerie. The shopkeeper is a beloved old soul, not a till - the strongest possible anti-casino move.
3. **It enforces the combat-loot firewall diegetically.** Fettle deals *only* in the sleeping and the forgotten and will physically **refuse spoils** torn off a living Manabit. Combat's deterministic "one real part off the loser" faucet is a harsher thing Fettle wants nothing to do with - so the two faucets can never merge.
4. **It gives combatless M0 its one warm relationship** - the Fellowship/relatedness a solo builder otherwise lacks.

**Voice (write these; they carry the tone - warm, never upsells, always points at the free path):**
- *Greeting:* "Ah - a maker at my counter. Mind the cart; every cog on it was somebody's someday."
- *Sitting on scrap:* "You're on a mountain of spares, young maker. Scrap doesn't dream - go wake something."
- *On a Coffer:* "Salvaged this one three spirals over. Yours to wake, at your own bench - I never peek."
- *On the Melt:* "Down to warm filings it goes. Nothing's ever wasted here."
- *On the Still:* "There's a little bound-light left in this one. Let's catch it proper."
- *Can't afford:* "A few filings short, maker. No shame - melt a spare, or take the day's gift."
- *The Doorstep Coffer:* "Left one on your step this morning. Always do."
- *Refusing spoils (the firewall, in character):* "Torn off a living bit, still warm? No. Fettle deals in the sleeping and the forgotten - never the taken."

> **Naming note (resolved):** "Fettle" is a real foundry verb - to *fettle* is to trim and clean the rough edges off a fresh casting ("in fine fettle" = restored to good condition). It literally means *the one who refurbishes scrap*. The runner-up name "Bellows" was rejected because `back_bellows` ("Mana Bellows") already exists in the catalog - a hard collision. The runner-up "Tallow" was rejected as a name but its **automaton visual** (lantern-belly, wind-up key, loupe-eye, wax-seal ledger) is adopted wholesale as Fettle's body.

**The place: THE BARROW** (subtitle "Fettle's Cart"). A "barrow" is both a handcart *and* a resting-mound for sleeping things - the double meaning is the fiction. Reached from a new Workshop top-bar button **"Fettle's Cart."**

---

## 2. Currencies - two, with a hard firewall

| Player noun | Icon / color | What it is | Code |
|---|---|---|---|
| **Scrap** | ⚙ · `--brass-hi` | the abundant tinker-currency; dull salvaged metal. "Filings" is flavor in Fettle's barks, not a second unit. | existing `player.scrap` (currently 0 and unused - this makes it live) |
| **Glimmer** | ✦ · `--stat-energy` (teal) | *distilled mana* - the bead of soul-light caught when a **bound (enchanted)** bit is unmade. Precious, slow, walled. | NEW `player.glimmer:int` |

**The firewall (the whole point - it keeps either system from cannibalizing the other):**
- **Scrap buys randomness + commons:** Tin/Brass **Coffers** and the one **COMMON Find** per day.
- **Glimmer buys the targeted enchanted long tail:** the **RARE / EPIC Finds** only.
- **Neither converts to the other. Glimmer can never buy a Coffer.** There is no closed loop, so no arbitrage cycle exists.
- **Glimmer's only faucet is the craft act of distilling your own enchanted dupes** (RARE/EPIC only - commons hold no bound mana). It is throttled at the source: you only get Glimmer by having already pulled *and chosen to distill* an enchanted dupe, so targeted acquisition self-limits to roughly one missing RARE every few sessions. *The mechanic is the lore:* only enchanted scrap holds bound mana, so only RARE/EPIC bits yield Glimmer.

> **Why two, not one:** a single currency either lets a scrap-rich player grind commons into the exact EPIC they're missing (kills the collection chase the game is built on) or leaves EPIC dupes salvaging for the same feel as a common (a real feel-bad). Glimmer solves both for the cost of one int + one save field + a handful of consts. It is deliberately *thin and load-bearing* - one faucet, one sink - not a subsystem. **Glimmer color is teal (`--stat-energy`), NOT amber**, so it never reads the same as Scrap's brass.

---

## 3. Faucets & sinks - every number (M0 starting knobs, flag for playtest)

### Faucets (value in)
| Faucet | Yields | Cadence | M0? |
|---|---|---|---|
| **The Waking** (open a Coffer at the Nook) | Tin: 3 bits · Brass: 5 bits (≥1 RARE+ floor, epic-pity 9) | on open | ✅ exists |
| **The Doorstep Coffer** (Fettle's free gift) | 1 **Tin** Coffer | once per real calendar day; **never expires**, no streak, no penalty for missed days | ✅ new |
| **The Melt** (Fettle's forge-belly) → **Scrap** | COMMON **8** · RARE **20** · EPIC **45** | on demand | ✅ new |
| **The Still** (Fettle's back-still) → **Glimmer** | RARE **1** · EPIC **3** (commons yield none) | on demand | ✅ new |
| **The Apprentice's Kit** (new-save grant) | **50 Scrap**, 0 Glimmer, 3 cores + rigged Brass (5 bits) + **coffers {tin:1, brass:2}** | once | ✅ extend existing kit |
| Combat win (one real part off the loser) | 1 part | per fight | ⛔ post-M0 (opposite contract) |

### Sinks (value out)
| Sink | Cost | Currency | M0? |
|---|---|---|---|
| **Tin Coffer** (from the Cartboard) | 40 | Scrap | ✅ |
| **Brass Coffer** | 100 | Scrap | ✅ |
| **COMMON Find** (a specific *discovered* common) | 25 | Scrap | ✅ |
| **RARE Find** (a specific *discovered* rare) | 4 | Glimmer | ✅ |
| **EPIC Find** (a specific *discovered* epic) | 10 | Glimmer | ✅ |
| Runewood Coffer | - | - | ⛔ named + greyed "none on the cart today" stub |
| The Coaxing (swap 3 napping dupes → 1 missing) · Standing Order (affinity find) · HP repair | - | - | ⛔ post-M0, named §9 |

The Melt and the Still read and mutate the **same `player.bits`** the Workshop's Salvage Tray shows - one source of truth, no extra plumbing (both screens already `refresh_from_player()` on show).

---

## 4. The anti-exploit invariant (provable, two dev-assertable rules)

Combat doesn't exist in M0, so the Broker *is* the whole faucet/sink loop. The governing law: **melting back everything a Coffer gave you always yields less Scrap than the Coffer cost.** Verified against the real catalog (5 COMMON / 3 RARE / 2 EPIC) and the real `PackRoller` odds:

1. **Guaranteed-melt < price** (deterministic floor): Tin's worst case = 3 commons = 3×8 = **24 < 40**. Brass's only guaranteed content is one RARE (melt 20) + 4 commons (32) = **52 < 100**.
2. **E[melt-back] < price** (expected): **Brass ≈ 71.7 Scrap < 100** (net −28). **Tin ≈ 31.7 Scrap < 40** (net −8) - *but only if the Tin uses its own common-heavy odds.*

> ⚠️ **REQUIRED FIX, not a nicety:** with the *current* shared Coffer odds (70/22/8), an expected Tin melts back to **~40.8 ≈ its 40 price - a break-even arbitrage leak.** `PackRoller` must give the **Tin its own common-heavy table (~85% C / 12% R / 3% E)**, which drops expected Tin melt to **~31.7 < 40** and makes Brass the aspirational quality tier. This is ~4 lines in `PackRoller._roll/_pick` (thread a weighting through). Do not ship the Tin on shared odds.

The one edge case (a ~0.2% Tin rolling 3 rares melts to 60 > 40) is random, non-repeatable, and irrational to actually do - you'd keep or distill those rares, not scrap them. Every deterministic and expected path is net-negative.

**Glimmer can't inflate either:** it can't buy Coffers and can't convert to Scrap (no cycle closes), and its only faucet - distilling enchanted dupes - is itself paid for with net-negative Scrap on Coffers. It is unfarmable by construction.

**The loop can never dead-end:** worst state (0 Scrap, 0 Glimmer, 0 Coffers, everything banked) → the Doorstep Coffer still delivers 3 fresh bits/day → dupes accrue → melt at 8 each → a Tin in a few days, and the gift feeds new bits forever. Session one is seeded by the 50-Scrap Apprentice's Kit.

---

## 5. Keeping the targeted shelf from becoming a catalog - **Today's Finds**

The builder brief sanctions "a small rotating set of KNOWN bits" that "must not become a full deterministic catalog." Four throttles thread it, and together they answer the Art lens's objection that a-la-carte parts could undercut combat loot:

1. **Compendium-gated (the load-bearing rule).** Today's Finds only ever offer bit ids **already in `player.compendium`** - bits you've already woken. **Coffers stay the SOLE discovery channel; the Broker is completion/replacement, never discovery.** A brand-new type can only first arrive via a Coffer or the rigged starter. This is why the targeted shop can never front-run the pack.
2. **Only 3 slots, seeded per calendar day** (`seed = unix_day`), stock 1 each - genuinely "what Fettle's got today," not a menu. Weighted toward discovered ids you currently own **0** loose copies of (a gap-filler / re-acquisition valve).
3. **The good ones are Glimmer-gated** (RARE 4 ✦ / EPIC 10 ✦); only the one COMMON slot (25 Scrap) is grind-affordable. So targeted rares/epics are rate-limited by scarce Glimmer.
4. **Premium priced + narrow.** Combat loot (post-M0) is free, per-fight, and takes *the specific part off the specific opponent you beat* - categorically faster, central, and higher-agency. Today's Finds is slow, premium, random-which-slots-appear, and completion-only. They are opposite contracts; the Broker's determinism is a slow relief valve that cannot cannibalize the wager fantasy.

Front/back-of-curve, expressed as a feedback loop: Coffers dominate early (discovery is efficient when everything is new); as the dex fills, per-Coffer discovery falls while dupe-melt income rises, so the player naturally pivots to saving Glimmer to *complete* the low-odds tail (the two 8%-drop EPICs `arm_seer` / `back_wing`). The crossover is the intended handoff, not a bolt-on.

---

## 6. The Barrow - screen layout & states (code-built, mirrors the four built screens)

`ui/broker_screen.gd` - `class_name BrokerScreen extends Control`; `signal done`; `setup(p)->self`; `_ready()` builds a code VBox/HBox layout (bg `ColorRect` `Tokens.BENCH_LO`, top bar with Back + currency chips, `call_deferred("refresh_from_player")`); reads **only** `PlayerState`/`Broker`. Landscape-primary, touch-first, 48dp targets. Exactly the skeleton `chest_screen.gd` already uses.

```
┌──────────────────────────────────────────────────────────────────┐
│ ◂ Back to the Workshop        THE BARROW        ⚙ 50   ✦ 2        │
│   Fettle's Cart · "Mind the cart - sit, look, take your time."    │
│ ┌── FETTLE ───┐  ┌── THE CARTBOARD (sealed Coffers) ────────────┐ │
│ │ automaton,  │  │ [Tin  ⚙40  (odds▸) 3 bits] [Brass ⚙100 ...   │ │
│ │ forge-belly │  │  (odds▸) 5 bits · 1 rare+ · Epic in 4]        │ │
│ │ breathing,  │  └───────────────────────────────────────────────┘ │
│ │ loupe-eye,  │  ┌── TODAY'S FINDS (3, resets dawn, stock 1) ───┐ │
│ │ key turning │  │ [Optic ⚙25] [Flail ✦4] [Seer ✦10 EPIC]        │ │
│ │ "no rush,   │  │  gap-filler · discovered-only · "set aside"    │ │
│ │  maker."    │  └───────────────────────────────────────────────┘ │
│ └─────────────┘  ┌── THE DOORSTEP COFFER ──┐                        │
│                  │ 🎀 a Tin, "for you"  [Untie]│                    │
│ ┌── THE MELT (forge-belly → ⚙) & THE STILL (back-still → ✦) ─────┐ │
│ │ your spares: [bit][bit][bit]…                                   │ │
│ │  tap a bit → [Melt →+8⚙]   RARE/EPIC also → [Distill →+1✦]     │ │
│ │  [Melt all common dupes → +N⚙]    core: 🔒 "a bound soul stays" │ │
│ └────────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────┘
```

**Two `CurrencyChip`s top-right, always visible** (⚙ Scrap / ✦ Glimmer), odometer-roll on change (reuse `--delta-roll`).

**Every applicable state, never color-only:**
- **CofferWare (Cartboard):** `affordable` (tag lit, Coffer breathes, hover-lift) · `too-dear` (numerals go `--wax-seal`, a warm shortfall chip "⚙40 - 12 short", **still tappable** → Fettle apologizes + highlights the Melt) · `bought` (wax **SOLD** stamp thunks, Coffer slides across, "+1" to the sealed count) · `coming-soon` (Runewood: greyed under a glass cloche, "none on the cart today" - no fake urgency).
- **FindCard (Today's Finds):** `affordable` · `unaffordable` (warm reason - a Glimmer Find reads *"4 Glimmer - distill a spare enchanted bit at the Still,"* never a dead grey) · `owned-already` (soft "you've one - take a spare?" tag, never blocked) · `sold` ("gone to a good bench already · fresh finds at dawn") · **`locked-undiscovered` is never rendered** (gated out entirely).
- **SalvageStation (Melt + Still):** `empty` ("Nothing to spare - every bit's a keeper") · `has-items` · `melting` / `distilling` (render animation) · `core-locked` (🔒 "Fettle won't melt a bound soul") · `last-of-type` (soft confirm "your only Optic Visor - render it?", warn not block) · `done`.
- **DoorstepCoffer:** `available` (ribbon breathes) · `claiming` (ribbon unwinds) · `claimed` (a quiet empty ring + "back at dawn" - **no countdown, no streak, no expiry**).

**Ethics baked into the UI (each is a build-failing test if violated):** odds + the live epic-pity counter printed on every Coffer face; an **"Earn-only - never for real coin"** seal on the cart; dupes never auto-destroyed; **no paid reroll**; **no countdown-to-punish timer** anywhere; every unaffordable state points at the *free* path (the Melt or the gift), never at a wallet.

---

## 7. Visual + transaction-juice spec (cozy craft, never a checkout)

**Fettle's portrait.** Rendered in the same **320×240 PS1 `SubViewport` → `TextureRect` (NEAREST)** stack as `ManabitStage`, so Fettle lives at world fidelity and can breathe/bow. M0 = primitive stand-in (box torso + sphere dome + cylinder key + a glowing quad forge-belly, etched-plastic material + amber emissive). The **forge-belly breathes** on the idle cadence (~480ms sine, same as the Nook rune) and **flares once on every transaction**; the wind-up key turns ~1 rev/6s; a rare slow loupe-blink. Even the primitive must feel alive - glow + breathe + greeting bow are the M0 must-haves. Sculpted mesh + rig is post-M0. States: `idle` / `greeting` (bow + belly-flare, reuse `core_wake`) / `appraising` (leans in when you load the Melt) / `selling` (hands the Coffer over) / `gifting` / `apologetic` (soft shrug, never a frown or red-X).

**Buy a Coffer (~700ms) - a sealed hand-off, purchase and reveal QUARANTINED.** Tap an affordable CofferWare → Fettle reaches with a small bow → the **wax `SOLD` seal thunks over the price numerals** (`wax_stamp` + `--stamp-thunk` 140ms BACK-out squash) → the ⚙ chip **rolls down** by the price (`--delta-roll`, descending `scrap_pour`) → the **sealed Coffer slides across the cart** into your count (`coffer_slide`). **No rarity reveal here, ever.** The Waking stays exclusive to the Coffer Nook. *This is the single strongest anti-gacha move: commerce is calm, anticipation is quarantined.* Test: if buying ever triggers a pull/reveal animation, it's a slot machine - kill it.

**The Melt (→ Scrap).** Tap a spare (or "Melt all common dupes") → each bit-card **tips into the forge-belly**, its glyph-light flares then dims to warm filings (`melt_render`), the belly-glow brightens → the ⚙ chip **rolls up** (rising `scrap_pour`), a warm **"+N filings"** toast floats up (colored `--brass-hi`, *not* delta-green - green/red are reserved for stat deltas). Fettle nods. Framed as *rescue*, never destruction - bits render to filings, no shatter/gore VFX.

**The Still (→ Glimmer).** Send a RARE/EPIC spare to the back-still → a bead of soul-light drips into a little vial (`glimmer_catch`, a soft chime), the ✦ chip rolls up by 1 or 3.

**Claim the Doorstep Coffer.** Tap the ribboned Tin → ribbon unwinds (`gift_found`, warm two-note) → Fettle tips the loupe → +1 Tin, no scrap change → spot settles to the quiet empty ring.

**Can't afford (anti-dark-pattern).** Numerals warm to `--wax-seal`, a single soft `invalid_clunk` (no buzz-of-shame), Fettle shrugs apologetically, tooltip points at the free path: *"A few filings short - melt a spare, or take the day's gift."* No red X, no "buy more."

**DESIGN.md additions - author BEFORE any styling (house rule):**
- **Tokens:** add **`--wax-seal #9A5A3C`** (the SOLD stamp, tag knots, unaffordable pre-glow). **Glimmer reuses `--stat-energy`** (teal); Scrap reuses `--brass-hi`. Motion: add **`--stamp-thunk` 140ms BACK-out**; odometer reuses `--delta-roll`. (Two new tokens total - restraint.)
- **SFX seams (named, wired via `Sfx.play(&"…")`, SILENT in M0 like the rest - cozy-craft only):** `scrap_pour` (dry brass-filings *shhk*, pitch↑ gain / ↓ spend - NOT a coin jingle), `wax_stamp` (waxy thunk), `melt_render` (glassy crumble → filings), `glimmer_catch` (chime into a vial), `coffer_slide` (sealed box slides into your keep), `gift_found` (warm two-note), `fettle_greet` (clockwork grumble - may reuse `core_wake`). **Banned (reaffirm):** casino chimes, register ka-ching, coin-cascade jackpots, foil crinkle.
- **Components (each ships all applicable states above):** `BrokerPortrait`, `CurrencyChip` ×2, `CofferWare` (odds+pity on face), `RunePriceTag` (parchment + brass eyelet + wax knot + etched rune-numerals, sways ~2° on idle; states default / unaffordable / paid-SOLD), `FindCard` (reuse `PartCard` visual + price row), `SalvageStation` (Melt + Still), `DoorstepCoffer`.

---

## 8. The Godot binding (surgical diffs against the built code)

All economy math lives in `PlayerState`/`Broker`; the screen only calls it - **no stat math in a widget** (mirrors the builder's rule).

**`meta/player_state.gd`** (mutate `bits` **in place** - `BuildSession` shares that Array by reference; never reassign it):
```gdscript
var glimmer: int = 0
var coffers: Dictionary = {"tin": 1, "brass": 2}   # was: coffers:int = 3
var broker_shelf: Array = []          # [{id, scrap, glimmer, sold}]
var last_gift_day: int = 0            # unix-day stamp of last Doorstep claim
var last_shelf_day: int = 0

func coffer_count() -> int: return int(coffers["tin"]) + int(coffers["brass"])
func buy_coffer(kind: String) -> bool          # debit Scrap by TIN/BRASS_PRICE; coffers[kind]+=1 (SEALED, not opened)
func open_coffer(kind: String) -> Array[PartInstance]   # kind → roller.roll_tin()/roll_brass(); decrement; append in place; _discover
func buy_find(i: int) -> bool                  # debit Scrap or Glimmer; append full-HP PartInstance in place; _discover; mark sold
func melt_bit(pi) -> int                        # REFUSE is_core; never last copy; Scrap += Broker.salvage_scrap(pi.data); bits.erase in place
func melt_common_dupes() -> int                 # every COMMON id owned ≥2 of, keep one; never a core/last/damaged single
func distill_bit(pi) -> int                     # REFUSE core/COMMON; never last copy; Glimmer += Broker.distill_glimmer(pi.data); erase
func claim_doorstep(today: int) -> bool         # today > last_gift_day → coffers.tin += 1; last_gift_day = today
func refresh_broker(today: int) -> void         # today > last_shelf_day → broker_shelf = Broker.roll_shelf(today, self); last_shelf_day = today
```
Extend `grant_starter_kit()` to also set `scrap = 50`, `glimmer = 0`, `coffers = {"tin":1, "brass":2}` (keeps the existing 3 cores + rigged Brass roll).

**`economy/broker.gd`** - `class_name Broker extends RefCounted`, pure & statically typed:
```gdscript
const TIN_PRICE := 40
const BRASS_PRICE := 100
static func salvage_scrap(pd) -> int        # COMMON 8 / RARE 20 / EPIC 45
static func distill_glimmer(pd) -> int      # RARE 1 / EPIC 3 / COMMON 0
static func find_price(pd) -> Dictionary    # COMMON {scrap:25,glimmer:0} / RARE {0,4} / EPIC {0,10}
static func roll_shelf(day_seed: int, player) -> Array   # 3 distinct DISCOVERED, non-core ids,
        # seeded by day_seed, prefer owned-0; each {id, scrap, glimmer, sold=false}
```

**`economy/pack_roller.gd`** - thread a common-heavy weighting into `roll_tin` (~85/12/3) so Tin stays net-negative (§4). Brass keeps 70/22/8 + rare floor + epic-pity.

**`meta/save_manager.gd` → v2** (additive, back-compat): bump `version` 1→2; persist `glimmer`, `coffers` (dict), `last_gift_day`, `last_shelf_day`, `broker_shelf`. **Migration v1→v2 in `load_into`:** if `coffers` loads as an int → `{"tin":0, "brass":<that int>}`; default `glimmer:0`, day-stamps `0`, `broker_shelf:[]` (refills on next Barrow visit). `garage`, `loose_bits`, `compendium`, `scrap` keys untouched.

**`ui/root.gd`** (copy the ChestScreen path exactly): `broker = BrokerScreen.new().setup(player)`; `broker.done.connect(func(): _show(workshop))`; `workshop.open_broker_requested.connect(func(): _show(broker))`; append to `_screens`; add `goto_broker()`. `_show()` already calls `refresh_from_player()`, and `BrokerScreen.refresh_from_player()` computes `today` and calls `player.refresh_broker(today)` - so the shelf + gift arm on show with no clock code in `root.gd`.

**`ui/workshop.gd`:** add `signal open_broker_requested` + a **"Fettle's Cart"** button beside the existing Menagerie / Compendium / Open-Chests buttons, plus a small **⚙ Scrap chip** in the top bar (scrap is currently invisible during building - surface it). Update the chests-button label to use `coffer_count()`.

**`ui/chest_screen.gd`:** typed-coffer display + a small **Tin/Brass selector** calling `open_coffer(kind)` (shown only when you own >1 type, else opens the one you have). The existing "No Coffers - earn some at the Broker" line becomes a tappable shortcut into the Barrow.

**Firewall invariants preserved end-to-end:** Coffers are the randomized out-of-combat faucet; Today's Finds are completion-only, discovered-gated, Glimmer-gated; **cores never enter the economy** (never in Coffers, excluded from `roll_shelf`, refused by the Melt/Still); Fettle sells SEALED (reveal stays in the Nook). Combat's deterministic "one real part off the loser" contract is neither duplicated nor cheapened; when combat lands, run-Coffers + win-Scrap simply **replace** the Doorstep scaffold - nothing here changes.

**`tests/smoke_broker.gd`** (headless `SceneTree`, arrange/act/assert, names per `test-standards.md`, prints `SMOKE PASS`/`quit(0/1)`):
`test_broker_buy_tin_debits_scrap_and_adds_sealed_coffer` · `test_broker_buy_brass_insufficient_scrap_is_rejected` · `test_broker_buy_find_common_debits_scrap_adds_full_hp_bit_and_marks_sold` · `test_broker_buy_find_rare_debits_glimmer` · `test_broker_melt_common_credits_scrap_and_removes_bit` · `test_broker_distill_rare_credits_glimmer_and_removes_bit` · `test_broker_melt_refuses_core` · `test_broker_melt_common_dupes_keeps_one_of_each` · `test_broker_salvage_never_removes_last_copy` · `test_broker_claim_doorstep_grants_tin_once_per_day` · `test_broker_shelf_deterministic_per_day_seed` · `test_broker_shelf_offers_only_discovered_non_core_ids` · `test_broker_buy_to_melt_is_net_negative` (seed roller, roll a large Tin & Brass batch, assert mean melt < price) · `test_broker_bits_mutated_in_place_preserves_shared_ref` · `test_savemanager_v2_roundtrips_glimmer_typed_coffers_and_broker_state` · `test_savemanager_migrates_v1_int_coffers_to_typed`. **Then re-run `smoke_contract` + `smoke_builder` + `smoke_persist` yourself** (update `smoke_persist`'s `coffers` assertion to the dict shape / `coffer_count()`) - don't trust a lane's green.

---

## 9. Deferred, named now (bolt on without changing anything above)
- **The Coaxing** (was "Reforge") - *coax three napping same-rank dupes into trading places* until the missing one wakes (a swap, never a shatter - honors "never melt a soul").
- **A Standing Order** (was "Attunement") - pay a premium; Fettle "keeps a nose out for attack-scrap, come back next spiral" (affinity-restricted find).
- **Runewood Coffer**, the full priced Cartboard, **HP-scaled salvage** (teaches the M1 repair economy), the Doorstep accumulate-up-to-3 generosity tweak, and **Tuppence** (a wind-up brass magpie that fetches the Coffer across the cart - pure "someone hands you a thing" juice). Combat-fed faucets replace the Doorstep scaffold when M1 lands.
