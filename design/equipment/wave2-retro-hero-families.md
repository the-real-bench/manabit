# WAVE 2 - THE HERO SHELF (retro boy-robot / super-robot families)

STATUS: TEAM-RATIFIED 2026-07-19 - stats PENDING wave-1 balance council; meshes PENDING art batch

Owner order: new bit sets, gundam-esque under the same principal design, in the Mega Man cohort /
Astro Boy / classic boy-robot and retro-super-robot toy register. Homage register only, always
legally distinct - vocabulary, never likeness.

## RECONCILIATION RECORD (producer + creative director, final)

Three lanes proposed nine family concepts across three registers. Ratified as THREE families -
fewer, stronger, one per register, every family carrying all three lanes' pieces:

| Register | Family (ratified) | Fantasy lane | Visual lane | Roster lane |
|---|---|---|---|---|
| Buster boy-hero (Mega cohort) | **Carillon Cadets** | Carillon Cadets (bellfoundry) | Rascal Roundworks system | Popgun Parade roster |
| Tin-toy rocket child (Astro) | **Larkabout Skyworks** | Larkabout Skyworks (elder couriers) | Skylark Wonderworks system | Skylark Cadets roster |
| Retro super-robot giant (Tetsujin/Gigantor) | **Steadfast Gallantworks** | new (this doc) | Stovepipe Sentinels system | Steadfast Gallantworks roster |

Rulings:
1. **Motley Guild is CUT from wave 2 and parked** as a future-wave concept. The order names three
   registers and the giant register needs a full family more than the wave needs a fourth; Motley's
   any-silhouette any-archetype shape is exactly the historical 50 percent silhouette-miss risk the
   art plan is built to kill. Its best beats survive here: catalogue-numbered naming on all three
   families, the chest-fin homage lands on Steadfast's crimson fin array, and the wax stamp-then-reveal
   seam is logged as the parked family's future pull moment.
2. **Roster shapes are the game designer's** (measured against the live 80-bit catalog); bit NAMES
   are re-skinned to the ratified fantasies. Carillon ships arms-heavy on purpose (the swap-arm
   homage IS the family); the CD's proposed Carillon head/legs/core bits are dropped - the measured
   holes are on arms, backs, and the EPIC shelves.
3. **Palettes are the art director's** (collision-audited). The CD's cream-dominant Carillon proposal
   is rejected: cream base belongs to Larkabout, and two cream families in one wave would blur at
   128px. Carillon's bell-bronze read lives in the RARE brass muzzle rings instead.
4. **Larkabout identity**: the CD's brace-first guardian and the GD's aggressive-tempo lane resolve
   as "fly first, hit honestly, catch what falls" - a SPD-lean SINGLE family. The brace identity
   moves wholly to Steadfast (Guardian Dome, Beacon Brow), which is where the gentle-protector
   fantasy wants it anyway.
5. **Family keys** (style-families.json AND lib FAMILY dict, matching existing convention):
   `carillon_cadets`, `larkabout_skyworks`, `steadfast_gallant`.
6. Wave size **20 bits (6 + 7 + 7), 6 COMMON / 10 RARE / 4 EPIC** - RARE/EPIC-skewed because COMMON
   is already 55 percent of the roster and every measured hole sits on the RARE/EPIC shelves.
7. **Gallant Core is a deliberate second EPIC core** (2 of 100 keeps near-unique gravity; no
   attack-affinity core exists above RARE). If the balance council vetoes, it demotes to RARE
   attack core with a high carry rider and the wave stays 20 bits.
8. Zero new engine mechanics: every ability composes from SINGLE (power / mana_cost /
   can_target_core), MULTI (hit_count / power), GUARD (DEF_BUFF / PART_RESTORE), passive stats,
   and the CORE-only carry rider. All three coffer-pull moments are presentation-layer only
   (Sfx pool seams + reveal tween ordering on the existing Waking ritual).

---

## FAMILY 1 - CARILLON CADETS (`carillon_cadets`)

