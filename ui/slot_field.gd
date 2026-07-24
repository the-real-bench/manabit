class_name SlotField extends PanelContainer
# A brass socket MEDALLION on the display-stand rim (workshop-style-direction move 1).
# Drag target + tap - the interaction contract is unchanged: tap filters the tray to what
# fits (filled: unequip-then-focus; again: clear) via the same `tapped` signal, drag-drop
# still goes through slot_accepts. NEW: hold a FILLED medallion ~0.45s for the dim-and-focus
# inspect (move 10) instead of a tap; hover warms the medallion and rim-lights the toy (move 3).
# Empty = die-cut darker silhouette (never gray) - filled = tiny bit icon + rarity rim -
# active/warm = --brass-hi - amber ! pip marks a slot that blocks the bind.

signal equip_requested(slot_name: String, pi: PartInstance)
signal tapped(slot_name: String)
signal hovered(slot_name: String, on: bool)      # move-3 seam: workshop links toy + medallion
signal inspect_requested(slot_name: String)      # move-10 seam: long-press on a filled socket

const MEDALLION := 88.0          # ~88px target (DESIGN.md section 3 SlotPlate size)
const LONG_PRESS := 0.45         # hold this long on a filled socket -> inspect, not tap

@export var slot_name: String = "HEAD"
var _session: BuildSession
var _needed := false             # amber ! pip: this slot blocks the bind right now
var _warm_hover := false         # transient: pointer over the medallion / linked card hover
var _warm_lit := false           # persistent: this slot is the active tray filter
var _press_held := false
var _press_t := 0.0
var _long_fired := false
var _invite := false             # calm-spec invite: slow GLOW_BASE ring breath, workshop-owned

func setup(sname: String, session: BuildSession) -> SlotField:
    slot_name = sname
    _session = session
    return self

func _ready() -> void:
    custom_minimum_size = Vector2(MEDALLION, MEDALLION)
    mouse_filter = Control.MOUSE_FILTER_STOP
    mouse_entered.connect(_on_mouse.bind(true))
    mouse_exited.connect(_on_mouse.bind(false))
    refresh()

func _pi() -> PartInstance:
    return _session.manabit.slots.get(slot_name) if _session != null else null

func refresh() -> void:
    for c in get_children():
        c.queue_free()
    var pi := _pi()
    _apply_base()
    if pi != null:
        # honest data relocated, never removed: full per-bit numbers ride the tooltip here
        # and the move-10 inspect chips (the old plate's informational job, per the spec)
        tooltip_text = "%s - %s %s\nAttack %d · Defense %d · Speed %d · Weight %d" % [
            pi.data.display_name, pi.data.rarity.capitalize(), Tokens.slot_word(slot_name),
            pi.data.attack, pi.data.defense, pi.data.speed, pi.data.weight]
        var icon_path := "res://art/icons/%s.png" % String(pi.data.id)
        if ResourceLoader.exists(icon_path):
            var tex = load(icon_path)
            if tex is Texture2D:
                var ir := TextureRect.new()
                ir.texture = tex
                ir.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
                ir.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
                ir.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
                ir.mouse_filter = Control.MOUSE_FILTER_IGNORE
                add_child(ir)
    else:
        tooltip_text = "%s - tap to see what fits" % Tokens.slot_word(slot_name)
    queue_redraw()

func _apply_base() -> void:
    # Circular brass medallion: StyleBoxFlat with full-round corners carries the shared
    # soft shadow; the rim border is the rarity frame material when filled (rarity law).
    var pi := _pi()
    var warm := _warm_hover or _warm_lit
    var sb := StyleBoxFlat.new()
    sb.set_corner_radius_all(int(MEDALLION * 0.5))
    sb.bg_color = Tokens.BRASS.lightened(0.08) if warm else Tokens.BRASS
    sb.set_border_width_all(3)
    if warm:
        sb.border_color = Tokens.BRASS_HI
    elif pi != null:
        sb.border_color = Tokens.rarity_frame(pi.data.rarity)
    else:
        sb.border_color = Color(Tokens.BENCH_LO, 0.8)
    # icon well: keep the tiny bit icon clear of the etched glyph and microlabel
    sb.content_margin_left = 24
    sb.content_margin_right = 24
    sb.content_margin_top = 20
    sb.content_margin_bottom = 28
    Tokens.shadow_soft(sb, 5)
    add_theme_stylebox_override("panel", sb)

