# DESIGN.md - MANABIT Workshop (Builder) - seed

> Author tokens/components here **before** any one-off styling in `.tscn`/scenes. If a token or component you need isn't here, add it here first. Every interactive component ships all its **applicable** states (default / hover / active / focus / selected / disabled / loading / empty / error / success) before it is "done."
> The 3D Manabit renders in a low-res SubViewport; **all chrome below is native-res** and must stay crisp on mobile.

## 1. Color tokens

**Room / surfaces (cozy-craft, warm - never crushed black / clinical white):**
| Token | Hex | Use |
|---|---|---|
| `--bench-walnut` | `#6B4A2F` (hi `#8A6440`, lo `#3E2A1A`) | workbench surface; vignette is dark walnut, never black |
| `--panel-fill` | `#3A2E24` | Ledger / tray panel backing |
| `--panel-deep` | `#2A211B` | deepest recessed panel |
| `--felt-teal` | `#2C4A44` | the Stand felt mat (makes amber parts pop) |
| `--brass` | `#B08D57` (hi `#E8C87E`) | sockets, gauges, nameplates, frames |
| `--brass-hi` | `#E8C87E` | warm-lit / active brass - selection warmth, lit medallions, selected-chip borders (`Tokens.BRASS_HI`; promoted to a first-class token 2026-07-18) |
| `--lamp-key` | `#FFD9A0` | warm key-light color of the whole room |
| `--parchment` | `#EAD9B0` | Ledger spec-sheet text ground |

**Mana-glow (signature - always sourced from a socket/seam/core/glyph):**
| Token | Hex | Use |
|---|---|---|
| `--glow-base` | `#FFB347` → core `#FFC24D` | base warm soul-glow (amber/honey) |
| `--affinity-attack` | `#C05A3E` | ember-rust - attack-core glow tint |
| `--affinity-defense` | `#5A7A9A` | slate-blue - defense-core glow tint |
| `--affinity-mana` | `#3FA890` | flux-teal - mana-core glow tint |
| `--affinity-*-text` | atk `#F0906A` / def `#8FB4D9` / mana `#6FD0B8` | text-tier variants (>=4.5:1 on `--panel-deep`) for core damage numbers + combat chips; `Tokens.affinity_text(a)` |

**Rarity (material frame + rune-light accent; NEVER foil-shine; NEVER color-only):**
| Rarity | Frame material | Rune accent |
|---|---|---|
| COMMON | worn tin `#AEB6B8` | none |
| RARE | brass `#B08D57` | cobalt `#4A90D9` |
| EPIC | runed-wood/gold `#C9A24E` | amethyst `#B857C9` + gold flecks |

**Stat readouts (drive every delta number, bar & gauge):**
| Token | Hex |
|---|---|
| `--stat-atk` | `#D9663E` |
| `--stat-def` | `#5A8FBF` |
| `--stat-spd` | `#6FCF97` |
| `--stat-weight` | `#D9A441` → overweight `#E8503A` |
| `--stat-energy` | `#3FD0C0` |
| `--delta-pos` | `#7FC96B` |
| `--delta-neg` | `#E8503A` |
| `--valid` | `#86D98F` |
| `--invalid` | `#E0673F` |

**Slot-family pastels (socket-family category tints - added 2026-07-18, Workshop reskin move 8):**
Muted pastels for bit-card title strips and family accents. They sit on the warm parchment/walnut ground - never candy-bright, never color-alone (always ride the slot glyph) - and carry dark walnut (`#3E2A1A`) text (all five checked >=4.5:1). ARM_L/ARM_R share the Arms pastel. Access via `Tokens.slot_family(slot)`.
| Token | Hex | Family |
|---|---|---|
| `--slot-head` | `#C9938A` | Head - dusty rose |
| `--slot-core` | `#A893B8` | Core - heather lilac |
| `--slot-arms` | `#9CB08C` | Arms - sage |
| `--slot-legs` | `#C4A76F` | Legs - warm sand |
| `--slot-back` | `#8CA3B8` | Back - dusty harbor blue |

