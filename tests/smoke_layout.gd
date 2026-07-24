extends SceneTree
# Layout gate: the Workshop's 1280x720 budget has ZERO slack, so any new row, taller font,
# or padding lands as an invisible regression without this.
# Budget re-pinned 2026-07-18 (workshop-calm-onboarding spec): the toolbar row + tray panel
# merged into ONE two-state drawer assembly (50px lip / 216px lip+well, separation 0), so
# the gate now asserts BOTH configurations:
#   old:        top 44 / stage 380 / bank 44 / toolbar 44 / tray 166 + 4x6 sep = 702 min
#   new CLOSED: top 44 / stage 380 / bank 44 / drawer lip 50        + 3x6 sep = 536 min
#   new OPEN:   top 44 / stage 380 / bank 44 / drawer 216 (50+166)  + 3x6 sep = 702 min
# Both must sit under the 704 pin with every control in-frame, the stage (the ONE expander)
# must render >= 380, and the Work-Order Tag must never intersect the CORE medallion.

var _f := 0
var _shop: WorkshopScreen
var _holder: Control
var _ok := true

func _initialize() -> void:
	_holder = Control.new()
	_holder.custom_minimum_size = Vector2(1280, 720)
	_holder.size = Vector2(1280, 720)
	get_root().add_child(_holder)
	var p := PlayerState.new()
	p.grant_starter_kit()        # binds_total == 0 + spare starter cores -> tag T1 is alive
	p.scrap = 999999             # renders as the capped '9999+'
	p.coffers = {"tin": 9, "brass": 9}   # renders as 'x9+'
	_shop = WorkshopScreen.new().setup(p)
	_shop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_holder.add_child(_shop)

func _process(_d: float) -> bool:
	_f += 1
	if _f == 2:
		# both ratified no-core note variants stay under the 72-char cap; pin the longer
		var n_spare := "Seat a mana core to wake it - one waits in your drawer."
		var n_bind := "Seat a mana core to wake it - tap here to bind one (⚙60)."
		_check("spare-core note <= 72 chars", n_spare.length() <= 72)
		_check("bind-core note <= 72 chars", n_bind.length() <= 72)
		_shop._set_note(n_bind, Tokens.LAMP_KEY, WorkshopScreen.NoteAct.BINDING)
	if _f == 4:
		_config("CLOSED", 536.0)
		_shop._set_drawer(true, false)   # instant, no slide - re-pin the OPEN config
	if _f < 6:
		return false
	_config("OPEN", 702.0)
	print("SMOKE PASS" if _ok else "SMOKE FAIL")
	quit(0 if _ok else 1)
	return true

func _config(cfg: String, expect_min: float) -> void:
	var rows := {"top": _shop._top_row, "bank": _shop._bank_row}
	for k in rows:
		var r: HBoxContainer = rows[k]
		if r == null:
			_check(cfg + " row missing: " + String(k), false)
			continue
		_check("%s %s row min width %.0f <= 1248" % [cfg, k, r.get_combined_minimum_size().x],
			r.get_combined_minimum_size().x <= 1248.0)
	if _shop._drawer_open:
		# the open lip hosts the toolbar (anchored inside the lip Button, so its min never
		# propagates to the row - measure it directly)
		var lw := _shop._lip_open.get_combined_minimum_size().x
		_check("%s lip toolbar min width %.0f <= 1232" % [cfg, lw], lw <= 1232.0)
	var vh := 0.0
	for c in _shop.get_children():
		if c is VBoxContainer:
			vh = (c as VBoxContainer).get_combined_minimum_size().y
			break
	_check("%s root stack min height %.0f == %.0f" % [cfg, vh, expect_min], absf(vh - expect_min) <= 1.0)
	_check("%s root stack min height %.0f <= 704" % [cfg, vh], vh <= 704.0)
	_check("%s stage renders %.0f >= 380" % [cfg, _shop._stage_area.size.y], _shop._stage_area.size.y >= 380.0)
	var frame := Rect2(Vector2.ZERO, Vector2(1281, 721))   # 1px grace for float rounding
	var bad := _first_escapee(_shop, frame)
	_check("%s every control inside 1280x720%s" % [cfg, "" if bad == "" else (" - escapee: " + bad)], bad == "")
	# the Work-Order Tag (T1 on this fresh kit) never covers the CORE medallion
	var tag: Control = _shop._tag
	var core: Control = _shop.slot_fields["CORE"]
	_check(cfg + " Work-Order Tag visible (T1)", tag != null and tag.visible)
	if tag != null and core != null:
		_check(cfg + " tag does not intersect the CORE medallion",
			not tag.get_global_rect().intersects(core.get_global_rect()))

func _check(label: String, cond: bool) -> void:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	_ok = _ok and cond

func _first_escapee(node: Control, frame: Rect2) -> String:
	if not node.visible:
		return ""   # a hidden subtree (closed drawer well, tucked toolbar) renders nothing
	var r := node.get_global_rect()
	# ignore zero-size helpers and transient overlays
	if r.size.x > 2.0 and r.size.y > 2.0 and not frame.encloses(r):
		return "%s at %s" % [node.name if node.name != "" else node.get_class(), str(r)]
	for c in node.get_children():
		if c is Control:
			var hit := _first_escapee(c, frame)
			if hit != "":
				return hit
	return ""