### Identity + fantasy
The boy-robot hero line - the front-window kit a kid begs for by name. Cast in the old Bellfoundry
that once poured the town's waking-bells; every Cadet helm is a scaled-down waking-bell, and Fettle
sets his cart clock by the foundry's noon peal. The family's whole identity is the arm cannon at
every price: a cheap pellet SINGLE and a big charged SINGLE in one kit, so a Cadet always has the
right shot for the mana you can pay.

LEGAL REGISTER: the buster silhouette is re-derived as a BELL - bell-mouth Chime Cannon forearms,
bell-dome helm vocabulary, muffle-and-carol bell language. Never a blue-bomber copy: invented
two-tone cerulean, bell-mouth flare instead of a straight buster barrel, clapper instead of a lens.

FLAVOR:
- "Every Cadet ships with one bell and one promise: ring true, ring once, ring for somebody."
- "Charge it as long as your courage holds - the peal is louder for the waiting."

NAMING: "Carillon Cadet No.N" catalogue prefix + bell-vocabulary nouns (Ding, Carol, Peal, Muffle,
Bellows, Grand Peal).

### Visual system (art-lane, ratified)
- **SILHOUETTE LAW (the one rule):** at least one terminal mass is a BARREL visibly WIDER than the
  limb feeding it - sculpted as a bell-mouth (flared frustum, r_mouth > r_limb) on ARM bits, drum
  masses elsewhere. Head vocabulary is a clean hemisphere dome with a horizontal brow band. No
  over-wide bell terminal = fails review.
- **PALETTE (two-tone-of-one-hue is itself the family tell - no existing family does this):**
  base vivid cerulean `#2E9FD9`, trim deep tone `#23538F` (lower/inner masses), cap off-white
  `#E4DED0` (face, palms, soles), microglow warm amber `#FFB347`. Finish: candy gloss.
  Collision note: sits between chatterbox `#8FC4E8` and errant `#3A5AA8`; the two-tone blocking +
  bell silhouette separates it at 128px; if the contact sheet disagrees, darken base to `#2380B8`,
  never drift toward errant navy.
- **GREEBLES:** `dome` (NEW op), band-as-short-cyl, `scribe`, `bolt`, `vent_cut` for the bore,
  `layer` for cuffs. Emissive ONLY inside the bell bore or chest gem, never at the socket
  (anti-totem rule); socket collar flush and dark.
- **RARITY LADDER:** COMMON = tin brow band + tin muzzle ring; RARE = brass muzzle ring (the
  bell-bronze read) + cobalt rune line down the barrel; EPIC = gold brow crest + amethyst charge
  ring recessed inside the bore.
