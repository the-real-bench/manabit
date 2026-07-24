extends SceneTree
# Calm/onboarding screenshot harness: empty-rest (Work-Order Tag T1, drawer closed),
# CORE-filtered open drawer, built open, built closed-rest.
# Run windowed:  godot --path . --script res://tests/shoot_calm.gd
# In-memory only - never calls save(), the real user:// save is untouched.
var _f := 0
var _root: Node

func _initialize() -> void:
	_root = load("res://ui/root.tscn").instantiate()
	get_root().add_child(_root)

func _process(_d: float) -> bool:
	_f += 1
	if _f == 6:
		# force the fresh-maker read regardless of the machine's real save
		var p: PlayerState = _root.player
		p.binds_total = 0
		var has_core := false
		for pi in p.bits:
			if pi.data.is_core:
				has_core = true
		if not has_core:
			p.bits.append(PartInstance.new(Catalog.starter_cores()[0]))
		_root.workshop.clear_build()
	if _f == 40:
		_shot("user://calm_empty_rest.png")
	if _f == 46:
		_root.workshop._on_slot_tapped("CORE")   # the tag path: medallion lights, drawer opens filtered
	if _f == 80:
		_shot("user://calm_core_open.png")
	if _f == 86:
		_root.workshop._on_filter_chip("")       # clear the filter, drawer stays open
		_root.workshop.demo_fill()
	if _f == 120:
		_shot("user://calm_built_open.png")
	if _f == 126:
		_root.workshop._set_drawer(false)
	if _f >= 160:
		_shot("user://calm_built_closed.png")
		print("SHOTS SAVED")
		return true
	return false

func _shot(p: String) -> void:
	get_root().get_texture().get_image().save_png(p)
