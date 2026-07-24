class_name PartCard extends PanelContainer
# A tray/pack bit card. Drag source + tap-select - the interaction model is untouched.
# Reskin 2026-07-18 (workshop-style-direction move 8): every bit shares one locked
# specimen anatomy - pastel slot-family title strip, icon in a soft family blob,
# headline stat + weight as corner capsules with tiny vector icons (never letter-code
# strings), rarity as the frame material plus a stamped seal, wax dot = seated,
# paper NEW stamp, duplicates as peeking stacked strips. All numbers stay honest.

signal selected(card: PartCard)
signal activated(card: PartCard)   # double-click / double-tap = attach to the build (owner ask 2026-07-20)
signal drag_started(card: PartCard)
signal drag_ended

const STRIP_Y := 8.0
const STRIP_H := 22.0

var pi: PartInstance
var origin: String = "tray"

# Additive state (integration wires these; defaults keep today's behavior 1:1):
var stack_count: int = 1     # >1 draws peeking stacked title strips - never an xN text badge
var seated: bool = false     # wax dot on the strip = seated on the current build
var is_new: bool = false     # paper NEW stamp (defaults on for pack-reveal cards)

var _sel := false
var _hovered := false
var _lifted := false
var _base_y := 0.0
var _lift_tween: Tween
var _new_stamp: Label
var _icon_missing := true
var _hs_kind := "atk"
var _hs_val := 0
var _hs_col := Color.WHITE
var _micro := ""
var _micro_col := Color.WHITE

static var _pill: StyleBoxFlat
static var _ring: StyleBoxFlat

func setup(p: PartInstance, from: String = "tray") -> PartCard:
    pi = p
    origin = from
    is_new = (from == "reveal")   # pack-reveal cards land wearing the NEW stamp (PackOpen spec)
    return self

func set_stack(n: int) -> PartCard:
    stack_count = maxi(1, n)
    queue_redraw()
    return self

func set_seated(on: bool) -> PartCard:
    seated = on
    queue_redraw()
    return self

func set_new(on: bool) -> PartCard:
    is_new = on
    if _new_stamp != null:
        _new_stamp.visible = on
    return self

func set_selected(on: bool) -> void:
    # tap-place ring + lift; brass-gold is sanctioned here (selection only - anti-casino)
    _sel = on
    _apply_lift()
    queue_redraw()

func _ready() -> void:
    custom_minimum_size = Vector2(122, 150)
    mouse_filter = Control.MOUSE_FILTER_STOP
    mouse_entered.connect(_on_hover.bind(true))
    mouse_exited.connect(_on_hover.bind(false))
    _build()

