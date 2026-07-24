# WAVE 2 MESH WORK ORDER - THE HERO SHELF (20 bits, 3 families)

RULING FIRST, HONESTLY: this machine has no Blender - this is a verbatim handoff for the second PC's blender-mcp session, exactly like the proven fx-work-order. The 20 catalog rows are ALREADY LIVE in parts/catalog_extra.json and ui/family_palette.gd already tints their procedural fallbacks, so the game ships fully working with zero of these glbs - every mesh below is a drop-in-by-filename upgrade (id == PartData.id exactly, no code edits, ever). Batch order is by the ratified spec's risk ratings: STEADFAST first (LOW - pure lathe stacking, calibrates the wave), CARILLON second (LOW-MEDIUM - one proportion law to police), LARKABOUT last (HIGH - the historical 50 percent silhouette-miss shape class; golden-example protocol mandatory). Authority for every visual call below: design/equipment/wave2-retro-hero-families.md (team-ratified 2026-07-19).

----------------------------------------------------------------------
MANABIT WAVE 2 MESH BATCH (20 bits) - for blender-mcp

SESSION SETUP (once). ROOT = the folder on THIS machine that contains tools\art\manabit_bit_lib.py. The lib's baked default says the last-known checkout here is G:\ClaudeAgents\my-game\.claude\manabit - VERIFY that path exists first; if the checkout moved, substitute the real root everywhere below.
    exec(open(ROOT + r"\tools\art\manabit_bit_lib.py").read())
    import math as _m
BITS_DIR stays the lib default (<ROOT>\art\bits) - these ARE bits, unlike the fx pack. Read tools\art\RECIPE_GUIDE.md end to end before the first build (the API, the GUNPLA DETAIL section, the socket-origin table, the render rig).

