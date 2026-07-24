# manabit_bit_lib.py -- the MANABIT bit-authoring backbone (runs INSIDE Blender via blender-mcp).
#
# Purpose: encode the Art Bible ONCE so every one of the 77 bits is coherent and
# spec-legal by construction. A per-bit "recipe" only describes GEOMETRY + which
# palette role each region wears; this lib enforces everything the owner cares about:
#   * family hue / trim / micro-glow + rarity frame, straight from the Art Bible table
#   * ONE small point-filtered (NEAREST) atlas + ONE material  (draw-call budget)
#   * hex snap-socket collar + amber glow-dot (the shared "one boxset" coherence tell)
#   * LOCAL origin = the socket point  (so ManabitStage.SLOT_POS places it right)
#   * 300-800 tri budget validated before export; glb dropped at res://art/bits/<id>.glb
#
# Built entirely with bmesh / bpy.data (NOT bpy.ops) so it never disturbs the
# selection, active object, or contents of whatever scene is already open.
#
# Usage (inside Blender):
#   exec(open(r"G:\ClaudeAgents\my-game\.claude\manabit\tools\art\manabit_bit_lib.py").read())
#   b = Bit("core_ember", family="baseline", rarity="COMMON", slot="CORE")
#   drum = b.hex(radius=0.42, depth=0.62);            b.paint(drum, "base")
#   ...build regions, b.paint(each, <role>)...
#   b.socket_collar(at=(0,0,-0.31))     # hex ring + amber glow-dot at the plug point
#   res = b.finalize(socket=(0,0,0))    # origin->socket, atlas bake, validate, export, clean up
#
# ponytail: flat per-region palette texels (real tiny atlas, gives the PS1 affine-warp
# surface + emissive mask, 1 material). Painted per-face rune/serial pixel detail and a
# true UV-unwrapped albedo are the v2 upgrade -- add when a bit needs texel art beyond flat.

import bpy, bmesh, math, os, struct
from mathutils import Vector, Matrix

BITS_DIR = r"G:\ClaudeAgents\my-game\.claude\manabit\art\bits"
_BUILD_COLL = "MANABIT_BUILD"
_TAG = "manabit_region"          # custom prop marking objects this lib owns

# ---------------------------------------------------------------- spec data
# All hexes verbatim from design/art/art-bible.md (the family palette table) + the
# rarity ladder + affinity soul-glow + shared neutrals. Keyed by family id used in
# parts/catalog_extra.json ("family") and the 13 hardcoded fixtures -> "baseline".