func _build() -> void:
    var d := pi.data

    # Body: the material sandwich (deep well) - radius and soft shadow as issued.
    # The frame is the rarity material (tin/brass/runed-wood, DESIGN.md section 1 law)
    # and margins are zeroed for the fixed specimen layout (tight tray card, section 9).
    var sb := Tokens.sandwich("deep")
    sb.set_border_width_all(3)
    sb.border_color = Tokens.rarity_frame(d.rarity)
    sb.content_margin_left = 0
    sb.content_margin_right = 0
    sb.content_margin_top = 0
    sb.content_margin_bottom = 0
    add_theme_stylebox_override("panel", sb)

    tooltip_text = "%s - %s %s" % [d.display_name, d.rarity.capitalize(), Tokens.slot_word(d.slot)]

    # Headline stat: same pick logic as ever - the number is untouched, only the clothing.
    _hs_kind = "atk"
    _hs_val = d.attack
    _hs_col = Tokens.STAT_ATK
    if d.defense > d.attack and d.defense >= d.speed:
        _hs_kind = "def"
        _hs_val = d.defense
        _hs_col = Tokens.STAT_DEF
    elif d.speed > d.attack:
        _hs_kind = "spd"
        _hs_val = d.speed
        _hs_col = Tokens.STAT_SPD

    _micro = ""
    if d.ability != null:
        _micro = String(d.ability.archetype)
    _micro_col = Color(Tokens.PARCHMENT, 0.8)
    if d.is_core and d.carry > 0:            # a stronger soul wakes a heavier body
        _micro += (" · " if _micro != "" else "") + "CARRY +%d" % d.carry
        if d.ability == null:
            _micro_col = Tokens.STAT_WEIGHT

    var wrap := Control.new()
    wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(wrap)

    var glyph := Label.new()
    glyph.text = Tokens.slot_glyph(d.slot)
    glyph.position = Vector2(7, STRIP_Y + 2)
    glyph.size = Vector2(15, STRIP_H - 4)
    glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    glyph.add_theme_font_size_override("font_size", 11)
    glyph.add_theme_color_override("font_color", Tokens.BENCH_LO)
    glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
    wrap.add_child(glyph)

    var nm := Label.new()
    nm.text = d.display_name
    nm.position = Vector2(22, STRIP_Y)
    nm.size = Vector2(86, STRIP_H)
    nm.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    Tokens.display(nm, 11)
    nm.add_theme_color_override("font_color", Tokens.BENCH_LO)
    nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
    wrap.add_child(nm)

    var icon_path := "res://art/icons/%s.png" % String(d.id)   # DROP-IN ART: bit icon if present
    if ResourceLoader.exists(icon_path):
        var tex = load(icon_path)
        if tex is Texture2D:
            _icon_missing = false
            var ir := TextureRect.new()
            ir.texture = tex
            ir.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
            ir.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
            ir.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
            ir.mouse_filter = Control.MOUSE_FILTER_IGNORE
            ir.set_anchors_preset(Control.PRESET_CENTER)
            ir.offset_left = -22
            ir.offset_top = -25
            ir.offset_right = 22
            ir.offset_bottom = 19
            wrap.add_child(ir)

    # Paper NEW stamp - a slightly cocked parchment tag, top-right under the strip.
    _new_stamp = Label.new()
    _new_stamp.text = "NEW"
    Tokens.display(_new_stamp, 10)
    _new_stamp.add_theme_color_override("font_color", Tokens.BENCH_LO)
    var ns := StyleBoxFlat.new()
    ns.bg_color = Tokens.PARCHMENT
    ns.set_corner_radius_all(3)
    ns.set_border_width_all(1)
    ns.border_color = Color(Tokens.BENCH_WALNUT, 0.6)
    ns.content_margin_left = 5
    ns.content_margin_right = 5
    ns.content_margin_top = 1
    ns.content_margin_bottom = 1
    _new_stamp.add_theme_stylebox_override("normal", ns)
    _new_stamp.rotation = -0.14
    _new_stamp.position = Vector2(76, 33)
    _new_stamp.visible = is_new
    _new_stamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
    wrap.add_child(_new_stamp)

    if pi.disabled:
        # broken bit: greyscale-dim read (drag only touches modulate.a, so this survives)
        modulate = Color(0.55, 0.55, 0.55)

