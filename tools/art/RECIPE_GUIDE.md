# MANABIT bit-authoring recipe guide

How a manifest **prompt** becomes a spec-legal `res://art/bits/<id>.glb`. This is the
brief the `manabit-bits` workflow hands each builder agent, and the how-to for authoring
a bit by hand. Engine: **blender-mcp procedural** (Blender 5.1, no external service).

The library (`tools/art/manabit_bit_lib.py`) already encodes the whole Art Bible - family
palette, rarity ladder, single 1-material NEAREST atlas, hex socket collar, origin=socket,
tri validation, glb export. **You only write GEOMETRY + which palette role each region wears.**
The lib guarantees coherence across all 77 bits ("one boxset").

## The loop (never one-shot)
1. **Read the bit's manifest entry** in `design/art/asset-manifest.md` (Spec + Prompt lines):
   its `id`, `family`, `slot`, `rarity`, silhouette, and which parts glow.
2. **Build** the recipe in Blender (see API + example below), `finalize(cleanup=False)`.
3. **Inspect** - `res["tris"]` in 300-800, `res["materials"]==1`, `res["warnings"]==[]`.
4. **Look** - render EEVEE from a 3/4 front angle; confirm the silhouette reads as the SLOT
   (a head reads as a head), the family hue is right, the glowing part actually glows.
5. **Fix** the worst problem, repeat. Then it's already exported to `art/bits/<id>.glb`.

## GUNPLA DETAIL - the whole point (read before every build)
These are **gunpla-esque enchanted toys**, NOT flat blocks. A bit that reads as a solid-color
box has FAILED even if the audit passes. Grounded in `G:\Git\blender-modeling-kit\docs\MODELING.md`
§2-3 (inset panels, boolean cuts, bevel + weighted normals). The lib's `finalize` already bevels
every edge + applies weighted normals (crisp injection-molded plastic) - your job is DETAIL + COLOR BREAK-UP:
- **Never one big flat plate.** Break every large face with `b.scribe(...)` panel lines and `b.layer(...)`
  stacked armor plates (overlap 2-3, slightly offset, chamfered = layered-armor read).
- **Color break-up:** a real part shows 3-5 colors - armor base + trim + a darker inner-frame at joints
  + a sensor/lens + panel-line darks. Paint sub-parts different roles; don't leave a monochrome block.
- **Greeble the mechanical bits:** `b.nozzle` on anything that thrusts/vents, `b.bolt` clusters on plates,
  `b.fin` for antennae/vanes/heat-fins, `b.vent_cut` for recessed intakes.
- **Joints read as joints:** put a `b.cyl`/`b.uvsphere` in a contrasting "trim" (inner-frame) color at every
  elbow/knee/shoulder/wrist so the armor looks bolted onto a frame (the core gunpla tell).
- **Silhouette:** the outline itself must carry detail - pauldrons, crests, fins, nozzles breaking the profile.
- **Glow:** the sensor eye / core lens / rune is emissive (`emissive=True`); it should read as lit, with a
  contrasting bezel (`cap`) around it. Put emissive parts in a DARK recess/bezel for contrast (amber glow on a
  yellow body is invisible unless recessed in dark gunmetal).
