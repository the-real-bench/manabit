class_name ChestScreen extends Control
# THE COFFER NOOK - open chests (Coffers). Pick Tin or Brass, then the Waking ritual:
# press-and-HOLD to channel (charge-ring) -> release to crack the seal (bounded flash) ->
# bits rise dormant and KINDLE in ascending rarity. [Rake it in] skips. Then back to the Workshop.

signal done
signal open_broker_requested

var player: PlayerState

var _reveal_box: HBoxContainer
var _empty_box: VBoxContainer   # zero-coffer empty state (warm label + Fettle's Cart CTA)
var _count_label: Label
var _tin_btn: Button
var _brass_btn: Button
var _coffer_btn: Button
var _ring: ChargeRing
var _coffer_sigil: ManaSigil2D      # slow-spinning power-rune backdrop behind the coffer
var _seal_back: Panel               # the dark wax seal disc - only shown while the seal is held
var _rune: Label
var _status: Label
var _skip_btn: Button
var _face: TextureRect          # drop-in coffer art (res://art/props/coffer_face_<kind>.png)
var _odds: Label                # odds printed on the coffer face (DESIGN.md PackOpen spec)

var _kind: String = "brass"
var _state: String = "idle"        # idle | charging | revealing
var _charge: float = 0.0
var _dormant: Array = []
var _skip := false
var _ritual_claimed := false       # Lane B1: the Waking press-hold owns one ritual duck at a time

func setup(p: PlayerState) -> ChestScreen:
    player = p
    return self

func _ready() -> void:
    if player == null:
        player = PlayerState.new()
        player.grant_starter_kit()
    _build_layout()
    set_process(true)
    visibility_changed.connect(_on_visibility_changed)
    call_deferred("refresh_from_player")

# The Coffer Nook bed = amb_nook (the workshop bed reused at -6 dB). Rides visibility with a
# 200ms fade that crosses the outgoing screen through near-silence (audio-full-game.md section 4).
func _on_visibility_changed() -> void:
    if visible:
        Sfx.loop_start(&"amb_nook", 0.2)
    else:
        _release_ritual()          # never leak a ritual duck if we leave mid-hold
        Sfx.loop_stop(&"amb_nook", 0.2)

# The Waking press-hold dips the nook bed a further 6 dB (ritual duck claim). Ref-counted in Sfx,
# so every claim is paired with exactly one release across every exit path.
func _claim_ritual() -> void:
    if _ritual_claimed:
        return
    _ritual_claimed = true
    Sfx.duck_claim(&"ritual")

func _release_ritual() -> void:
    if not _ritual_claimed:
        return
    _ritual_claimed = false
    Sfx.duck_release(&"ritual")