## 2. Type
- **UI is native-res** (only the bit is PS1). Roles, not fonts (dev picks): a warm humanist/hand-lettered **display** for headers & the nameplate; a clean legible **sans** for stat numbers.
- **Display face (chosen 2026-07-16): Baloo 2** (`res://art/fonts/Baloo2.ttf`, OFL license alongside) - chunky, warm, rounded; reads "collectible toy box" and stays legible at header sizes. Apply via `Tokens.display(control, size)`. Stat numbers stay on the default sans.
- Sizes: stat numbers **20-28sp**, body **~16sp**; PartCard legible at **~90px**. High contrast on solid plates.

## 3. Spacing & targets
- Min interactive target **48dp**. SlotPlate hex **88px** (thumb-friendly). Critical actions (Wake, tray, Bank) in the bottom ~60% + corners; dragged card rides **above** the finger.
- Card grid gutter 8px; panel padding 12-16px.

## 4. Motion
| Token | Value | Use |
|---|---|---|
| `--snap-pop` | 120ms BACK-out | slot seat overshoot (squash 0.85/1.15 → 1.0) |
| `--delta-roll` | 150-250ms ease-out | stat number odometer commit |
| `--socket-flare` | 200ms | socket mana-glow flare on seat |
| `--reject-shake` | 150ms | invalid drop shake + fly-back |
| `--card-lift` | 90ms, +4px | hover lift |
| `--charge-ring` | ~800ms | Coffer press-hold channel fill |
| `--epic-hold` | 600ms + rune-ring | EPIC reveal beat |
| `--drag-spin` | 0.45 deg/px, inertia decay exp(-3.2t) | Stand drag-to-rotate (NO idle auto-rotate - owner rule) |
| `--drawer-slide` | 180ms ease-out | Workshop drawer open/close slide on the well's min-height; reduce-motion = instant |
| `--tag-untie` | 400ms | Work-Order Tag untie-and-slide-off on the first bind - plays once, never returns |
| `--ink-wipe` | 250ms | Work-Order Tag re-ink between states; reduce-motion = hard swap |
| `--invite-breath` | 2s loop | SlotField invite ring (GLOW_BASE 0.25-0.45) + dormant cavity-rim heartbeat (0.15-0.30), shared engine-clock phase; reduce-motion = static ring |
- **Reduce-motion** toggle damps jitter, pack flash/particles, tumble; seal-crack flash always under photosensitivity threshold.

## 5. SFX seams (named, via `AudioManager.play(&"…")` - cozy-craft only)
`seal_channel` (rising ratchet+hum) · `seal_crack` (warm chime-snap) · `gear_tick` (×3) · `lid_spring` · `reveal_common` (wood-tok) · `reveal_rare` (glass chime) · `reveal_epic` (deep bell + choral) · `new_stamp` (ka-chunk) · **`snap`** (plastic-click + brass-ding + mana-shimmer - the hero sound, pitch↑ with rarity) · `equip_whoosh` · `invalid_clunk` · `core_wake` (warm chord) · `strain_creak` · `christen_chime` · `bound_chord` · `ambience_workshop` (loop). **Banned:** foil/plastic crinkle, casino chimes, harsh electronic beeps.

## 6. Core reusable components

### `PartCard` (tray card + pack-reveal card)
140×180. Face: mini-mesh/icon, display name, **slot glyph** (corner), **rarity frame material + rune-rim**, headline stat + weight, archetype icon (S/M/G), NEW ribbon.
**States:** default (faint rune shimmer) · hover (lift 4px + quick-stat pip) · dragging-source (40% dim, dashed-brass ghost left behind) · selected (tap-place ring) · equipped-elsewhere (dim + check) · NEW · **damaged** (`current_hp<max_hp` → cracked frame + HP pip `12/20`; `==0`/disabled → heavy crack + greyscale) · disabled/incompatible (during a slot-selected state, ~40% desat).

### `SlotField` (hex SocketPlate, anchored to a body region)
Bound to a `Marker3D` socket via a mana-thread leader line. ≥88px target. `@export slot_name`.
**States:** empty (breathing ghost-socket silhouette + slot glyph; amber **!** "needed" pip if it blocks Bank) · drag-eligible (fitting plates pulse green + spin; non-fitting dim ~40% desat) · valid-hover (bright ring + 2-3 mana-arcs + ghost part on mesh, 1.05 scale) · invalid-hover (⊘ barred, grey/broken ring, recoil, double-buzz) · swap-preview (⇄, old part "will-return" fade, net deltas) · filled (mesh + name chip + 3 stat pips + rarity rim + HP bar) · snap-success (120ms pop + flare) · reject (shake + dull SFX) · selected (tap-place) · **invite** (calm spec: keeps the pip + a slow GLOW_BASE ring `--invite-breath`, NEVER BRASS_HI - anti-casino; at most ONE invited medallion, workshop-owned, suppressed during drag/inspect/overlay; reduce-motion = static ring at 0.35). ARM_L/ARM_R accept any `ARM_*`; CORE accepts only `is_core`.