- **PER-SLOT:** ARM = ball shoulder, capsule upper arm, over-wide bell-mouth forearm with banded
  wrist + dark recessed bore + amber charge dot. BACK = twin stacked round canisters with band
  rings (the bellows-and-ammo read). HEAD vocabulary (future bits) = dome + brow band + mirrored
  ear pucks, NO visor slit (Everykit's cue).
- **Tri budget 600-1400. BATCH RISK: LOW-MEDIUM** - lathe-friendly; one proportion rule to police
  (bell wider than limb). Batch SECOND.

### Bit list (6 - deliberately arms-heavy; stats are the council's)
| # | Name | Slot | Rarity | Role + rough tier | Ability composition |
|---|---|---|---|---|---|
| 1 | Ding Arm | ARM_R | COMMON | The signature baseline: mid-weight honest-power cheap pellet shot, cost-1 tempo poker | SINGLE, low power, mana_cost 1, can_target_core false |
| 2 | Carol Arm | ARM_L | COMMON | Light rapid-fire ring-of-bells, the "rapid mode" as its own arm | MULTI, 3 hits, low power, cheap |
| 3 | Peal Cannon | ARM_R | RARE | The charge shot: heavy SINGLE at high mana so it fires roughly every other turn; Boldheart-adjacent but lighter and faster, no core reach | SINGLE, high power, high mana_cost, can_target_core false |
| 4 | Muffle Mitt | ARM_R | RARE | Light-weight brace arm - the slide-and-parry homage; fills the thin light ARM_R GUARD shelf | GUARD DEF_BUFF, light weight, modest cost |
| 5 | Grand Peal | ARM_L | EPIC | The crown bell: high-power core-capable SINGLE at steep mana, MID weight - a third distinct core-capable EPIC arm lane vs Meteor (w50 slow) and Grinlet (feather glass) | SINGLE, high power, can_target_core TRUE, steep mana_cost |
| 6 | Bellows Pack | BACK | RARE | Energy-rich light GUARD back that funds the charge cycle (Everykit Cell one tier up; thickens the thin RARE BACK shelf) | GUARD DEF_BUFF small + high energy stat line |

### Coffer-pull moment
The pull RINGS - one clear chime as the bit lands and the bell-mouth catches the lamp (Sfx pool,
single note per rarity pitch). Grand Peal gets a long swelling three-note peal and a slow amethyst
warm-up inside the bore. Presentation-layer only.

---

## FAMILY 2 - LARKABOUT SKYWORKS (`larkabout_skyworks`)

### Identity + fantasy
The kindly elder sibling line - the oldest shelf in the Barrow. The grandparent Artificers' courier
line, made to fetch kites off rooftops and mind children on the walk home; long retired, endlessly
repaired, never thrown away. Fettle keeps one Larkabout heart under the cart counter "for
sentiment." In play it is the first-mover: rocket boots, a glowing chest-hatch heart, honest fast
hits - built to fly first, and to catch you on the way down.

LEGAL REGISTER: tin-toy retro-future rocket boots as a VOCABULARY - riveted porcelain-tin, bell
nozzles, a hinged chest hatch over a warm heart. The head crest is a LARK'S crest (two swept
feather-tin fins at a fixed 30 degree back-sweep), never the twin-spike hairdo.

FLAVOR:
- "Built to reach the kite stuck in the tallest tree, and to catch you on the way down."
- "The boots know the way up. The heart knows the way home."

NAMING: "Larkabout No.N" catalogue prefix + sky-and-sunup verb-forward nouns.

### Visual system (art-lane, ratified)
- **SILHOUETTE LAW (the one rule):** CAPSULES ONLY - every armor mass is a sphere, dome, or
  sphere-capped cylinder; a box anywhere on the armor fails review (boxes only as dark frame/joint
  fillers); boots MUST flare into bell nozzles.
- **PALETTE:** base warm porcelain cream `#EAD9B0` (the only cream-BASED family - open lane;
  neutral-hex reuse precedented by sovereign_brass), trim candy-scarlet `#D8342E` for gloves,
  boots, belt (hex shared with boldheart/tinbox - precedented; blocking differs: cream body with
  scarlet extremities vs red body), cap glossy warm near-black `#3A2A1E` for the swept crest
  (above the `#2A211B` floor), microglow warm amber `#FFB347` (the chest heart-light, plus
  emissive amber nozzle throats at the boot heels - the first family whose glow lives at the
  LEGS). Finish: high-gloss porcelain enamel.
- **GREEBLES:** `dome` (NEW op), `fin` x2 mirrored at a FIXED 30 degree back-sweep for the crest,
  `nozzle` inside each boot heel (emissive amber throat only there), `scribe` for the
  rounded-corner chest hatch, `bolt` sparingly.
- **RARITY LADDER:** COMMON = tin boot-bell rims, closed hatch + amber dot; RARE = brass bell rims
  + hatch outline that lights cobalt; EPIC = gold hatch cracked open a sliver with the amethyst
  heart rune glowing inside + gold fleck.
- **PER-SLOT:** HEAD = smooth dome + two mirrored swept crest fins + cream face with big friendly
  dark scribe eyes and tiny amber glints, no jaw box; ARM = sphere-capped capsule with an
  oversized rounded scarlet glove fist + wrist ring; LEGS = slim capsule thighs into flared
  scarlet bell boots, nozzle throat per heel; BACK = teardrop twin jet pods with swept fins +
  nozzle bells, folded-wing stance.
