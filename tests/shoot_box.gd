extends SceneTree
# Box of Scrap reveal harness: capture a LOW-grade box and a HIGH-grade box to show the range.
var _f := 0
var _root: Node
var _low := -1
var _high := -1

func _initialize() -> void:
	_root = load("res://ui/root.tscn").instantiate()
	get_root().add_child(_root)
	# find a low-grade and a high-grade nonce (deterministic seeds)
	for n in range(0, 600):
		var seed := (n * 2654435761 + 1013904223) & 0x7FFFFFFF
		var g := BoxRoller.grade(seed)
		if _low < 0 and (g == "Dud" or g == "Rough"):
			_low = n
		if _high < 0 and (g == "Gleaming" or g == "Keen"):
			_high = n
	print("low nonce=%d  high nonce=%d" % [_low, _high])

func _process(_d: float) -> bool:
	_f += 1
	if _f == 20:
		_root.player.kit_box_nonce = _low
		_root.workshop._open_box_reveal()
	if _f == 50:
		_shot("user://box_low.png")
		_root.workshop._close_box_reveal()
	if _f == 56:
		_root.player.kit_box_nonce = _high
		_root.workshop._open_box_reveal()
	if _f >= 90:
		_shot("user://box_high.png")
		print("SHOTS SAVED")
		return true
	return false

func _shot(p: String) -> void:
	get_root().get_texture().get_image().save_png(p)