### `StatDeltaRow` (one Ledger stat line)
Label · current value · bar · projected delta. **States:** static (committed value) · projecting (`current → projected (±N)`, colored `--delta-pos`/`--delta-neg`, ▲▼ + number) · roll-commit (odometer 150-250ms, flash color once). Reads `bit.derived()` / `preview_derived_with()` only - **no stat math in the widget.**

### `WeightMeter` - "the Balance" (brass balance-beam)
0→`WEIGHT_BUDGET(100)` fill + budget line. **States:** under-budget (level, green, "0 SPD penalty") · at-line · **overweight** (beam tips, overflow segment hatches amber→red, STRAIN tag, inline `SPD x → y (−N)` where `N=(weight−100)×OVERWEIGHT_SPD_COST`) · projecting (ghost fill on hover, pre-glows red past 100). Never blocks banking.

### `PackOpen` - the Coffer / the Waking (full-screen overlay `CacheCoffer`)
**States:** hidden · idle/rest (Coffer bobs, sleep-rune breathes, bench dims 15%) · channel (press-hold radial charge-ring ~800ms + rising ratchet + ramping haptic) · crack (bounded flash + snap-haptic + iris/lid spring) · rise (parts hover grey/dormant) · waking (per-part ascending-rarity kindle: common motes / RARE cobalt ring+rim / EPIC amethyst shockwave+gold+bell+banner; each tappable to wake early; **[Rake it in]** skip) · land (cards clack into tray + NEW stamp + "Compendium +N%"). Driven by a scripted Tween over a **real seedable `PackRoller`** result (≥RARE floor, visible epic-pity, odds printed on the Coffer face).

### `TrayToolbar` - filter/sort bar above the Salvage Tray (added 2026-07-17)
One ~34px row: title+count (`YOUR BITS · N`; filtered → `◉ HEAD · 4 of 34`) · slot chips `[All][◉ Head][❖ Core][✦ Arms][▟ Legs][▚ Back]` (ARMS combined; ≥48dp incl. padding) · spacer · Rarity dropdown (Any/Common/Rare/Epic) · Sort dropdown (**Newest** default / Rarity / Weight / Attack / Name).
**Rules:** chips + socket-taps share ONE filter state (single source of truth); filter predicate = `BuildSession.slot_accepts` (never a parallel rule); filters AND together; sort operates on a **copy**, never the live inventory; state persists across tray rebuilds (equip/unequip must not reset the view).
**Chip states:** default (dim brass border) · hover · **selected** (pressed, `--brass-hi` border + warm fill) · disabled (kit-locked tray).
**States:** default/all · filtered (count title + lit chip) · empty-result (warm parchment note in-tray, never blank: "No bits match this filter") · no-bits (bare-bench note; toolbar stays visible).

