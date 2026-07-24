class_name ManabitStage extends Control
# The Stand: a low-res PS1 SubViewport turntable that rebuilds from a BuildSession.
# Inert/dark until a CORE is seated (core-wake); then the whole build glows the core affinity hue.
# Bits are composite low-poly assemblies (chunky, few segments) with brighter mana accents.
#
# Combat-juice plumbing (2026-07-18): scene graph is world -> _rig -> _turntable ->
# [mount(slot) -> visual(slot) -> meshes]. _rig carries ALL whole-toy motion (anticipation,
# lunge, return, brace, jabs) and sits OUTSIDE the drag yaw, so +x is always screen-right no
# matter how the player has spun the toy. mount holds the AABB-snap position (only animated by
# detach); visual is the _build_bit() result at identity under its mount - per-part animation
# tweens the visual and always returns to identity. sync() diffs a composition fingerprint so
# per-hit updates never tear the model down; rebuild(m) keeps its exact signature and behavior
# (force full teardown + rebuild) for workshop/menagerie/run_screen callers.
#
# Workshop reskin (2026-07-18, moves 2+3): hero framing - the toy stands ~HERO_FILL of stage
# height at the 18-deg hero yaw, seen from a slightly LOW camera; a world-space felt-and-brass
# display plinth + a warm lamp pool ground it. highlight_slot(slot, on) is the move-3 hover
# seam: per-slot overlay rim in --glow-base amber, never touching shared glb materials.

static var SLOT_POS := {
    "CORE": Vector3(0, 0, 0),
    "HEAD": Vector3(0, 1.15, 0),
    "ARM_L": Vector3(-1.05, 0.05, 0),
    "ARM_R": Vector3(1.05, 0.05, 0),
    "LEGS": Vector3(0, -1.15, 0),
    "BACK": Vector3(0, 0.1, -0.55),
}

const KEY_LIGHT_REST := 1.15
const AMBIENT_REST := 0.5
const SOUL_REST := 1.2
const LAMP_POOL_REST := 2.0     # the warm lamp pool spot behind/above the stand
const HERO_FILL := 0.75         # hero framing: the toy stands ~75% of stage height (70-80 band)
const HERO_TILT_DEG := 6.0      # slightly LOW hero camera - up-tilt, mirrors the old 6-deg down
const CROP_MARGIN := 0.25       # crop-clamp margin (world units): toy + margin always fits
const HERO_MIN_DIST := 2.4      # camera floor - tiny/partial builds (dormant cavity) never blob the lens; full builds (~3.25) frame past it untouched
const HIGHLIGHT_A := 0.32       # move-3 hover rim alpha - selection-only amber, never ambient
const DORMANT_DIM := 0.55       # calm spec 4.1: ember lamp - key/lamp dim to ~0.55 while no core
const REST_YAW_DEG := 18.0      # the hero yaw the turntable starts at (calm 4.2 compensates it)
const PLINTH_FELT_H := 0.05     # felt pad thickness on the display stand
const PLINTH_BASE_H := 0.14     # brass drum height under the felt
const PLINTH_RIM_LIP := 0.05    # brass rim peeking past the felt edge
const PLINTH_LAYER := 2         # render layer for the stand: the soul light excludes it so the
                                # core's glow never pools on the felt (still lit by key/rim/lamp)
const DORMANT_FLOAT := 0.25     # the empty core socket + its ring HOVER this far above the felt
                                # (no legs to stand on - the cavity floats where the soul will go)
const SIGIL_SPIN := TAU / 60.0  # one full sweep per minute - the backdrop reads as a turn timer
const FX_DIR := "res://art/fx/"
const FX_CAP := 6

var _svp: SubViewport
var _world: Node3D                  # SubViewport world root (plinth + furniture live here)
var _rig: Node3D                    # whole-toy motion carrier (outside the drag yaw)
var _turntable: Node3D
var _fx3d: Node3D                   # persistent 3D fx layer, mirrors the turntable yaw
var _rect: TextureRect
var _cam: Camera3D
var _key_light: DirectionalLight3D
var _env: Environment
var _soul: OmniLight3D = null       # the awake core's light, spilling onto the inner faces
var _lamp: SpotLight3D = null       # warm lamp pool behind/above the stand (furniture light)
var _plinth: Node3D = null          # felt display stand + brass rim, world-space furniture
var _sigil: Node3D = null           # mana power-sigil backdrop (on _rig, not the turntable - it never yaws)
var _drag := false          # owner rule: the toy NEVER rotates on its own - drag to turn it
var _spin_vel := 0.0        # release inertia (deg/s), decays exp(-3.2 dt), killed by a new press
var _awake := false
var _ground_y := 0.0        # turntable offset that plants the feet on the shelf line
var _bob_t := 0.0
var _cavity_rim: MeshInstance3D = null   # amber mouth-ring on the dormant cavity (calm 4.4)
var _dormant_pulse := false              # workshop-owned: on ONLY during tag T1/T2

# combat plumbing state
var _mounts := {}           # slot -> Node3D mount (stable handle at the AABB-snap position)
var _visuals := {}          # slot -> Node3D visual (identity under its mount)
var _comp := {}             # composition fingerprint (bit ids + __awake; HP excluded)
var _flash_mats := {}       # slot -> per-slot overlay StandardMaterial3D (never shared glb mats)
var _hl_tweens := {}        # slot -> active move-3 highlight fade tween
var _hl_on := {}            # slot -> true while the move-3 hover rim is held
var _slot_tweens := {}      # slot -> active per-part tween
var _rig_tween: Tween = null
var _cam_rest := Transform3D.IDENTITY
var _framing_locked := false    # combat seam: HOLD the camera between rebuilds (see lock_framing)
var _cam_framed := false        # true once the hero framing has run since the last lock re-arm
var debug_rebuild_count := 0

static var _ab_cache := {}  # bit id -> measured local AABB (geometry per id is constant)

