# Art landing zone (drop-in - zero code edits)

Real art plugs into the game by **filename convention**. Until an asset exists, the game uses its
built-in procedural placeholder, so you can drop art in one bit at a time.

## Bit meshes (3D)
- Put a low-poly model at **`res://art/bits/<bit_id>.glb`** (e.g. `art/bits/boldheart_arm_meteor.glb`).
- Reimport in Godot. `ui/manabit_stage.gd` instances it in the bit's socket automatically
  (`_build_bit()`), replacing the procedural primitive. No code change.
- Orientation: neutral, origin at the socket attach point (the mesh is placed at the slot's
  `SLOT_POS`); keep it roughly within a ~1-unit envelope. ~300-800 tris, point-filtered chunky texture.

## Bit icons (2D card art)
- Put a small texture at **`res://art/icons/<bit_id>.png`**.
- `ui/part_card.gd` shows it at the top of that bit's card automatically (nearest-filtered).

## Ids
- Bit ids are the `id` field in `parts/catalog.gd` (base fixtures) and `parts/catalog_extra.json`
  (the 64 team bits). See `design/art/asset-manifest.md` (generated) for the full list + per-bit
  generation prompts and the production priority order.

## Fettle / challengers / UI
- Fettle is currently a drawn automaton (`ui/fettle_portrait.gd`); challengers reuse bit meshes via
  their loadouts, so they light up for free as bit art lands. See the manifest for their specs.
