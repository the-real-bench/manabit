extends SceneTree
# Trundle + Binding screenshot harness: bankrow buttons, The Binding panel, a kit run at a Rest.
# Run windowed:  godot --path . --script res://tests/shoot_kit.gd
var _f := 0
var _root: Node

func _initialize() -> void:
	_root = load("res://ui/root.tscn").instantiate()
	get_root().add_child(_root)

func _process(_d: float) -> bool:
	_f += 1
	if _f == 24:
		_root.workshop._toggle_binding_panel()
	if _f == 60:
		_shot("user://kit_binding.png")
	if _f == 66:
		_root.workshop._toggle_binding_panel()
		_root._on_kit_venture()
	if _f == 100:
		_shot("user://kit_run_fight.png")
	if _f == 106:
		_root.run.satchel_scrap = 10        # as if the Skirmish purse landed
		_root.run.advance()                 # move to the first Rest
		_root.run_screen.refresh()
	if _f >= 140:
		_shot("user://kit_run_rest.png")
		print("SHOTS SAVED")
		return true
	return false

func _shot(p: String) -> void:
	get_root().get_texture().get_image().save_png(p)
