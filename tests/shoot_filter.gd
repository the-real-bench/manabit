extends SceneTree
# Filter/sort screenshot harness: default toolbar, socket-tap filter, rarity+sort combo.
# Run windowed:  godot --path . --script res://tests/shoot_filter.gd
var _f := 0
var _root: Node

func _initialize() -> void:
	_root = load("res://ui/root.tscn").instantiate()
	get_root().add_child(_root)

func _process(_d: float) -> bool:
	_f += 1
	if _f == 24:
		_root.workshop.demo_varied()
	if _f == 60:
		_shot("user://filter_all.png")
	if _f == 66:
		_root.workshop._on_slot_tapped("HEAD")   # tap a filled socket: unequip + filter to HEAD fits
	if _f == 100:
		_shot("user://filter_head.png")
	if _f == 106:
		_root.workshop._on_filter_chip("")        # clear slot filter
		_root.workshop._on_rarity_selected(3)     # Epic only
		_root.workshop._on_sort_selected(2)       # sort by Weight
		_root.workshop._rarity_opt.select(3)
		_root.workshop._sort_opt.select(2)
	if _f >= 140:
		_shot("user://filter_epic.png")
		print("SHOTS SAVED")
		return true
	return false

func _shot(p: String) -> void:
	get_root().get_texture().get_image().save_png(p)