NEUTRAL = {
    "worn_tin": "#C9C3B4", "cream": "#EAD9B0", "walnut": "#6B4A2F",
    "tin_frame": "#AEB6B8", "brass": "#B08D57", "runed_gold": "#C9A24E",
    "cobalt": "#4A90D9", "amethyst": "#B857C9", "amber": "#FFB347",
    "dark_etch": "#2A211B", "gold_fleck": "#E8C87E",
}
AFFINITY = {"attack": "#C05A3E", "defense": "#5A7A9A", "mana": "#3FA890"}  # ember-rust / slate-blue / flux-teal
# Colors that are metal-plated (chrome/gold/brass/silver/tin) -> rendered glossy+metallic so they
# POP like real gunpla plating instead of reading as flat tan. Plastic colors stay matte.
METAL = {"#B08D57", "#C9A24E", "#E8C87E", "#C9CCD6", "#AEB6B8", "#C9C3B4"}
RARITY = {  # frame material + rune-light color (NEVER a hue swap, NEVER foil)
    "COMMON": {"frame": "#AEB6B8", "rune": None},
    "RARE":   {"frame": "#B08D57", "rune": "#4A90D9"},
    "EPIC":   {"frame": "#C9A24E", "rune": "#B857C9"},
}
# family -> named roles. base/trim/cap are plastic; microglow is the always-on emissive
# family signature. Cores also expose affinity lens colors via AFFINITY above.
FAMILY = {
    "baseline":          {"base": "#C9C3B4", "trim": "#6B4A2F", "cap": "#EAD9B0", "microglow": "#FFB347"},
    "artificer_first":   {"base": "#C9C3B4", "trim": "#6B4A2F", "cap": "#EAD9B0", "microglow": "#FFB347"},
    "everykit_standard": {"base": "#C1443A", "trim": "#7A7E82", "cap": "#E4DED0", "microglow": "#FFB347"},
    "boldheart":         {"base": "#D8342E", "trim": "#E8C87E", "cap": "#E8C87E", "microglow": "#FF8A3D"},
    "grumble_co":        {"base": "#E0A82E", "trim": "#4A4E52", "cap": "#4A4E52", "microglow": "#FFB347"},
    "whirligig":         {"base": "#2FA7A0", "trim": "#E8EDEA", "cap": "#E8EDEA", "microglow": "#4FD6E8"},
    "thicket_fang":      {"base": "#5E7B3E", "trim": "#E4D9B8", "cap": "#E4D9B8", "microglow": "#8FD46B"},
    "silksteel":         {"base": "#A98FD0", "trim": "#C9CCD6", "cap": "#C9CCD6", "microglow": "#D857C9"},
    "pith_sinew":        {"base": "#D98A6E", "trim": "#E88AA0", "cap": "#E88AA0", "microglow": "#FF7DA0"},
    "quivergear":        {"base": "#6E7346", "trim": "#E07B2E", "cap": "#E07B2E", "microglow": "#FFB347"},
    "errant":            {"base": "#3A5AA8", "trim": "#B08D57", "cap": "#B08D57", "microglow": "#E8C87E"},
    "cobble_sons":       {"base": "#C57A3E", "trim": "#7A7E82", "cap": "#7A7E82", "microglow": "#6FCF97"},
    "chatterbox":        {"base": "#8FC4E8", "trim": "#E8EDEA", "cap": "#E8EDEA", "microglow": "#6FB8E8"},
    "sovereign_brass":   {"base": "#B08D57", "trim": "#E4DED0", "cap": "#E4DED0", "microglow": "#E8C87E"},
    "tinbox":            {"base": "#D8342E", "trim": "#C9C3B4", "cap": "#C9C3B4", "microglow": "#FFB347"},
    "pocketful":         {"base": "#E88AA0", "trim": "#E8EDEA", "cap": "#E8EDEA", "microglow": "#FFE0A0"},
}

TRI_MIN, TRI_MAX = 300, 2400   # raised from PS1-strict 800: gunpla-esque paneling + greebles + edge
                               # bevels need the headroom. Detailed cores/heroes land ~1500-2200;
                               # simple bits stay ~500-900. Assembled 6-bit Manabit ~8-13k tris, trivial.

# ---------------------------------------------------------------- color helpers
def _hex_rgb(s):
    s = s.lstrip("#")
    return tuple(int(s[i:i+2], 16) / 255.0 for i in (0, 2, 4))  # sRGB 0..1

def _srgb_to_lin(c):
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4

def _resolve(family, role):
    """role -> '#RRGGBB'. Accepts a literal hex, a family role, a NEUTRAL/AFFINITY name,
    or 'frame'/'rune' (rarity-driven; caller passes rarity via Bit)."""
    if isinstance(role, str) and role.startswith("#"):
        return role
    fam = FAMILY.get(family, FAMILY["baseline"])
    if role in fam:      return fam[role]
    if role in NEUTRAL:  return NEUTRAL[role]
    if role in AFFINITY: return AFFINITY[role]
    raise KeyError("unknown palette role %r for family %r" % (role, family))

# ---------------------------------------------------------------- scene isolation
def _build_collection():
    c = bpy.data.collections.get(_BUILD_COLL)
    if c is None:
        c = bpy.data.collections.new(_BUILD_COLL)
        bpy.context.scene.collection.children.link(c)
    return c