- **Tri budget 500-1500** (sphere-heavy; uvsphere segments 8 / rings 5).
- **ADJACENCY GUARD** vs Tinbox (stamped-tin huggable wind-up) and Pocketful (chibi big-head):
  Larkabout is heroic-proportioned, glossy, aerodynamic - crests + bell boots differentiate.
- **BATCH RISK: HIGH** (the historical-miss shape class - sphere builds blob out, crest angles get
  fumbled). Hand-build ONE golden example first; lock crest rotation constants, boot-flare ratio,
  and eye scribe positions as recipe-header constants; THEN batch. Batch LAST.

### Bit list (7 - stats are the council's)
| # | Name | Slot | Rarity | Role + rough tier | Ability composition |
|---|---|---|---|---|---|
| 1 | Larkcrest Dome | HEAD | COMMON | Light fast jab head - Everykit-Cowl-adjacent but thinner and quicker | SINGLE, light power, cheap |
| 2 | Swoop-Crest Helm | HEAD | RARE | SPD-heavy called-shot head, Windshear-Visor one tier up | SINGLE, can_target_core TRUE, moderate power, priced by mana |
| 3 | Catch-Hand Mitt | ARM_R | COMMON | FEATHER-class right arm (first fill on the measured zero-feather-ARM_R hole); the gentle catch | SINGLE, low power, very light, cheap |
| 4 | Sunup Haymaker | ARM_L | RARE | Mid-weight SINGLE nuke, Boldheart-adjacent but SPD stays above 0 - the hero swings before the wall braces | SINGLE, high-mid power, moderate mana_cost |
| 5 | Rocketboot Striders | LEGS | RARE | The missing aggressive RARE legs: high SPD plus a point of ATK (existing RARE legs are all defense or pure tempo) | Passive stat line (legs never carry abilities) |
| 6 | Contrail Boots | LEGS | EPIC | Featherweight glass-rocket legs: top SPD, thin HP, zero DEF - the opposite pole to Bedrock; fills LEGS-EPIC=1 hole | Passive stat line |
| 7 | Updraft Satchel | BACK | RARE | Passive mobility back: SPD plus energy (the first RARE passive BACK - fills that hole) | Passive NONE archetype, SPD + energy line |

### Coffer-pull moment
The bit comes out already airborne - it rises from the coffer on a soft contrail sparkle, hangs a
beat, and settles as the heart-hatch warms to a glow (reveal tween + Sfx whistle-hush).
Contrail Boots settle last with both nozzle throats lit. Presentation-layer only.

---

## FAMILY 3 - STEADFAST GALLANTWORKS (`steadfast_gallant`)

### Identity + fantasy
The gentle tin giant and its little signal-glove controller - the Tetsujin/Gigantor register
rendered cozy. Cast in the same Bellfoundry generation as the Larkabout couriers: the heavy line,
built to carry roof-beams, raise stuck portcullises, and stand fire-watch through the night. Every
Steadfast answers to a child's signal-glove, and the old Guild rule stands: a giant may only ever
be as brave as the hand that guides it. Fettle rents the last working Steadfast every spring to
raise the cart's awning, and pays it in polish.

LEGAL REGISTER: 1960s remote-hero super robot as VOCABULARY - stovepipe cylinder construction,
rivet seams, bullet-nose head, crimson chest-fin array (the retro-super-robot chest fins the owner
ordered live HERE), finned rocket backpack, the child controller as a feather ARM bit. Invented
slate-and-cream palette, no likeness.

FLAVOR:
- "Wind it, point it at the heavy thing, and go play. It will still be standing when you get back."
- "The glove does the deciding. The giant just makes the deciding true."

NAMING: "Steadfast No.N" catalogue prefix + stalwart guardian nouns.

### Visual system (art-lane, ratified)
- **SILHOUETTE LAW (the one rule):** every mass is a straight-walled CYLINDER or FRUSTUM stacked
  coaxially with a proud seam band + rivet ring at every joint; fins are the ONLY sharp shapes and
  they are always crimson.
