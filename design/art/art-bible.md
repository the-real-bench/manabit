# MANABIT - ART BIBLE (the spec every one of the 77 bits obeys)

## 0. The lock (one line, non-negotiable)
Every bit is an **etched-rune PLASTIC toy component** - PS1 rendering technique (chunky ~300-800 tris, point-filtered pixel textures, 320×240 upscale) + cozy-craft tone (warm/collectible palette, soft mana-glow at sockets/cores). Read target: *"a toy that happens to be enchanted,"* NOT liminal-horror, NOT cyber-circuitry, NOT licensed. A player must be able to name the slot from the silhouette alone.

## 1. PALETTE SYSTEM (how a bit gets its colors)
Three independent color channels, so a mixed-family build never turns to mud. All values live/extend `ui/tokens.gd`.

**Channel A - FAMILY HUE (identity, baked into the atlas).** Each family owns one signature plastic base + one trim. Never pure black (`< #2A211B`) or clinical white (`> #EAD9B0`) - same value gamut as the room so bits sit in it.

**Channel B - RARITY (frame material + rune accent, per DESIGN.md §1; a texel/material detail, NEVER a hue swap, NEVER foil).** COMMON = worn tin `#AEB6B8`, no rune. RARE = brass `#B08D57` + cobalt `#4A90D9` rune-light. EPIC = runed-wood/gold `#C9A24E` + amethyst `#B857C9` rune + gold flecks.

**Channel C - MANA-GLOW (two layers).** (1) *Soul-glow* = the build-wide affinity glow the engine paints at the CORE + socket collars, tinted by `Tokens.affinity_color()` (attack `#C05A3E` / defense `#5A7A9A` / mana `#3FA890`), only when a core is seated (core-wake). (2) *Family micro-glow* = a small always-on emissive texel accent baked into the atlas; defaults to warm amber `#FFB347`, with 5 deliberate signature overrides so the standouts read: **Whirligig cyan `#4FD6E8`, Thicket leaf-green `#8FD46B`, Silksteel magenta `#D857C9`, Pith rose-from-within `#FF7DA0`, Chatterbox sky-blue `#6FB8E8`.** All other families keep warm amber so the room stays coherent.

**FAMILY PALETTE TABLE (base / trim / micro-glow / finish / silhouette / rune-style):**
| Family | Base | Trim | Micro-glow | Finish | Silhouette | Rune |
|---|---|---|---|---|---|---|
| baseline (13 fixtures) | tin `#C9C3B4` / cream `#EAD9B0` | walnut `#6B4A2F` | amber | matte | plain boxy | plain stamped serial |
| everykit_standard | red `#C1443A` | grey `#7A7E82`+off-white `#E4DED0` | amber | matte | boxy humanoid | serial glyphs |
| boldheart | candy-red `#D8342E` | chrome-gold `#E8C87E` | hot orange `#FF8A3D` | gloss | V-hero, huge shoulders | heraldic "courage" |
| grumble_co | safety-yellow `#E0A82E` | gunmetal `#4A4E52` | deep seam-amber | matte | wide low trapezoid | riveted load-rating |
| whirligig | teal `#2FA7A0` | white `#E8EDEA` | **cyan `#4FD6E8`** | gloss | aero wedge | swift aero glyphs |
| thicket_fang | moss `#5E7B3E` | bone `#E4D9B8` | **leaf-green `#8FD46B`** | flocked-matte | crouched beast | knotwork/totem |
| silksteel | lavender `#A98FD0` | silver `#C9CCD6` | **magenta `#D857C9`** | pearl-gloss | slim minimal | jeweller filigree |
| pith_sinew | amber-rose resin `#D98A6E` | rose `#E88AA0` | **rose-within `#FF7DA0`** | translucent/subsurface | rounded organic | vein-glyphs in resin |
| quivergear | olive `#6E7346` | safety-orange `#E07B2E` | sequenced amber pips | matte | back-heavy hunch | stencil hazard |
| errant | royal-blue `#3A5AA8` | brass `#B08D57` | gold `#E8C87E` | enamel-satin | upright knight | gilt oath sigils |
| cobble_sons | worn-orange `#C57A3E` | grey `#7A7E82` | tool-green `#6FCF97` | matte-scuffed | stocky utility | measure/mend marks |
| chatterbox | sky-blue `#8FC4E8` | white `#E8EDEA` | **soft-blue `#6FB8E8`** | gloss | round pod-on-legs | dotted chatter |
| sovereign_brass | brass `#B08D57` | cream enamel `#E4DED0` | grand gold `#E8C87E` | polished-gloss | broad symmetric obelisk | deco filigree |
| tinbox | primary-red `#D8342E` (+blue/yellow) | tin `#C9C3B4` | amber dot | stamped-tin satin | rounded retro | big printed glyph |
| pocketful | candy-pink `#E88AA0` (per-capsule) | white | sparkle `#FFE0A0` | candy-gloss | big-head/tiny-body chibi | one big belly glyph |

*Family lookup:* `catalog_extra.json` carries `family`; the 13 hardcoded fixtures have none → map them to **baseline**. Add a tiny `res://art/family_map.json` (id → family) OR a `Catalog.family_of(id)` helper so the material tinter can find the family without touching `PartData`.