def _purge_build():
    """Remove only objects this lib owns; never touch the user's scene objects."""
    for o in list(bpy.data.objects):
        if o.get(_TAG):
            m = o.data
            bpy.data.objects.remove(o, do_unlink=True)
            if m and m.users == 0:
                bpy.data.meshes.remove(m)

# ---------------------------------------------------------------- the Bit builder
class Bit:
    def __init__(self, bit_id, family="baseline", rarity="COMMON", slot="CORE"):
        self.id = bit_id
        self.family = family if family in FAMILY else "baseline"
        self.rarity = rarity if rarity in RARITY else "COMMON"
        self.slot = slot
        self.regions = []            # list of bpy objects, each carries ["_role_hex"], ["_emit"]
        _purge_build()               # fresh start each build
        self.coll = _build_collection()

    # -- primitive region builders (bmesh -> object, linked to our collection) ---
    def _obj(self, name, bm):
        me = bpy.data.meshes.new(name)
        bm.to_mesh(me); bm.free()
        o = bpy.data.objects.new(name, me)
        o[_TAG] = 1
        self.coll.objects.link(o)
        self.regions.append(o)
        return o

    @staticmethod
    def _place(bm, rot, at):
        """CREATE-then-TRANSFORM: rotate about the primitive's own center, THEN translate
        to `at`. rot = (rx,ry,rz) in degrees. This keeps `at` the final center regardless
        of rotation (the lib's guard against the rotate-about-world-origin footgun)."""
        if rot and any(rot):
            import mathutils as _mu
            R = (_mu.Euler((math.radians(rot[0]), math.radians(rot[1]), math.radians(rot[2])), 'XYZ')
                 .to_matrix().to_4x4())
            bmesh.ops.transform(bm, matrix=R, verts=bm.verts)
        if any(at):
            bmesh.ops.translate(bm, vec=at, verts=bm.verts)

    def box(self, sx, sy, sz, at=(0, 0, 0), rot=(0, 0, 0), name="box"):
        bm = bmesh.new()
        bmesh.ops.create_cube(bm, size=1.0)
        bmesh.ops.scale(bm, vec=(sx, sy, sz), verts=bm.verts)
        self._place(bm, rot, at)
        return self._obj(name, bm)

    def cyl(self, radius, depth, segments=8, at=(0, 0, 0), rot=(0, 0, 0), name="cyl"):
        bm = bmesh.new()
        bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False,
                              segments=segments, radius1=radius, radius2=radius, depth=depth)
        self._place(bm, rot, at)
        return self._obj(name, bm)

    def hex(self, radius, depth, at=(0, 0, 0), rot=(0, 0, 0), name="hex"):
        return self.cyl(radius, depth, segments=6, at=at, rot=rot, name=name)

    def cone(self, r_bottom, r_top, depth, segments=8, at=(0, 0, 0), rot=(0, 0, 0), name="cone"):
        bm = bmesh.new()
        bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False,
                              segments=segments, radius1=r_bottom, radius2=r_top, depth=depth)
        self._place(bm, rot, at)
        return self._obj(name, bm)

    def uvsphere(self, radius, segments=6, rings=4, at=(0, 0, 0), rot=(0, 0, 0), name="sph"):
        bm = bmesh.new()
        bmesh.ops.create_uvsphere(bm, u_segments=segments, v_segments=rings, radius=radius)
        self._place(bm, rot, at)
        return self._obj(name, bm)

    def mirror(self, obj, axis="x"):
        """Symmetry the kit way: build ONE side, mirror it -- never hand-place L+R. Copies the
        source region's palette tag. Use for arms (L/R), legs, ribs, wings, any bilateral bit."""
        idx = {"x": 0, "y": 1, "z": 2}[axis]
        bm = bmesh.new(); bm.from_mesh(obj.data)
        S = Matrix.Diagonal([(-1.0 if i == idx else 1.0) for i in range(3)]).to_4x4()
        bmesh.ops.transform(bm, matrix=S, verts=bm.verts)
        bmesh.ops.reverse_faces(bm, faces=bm.faces)          # restore outward normals after mirror
        new = self._obj(obj.name + "_m", bm)
        if "_role_hex" in obj:
            new["_role_hex"] = obj["_role_hex"]; new["_emit"] = obj["_emit"]
        return new

    def bevel(self, obj, width=0.02, segments=1):
        """Chamfer edges -- adds the chunky toy-plastic read and lifts tri count into budget."""
        bm = bmesh.new(); bm.from_mesh(obj.data)
        bmesh.ops.bevel(bm, geom=bm.edges[:] + bm.verts[:], offset=width,
                        segments=segments, affect="EDGES", clamp_overlap=True)
        bm.to_mesh(obj.data); bm.free()
        return obj

    # -- GUNPLA DETAIL VOCABULARY (greebles: what makes a block read as a model kit) ----
    def nozzle(self, at=(0, 0, 0), r_out=0.10, r_in=0.07, depth=0.14, rot=(0, 0, 0), name="nozzle"):
        """Thruster/booster bell: a flared cone with a recessed dark throat. Returns the bell
        (caller paints its plastic role); the throat is auto-painted dark. Axis = +Z before rot."""
        bell = self.cone(r_in, r_out, depth, segments=10, at=at, rot=rot, name=name)
        self.bevel(bell, 0.012, 1)
        throat = self.cyl(r_in * 0.82, depth * 0.7, segments=10, at=at, rot=rot, name=name + "_throat")
        self.paint(throat, "dark_etch")
        return bell

    def bolt(self, at=(0, 0, 0), r=0.03, h=0.03, rot=(0, 0, 0), name="bolt"):
        """Rivet / bolt-head nub (hex). Caller paints; defaults look right as 'trim' or 'frame'."""
        return self.cyl(r, h, segments=6, at=at, rot=rot, name=name)

    def fin(self, w=0.10, h=0.30, t=0.04, at=(0, 0, 0), rot=(0, 0, 0), name="fin"):
        """Antenna / vane / vent fin: a thin tapered blade. Returns obj (caller paints)."""
        f = self.cone(w, w * 0.25, h, segments=4, at=at, rot=rot, name=name)   # 4-seg = flat blade
        return f

    def scribe(self, length=0.3, width=0.03, at=(0, 0, 0), rot=(0, 0, 0), name="scribe"):
        """Panel LINE: a thin dark strip that sits proud of a surface. Auto-painted dark_etch.
        Lay several across a big flat plate to break it up into panels (the #1 anti-swatch move)."""
        s = self.box(length, width, 0.012, at=at, rot=rot, name=name)
        self.paint(s, "dark_etch")
        return s

    def layer(self, sx, sy, sz, at=(0, 0, 0), rot=(0, 0, 0), bev=0.02, name="plate"):
        """Layered armor plate: a beveled thin slab offset proud of a base surface. The overlap +
        chamfer = the 'stacked plastic armor' read. Returns obj (caller paints)."""
        p = self.box(sx, sy, sz, at=at, rot=rot, name=name)
        self.bevel(p, bev, 1)
        return p

    def vent_cut(self, target, at=(0, 0, 0), size=(0.2, 0.05, 0.1), rot=(0, 0, 0)):
        """Boolean-DIFFERENCE a slot/vent out of a region object (bracket.py pattern, EXACT solver).
        Recessed grooves read as intakes/panel gaps. Cleans up the cutter. Mutates `target` in place."""
        cutter = self.box(size[0], size[1], size[2], at=at, rot=rot, name="__cut")
        self.regions.remove(cutter)                 # cutter is temp, not a region
        m = target.modifiers.new("cut", 'BOOLEAN'); m.operation = 'DIFFERENCE'
        m.solver = 'EXACT'; m.object = cutter
        bpy.context.view_layer.objects.active = target
        for o in bpy.context.selected_objects: o.select_set(False)
        target.select_set(True)
        bpy.ops.object.modifier_apply(modifier=m.name)
        d = cutter.data; bpy.data.objects.remove(cutter, do_unlink=True)
        if d.users == 0: bpy.data.meshes.remove(d)
        return target

    # -- palette assignment -----------------------------------------------------
    def paint(self, obj, role, emissive=None):
        """Tag a region with a palette color. role: family role / neutral / affinity / literal hex.
        emissive defaults to True for lens/glow/rune/affinity roles."""
        hexv = self._role_hex(role)
        if emissive is None:
            emissive = role in ("glow", "microglow", "rune") or role in AFFINITY or role in AFFINITY.values()
        obj["_role_hex"] = hexv
        obj["_emit"] = bool(emissive)
        return obj

    def _role_hex(self, role):
        if role == "frame":
            return RARITY[self.rarity]["frame"]
        if role == "rune":
            r = RARITY[self.rarity]["rune"]
            return r if r else NEUTRAL["dark_etch"]   # COMMON: dark unlit stamped serial
        return _resolve(self.family, role)

    # -- the shared coherence tell ---------------------------------------------
    def socket_collar(self, at=(0, 0, 0), radius=0.22, height=0.06):
        """Chamfered hex snap-socket collar (frame material) + one amber glow-dot at the
        plug point. EVERY bit carries this -- it is what makes mixed-family builds read as
        one toy. Returns (collar, dot)."""
        collar = self.hex(radius=radius, depth=height, at=at, name="collar")
        self.bevel(collar, width=0.015, segments=1)
        self.paint(collar, "frame", emissive=False)
        # small FLUSH glow-dot (a flat disc, not a sphere): a big glowing knob on top of an
        # arm reads as a HEAD. Keep it subtle -- it's a plug indicator, not a sensor eye.
        dot = self.cyl(radius=radius * 0.30, depth=height * 0.5, segments=8,
                       at=(at[0], at[1], at[2] + height * 0.4), name="glowdot")
        self.paint(dot, "amber", emissive=True)
        return collar, dot

    # -- finish: atlas bake -> join -> origin -> validate -> export -------------
    def finalize(self, socket=(0, 0, 0), atlas_px=16, cleanup=True,
                 bevel=0.01, bevel_seg=1, smooth_angle=50):
        assert self.regions, "no regions built"
        # 0. any region left unpainted -> default to family base (forgiving, not a crash)
        unpainted = 0
        for o in self.regions:
            if "_role_hex" not in o:
                o["_role_hex"] = _resolve(self.family, "base"); o["_emit"] = False
                unpainted += 1
        # 1. unique palette of (hex, emissive)
        palette, index = [], {}
        for o in self.regions:
            key = (o["_role_hex"], bool(o["_emit"]))
            if key not in index:
                index[key] = len(palette); palette.append(key)
        assert len(palette) <= atlas_px * atlas_px, "too many colors for %dx%d atlas" % (atlas_px, atlas_px)

        # 2. albedo + emission palette images (sRGB, NEAREST-sampled at texel centers)
        alb = _make_palette_image(self.id + "_alb", atlas_px, palette, emission=False)
        emi = _make_palette_image(self.id + "_emi", atlas_px, palette, emission=True)
        spec = _make_spec_image(self.id + "_spec", atlas_px, palette)   # metalness+roughness
        any_emit = any(e for _, e in palette)

        # 3. write each region's UVs to its color's texel center (flat per-region)
        for o in self.regions:
            idx = index[(o["_role_hex"], bool(o["_emit"]))]
            u = (idx % atlas_px + 0.5) / atlas_px
            v = (idx // atlas_px + 0.5) / atlas_px
            me = o.data
            uvl = me.uv_layers.new(name="atlas") if not me.uv_layers else me.uv_layers[0]
            for loop in me.loops:
                uvl.data[loop.index].uv = (u, v)

        # 4. join all regions into one mesh via bmesh (no ops, no selection side effects)
        merged = bmesh.new()
        for o in self.regions:
            merged.from_mesh(o.data)
        bmesh.ops.recalc_face_normals(merged, faces=merged.faces)
        # GLOBAL EDGE BEVEL: universal chamfer so every part's edges catch light like
        # injection-molded plastic (the #1 anti-flat-swatch move). Each region is its own
        # shell, so this bevels each part independently; UVs (flat per region) carry through.
        if bevel and bevel > 0:
            bmesh.ops.bevel(merged, geom=merged.edges[:] + merged.verts[:], offset=bevel,
                            segments=bevel_seg, affect="EDGES", clamp_overlap=True)
        bmesh.ops.triangulate(merged, faces=merged.faces)   # honest tri count, no ngons
        final_me = bpy.data.meshes.new(self.id)
        merged.to_mesh(final_me); merged.free()   # UVs (layer "atlas") flow through from_mesh

        obj = bpy.data.objects.new(self.id, final_me)
        obj[_TAG] = 1
        self.coll.objects.link(obj)

        # crisp plastic shading: smooth-by-angle keeps big faces flat but rounds the bevel
        # chamfers into highlight edges; weighted-normal cleans it. Both apply on export.
        for p in final_me.polygons:
            p.use_smooth = True
        for o in list(bpy.context.selected_objects):
            o.select_set(False)
        obj.select_set(True); bpy.context.view_layer.objects.active = obj
        try:
            bpy.ops.object.shade_auto_smooth(angle=math.radians(smooth_angle))
        except Exception:
            pass
        wn = obj.modifiers.new("wn", "WEIGHTED_NORMAL")
        wn.keep_sharp = True; wn.weight = 50; wn.mode = "FACE_AREA"

        # 5. one material: NEAREST palette atlas. Name it per-bit (NOT a shared "mana_glow") so
        # building many bits in one Blender session doesn't clobber earlier bits' materials.
        mat = _atlas_material(self.id + "_mat", alb, emi if any_emit else None, spec)
        final_me.materials.append(mat)

        # 6. origin -> socket point (mesh authored so socket sits at Blender world origin,
        #    then we shift so the given socket coord becomes local (0,0,0))
        off = Vector(socket)
        final_me.transform(Matrix.Translation(-off))

        # 7. validate tri budget
        tris = sum((len(p.vertices) - 2) for p in final_me.polygons)
        dims = tuple(round(d, 3) for d in obj.dimensions)

        # 8. remove the source regions, keep only the merged obj for export
        for o in list(self.regions):
            m = o.data
            bpy.data.objects.remove(o, do_unlink=True)
            if m.users == 0:
                bpy.data.meshes.remove(m)
        self.regions = []

        os.makedirs(BITS_DIR, exist_ok=True)
        out = os.path.join(BITS_DIR, self.id + ".glb")
        _export_glb(obj, out)

        if cleanup:
            m = obj.data
            bpy.data.objects.remove(obj, do_unlink=True)
            if m.users == 0:
                bpy.data.meshes.remove(m)

        ok = TRI_MIN <= tris <= TRI_MAX
        warns = []
        if not ok:
            warns.append("tris %d outside %d-%d" % (tris, TRI_MIN, TRI_MAX))
        if unpainted:
            warns.append("%d region(s) left unpainted -> defaulted to base" % unpainted)
        return {"id": self.id, "glb": out, "tris": tris, "in_budget": ok,
                "materials": 1, "atlas_px": atlas_px, "colors": len(palette),
                "dimensions": dims, "emissive": any_emit, "warnings": warns}

# ---------------------------------------------------------------- module helpers
def _make_palette_image(name, px, palette, emission):
    img = bpy.data.images.get(name)
    if img:
        bpy.data.images.remove(img)
    img = bpy.data.images.new(name, width=px, height=px, alpha=True)
    img.colorspace_settings.name = "sRGB"
    # Store RAW sRGB hex values and tag the image sRGB: Blender does the single
    # sRGB->linear at shade time, and the exported PNG is sRGB (correct for glTF
    # baseColor/emissive textures, both sRGB). Do NOT pre-linearize here or the
    # color gets darkened twice.
    pixels = [0.0] * (px * px * 4)
    for i, (hexv, emit) in enumerate(palette):
        r, g, b = _hex_rgb(hexv)
        if emission and not emit:
            r = g = b = 0.0
        base = i * 4
        pixels[base + 0] = r
        pixels[base + 1] = g
        pixels[base + 2] = b
        pixels[base + 3] = 1.0
    img.pixels[:] = pixels
    img.pack()
    return img

def _make_spec_image(name, px, palette):
    """Metalness (R) + roughness (G) per palette color. Metal-plated colors -> metallic + glossy;
    everything else -> matte dielectric. Non-Color data map."""
    img = bpy.data.images.get(name)
    if img:
        bpy.data.images.remove(img)
    img = bpy.data.images.new(name, width=px, height=px, alpha=True)
    img.colorspace_settings.name = "Non-Color"
    pixels = [0.0] * (px * px * 4)
    for i, (hexv, emit) in enumerate(palette):
        gloss = (not emit) and (hexv.upper() in METAL)
        base = i * 4
        # glTF metallicRoughness layout: G = roughness, B = metallic. Enchanted-TOY look = GLOSSY
        # plastic-gold (bright color + sharp highlight), NOT dark realistic metal: low metallic,
        # low roughness on plated colors; matte plastic everywhere else.
        pixels[base + 1] = 0.25 if gloss else 0.82   # G roughness (glossy vs matte)
        pixels[base + 2] = 0.2 if gloss else 0.0     # B metallic (subtle sheen, keeps color bright)
        pixels[base + 3] = 1.0
    img.pixels[:] = pixels
    img.pack()
    return img

def _atlas_material(name, alb_img, emi_img, spec_img=None):
    mat = bpy.data.materials.get(name)
    if mat:
        bpy.data.materials.remove(mat)
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    for n in list(nt.nodes):
        nt.nodes.remove(n)
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.inputs["Roughness"].default_value = 0.85
    bsdf.inputs["Metallic"].default_value = 0.0
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = alb_img
    tex.interpolation = "Closest"          # -> glTF sampler NEAREST on export
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    if emi_img is not None:
        et = nt.nodes.new("ShaderNodeTexImage")
        et.image = emi_img
        et.interpolation = "Closest"
        nt.links.new(et.outputs["Color"], bsdf.inputs["Emission Color"])
        bsdf.inputs["Emission Strength"].default_value = 1.8   # PS1 mana-glow bloom
    if spec_img is not None:
        st = nt.nodes.new("ShaderNodeTexImage")
        st.image = spec_img
        st.interpolation = "Closest"
        st.image.colorspace_settings.name = "Non-Color"
        sep = nt.nodes.new("ShaderNodeSeparateColor")
        nt.links.new(st.outputs["Color"], sep.inputs["Color"])
        nt.links.new(sep.outputs["Blue"], bsdf.inputs["Metallic"])    # B=metallic (glTF), metal colors pop
        nt.links.new(sep.outputs["Green"], bsdf.inputs["Roughness"])  # G=roughness, glossy metal vs matte plastic
    nt.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    return mat

def _export_glb(obj, path):
    # select only our object; export_scene.gltf is the one bpy.ops we must use, scoped
    # to use_selection so nothing else in the user's scene is written.
    for o in bpy.context.selected_objects:
        o.select_set(False)
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.export_scene.gltf(
        filepath=path, export_format="GLB", use_selection=True,
        export_apply=True, export_yup=True, export_texcoords=True,
        export_normals=True, export_materials="EXPORT",
    )