func _ready() -> void:
    _svp = SubViewport.new()
    _svp.size = Vector2i(320, 240)
    _svp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    _svp.msaa_3d = Viewport.MSAA_DISABLED
    # OWN World3D per stage: without this every stage shares the main world, so in combat both
    # fighters (and stray dormant-cavity core-runes from other stages) render at the world
    # origin superimposed - "manabits sit overtop one another." Each stage renders ONLY its toy.
    _svp.own_world_3d = true
    add_child(_svp)

    var world := Node3D.new()
    _svp.add_child(world)
    _world = world

    var env := WorldEnvironment.new()
    var e := Environment.new()
    e.background_mode = Environment.BG_COLOR
    e.background_color = Tokens.FELT_TEAL.darkened(0.4)
    e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    e.ambient_light_color = Tokens.LAMP_KEY
    e.ambient_light_energy = AMBIENT_REST
    env.environment = e
    _env = e
    world.add_child(env)

    var light := DirectionalLight3D.new()
    light.rotation_degrees = Vector3(-52, -40, 0)
    light.light_color = Tokens.LAMP_KEY
    light.light_energy = KEY_LIGHT_REST
    _key_light = light
    world.add_child(light)

    # Rim light: separates the connected silhouette from the felt at 240p.
    var rim := DirectionalLight3D.new()
    rim.rotation_degrees = Vector3(30, 140, 0)
    rim.light_color = Tokens.FELT_TEAL.lightened(0.5)
    rim.light_energy = 0.35
    world.add_child(rim)

    # Lamp pool (move 2): one warm spot hung behind/above the stand - pools LAMP_KEY light
    # on the felt and halos the toy's crown. Furniture light: static, no shadows, dims in
    # step with the key during the fight-end beat.
    _lamp = SpotLight3D.new()
    _lamp.light_color = Tokens.LAMP_KEY
    _lamp.light_energy = LAMP_POOL_REST
    _lamp.spot_range = 5.5
    _lamp.spot_angle = 28.0
    _lamp.spot_angle_attenuation = 1.6
    _lamp.shadow_enabled = false
    world.add_child(_lamp)
    _lamp.look_at_from_position(Vector3(0.4, 2.6, -1.2), Vector3(0, SHELF_Y, 0), Vector3.UP)

    _cam = Camera3D.new()
    _cam.fov = 50.0   # product-shot look; 75 was fisheye
    world.add_child(_cam)
    _cam.look_at_from_position(Vector3(0, 0.43, 3.4), Vector3(0, 0.05, 0), Vector3.UP)
    _cam_rest = _cam.transform

    _rig = Node3D.new()
    world.add_child(_rig)

    _turntable = Node3D.new()
    _turntable.rotation.y = deg_to_rad(18.0)   # 3/4 hero angle toward the key light, never dead-on
    _rig.add_child(_turntable)

    _fx3d = Node3D.new()
    _rig.add_child(_fx3d)

    _rect = TextureRect.new()
    _rect.texture = _svp.get_texture()
    _rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    _rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    _rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    _rect.set_anchors_preset(Control.PRESET_FULL_RECT)
    _rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_rect)

func _process(delta: float) -> void:
    if _turntable == null:
        return
    # Awake breathing: a gentle bob, never rotation (owner rule: no motion without input).
    # Dormant (calm 4.3): a SLEEP breath - half the awake amplitude on a 3s period.
    if _awake and not Juice.reduce_motion:
        _bob_t += delta
        var bob := sin(_bob_t * TAU / 4.0) * 0.015
        _turntable.position.y = _ground_y + bob
        if _soul != null and is_instance_valid(_soul):
            _soul.light_energy = SOUL_REST + sin(_bob_t * TAU / 4.0) * 0.1   # glow sways in phase
        if _sigil != null and is_instance_valid(_sigil):
            _sigil.rotation.z += SIGIL_SPIN * delta   # the backdrop sweeps slowly - a turn-timer read
    elif not _awake and not Juice.reduce_motion:
        _bob_t += delta
        _turntable.position.y = _ground_y + sin(_bob_t * TAU / 3.0) * 0.0075
    else:
        _turntable.position.y = _ground_y
    # Cavity-rim heartbeat (calm 4.4): GLOW_BASE alpha 0.15-0.30 on a 2s engine-clock period,
    # in phase with the CORE medallion's invite ring (both sample Time.get_ticks_msec()).
    # Reduce-motion: a static mid-value glow - state, not motion.
    if _cavity_rim != null and is_instance_valid(_cavity_rim):
        var rmat := _cavity_rim.material_override as StandardMaterial3D
        if rmat != null:
            var rc := rmat.albedo_color
            if _dormant_pulse:
                rc.a = 0.225
                if not Juice.reduce_motion:
                    rc.a = 0.225 + 0.075 * sin(float(Time.get_ticks_msec()) / 1000.0 * TAU / 2.0)
            else:
                rc.a = 0.0
            rmat.albedo_color = rc
    # 3D fx track a hand-spun toy: mirror the turntable yaw + grounding every frame.
    if _fx3d != null:
        _fx3d.rotation.y = _turntable.rotation.y
        _fx3d.position.y = _turntable.position.y
    # Release inertia from a hand spin - decays fast, a new press kills it instantly.
    if _drag or Juice.reduce_motion:
        return
    if absf(_spin_vel) > 2.0:
        _turntable.rotate_y(deg_to_rad(_spin_vel) * delta)
        _spin_vel *= exp(-3.2 * delta)
    else:
        _spin_vel = 0.0

func _gui_input(event: InputEvent) -> void:
    # Drag left-right to turn the toy in your hands (0.45 deg per stage pixel; yaw only).
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        _drag = event.pressed
        if event.pressed:
            _spin_vel = 0.0
    elif event is InputEventMouseMotion and _drag and _turntable != null:
        var deg: float = event.relative.x * 0.45
        _turntable.rotate_y(deg_to_rad(deg))
        _spin_vel = clampf(lerpf(_spin_vel, deg * 60.0, 0.35), -420.0, 420.0)

# Attach constants (art-director ruled): plug-in overlap band 0.02..0.12 - below reads floaty,
# above z-fights at 320x240. High shoulders = chunky figure; the pack seats between the blades.
const PLUG_Y := 0.06
const PLUG_SIDE := 0.05
const SHOULDER_DROP := 0.04
const BACK_TOP_DROP := 0.10
# Spacing pass (owner call 2026-07-19): a bit whose span rivals the core's earns outward
# AIR proportional to the excess, so chunky tool-bits read attached, not embedded. Normal
# bits (ratio below OVERSIZE_START) keep the snug plug exactly as before.
const OVERSIZE_START := 0.60    # span ratio where a bit starts earning air
const OVERSIZE_GAP := 0.12      # max outward air a chunky bit earns (world units)
const SHELF_Y := -1.05        # the feet always land on this line - the toy STANDS
# Dormant reference envelope (matches core_ember): bits still attach when no soul is seated.
const ENVELOPE := AABB(Vector3(-0.42, -0.34, -0.35), Vector3(0.84, 0.68, 0.70))

# --- composition diff: the one entry combat uses ---------------------------------------