LIB UPDATES FIRST (do these before any build, then re-exec the lib):
1. Three FAMILY dict rows, hexes VERBATIM (they must match the main PC's ui/family_palette.gd rows, which are already live):
    "carillon_cadets":    {"base": "#2E9FD9", "trim": "#23538F", "cap": "#E4DED0", "microglow": "#FFB347"},
    "larkabout_skyworks": {"base": "#EAD9B0", "trim": "#D8342E", "cap": "#3A2A1E", "microglow": "#FFB347"},
    "steadfast_gallant":  {"base": "#55627A", "trim": "#EAD9B0", "cap": "#C1443A", "microglow": "#FFB347"},
   Do NOT add any of these hexes to METAL (satin lithographed-tin is the Steadfast finish - rivets and frames carry all the sheen). Do NOT add microglow overrides anywhere - all three families keep default amber, the signature-glow override count stays at the bible's cap of 5.
2. Exactly TWO new greeble ops (the ratified cap), same create-then-transform conventions as the existing ops:
    b.dome(radius, at=(0,0,0), rot=(0,0,0), segments=10, rings=5, name="dome") - hemisphere with a filled flat base: create_uvsphere, delete verts z < -1e-4, cap the rim, then place. Needed because half-sunk full spheres double hidden tris and read wrong from below at the stage's 18 deg hero yaw.
    b.rivet_ring(radius, count=8, at=(0,0,0), rot=(0,0,0), r=0.022, h=0.025, name="rivets") - places count bolt nubs evenly on a local-XY circle, each rotated to point radially outward, then places the group. Makes Steadfast seams deterministic instead of hand-placed.
   Smoke the two ops on a throwaway Bit before the batch: dome from below shows a closed base; rivet_ring nubs all point outward.

SHARED RULES (every one of the 20): these are normal BITS - hex socket_collar + amber glow-dot at the plug point, rarity frame, rune, 1 material, atlas <= 256px (the lib's palette atlas default is fine), finalize(cleanup=False), inspect res: materials==1, warnings==[], tris inside the family band below (the Godot audit hard range is 300-2400). LOCAL origin = the socket point - pass the slot's plug point as socket= per the RECIPE_GUIDE table: HEAD neck at bottom, ARM shoulder at top, LEGS hips at top, BACK mount face (pack extends -Y), CORE centered. Envelope: longest dim <= 1.4 (audit hard-fails at 1.8). The stage does NOT mirror arm meshes - ARM_L and ARM_R are each their own glb, arm hanging straight down from the shoulder plug; the stage plugs them against the core by bounding box, so put the ONE-read mass at the far end and keep the socket collar small and flush. Use b.mirror for within-bit symmetry (legs, paired fins, paired pods) - never hand-place both sides. Emissive discipline is PER FAMILY and listed below; the only universal emissive is the socket glow-dot. After each build: EEVEE render with the RECIPE_GUIDE 3-point rig (bright rig + Standard view transform - the proven rig lesson: a dim world makes atlases look muddy when they are bible-true) to G:\ClaudeData\tmp\claude\manabit-bits\<id>.png at 440px PLUS one at 160px - if the silhouette does not read as its SLOT at 160px it FAILS (the game renders at 320x240). Iterate silhouette FIRST, detail second - a detailed bit with the wrong silhouette is a FAIL (the wave-1 lesson: arm-as-totem, back-as-figurine).

IDS ARE LOAD-BEARING: the id in each header below is the exact catalog id; the glb filename must be <id>.glb or the drop-in pipeline stays dark. Do not rename anything.

======================================================================
BATCH 1 - STEADFAST GALLANTWORKS (7 bits) - RISK: LOW, build FIRST to calibrate the wave
======================================================================

FAMILY VISUAL SYSTEM (spec section: FAMILY 3):
- SILHOUETTE LAW: every mass is a straight-walled CYLINDER or FRUSTUM stacked coaxially, with a proud seam band (short cyl) + b.rivet_ring at EVERY joint. Fins are the ONLY sharp shapes and they are ALWAYS crimson.
- PALETTE: base slate-steel blue #55627A, trim cream #EAD9B0 (face plates, seam bands), cap crimson #C1443A (fins, feet, mitts), microglow warm amber #FFB347. Finish satin - the base hex stays OUT of METAL; rivets ("frame") and gold/brass carry the sheen.
- EMISSIVE DISCIPLINE: amber porthole eyes / banked pilot lights only, always recessed in a dark bezel. Heads glow; the key and the legs do not.
- RARITY LADDER: COMMON = tin rivets + tin seam bands + dark stamped serial; RARE = brass rivets + ONE cobalt load-glyph on the named surface; EPIC = gold rivets + amethyst-lit fin edges + gold fleck on the crown seam.
- ADJACENCY GUARD: vs grumble_co (wide LOW trapezoid slabs, safety-yellow) and tinbox (small huggable primaries) - Steadfast is TALL, coaxial, monumental.
- TRI BUDGET: 600-1300 per bit.
- POLICE RULE for the whole batch: if any mass is a box (other than a dark joint filler) or any fin is not crimson, it fails review.

1. steadfast_gallant_head_guardian - HEAD, COMMON (Guardian Dome, the cheap brace head, w12)
   ONE READ: a riveted stovepipe with a bullet-nose crown.
   Build: vertical cylinder head, b.dome crown, rivet_ring at the crown seam; cream face-plate band; twin amber porthole eyes (emissive, each recessed in a dark bezel cyl); ONE small crimson antenna fin off the crown. Neck stub at the bottom = origin, socket=(0,0,0). Tin rivets + tin seam band + dark serial on the rear. ~600-900 tris.
2. steadfast_gallant_head_beacon - HEAD, EPIC (Beacon Brow, the biggest brace in the game, w26 spd0)
   ONE READ: a lighthouse brow on a stovepipe head.
   Build: taller, wider stack than Guardian (this head is HEAVY - let the proportions say so); a proud cream BROW ledge (overhanging frustum) above a single dark visor slit (vent_cut); the beacon = one large amber lamp (emissive) centered in the brow recess; two rivet_rings (crown seam + neck seam); one crimson antenna fin with an amethyst-lit edge (EPIC rung); gold rivets + gold fleck on the crown seam. ~900-1300 tris.
3. steadfast_gallant_arm_signalglove - ARM_R, COMMON (Signal-Glove, the child controller, w5 - FEATHER class)
   ONE READ: a tiny glove waving on a stick.
   Build: the SMALLEST arm of the wave - slim cylinder upper arm, one tin seam band, ending in an oversized crimson mitten (cylinder mitt + dome) with a cream cuff ring; one tiny fin at the cuff = the signal aerial; ONE small amber lamp on the BACK of the mitt (end-effector glow - the anti-totem rule: NOTHING glows at the shoulder, collar flush and dark). Shoulder at origin, arm extends -Z. ~600-800 tris. Weight 5 in the catalog - keep it visibly slight next to Rocketfist.
4. steadfast_gallant_arm_rocketfist - ARM_L, RARE (Twin Rocketfist, the signature volley, w32)
   ONE READ: a riveted piston arm whose fist is about to launch.
   Build: the fattest arm - stovepipe segments with rivet_ring at both seams; wide flat drum pauldron at the shoulder; big crimson cylinder-mitten fist; a dark wrist GAP ring implying the detach + a recessed nozzle ring behind the fist (the launch throat - a tiny banked amber pilot dot inside it is the only sanctioned glow); brass rivets + ONE cobalt load-glyph scribed on the forearm. Shoulder at origin, extends -Z. ~800-1200 tris.
5. steadfast_gallant_legs_gantry - LEGS, RARE (Gantry Greaves, tank legs, w30 hp22)
   ONE READ: two riveted bridge pylons with feet.
   Build: build ONE thick stovepipe column and b.mirror - rivet seam (scribe + rivet_ring) down the OUTER face only, cream ankle band, wide flat oval crimson foot; brass rivets + one cobalt glyph on one thigh (asymmetric is fine - it is a load stencil). Hips at origin, legs extend -Z. No emissive. ~800-1200 tris.
6. steadfast_gallant_back_windup - BACK, COMMON (Windup Key, the PART_RESTORE pack, w16)
   ONE READ: the wind-up key of the whole toy.
   Build: flat round mount plate at the origin face, short slate shaft extending -Y, ending in a two-lobed key bow (two flattened cylinder loops side by side, cream lobe rims); tin rivet_ring on the mount plate; dark serial on the shaft. NO emissive - the key is banked, sleeping. Mount face at origin, pack extends -Y. ~600-900 tris.
7. steadfast_gallant_core_gallant - CORE, EPIC (Gallant Core, the wave's chase, attack affinity, carry 12)
   ONE READ: a riveted boiler chest with a crimson fin array.
   Build: barrel torso frustum (wider at the shoulders), rivet_ring at the top AND bottom seams, cream seam bands; the sternum CHEST FIN ARRAY = 3 vertical crimson fins with amethyst-lit edges (this is the owner's retro-super-robot chest-fin homage - it lives HERE and nowhere else); the attack soul lens = paint "attack" emissive in a dark recessed porthole above the fins; gold rivets + gold fleck on the crown seam. Build centered, socket=(0,0,0). Top of the family band, ~1000-1300 tris - it is the family flagship, spend the budget.

CONTACT SHEET (before touching Carillon): render all 7 on one sheet - front + 3/4 per bit at 440px, plus a 64px AND 128px strip - to G:\ClaudeData\tmp\claude\manabit-contact\wave2_steadfast_sheet.png. Verify: every joint shows a rivet ring; every mass coaxial; fins crimson only; TALL-monumental read vs grumble_co (pull grumble_co_girder_fist + anvil_cowl renders alongside - at 64px they must never confuse). Fix before batch 2.

======================================================================
BATCH 2 - CARILLON CADETS (6 bits) - RISK: LOW-MEDIUM, ONE law to police
======================================================================

FAMILY VISUAL SYSTEM (spec section: FAMILY 1):
- SILHOUETTE LAW (police on EVERY arm): at least one terminal mass is a BARREL visibly WIDER than the limb feeding it - a bell-mouth flared frustum with r_mouth > r_limb. Assert it numerically in the recipe (keep r_mouth >= 1.4 * limb radius); an arm without an over-wide bell terminal FAILS review.
- PALETTE (the two-tone-of-one-hue IS the family tell): base vivid cerulean #2E9FD9 (outer masses), trim deep #23538F (lower/inner masses - block deliberately, upper-outer light vs lower-inner deep), cap off-white #E4DED0 (cuffs, soles), microglow amber #FFB347. Candy gloss.
- EMISSIVE DISCIPLINE (anti-totem, non-negotiable): emissive ONLY inside the bell bore (the amber charge dot) - NEVER at the socket, never on a collar. Socket collar flush and dark.
- RARITY LADDER: COMMON = tin muzzle ring; RARE = brass muzzle ring (the bell-bronze read) + cobalt rune line scribed down the barrel; EPIC = gold crest ridge + amethyst charge ring recessed inside the bore + gold fleck.
- GREEBLES: dome, band-as-short-cyl, scribe, bolt, vent_cut for the bore, layer for cuffs.
- ADJACENCY GUARD: sits between chatterbox #8FC4E8 and errant #3A5AA8 - the two-tone blocking + bell silhouette separates it at 128px. If the contact sheet disagrees, darken base to #2380B8 and NEVER drift toward errant navy.
- TRI BUDGET: 600-1400 per bit.

1. carillon_cadets_arm_ding - ARM_R, COMMON (Ding Arm, the signature baseline pellet shot, w18)
   ONE READ: a bell for a hand.
   Build: THE reference Cadet arm - ball shoulder (uvsphere, deep-tone trim), cerulean capsule upper arm, over-wide bell-mouth forearm (flared frustum, mouth clearly wider than the limb), deep-tone banded wrist, off-white cuff layer; dark recessed bore (inner dark cone) with the amber charge dot (emissive) deep inside; tin muzzle ring + dark serial. Shoulder at origin, extends -Z. ~600-900 tris. Get this one perfect - the other four arms are variations on it.
2. carillon_cadets_arm_carol - ARM_L, COMMON (Carol Arm, the 3-hit ring-of-bells, w20)
   ONE READ: three bells stacked into one barrel.
   Build: slimmer barrel than Ding with THREE shallow flares in series (triple-stepped bell, each step a band ring) - the final flare still satisfies the law; amber dot deep in the final bore; tin ring + serial. ARM_L: shoulder at origin, extends -Z (own mesh - no engine mirror). ~600-900 tris.
3. carillon_cadets_arm_peal - ARM_R, RARE (Peal Cannon, the charge shot, w30 spd1)
   ONE READ: a siege bell braced for the big ring.
   Build: the longest barrel + widest single flare of the RARE shelf; heavier shoulder ball + layered cuff; brass muzzle ring + cobalt rune line scribed DOWN the barrel length (the RARE rung, and it sells "charge"); deeper bore, amber charge dot. ~800-1100 tris.
4. carillon_cadets_arm_muffle - ARM_R, RARE (Muffle Mitt, the light GUARD parry arm, w14)
   ONE READ: a bell wearing a cushion.
   Build: slim LIGHT limb (it is the featherest Cadet - w14) ending in a bell whose mouth is CAPPED by a cream padded muffle (b.dome seated over the mouth) - the muffle dome is the over-wide terminal mass, so the law still holds while the guard read lands; brass ring at the bell/muffle seam + cobalt rune line; NO emissive anywhere (the bore is capped - a muffled bell is dark; this is the one Cadet that does not glow). ~600-900 tris.
5. carillon_cadets_arm_grandpeal - ARM_L, EPIC (Grand Peal, the crown bell, core-capable, w32)
   ONE READ: a cathedral bell carried as an arm.
   Build: the WIDEST flare of the entire wave; MID-weight limb (spec ruling - the arm is honest, the bell is huge); gold crest ridge (layer) along the barrel top + gold muzzle ring + gold fleck; the EPIC rung: an amethyst charge RING recessed inside the bore with the amber dot at the throat behind it - two lights deep in one dark bore, nothing on the surface; two-tone blocking + off-white cuff. ARM_L, shoulder at origin. Top of band, ~900-1400 tris.
6. carillon_cadets_back_bellows - BACK, RARE (Bellows Pack, the energy pack, w12 energy 9)
   ONE READ: two bell-metal drums strapped to the back.
   Build: twin stacked round canisters (two horizontal cerulean drums, one above the other, deep-tone saddle between) with band rings; brass rings + cobalt rune line across the upper drum; bolt cluster on the mount plate. NO emissive (the bore-only rule means packs are dark). Mount face at origin, drums extend -Y. ~600-900 tris.

CONTACT SHEET (before touching Larkabout): all 6 to G:\ClaudeData\tmp\claude\manabit-contact\wave2_carillon_sheet.png (same format). Verify: every arm passes the r_mouth >= 1.4x check by EYE at 64px (the flare must be unmistakable); no glow outside a bore; the two-tone blocking reads as one family. Run the cerulean collision check: render next to chatterbox and errant bits at 64-128px - if Carillon smears into either, darken base to #2380B8 (never toward navy) and re-render. Also run vs everykit (dome + brow band + NO visor slit vs everykit's boxy visor; two-tone blue vs red-grey).

======================================================================
BATCH 3 - LARKABOUT SKYWORKS (7 bits) - RISK: HIGH, golden-example protocol MANDATORY
======================================================================

This is the historical-miss shape class (sphere builds blob out, crest angles get fumbled - the wave-1 agents missed this silhouette half the time). Protocol: HAND-BUILD ONE golden example first (bit 1, Larkcrest Dome), iterate it until it unmistakably reads, then LOCK the family constants at the top of the batch script and reuse them verbatim in the other six:
    CREST_SWEEP_DEG = 30.0        # fixed back-sweep for every crest fin, both heads + the pod fins
    EYE_SCRIBE = (...)            # the locked eye scribe positions + sizes from the golden head
    BOOT_FLARE = 1.55             # r_mouth / r_ankle for every boot bell (lock the real value at bit 5)
Only after the golden example passes its 160px render do you batch the rest.

FAMILY VISUAL SYSTEM (spec section: FAMILY 2):
- SILHOUETTE LAW: CAPSULES ONLY - every armor mass is a sphere, dome, or sphere-capped cylinder; a box ANYWHERE on the armor fails review (boxes only as dark frame/joint fillers); boots MUST flare into bell nozzles.
- PALETTE: base warm porcelain cream #EAD9B0 (the only cream-BASED family), trim candy-scarlet #D8342E (gloves, boots, belt - cream body with scarlet EXTREMITIES, never a red body: that blocking is what separates it from boldheart/tinbox which share the hex), cap glossy warm near-black #3A2A1E (the swept crest), microglow amber #FFB347. High-gloss porcelain enamel.
- EMISSIVE DISCIPLINE: the family glow lives at the chest heart-hatch and the boot-heel nozzle throats. NO torso bit ships this wave, so the ONLY live emissives are the LEG heel throats (bits 5 and 6) - the first family whose glow lives at the LEGS. Heads get tiny literal-amber eye glints (painted, NOT emissive). Arms and the back pack stay dark (back pods = folded wings, engines at rest, throats unlit).
- RARITY LADDER (the hatch rungs belong to future torso bits - express the ladder on rims, crests, and runes this wave): COMMON = tin boot-bell/crest rims + dark serial; RARE = brass rims + a cobalt rune line; EPIC = gold rims + amethyst rune + gold fleck.
- GREEBLES: dome, fin x2 mirrored at CREST_SWEEP_DEG, nozzle (heel throats only get emissive), scribe (eyes, hatch lines), bolt sparingly.
- ADJACENCY GUARD: vs tinbox (stamped-tin huggable wind-up) and pocketful (chibi big-head) - Larkabout is heroic-proportioned, glossy, aerodynamic; crests + bell boots differentiate.
- TRI BUDGET: 500-1500 per bit (sphere-heavy; uvsphere segments 8 / rings 5 keeps it in band).

1. larkabout_skyworks_head_larkcrest - HEAD, COMMON (Larkcrest Dome, the light fast jab head, w7) - THE GOLDEN EXAMPLE
   ONE READ: a friendly egg with swept lark fins.
   Build BY HAND, iterate: smooth cream b.dome skull (spend segments here - the dome must read porcelain-smooth, not faceted); TWO mirrored near-black feather-tin crest fins (b.fin + b.mirror) at EXACTLY CREST_SWEEP_DEG back-sweep - this angle is the whole family read, do not eyeball it per-bit; cream face with two BIG friendly dark scribe eyes + tiny amber glint dots (painted amber, not emissive); NO jaw box, no visor. Tin crest rims + dark serial behind the crest. Neck at origin, socket=(0,0,0). ~500-800 tris. When it passes at 160px, write the three constants down and only then continue.
2. larkabout_skyworks_head_swoopcrest - HEAD, RARE (Swoop-Crest Helm, the SPD called-shot head, w10)
   ONE READ: the same lark leaning into a dive.
   Build: golden-head DNA with a LONGER, deeper crest pair (same CREST_SWEEP_DEG - bigger fins, same angle); a slight brow overhang (dome overlap) so the face reads focused; eyes re-scribed narrower from EYE_SCRIBE; brass crest rims + a cobalt rune line along each fin. ~600-900 tris.
3. larkabout_skyworks_arm_catchhand - ARM_R, COMMON (Catch-Hand Mitt, the feather catch, w6)
   ONE READ: an open hand waiting to catch.
   Build: slim sphere-capped cream capsule arm; oversized rounded scarlet glove with an OPEN, upturned cupped palm (fused-mitt dome, hollowed with a shallow vent_cut - the catch gesture is the silhouette); cream wrist ring; tin + serial. No glow anywhere. Shoulder at origin, extends -Z. ~500-800 tris. Weight 6 - keep it visibly slight.
4. larkabout_skyworks_arm_haymaker - ARM_L, RARE (Sunup Haymaker, the honest nuke, w28)
   ONE READ: a cartoon haymaker mid-windup.
   Build: the family's one BIG mass - sphere shoulder, capsule arm, the biggest closed rounded scarlet glove FIST of the wave, cocked slightly back (rotate the fist mass, static wind-up read); brass wrist ring + a cobalt rune arc scribed across the glove's back. Still capsules only - the fist is a squashed sphere, not a box. ARM_L, shoulder at origin. ~700-1100 tris.
5. larkabout_skyworks_legs_rocketboot - LEGS, RARE (Rocketboot Striders, the aggressive legs, w24 spd6) - LOCK BOOT_FLARE HERE
   ONE READ: rocket bell boots ready to jump.
   Build ONE leg + b.mirror: slim cream capsule thigh into a flared scarlet bell boot (flare ratio = BOOT_FLARE, locked here for the family - target ~1.5-1.6, wide enough to be unmistakable at 64px); b.nozzle recessed in the heel with the throat painted amber EMISSIVE (the family's sanctioned leg-glow); brass boot rims + a cobalt rune ring on one boot. Hips at origin, legs extend -Z. ~700-1100 tris.
6. larkabout_skyworks_legs_contrail - LEGS, EPIC (Contrail Boots, the glass rocket, w16 spd8)
   ONE READ: two contrails wearing boots.
   Build: the slimmest thighs of the wave (glass - let the fragility show) into TALLER boot bells with an extended double flare (bell over bell, outer skirt at BOOT_FLARE, inner bell deeper); BOTH heel throats lit (larger emissive throat than Rocketboot - this is the settle-last coffer beat); gold rims + an amethyst rune line down each boot + gold fleck. ~800-1200 tris.
7. larkabout_skyworks_back_updraft - BACK, RARE (Updraft Satchel, the passive mobility pack, w12)
   ONE READ: a courier's satchel with folded rocket wings.
   Build: a rounded cream capsule satchel body (courier-bag read - scribe the flap line, one bolt as the clasp) with TWIN teardrop scarlet jet pods (sphere-capped capsules tapering aft, b.mirror), each with a small swept fin at CREST_SWEEP_DEG + an aft bell nozzle; pods angled slightly down-and-in = the folded-wing stance; throats UNLIT (engines at rest - the family glow stays at the heels); brass pod rims + cobalt rune on the flap. Mount face at origin, pack extends -Y. ~700-1100 tris.

CONTACT SHEET: all 7 to G:\ClaudeData\tmp\claude\manabit-contact\wave2_larkabout_sheet.png (same format). Verify: ZERO boxes on armor; every crest/pod fin at the locked sweep; boots flare at the locked ratio; cream-body-scarlet-extremity blocking (if a bit reads red-bodied, it fails). Run BOTH adjacency pairs at 64-128px: vs tinbox (tinbox_* renders) and vs pocketful - Larkabout must read heroic + glossy + aerodynamic next to both.

======================================================================
ICON PASS (after each family's meshes pass their sheet - same session, per family)
======================================================================
Per bit, render the card icon to <ROOT>\art\icons\<id>.png exactly as the existing 80: 128x128, TRANSPARENT background (scene film_transparent = True), auto-framed (fit the camera to the mesh AABB with ~10 percent margin - same 3/4 hero angle as the 440px look renders), 3-point rig, Standard view transform. The card hook is already live (part_card.gd falls back to a SubViewport thumbnail until the png exists) - icons are optional but this wave ships them. 20 pngs total. Do not rename; <id>.png must match the glb id.

======================================================================
DELIVERY + MAIN-PC ACCEPTANCE
======================================================================
Report per bit: the finalize res dict (tris/materials/warnings) + the 440px and 160px render paths + which family constants it consumed. The glbs land at <ROOT>\art\bits\ and icons at <ROOT>\art\icons\ in that checkout; sync to the main PC at G:\ClaudeApps\manabit\art\bits\ and G:\ClaudeApps\manabit\art\icons\ (Syncthing covers this - verify arrival, do not assume). Also deliver the lib diff (2 ops + 3 FAMILY rows) back to the main PC's tools\art\manabit_bit_lib.py so the checkouts do not fork.

Main-PC acceptance (run these, parse the output yourself - do not accept a "looks good" claim):
    cd "G:\ClaudeApps\manabit"; & "G:\Godot\Godot_v4.7-stable_win64_console.exe" --headless --path G:\ClaudeApps\manabit --import
    cd "G:\ClaudeApps\manabit"; & "G:\Godot\Godot_v4.7-stable_win64_console.exe" --headless --path G:\ClaudeApps\manabit -s "res://tests/smoke_art.gd"
smoke_art iterates Catalog.all() - the 20 wave-2 catalog rows are already merged, so the denominator is ALREADY 100: today it reports coverage 80/100 (absent bits are not failures, they fall back to the procedural composite). The audit per present bit enforces tris 300-2400, <=2 draws, atlas <=256px, envelope <=1.8, origin-on-socket. Expected tail when the full batch lands:
    coverage: 100/100 real bits (100.0%)   off-spec: 0
    ART AUDIT PASS
Partial drops are fine and safe - each synced glb lights up alone; the expectation per drop is present-count rises and off-spec stays 0. After the final sync, re-run the full 14-gate set (smoke_catalog is untouched by mesh work but house rules say re-run everything) and report gate tails verbatim. Then a windowed stage look: equip one bit per family in the Workshop and confirm the family palette on the real mesh matches what FamilyPalette was tinting the fallback - the two must feel like the same family, sharper.
----------------------------------------------------------------------
