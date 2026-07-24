# THE BARROW - Transaction-Juice Spec (buildable, `ui/broker_screen.gd`)

Commerce speaks combat's four-verb language, retuned from SNAP to SETTLE. Combat's `_juice` (in `ui/combat_screen.gd`) does: floating number (always) · recoil punch (gated) · hit-flash (gated) · SparkBurst (gated). The Barrow's cozy-craft analogs:

| Combat verb | Barrow analog | Gating |
|---|---|---|
| floating `−N` number | currency **odometer roll** + a **`＋N`/`−N` toast/wisp** | info ALWAYS plays |
| recoil scale-punch on the stage | **wax-stamp thunk** on the price tag | gates off |
| hit-flash (≤0.22a) | **local warm bloom** (belly-ember / teal still-shimmer) | gates off |
| SparkBurst radial blast | **2-3 filings-motes that RISE** (small, tinted) | gates off |

The one element every transaction routes through is the **CurrencyChip odometer** - commerce's shared spine. Build it first; every beat sheet ends by feeding it.

---

## §0 · Reconciliation ledger (conflicts resolved, so the dev has one answer)
1. **Stamp shape/pacing:** DESIGN §7 says `--stamp-thunk` 120ms/1.4→1.0; built `_stamp` uses `squash_pop 0.14` (0.85 small-start - wrong). **Resolved:** new `Juice.stamp_thunk`, **1.4→1.0 BACK-out over 140ms** (keep built pacing), lands at **−14°**. Update the DESIGN §7 token text 120→**140ms**.
2. **Odometer duration:** 220ms sits inside DESIGN §4 `--delta-roll` (150-250ms). **Resolved: 220ms `TRANS_CUBIC/EASE_OUT`; reduce-motion shortens to 120ms but still rolls.**
3. **Chip flash color:** never stat green/red (`DELTA_POS/NEG` are reserved for stat deltas). **Resolved:** gain → brighten toward `Tokens.LAMP_KEY`; spend → dim toward `Tokens.WAX`; ease home to `BRASS_HI`(⚙)/`STAT_ENERGY`(✦). Plus a `squash_pop(0.12)` land-nudge.
4. **SFX names:** DESIGN §7 is canonical and the built code already fires `wax_stamp/forge_melt/still_drip/doorstep_untie`. **Resolved:** use DESIGN §7 names (`coin_scrap`, not `scrap_pour`; `still_drip`, not `glimmer_catch`; etc.). **Exactly ONE net-new seam to author: `coffer_slide`.**
5. **Buy-Find celebration:** the brief's "＋1 Compendium?" is a lie - Finds are discovered-gated re-acquisition (`Broker.roll_shelf` only offers ids already in `compendium`), never discovery. **Resolved: "＋1 to the bench"** (no `?`). Compendium juice stays exclusive to the Coffer Nook Waking - protects the discovery firewall.
6. **Spend feedback:** unify the two contributions - a **BUY** = a `−N` **spend-wisp** that peels off the ware and arcs into the chip, landing to trigger the down-roll; an **EARN** (melt/still) = a `＋N` **toast** rising from the belly/vial with the up-roll.

---

## §1 · THE SHARED SPINE - CurrencyChip odometer (BUILD FIRST)
Today `refresh_from_player()` teleports the count (`_scrap_chip.text = "⚙ %d"`, lines 160-161). Replace with a roll driven entirely inside `refresh_from_player()` by comparing a stored last-shown value to the live one (decouples the roll from every transaction site).

- **Helper:** `Juice.odometer(label, from_i, to_i, prefix, dur:=0.22)` - `tween_method` on an int→`"%s %d" % [prefix,v]` setter, `TRANS_CUBIC/EASE_OUT`; digits visibly roll old→new. Reduce-motion: `dur=0.12`, still rolls (never a teleport).
- **State:** `_shown_scrap`/`_shown_glimmer`. `_ready`: init both to the live value **before** the first refresh (no roll on screen open). Each refresh: roll `_shown → player.scrap`/`player.glimmer`, then store the new value.
- **Direction encodes intent** (interpolation handles both): BUY rolls **down**, melt/still/gift-count roll **up**.
- **Land cue:** on tween end → `Juice.squash_pop(chip, 0.12)` + a **brightness flash** (gain→`LAMP_KEY`, spend→`WAX`) that eases home over 220ms. Home colors stay `BRASS_HI`(⚙)/`STAT_ENERGY`(✦). Never `DELTA_POS/NEG`.
- **SFX:** `coin_scrap` once per roll - pitch ↑ gain / ↓ spend. Never per-digit, never a jingle/ka-ching.
- **Haptic:** `Input.vibrate_handheld(18)` ONCE at roll start, only when the value changed. Only one currency moves per transaction, so this is one tick/transaction. Per-digit haptics banned.