func _build_layout() -> void:
    set_anchors_preset(Control.PRESET_FULL_RECT)
    var bg := ColorRect.new()
    bg.color = Tokens.BENCH_LO
    bg.set_anchors_preset(Control.PRESET_FULL_RECT)
    bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(bg)
    Warmth.apply(self)

    var root := VBoxContainer.new()
    root.set_anchors_preset(Control.PRESET_FULL_RECT)
    root.offset_left = 18
    root.offset_top = 12
    root.offset_right = -18
    root.offset_bottom = -14
    root.add_theme_constant_override("separation", 10)
    add_child(root)

    var top := HBoxContainer.new()
    root.add_child(top)
    var back := Button.new()
    back.text = "◂  Back to the Workshop"
    back.pressed.connect(func(): Sfx.play(&"ui_tap"); done.emit())
    top.add_child(back)
    var spacer := Control.new()
    spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    top.add_child(spacer)
    _count_label = Label.new()
    _count_label.add_theme_color_override("font_color", Tokens.BRASS_HI)
    top.add_child(_count_label)

    var title := Label.new()
    title.text = "THE COFFER NOOK"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_color_override("font_color", Tokens.BRASS_HI)
    Tokens.display(title, 24)
    root.add_child(title)

    var sub := Label.new()
    sub.text = "Choose a Coffer, then channel your mana to wake the bits inside."
    sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    sub.add_theme_color_override("font_color", Color(Tokens.PARCHMENT, 0.8))
    root.add_child(sub)

    var selector := HBoxContainer.new()
    selector.alignment = BoxContainer.ALIGNMENT_CENTER
    selector.add_theme_constant_override("separation", 10)
    root.add_child(selector)
    _tin_btn = Button.new()
    _tin_btn.custom_minimum_size = Vector2(140, 0)
    _tin_btn.pressed.connect(func(): Sfx.play(&"ui_tap"); _select("tin"))
    selector.add_child(_tin_btn)
    _brass_btn = Button.new()
    _brass_btn.custom_minimum_size = Vector2(140, 0)
    _brass_btn.pressed.connect(func(): Sfx.play(&"ui_tap"); _select("brass"))
    selector.add_child(_brass_btn)

    var pad_top := Control.new()
    pad_top.size_flags_vertical = Control.SIZE_EXPAND_FILL
    root.add_child(pad_top)

    var coffer_stack := Control.new()
    coffer_stack.custom_minimum_size = Vector2(224, 168)
    coffer_stack.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    root.add_child(coffer_stack)
    # BACKDROP: the spinning power-rune sits BEHIND the coffer, framing it like the 3D backdrop
    # behind a seated Manabit - one slow sweep a minute, the opaque coffer covers its centre so
    # only the halo shows around it.
    _coffer_sigil = ManaSigil2D.new()
    _coffer_sigil.set_anchors_preset(Control.PRESET_FULL_RECT)
    _coffer_sigil.radius_px = 150.0
    coffer_stack.add_child(_coffer_sigil)

    _coffer_btn = Button.new()
    _coffer_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
    _coffer_btn.pivot_offset = Vector2(112, 84)
    var csb := StyleBoxFlat.new()
    csb.bg_color = Tokens.PANEL_FILL
    csb.set_border_width_all(3)
    csb.border_color = Tokens.BRASS
    csb.set_corner_radius_all(14)
    _coffer_btn.add_theme_stylebox_override("normal", csb)
    _coffer_btn.add_theme_stylebox_override("hover", csb)
    _coffer_btn.add_theme_stylebox_override("pressed", csb)
    _coffer_btn.button_down.connect(_coffer_down)
    _coffer_btn.button_up.connect(_coffer_up)
    coffer_stack.add_child(_coffer_btn)

    _face = TextureRect.new()
    _face.set_anchors_preset(Control.PRESET_FULL_RECT)
    _face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    _face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    _face.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    _face.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _coffer_btn.add_child(_face)

    _odds = Label.new()
    _odds.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _odds.add_theme_font_size_override("font_size", 11)
    _odds.add_theme_color_override("font_color", Color(Tokens.PARCHMENT, 0.85))
    _odds.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
    _odds.offset_top = -22
    _odds.offset_bottom = -6
    _odds.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _coffer_btn.add_child(_odds)

    _ring = ChargeRing.new()
    _ring.set_anchors_preset(Control.PRESET_FULL_RECT)
    _ring.visible = false          # the charge ring only appears while the seal is being HELD
    _coffer_btn.add_child(_ring)

    # the SEAL - a dark wax disc backing + the breathing glow rune. Hidden on a resting coffer;
    # the seal only appears while you press-and-HOLD to channel (owner: the middle circle should
    # not sit on the chest at rest). The coffer itself stays the press target + the status line guides.
    _seal_back = Panel.new()
    var ssb := StyleBoxFlat.new()
    ssb.bg_color = Color(Tokens.PANEL_DEEP, 0.85)
    ssb.set_corner_radius_all(28)
    ssb.set_border_width_all(2)
    ssb.border_color = Tokens.BRASS_HI
    _seal_back.add_theme_stylebox_override("panel", ssb)
    _seal_back.custom_minimum_size = Vector2(56, 56)
    _seal_back.set_anchors_preset(Control.PRESET_CENTER)
    _seal_back.offset_left = -28
    _seal_back.offset_top = -28
    _seal_back.offset_right = 28
    _seal_back.offset_bottom = 28
    _seal_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _seal_back.visible = false
    _coffer_btn.add_child(_seal_back)

    _rune = Label.new()
    _rune.text = "❖"
    _rune.add_theme_font_size_override("font_size", 46)
    _rune.add_theme_color_override("font_color", Tokens.GLOW_BASE)
    _rune.set_anchors_preset(Control.PRESET_CENTER)
    _rune.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _rune.visible = false
    _coffer_btn.add_child(_rune)

    _status = Label.new()
    _status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _status.add_theme_color_override("font_color", Tokens.LAMP_KEY)
    root.add_child(_status)

    # zero-coffer empty state: warm words + a real CTA, never a lone disabled coffer
    _empty_box = VBoxContainer.new()
    _empty_box.alignment = BoxContainer.ALIGNMENT_CENTER
    _empty_box.add_theme_constant_override("separation", 10)
    _empty_box.visible = false
    root.add_child(_empty_box)
    var empty_l := Label.new()
    empty_l.text = "No Coffers to wake. Fettle's Cart sells sealed ones - a Tin is ⚙40."
    empty_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    empty_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    empty_l.add_theme_color_override("font_color", Tokens.PARCHMENT)
    _empty_box.add_child(empty_l)
    var cart := Button.new()
    cart.text = "Fettle's Cart"
    cart.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    cart.pressed.connect(func(): Sfx.play(&"ui_tap"); open_broker_requested.emit())
    Tokens.brass_button(cart)   # empty-state CTA = the screen's one brass action
    Tokens.pad_target(cart, 44.0)
    _empty_box.add_child(cart)

    var pad_bot := Control.new()
    pad_bot.size_flags_vertical = Control.SIZE_EXPAND_FILL
    root.add_child(pad_bot)

    var reveal_head := HBoxContainer.new()
    root.add_child(reveal_head)
    var rh := Label.new()
    rh.text = "WOKEN BITS"
    rh.add_theme_font_size_override("font_size", 12)
    rh.add_theme_color_override("font_color", Tokens.BRASS_HI)
    reveal_head.add_child(rh)
    var rsp := Control.new()
    rsp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    reveal_head.add_child(rsp)
    _skip_btn = Button.new()
    _skip_btn.text = "Rake it in  ⏩"
    _skip_btn.visible = false
    _skip_btn.pressed.connect(func(): Sfx.play(&"ui_tap"); self._skip = true)
    reveal_head.add_child(_skip_btn)

    var reveal_panel := PanelContainer.new()
    reveal_panel.custom_minimum_size = Vector2(0, 178)
    var rsb := StyleBoxFlat.new()
    rsb.bg_color = Tokens.PANEL_DEEP
    rsb.set_corner_radius_all(8)
    rsb.content_margin_left = 10
    rsb.content_margin_right = 10
    rsb.content_margin_top = 8
    rsb.content_margin_bottom = 8
    reveal_panel.add_theme_stylebox_override("panel", rsb)
    root.add_child(reveal_panel)
    var scroll := ScrollContainer.new()
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
    scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    reveal_panel.add_child(scroll)
    _reveal_box = HBoxContainer.new()
    _reveal_box.add_theme_constant_override("separation", 8)
    scroll.add_child(_reveal_box)