- **PALETTE:** base slate-steel blue `#55627A` (new hue territory - blue-leaning where grumble's
  gunmetal `#4A4E52` is a neutral-dark TRIM; far from silksteel silver `#C9CCD6`), trim cream
  `#EAD9B0` (face plate, seam bands), cap crimson `#C1443A` (chest fins, tail fins, feet, mitts;
  hex shared with everykit base - precedented, blocking differs), microglow warm amber `#FFB347`
  (porthole eyes / banked pilot light). Finish: satin lithographed-tin plastic - keep `#55627A`
  OUT of the lib METAL set; rivets and frames carry all metal sheen.
- **GREEBLES:** `rivet_ring` (NEW op), band-as-short-cyl seams, `dome` for the bullet-nose crown,
  `fin` for chest/tail fins, `nozzle` for the flight pack, `scribe`, `vent_cut` for the visor slit.
- **RARITY LADDER (cleanest of the wave - the rivets ARE the frame):** COMMON = tin rivets + tin
  seam bands; RARE = brass rivets + one cobalt load-glyph on the chest between the fins; EPIC =
  gold rivets + amethyst-lit fin edges + gold fleck on the crown seam.
- **PER-SLOT:** HEAD = vertical cylinder with dome crown + rivet ring at the crown seam + single
  dark visor slit or twin amber porthole eyes + one small antenna fin; ARM = stovepipe segments
  with rivet-ringed seams, wide flat drum pauldron, cylinder mitten fist; LEGS = two thick
  stovepipe columns, ankle bands, wide flat oval feet, rivet seam down each outer face; CORE =
  barrel torso frustum + the sternum CHEST FIN ARRAY (2-3 vertical crimson fins) + rivet rings at
  top and bottom seams; BACK = twin large rocket nozzles + swept crimson tail fins.
- **Tri budget 600-1300.**
- **ADJACENCY GUARD** vs Grumble (wide low trapezoid slabs, safety-yellow) and Tinbox (small
  huggable primaries): Steadfast is TALL, coaxial, monumental.
- **BATCH RISK: LOW - the lowest of the wave.** Pure lathe stacking plus rivet_ring makes the
  silhouette near-impossible to miss. Batch FIRST to calibrate the wave.

### Bit list (7 - stats are the council's)
| # | Name | Slot | Rarity | Role + rough tier | Ability composition |
|---|---|---|---|---|---|
| 1 | Guardian Dome | HEAD | COMMON | Cheap light brace head - fills the no-COMMON-GUARD-head hole (only Herald Crown guards from HEAD today) | GUARD DEF_BUFF, small amount, cost 1 |
| 2 | Beacon Brow | HEAD | EPIC | The biggest DEF_BUFF brace in the game on a heavy head - the anti-Oracle; fills HEAD-EPIC=1 hole | GUARD DEF_BUFF at the EPIC soft-cap, heavy, real mana_cost |
| 3 | Signal-Glove | ARM_R | COMMON | Feather-class controller-boy arm: tiny hit, contributes energy (second fill on the zero-feather-ARM_R hole) | SINGLE tiny power + energy stat line |
| 4 | Twin Rocketfist | ARM_L | RARE | The signature volley: the game's first LOW-COUNT heavy MULTI - 2 hits at the per-hit ceiling, between Thicket's 4-5 bites and Boldheart's one huge hit; inside shipped soft-caps | MULTI, hit_count 2, per-hit at RARE ceiling, real mana_cost |
| 5 | Gantry Greaves | LEGS | RARE | HP-deepest legs with a point of energy - tank-legs lane between Rampart and Bedrock | Passive stat line |
| 6 | Windup Key | BACK | COMMON | "Wind it back up" - spreads PART_RESTORE to a fourth family with perfect thematic cover | GUARD PART_RESTORE, modest amount, cheap |
| 7 | Gallant Core | CORE | EPIC | The wave's chase: attack-affinity counterpart to Regalia (today's only EPIC core is defense) - big HP, attack lean, HIGH carry rider (it IS a giant; capacity is the fantasy). Keeps EPIC cores near-unique at 2 of 100. Council veto fallback: demote to RARE attack core with high carry, wave stays 20 bits | Core stat line + carry rider (existing CORE-only rider, priced 0.4/pt per balance-notes) |