func _draw() -> void:
    if pi == null:
        return
    var d := pi.data
    var w := size.x
    var h := size.y
    var fam := Tokens.slot_family(d.slot)
    var f := get_theme_default_font()

    # Duplicates: peeking stacked title strips (Stacklands read; wired via set_stack).
    if stack_count > 2:
        draw_rect(Rect2(12, 1, w - 24, 4), fam.darkened(0.34))
    if stack_count > 1:
        draw_rect(Rect2(7, 4, w - 14, 5), fam.darkened(0.2))

    # Pastel slot-family title strip - dark walnut text rides it (contrast-checked).
    draw_rect(Rect2(4, STRIP_Y, w - 8, STRIP_H), fam)

    if seated:
        # wax dot on the strip corner = seated on the current build
        draw_circle(Vector2(w - 9, STRIP_Y + 11), 4.5, Tokens.WAX)
        draw_circle(Vector2(w - 10.5, STRIP_Y + 9.5), 1.4, Color(1, 1, 1, 0.3))

    # The specimen: icon sits in a soft circular family blob.
    var blob := Vector2(w * 0.5, h * 0.5 - 3.0)
    draw_circle(blob, 27.0, Color(fam, 0.13))
    draw_circle(blob, 21.0, Color(fam, 0.22))
    if _icon_missing:
        _center_text(f, Tokens.slot_glyph(d.slot), Rect2(blob - Vector2(20, 14), Vector2(40, 28)), 22, Color(Tokens.PARCHMENT, 0.9))

    # Damaged: cracked frame + the honest HP pip (12/20 stays 12/20).
    if pi.current_hp < d.max_hp:
        draw_polyline(PackedVector2Array([Vector2(w - 26, 3), Vector2(w - 21, 12), Vector2(w - 27, 21), Vector2(w - 19, 30)]), Color(0, 0, 0, 0.4), 1.5)
        var pip := Rect2(Vector2(5, STRIP_Y + STRIP_H + 3), Vector2(52, 16))
        _pill_box(Tokens.PANEL_FILL).draw(get_canvas_item(), pip)
        _center_text(f, "✖ %d/%d" % [pi.current_hp, d.max_hp], pip, 10, Tokens.DELTA_NEG)

    # Archetype / carry microline - words and numbers kept, never letter-code soup.
    if _micro != "":
        _center_text(f, _micro, Rect2(Vector2(4, h - 44), Vector2(w - 8, 12)), 10, _micro_col)

    # Corner capsules: headline stat (left) + weight (right) - icon + number in the
    # stat's locked hue (color economy RULE), tiny vector icons so no font roulette.
    var cap := Rect2(Vector2(6, h - 30), Vector2(46, 24))
    _pill_box(_hs_col).draw(get_canvas_item(), cap)
    _draw_stat_icon(_hs_kind, cap.position + Vector2(6, 7.5))
    _center_text(f, str(_hs_val), Rect2(cap.position + Vector2(15, 0), Vector2(cap.size.x - 19, cap.size.y)), 12, Tokens.BENCH_LO)
    var wcap := Rect2(Vector2(w - 52, h - 30), Vector2(46, 24))
    _pill_box(Tokens.STAT_WEIGHT).draw(get_canvas_item(), wcap)
    _draw_stat_icon("wt", wcap.position + Vector2(6, 7.5))
    _center_text(f, str(d.weight), Rect2(wcap.position + Vector2(15, 0), Vector2(wcap.size.x - 19, wcap.size.y)), 12, Tokens.BENCH_LO)

    # Rarity: the frame material above, plus a small stamped seal here - shape-coded
    # (RARE one rune, EPIC two), never color-only. COMMON tin wears no seal.
    if d.rarity != "COMMON":
        var sc := Vector2(w * 0.5, h - 21.0)
        var acc := Tokens.rarity_accent(d.rarity)
        draw_circle(sc, 9.5, acc)
        draw_arc(sc, 9.5, 0.0, TAU, 24, acc.darkened(0.35), 1.5, true)
        _center_text(f, "◆◆" if d.rarity == "EPIC" else "◆", Rect2(sc - Vector2(12, 8), Vector2(24, 16)), 8, Tokens.BENCH_LO)

    if _sel:
        _ring_box().draw(get_canvas_item(), Rect2(Vector2(-2, -2), size + Vector2(4, 4)))