func _kind_count() -> int:
    return int(player.coffers.get(_kind, 0))

func _select(k: String) -> void:
    if _state != "idle":
        return
    _kind = k
    refresh_from_player()

func refresh_from_player() -> void:
    var tin := int(player.coffers.get("tin", 0))
    var brass := int(player.coffers.get("brass", 0))
    _tin_btn.text = "Tin  ×%d" % tin
    _brass_btn.text = "Brass  ×%d" % brass
    if _kind_count() <= 0:
        if brass > 0:
            _kind = "brass"
        elif tin > 0:
            _kind = "tin"
    # tab states (a11y gate): selected = brass ring; unselected-but-OWNED stays full-bright;
    # only a true ×0 gets the dim treatment. Never dim something the player owns.
    _tab_style(_tin_btn, _kind == "tin", tin > 0)
    _tab_style(_brass_btn, _kind == "brass", brass > 0)
    _count_label.text = "Coffers:  Tin ×%d · Brass ×%d" % [tin, brass]
    var can := _kind_count() > 0 and _state != "revealing"
    _coffer_btn.disabled = not can
    var none := tin + brass == 0
    _coffer_btn.visible = not none
    if _coffer_sigil != null:
        _coffer_sigil.visible = not none   # the backdrop rune rides with the coffer
    _empty_box.visible = none
    # drop-in coffer face + odds printed on it (PackOpen spec)
    var face_path := "res://art/props/coffer_face_%s.png" % _kind
    _face.texture = load(face_path) if ResourceLoader.exists(face_path) else null
    _odds.text = PackRoller.odds_line(_kind)
    if _state == "idle":
        if none:
            _status.text = ""   # the empty state above carries the message
        else:
            _status.text = ("Hold the %s Coffer's seal until it cracks - let go to stop." % _kind.capitalize()) if can else "No Coffers - visit Fettle's Cart."
        _show_empty_tray_prompt()