### Coffer-pull moment
The heavy landing - the coffer light dims a beat, the bit settles with a deep felted thud, the
amber portholes blink awake one at a time, and the wind-up key gives a single slow click-turn.
Gallant Core instead lights its crimson fin array edge by edge, bottom to top. Presentation-layer
only (Sfx pool + existing reveal tween ordering).

---

## WHEEL ADDITIONS (intransitive, each hooks an existing pole; no loops among the three new families)

- **Carillon Cadets BEAT Grumble & Co** - the charged Peal Cannon / Grand Peal punches through DEF
  tuned to blunt flurries; the wall cannot dodge slow big shots. **LOSE TO Whirligig Foldforms** -
  tempo strips the cannon arm mid-charge; the mana-hungry cycle never completes.
- **Larkabout Skyworks BEATS Boldheart Valorworks** - out-initiatives it and breaks the drill arm
  before the haymaker fires. **LOSES TO Thicket & Fang** - MULTI auto-lowest-HP shreds its thin
  feather bits.
- **Steadfast Gallantworks BEATS Whirligig Foldforms** - deep part-HP plus cheap braces absorb the
  chip race, then Twin Rocketfist deletes glass. **LOSES TO Silksteel Atelier** - the slow giant
  cannot keep the scalpel off its core; the classic giant-felled-by-precision beat.

Wave-internal story: Whirligig beats Carillon and loses to Steadfast, so the two new poles already
pressure each other through an existing family - the wheel stays intransitive with no new closed
pair.

## CHALLENGER ADOPTION (later wave, per _challenger_ids.txt conventions)

- Scrap-Pup tier: a low ranged challenger built from **Ding Arm + Carol Arm** teaches the
  DEF-vs-flurry rule; a fast early challenger from **Larkcrest Dome + Rocketboot Striders**
  teaches initiative.
- Cogsworth (elite) variant adopts **Peal Cannon + Bellows Pack** as the ranged elite.
- Prince Gildfall (2nd boss) or a new giant boss adopts **Beacon Brow + Twin Rocketfist +
  Gallant Core** as the Steadfast showcase - elite/boss are the sanctioned core-aimers, matching
  the Silksteel-beats-Steadfast story.

## MEASURED ROSTER HOLES THIS WAVE FILLS (baseline: 80 live bits, GD lane audit 2026-07-19)

1. EPIC HEAD 1 -> 2 (Beacon Brow)
2. EPIC LEGS 1 -> 2 (Contrail Boots)
3. EPIC CORE 1 -> 2 (Gallant Core; deliberate, veto fallback documented)
4. Feather ARM_R 0 -> 2 (Catch-Hand Mitt, Signal-Glove)
5. COMMON GUARD head 0 -> 1 (Guardian Dome)
6. RARE BACK 3 -> 5, including the first RARE passive-mobility back (Updraft Satchel, Bellows Pack)
7. Light ARM_R GUARD (Muffle Mitt; existing 2 are both mid-heavy)
8. PART_RESTORE spread to a 4th family (Windup Key)
9. Aggressive RARE legs (Rocketboot Striders)
10. New-but-capped MULTI shape: 2 hits at per-hit ceiling (Twin Rocketfist - existing keywords only)
11. Third distinct core-capable EPIC arm lane (Grand Peal, vs Meteor w50-slow and Grinlet feather-glass)

Known cost: COMMON heads go 8 -> 10 (Larkcrest Dome + Guardian Dome); accepted because the GUARD
head is a real archetype hole - council may demote Larkcrest Dome if the shelf feels crowded.

Adjacent flag, NOT this wave: tinbox has 1 live bit vs its style-families.json promise. Recommend a
5-bit tinbox completion mini-wave AFTER this wave lands, so the boy-robot families read as new.

## ART-LIB DELIVERABLES (art lane, ratified verbatim)

New FAMILY dict rows for `tools/art/manabit_bit_lib.py` (do NOT add any base hex to METAL; all
three keep default amber microglow - the signature-glow override count stays at the bible's cap of
5, and amber reads as the tin-toy pilot-light of this whole register):

