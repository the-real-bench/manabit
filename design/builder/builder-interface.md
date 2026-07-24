# MANABIT - The Workshop (Builder Interface) - Unified Design

*Lane A / M0. Binds to the §13 Frozen Contract. Single source of truth for the builder build.*

> **TERMINOLOGY (LOCKED 2026-07-11 by owner) - read before this doc.** A **bit** is a single piece/part
> (the tray holds your *bits*). A **Manabit** is the whole assembled robot. Where earlier prose below
> calls the 3D construct on the Stand "the bit," read that as "the **Manabit**." **Opening chests
> (Coffers) is its OWN screen** (the Coffer Nook); the **Workshop** screen is assembly only. The two
> are separate flows, navigable back and forth.

---

## 0. The fantasy, in one line

**You are a maker-mage at a lamplit workbench: crack open a Coffer of sleeping scrap, wake it with your mana, and tinker the pieces into a clockwork champion that is unmistakably yours.** The builder must be fully fun with *no combat*: the reward you chase in M0 is a **resolved, named Manabit**, and everything needed to fall in love with it - the pack ritual, the theorycraft, the collection - lives on this one screen.

Three fun-hooks lead in equal measure: **tactile juice** (the Waking + the snap + the core waking up), **optimization/theorycraft** (live before→after stat deltas + the weight budget + what the game *names* your build), **expression/collection** (christen it, pose it, shelf it, complete the dex).

**Five tone guardrails (falsifiable - every element must pass all five):**
1. **Handmade, not manufactured.** Wax seals, wound latches, glyphs cut *into* plastic. *Test: if a UI element could live in a Vegas card app or a loot-box game, it's wrong.*
2. **Mana-glow is warm and SOURCED.** Amber/honey base + one affinity hue, always emanating from a socket, seam, core, or glyph - an ember, never a neon flood or circuit-trace. *Test: if it reads as a PCB, kill it.*
3. **Cozy over epic, warm over cold.** Honeyed woods, brass, patinated tin, soft plastics, workshop-lamp light. No crushed blacks, no clinical white.
4. **Parts are toys with souls, not weapons or gore.** A damaged part reads as a *scuffed/sleepy toy* - dulled glow, loose spring, dinged panel - never blood, never a severed limb.
5. **You DO things with your hands.** Every core action is a physical craft gesture - channel a seal, drag-and-snap a part into a socket, thumb a nameplate. No abstract menu confirm where a tactile gesture fits.

---

## 1. Screen anatomy - the Workshop

Player-facing room = **the Workshop**. The frozen save key stays **`garage`** exactly as §13.5 spells it - never rename the contract; the *room* just has a warmer name. Landscape-primary (the 3D bit + anchored sockets + tray triad needs horizontal room); portrait is a documented adaptation (preview top ~45%, Ledger as a swipe-up sheet, tray as bottom shelf).

```
 ┌───────────────────────────────────────────────────────────────────────┐
 │ NAMEPLATE "Cogsworth-7"  ◈affinity   [Pose][Frame]      Coffers ×2  ⚙  │
 │                    ┌─HEAD─┐                            ┌── THE LEDGER ──┐│
 │   ┌ARM_L┐         (ghost)         ╔═ THE STAND ═╗      │ ATK  8  ▲2      ││
 │  (socket)═════════════════════════╣ PS1 Manabit ╠══════│ DEF  3          ││
 │   └─────┘   CORE▶  (chest, glowing)║ on turntable║      │ SPD 12 → 4 ▼    ││
 │   ┌ARM_R┐                          ╚═════════════╝      │ MANA 6         ││
 │  (socket)              ┌─LEGS─┐   ┌BACK┐               │ ⚖ ▓▓▓▓▓▓▓█░░ 110││
 │                                                        │  −10 SPD (over) ││
 │                                                        │ Kit: 1S·1M·1G   ││
 │                                                        │ ▸ Skirmisher    ││
 │                                                        │ [Compare]       ││
 │───────────────── THE SALVAGE TRAY (drawer) ───────────────────[COFFER]──││
 │ [HEAD][CORE][ARMS][LEGS][BACK] · sort:Newest▾ · filter    NOOK: ◈ Coffer ││
 │ [card][card][card][card][card][card]  ⟵ scroll ⟶       [ ⬛ BANK MANABIT ]││
 └───────────────────────────────────────────────────────────────────────┘
```

**Canonical zone vocabulary (build UI to these names):**