func _tab_style(btn: Button, selected: bool, owned: bool) -> void:
    btn.modulate = Color(1, 1, 1, 1.0) if owned else Color(1, 1, 1, 0.4)
    var sb := StyleBoxFlat.new()
    sb.bg_color = Tokens.PANEL_FILL if not selected else Tokens.BENCH_WALNUT
    sb.set_corner_radius_all(6)
    sb.set_border_width_all(2)
    sb.border_color = Tokens.BRASS_HI if selected else Tokens.PANEL_DEEP
    sb.content_margin_left = 12
    sb.content_margin_right = 12
    sb.content_margin_top = 8
    sb.content_margin_bottom = 8
    btn.add_theme_stylebox_override("normal", sb)
    btn.add_theme_stylebox_override("hover", sb)
    btn.add_theme_stylebox_override("pressed", sb)
    btn.add_theme_color_override("font_color", Tokens.PARCHMENT if owned else Color(Tokens.PARCHMENT, 0.6))

func _show_empty_tray_prompt() -> void:
    if _reveal_box == null or _reveal_box.get_child_count() > 0:
        return
    var p := Label.new()
    p.text = "  Woken bits land here. Hold the seal above."
    p.add_theme_color_override("font_color", Color(Tokens.PARCHMENT, 0.5))
    _reveal_box.add_child(p)

func _process(delta: float) -> void:
    if _state == "idle" and _rune != null:
        _rune.modulate.a = 0.55 + 0.35 * sin(Time.get_ticks_msec() / 480.0)
    elif _state == "charging":
        _charge = minf(1.0, _charge + delta / 0.9)
        _ring.progress = _charge
        _rune.modulate.a = 1.0
        var s := 1.0 + (0.04 * _charge)
        _coffer_btn.scale = Vector2(s, s)
        if _charge >= 1.0:
            # the seal filled all the way - THIS is the only thing that opens a coffer.
            _coffer_btn.scale = Vector2.ONE
            _release_ritual()          # lift the bed dip; the crack + reveal ride full
            _crack_and_open()

func _coffer_down() -> void:
    if _state != "idle" or _kind_count() <= 0:
        return
    _state = "charging"
    _charge = 0.0
    _ring.visible = true           # ring + seal disc + rune all appear the moment the hold begins
    _ring.progress = 0.0
    _seal_back.visible = true
    _rune.visible = true
    _rune.modulate.a = 1.0
    _status.text = "channeling… hold to the end"
    Sfx.play(&"seal_channel")
    _claim_ritual()                # dip the bed while the seal is held

func _coffer_up() -> void:
    if _state != "charging":
        return
    # Let go before the seal filled -> ALWAYS cancel, never open. You are never committed:
    # only channeling the ring all the way to full cracks a coffer (fires from _process).
    _release_ritual()              # the hold ended - lift the bed dip
    _coffer_btn.scale = Vector2.ONE
    _state = "idle"
    _charge = 0.0
    _ring.progress = 0.0
    _ring.visible = false          # released early - the ring + seal vanish with the hold
    _seal_back.visible = false
    _rune.visible = false
    _status.text = "You ease off - the seal rests, still sealed."