func _draw() -> void:
    var pi := _pi()
    var c := size * 0.5
    var f: Font = Tokens.display_font()
    if f == null:
        f = get_theme_default_font()
    var warm := _warm_hover or _warm_lit
    if pi == null:
        # EMPTY: die-cut darker silhouette of the awaited bit - a shaped absence, never gray.
        draw_circle(c + Vector2(0, -4), 26.0, Tokens.BENCH_LO)
        draw_arc(c + Vector2(0, -4), 26.0, 0.0, TAU, 32, Color(Tokens.BENCH_LO, 1.0).darkened(0.3), 1.5, true)
        _etched_text(f, Tokens.slot_glyph(slot_name), Rect2(c + Vector2(-20, -26), Vector2(40, 32)), 22,
            Color(Tokens.BENCH_WALNUT, 0.85), Color(0, 0, 0, 0))
    else:
        # FILLED: soft family blob under the tiny bit icon; the rim border is the rarity material.
        draw_circle(c + Vector2(0, -4), 26.0, Color(Tokens.slot_family(slot_name), 0.35))
        _etched_text(f, Tokens.slot_glyph(slot_name), Rect2(Vector2(c.x - 12, 3), Vector2(24, 14)), 10,
            Color(Tokens.BENCH_LO, 0.8), Color(Tokens.BRASS_HI, 0.35))
    # Baloo 2 microlabel, small caps, etched into the brass (move 14 shade pass)
    _etched_text(f, Tokens.slot_word(slot_name).to_upper(), Rect2(Vector2(4, size.y - 25), Vector2(size.x - 8, 14)), 9,
        Tokens.BENCH_LO, Color(Tokens.BRASS_HI, 0.35))
    if warm:
        # warm-lit ring: --brass-hi, selection register only (anti-casino guard)
        draw_arc(c, size.x * 0.5 - 1.0, 0.0, TAU, 48, Color(Tokens.BRASS_HI, 0.45), 2.0, true)
    if _invite:
        # invite breath (calm spec section 5): GLOW_BASE ring, alpha 0.25-0.45 on a 2s
        # engine-clock period - in phase with the cavity-rim heartbeat, which samples the
        # same clock. NEVER BRASS_HI (anti-casino: brass stays selection-only).
        # Reduce-motion: static ring at 0.35.
        var ia := 0.35
        if not Juice.reduce_motion:
            ia = 0.35 + 0.10 * sin(float(Time.get_ticks_msec()) / 1000.0 * TAU / 2.0)
        draw_arc(c, size.x * 0.5 - 4.0, 0.0, TAU, 48, Color(Tokens.GLOW_BASE, ia), 2.5, true)
    if _needed:
        # amber ! pip: this socket blocks the bind (SlotField spec, survives the reskin)
        var pc := Vector2(size.x - 15.0, 13.0)
        draw_circle(pc, 8.0, Tokens.GLOW_BASE)
        draw_arc(pc, 8.0, 0.0, TAU, 20, Color(Tokens.BENCH_LO, 0.5), 1.0, true)
        var df := get_theme_default_font()
        _etched_text(df, "!", Rect2(pc - Vector2(8, 7), Vector2(16, 14)), 11, Tokens.BENCH_LO, Color(0, 0, 0, 0))

func _etched_text(f: Font, txt: String, r: Rect2, px: int, ink: Color, hi: Color) -> void:
    # etched lettering: a 1px light under-stroke below the dark ink reads as stamped brass
    var base_y := r.position.y + (r.size.y - f.get_height(px)) * 0.5 + f.get_ascent(px)
    if hi.a > 0.0:
        draw_string(f, Vector2(r.position.x, base_y + 1.0), txt, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, px, hi)
    draw_string(f, Vector2(r.position.x, base_y), txt, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, px, ink)

# --- state setters (visual only) --------------------------------------------------------

func set_needed(on: bool) -> void:
    if _needed == on:
        return
    _needed = on
    queue_redraw()

func set_invite(on: bool) -> void:
    # Calm spec section 5: keeps the amber ! pip, adds the slow GLOW_BASE ring breath.
    # The workshop owns exclusivity (at most ONE invited medallion) and suppression.
    if _invite == on:
        return
    _invite = on
    if _invite and not Juice.reduce_motion:
        set_process(true)        # the breath samples the engine clock every frame
    queue_redraw()