### `InventoryGrid` - the Salvage Tray (two-state drawer, calm spec 2026-07-18)
Felt-lined bottom drawer, now real two-state furniture: ONE assembly (50px walnut LIP over a 166px felt WELL, internal separation 0) replacing the old toolbar row + tray panel. Binary machine, no half-peek third state:
- **CLOSED** (rest default, fulfills the old "collapsed" state): lip only - walnut face on `sandwich("deep")` ground (felt is the lining, seen only open), DrawerChrome brackets + dovetail teeth, a drawn brass **bail handle** centered, parchment count tag `YOUR BITS · N` (honest TOTAL, never filtered) rotated -1 deg, paper `NEW ·N` stamp while unseen bits exist, up to 6 non-interactive card-top **spines** (10px rounded slivers, slot-family pastel + rarity-material edge, first 6 of the current sorted view). Whole lip = one >= 44px tap target. Lip states: default / hover (handle warms BRASS_HI, lifts 2px; reduce-motion kills the lift) / pressed (dips) / focus (ring, keyboard accept opens). Tooltip (PC nicety only): `Slide the drawer open - your bits live in here.`
- **OPEN** (work): the lip becomes the toolbar - title, 6 file-tab chips, rarity + sort dropdowns, plus a 44px brass tuck chevron (`Tuck the drawer away.`); the 166px well below is the tray unchanged. Implementation rule: `_lip_closed` / `_lip_open` are siblings toggled by visibility - no control reparents at runtime.
- **Opens on:** lip tap · any socket-medallion tap (existing tap contract runs EXACTLY, drawer ensures visibility first) · Wake-return with new bits (auto) · Binding success (auto, filtered CORE) · keyboard/gamepad accept · `_focus_slot_in_tray()`. Entry-time auto-opens beat the enter-closed default; open state is never persisted.
- **Closes on:** tuck chevron · open-lip background tap · tap-away on stage/wall (guarded: no drag in flight, <= 6px press-release travel; with a tap-place selection active the first tap-away only cancels it) · BIND success (self-tuck) · leaving the screen. **NEVER closes on** equip / unequip / filter / sort / drag-end. Closing clears any live selection.
- Filter state persists across open/close; the closed tag always shows the honest total; an active filter re-presents via the open title before the slide finishes.
Slot-tab / auto-filter / sort / empty rules unchanged from TrayToolbar. Dupes stack **only when identical id AND full HP** (×N badge, long-press to fan out); any damaged instance shows **separately** with its HP pip - never hidden.

### `WorkOrderTag` - the one teaching voice (calm spec 2026-07-18)
A parchment swing-tag ~200x64, `sandwich("parchment")`, one brass rivet, drawn 2px twine to the stand's brass rim; anchored bottom-left inside the stage area, clear of the CORE medallion and plinth. Two lines: story (display 14sp, walnut ink) + underlined action (13sp, ink-link register on parchment). Whole tag one >= 44px `MOUSE_FILTER_STOP` target.
**Existence:** only while `PlayerState.binds_total == 0` AND no overlay (Binding / box reveal / inspect) AND no drag (120ms fades around those). First bind: `--tag-untie`, gone forever - no veteran ever sees it.
**States T1-T6** (first match wins, one alive, derived from live save/build state): T1 asleep/seat-a-core (spare core owned) · T2 bind-a-core ⚙60 · T3 wake-a-coffer · T4 crack-the-box · T5 give-it-an-arm · T6 press-the-seal (600ms BIND-plate sheen, once per entry - the tag never binds for you). Re-ink between states = `--ink-wipe`.
**One-voice rule:** while the tag lives, the status note's two JOURNEY lines (no-core, no-weapon) suppress to empty; every TRANSACTIONAL line stays. **Invites:** the workshop holds at-most-ONE SlotField invite (T1/T2 -> CORE + cavity heartbeat, T5 -> ARM_L), suppressed with the tag.

**Workshop calm rules (2026-07-18):** the Ledger + Balance panel is visible iff (any bit seated) OR (drawer open) - fades in 160ms; over an empty build its verdict reads `Nothing on the stand yet.` with the archetype line hidden (numbers stay honest). The anatomy inset is work-mode chrome (drawer open OR drag/tap-place in flight); its foot carries the two permanent 9sp etched manual print lines: `tap a socket - see what fits` / `hold a bit - read its tag`. The nameplate renders as an engraved brass label until tapped, then swaps to the focused LineEdit. Stage dormant dressing while no core is seated: ember-dimmed lamp (~0.55 key), soul off, chest cavity facing camera at rest yaw, half-amplitude 3s sleep breath, cavity-rim heartbeat only during tag T1/T2 (`stage.set_dormant_pulse`).

### Supporting components (spec before use)
- **`ManabitStage`** - SubViewport(320×240, NEAREST) → TextureRect under the UI; turntable drag + idle-spin; limb assemble/disassemble; **core-wake** (inert/dark → breathing idle); strain-pose; damaged crack decals; empty-slot wireframe ghosts.
- **`NamePlate`** - LineEdit + reroll die + engrave animation; states: empty (auto-default) / editing / christened (lit glyphs + chime).
- **`RarityBurst` VFX** - 3 tiers (motes / cobalt ring+rim / amethyst shockwave+bloom+banner).
- **`SnapFX`** - spark-ring + light-pop + shock-ring decal + squash controller (fires on every seat).
- **`Toast/Banner`** - EPIC! / NEW! / BOUND! / warm "bind a weapon" gate message (never a red error).
- **`ArchetypeBadge`** - Bruiser/Skirmisher/Bulwark/Battery/Glass/All-rounder from thresholds + kit (NOT a power score).


