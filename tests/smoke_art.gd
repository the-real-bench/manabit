extends SceneTree
# Art asset-audit gate (manifest "Validation & proven"): over every Catalog bit id, if a
# real res://art/bits/<id>.glb exists, assert it is spec-legal -- tris 300-2400, <=2 draw
# calls (1 material + optional emissive), atlas <=256px, and the LOCAL origin (the socket
# point) lies on the mesh. Absent bits are NOT failures (they fall back to the procedural
# primitive); only a PRESENT-but-off-spec bit fails. Emits a coverage %.
#
# Run headless:  godot --headless --path . --script res://tests/smoke_art.gd

func _initialize() -> void:
	var all := Catalog.all()
	var total := all.size()
	var present := 0
	var fails := 0
	print("MANABIT art asset-audit  (", total, " catalog bits)")
	for pd in all:
		var id := String(pd.id)
		var path := "res://art/bits/%s.glb" % id
		if not ResourceLoader.exists(path):
			continue
		present += 1
		var scene = load(path)
		if scene == null or not (scene is PackedScene):
			print("  [FAIL] %-28s glb will not load" % id); fails += 1; continue
		var inst = scene.instantiate()
		var tris := 0
		var surfaces := 0
		var max_tex := 0
		var aabb := AABB()
		var seen := false
		for mi in _meshes(inst):
			var mesh: Mesh = mi.mesh
			if mesh == null:
				continue
			tris += mesh.get_faces().size() / 3
			surfaces += mesh.get_surface_count()
			for s in mesh.get_surface_count():
				var mat = mesh.surface_get_material(s)
				if mat is BaseMaterial3D and mat.albedo_texture != null:
					max_tex = max(max_tex, mat.albedo_texture.get_width())
			var a: AABB = mi.transform * mesh.get_aabb()
			aabb = a if not seen else aabb.merge(a)
			seen = true
		inst.free()

		var longest: float = max(aabb.size.x, max(aabb.size.y, aabb.size.z))
		var ok_tris := tris >= 300 and tris <= 2400   # raised from 800: gunpla-esque detail budget
		var ok_draw := surfaces >= 1 and surfaces <= 2
		var ok_tex := max_tex <= 256
		var ok_env := seen and longest <= 1.8
		var ok_origin := seen and aabb.grow(0.05).has_point(Vector3.ZERO)  # socket point on the mesh
		var ok := ok_tris and ok_draw and ok_tex and ok_env and ok_origin
		if not ok:
			fails += 1
		var flags := ""
		if not ok_tris: flags += " tris=%d!" % tris
		if not ok_draw: flags += " draws=%d!" % surfaces
		if not ok_tex: flags += " atlas=%dpx!" % max_tex
		if not ok_env: flags += " env=%.2f!" % longest
		if not ok_origin: flags += " origin-off-socket!"
		print("  [%s] %-28s tris=%-4d draws=%d atlas=%dpx env=%.2f%s" %
			["PASS" if ok else "FAIL", id, tris, surfaces, max_tex, longest, flags])

	var pct := 0.0 if total == 0 else 100.0 * present / total
	print("coverage: %d/%d real bits (%.1f%%)   off-spec: %d" % [present, total, pct, fails])
	# "Pipeline proven" = at least one real bit is present and every present bit is spec-legal.
	# --- coffer faces stay inside the palette (L-08) ---
	# The brass lid gem shipped at #7be1ff: hue 194, value 1.00 - matching no
	# DESIGN.md token and brighter than every one of them, on an entirely warm screen.
	# The identity line is "soft mana-glow, NOT cyber-circuitry". Cool pixels are
	# allowed - a mana seal should read cool against brass - but they must sit in the
	# teal band the palette actually defines (--affinity-mana #3FA890 hue 168,
	# Glimmer #3FD0C0 hue 172) and must not outshine every token in it.
	var coffer_ok := true
	for face in ["brass", "tin"]:
		var fimg := Image.new()
		if fimg.load("res://art/props/coffer_face_%s.png" % face) != OK:
			print("  [FAIL] coffer face %s loads" % face)
			coffer_ok = false
			continue
		var offspec := 0
		var worst := ""
		for y in fimg.get_height():
			for x in fimg.get_width():
				var c := fimg.get_pixel(x, y)
				if c.a < 0.5 or c.b <= c.r + 0.10:
					continue
				var hue_deg := c.h * 360.0
				if hue_deg < 155.0 or hue_deg > 190.0 or c.v > 0.85:
					offspec += 1
					if worst == "":
						worst = "  first #%s h%.0f v%.2f at %d,%d" % [c.to_html(false), hue_deg, c.v, x, y]
		print("  [%s] coffer face %s: %d off-palette cool pixels%s" % ["PASS" if offspec == 0 else "FAIL", face, offspec, worst])
		coffer_ok = coffer_ok and offspec == 0

	var proven := present >= 1 and fails == 0 and coffer_ok
	print("ART AUDIT PASS" if proven else "ART AUDIT FAIL")
	quit(0 if proven else 1)

func _meshes(n: Node) -> Array:
	var out := []
	if n is MeshInstance3D:
		out.append(n)
	for c in n.get_children():
		out.append_array(_meshes(c))
	return out