func _breathing() -> bool:
    return _invite and not Juice.reduce_motion

func set_warm(on: bool) -> void:
    # transient hover warmth (own hover, or the linked tray-card hover via the workshop)
    if _warm_hover == on:
        return
    _warm_hover = on
    _apply_base()
    queue_redraw()

func set_lit(on: bool) -> void:
    # persistent warmth: this socket is the active tray filter
    if _warm_lit == on:
        return
    _warm_lit = on
    _apply_base()
    queue_redraw()

func _on_mouse(inside: bool) -> void:
    set_warm(inside)
    hovered.emit(slot_name, inside)
    if not inside:
        _press_held = false
        if not _breathing():
            set_process(false)

var _hl: Panel

func set_eligibility(active: bool, fits: bool) -> void:
    if _hl == null or not is_instance_valid(_hl):
        _hl = Panel.new()
        _hl.set_anchors_preset(Control.PRESET_FULL_RECT)
        _hl.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _hl.visible = false
        var sb := StyleBoxFlat.new()
        sb.bg_color = Color(Tokens.VALID, 0.16)
        sb.set_corner_radius_all(int(MEDALLION * 0.5))
        sb.set_border_width_all(4)
        sb.border_color = Tokens.VALID
        _hl.add_theme_stylebox_override("panel", sb)
        add_child(_hl)
    pivot_offset = size / 2.0
    if not active:
        modulate = Color(1, 1, 1, 1)
        scale = Vector2.ONE
        _hl.visible = false
    elif fits:
        modulate = Color(1, 1, 1, 1)
        scale = Vector2(1.06, 1.06)
        _hl.visible = true
    else:
        modulate = Color(1, 1, 1, 0.3)
        scale = Vector2.ONE
        _hl.visible = false

func _can_drop_data(_pos: Vector2, data: Variant) -> bool:
    if typeof(data) != TYPE_DICTIONARY or data.get("kind") != "part":
        return false
    return _session.slot_accepts(slot_name, data["pi"])

func _drop_data(_pos: Vector2, data: Variant) -> void:
    equip_requested.emit(slot_name, data["pi"])

func _gui_input(event: InputEvent) -> void:
    # Tap contract unchanged (filter / unequip-then-focus / clear) - a quick press-release is
    # a tap. Holding a FILLED medallion past LONG_PRESS opens the inspect instead; holding an
    # EMPTY one resolves to the same tap at the threshold, so nothing ever feels dead.
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed:
            _press_held = true
            _press_t = 0.0
            _long_fired = false
            set_process(true)
        else:
            if not _breathing():
                set_process(false)
            if _press_held and not _long_fired:
                tapped.emit(slot_name)
            _press_held = false

func _process(delta: float) -> void:
    if _press_held:
        _press_t += delta
        if _press_t >= LONG_PRESS:
            _long_fired = true
            _press_held = false
            if _pi() != null:
                inspect_requested.emit(slot_name)
            else:
                tapped.emit(slot_name)
    if _breathing():
        queue_redraw()           # the invite ring samples the engine clock
    if not _press_held and not _breathing():
        set_process(false)

# --- seat / reject juice ---
func play_seat_fx() -> void:
    Juice.squash_pop(self, 0.14)
    _flare()
    if not Juice.reduce_motion:
        var burst := SparkBurst.new()
        add_child(burst)
        burst.set_anchors_preset(Control.PRESET_FULL_RECT)
        burst.fire(Tokens.GLOW_BASE)

func _flare() -> void:
    if Juice.reduce_motion:
        return
    var f := Panel.new()
    var sb := StyleBoxFlat.new()
    sb.bg_color = Color(Tokens.GLOW_BASE, 0.0)
    sb.set_corner_radius_all(int(MEDALLION * 0.5))
    sb.set_border_width_all(3)
    sb.border_color = Tokens.LAMP_KEY
    f.add_theme_stylebox_override("panel", sb)
    f.set_anchors_preset(Control.PRESET_FULL_RECT)
    f.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(f)
    var tw := f.create_tween()
    tw.tween_property(f, "modulate:a", 0.0, 0.2).from(1.0)
    tw.tween_callback(f.queue_free)

func play_reject() -> void:
    Juice.shake(self, 8.0, 0.15)
    Sfx.play(&"invalid_clunk")