## 2. MATERIAL + MANA-GLOW RULES
- **Plastic:** matte-to-satin ABS. `StandardMaterial3D`: `metallic=0`, `roughness≈0.85` (matte families) / `≈0.55` + small `specular` bump (gloss/pearl/candy families); Pith gets `subsurf_scatter` + `rim` + emission-from-within. Keep per-vertex/flat lighting (matches the existing `DirectionalLight3D` + ambient rig in `manabit_stage.gd`). One material per bit.
- **Soul-glow:** emissive, engine-added, `emission_energy` core ≈0.5 / socket-collar ≈1.2-1.4 (mirrors current `_mat()` emit values), **on only when awake**.
- **Micro-glow:** baked emissive channel in the atlas, low energy (~0.3), always on - the rune-light/eye-slit that carries the family signature hue.
- **Rarity frame:** a trim material on the bit's frame edges; tint from `Tokens.rarity_frame()`, rune-light from `Tokens.rarity_accent()`. Never a shader shine - it's a colored edge + an etched rune that lights.

## 3. ETCHED-RUNE TEXEL MOTIF
Runes are **baked into the low-res albedo as dark etched insets** (+ an emissive-masked light-line for RARE/EPIC) - texture detail, never geometry (period-correct PS1). Bold and few: a rune stroke must be ≥2 on-screen texels at the 320×240 render. **Rune density scales with rarity:** COMMON = 1 small stamped serial (dark, unlit); RARE = a rune line that lights cobalt; EPIC = a full family rune motif that lights amethyst + gold fleck. Rune STYLE per family (see table col 7) - this is a second, quieter identity cue behind hue+silhouette.

## 4. SILHOUETTE + READABILITY
- Each family owns a silhouette archetype (table col 6). One dominant shape + ≤2 secondary shapes per bit. **No thin filigree geometry** - fine detail goes in texture.
- Reads at ~64px tall in the 320×240 viewport. The **slot must be legible from silhouette** (HEAD reads as head, ARM as arm) - the socket-rig UX depends on it.
- **The coherence anchor (shared by ALL 77 bits):** every bit exposes an obvious **hex snap-socket collar** where it plugs in - a small chamfered brass/tin ring + a glow-dot. This one shared tell is what makes a Boldheart-arm + Chatterbox-legs build read as one toy instead of a bug.

## 5. BUDGETS + IMPORT
- **Tris:** 300-800/part; cores & EPIC heroes up to ~600, pocketful/chibi ~150-300. Assembled Manabit (6 bits) ≤ ~3,500 tris.
- **Atlas:** ONE per bit - **128×128 default**, **256×256 for cores + EPICs**. RGBA, point-filtered, no mipmaps (or 1). Emissive lives as a mask channel on the SAME atlas → 1 material → ~1 draw call/bit (≤6 + glow per Manabit). The shared family palette keeps atlases tiny.
- **Import (Godot 4.7):** glTF sampler `magFilter/minFilter = NEAREST`, mipmaps off, sRGB albedo. The 320×240 SubViewport (already `TEXTURE_FILTER_NEAREST`) handles the chunky upscale; the nearest atlas sampler stops texture smoothing - you need BOTH.

## 6. COHERENCE ACROSS 15 FAMILIES (the "one boxset" rule)
SHARED (never varies): snap-socket collar + glow-dot · etched-rune-as-texel · matte/satin plastic family · rarity frame trio · affinity soul-glow · 300-800 tri / 128px point-filter budget · the low-res render. DISTINCT (the only knobs): family hue · silhouette archetype · rune style · (5 families) signature micro-glow. That's the whole system: same manufacturing language, different figures.

## 7. CHARACTER & ASSEMBLED READS (spec notes)
- **Fettle (automaton shopkeep, the first Manabit):** currently `ui/fettle_portrait.gd` (2D `_draw`: brass cabinet, forge-belly, loupe-eye, wind-up key). KEEP him 2D UI chrome (he never battles) - upgrade to a painted-but-point-filtered portrait `res://art/portraits/fettle.png` matching the cozy palette. He is **sovereign_brass-family cues + EPIC frame** (venerable, runed-wood/gold + amethyst), glow = **warm amber, affinity-neutral** (he's not wagered). He must read as *made of bits* but older/venerable than anything the player builds.
- **The 5 challengers (Scrap-Pup → Cogsworth → … → Brassmore):** each is a real assembled Manabit → renders through the SAME stage/pipeline; NO bespoke meshes needed beyond their equipped bits. Give each a signature family bias so they read as characters: Scrap-Pup = cobble/tinbox scrappy underdog; Cogsworth = errant/sovereign clockwork knight; **Brassmore (boss) = sovereign_brass, +~10% scale, EPIC frame on every bit.** Identity = loadout + name chip + core color, not new art.
- **Assembled-Manabit read:** mixed-family builds are EXPECTED (the whole game). Unity comes from (a) shared socket collars visually stitching parts, (b) the affinity soul-glow unifying the color story, (c) consistent scale. A broken part falls off (already implemented) - the stump should show a **dark socket + a faint sad glow-out**, not a clean hole.