func _crack_and_open() -> void:
    _state = "revealing"
    _ring.progress = 0.0
    _ring.visible = false          # the seal cracked - ring + seal are done
    _seal_back.visible = false
    _rune.visible = false
    _coffer_btn.disabled = true
    var perfect := _charge >= 0.95
    _flash()
    Juice.squash_pop(_coffer_btn, 0.18)
    Sfx.play(&"seal_crack")
    Sfx.play(&"lid_spring")
    _status.text = "The seal cracks - the scrap stirs."
    var rolled := player.open_coffer(_kind)
    await _reveal_sequence(rolled, perfect)
    _state = "idle"
    player.save()
    refresh_from_player()

func _reveal_sequence(rolled: Array, perfect: bool) -> void:
    for c in _reveal_box.get_children():
        c.queue_free()
    _dormant.clear()
    _skip = false
    _skip_btn.visible = true

    var order := {"COMMON": 0, "RARE": 1, "EPIC": 2}
    var seq := rolled.duplicate()
    seq.sort_custom(func(a, b): return order[a.data.rarity] < order[b.data.rarity])

    for pi in seq:
        var card := PartCard.new().setup(pi, "reveal")
        _reveal_box.add_child(card)
        card.modulate = Color(0.45, 0.45, 0.45, 0.25)
        _dormant.append(card)

    for i in seq.size():
        if _skip:
            break
        await get_tree().create_timer(0.24).timeout
        _kindle(_dormant[i], seq[i])
    if _skip:
        for j in seq.size():
            _kindle(_dormant[j], seq[j])

    _skip_btn.visible = false
    var best := "COMMON"
    for pi2 in seq:
        if pi2.data.rarity == "EPIC":
            best = "EPIC"
        elif pi2.data.rarity == "RARE" and best != "EPIC":
            best = "RARE"
    if best == "EPIC":
        _status.text = "✦ EPIC! ✦  " + ("A perfect channel." if perfect else "The seal gave up something rare.")
    elif best == "RARE":
        _status.text = "◆  A rare bit stirs awake."
    else:
        _status.text = "＋%d bits woken into your collection." % rolled.size()

func _kindle(card: Control, pi: PartInstance) -> void:
    if card == null:
        return
    var r := String(pi.data.rarity)
    # Explicit StringName match (audio wave 4a, plan T4): the old dynamic
    # "reveal_" + r.to_lower() was invisible to the smoke gate's seam regex.
    match r:
        "EPIC":
            Sfx.play(&"reveal_epic")
        "RARE":
            Sfx.play(&"reveal_rare")
        _:
            Sfx.play(&"reveal_common")
    var tw := card.create_tween()
    tw.tween_property(card, "modulate", Color(1, 1, 1, 1), 0.18)
    Juice.squash_pop(card, 0.2)
    if r != "COMMON" and not Juice.reduce_motion:
        var burst := SparkBurst.new()
        card.add_child(burst)
        burst.set_anchors_preset(Control.PRESET_FULL_RECT)
        burst.fire(Tokens.rarity_accent(r))

func _flash() -> void:
    if Juice.reduce_motion:
        return
    var f := ColorRect.new()
    f.color = Color(1.0, 0.92, 0.72, 0.0)
    f.set_anchors_preset(Control.PRESET_FULL_RECT)
    f.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(f)
    var tw := f.create_tween()
    tw.tween_property(f, "color:a", 0.34, 0.06)
    tw.tween_property(f, "color:a", 0.0, 0.24)
    tw.tween_callback(f.queue_free)

# For the screenshot harness.
func debug_open() -> void:
    if _state != "idle":
        return
    _kind = "brass" if int(player.coffers.get("brass", 0)) > 0 else "tin"
    if _kind_count() <= 0:
        return
    _charge = 1.0
    _crack_and_open()