- **ARMS/LEGS ANTI-PATTERN (the #1 failure):** the socket end (top of an arm) is a PLUG, not a sensor. Put NO
  glowing dome/knob/eye/cabochon there - a glowing dot on a collar on top makes the whole arm read as a
  head-on-a-neck (a totem). The only glow on an arm belongs at the END-EFFECTOR (fist/weapon) or a rune on the
  armor. Keep the socket collar small + flush. The FIST/end-effector must be the biggest, most-detailed mass.
Per-slot cues: CORE=reactor dome/window + sunray or bracket fins + vents · HEAD=visor or mono-eye + crest +
antenna + cheek vents · ARM=layered shoulder pauldron + elbow joint + forearm panels + end-effector · LEGS=
thigh armor + knee guard + shin vents + ankle joint + flared foot · BACK=thruster cluster + wings/boosters.

VISUAL REFERENCES (Read 1-2 before building to calibrate the detail bar):
`G:\ClaudeData\tmp\claude\gunpla-refs\01_head_pauldron_core_RX78_statue.jpg` (gundam variety: V-fins, pauldrons, thruster packs, hero colors)
`G:\ClaudeData\tmp\claude\gunpla-refs\03_armor_plates_panelline_sprue.jpg` (surface bar: recessed panel lines + rectangular vent slots + chamfered edges).
Golden built example (matches this bar): `G:\ClaudeData\tmp\claude\manabit-bits\sunheart_v2.png` (candy-red plastic + gold sun-disc + glowing dome + brass bolts + cobalt rune).

## Load the lib (inside Blender, once per session)
```python
exec(open(r"G:\ClaudeAgents\my-game\.claude\manabit\tools\art\manabit_bit_lib.py").read())
```

## API
```python
b = Bit(bit_id, family="baseline", rarity="COMMON", slot="CORE")
# builders (CREATE-then-TRANSFORM: rot rotates about the part's own center, THEN moves to `at`)
b.box(sx, sy, sz, at=(0,0,0), rot=(0,0,0))      # rot in degrees
b.cyl(radius, depth, segments=8, at=..., rot=...)
b.hex(radius, depth, at=..., rot=...)           # 6-sided cyl
b.cone(r_bottom, r_top, depth, segments=8, ...) # taper / drill
b.uvsphere(radius, segments=6, rings=4, ...)
b.bevel(obj, width=0.03, segments=1)            # chamfer -> chunky toy read + lifts tris into budget
b.mirror(obj, axis="x")                          # build ONE side, mirror it (arms L/R, legs, ribs, wings). NEVER hand-place both sides.
# GUNPLA GREEBLES (what turns a block into a model kit - use liberally, this is the whole point):
b.nozzle(at=..., r_out=.10, r_in=.07, depth=.14, rot=...)  # thruster/booster bell + dark throat. Returns bell (paint it); throat auto-dark.
b.bolt(at=..., r=.03, h=.03, rot=...)            # rivet/bolt-head nub (hex). paint "trim"/"frame".
b.fin(w=.10, h=.30, t=.04, at=..., rot=...)      # antenna / vane / vent blade. paint it.
b.scribe(length=.3, width=.03, at=..., rot=...)  # PANEL LINE (auto-dark). Lay several across big flat plates.
b.layer(sx,sy,sz, at=..., rot=..., bev=.02)      # layered armor plate (pre-beveled). paint it. Overlap 2-3 for stacked-armor read.
b.vent_cut(target, at=..., size=(.2,.05,.1), rot=...)  # boolean-cut a recessed vent/gap INTO a region (intakes, panel gaps).
# paint each region with a palette ROLE (resolved from the family, or a literal "#RRGGBB"):
b.paint(obj, "base")        # family plastic base hue
b.paint(obj, "trim")        # family trim
b.paint(obj, "cap")         # family secondary/cap
b.paint(obj, "microglow")   # family always-on emissive signature (auto-emissive)
b.paint(obj, "frame")       # rarity frame: tin(COMMON)/brass(RARE)/gold(EPIC)
b.paint(obj, "rune")        # COMMON->dark unlit serial; RARE->cobalt; EPIC->amethyst (auto-emissive on RARE/EPIC)
b.paint(obj, "attack"|"defense"|"mana", emissive=True)   # affinity soul color (ember-rust/slate-blue/flux-teal)
b.paint(obj, "#RRGGBB", emissive=False)         # literal, when the manifest names a specific color
# the shared coherence tell (EVERY bit): hex collar + amber glow-dot at the plug point
b.socket_collar(at=(0,0,-0.41), radius=0.24, height=0.06)
# finish: origin->socket, atlas bake, validate, export to art/bits/<id>.glb
res = b.finalize(socket=(0,0,0), cleanup=False)  # cleanup=False keeps it in-scene so you can render
```

## Socket origin per slot (author LOCAL origin = the plug point; `finalize(socket=...)` sets it)
The game places the mesh at `SLOT_POS[slot]`, so origin must be where the bit plugs in.
Build the geometry so the plug point sits at Blender world origin, then pass that point as `socket`:
- **CORE** → `socket=(0,0,0)` (build centered; it sits at the build center).
- **HEAD** → neck at the bottom: build with the neck at origin, `socket=(0,0,0)`; body extends +Z.
- **ARM_L / ARM_R** → shoulder at origin; arm extends along -Z (down) or -X.
- **LEGS** → hips at origin (top); legs extend -Z.
- **BACK** → mount face at origin; pack extends -Y (behind).
Keep the whole bit within a **~1-unit envelope** (longest dim ≤ ~1.4).

## Worked example - `core_ember` (CORE, COMMON, baseline) - the golden pattern
```python
b = Bit("core_ember", family="baseline", rarity="COMMON", slot="CORE")
drum = b.hex(radius=0.42, depth=0.60, name="drum"); b.bevel(drum, 0.05); b.paint(drum, "base")   # worn-tin
capT = b.hex(radius=0.40, depth=0.06, at=(0,0,0.31)); b.paint(capT, "cap")     # cream
capB = b.hex(radius=0.40, depth=0.06, at=(0,0,-0.31)); b.paint(capB, "cap")
brk  = b.hex(radius=0.44, depth=0.08, at=(0,0,-0.33)); b.bevel(brk, 0.02); b.paint(brk, "trim")  # walnut
lens = b.cyl(radius=0.17, depth=0.10, segments=12, at=(0,-0.40,0.05), rot=(90,0,0)); b.paint(lens, "attack", emissive=True)  # ember soul
serial = b.box(0.02, 0.14, 0.10, at=(0.40,0.05,0.06)); b.paint(serial, "rune")  # dark stamped serial
b.socket_collar(at=(0,0,-0.41), radius=0.30, height=0.07)
res = b.finalize(socket=(0,0,0), cleanup=False)   # 336 tris, 1 material, ember lens glows
```

## "Done" checklist (the Godot audit `tests/smoke_art.gd` enforces all of these)
- [ ] tris **300-2400** (detailed cores/heroes ~1500-2200; simple bits ~500-900; chibi Pocketful lower)
- [ ] does NOT look like a flat color block - panel lines, layered plates, greebles, 3-5 colors, glowing sensor
- [ ] **1 material**, atlas **≤256px** (the lib's palette atlas is tiny by default)
- [ ] silhouette reads as the **slot** from ~64px; family hue correct; the glowing part glows
- [ ] hex **socket collar + amber glow-dot** present at the plug point
- [ ] LOCAL origin = the socket point (pass the right `socket=` to finalize)
- [ ] tone: warm cozy-craft toy, NOT liminal-horror / circuitry / licensed

## Note on the current engine coupling
The live loader (`ui/manabit_stage.gd::_build_bit`) instances the glb **raw** - it does NOT
re-tint by material name yet. So bake the final look INTO the atlas (family hue + micro-glow +
rarity frame + affinity lens for cores). The lib still NAMES the emissive material `mana_glow`
so the planned `_apply_soul_glow` seam (Art Pipeline doc) works for free if it's added later.

## Render to look (EEVEE + 3-POINT LIGHTING - after finalize with cleanup=False)
CRITICAL: light it properly or you WILL misjudge. A single harsh light makes worn-tin read as
muddy dark grey and the bit "looks like a flat swatch" when it isn't. Use key+fill+rim:
```python
import bpy, math; from mathutils import Vector, Euler
scn=bpy.context.scene; scn.render.engine='BLENDER_EEVEE'; scn.render.resolution_x=scn.render.resolution_y=440
def sun(nm,e,rot):
    d=bpy.data.lights.new(nm,'SUN'); d.energy=e; o=bpy.data.objects.new(nm,d)
    scn.collection.objects.link(o); o.rotation_euler=Euler([math.radians(a) for a in rot],'XYZ')
for nm in ("KEY","FILL","RIM"):
    old=bpy.data.objects.get(nm)
    if old: bpy.data.objects.remove(old,do_unlink=True)
sun("KEY",3.2,(-50,-25,15)); sun("FILL",1.4,(-25,60,-10)); sun("RIM",2.2,(200,10,0))
ol=bpy.data.objects.get("Light")
if ol: ol.data.energy=0.0
scn.world.use_nodes=True; bg=scn.world.node_tree.nodes.get("Background")
if bg: bg.inputs[0].default_value=(0.32,0.33,0.36,1); bg.inputs[1].default_value=0.9
try:
    scn.eevee.use_ssr=True   # screen-space reflections so glossy metal/gold reads shiny
except Exception: pass
cam=bpy.data.objects.get("SHOTCAM") or bpy.data.objects.new("SHOTCAM", bpy.data.cameras.new("SHOTCAM"))
if cam.name not in scn.collection.objects: scn.collection.objects.link(cam)
cam.location=Vector((1.5,-1.9,0.6)); cam.rotation_euler=(Vector((0,0,0))-cam.location).normalized().to_track_quat('-Z','Y').to_euler()
scn.camera=cam; scn.render.filepath=r"G:\ClaudeData\tmp\claude\manabit-bits\<id>.png"; bpy.ops.render.render(write_still=True)
# then Read the PNG. (WORKBENCH shows only silhouette, not atlas colors - use EEVEE for color.)
```