| Zone | What it is |
|---|---|
| **The Workshop** | the whole builder screen |
| **The Workbench** | the central warm walnut surface under a single lamp |
| **The Stand** | a turntable pedestal holding the low-res 3D Manabit (PS1 SubViewport) - drag to spin, idle auto-rotates ~4°/s to show off |
| **The Sockets** (×6) | HEAD · CORE · ARM_L · ARM_R · LEGS · BACK - hex **SlotPlates** anchored *spatially to the body* (HEAD top, CORE chest, arms flanking, LEGS bottom, BACK shoulder-tab) with thin mana-thread leader lines to the 3D socket points |
| **The Salvage Tray** | bottom inventory drawer (felt-lined) of woken parts; collapsed = 1 peeking row, drag up to expand |
| **The Ledger** | the theorycraft panel - live stats, before→after deltas, the Balance, kit summary, archetype label, Compare |
| **The Balance** | the weight budget rendered as a brass balance-beam (the weight sub-meter of the Ledger) |
| **The Coffer Nook** | where an unopened Coffer waits |
| **The Menagerie** | gallery of your built/named/banked Manabits (the show-off home) |
| **The Compendium** | the parts "dex" - every part *type* you've woken, filled vs greyed silhouette |

**PS1 composite (locked technique):** a **fixed 320×240 `SubViewport` → `TextureRect` with `TEXTURE_FILTER_NEAREST`** (NOT a `SubViewportContainer` - the fixed viewport decouples chunky-pixel size from screen size so it looks identical on a phone and a 1080p monitor). Crisp **native-res UI chrome sits on top** so stat text stays razor-sharp. For M0 the render stack is only **low-res + nearest upscale + flat/vertex lighting + the mana-glow emissive material** - that already sells ~60% of the look. Vertex-jitter and affine-warp shaders are **deferred to Lane E**, not omitted.

---

## 2. The pack - the **Coffer**

An Artificer doesn't buy foil packets; they salvage. A **Coffer** is a hand-made lidded clockwork box of scrap the Artificer once wound shut and put to sleep so the bound-in mana wouldn't drain. The parts inside are **dormant** - grey, dark, still - until *you* wake them. That single fiction ("the parts are asleep, and I wake them") is why the open feels like a craft ritual, not a purchase, and it *rehearses the Artificer's core magic of animating dormant matter*. ("Cache" is a casual lowercase synonym only; the object is a Coffer.)

**Coherence rule - Coffers hold body parts ONLY, never a mana core.** Cores are *crafted* by the Artificer from affinities/blueprints (§7) - that is what makes a core "the bound soul you made," and it must never become loot. In M0 the player owns **3 starter cores** (one per affinity) pre-slotted in the CORE tab; Coffers supply HEAD/ARM_*/LEGS/BACK. This maps onto §13's `is_core` flag and keeps cores off the loot table forever.

