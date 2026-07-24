extends SceneTree
# Screenshot harness: captures every screen to user:// for visual review.
# Run windowed:  godot --path . --script res://tests/shoot.gd
var _f := 0
var _root: Node
var _shots: Array = []   # [frame, name, callable]

func _initialize() -> void:
	_root = load("res://ui/root.tscn").instantiate()
	get_root().add_child(_root)
	_shots = [
		[24, "", func(): _root.workshop.demo_varied()],
		[60, "workshop", func(): pass],
		[66, "", func(): _root.goto_chest()],
		[100, "coffer_nook", func(): pass],
		[106, "", func(): _root.goto_broker()],
		[140, "barrow", func(): pass],
		[146, "", func(): _root.goto_menagerie()],
		[180, "menagerie", func(): pass],
		[186, "", func(): _root.goto_compendium()],
		[220, "compendium", func(): pass],
		[226, "", func(): _root.goto_proving()],
		[260, "proving", func(): pass],
	]

func _process(_d: float) -> bool:
	_f += 1
	for s in _shots:
		if _f == int(s[0]):
			(s[2] as Callable).call()
			if String(s[1]) != "":
				_shot("user://shot_%s.png" % s[1])
	if _f >= 266:
		print("SHOTS SAVED")
		return true
	return false

func _shot(p: String) -> void:
	get_root().get_texture().get_image().save_png(p)