## §2 · THE WAX-STAMP SPINE + the FX overlay (fixes the invisible-stamp bug)
**Bug (real, lines 311-332 + 403-405):** `_on_buy_*` calls `_stamp(card)` then `refresh_from_player()` immediately; refresh `_clear()`s the column and `queue_free()`s that card **and its stamp child** end-of-frame → SOLD/TAKEN never renders. **Fix:** add a persistent `_fx: Control` overlay (full-rect, `MOUSE_FILTER_IGNORE`, added LAST in `_build_layout` - same pattern as combat's `_fx`, line 166) and run all transient FX (stamp, toasts, wisps, motes, hand-off) on it, positioned over the target's `get_global_rect()`. The stamp survives the rebuild because it's no longer parented to the freed card.

- **`Juice.stamp_thunk(node, dur:=0.14)`:** `pivot_offset = size/2`; scale **1.4→1.0** `TRANS_BACK/EASE_OUT`, rotation settling to **−14°**. Reduce-motion: place at scale 1.0, no overshoot (fade-in over 60ms). Color `Tokens.WAX`, size 22, fade out after 0.5s.

## §3 · Toast / wisp / hand-off primitives (on `_fx`)
- **`_toast(text, color, at_global, rise:=40.0)`** - mirrors combat `_float_damage`: rise `rise`px over ~500ms `QUAD/EASE_OUT`, fade the last 300ms. Always plays (info). Reduce-motion: `rise=20`.
- **`_spend_wisp(from_rect, text, color)`** - a `−N` label peels off the ware and arcs to the matching chip over 350ms ease-in; on arrival the chip's roll is already running. Reduce-motion: straight 150ms fade (roll still fires).
- **`_handoff(from_rect, glyph)`** - a glyph arcs from the ware to the **keep readout** (§6), scale 1.0→0.7 over 340ms ease-in-out; `coffer_slide`. Reduce-motion: 150ms cross-fade to the keep count.

## §4 · Fettle reaction layer (the character on top - combat's recoil/reaction analog)
Author on the **existing** `fettle_portrait.gd` sine-breath (`0.6 + 0.3*sin(t/520)`), not a new asset. Add `var _pulse := 0.0` (decays in `_process`), fold `_pulse` into the belly+loupe brightness in `_draw`, and expose `pulse(a:=0.3)` / `apologise()`. Keep a `_fettle` ref in the broker.
- **Sale/gain pulse (every success):** `_fettle.pulse(0.3)` → loupe brightens (≈×1.4, 120ms up/200 settle) + one belly swell + a ~2° bow. `fettle_appraise`. Reduce-motion: belly brightness only (soft), drop the bow/lean.
- **Apologetic dim (refusal):** `_fettle.apologise()` → belly dims ~20% for 300ms then recovers + a slow loupe-blink + ~2° shrug. Never a frown, never a red-X.

---

## §5 · PER-TRANSACTION BEAT SHEETS

### 1 · BUY COFFER (~700ms) - purchase & seat, **NO rarity reveal**
| t (ms) | beat | motion / token | SFX | reduce-motion |
|---|---|---|---|---|
| 0 | Fettle small bow, belly swell, loupe brightens | `_fettle.pulse(0.3)` | `fettle_appraise` | belly brightness only |
| 60-200 | **Wax "SEALED" stamp thunks over the price tag** (on `_fx`) | `Juice.stamp_thunk`, WAX, land −14° | `wax_stamp` (single thunk) | fade-in at scale 1.0 |
| 200-420 | **⚙ Scrap odometer rolls DOWN by price**; `−P` spend-wisp arcs tag→chip | shared spine, dim-recover, 1 haptic | `coin_scrap` ↓ | roll 120ms, wisp→150ms fade |
| 300-640 | **Sealed Coffer hand-off** arcs to the keep readout; keep count ticks +1 | `_handoff`, scale→0.7, 340ms; keep `squash_pop(0.12)` | `coffer_slide` | 150ms cross-fade to count |
| ~700 | micro-toast "＋1 tucked in your keep"; bark settles | `_toast`, BRASS_HI | - | - |

**Bark:** *"Salvaged this one a few spirals over. Yours to wake, at your own bench - I never peek."*
**HARD RULE (build-failing):** no Coffer opens, no pull, no odds spin, no rarity reveal here - the Waking lives ONLY in the Coffer Nook (`player.open_coffer` is a different screen). A reveal on a BUY is a slot machine. `buy_coffer` only increments `player.coffers[kind]`; that is the whole transaction.

### 2 · BUY FIND (~750ms) - the bit settles into your collection + honest nudge
| t (ms) | beat | motion / token | SFX | reduce-motion |
|---|---|---|---|---|
| 0 | Fettle nods | `_fettle.pulse(0.3)` | `fettle_appraise` | belly only |
| 40-200 | **Wax "TAKEN" stamp** over the FindCard price row | `stamp_thunk`, WAX | `wax_stamp` | fade-in |
| 120-560 | **Bit card hand-off to the Salvage-Tray anchor** - ghost lifts +4px (`--card-lift`) then arcs down, scale→0.65, soft landing squash | `_handoff` variant, 380ms ease-in-out | `coffer_slide` | 150ms cross-fade to tray |
| 200-420 | **Correct-currency odometer rolls DOWN** (`⚙` COMMON / `✦` RARE·EPIC - chip color IS the tell); spend-wisp | shared spine | `coin_scrap` ↓ | short roll |
| ~560 | **"＋1 to the bench" toast** near the tray | `_toast`, BRASS_HI, brass-underline sweep | - | rise 20px |
| ~750 | FindCard → `sold`; card's Take button crossfades to the taken tag | - | - | - |

**Bark:** *"Good eye. Off it goes to a maker who'll wake it proper."*
**Firewall note:** celebrate "＋1 to the bench" - NEVER "＋1 Compendium". Undiscovered ids are never rendered on the shelf.

### 3 · THE MELT → Scrap (~650ms) - RESCUE, not destruction
| t (ms) | beat | motion / token | SFX | reduce-motion |
|---|---|---|---|---|
| 0 | Fettle leans toward the belly (anticipation, before the render) | ~100ms lean + `pulse` | `fettle_appraise` | belly warm only |
| 40-300 | **Bit tips into the forge-belly** - card rotates ~15° + slides down, scale→0.5, glyph-light flares then dims to ember (`GLOW_BASE`→`BENCH_LO`). **No shatter/crack/gore.** | 260ms ease-in | `forge_melt` | card fades in place 150ms |
| 300-400 | **Ember bloom** at the belly (local, ≤0.22a, 100 up/250 settle) + **2-3 filings-motes RISE** - a small `SparkBurst` (~40px) tinted `BRASS_HI`, its node tweened up ~10px over its 0.28s life | burst analog, sparse+rising | - | no motes; belly swell only |
| 320-540 | **⚙ Scrap odometer rolls UP by N**, brighten | shared spine | `coin_scrap` ↑ | short roll |
| ~360 | **"＋N filings" toast** rises 40px from the belly | `_toast`, BRASS_HI (never delta-green) | - | rise 20px |
| ~650 | Fettle nods → idle | - | - | - |

**Bark:** *"Down to warm filings it goes. Nothing's ever wasted here. (＋⚙N)"*
**Melt-all:** same beats; a handful of cards tip in a 60ms-staggered cascade; one aggregate toast + bark *"Melted N common spares down. (＋⚙M)"*; on none: *"No common spares to melt, maker - you keep a tidy bench."*

### 4 · THE STILL → Glimmer (~750ms) - the slowest, most precious
| t (ms) | beat | motion / token | SFX | reduce-motion |
|---|---|---|---|---|
| 0 | Fettle turns to the back-still, careful; loupe brightens teal-ish | gentle `pulse` | `fettle_appraise` | loupe only |
| 40-320 | **Enchanted bit rises UP-and-back** (opposite of the Melt's DOWN - vertical direction encodes refine-up vs render-down), scale→0.5, rune-accent shimmer (COBALT rare / AMETHYST epic) | 280ms ease-out | quiet rising hum | fade in place |
| 320-560 | **Bead(s) of soul-light drip into a vial** - one teal `STAT_ENERGY` `#3FD0C0` bead falls + tiny bounce-settle, 240ms. **RARE = 1 bead; EPIC = 3 beads 90ms apart** (quiet rarity tell, never a jackpot). Teal shimmer on vial+chip ≤0.2a | `_glimmer_drip(count)` | `still_drip` **per bead** (EPIC = 3 ascending chimes) | drop the drip particle; vial swell only |
| 360-580 | **✦ Glimmer odometer rolls UP, synced to the drips** - the `still_drip` chimes ARE the odometer audio (**no `coin_scrap` layered**) | shared spine, teal brighten | (the drips) | short roll |
| ~640 | **"＋N Glimmer" toast** in teal | `_toast`, STAT_ENERGY | - | rise 20px |

**Bark:** *"There's a little bound-light in this one. Caught it proper. (＋✦N)"*
Deliberately ~100ms slower than the Melt - pacing says "this currency is rarer" without number-shouting.

### 5 · THE DOORSTEP (~600ms) - the Tin appears; **NO currency change**
| t (ms) | beat | motion / token | SFX | reduce-motion |
|---|---|---|---|---|
| 0 | Fettle tips the loupe (soft blink + belly warm) | `_fettle.pulse(0.2)` | `fettle_greet` | belly only |
| 40-300 | **Ribbon/wax-seal unties** - knot pops (stamp_thunk in REVERSE: 1.0→1.15→0, 140ms), ribbon ends sweep apart + fade | 260ms ease-out | `doorstep_untie` | ribbon cross-fades out 150ms |
| 280-520 | **Tin appears** (scale 0.7→1.0, `squash_pop(0.16)` overshoot) then rides the **same `coffer_slide` hand-off arc** into the keep count | `_handoff`; count +1 | `coffer_slide` | cross-fade to count |
| ~600 | Doorstep → claimed: quiet empty ring + "back at dawn" | - | - | - |

**Bark:** *"Left one on your step this morning. Always do."*
**The shared spine is intentionally ABSENT** - no odometer, because the gift costs nothing; the keep-count pop stands in and its silence says "this was free." **No countdown, no streak, no expiry ever renders** (`doorstep_available` is a calendar-day check with no penalty - anti-dark-pattern).

---

## §6 · ELEMENT STATES (every element ships all applicable states; legible without color alone; 48dp targets; price+glyph on every face)

**CofferWare** (`_coffer_ware`, Tin 40 / Brass 100 Scrap) - idle/affordable (`BRASS_HI` tag, odds + epic-pity line on face, coffer glyph breathes) · **too-dear** (numerals → `Tokens.WAX`, append shortfall chip `⚙40 - 12 short`; **stays tappable**) · hover (lift +4px, tag brightens, loupe glances over) · pressed (scale 0.96, border → `LAMP_KEY`) · just-transacted (Trinity + hand-off slide, **no reveal ever**) · sold-out (Coffers don't sell out - greyed Runewood cloche "none on the cart today", never a timer).
> **Fix line 192:** unaffordable currently uses `Tokens.DELTA_NEG` (stat red) - change to `Tokens.WAX` + add the shortfall chip.

**FindCard** (`_find_card`) - affordable (price in currency color, rarity frame material + rune-rim) · **too-dear** (numerals → `WAX` + a warm reason line, e.g. Glimmer find → *"✦4 - distill a spare at the Still"*, Scrap find → *"melt a spare at the Melt"*; stays tappable) · hover/pressed (as CofferWare) · owned-already (soft tag *"you've one - take a spare?"*, never blocked) · just-transacted (Trinity; Take crossfades to taken tag) · **sold** (*"- gone to a good bench · fresh finds at dawn -"* in `WAX`, replacing the bare "- taken -"). Undiscovered ids never rendered.
> **Fix line 234:** unaffordable currently greys to `Color(PARCHMENT,0.4)` (dead grey, banned) - change to `WAX` numerals + reason line.

**SalvageBit** (`_salvage_bit`) - idle (`Melt ⚙N` / `Still ✦N` on the face; Still shows only when `distill_glimmer>0`, so commons never offer it) · has-items→transact (Melt/Still beats §5.3/5.4) · **core-locked** (render the core with a `🔒 a bound soul stays` chip instead of hiding it; its Melt/Still are locked → tap = firewall refusal). Optional last-copy soft-confirm is deferred (the model already melts safely).
> **Fix line 277:** `if pi.data.is_core: continue` hides cores - render the locked state so the combat-loot firewall is *taught*, not invisible.

**DoorstepCoffer** (`_rebuild_doorstep`) - available (ribbon breathes, "Take the day's gift") · claiming (§5.5) · claimed (quiet ring + "come back tomorrow"; **no countdown/streak/expiry** - current copy is correct).

**CurrencyChips** (top-right) - the odometer (§1). Add a **keep readout** `◈ in your keep: N` under the Cartboard header (`player.coffers.tin + player.coffers.brass`) so every hand-off slide has a legible destination.

**BarkRibbon** (`_bark_say`, line 367) - today a raw text swap. Give it a 2-beat settle: fade-out 80ms → swap text → fade-in 120ms + a 2px parchment drop. Every transaction AND every refusal writes a bark, so Fettle always narrates the *why*.

---

## §7 · REFUSALS - the anti-dark-pattern reaction (never silent, never a red-X)
- **Unaffordable tap:** `_fettle.apologise()` + tapped numerals warm to `WAX` + shortfall chip + card **stays tappable**; ONE soft `invalid_clunk` (NOT combat's double-buzz); pulse the Melt/Doorstep header once (`LAMP_KEY` sweep) to physically point at the FREE path. Bark ALWAYS names the free path, never a wallet:
  - Coffer short: *"A few filings short, maker. No shame - melt a spare, or take the day's gift."*
  - Find short: *"A little short for that one, maker. The bound ones ask for Glimmer - distill a spare."*
- **Core-lock tap (the firewall, reachable once cores render):** `apologise()` + `invalid_clunk` + bark *"A bound soul stays bound, maker - I'll not melt a heart that's still beating."*
- **No silent dead taps:** add the `else` branch to `_on_melt`/`_on_distill` (lines 341-355) - any `g==0` refusal barks the reason + `invalid_clunk`, so the player always learns why.

## §8 · REDUCE-MOTION + PHOTOSENSITIVITY (mirror combat's own discipline exactly)
Combat gates `_punch`/`_flash_stage`/`_core_flash`/SparkBurst but lets `_float_damage` ALWAYS play. Same rule here: **information floats always; impact/flash/particles gate.**
- **KEEP:** odometer roll (→120ms), its color flash (a tint, not jitter), all SFX, every `＋N`/`−N` toast (rise 40→20px).
- **DROP/replace:** stamp SLAM (fade-in at 1.0), the hand-off ARC (150ms cross-fade), filings-motes + still-drip particles (value + toast still fire; belly/vial do a brightness swell only), Fettle's bow/lean (soft belly brightness stays).
- **Photosensitivity:** **NO full-screen flash anywhere in the Barrow - never call combat's full-screen `_core_flash`.** Every glow is LOCAL (belly, vial, chip), single-shot, ≤0.22 alpha. No strobe/flash-train: the odometer flash is a slow 220ms ease; EPIC's 3 still-drips are low-alpha local drips ≥90ms apart. One haptic tick per transaction.

## §9 · HONESTY INVARIANTS (build-failing assertions)
1. Prices always on the face in currency color; shortfall shown as a number, never a mystery grey.
2. Odds + live epic-pity count printed on every Coffer face.
3. Reveal quarantined - a BUY never triggers a pull.
4. Earnings float in currency color (`BRASS_HI`/`STAT_ENERGY`), never `DELTA_POS/NEG`.
5. Sold = "fresh finds at dawn" - no fake scarcity/urgency.
6. Doorstep = "back tomorrow" - no countdown/streak/missed-day penalty.
7. Too-dear always points at the free path (Melt/gift), stays tappable, never a wallet.
8. Cores shown locked (`🔒`), never silently gone; dupes never auto-destroyed; no paid reroll; no currency conversion.
