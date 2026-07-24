# Workshop Calm + Onboarding - the resting bench and the first bind

STATUS: TEAM-RATIFIED (producer-synthesis) 2026-07-18 - implementing

Producer synthesis of the two 2026-07-18 design lanes (Workshop onboarding / calm-screen
tray architecture), responding to the owner playtest: (1) the blank preview teaches nothing,
(2) the inventory should not be instantly open at the bottom, (3) the resting screen is too
busy - the toy should be the hero. Supersedes nothing in `workshop-style-direction.md`;
this is additive on top of the shipped reskin. NO em or en dashes anywhere - hyphens only.

---

## 0. The three fixes, in one breath

- **The drawer becomes real furniture.** The bit tray + its toolbar collapse into ONE
  two-state drawer assembly: CLOSED (rest default, a 50px walnut lip with a brass handle,
  a count tag, and card spines peeking out) / OPEN (the lip becomes the toolbar, the
  166px felt well below is today's tray byte-for-byte). At rest the stage gains 166px.
- **The Work-Order Tag is the single teaching voice.** A parchment swing-tag hung on the
  stand's brass rim, alive only until the player's first bind (`binds_total == 0`),
  walking T1 -> T6 from "seat a core" to "press the seal", each state derived purely from
  live save/build state. It unties and slides away forever on the first BOUND! and no
  veteran ever sees it.
- **The husk becomes a sleeping toy.** Ember-dimmed lamp, soul light off, the dark chest
  cavity facing camera at rest yaw, a slow half-amplitude sleep breath, and a shared
  amber heartbeat between the cavity rim and the invited CORE medallion. It reads
  "asleep, waiting for a soul" instead of "unloaded asset".

At-rest census after this change: top nav 44 / full-hero stage with medallions (+ the tag
while it lives) / bank row 44 (BIND plate + ink links + note - the screen's exits and its
one transactional voice) / closed drawer lip 50. Warmth props + watermark in the margins.
Toolbar, tray well, anatomy inset, and (on an empty bench) the Ledger appear only in work
mode. The empty-rest screen is deliberately spacious; the tag is what fills it with meaning.

---

## 1. Row budget (re-ratified - sums <= 720, ONE expander)

Root VBox unchanged: offsets left 16 / right -16 / top 6 / bottom -6, separation 6.
The toolbar row and tray panel are REPLACED by one drawer assembly (internal separation 0),
so the root goes from 5 rows to 4 (3 separations = 18px).

| Row | Old | New CLOSED | New OPEN |
|---|---|---|---|
| top | 44 | 44 | 44 |
| stage (the ONE expander) | min 380 (renders 386) | min 380 (renders **552**) | min 380 (renders **386**) |
| bank | 44 | 44 | 44 |
| toolbar | 44 | - (merged into drawer) | - |
| tray / drawer | 166 | **50** (lip only) | **216** (50 lip + 166 well, separation 0) |
| separations | 4 x 6 = 24 | 3 x 6 = 18 | 3 x 6 = 18 |
| **root min stack** | **702** | **536** | **702** |

- Render math at 720 (708 inside offsets): closed 708 - (44+44+50+18) = 552 stage;
  open 708 - (44+44+216+18) = 386 stage. Stage never dips below its 380 min.
- The OPEN min stack is exactly today's 702, so the existing `<= 704` pin survives; the
  gate must now assert BOTH configurations (section 8).
- The FOV-50 auto-framing camera makes the reclaimed 166px pure toy - no camera work.

---

## 2. The Drawer (calm lane) - two-state furniture

One `PanelContainer` (`_drawer`) replacing today's separate `_toolbar_row` + tray panel in
`ui/workshop.gd`: a 50px LIP on top of a 166px felt WELL, internal separation 0 (one piece
of furniture - the felt runs up under the lip). Binary state machine: **CLOSED** (rest
default) / **OPEN** (work). No third half-peek state - the spine peek is a rendering of
CLOSED, keeping the machine two-state.

### 2.1 CLOSED lip anatomy (50px, always the bottom row)

- Walnut drawer face on `Tokens.sandwich("deep")` - never felt (felt is the lining you
  only see when open). DrawerChrome brackets + dovetail teeth along the top edge.
- A drawn brass **bail handle** centered. The WHOLE lip is one >= 44px tap target.
- Parchment **count tag** at the left, rotated -1 deg: `YOUR BITS · 8` (honest TOTAL,
  never the filtered count). Zero bits owned: `YOUR BITS · 0`, no spines.
- Up to 6 non-interactive card-top **spines**: 10px rounded slivers in each bit's
  slot-family pastel with its rarity-material edge, first 6 of the current sorted view,
  peeking from behind the lip. The diegetic "there is treasure in here" cue.
- Paper `NEW ·N` stamp beside the tag when any bit carries the same NEW flag PartCard's
  ribbon reads; clears when that flag clears (state-derived, veteran-safe).
- Tooltip on the lip: `Slide the drawer open - your bits live in here.` (PC nicety only -
  the handle + spines are the affordance; nothing essential is hover-only).
- **Lip states:** default / hover (handle warms BRASS_HI, lifts 2px) / pressed (dips) /
  focus (ring; keyboard-gamepad accept opens). Reduce-motion kills the lift.

### 2.2 OPEN state

- The lip becomes the toolbar: the existing `_tray_title`, 6 file-tab chips, rarity and
  sort OptionButtons move onto the 50px lip (they already read as tabs on a drawer edge;
  now they literally are), plus a 44px brass **tuck chevron** at the far right (close
  affordance, tooltip `Tuck the drawer away.`).
- Implementation: the lip hosts two sibling containers, `_lip_closed` (handle + tag +
  spines) and `_lip_open` (toolbar contents + chevron); state toggles visibility. No
  control is reparented at runtime.
- The 166px well below is today's tray UNCHANGED: same PartCard grid, card tilt,
  BindCoreCard on the CORE filter, slim scroll indicator, warm empty notes.
- The TrayToolbar state machine, `slot_accepts` predicate, sort-on-a-copy, and filter
  persistence survive byte-for-byte - only their container moved.
- Slide: 180ms ease-out on the drawer's min-height; the stage reframes with it.
  Reduce-motion: instant show/hide, no tween.

### 2.3 Opening triggers

1. Lip / handle tap - opens, no filter change.
2. Any socket medallion tap - runs the existing tap contract EXACTLY (empty: set filter,
   again: clear; filled: unequip-then-focus) and ensures the drawer is open first, so the
   filter result is always visible. Tap-again-clear keeps the drawer open.
3. Returning from Wake Coffers with new bits - auto-opens, Newest sort puts them in front.
4. Binding success (from the tappable note or the BindCoreCard) - auto-opens filtered to
   CORE so the new core is the first card, one drag from the socket that needs it.
5. Keyboard / gamepad accept on the focused lip.
6. The Work-Order Tag's `_focus_slot_in_tray()` calls (section 3).

Precedence rule: entry-time auto-opens (trigger 3, 4) win over the enter-closed default.
Every other screen entry starts CLOSED - the rest state is never persisted open.

### 2.4 Closing triggers

1. Tuck chevron.
2. Tap on the open lip's background (not a chip / dropdown / tab / chevron).
3. Tap-away: a clean press-release on the stage or wall that is not a medallion, not the
   tag, not a drag-end, and not a stage-rotate. Guard: ignore any release while
   `gui_is_dragging()` or when the press-to-release travel exceeds 6px (rotation).
   A stationary click on the stage currently does nothing, so this input is free.
4. BIND success - the bench clears, the drawer tucks itself, the toy celebrates alone.
5. Leaving the screen (next entry starts CLOSED unless trigger 3/4 above fires).

**NEVER closes on:** equip, unequip, filter change, sort change, drag-end - building is
iterative. **Tap-place rule:** tap-away with a tap-place selection active first CANCELS
the selection; a second tap-away closes. Closing always clears any live selection.

### 2.5 Filter honesty across the lip

Filter state persists across open/close per the TrayToolbar rule. The closed tag always
shows the honest TOTAL (`YOUR BITS · 8`); any active filter re-presents on open via the
title (`◉ HEAD · 4 of 8`), rendered before the slide finishes so the count is never
momentarily wrong.

---

## 3. The Work-Order Tag (onboarding lane) - one teaching voice

A parchment swing-tag, about 200x64, `Tokens.sandwich("parchment")`, one brass rivet,
tied by a drawn 2px string to the stand's brass rim. Anchored bottom-left INSIDE
`_stage_area` - above StandFrame, below the inspect dim, clear of the medallion arc and
plinth (verify against the CORE medallion at the 560px minimum stage width; the smoke
gate asserts non-overlap). Two lines: a story line (display face 14sp, walnut ink) and an
underlined action line (13sp, ink-link register). The whole tag is one >= 44px tap target
with `MOUSE_FILTER_STOP` - its input never reaches the drag-rotate stage or the tap-away
close handler.

**Existence:** visible only while `player.binds_total == 0` (section 7) AND no overlay
(Binding panel, box reveal, inspect) is up AND no drag is in flight (120ms modulate fade
out/in around those). On the first bind it plays a 400ms untie-and-slide-off
(reduce-motion: instant hide) and never returns.

### 3.1 Tag state machine

Evaluated in `refresh_from_player`, first match wins, exactly ONE state alive. "Spare
core" = a bindable core sitting unequipped in `player.bits`.

| State | Condition | Story line | Action line | Tap does | Invite |
|---|---|---|---|---|---|
| T1 | build empty AND spare core owned | `This one's still asleep.` | `Seat a core` | `_focus_slot_in_tray("CORE")` via the existing `_on_slot_tapped("CORE")` path | CORE medallion |
| T2 | build empty, no spare core, scrap >= 60 | `A body needs a soul.` | `Bind a core - ⚙60` | `_toggle_binding_panel()` | CORE medallion |
| T3 | build empty, no spare core, scrap < 60, `coffer_count() > 0` | `Sleeping scrap waits.` | `Wake a Coffer` | `open_chests_requested.emit()` | none |
| T4 | build empty, no spare core, scrap < 60, no coffers | `A few filings short.` | `Crack the Box of Scrap` | `_open_box_reveal()` | none |
| T5 | core seated, no offensive move | `Awake, but empty-handed.` | `Give it an arm` | `_focus_slot_in_tray("ARMS")` (filter ARMS + open drawer) | ARM_L medallion |
| T6 | `session.is_deployable()` (still never bound) | `She's ready.` | `Press the seal` | one 600ms warm sheen on the BIND brass plate (celebration register, once per state entry) - the tag never binds for you | none (the sheen is the invite) |

State changes re-ink the tag with a 250ms ink-wipe (reduce-motion: hard swap).

### 3.2 The one-voice rule

While the tag is visible, `_refresh_bank` suppresses its two JOURNEY lines (no-core,
no-weapon) to empty - the tag carries them - and keeps every TRANSACTIONAL line
untouched: `Ready to bind (strained: SPD -N).`, `Ready to bind.`, BOUND!,
`deploy_block_reason` for anything the tag is not currently pointing at. After the first
bind the note resumes today's full contract verbatim. `_set_note` API, 72-char cap,
toast escalation, and tappable-note behavior are unchanged.

### 3.3 The drawer seam

Every teaching action that needs the drawer routes through ONE function:

```
_focus_slot_in_tray(chip_key)   # set filter + ensure drawer open + light medallion
```

The drawer owns open/close; the tag only calls the seam. (If the drawer were ever backed
out, the seam degrades to filter-only with zero design change.)

### 3.4 Gesture teaching, zero popups

- **Tap-socket-filter is taught by doing:** the T1 tag tap literally performs the socket
  tap - the player watches the medallion light and the drawer open filtered, cause and
  effect labeled once.
- **Drag is taught by the drawer:** when it opens on a slot filter DURING the tag era
  (`binds_total == 0` only - veterans never see it), the first fitting card plays one
  200ms lift-and-settle nudge, once per filter-open, skipped under reduce-motion. The
  medallion die-cut silhouette + the existing green eligibility pulse finish the sentence.
- **Permanent quiet reference:** two 9sp etched print lines at the foot of the anatomy
  inset - it is a gunpla manual, print belongs on it: `tap a socket - see what fits` /
  `hold a bit - read its tag`. Diegetic furniture, works on touch, and it is the ONLY
  teaching residue a veteran can ever see.
- Hold-to-bind stays taught inside the Binding overlay blurb, unchanged.

---

## 4. Stage dormant dressing (v1 scope)

While no core is seated (`ui/manabit_stage.gd`):

1. **Ember lamp:** key light dims to ~0.55 of `KEY_LIGHT_REST`; the lamp pool follows
   proportionally (reuse the `light_dim` ratio plumbing); soul light stays off. On core
   seat the existing core-wake glow fires and the lamp returns to full.
2. **Cavity faces camera:** the dark hex chest cavity (`_dormant_cavity`) faces the
   camera at rest yaw so the "waiting for a soul" read is unmissable. (Drag can still
   turn it - rest yaw is the default presentation.)
3. **Sleep breath:** half the awake bob amplitude on a 3s period (awake = 0.015 at 4s;
   sleep = 0.0075 at 3s). Reduce-motion: static, exactly as the awake bob already is.
4. **Heartbeat:** while tag T1/T2 is alive, the cavity rim pulses GLOW_BASE alpha
   0.15-0.30 on a 2s period, in phase with the CORE medallion invite ring. Implementation:
   both sample the same engine clock (`Time.get_ticks_msec()`), no sync bus. Nothing else
   on screen pulses.

New seam: `stage.set_dormant_pulse(on: bool)` - workshop-owned, on only for T1/T2.

**DEFERRED (cut from v1):** the five die-cut ghost limb wireframe frames at the mount
points. The medallion arc + eligibility pulses already carry the drag-target teaching;
ship the cheap set above first, revisit wireframes only if the fresh-eyes playtest still
reads the husk as a bug.

---

## 5. SlotField invite state (`ui/slot_field.gd`)

New `set_invite(on: bool)`: keeps the amber `!` pip and adds a slow GLOW_BASE ring breath
(alpha 0.25-0.45, 2s period, engine-clock phase; reduce-motion: static ring at 0.35).

- At most ONE medallion is invited at any time, chosen by the tag state (T1/T2 -> CORE,
  T5 -> ARM_L). The workshop owns this exclusivity - widgets are never trusted to
  self-coordinate.
- All invites are suppressed (with the tag) while a drag, inspect dim, Binding overlay,
  or box reveal is live.
- BRASS_HI stays selection-only per the anti-casino guard - the invite breath is
  GLOW_BASE, never brass.
- The existing needed-pip logic in `refresh_from_player` (lines 283-287) is untouched:
  veterans get pips without breath, forever.

---

## 6. Ledger, anatomy inset, nameplate (calm rules)

- **Ledger visibility:** the Ledger + Balance panel is visible iff (any bit is seated) OR
  (the drawer is open). Built toy at rest = the spec card stays beside the stand (the
  theorycraft pillar). Empty bench + closed drawer = no instruments; the stage takes the
  full mid-row width and the husk stops sitting in a cockpit of dead gauges. Fades in
  160ms when the first bit seats or the drawer opens (reduce-motion: instant). Hover
  preview always has a Ledger to project into, because hovering a card requires the open
  drawer.
- **Honest-quiet empty Ledger** (when visible with an empty build): the Balance verdict
  line reads `Nothing on the stand yet.` instead of `Rides light and lively`, and the
  archetype line hides. The 0/100 numbers stay - honest data untouched; only the cheerful
  verdict about nothing goes. (`ui/ledger.gd` `show_build`: empty-build branch keyed off
  zero seated bits.)
- **Anatomy inset = work-mode chrome:** visible only while the drawer is open OR a
  drag / tap-place is in flight - it is the drag legend, so it appears exactly when
  dragging is possible. Hidden at rest; the left rail is free for the tag. Its foot
  carries the two etched manual print lines (section 3.4).
- **Nameplate at rest:** the top-row LineEdit renders as an engraved brass nameplate
  label (display face, no input chrome) until tapped, then swaps to the focused LineEdit.
  Same 44px row, no budget change. Kills the one raw form field at rest.

---

## 7. Data + note contract changes

### 7.1 `binds_total` (PlayerState, additive on save v4)

New `var binds_total: int = 0`, incremented in `bank_manabit`. Persisted additively (kit
counter precedent). **Load migration:** if the field is absent in a loaded save, seed it
to `menagerie.size()` - existing veterans never see the tag; a veteran later wiped to
zero Manabits STILL never sees it (their `binds_total` is > 0). This kills the lane's
biggest risk for one int. The tag condition everywhere is `binds_total == 0`, never
`menagerie.is_empty()`.

### 7.2 Note-action enum + the spare-core fix (veteran path, tag gone)

Widen `_note_opens_binding: bool` into a small enum: `NOTE_ACT_NONE / NOTE_ACT_BINDING /
NOTE_ACT_FILTER_CORE`. The `core == null` branch of `_refresh_bank` first checks for a
spare bindable core in the tray:

- Spare core owned: `Seat a mana core to wake it - one waits in your drawer.` - tapping
  the note runs `_focus_slot_in_tray("CORE")` (filter CORE + open drawer).
- No spare core: today's line verbatim:
  `Seat a mana core to wake it - tap here to bind one (⚙60).` - tap opens the Binding.

This stops the note pointing a fresh player at spending ⚙60 they do not need to spend
while three starter cores sit in their drawer. Both lines <= 72 chars.

---

## 8. Copy table (complete - hyphens only, all new strings)

| Where | String |
|---|---|
| Tag T1 | `This one's still asleep.` / `Seat a core` |
| Tag T2 | `A body needs a soul.` / `Bind a core - ⚙60` |
| Tag T3 | `Sleeping scrap waits.` / `Wake a Coffer` |
| Tag T4 | `A few filings short.` / `Crack the Box of Scrap` |
| Tag T5 | `Awake, but empty-handed.` / `Give it an arm` |
| Tag T6 | `She's ready.` / `Press the seal` |
| Note (no core, spare owned) | `Seat a mana core to wake it - one waits in your drawer.` |
| Note (no core, none owned) | `Seat a mana core to wake it - tap here to bind one (⚙60).` (unchanged) |
| Ledger empty verdict | `Nothing on the stand yet.` |
| Anatomy manual line 1 | `tap a socket - see what fits` |
| Anatomy manual line 2 | `hold a bit - read its tag` |
| Closed lip tag | `YOUR BITS · 8` / `YOUR BITS · 0` |
| Closed lip NEW stamp | `NEW ·3` |
| Lip tooltip (closed) | `Slide the drawer open - your bits live in here.` |
| Tuck chevron tooltip | `Tuck the drawer away.` |

Existing tray strings survive unchanged: `Your bench is bare. Wake a Coffer to find some
bits.` / `No bits match this filter - tap All to clear.` / `No spare cores on the bench.`

---

## 9. Contract survival (stated explicitly - none of these break)

- Drag-and-drop bits to sockets: drags only ever originate inside the OPEN drawer;
  medallions stay live drop targets; eligibility pulses fire whenever a drag or selection
  exists (which implies the drawer is open).
- Tap-socket-filters-tray with `slot_accepts` the ONLY predicate; filled =
  unequip-then-focus; again = clear. Unchanged - the drawer just guarantees visibility.
- TrayToolbar filter / sort state machine, sort-on-a-copy, persistence across rebuilds.
- Hold-to-bind (Binding overlay), long-press inspect (cards + sockets, 0.45s), dim-and-
  focus.
- Status-note contract: `_set_note`, 72-char cap, toast escalation, tappable note. The
  bool parameter widens to the enum (7.2); all call sites updated in the same change.
- Honest data honest: Ledger numbers, strain math, prices, counts - never hidden while
  relevant, never softened.
- \>= 44px targets everywhere new (lip, tag, chevron); reduce-motion on every new motion
  (slide, breath, pulse, nudge, ink-wipe, untie, sheen, fades); no hover-only essential
  affordance.

---

## 10. Files changed / untouched

**Changed:**
- `ui/workshop.gd` - drawer assembly (lip + well, state machine, triggers, spines, count
  tag, NEW stamp), `_focus_slot_in_tray`, Work-Order Tag (widget + T1-T6 + one-voice +
  untie), invite exclusivity + suppression, Ledger / anatomy visibility rules, nameplate
  swap, note-action enum + spare-core branch, settle nudge (tag-era), auto-open hooks
  (`_on_slot_tapped`, Binding success, Wake return), BIND-success tuck, DrawerChrome
  extension (handle, tag, spines).
- `ui/slot_field.gd` - `set_invite()` only (needed-pip logic untouched).
- `ui/manabit_stage.gd` - ember lamp on dormant, sleep breath, cavity rest-facing,
  `set_dormant_pulse()`.
- `ui/ledger.gd` - empty-build verdict branch + archetype hide.
- `meta/player_state.gd` (+ its save path) - `binds_total` additive field, increment in
  `bank_manabit`, load-seed from `menagerie.size()`.
- `tests/smoke_layout.gd` - two-state re-pin (section 11).
- `tests/shoot.gd` - capture set: closed-rest (built), open-all, socket-filtered,
  empty-rest (tag T1).
- `DESIGN.md` - record BEFORE code (house rule): InventoryGrid gains the CLOSED/OPEN
  state machine + lip anatomy (fulfilling its existing "collapsed" state), new
  `WorkOrderTag` component + states, SlotField `invite` state, Ledger / anatomy
  visibility rules, motion tokens `--drawer-slide` 180ms / `--tag-untie` 400ms /
  `--ink-wipe` 250ms / `--invite-breath` 2s.

**Untouched:** `ui/part_card.gd` (nudge is a workshop-driven tween), `BuildSession`,
`slot_accepts`, the Binding overlay internals, box reveal internals, inspect internals,
`SocketRig`, Warmth, all combat / economy / catalog code, all other screens.

---

## 11. Tests + gates

- `tests/smoke_layout.gd`: instantiate, assert CLOSED config (root min <= 704, every
  control in-frame, stage renders >= 380), toggle the drawer OPEN, re-assert (root min
  702 <= 704, in-frame), assert the tag rect does not intersect the CORE medallion rect
  at 1280x720, keep worst-case note strings (test BOTH no-core variants).
- Audit `smoke_builder` (and any other gate) for exact note-text assertions on the old
  empty-state string; update in the SAME change so gates only go red for real reasons.
- `smoke_kit`, `smoke_persist`: extend persist round-trip to cover `binds_total`
  (absent-field seed + increment on bank).
- Re-run all 14 fast gates headless after the merge; do not trust lane "green"
  (standing memory rule: re-parse the artifact).
- Fresh-eyes playtest of the first 60 seconds (section 12) before closing the owner loop.

---

## 12. First 60 seconds, fresh save (acceptance narrative)

0-5s: Workshop opens. Drawer closed (spines + `YOUR BITS · 8` peeking), no Ledger, no
anatomy inset, nameplate engraved. The husk breathes slowly under ember lamplight at
552px hero scale; one tag hangs off the brass rim: `This one's still asleep. - Seat a
core`; the CORE medallion and chest cavity share one slow amber heartbeat. Nothing else
moves. 5-15s: the player taps the tag or the medallion (same result): medallion lights,
drawer slides open filtered to CORE showing the three starter cores + the BindCoreCard
ghost; the first core card gives one settle nudge; Ledger and anatomy inset fade in.
15-25s: drag Ember Core to the cavity - SNAP, soul kindles, lamp comes up, husk
straightens; tag re-inks to `Awake, but empty-handed. - Give it an arm`; pips move to the
arms. 25-45s: tap an arm medallion, drawer filters ARMS, drag a claw in; Ledger rolls;
the grammar (tap socket -> see fits -> drag) is now learned by having done it twice. Tag
re-inks to `She's ready. - Press the seal`; the BIND plate sheens once. 45-60s: press
BIND - wax seal, BOUND! toast, drawer tucks itself, the tag unties and slides away
forever. The bench resets to a sleeping husk, the toy celebrated alone, and the player
has completed the core loop once, self-served.

---

## 13. Ordered implementation checklist

1. `DESIGN.md`: record the drawer state machine, WorkOrderTag, invite state, visibility
   rules, motion tokens (design-first house rule).
2. `meta/player_state.gd` + save path: `binds_total` (field, increment, load-seed);
   extend `smoke_persist`.
3. `ui/workshop.gd`: drawer assembly refactor (lip + well replace toolbar row + tray
   panel; `_lip_closed` / `_lip_open`; slide; open / close triggers incl. tap-away
   guards and tap-place cancel rule; spines / count tag / NEW stamp; auto-open hooks).
4. `tests/smoke_layout.gd`: two-state re-pin (run now - the budget must be green before
   any dressing lands).
5. `ui/workshop.gd`: Ledger + anatomy visibility rules; nameplate at-rest swap.
6. `ui/ledger.gd`: empty verdict + archetype hide.
7. `ui/workshop.gd`: note-action enum + spare-core note branch.
8. `ui/slot_field.gd`: `set_invite()`.
9. `ui/manabit_stage.gd`: ember lamp, sleep breath, cavity rest-facing,
   `set_dormant_pulse()`.
10. `ui/workshop.gd`: Work-Order Tag widget + T1-T6 + one-voice suppression + invite
    exclusivity + overlay / drag suppression + untie-on-bind + T6 sheen + settle nudge
    (tag-era gate) + anatomy manual print lines.
11. Gate sweep: all 14 fast gates + updated `smoke_layout` / `smoke_persist` /
    note-text audits; `tests/shoot.gd` capture set for the before / after.
12. Fresh-eyes 60-second playtest against section 12; only then report to the owner.

---

## 14. Rejected / deferred (so nothing silently vanishes)

- 3D ghost limb wireframe frames at the five mounts - DEFERRED (priciest item; the cheap
  dressing set + medallion teaching covers the read; revisit only if playtest fails).
- Half-peek third drawer state - rejected by both-lane consensus; the machine is binary.
- "Start OPEN on the very first session" fallback - not shipped; the T1 tag tap opens the
  drawer, which is the stronger teach. Reconsider only if the fresh-eyes playtest fails.
- `Bench is bare - crack the Box of Scrap or see Fettle.` tray-empty variant - the
  existing warm empty note survives; tag T4 already carries the Box path.
- Cross-widget heartbeat sync bus - the effect ships, implemented as shared engine-clock
  sampling; no new coordination machinery.
- Persisting the drawer's open state across screen entries - rest default is CLOSED.
- Any tutorial flag in the save - `binds_total` is an honest event counter (kit-counter
  precedent), not a tutorial bool.
