# MANABIT - DROP-IN ART PIPELINE (how the owner lands art)

**The gesture:** author `res://art/bits/<id>.glb`, drop it into `res://art/bits/`, reimport in Godot - it renders on the next stage rebuild. No code edits per bit, ever. Until a bit's file exists it falls back to the procedural primitive composite, so the game is never broken. Mirrors the owner's "byte-overwrite landing zone."

## Naming (load-bearing - the loader finds art BY id)
- **Bit mesh:** `res://art/bits/<id>.glb` - `<id>` == `PartData.id` **exactly** (e.g. `boldheart_arm_meteor.glb`, `core_ember.glb`). Atlas embedded (single-file drop). Authored at **LOCAL origin = the socket point** so `ManabitStage.SLOT_POS` + `PartData.socket_offset` still apply.
- **Bit icon (optional):** `res://art/icons/<id>.png` - 128×128, point-filtered.
- **Fettle:** `res://art/portraits/fettle.png` (2D). **Challengers:** none - they're loadouts, they inherit their bits' art.
- **Optional mid-tier fallback:** `res://art/bits/_family_<family>_<slot>.glb` - a per-family generic that beats the primitive before per-bit art exists.
- Ship `res://art/family_map.json` (id→family) so the tinter resolves family without a `PartData` field.

## The one-time code seam (edit once in `ui/manabit_stage.gd::rebuild()`, then never again)
Replace `var bit := _build_bit(...)` with `var bit := _spawn_bit(pi, ...)`. `_spawn_bit` tries `res://art/bits/<id>.glb`, then the `_family_<family>_<slot>.glb` fallback, then the existing procedural composite (UNCHANGED). On a real glb it calls `_apply_soul_glow(inst, glow, awake, is_core)`. ~18 lines total. This is the entire coupling.

## Coupling model (least author burden - bake plastic, let the engine light it)
Ship a plain good-looking plastic bit with family hue + runes + the low-energy family micro-glow baked into the atlas. The **engine** does the affinity lighting:
- spawns a small glowing **socket-collar** node at the bit origin (attack ember-rust `#C05A3E` / defense slate-blue `#5A7A9A` / mana flux-teal `#3FA890`),
- if the glb has a material named **`mana_glow`**, re-tints its emission to the affinity `glow` and toggles it with `awake` (for bodies that glow their affinity from within, e.g. Pith),
- if the glb has a material named **`frame`**, tints it to `Tokens.rarity_frame(rarity)` (tin→brass→gold).
So the author never writes per-bit code and never bakes the affinity color - just name those two materials when relevant.

## Icons (same id fallback, zero code per bit)
`PartCard` renders the bit (real or primitive) to a small SubViewport thumbnail NOW; if `res://art/icons/<id>.png` exists it uses that instead. One `ResourceLoader.exists()` guard = every icon drops in by id.

## Import settings (bake once)
- 3D: glTF sampler **NEAREST**, **mipmaps off**; keep the stage SubViewport 320×240 / `MSAA_DISABLED` / `TEXTURE_FILTER_NEAREST`.
- 2D icons/portraits: Project Settings → Rendering → Textures → Canvas default filter = **Nearest** (or per-import Filter=Nearest, Mipmaps=off) so cards/portraits stay crisp.

## Per-bit budget (what "done" means)
300-800 tris (cores & EPICs ≤~600; chibi Pocketful ≥150) · one point-filtered atlas (128px COMMON/RARE, 256px cores/EPICs), mipmaps off · hex snap-socket collar + glow-dot at LOCAL origin · runes baked as texel detail, never geometry · rarity = material frame + rune-light, never foil/color-only · warm cozy-craft, NOT liminal-horror / circuitry / licensed.

## Validation & "proven"
Run the headless asset-audit after each batch over all 77 `Catalog.all()` ids: per id assert glb present, single material + atlas ≤256px, tris 300-800, socket collar at origin; emit a coverage %. **Pipeline is proven** the moment ANY one real `<id>.glb` renders on the stage with correct soul-glow while the other 76 still fall back to primitives - the zero-code drop confirmed. Target: 100% coverage, primitive composite retained permanently as the safety net.