func _composition_of(m: ManabitState) -> Dictionary:
    # bit ids + awake only; HP is DELIBERATELY excluded so per-hit updates never tear down.
    var comp := {}
    var core_pi: PartInstance = m.slots.get("CORE")
    comp["__awake"] = core_pi != null and not core_pi.disabled
    for slot in SLOT_POS.keys():
        var pi: PartInstance = m.slots.get(slot)
        if pi == null or pi.disabled:
            continue
        comp[slot] = String(pi.data.id)
    return comp

func sync(m: ManabitState) -> void:
    if _turntable == null:
        return
    var comp := _composition_of(m)
    if comp == _comp:
        update_damage(m)
        return
    if _is_shrink_of(comp, _comp):
        # only slots vanished (newly disabled) - detach them, keep every sibling's identity
        update_damage(m)
        _comp = comp
        return
    rebuild(m)

func _is_shrink_of(now: Dictionary, prev: Dictionary) -> bool:
    # true when `now` is `prev` minus some part slots: same awake, no new/changed entries.
    if now.get("__awake") != prev.get("__awake"):
        return false
    if now.size() >= prev.size():
        return false
    for k in now.keys():
        if not prev.has(k) or prev[k] != now[k]:
            return false
    return true

func update_damage(m: ManabitState) -> void:
    # Detach newly disabled slots; nothing else. Per-hit HP changes never rebuild.
    for slot in _mounts.keys().duplicate():
        var pi: PartInstance = m.slots.get(slot)
        if pi == null or pi.disabled:
            detach_part(String(slot))

func part_node(slot: String) -> Node3D:
    var v: Node3D = _visuals.get(slot)
    if v != null and is_instance_valid(v):
        return v
    return null

func _kill_slot_tween(slot: String) -> void:
    var tw: Tween = _slot_tweens.get(slot)
    if tw != null and tw.is_valid():
        tw.kill()
    _slot_tweens.erase(slot)

func _kill_hl_tween(slot: String) -> void:
    var tw: Tween = _hl_tweens.get(slot)
    if tw != null and tw.is_valid():
        tw.kill()
    _hl_tweens.erase(slot)

func _kill_all_anims() -> void:
    if _rig_tween != null and _rig_tween.is_valid():
        _rig_tween.kill()
    _rig_tween = null
    for slot in _slot_tweens.keys().duplicate():
        _kill_slot_tween(String(slot))
    for slot in _hl_tweens.keys().duplicate():
        _kill_hl_tween(String(slot))
    if _rig != null:
        _rig.position = Vector3.ZERO
        _rig.rotation = Vector3.ZERO
        _rig.scale = Vector3.ONE
    _mounts.clear()
    _visuals.clear()
    _flash_mats.clear()
    _hl_on.clear()
    if _fx3d != null:
        for c in _fx3d.get_children():
            c.queue_free()

# --- detach + part-level FX ------------------------------------------------------------

