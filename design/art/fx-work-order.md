RULING FIRST, HONESTLY: combat feel does NOT need Blender. No rigs, no skeletons, no animation clips - the entire motion language is transforms, lights, and overlays on the existing 80 glbs, and the killed items (slash arc, mend swirl, debris sets, pose packs, shield dome) stay killed. This pack is OPTIONAL POLISH: four tiny fiction props that genuinely beat procedural geometry (a brass socket stub, a chunky burst star, a hex shockwave ring, a single loose peg mote). The game ships fully working with an empty art/fx dir - every spawn_fx call is exists-gated with a procedural 2D fallback. If you fire up the second PC, hand everything below the line to the Blender-MCP session verbatim.

----------------------------------------------------------------------
MANABIT FX PACK v1 (merged studio order - 4 items) - for blender-mcp

SESSION SETUP (once). ROOT = the folder on THIS machine that contains tools\art\manabit_bit_lib.py. The lib's baked default says the last-known checkout here is G:\ClaudeAgents\my-game\.claude\manabit - VERIFY that path exists first; if the checkout moved, substitute the real root everywhere below.
    exec(open(ROOT + r"\tools\art\manabit_bit_lib.py").read())
    BITS_DIR = ROOT + r"\art\fx"      # NEW dir - deliberately NOT art/bits (bit loader + smoke_art untouched)
    TRI_MIN = 40                       # FX are tiny by design; kills spurious tri warnings
    import math as _m

SHARED RULES: these are EFFECT meshes, not bits - NO socket_collar, no rune, no rarity frame. finalize(socket=(0,0,0), cleanup=False) for every item; inspect res: materials==1, warnings==[], tris inside the item budget. Flat camera-facing items (star, ring) lie in the Blender X-Z plane with thickness ~0.05 along Y (the lib's export_yup lands them facing the Godot stage camera). Glow items paint literal "#FFE8C0" or role "amber" with emissive=True - the engine re-tints per affinity at runtime, the baked warm-white is the fallback look. Physical items (stub, peg) paint neutral roles, NOT emissive. Chunky beveled toy-plastic silhouettes; no spikes-of-doom, no shatter-glass. After each build: EEVEE render with the RECIPE_GUIDE 3-point rig to G:\ClaudeData\tmp\claude\manabit-fx\<id>.png at 440px PLUS one at 160px - if the silhouette does not read at 160px it FAILS (the game renders at 320x240).

ITEM 1 - fx_socket_stub (budget 40-120 tris) - the bare brass peg revealed where a part snapped off.
    b = Bit("fx_socket_stub", family="baseline", rarity="COMMON", slot="CORE")
    peg = b.cyl(radius=0.055, depth=0.10, segments=6, at=(0, 0, 0.02))
    b.bevel(peg, 0.008); b.paint(peg, "brass")
    collar = b.cyl(radius=0.10, depth=0.03, segments=6, at=(0, 0, -0.03))
    b.bevel(collar, 0.006); b.paint(collar, "#E8C87E")
    res = b.finalize(socket=(0,0,0), cleanup=False)

ITEM 2 - fx_impact_star (budget 150-400 tris) - 8-point burst star, alternating long/short flat blades around a hex hub.
    b = Bit("fx_impact_star", family="baseline", rarity="COMMON", slot="CORE")
    hub = b.hex(radius=0.09, depth=0.05, rot=(90, 0, 0))
    b.paint(hub, "#FFE8C0", emissive=True)
    for i in range(8):
        ang = 45.0 * i
        ln = 0.40 if i % 2 == 0 else 0.24
        sp = b.fin(w=0.09, h=ln, t=0.05,
                   at=(_m.sin(_m.radians(ang)) * (ln * 0.5 + 0.08), 0,
                       _m.cos(_m.radians(ang)) * (ln * 0.5 + 0.08)),
                   rot=(0, ang, 0))
        b.paint(sp, "amber", emissive=True)
    res = b.finalize(socket=(0,0,0), cleanup=False)

ITEM 3 - fx_ring_hex (budget 100-300 tris) - hexagonal shockwave ring of 6 beveled bars; it must echo the hex socket-collar language every bit carries. Lengthen the segments until the hex closes.
    b = Bit("fx_ring_hex", family="baseline", rarity="COMMON", slot="CORE")
    for i in range(6):
        ang = 60.0 * i + 30.0
        seg = b.box(0.52, 0.05, 0.08,
                    at=(_m.sin(_m.radians(ang)) * 0.45, 0, _m.cos(_m.radians(ang)) * 0.45),
                    rot=(0, ang + 90.0, 0))
        b.bevel(seg, 0.012)
        b.paint(seg, "amber", emissive=True)
    res = b.finalize(socket=(0,0,0), cleanup=False)

ITEM 4 - fx_loose_peg (budget 40-120 tris) - a single snapped peg-and-washer mote, the chunky piece that tumbles out of a break. NOT emissive - physical, plastic-and-brass.
    b = Bit("fx_loose_peg", family="baseline", rarity="COMMON", slot="CORE")
    head = b.bolt(at=(0, 0, 0.035), r=0.045, h=0.035)
    b.paint(head, "brass")
    shank = b.cyl(radius=0.024, depth=0.08, segments=6, at=(0, 0, -0.02))
    b.paint(shank, "brass")
    washer = b.cyl(radius=0.05, depth=0.012, segments=8, at=(0, 0, -0.065))
    b.paint(washer, "tin_frame")
    res = b.finalize(socket=(0,0,0), cleanup=False)

DELIVERY: report per item the finalize res dict + both render PNG paths. The .glb files land at <ROOT>\art\fx\ in that checkout; sync them to the main PC at G:\ClaudeApps\manabit\art\fx\ (create the dir). Do not rename anything - the engine loads by exact filename. Main-PC acceptance: run the headless --import pass, re-run all gates (smoke_art audits only art/bits by design - run it anyway), then a windowed spar screenshot showing a star/ring frame, eyeballed by a human. Re-parse the res dicts and PNGs yourself - do not accept a "looks good" claim.
----------------------------------------------------------------------