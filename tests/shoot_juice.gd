extends SceneTree
# Combat-juice screenshot harness. Warms the renderer up FIRST (auto off, nothing moves),
# then toggles Auto at a known t0 so the beat clock is deterministic against JuiceTuning
# (auto scale 0.6): think 120 -> pull-back 120-192 -> thrust 192-234 -> impact 234 (+30 stop)
# -> extension HELD to ~360 -> return -> control ~468. Turn 3 is the hammer break volley.
# Run windowed:  godot --path . -s res://tests/shoot_juice.gd
# Eyeball: attacker rig visibly displaced toward the foe, number held at impact, bar mid-roll
# post-stop, BROKEN!/burst/tumble on the break, guard chip on the foe answer.

var _cs: CombatScreen

func _initialize() -> void:
	Engine.max_fps = 60
	_run()

func _run() -> void:
	await process_frame
	var holder := Control.new()
	holder.size = Vector2(1280, 720)
	get_root().add_child(holder)
	var p := PlayerState.new()
	_cs = CombatScreen.new().setup(p)
	_cs.set_anchors_preset(Control.PRESET_FULL_RECT)
	holder.add_child(_cs)
	await process_frame
	_cs.begin_spar(_fighter())      # auto OFF: sits in choose_move while shaders warm up
	await _wait(1.2)
	await process_frame
	_cs.debug_autostep()            # t0: the deterministic clock starts here
	await _wait(0.200)
	_shot("user://juice_windup.png")       # pull-back, squash
	await _wait(0.048)
	_shot("user://juice_impact.png")       # impact frame: number spawns held, part blip
	await _wait(0.055)
	_shot("user://juice_lunge.png")        # post-stop: rig HELD at extension, bar rolling
	await _wait(0.045)
	_shot("user://juice_recover.png")      # number rising, still extended
	await _wait(0.30)
	_shot("user://juice_aftermath.png")    # returned + settled, log revealed
	await _wait(0.75)
	_shot("user://juice_foe_turn.png")     # foe answer volley (guard chip / their lunge)
	# turn 3 = my second hammer strike: head 4/8 - 4 dmg = the break
	await _wait(0.62)
	_shot("user://juice_break_a.png")
	await _wait(0.16)
	_shot("user://juice_break_b.png")
	await _wait(0.16)
	_shot("user://juice_break_c.png")
	await _wait(0.30)
	_shot("user://juice_break_d.png")
	print("SHOTS SAVED")
	quit(0)

func _wait(s: float) -> void:
	await create_timer(s).timeout

func _fighter() -> ManabitState:
	var cat := Catalog.by_id()
	var m := ManabitState.new()
	m.slots["CORE"] = PartInstance.new(cat["core_ember"])
	m.slots["ARM_R"] = PartInstance.new(cat["arm_hammer"])
	m.slots["HEAD"] = PartInstance.new(cat["head_optic"])
	m.slots["LEGS"] = PartInstance.new(cat["legs_light"])
	return m

func _shot(path: String) -> void:
	get_root().get_texture().get_image().save_png(path)