**Coffer ladder** (tier name = the seal's material; the material doubles as the on-card rarity-frame language - see §9):

| Tier | Coffer | Parts | Contents | M0? |
|---|---|---|---|---|
| 1 | **Tin Coffer** | 3 | COMMON-weighted, no featured slot | **Ship** - the free per-session gift + cheap grinder |
| 2 | **Brass Coffer** | 5 | 1 **guaranteed RARE+** (featured slot) + epic-pity | **Ship - the M0 workhorse; build the whole loop around this** |
| 3 | **Runewood Coffer** | 5 | guarantees ≥1 EPIC + ≥2 RARE+ | Named + stubbed (post-M0) |
| - | **Attunement Coffer** | 4 | affinity-restricted (you choose atk/def/mana) | Post-M0 (the theorycrafter's tool) |

Five parts is deliberate for the workhorse: enough to meaningfully re-solve a 6-slot build in one open, not so many the tray floods.

---

## 3. The Waking - the Coffer-open ritual (the tactile-juice centerpiece)

Opening is an **active craft gesture**, not a tap. The player *animates the scrap*; they don't tear foil.

**Beat sheet (~2.8s, skippable after the crack):**
1. **Rest.** The Coffer sits in the Coffer Nook, lid shut, a faint amber pulse breathing on the wax **sleep-rune**; a Brass Coffer's clockwork latch *ticks* softly. Bed: warm workshop hum, low mana-thrum, distant clockwork chimes. Rest of the bench dims ~15% and the lamp pools onto it.
2. **Channel (press-and-hold).** You **press-and-hold the sleep-rune** to channel mana into the seal; a radial charge-ring fills (~0.8s), the rune brightens under your thumb, the thrum climbs in pitch, haptic ramps with escalating ticks, a clockwork ratchet rises. *This is you doing the binding - holding, not tapping.* On a Brass Coffer the three rune-bands click open one-per-third (tick·tick·tick).
3. **Crack.** At the threshold the seal gives with a warm **chime-snap** - *not* a foil rip - wax flakes scatter, a firm snap-haptic, a bounded flash (under the photosensitivity threshold, no strobe), the clockwork iris/lid springs open, overshoots, settles, a puff of warm mana-dust.
4. **Rise dormant.** A column of honey-warm light spills up; the parts rise out and hover, slowly turning - **grey and unlit**, still asleep.
5. **The Waking (ascending rarity, rarest LAST).** Each part **wakes** in turn - mana-glow ignites at its sockets, its etched glyphs catch light, a soft *tink* sounds - pitch and brightness rising with rarity. *The deepest-bound scrap stirs last:* the rarest gets a held beat. By default the parts auto-kindle in sequence; each is **tappable to wake early**, and **[Rake it in]** sweeps the rest in. This merges the cozy auto-cinematic with the per-part gacha anticipation.
   - **COMMON** (~0.6s): wrapping puffs to bone-grey motes, one slow hero-spin, soft *wood-tok*, light haptic.
   - **RARE** (~0.9s): a **cobalt ground-ring** pulses out, part gains a persistent cobalt rune-rim, glyphs glow blue-white, bright **glass chime**, medium haptic, slight time-dilation.
   - **EPIC** (~1.3s): background dims to warm-dark, spotlight snaps on, **amethyst shockwave ring** with **raining gold flecks**, a double-spin, glyphs blaze magenta-gold, a **deep bell + rising choral shimmer** (the one "big" sound), gold screen-edge vignette pulse, heavy double haptic, a banner unfurls: **"EPIC - [name]."**
6. **Land.** Woken parts drift down and **snap** into the Salvage Tray as cards (a *tile-clack* each). New part *types* get a brass **NEW** stamp (*ka-chunk*). A "Compendium +N%" ticker fires if any new type was woken.

**Sound palette (cozy-craft, no exceptions):** warm chime-snap (seal), clockwork ratchet + gear-ticks, wax-crack, spring-open, per-rarity reveal (wood-tok / glass-chime / bell+choral), workshop-lamp ambience. **Banned:** foil crinkle, plastic-crinkle, casino chimes, harsh electronic beeps. Feel: **winding open a music-box full of sleepy clockwork toys.**

---

## 4. Inventory + drag-and-drop - the hero interaction

### 4.1 The model it writes to (binds to §13, never reimplements it)

The builder is a **binding, not a new system**. A thin **`BuildSession` (RefCounted)** wraps a §13 `ManabitState`:

- **Inventory = `Array[PartInstance]`** (NOT `PartData`). One `PartInstance` = one physical owned part that lives *either* in the tray *or* in a slot. Equipping **moves** the object - this is what makes `current_hp` survive (a banked damaged part stays damaged), matches the §13.5 save shape (`{id, current_hp}`), and gives each part a real "this exact one has history" identity.
- **Equip writes into `bit.slots[slot]`**; the UI reads **only** `bit.derived()`, `pi.current_hp / pi.data.max_hp`, and `is_deployable()`. No stat math lives in a widget.
- **`slot_accepts(pi, slot)`**: ARM_L/ARM_R both accept any `ARM_*` part (§12.3 interchangeable); CORE accepts only `is_core`; everything else exact-match.
- **Displacement is conserved:** dropping onto an occupied slot pops the old `PartInstance` back to the tray - nothing is lost or duplicated.

### 4.2 Drop-on-bit magnet routing (the ergonomic key insight)

Slot type is **intrinsic to the part**, so precise aiming is mostly unnecessary: **dropping a part anywhere on the bit routes it to its only valid socket and magnet-snaps.** The *sole* ambiguous case is ARM_L vs ARM_R (both take `ARM_*`) - resolve by nearest-side, or if both are full, a swap-choice hover. This fixes touch ergonomics (no long precise drag to a far top socket) and adds snap juice.

### 4.3 Co-equal tap-to-equip (not a fallback)

A cross-screen touch drag is error-prone, so tap is a **co-equal** path, guaranteeing a complete no-drag route for one-handed and motor-accessible play:
- **Single-tap a card** → selects it, all valid sockets pulse, hint "Tap a socket to mount." Tap a valid SlotPlate → snap-equips. Tap the bit → auto-routes (arms → nearest empty, else swap chooser).
- **Double-tap a card** → auto-equips to the valid empty slot (occupied → swap; both arms full → deterministic ARM_R-then-ARM_L, else swap chooser).
- **Tap an equipped SlotPlate** → opens its card with `[Unmount] [Swap] [Inspect]`.

Both paths call the same `BuildSession.equip`. Native Godot Control DnD (`_get_drag_data` / `_can_drop_data` / `_drop_data`) with a `{kind, pi, origin}` Dictionary payload is the drag implementation; `_can_drop_data` doubles as the **live-projection trigger**.

### 4.4 Every interactive state (touch + mouse; never color-only)

**SlotPlate states:** `empty` (breathing ghost-socket silhouette + slot glyph; amber **! "needed"** pip if it blocks deploy) · `drag-eligible` (fitting sockets pulse green + spin the instant a drag starts; non-fitting dim to ~40% + desaturate) · `valid-hover` (ring snaps brighter, draws 2-3 short mana-arcs "reaching" for the part, translucent ghost part previews *on the mesh*, 1.05 scale) · `invalid-hover` (⊘ barred-socket, ring greys/breaks, tiny recoil, dull clunk, double-buzz - rare thanks to magnet routing) · `swap-preview` (⇄ glyph, old part ghosts to "will-return" fade, deltas show NET of swap) · `filled` (mini-mesh + name chip + 3 stat pips + rarity rim + HP bar) · `snap-success` (0.12s pop + socket flare) · `reject` (0.15s shake + dull SFX) · `damaged` (cracked overlay + HP pip) · `selected` (tap-place selection ring).

**PartCard states:** `default` (faint rune shimmer loop) · `hover` (lift 4px + glow + quick-stat pip) · `dragging-source` (40% dim, leaves a dashed-brass ghost) · `NEW` (brass ribbon) · `equipped-elsewhere` (dim + check) · `incompatible` (during a slot-selected state) · `damaged` (`current_hp < max_hp` → cracked frame + HP pip `12/20`; at 0/disabled → heavy crack + greyscale) · `selected` (tap-place ring) · rarity frame material always present.

---

## 5. The Ledger - theorycraft made fun with zero combat (fun-hook #2)

Everything binds to the frozen API and is *honest* - it's the actual contract math, not a fake preview.

**(a) Live stat bars + before→after ghost.** ATK/DEF/SPD/WEIGHT/MANA as bars with numbers. The killer feel: **while a part hovers a valid slot (pre-drop)**, call **`preview_derived_with(pi, slot)`** - it temporarily swaps the candidate into `bit.slots`, calls the *frozen* `derived()`, and swaps back (non-mutating). Paint a translucent "would-become" overlay with colored ±deltas (`24 → 31 (+7)`, green up / red down) and a number roll. Same when hovering a tray part against an already-slotted one (swap delta). Because it reuses §13 math verbatim, the preview can **never drift** from committed values.

**(b) The Balance - weight budget as its own hero meter (not a radar axis).** A 0→**100** brass balance-beam with a bright budget line at `WEIGHT_BUDGET`. Under the line: level and green, label **"0 SPD penalty."** Over it: the overflow segment tips and hatches amber→red with a live **"−N SPD (overweight)"**, where `N = (weight − 100) × OVERWEIGHT_SPD_COST`. Because *only* overweight costs SPD (§12.6 soft threshold) and `derived()` clamps SPD to ≥1, the decision is never "avoid weight," it's **"how far over is the hitting power worth?"** - a genuine frontier problem, legible without a single fight.
  - *Worked example (real §13.7 numbers):* two heavy arms (hammer 40 + flail 30) + legs 30 + core 10 = **110 weight → −10 SPD**; base SPD 14 → **4**. Swap the flail for a 10-weight light arm → 90 weight, back under budget → **SPD 14**. That trade - a MULTI move + 3 ATK for **+10 initiative** - is a complete, satisfying theorycraft decision on day one.

**(c) Castability.** Mana pool = `derived().energy` (starts full in a fight, regens `+MANA_REGEN_PER_TURN`=2/turn). Beside the kit, flag each move's `mana_cost` vs the pool: "⚠ your GUARD (cost 3) outpaces your pool (2)" - energy is a *live build stat*, a real reason to slot a mana-affinity core or an energy part.

**(d) Kit summary.** The 5 non-core parts each grant one move; render the tally straight from `ability.archetype` - e.g. **"1 SINGLE · 1 MULTI · 0 GUARD."** Pure pre-combat theorycraft: "all SINGLE, no GUARD = glassy racer" is readable from the panel alone.

**(e) Archetype label - the game names what you built (the Competence hit).** From stat thresholds + move mix the build snaps to a label: **Bruiser** (top-third ATK, overweight/low SPD) · **Skirmisher** (top-third SPD, light, ≥2 MULTI) · **Bulwark** (top-third DEF + ≥1 GUARD + high durability) · **Battery** (top-third ENERGY + GUARD) · **Glass** (top-third ATK + bottom-third durability) · else **All-rounder**. It *teaches the system by naming your build* and legitimizes many identities - explicitly **NOT** a single "power score" (a power number would lie about a multi-axis system and breed a dominant stat to max).

**(f) Compare.** A **[Compare]** toggle pins the current build as a ghost column to A/B any two builds across all axes + weight + kit (green/red deltas).

**Anti-dominant-strategy (catalog authoring rule - locked):** *higher rarity buys a higher stat ceiling **or** a stronger ability, ALWAYS paid for in weight, energy, or HP - never a pure upgrade.* So an EPIC arm might be the wrong archetype, push you overweight, or grant a MULTI when you wanted a SINGLE. "Always equip the shiniest" is designed out; the fit-vs-shiny decision that makes the collection interesting is preserved.

*(Stretch, high value: a 5-axis radar - ATK/DEF/SPD/ENERGY/DURABILITY, where durability = core max_hp + Σ part max_hp, surfacing the HP axis `derived()` hides; and **Commissions** - 3 rotating build-to-spec briefs like "SPD ≥ 18, WEIGHT ≤ 60, ≥1 MULTI" checked live against `derived()` + kit, giving the builder a directed objective before combat exists.)*

---

## 6. Juice & art choreography (fun-hook #1) - frame-by-frame

**Motion philosophy:** anticipation + back-ease overshoot; UI moves 120-220ms; big reveals get more; everything has a sound + a haptic tier. All feel-knobs live in a data file, tunable in playtest.

**THE SNAP (the money moment, ~350ms):** on release the part **rockets** the last few px into the socket (ease-in ~90ms - a magnetic catch, not a gentle settle). On contact: **squash** to 0.85 on travel axis / 1.15 perpendicular, spring back to 1.0 over ~180ms; the socket ring **flares white-gold 2 frames**; **8-12 warm sparks** burst from the seam (affinity-colored for a core) + a brief point-light pop; a shock-ring decal races across the whole toy and a glyph-shimmer travels limb-to-limb. **Hero SFX** = layered *chunky plastic-click (peg seating) + brass ding (rune catching) + short mana-shimmer tail*, pitch nudging up with rarity. **Heavy haptic** (the one strong buzz). Then the Ledger commits - numbers **roll** old→new over ~250ms, changed stats flash their color once.

**3D preview rebuilds limb-by-limb (synced to the snap):** the mesh **flies in from just outside its socket and snaps**, mirroring the UI gesture 1:1 (same timing + squash), with a 2-3 frame vertex "shiver" on impact (reserved for Lane E's jitter uniform; M0 approximates with a scale-in). Empty slots show a faint **wireframe ghost** of that slot type ("under construction," not broken). Invalid drop → springs back to origin (soft whiff, **no penalty** - it's a toy box, not a punishment).

**CORE-WAKE (the identity spine, dramatized - the single biggest cozy payoff):** before a core is seated the Manabit is **inert and dark**. The instant CORE snaps in, a **warm pulse radiates from the chest**, the head-glyph/eyes light, and it settles into a **breathing idle** - *the toy comes alive because you gave it a soul.* Mechanically true to §13 (core = life + affinity). Onboarding equips CORE first for exactly this beat.

**Overweight "strain" (soft cost - warn, never block):** past 100 the Balance glows hot red, a stamped **"STRAIN"** tag appears (stress-creak SFX), SPD shows the exact inline penalty. On the 3D toy the idle shifts to a **labored pose** - slumps ~5°, knees bend, bob slows and heavies, a red strain-glyph flickers at LEGS/CORE, a bead of steam vents. You **can still bank** - the sag makes you *choose* the trade knowingly.

**"BOUND!" completion flourish:** when the build is deployable (live core + ≥1 offensive part), the Manabit does a happy activation bob, all glyphs shimmer head-to-toe, a warm *chord resolves*, and the Bank button lights.

---

## 7. Expression & collection (fun-hook #3)

- **Christen it.** Top-bar nameplate; thumb it to "bind the soul by naming it" - a christen chime, lit glyphs, a brass nameplate **engraves** onto the Stand base. Cozy auto-default names + a reroll die: *Tock, Emberkin, Sprocket-7, Cogsworth Mk.II, Old Rusty, Emberpup.*
- **Pose + Build Card.** A pose picker the bit strikes on the turntable (M0: 2 poses - proud/ready + wave/sleepy-slump); a **[Frame]** that freezes the PS1 render into a stylized **Build Card** (composited preview + stat block + name) - the local show-off surface.
- **Affinity tints the whole build.** The core's `affinity` sets the mana-glow hue across the *entire* Manabit (attack ember-rust, defense slate-blue, mana flux-teal) - the soul animates the body, so two builds on different cores literally look different. Free expression + coherence straight off §13 data.
- **The Menagerie** - a warm shelf of your banked Manabits, each idling as a toy on its nameplate (damaged builds show dimmed/cracked parts; empty slots a dust ring). Tap one to bring it to the bench. Filling the shelf with characters you made *is* the standalone builder's macro goal and return hook.
- **The Compendium** - the parts "dex": every part *type* you've woken shown full + owned-count, undiscovered ones a **dim rune-etched silhouette** ("un-attuned"), on a cozy pegboard of labeled cubbies. Sort/filter by slot, rarity, affinity, weight, stat, owned/missing - the optimizer's reference *and* the collector's trophy wall in one surface, with a live completion %.

---

## 8. The pack / collection economy (M0 = minimal, never dead-ends)

The full faucet/sink model (buy-to-salvage net-negative, Reforge, Attunement, 4-tier shop) is the **Economy lane and is deferred**. M0 ships the smallest slice that keeps the collect loop closing *and never dead-ending*, with zero combat:

**In M0 (core):**
- **The Apprentice's Kit** - granted on a new save so the builder is instantly playable and **legal per §13.2** from the first second: the **3 starter cores** (one per affinity, pre-owned) + a **rigged first Coffer** guaranteeing exactly one full legal build (HEAD + offensive ARM (SINGLE) + GUARD ARM + LEGS + BACK, covering SINGLE/MULTI/GUARD) + starting scrap + **2 Brass Coffers** to seed the chase.
- **Seedable `PackRoller`** - real, deterministic-per-seed rolling with a **guaranteed ≥RARE floor** on the Brass Coffer's featured slot (kills the all-common feel-bad open) and a **visible epic-pity counter** ("Epic guaranteed in N", resets on any epic). Parts roll in at full HP.
- **Transparency baked in (ethics from day one):** **odds printed on every Coffer face** + a Details sheet + the always-visible pity counter. Earn-only - scrap is never real-money purchasable. No streaks, no timed FOMO, dupes never auto-destroyed.
- **The Broker's Gift** - each session, 1 free **Tin Coffer** (no streaks, no punishment for missing days) so you always progress even at 0 scrap.
- **Salvage stub** - a Dupe tray with a one-tap "Salvage All (+X scrap)"; scrap buys more Coffers at a 2-item **Broker's Stall** (Tin 40 / Brass 100, odds on the face). This gives dupes agency without the full economy.

**The M0 loop (closes with no combat):** *Apprentice's Kit → Wake a Coffer → drag-drop & theorycraft a build → salvage dupes to scrap → Broker's Gift + salvage buy the next Coffer → christen + bank into the Menagerie → Compendium % climbs → chase it.* The Broker's Gift guarantees the loop can never soft-lock at 0 scrap.

**Deferred to the Economy lane (named, not built in M0):** the Reforge Bench (shatter 3 same-rarity dupes → 1 guaranteed missing part), the Attunement Coffer, Runewood Coffer, the full 4-tier priced shop, combat-fed faucets. *Where combat plugs in later:* run-structure Coffers + win scrap simply **replace** the Broker's Gift scaffold - nothing in the pack system has to change. Combat loot stays the *opposite* contract (§6: deterministic, one real part off the loser); Coffers are the randomized out-of-combat faucet, so the two never contradict.

---

## 9. Affinity & rarity visual language

**Affinity (from the core) tints the build's glow hue** - base soul-glow is warm amber-gold `#FFB347`; the affinity shifts it: **attack** ember-rust `#C05A3E`, **defense** slate-blue `#5A7A9A`, **mana** flux-teal `#3FA890`.

**Rarity is carried by frame MATERIAL first, a rune-light accent second, foil NEVER.** The frame material is the warm anti-foil read AND doubles as the Coffer-tier language: **COMMON** worn tin (no rim), **RARE** brass + a cool **cobalt** rune-rim, **EPIC** runed-wood-and-gold + an **amethyst** rune-rim with gold flecks. The cobalt/amethyst give the instant "how lucky was this" read (the learned convention, rendered as *magic* not shine); the material keeps it handmade. **Never color-only:** rarity = material + rune-rim shape + slot glyph + label; valid/invalid = size + icon (glow-ring vs ⊘) + SFX + haptic; deltas = ▲▼ + ± + number; overweight = hatch + STRAIN icon + text.

**Damaged read (surfaces §13.5's "banked damaged build stays damaged"):** `current_hp < max_hp` → a crack/scorch decal + the glow **dims and flickers**, a small crack icon on the tray card, a crack decal on the 3D toy. **Precision note for the dev:** a damaged part with `hp > 0` is **not** `disabled`, so `active_parts()`/`derived()` still count its **full** stats - the damage read is a durability/fragility warning, *not* a stat penalty, until HP hits 0 (at which point the part is disabled and drops out of `derived()`). M0 opens parts at full HP; prove the damaged render by loading a pre-damaged banked fixture.

---

## 10. Build legality gate (§13.2 invariant, as a maker's care not a red error)

**[BANK MANABIT]** is disabled with an **explicit warm text reason**, never a silent grey-out, wired to `is_deployable()`:
- No core → *"Every Manabit needs a soul - bind a mana core."*
- Core but no offensive part (no non-CORE part with `ability.archetype != "GUARD"`) → *"You won't send a creation out with nothing to swing - bind a weapon."*

This enforces the frozen §13.2 invariant (live core **and** `has_offensive_move()`), guaranteeing every banked build is legal so the deferred combat lane's survivable-loss forfeit path can never dead-end - and it teaches the two hard rules diegetically.

---

## 11. How it binds to §13 (the contract table - the staff-engineer checklist)

| Builder element | §13 binding |
|---|---|
| Inventory | `Array[PartInstance]` (owned parts); equip **moves** the instance into `ManabitState.slots[slot]` |
| Stat bars / deltas | read `bit.derived()` only; deltas via `preview_derived_with(pi, slot)` = temp-swap → frozen `derived()` → swap back (non-mutating) |
| The Balance | `WEIGHT_BUDGET = 100`, `OVERWEIGHT_SPD_COST = 1`; penalty `(weight−100)×cost`; SPD clamps `maxi(1, …)` |
| Castability | `derived().energy` pool, `MANA_REGEN_PER_TURN = 2`, per-move `ability.mana_cost` |
| Kit summary / archetype | `active_parts()` → each `pi.data.ability.archetype` (SINGLE/MULTI/GUARD) |
| Slot-fit | ARM_L/ARM_R accept any `ARM_*`; CORE accepts only `is_core`; else exact |
| Bank gate | `is_deployable()` = `core()` alive **and** `has_offensive_move()` (§13.2) |
| Damaged card | `pi.current_hp < pi.data.max_hp`; disabled (stats drop) only at `current_hp == 0` |
| Affinity glow | `core.data.affinity` ∈ `{attack, defense, mana}` |
| Coffer parts | full-HP `PartInstance`s; Coffers never yield `is_core` parts |
| Save | §13.5 JSON - `{version, artificer, garage:[{core_id, parts:[{id, current_hp}]}], scrap, run}`, key `garage` untouched |
| Gate test | `res://tests/smoke_builder.gd` mirroring §13.7 (below) |

**Headless smoke test (`res://tests/smoke_builder.gd`, must be green before fan-out, re-run after every merge - do not trust a lane's "green"):** (1) slot-fit - ARM fits L and R, HEAD rejected from CORE, core rejected from ARM; (2) derived binding matches expected aggregate incl. the overweight penalty (reuse §13 numbers); (3) **projection non-mutation** - `preview_derived_with` returns projected stats AND leaves `bit.slots` unchanged; (4) **displacement conservation** - equip A→ARM_R then B→ARM_R leaves A back in inventory, total `PartInstance` count constant; (5) **deployability** - core + GUARD-only arm is NOT deployable, adding a SINGLE arm flips it; (6) **pack roll** - N instances at full HP, honors the ≥RARE floor, deterministic per seed; (7) **save/reload** - bank inventory+garage to §13.5 JSON and reload, ids + `current_hp` roundtrip incl. the pre-damaged part. Prints `SMOKE PASS`, exit 0.

---

## 12. Onboarding (no text wall - the object sequence teaches the loop)

1. Empty Workbench, an **inert un-cored** armature on the Stand, one glowing **Tin Coffer** in the Nook - single diegetic prompt "Press the seal to wake it." → forced first Waking teaches the ritual.
2. The **first Coffer is rigged** to the Apprentice's Kit's complete COMMON starter, so the tutorial always ends in a legal, bankable bit.
3. **CORE-first guided equip:** the CORE socket pulses hardest ("Every Manabit needs a soul"). Mounting the core **wakes the bit** - the big juice payoff, tied to the core=soul fiction, and it satisfies the invariant early.
4. Remaining sockets reveal one-by-one with glyph + name as they light. Coach-marks only on the *first* of each interaction: first drag, first swap, first overweight. Explicitly teach **drop-on-bit magnet** ("Toss a part at your Manabit - it finds its socket") and **tap-to-equip** ("or tap a part, then tap a socket").
5. End: a full, named bit → **"Your first Manabit lives"** → unlock Pose + Frame + the Menagerie. Emotional arc = dead scrap → your living named toy.
6. **Progressive disclosure:** Compare / sort / filter / Menagerie / Compendium hidden until after the first build; the Balance surfaces only when a part first approaches/exceeds 100, with a one-time Overload teach.

---

## 13. Accessibility & platform baseline (not optional)

- **No color-only signals** (shape + material + icon + label + SFX + haptic everywhere); palette skews warm amber/teal/cream, avoiding red/green as a sole signal.
- **Thumb-reach (landscape):** Wake-Coffer, tray, tap targets, and BANK live in the bottom ~60% + corners; magnet-drop + tap-auto-route mean no critical action needs the extreme top corners. The dragged card rides **above** the finger (no occlusion). Min interactive target **48dp**; SlotPlates **88px**.
- **Readable at mobile res:** UI is native-res (only the bit is low-res PS1). Stat numbers on solid plates, ~20-28sp; body ~16sp; cards legible at ~90px.
- **Motor:** full tap-only path, generous magnet drop-tolerance, forgiving fly-back cancel, no timers.
- **Reduce-motion** toggle damps vertex-jitter, pack-open flash/particles, and tumble; the seal-crack flash stays under the photosensitivity threshold regardless.
- **Dual-input verified:** the golden path (Wake → build → name → bank) works with mouse on PC **and** touch on mobile (native drag + tap-place) before the builder is "done."

---

## 14. What's placeholder vs invest in M0 (the fun lives in the feedback layer)

**Invest (this IS the fun - cannot be programmer-temp):** the composite **snap SFX** (plastic-click + brass-ding + shimmer), the **Waking SFX set** (ratchet, rune-ignite whoosh, wax-crack, spring-open, chimes), the **rarity SFX** (wood-tok / glass-chime / bell+choral), **SnapFX** + **RarityBurst** VFX (esp. EPIC), the **core-wake** animation + glow, the **strain** Balance+pose, the **mana-glow emissive material**, the teal-felt + warm-lamp lighting, and the live `derived()` delta/Balance readouts.

**Placeholder (temp, still readable):** part **meshes** = 6-10 primitive box/cylinder/capsule stand-ins per slot with the etched-plastic material + one glyph, tinted by rarity, instanced at the `Marker3D` sockets; thumbnails rendered from those; the bench/backdrop (simple vertex-colored); the Coffer mesh (plain brass box); 2 poses; the Menagerie shelf (flat tiles); one warm music loop; a small name word-bank.

*Principle: a cube with the right glow, snap, and sound beats a beautiful mesh that plops in silently - M0 budget goes into juice systems + the signature material, not geometry. The full PS1 shader stack (vertex-jitter, affine warp) is Lane E, deferred.*

---

## 15. Deferred (named, out of M0)

Combat, run-map, economy faucets/Reforge/Attunement/full shop, the overworld + Artificer avatar customization, procedural meshes, the vertex-jitter/affine PS1 shaders, the 5-axis radar, Commissions, spare-heart cores in Coffers, fusion. All can bolt on without changing the builder's frozen bindings.