## 7. The Barrow / Fettle's Cart (economy - added 2026-07-13)
- **Currency colors:** Scrap = `--brass-hi` `#E8C87E` (⚙); Glimmer = `--stat-energy` teal `#3FD0C0` (✦) - deliberately NOT amber, so it never reads as Scrap. New token `--wax-seal` `#B4472E` (the SOLD stamp only).
- **Motion:** `--stamp-thunk` 120ms - wax SOLD stamp scales 1.4→1.0 with a small rotate, a single thunk (no strobe).
- **SFX seams (wired silent, cozy-craft only - never casino):** `ledger_open` · `coin_scrap` (soft filings up/down) · `still_drip` (Glimmer) · `forge_melt` · `wax_stamp` (SOLD) · `doorstep_untie` · `fettle_greet` / `fettle_appraise` / `fettle_apologise`.
- **Components:** `FettlePortrait` (drawn automaton: cabinet body + glowing forge-belly + loupe-eye + wind-up key) · `BarkRibbon` (parchment line of Fettle's patter) · `CurrencyChip` (⚙/✦ + count) · `CofferWare` (sealed coffer + odds line + rune price-tag + BUY; buying shows NO reveal) · `FindCard` (a discovered bit + price in its currency + BUY / SOLD stamp) · `SalvageBit` (loose bit + Melt/Still buttons; cores locked) · `DoorstepCoffer` (free daily Tin claim / "back tomorrow").

## 8. The Run - RouteBed and the Junction (branching map, added 2026-07-18)

**Motion tokens:**
| Token | Value | Use |
|---|---|---|
| `--switch-throw` | 180ms | junction commit - the switch needle throws, the unchosen lane snaps to bypassed |
| `--route-glow-crawl` | 300ms | traveled-rail glow crawl to the next chip on advance |
| `--chip-breath` | ~2s loop | current-chip idle breath (reuses `--snap-pop`, `--card-lift`; off under reduce-motion) |

**SFX seams (wired silent, cozy-craft only):** `switch_throw` (heavy brass lever + rail clunk) · `route_step` (footfall + satchel jingle on advance) · `fork_reveal` (soft double-chime when the fork panel opens).

### `RouteBed` (replaces the bare map row in the Run screen)
Full-width strip, FIXED height 108px in all states (no layout jump). PANEL_DEEP fill, 2px BRASS 0.4 border, radius 8. Five columns of 150px chips (5 x 150 + 4 x 8 = 782px). A custom draw pass under the chips draws the brass rail: 3px BRASS 0.5 through chip centers, S-curve split at junction columns with a 20px `SwitchPoint` Y-glyph; traveled segments overdraw 5px GLOW_BASE 0.6. Chips are NOT interactive (mouse-ignore) - all decisions live in the action panel. Run-over banked: glow stays warm. Run-over death: 400ms glow fade (instant under reduce-motion).

### `RouteChip` (one map step in the bed)
150px wide. Normal chip: mark + node glyph + label, 12sp. Junction columns render as a 2-row stack of two 44px lane chips (row gap 8) until chosen: each lane chip = 10sp letterspaced modifier strap (glyph + name, BRASS_HI - checked 9.8:1 on PANEL_DEEP, passes 4.5:1; PARCHMENT fallback pre-declared but not needed) over the normal node line. **States:** upcoming (dim) · current (brass border, LAMP_KEY, `CoreLightMarker`) · done (check) · selected-preview (BRASS_HI border while its PathCard is selected) · bypassed/ghost (road_not_taken at 0.15 alpha, forever - honest history).

### `SwitchPoint`
20px Y-glyph drawn where the rail splits: brass hub dot + a 20px BRASS_HI needle. Needle tilts toward the previewed lane while choosing; throws on commit (`--switch-throw`).

### `CoreLightMarker`
Small glow dot on the CURRENT chip, colored from the carried core's affinity (`Tokens.affinity_color`). Never color-alone - it rides the current chip's brass border + LAMP_KEY text.

### `PathCard` (junction action panel, 2 per fork)
356 x 120 min, PANEL_FILL, BRASS 0.5 border, radius 8, whole card one tap target (>= 44px). Top-to-bottom: lane name in display face 16sp LAMP_KEY; challenger row - 40px icon from `art/icons/<HEAD bit id>.png` (same asset path the Proving rows use) + challenger name 13sp; modifier line - name 13sp BRASS_HI + " - " + the exact rule text from `RunMods.TABLE` verbatim (max 38 chars, authoring-enforced) 12sp PARCHMENT 0.8; the existing core warning line verbatim (word and glyph in STAT_WEIGHT_OVER, never color alone); kit runs add footer "WIN: +N to your satchel" from the tier purse table (equal on both lanes by design). **States:** default · hover (lift) · selected (2px BRASS_HI border + strip-side rail preview) · pressed · focus.
Two-step commit (irreversible choice, no fat-finger locks): tap a card = selected + preview; full-width 48px brass primary button below - disabled "Pick a path first", enabled "Take this path"; on press `run.choose(i)` + refresh. The Fight button never exists pre-collapse.

### `ModifierBanner`
Pill in the Run top row between the title and Abandon while the current node carries a modifier: glyph + name + rule text, 12sp, PANEL_FILL fill, BRASS 0.6 border, height 26. Hidden on clean nodes. The rule is visible before (chip strap), at (PathCard), and after (banner) commit.

## 9. Material sandwich + color economy (Workshop reskin - added 2026-07-18)

**Material tokens (the shared recipe - one shadow direction, one radius, one seam):**
| Token | Value | Use |
|---|---|---|
| `--shadow-soft` | offset `0/3px`, `#3E2A1A` @ 40%, blur 6 | the ONE shared soft shadow under every container - dark walnut, never black; `Tokens.shadow_soft(sb)` / `Tokens.SHADOW_SOFT` |
| `--radius-card` | `10` | shared container corner radius; `Tokens.RADIUS_CARD` / `Tokens.card_radius(sb)` |
| `--stitch-detail` | `--parchment` @ 35%, 4px dash / 4px gap, inset 3px | hand-sewn seam rim on felt/parchment surfaces; `Tokens.draw_stitch(ci, a, b)` / `Tokens.draw_stitch_rect(ci, rect)` |

**RULE - the material sandwich (every container, no exceptions):** walnut frame + parchment-or-deep inset + at most ONE brass accent detail (a rivet, a clip, a stitched tab - the component's job, never the factory's) + `--shadow-soft`. Never hand-roll a container StyleBox - pull `Tokens.sandwich(kind)`:
| Kind | Frame (2px) | Inset fill | Use |
|---|---|---|---|
| `"parchment"` (default) | `--bench-walnut` | `--parchment` | spec cards, Ledger face, parchment chips |
| `"deep"` | walnut lo `#3E2A1A` | `--panel-deep` | recessed panels, tray backing, wells |
| `"brass"` | `--brass-hi` | `--brass` | stamped brass plate - the hero-action tier ONLY, one per screen |
| `"felt"` | `--bench-walnut` | `--felt-teal` | felt-lined wells - display-stand rim, drawer lining |

All kinds ship `--radius-card` corners, 12px content margins (section 3 panel padding), and `--shadow-soft` pre-applied.

**RULE - semantic color economy (locked 2026-07-18, Workshop reskin move 13):**
- **One hue never means two things.** The locks: **ember = ATK** (`--stat-atk`, `--affinity-attack` family) - **slate = DEF** (`--stat-def`, `--affinity-defense` family) - **leaf = SPD** (`--stat-spd`) - **teal = mana / Glimmer** (`--stat-energy`, `--affinity-mana`) - **brass-gold = selection + celebration ONLY** (`--brass-hi`, `--glow-base`): never ambient on every panel (the anti-casino guard).
- The delta pair is the one sanctioned directional reuse (move 5 grammar): `--delta-pos` leaf = up / better, `--delta-neg` ember = down / worse - warm register only.
- Saturation is reserved for the toy and celebration moments; chrome stays on the warm neutral ground (walnut / parchment / felt).
- **Letter-code stat strings are BANNED project-wide** (`A1 D2 S1`, `ATK 4 - WT 26 - MULTI`): every stat everywhere renders as icon + colored capsule (brass-pip lozenge / corner blob) in its locked hue. The ban is on the abbreviation soup, never the numbers - the honest math (strain, `SPD x -> y (-N)`, capacity, prices) is untouchable.
- Slot-family pastels are category tints, not meanings: light pastel register only, always with the slot glyph, never carrying stat semantics.