```python
"carillon_cadets":    {"base": "#2E9FD9", "trim": "#23538F", "cap": "#E4DED0", "microglow": "#FFB347"},
"larkabout_skyworks": {"base": "#EAD9B0", "trim": "#D8342E", "cap": "#3A2A1E", "microglow": "#FFB347"},
"steadfast_gallant":  {"base": "#55627A", "trim": "#EAD9B0", "cap": "#C1443A", "microglow": "#FFB347"},
```

Exactly TWO new greeble ops (per the cap):
1. `b.dome(radius, at=(0,0,0), rot=(0,0,0), segments=10, rings=5, name="dome")` - hemisphere with
   a filled flat base (create_uvsphere, delete verts z < -1e-4, cap the rim, then place). Needed
   because half-sunk full spheres double hidden tris and read wrong from below at the stage's
   18 degree hero yaw - two of three families are dome-led.
2. `b.rivet_ring(radius, count=8, at=(0,0,0), rot=(0,0,0), r=0.022, h=0.025, name="rivets")` -
   places count bolt nubs evenly on a local-XY circle, each rotated to point radially outward,
   then places the group. Kills the fiddly hand-placement step that drove the historical
   50 percent silhouette miss rate; makes Steadfast seams deterministic.

Also add the three rows to the art-bible.md family palette table and three entries to
design/equipment/style-families.json (key/name/mecha_inspiration/motif/mechanical_identity/naming,
matching the existing doc shape) using the identities in this spec.

Adjacency checks the review pass must run at 64-128px: Larkabout vs Tinbox, Larkabout vs
Pocketful, Steadfast vs Grumble, Carillon vs Everykit (dome + brow band + no visor vs boxy visor;
two-tone blue vs red-grey). These four pairs are the only plausible confusions.

## PRODUCTION CHECKLIST (ordered)

1. **STATS** - wave-1 balance council prices all 20 bits against the shipped budget model
   (balance-notes.md bands COMMON 14-18 / RARE 18-22 / EPIC 22-26; soft-caps SINGLE 5/7/9, MULTI
   hits 3/4/5 per-hit 3/3/4, GUARD 4/6/8; carry at 0.4/pt). Council also rules the Gallant Core
   EPIC-vs-demote question and the Larkcrest Dome COMMON-head-crowding question.
2. **CATALOG ENTRIES** - 20 rows appended to `parts/catalog_extra.json` (PartData shape as live:
   id, name, slot, rarity, family, stats, ability block). Suggested id pattern
   `<family>_<slot>_<noun>` per existing convention. Three new entries in
   `design/equipment/style-families.json`. Re-run `smoke_contract` + `smoke_catalog`.
3. **PLACEHOLDERS LIVE** - bits pull in Workshop/Coffer/Barrow via the procedural fallback;
   verify tray filters, Today's Finds, and challenger loadouts still gate correctly
   (`smoke_broker`, `smoke_kit_sim` after stats).
4. **ICONS** - 20 card icons at `art/icons/<id>.png` through the existing icon pass.
5. **MESH BATCH** - lib updates first (2 greeble ops + 3 FAMILY rows), then batch order:
   Steadfast (lowest risk, calibrates the wave) -> Carillon (police the bell-wider-than-limb rule
   + anti-totem bore glow) -> Larkabout (hand-build ONE golden example, lock crest/boot-flare/eye
   constants in the recipe header, then batch). All existing boxset tells unchanged: hex socket
   collar + amber glow-dot, rarity frame trio, etched-rune-as-texel, 1 material, atlas <= 256,
   origin on socket, tris 300-2400 (family targets above).
6. **ART AUDIT** - `tests/smoke_art.gd` PASS at off-spec 0, contact sheet at 64/128px against the
   four adjacency pairs + the cerulean collision check (darken to #2380B8 only if it fails), then
   the coffer-pull presentation pass (chime / airborne-settle / heavy-landing) on the existing
   Waking ritual seams.