func detach_part(slot: String) -> void:
    # The break fall-off: one rigid piece snapped off the peg, never shrapnel.
    var mount: Node3D = _mounts.get(slot)
    _kill_slot_tween(slot)
    _kill_hl_tween(slot)
    _mounts.erase(slot)
    _visuals.erase(slot)
    _flash_mats.erase(slot)
    _hl_on.erase(slot)
    _comp.erase(slot)     # load-bearing: the aftermath sync sees a matching comp, never re-rebuilds
    if mount == null or not is_instance_valid(mount):
        return
    _spawn_socket_stub(mount.position)
    if Juice.reduce_motion:
        # departure information always plays: a quick scale-pop out in place, no tumble
        var tw := mount.create_tween()
        tw.tween_property(mount, "scale", Vector3(0.02, 0.02, 0.02), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
        tw.tween_callback(mount.queue_free)
        return
    var tw2 := mount.create_tween()   # BOUND TO THE MOUNT - dies with the node, never orphans
    tw2.set_parallel(true)
    var drop := mount.position + Vector3(randf_range(-0.3, 0.3), -1.7, 0.2)
    tw2.tween_property(mount, "position", drop, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
    tw2.tween_property(mount, "rotation", Vector3(randf_range(0.6, 1.0), 0.0, randf_range(-0.5, 0.5)), 0.45)
    tw2.tween_property(mount, "scale", Vector3(0.6, 0.6, 0.6), 0.45)
    tw2.chain().tween_callback(mount.queue_free)

func _spawn_socket_stub(at: Vector3) -> void:
    # Brass stub at the emptied seat if the fx glb exists (fiction: snapped-off-the-peg).
    # Shown under reduce_motion too - it is information. Cleared naturally by the next rebuild.
    if not ResourceLoader.exists(FX_DIR + "fx_socket_stub.glb"):
        return
    var res = load(FX_DIR + "fx_socket_stub.glb")
    if res is PackedScene:
        var inst = res.instantiate()
        if inst is Node3D:
            inst.position = at
            _turntable.add_child(inst)

func _overlay_for(slot: String, visual: Node3D) -> StandardMaterial3D:
    # The per-slot overlay instance both flash_part and highlight_slot ride. Shared-material
    # hazard law: ZERO runtime touches on glb-imported materials - overlays only.
    var mat: StandardMaterial3D = _flash_mats.get(slot)
    if mat == null:
        mat = StandardMaterial3D.new()
        mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
        mat.albedo_color = Color(1.0, 0.91, 0.75, 0.0)   # warm white, a=0
        _flash_mats[slot] = mat
        _apply_overlay(visual, mat)
    return mat

func flash_part(slot: String, peak: float = 0.35) -> void:
    # Overlay-material glow blip (combat hit). Rides the per-slot overlay; if a move-3
    # highlight is held on this slot, the blip settles back to the held rim, not to zero.
    if Juice.reduce_motion:
        return    # FULL no-op under reduce motion, never softened
    var visual := part_node(slot)
    if visual == null:
        return
    var mat := _overlay_for(slot, visual)
    var held: bool = _hl_on.get(slot, false)
    if not held:
        mat.albedo_color = Color(1.0, 0.91, 0.75, mat.albedo_color.a)   # warm white flash tint
    var tw := create_tween()
    tw.tween_property(mat, "albedo_color:a", peak, 0.06)
    tw.tween_property(mat, "albedo_color:a", HIGHLIGHT_A if held else 0.0, 0.16)

func highlight_slot(slot: String, on: bool) -> void:
    # Move-3 hover seam: rim-light the mounted part of `slot` in --glow-base amber while a
    # matching tray card or socket medallion is hovered; clear it on hover-out. Selection-only
    # glow (anti-casino guard), via the same per-slot overlay plumbing as the combat flash -
    # shared glb materials are NEVER touched. The held rim is state, not motion: it still
    # shows under reduce-motion, just without the fade. Does NOT survive rebuild() - the
    # caller re-issues it after a re-equip if the hover is still live.
    _kill_hl_tween(slot)
    if not on:
        _hl_on.erase(slot)
        var off_mat: StandardMaterial3D = _flash_mats.get(slot)
        if off_mat == null:
            return    # never lit - nothing to clear
        if Juice.reduce_motion:
            var oc := off_mat.albedo_color
            oc.a = 0.0
            off_mat.albedo_color = oc
            return
        var otw := create_tween()
        otw.tween_property(off_mat, "albedo_color:a", 0.0, 0.12)
        _hl_tweens[slot] = otw
        return
    var visual := part_node(slot)
    if visual == null:
        return    # empty socket - no mounted mesh to rim
    _hl_on[slot] = true
    var mat := _overlay_for(slot, visual)
    var c := Tokens.GLOW_BASE
    c.a = mat.albedo_color.a
    mat.albedo_color = c
    if Juice.reduce_motion:
        c.a = HIGHLIGHT_A
        mat.albedo_color = c
        return
    var tw := create_tween()
    tw.tween_property(mat, "albedo_color:a", HIGHLIGHT_A, 0.12)
    _hl_tweens[slot] = tw

func _apply_overlay(node: Node, mat: Material) -> void:
    if node is MeshInstance3D:
        (node as MeshInstance3D).material_overlay = mat
    for c in node.get_children():
        _apply_overlay(c, mat)

func hit_react(slot: String, punch: float = 1.06) -> void:
    # Part-level hit: scale punch + glow blip. Degrades silently if the slot already detached.
    var visual := part_node(slot)
    if visual == null:
        return
    flash_part(slot, 0.35 if punch < 1.08 else 0.5)
    if Juice.reduce_motion:
        return
    _kill_slot_tween(slot)
    visual.scale = Vector3.ONE * punch
    var tw := visual.create_tween()
    tw.tween_property(visual, "scale", Vector3.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    _slot_tweens[slot] = tw

# --- rig verbs (whole-toy motion; the stage stays side-agnostic: ME dir=1, FOE dir=-1) ---

func _kill_rig_tween() -> void:
    if _rig_tween != null and _rig_tween.is_valid():
        _rig_tween.kill()
    _rig_tween = null

func _rig_rest() -> void:
    _rig.position = Vector3.ZERO
    _rig.rotation = Vector3.ZERO
    _rig.scale = Vector3.ONE

func _oversize_air(ratio: float) -> float:
    # Spacing pass: 0 below OVERSIZE_START, ramping linearly to OVERSIZE_GAP at ratio 1.0+.
    var t := clampf((ratio - OVERSIZE_START) / (1.0 - OVERSIZE_START), 0.0, 1.0)
    return OVERSIZE_GAP * t

func lock_framing(on: bool) -> void:
    # Combat seam: HOLD the camera between rebuilds so a part break (smaller AABB) never
    # re-zooms mid-fight. Locking re-arms exactly one fresh framing, so each fight frames
    # its own starting build once and keeps that shot. Workshop/menagerie never lock.
    _framing_locked = on
    if on:
        _cam_framed = false

func windup(dir: int, ts: float = 1.0) -> void:
    # MULTI shared wind-up: rig pulls back + squash, HELD until the flurry begins.
    if Juice.reduce_motion:
        return
    _kill_rig_tween()
    _rig_rest()
    _rig_tween = create_tween()
    _rig_tween.set_parallel(true)
    _rig_tween.tween_property(_rig, "position:x", -dir * 0.10, 0.10 * ts).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    _rig_tween.tween_property(_rig, "scale", Vector3(0.96, 1.02, 0.96), 0.10 * ts).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func lunge(dir: int, ts: float = 1.0, thrust_only: bool = false) -> void:
    # Anticipation pull-back (0.12) then drive toward the foe (0.07), HELD at extension.
    if Juice.reduce_motion:
        return
    _kill_rig_tween()
    if not thrust_only:
        _rig_rest()
    _rig_tween = create_tween()
    if not thrust_only:
        _rig_tween.tween_property(_rig, "position:x", -dir * 0.10, 0.12 * ts).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
        _rig_tween.parallel().tween_property(_rig, "scale", Vector3(0.97, 1.02, 0.97), 0.12 * ts).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    _rig_tween.tween_property(_rig, "position:x", dir * 0.33, 0.07 * ts).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
    _rig_tween.parallel().tween_property(_rig, "scale", Vector3.ONE, 0.07 * ts)

func jab(dir: int, ts: float = 1.0) -> void:
    # MULTI mini-jab: out 40ms, back 60ms.
    if Juice.reduce_motion:
        return
    _kill_rig_tween()
    _rig_tween = create_tween()
    _rig_tween.tween_property(_rig, "position:x", dir * 0.14, 0.04 * ts).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
    _rig_tween.tween_property(_rig, "position:x", -dir * 0.06, 0.06 * ts).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func settle(ts: float = 1.0) -> void:
    # Return to rest, 0.18 QUAD-out.
    _kill_rig_tween()
    if Juice.reduce_motion:
        _rig_rest()
        return
    _rig_tween = create_tween()
    _rig_tween.set_parallel(true)
    _rig_tween.tween_property(_rig, "position", Vector3.ZERO, 0.18 * ts).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    _rig_tween.tween_property(_rig, "rotation", Vector3.ZERO, 0.18 * ts).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    _rig_tween.tween_property(_rig, "scale", Vector3.ONE, 0.18 * ts).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func brace(ts: float = 1.0) -> void:
    # GUARD exhale: rig sinks into itself - NEVER a flash, stop, or shake.
    if Juice.reduce_motion:
        return
    _kill_rig_tween()
    _rig_rest()
    _rig_tween = create_tween()
    _rig_tween.tween_property(_rig, "scale", Vector3(1.03, 0.94, 1.03), 0.10 * ts).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    _rig_tween.tween_property(_rig, "scale", Vector3.ONE, 0.14 * ts).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

# --- fight-end helpers ------------------------------------------------------------------

func light_dim(key_to: float, ambient_to: float, dur: float) -> void:
    # Material-free glow-death: reads on every bit type, zero shared-material access.
    # The lamp pool dims in proportion with the key so the beat darkens the whole stand.
    var tw := create_tween()
    tw.set_parallel(true)
    tw.tween_property(_key_light, "light_energy", key_to, dur)
    tw.tween_property(_env, "ambient_light_energy", ambient_to, dur)
    if _lamp != null:
        tw.tween_property(_lamp, "light_energy", LAMP_POOL_REST * (key_to / KEY_LIGHT_REST), dur)

func soul_flare(to_energy: float, dur: float) -> void:
    # Guarded by _awake=false first so the breathing bob in _process stops fighting the tween.
    _awake = false
    if _soul != null and is_instance_valid(_soul):
        var tw := create_tween()
        tw.tween_property(_soul, "light_energy", to_energy, dur)

func reset_pose() -> void:
    # Called from combat _start() on both stages: loss slump and death dim persist only
    # until the next fight begins.
    _kill_rig_tween()
    for slot in _slot_tweens.keys().duplicate():
        _kill_slot_tween(String(slot))
    if _rig != null:
        _rig_rest()
    if _key_light != null:
        _key_light.light_energy = KEY_LIGHT_REST
    if _env != null:
        _env.ambient_light_energy = AMBIENT_REST
    if _lamp != null:
        _lamp.light_energy = LAMP_POOL_REST
    if _soul != null and is_instance_valid(_soul):
        _soul.light_energy = SOUL_REST
    if _cam != null:
        _cam.transform = _cam_rest

func camera_push(pct: float = 0.06, dur: float = 0.9) -> void:
    # The only camera verb in the game: the death push-in. No roll, ever.
    if Juice.reduce_motion or _cam == null:
        return
    var fwd := -_cam.transform.basis.z
    var tw := create_tween()
    tw.tween_property(_cam, "position", _cam.position + fwd * (_cam.position.length() * pct), dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func unmake(stagger_s: float = 0.09) -> void:
    # THE UNMAKING part release: non-core parts gently let go, staggered, LEGS last.
    # Soft drift + tumble <= 60 deg - the Waking in reverse, never an explosion.
    # Slots are erased from the dicts as they release, so the post-fight rebuild clears them.
    var order := ["HEAD", "BACK", "ARM_L", "ARM_R", "LEGS"]
    var i := 0
    for slot in order:
        var mount: Node3D = _mounts.get(slot)
        if mount == null or not is_instance_valid(mount):
            continue
        _kill_slot_tween(slot)
        _kill_hl_tween(slot)
        _mounts.erase(slot)
        _visuals.erase(slot)
        _flash_mats.erase(slot)
        _hl_on.erase(slot)
        var tw := mount.create_tween()   # bound to the mount
        var delay := stagger_s * float(i)
        if Juice.reduce_motion:
            # staggered scale-pops: departure information always plays
            tw.tween_interval(maxf(0.01, delay))
            tw.tween_property(mount, "scale", Vector3(0.02, 0.02, 0.02), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
            tw.tween_callback(mount.queue_free)
        else:
            tw.tween_interval(maxf(0.01, delay))
            var drift := mount.position + Vector3(randf_range(-0.12, 0.12), -0.45, 0.06)
            tw.tween_property(mount, "position", drift, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
            tw.parallel().tween_property(mount, "rotation", Vector3(randf_range(0.3, 0.6), 0.0, randf_range(-0.4, 0.4)), 0.6)
        i += 1

# --- optional 3D fx (exists-gated; the game stays fully working with an empty art/fx dir) ---

func spawn_fx(fx_name: String, slot: String, tint: Color, fx_scale: float = 1.0) -> Node3D:
    if Juice.reduce_motion:
        return null
    if _fx3d == null or _fx3d.get_child_count() >= FX_CAP:
        return null
    var path := FX_DIR + fx_name + ".glb"
    if not ResourceLoader.exists(path):
        return null
    var res = load(path)
    if not (res is PackedScene):
        return null
    var inst = res.instantiate()
    if not (inst is Node3D):
        inst.queue_free()
        return null
    var n := inst as Node3D
    var mount: Node3D = _mounts.get(slot)
    if mount != null and is_instance_valid(mount):
        n.position = mount.position
    else:
        n.position = SLOT_POS.get(slot, Vector3.ZERO)
    n.scale = Vector3.ONE * fx_scale
    _tint_fx(n, tint)
    _fx3d.add_child(n)
    var tw := n.create_tween()   # safety: never outlive its moment
    tw.tween_interval(1.0)
    tw.tween_callback(n.queue_free)
    return n

func _tint_fx(node: Node, tint: Color) -> void:
    if node is MeshInstance3D:
        var m := StandardMaterial3D.new()
        m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        m.albedo_color = tint
        m.emission_enabled = true
        m.emission = tint
        m.emission_energy_multiplier = 1.2
        (node as MeshInstance3D).material_override = m
    for c in node.get_children():
        _tint_fx(c, tint)

# --- rebuild (public signature and behavior FROZEN for workshop/menagerie/run_screen) ---

func rebuild(m: ManabitState) -> void:
    if _turntable == null:
        return
    _kill_all_anims()
    var keep_yaw := _turntable.rotation.y          # yaw persists across rebuilds (hand position)
    for c in _turntable.get_children():
        c.queue_free()
    if _sigil != null and is_instance_valid(_sigil):
        _sigil.queue_free()             # the backdrop lives on _rig, not the turntable - free it here
    _sigil = null
    _soul = null
    _cavity_rim = null
    var core_pi: PartInstance = m.slots.get("CORE")
    _awake = core_pi != null and not core_pi.disabled
    # Ember lamp (calm 4.1): while no core is seated the key light dims to DORMANT_DIM of
    # rest and the lamp pool follows proportionally (the light_dim ratio plumbing). Soul
    # light stays off (never created dormant). Core seat -> rebuild restores full light.
    var dimf := 1.0 if _awake else DORMANT_DIM
    if _key_light != null:
        _key_light.light_energy = KEY_LIGHT_REST * dimf
    if _lamp != null:
        _lamp.light_energy = LAMP_POOL_REST * dimf
    var aff := "attack"
    if core_pi != null:
        aff = String(core_pi.data.affinity)
    var glow := Tokens.affinity_color(aff)
    var parts := {}
    for slot in SLOT_POS.keys():
        var pi: PartInstance = m.slots.get(slot)
        if pi == null or pi.disabled:      # broken parts fall off the model
            continue
        var fam := String(pi.data.family)                       # tint by style family (art bible sec 1)
        var base_col := FamilyPalette.base(fam)
        var micro := FamilyPalette.microglow(fam)
        var accent_glow := glow if slot == "CORE" else micro    # core glows the build affinity; else family micro
        var mat := _mat(base_col.darkened(0.1), micro, _awake, 0.0 if slot == "CORE" else 0.1)
        var accent := _mat(accent_glow.darkened(0.1), accent_glow, _awake, 1.3)
        parts[slot] = _build_bit(String(slot), String(pi.data.id), mat, accent)
    # HUB-AND-SPOKE attach: every bit plugs into the CORE box (or the dormant envelope) so the
    # Manabit reads as ONE connected toy. Position-only - never rotate/scale bits at runtime.
    # AABBs are measured on the bare visual BEFORE parenting; the mount carries the position.
    var core_ab := ENVELOPE
    if parts.has("CORE"):
        core_ab = _bounds_for(String(m.slots["CORE"].data.id), parts["CORE"])
    else:
        _turntable.add_child(_dormant_cavity())    # a hollow chest waiting for a soul
    var cc := core_ab.get_center()
    var assembled := core_ab
    for slot in parts.keys():
        var bit: Node3D = parts[slot]
        var mount := Node3D.new()
        if String(slot) != "CORE":
            var pi2: PartInstance = m.slots.get(slot)
            var ab := _bounds_for(String(pi2.data.id), bit)
            if not _sane(ab):
                push_warning("manabit_stage: insane bounds for %s - falling back to SLOT_POS" % String(pi2.data.id))
                mount.position = SLOT_POS[slot]
                mount.add_child(bit)
                _turntable.add_child(mount)
                _mounts[slot] = mount
                _visuals[slot] = bit
                continue
            var pc := ab.get_center()
            # Spacing pass: air earned by span ratio vs the core (0 for normal bits). Heads
            # and legs cap at flush (never a floating gap in the silhouette spine); arms and
            # packs may gap fully - a held tool or mounted pack reads right with daylight.
            var arm_air := _oversize_air(maxf(ab.size.y / core_ab.size.y, ab.size.z / core_ab.size.z))
            var cap_air_head := minf(_oversize_air(maxf(ab.size.x / core_ab.size.x, ab.size.z / core_ab.size.z)), PLUG_Y)
            var back_air := _oversize_air(maxf(ab.size.x / core_ab.size.x, ab.size.y / core_ab.size.y))
            match String(slot):
                "HEAD":
                    mount.position = Vector3(cc.x - pc.x, core_ab.end.y - ab.position.y - PLUG_Y + cap_air_head, cc.z - pc.z)
                "LEGS":
                    mount.position = Vector3(cc.x - pc.x, core_ab.position.y - ab.end.y + PLUG_Y - cap_air_head, cc.z - pc.z)
                "ARM_L":
                    mount.position = Vector3(core_ab.position.x - ab.end.x + PLUG_SIDE - arm_air, core_ab.end.y - ab.end.y - SHOULDER_DROP, cc.z - pc.z)
                "ARM_R":
                    mount.position = Vector3(core_ab.end.x - ab.position.x - PLUG_SIDE + arm_air, core_ab.end.y - ab.end.y - SHOULDER_DROP, cc.z - pc.z)
                "BACK":
                    mount.position = Vector3(cc.x - pc.x, core_ab.end.y - ab.end.y - BACK_TOP_DROP, core_ab.position.z - ab.end.z + PLUG_SIDE - back_air)
            assembled = assembled.merge(AABB(ab.position + mount.position, ab.size))
        mount.add_child(bit)
        _turntable.add_child(mount)
        _mounts[slot] = mount
        _visuals[slot] = bit
    # GROUNDING: a built toy PLANTS its feet on the shelf line. The pure empty core socket has
    # no legs to stand on, so it HOVERS at torso height - the cavity and its ring float clear of
    # the felt (owner: the ring must not touch the stand) with the contact shadow still pooling
    # below. Any real build (even one bit) grounds normally.
    _ground_y = SHELF_Y - assembled.position.y
    if parts.is_empty():
        _ground_y += DORMANT_FLOAT
    _turntable.position.y = _ground_y
    _bob_t = 0.0
    # Contact shadow (move 2, strengthened): two stacked discs - a wide penumbra plus a
    # tighter dark core under the feet - so the toy reads PLANTED on the felt, never afloat.
    var half := maxf(assembled.size.x, assembled.size.z) * 0.5
    var sh_r := half * 0.55 + 0.12
    var sh_y := SHELF_Y + 0.005 - _ground_y
    _turntable.add_child(_shadow_disc(sh_r, 0.45, Vector3(cc.x, sh_y, cc.z)))
    _turntable.add_child(_shadow_disc(sh_r * 0.55, 0.40, Vector3(cc.x, sh_y + 0.004, cc.z)))
    # Display stand: felt disc in a brass drum, sized to the build's swept footprint so the
    # shadow stays on the felt at every drag yaw.
    _make_plinth(sh_r + Vector2(cc.x, cc.z).length() + 0.10)
    # SOUL LIGHT: one omni at the core center when awake - one soul animating all the bits.
    if _awake and parts.has("CORE"):
        _soul = OmniLight3D.new()
        _soul.light_color = glow
        _soul.light_energy = SOUL_REST
        _soul.omni_range = 1.6
        _soul.shadow_enabled = false
        _soul.light_cull_mask = 0xFFFFF & ~PLINTH_LAYER   # the core glow lights the toy, never the felt stand
        _soul.position = cc
        _turntable.add_child(_soul)
        # MANA SIGIL (power ON): a flipped power-button rune wraps the seated soul - a broken ring
        # with a downstroke channelling the charge into the body, glowing the core's affinity hue.
        # BACKDROP: the flipped power-button rune hangs BEHIND the Manabit as a glowing aura,
        # scaled to frame the whole toy, facing the camera (on _rig so it never yaws with a drag).
        var sig_r := maxf(assembled.size.y, assembled.size.x) * 0.60
        _sigil = _mana_sigil(glow, sig_r, false)   # backdrop: signal line rises ABOVE the toy
        _sigil.position = Vector3(0.0, assembled.get_center().y + _ground_y + sig_r * 0.15, assembled.position.z - 0.20)
        _rig.add_child(_sigil)
    _turntable.rotation.y = keep_yaw
    # CAMERA: hero framing (move 2) - the toy stands ~HERO_FILL of stage height at the
    # 18-deg hero yaw, seen from a slightly LOW angle (up-tilt HERO_TILT_DEG). Same FOV-50
    # auto-framing family as before, same crop clamp: the distance never drops below what
    # fits the whole toy + CROP_MARGIN, so nothing ever crops.
    # While lock_framing holds, the shot is framed ONCE (the fight's starting build) and
    # then kept - a part break shrinking the AABB must never re-zoom the camera mid-fight.
    if _cam != null and not (_framing_locked and _cam_framed):
        var t_y := assembled.get_center().y + _ground_y
        var h := assembled.size.y
        var tan_half_fov := tan(deg_to_rad(_cam.fov * 0.5))
        var fill_dist := h / (2.0 * HERO_FILL * tan_half_fov)      # stands the toy at HERO_FILL
        var crop_dist := (h * 0.5 + CROP_MARGIN) / tan_half_fov    # crop clamp - always fits
        var dist := maxf(maxf(fill_dist, crop_dist), HERO_MIN_DIST)
        var cam_y := t_y - dist * tan(deg_to_rad(HERO_TILT_DEG))   # low hero angle, looking up
        _cam.look_at_from_position(Vector3(0, cam_y, dist), Vector3(0, t_y, 0), Vector3.UP)
        _cam_rest = _cam.transform
        _cam_framed = true
    debug_rebuild_count += 1
    _comp = _composition_of(m)

func _sane(ab: AABB) -> bool:
    var longest := maxf(ab.size.x, maxf(ab.size.y, ab.size.z))
    return longest <= 3.0 and longest >= 0.05

func _bounds_for(bit_id: String, n: Node3D) -> AABB:
    if _ab_cache.has(bit_id):
        return _ab_cache[bit_id]
    var ab := _part_bounds(n)
    _ab_cache[bit_id] = ab
    return ab

# The dormant chest cavity: a dark open hex frame where a soul would sit - the empty-core beat.
# Calm 4.2: the -REST_YAW_DEG yaw cancels the turntable's hero yaw so the cavity mouth faces
# the camera at rest (drag can still turn it - rest yaw is the default presentation).
func _mana_sigil(color: Color, radius: float, flipped: bool = true) -> Node3D:
    # The power-button rune: a smooth broken ring plus a stroke through the gap, built from thin
    # connected segments so it reads as one continuous bright line. Colour is the seated core's
    # affinity hue (a red core burns red, a mana core teal). flipped = gap/stroke at the BOTTOM;
    # non-flipped = at the TOP (the signal line rises above the toy as a backdrop).
    var n := Node3D.new()
    var mat := StandardMaterial3D.new()
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mat.albedo_color = color.lightened(0.3)
    var tube := maxf(0.02, radius * 0.045)          # line weight scales with the ring size
    var gap_half := deg_to_rad(30.0)
    var gap_c := (-PI * 0.5) if flipped else (PI * 0.5)   # gap centre: bottom if flipped, else top
    var segs := 64
    var sweep := TAU - 2.0 * gap_half
    var prev := Vector3.INF
    for i in range(segs + 1):
        var a := gap_c + gap_half + sweep * float(i) / float(segs)
        var p := Vector3(cos(a) * radius, sin(a) * radius, 0.0)
        if prev != Vector3.INF:
            n.add_child(_sigil_seg(prev, p, tube, mat))
        prev = p
    var base_y := (radius * 0.05) if flipped else (-radius * 0.05)
    var tip_y := (-radius * 1.12) if flipped else (radius * 1.12)
    n.add_child(_sigil_seg(Vector3(0, base_y, 0), Vector3(0, tip_y, 0), tube, mat))
    return n

func _sigil_seg(p0: Vector3, p1: Vector3, tube: float, mat: Material) -> MeshInstance3D:
    var d := p1 - p0
    var cm := CylinderMesh.new()
    cm.top_radius = tube
    cm.bottom_radius = tube
    cm.height = d.length()
    cm.radial_segments = 6
    var mi := MeshInstance3D.new()
    mi.mesh = cm
    mi.material_override = mat
    mi.position = (p0 + p1) * 0.5
    mi.rotation.z = atan2(d.y, d.x) - PI * 0.5           # cylinders lie along Y; aim along the segment
    return mi

func _dormant_cavity() -> Node3D:
    var mi := MeshInstance3D.new()
    var cm := CylinderMesh.new()
    var cav_r := 0.42
    cm.top_radius = cav_r
    cm.bottom_radius = cav_r
    cm.height = 0.6
    cm.radial_segments = 6
    mi.mesh = cm
    mi.rotation_degrees = Vector3(90, -REST_YAW_DEG, 0)
    # Rest the hollow husk's BOTTOM on the shelf line. Rotated 90 deg, the cylinder's radius
    # (0.42) is its vertical half-extent - taller than the ENVELOPE grounding box (0.34 half),
    # so at the origin the lower rim clips 0.08 down through the felt pedestal. Lift it so its
    # bottom aligns with the ENVELOPE bottom (which grounds exactly on SHELF_Y): it sits ON the
    # felt like feet do, never through it.
    mi.position.y = ENVELOPE.position.y + cav_r
    var m := StandardMaterial3D.new()
    m.albedo_color = Color("3E2A1A")
    m.roughness = 1.0
    m.cull_mode = BaseMaterial3D.CULL_FRONT   # hollow: you look INTO the cavity
    mi.material_override = m
    # Amber ring at the cavity mouth - the tag-era heartbeat. Alpha driven in _process;
    # dark (a=0) unless set_dormant_pulse(true) - nothing else on screen pulses.
    var rim := MeshInstance3D.new()
    var rmesh := TorusMesh.new()
    rmesh.inner_radius = 0.40
    rmesh.outer_radius = 0.47
    rim.mesh = rmesh
    rim.position = Vector3(0, 0.31, 0)     # the camera-facing mouth of the tube
    var rmat := StandardMaterial3D.new()
    rmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    rmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    rmat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
    rmat.albedo_color = Color(Tokens.GLOW_BASE, 0.0)
    rim.material_override = rmat
    mi.add_child(rim)
    _cavity_rim = rim
    return mi

# Calm 4.4 seam: workshop-owned - the heartbeat runs ONLY while the tag is at T1/T2.
func set_dormant_pulse(on: bool) -> void:
    _dormant_pulse = on

# Contact-shadow disc: unshaded transparent felt-dark; rebuild stacks two of these.
func _shadow_disc(r: float, alpha: float, pos: Vector3) -> MeshInstance3D:
    var disc := MeshInstance3D.new()
    var dm := CylinderMesh.new()
    dm.top_radius = r
    dm.bottom_radius = r
    dm.height = 0.01
    dm.radial_segments = 18
    disc.mesh = dm
    var dmat := StandardMaterial3D.new()
    dmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    dmat.albedo_color = Color(Tokens.FELT_TEAL.darkened(0.6), alpha)
    dmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    disc.material_override = dmat
    disc.position = pos
    return disc

# The display stand (move 2): a felt-topped disc in a brass drum, top surface exactly on the
# shelf line so the feet rest ON the felt. WORLD-space furniture on the turntable axis - it
# never bobs with the breath, never yaws with the drag (symmetric), and stays planted under
# combat lunges: furniture, not toy. Brass here is material, not glow (no emission).
func _make_plinth(felt_r: float) -> void:
    if _plinth != null and is_instance_valid(_plinth):
        _plinth.queue_free()
    _plinth = Node3D.new()
    var felt := StandardMaterial3D.new()
    felt.albedo_color = Tokens.FELT_TEAL
    felt.roughness = 1.0
    var brass := StandardMaterial3D.new()
    brass.albedo_color = Tokens.BRASS
    brass.metallic = 0.55
    brass.roughness = 0.45
    # The stand sits on its own render layer (PLINTH_LAYER) so the soul light excludes it -
    # the core's glow never pools on the felt. Key / rim / lamp keep default masks and still light it.
    var felt_disc := _mi(_disc_mesh(felt_r, PLINTH_FELT_H), felt, Vector3(0, SHELF_Y - PLINTH_FELT_H * 0.5, 0))
    felt_disc.layers = PLINTH_LAYER
    _plinth.add_child(felt_disc)
    var brass_disc := _mi(_disc_mesh(felt_r + PLINTH_RIM_LIP, PLINTH_BASE_H), brass, Vector3(0, SHELF_Y - PLINTH_FELT_H - PLINTH_BASE_H * 0.5, 0))
    brass_disc.layers = PLINTH_LAYER
    _plinth.add_child(brass_disc)
    if _world != null:
        _world.add_child(_plinth)

func _disc_mesh(r: float, h: float) -> CylinderMesh:
    # Round display-stand cylinder (the 6-segment _cyl stays reserved for chunky bit geometry).
    var c := CylinderMesh.new()
    c.top_radius = r
    c.bottom_radius = r
    c.height = h
    c.radial_segments = 20
    return c

# Merged local-space AABB of every mesh under a part root (root's own transform excluded -
# we place the root). Handles glbs (any authored origin) and the procedural composites alike.
func _part_bounds(n: Node3D) -> AABB:
    var boxes: Array = []
    _merge_aabbs(n, Transform3D.IDENTITY, boxes)
    if boxes.is_empty():
        return AABB(Vector3(-0.05, -0.05, -0.05), Vector3(0.1, 0.1, 0.1))
    var ab: AABB = boxes[0]
    for i in range(1, boxes.size()):
        ab = ab.merge(boxes[i])
    return ab

func _merge_aabbs(node: Node, xf: Transform3D, out: Array) -> void:
    if node is MeshInstance3D and node.mesh != null:
        out.append(xf * node.mesh.get_aabb())
    for c in node.get_children():
        var cxf := xf
        if c is Node3D:
            cxf = xf * (c as Node3D).transform
        _merge_aabbs(c, cxf, out)

func _mat(albedo: Color, glow: Color, awake: bool, emit: float) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = albedo
    m.roughness = 0.85
    m.specular = 0.2
    if awake and emit > 0.0:
        m.emission_enabled = true
        m.emission = glow
        m.emission_energy_multiplier = emit
    return m

func _build_bit(slot: String, bit_id: String, mat: Material, accent: Material) -> Node3D:
    # DROP-IN ART: if a low-poly model exists for this bit id, instance it; else procedural composite.
    for ext in [".glb", ".gltf", ".tscn", ".scn"]:
        var art := "res://art/bits/%s%s" % [bit_id, ext]
        if ResourceLoader.exists(art):
            var res = load(art)
            if res is PackedScene:
                var inst = res.instantiate()
                if inst is Node3D:
                    return inst
    var n := Node3D.new()
    match slot:
        "CORE":
            n.add_child(_mi(_box(0.9, 0.9, 0.64), mat, Vector3.ZERO))
            n.add_child(_mi(_box(0.42, 0.42, 0.72), accent, Vector3(0, 0, 0.02)))     # glowing heart
        "HEAD":
            n.add_child(_mi(_box(0.62, 0.5, 0.56), mat, Vector3.ZERO))
            n.add_child(_mi(_box(0.5, 0.14, 0.06), accent, Vector3(0, 0.03, 0.28)))    # visor
            n.add_child(_mi(_cyl(0.03, 0.34), mat, Vector3(0.2, 0.35, 0)))             # antenna
            n.add_child(_mi(_sphere(0.06), accent, Vector3(0.2, 0.54, 0)))             # antenna tip
        "ARM_L", "ARM_R":
            n.add_child(_mi(_cap(0.16, 0.72), mat, Vector3(0, -0.08, 0)))
            n.add_child(_mi(_box(0.32, 0.3, 0.32), mat, Vector3(0, -0.56, 0)))         # fist
        "LEGS":
            n.add_child(_mi(_box(0.26, 0.5, 0.28), mat, Vector3(-0.22, 0, 0)))
            n.add_child(_mi(_box(0.26, 0.5, 0.28), mat, Vector3(0.22, 0, 0)))
            n.add_child(_mi(_box(0.34, 0.14, 0.44), mat, Vector3(-0.22, -0.32, 0.07))) # feet
            n.add_child(_mi(_box(0.34, 0.14, 0.44), mat, Vector3(0.22, -0.32, 0.07)))
        "BACK":
            n.add_child(_mi(_box(0.6, 0.66, 0.2), mat, Vector3.ZERO))
            n.add_child(_mi(_cyl(0.06, 0.3), accent, Vector3(-0.18, 0.22, -0.1), Vector3(90, 0, 0)))
            n.add_child(_mi(_cyl(0.06, 0.3), accent, Vector3(0.18, 0.22, -0.1), Vector3(90, 0, 0)))
        _:
            n.add_child(_mi(_box(0.5, 0.5, 0.5), mat, Vector3.ZERO))
    return n

func _mi(mesh: Mesh, mat: Material, pos: Vector3, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    var mi := MeshInstance3D.new()
    mi.mesh = mesh
    mi.material_override = mat
    mi.position = pos
    mi.rotation_degrees = rot
    return mi

func _box(x: float, y: float, z: float) -> BoxMesh:
    var b := BoxMesh.new()
    b.size = Vector3(x, y, z)
    return b

func _sphere(r: float) -> SphereMesh:
    var s := SphereMesh.new()
    s.radius = r
    s.height = r * 2.0
    s.radial_segments = 6
    s.rings = 4
    return s

func _cyl(r: float, h: float) -> CylinderMesh:
    var c := CylinderMesh.new()
    c.top_radius = r
    c.bottom_radius = r
    c.height = h
    c.radial_segments = 6
    return c

func _cap(r: float, h: float) -> CapsuleMesh:
    var c := CapsuleMesh.new()
    c.radius = r
    c.height = h
    c.radial_segments = 6
    c.rings = 2
    return c