func _draw_stat_icon(kind: String, at: Vector2) -> void:
    # Tiny 9px vector stat icons - dark walnut on the colored capsule.
    var col := Tokens.BENCH_LO
    match kind:
        "atk":   # a little upturned blade with crossguard and grip
            draw_colored_polygon(PackedVector2Array([at + Vector2(4.5, 0), at + Vector2(7.5, 5.5), at + Vector2(1.5, 5.5)]), col)
            draw_rect(Rect2(at + Vector2(0.5, 5.5), Vector2(8, 1.2)), col)
            draw_rect(Rect2(at + Vector2(3.5, 6.7), Vector2(2, 2.3)), col)
        "def":   # shield
            draw_colored_polygon(PackedVector2Array([at, at + Vector2(9, 0), at + Vector2(9, 5), at + Vector2(4.5, 9), at + Vector2(0, 5)]), col)
        "spd":   # double chevron
            draw_polyline(PackedVector2Array([at + Vector2(1.2, 0.5), at + Vector2(5, 4.5), at + Vector2(1.2, 8.5)]), col, 1.6)
            draw_polyline(PackedVector2Array([at + Vector2(5.2, 0.5), at + Vector2(9, 4.5), at + Vector2(5.2, 8.5)]), col, 1.6)
        "wt":    # a hanging plumb weight
            draw_circle(at + Vector2(4.5, 1.6), 1.6, col)
            draw_colored_polygon(PackedVector2Array([at + Vector2(1.5, 3.2), at + Vector2(7.5, 3.2), at + Vector2(9, 9), at + Vector2(0, 9)]), col)

func _center_text(f: Font, txt: String, r: Rect2, px: int, col: Color) -> void:
    var base_y := r.position.y + (r.size.y - f.get_height(px)) * 0.5 + f.get_ascent(px)
    draw_string(f, Vector2(r.position.x, base_y), txt, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, px, col)

static func _pill_box(fill: Color) -> StyleBoxFlat:
    if _pill == null:
        _pill = StyleBoxFlat.new()
        _pill.set_corner_radius_all(12)
    _pill.bg_color = fill
    return _pill

static func _ring_box() -> StyleBoxFlat:
    if _ring == null:
        _ring = StyleBoxFlat.new()
        _ring.draw_center = false
        _ring.set_border_width_all(2)
        _ring.border_color = Tokens.BRASS_HI
        _ring.set_corner_radius_all(Tokens.RADIUS_CARD + 2)
    return _ring

func _on_hover(on: bool) -> void:
    _hovered = on
    _apply_lift()

func _apply_lift() -> void:
    # --card-lift: hover/selected raise the card 4px in 90ms (DESIGN.md section 4).
    var want := _hovered or _sel
    if want == _lifted:
        return
    _lifted = want
    if not is_inside_tree():
        return
    if want and (_lift_tween == null or not _lift_tween.is_running()):
        _base_y = position.y
    if _lift_tween != null and _lift_tween.is_running():
        _lift_tween.kill()
    var target := (_base_y - 4.0) if want else _base_y
    if Juice.reduce_motion:
        position.y = target
    else:
        _lift_tween = create_tween()
        _lift_tween.tween_property(self, "position:y", target, 0.09).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _get_drag_data(_pos: Vector2) -> Variant:
    set_drag_preview(_make_preview())
    modulate.a = 0.4
    drag_started.emit(self)
    return {"kind": "part", "pi": pi, "origin": origin, "card": self}

func _make_preview() -> Control:
    # The held bit rides as a parchment shipping tag under the finger.
    var p := PanelContainer.new()
    var sb := Tokens.sandwich("parchment")
    sb.content_margin_left = 10
    sb.content_margin_right = 10
    sb.content_margin_top = 5
    sb.content_margin_bottom = 5
    p.add_theme_stylebox_override("panel", sb)
    var l := Label.new()
    l.text = pi.data.display_name
    Tokens.display(l, 13)
    l.add_theme_color_override("font_color", Tokens.BENCH_LO)
    p.add_child(l)
    return p

func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        selected.emit(self)            # single press = tap-place select (unchanged, all screens)
        if event.double_click:
            activated.emit(self)       # workshop attaches; screens that ignore it are unaffected

func _notification(what: int) -> void:
    if what == NOTIFICATION_DRAG_END:
        modulate.a = 1.0
        drag_ended.emit()
