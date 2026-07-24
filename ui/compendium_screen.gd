class_name CompendiumScreen extends Control
# THE COMPENDIUM - the bit-dex. Every catalog bit; discovered ones lit, the rest greyed silhouettes.

signal done

var player: PlayerState
var _grid: HFlowContainer
var _pct: Label

func setup(p: PlayerState) -> CompendiumScreen:
    player = p
    return self

func _ready() -> void:
    if player == null:
        player = PlayerState.new()
    _build_layout()
    call_deferred("refresh_from_player")

func _build_layout() -> void:
    set_anchors_preset(Control.PRESET_FULL_RECT)
    var bg := ColorRect.new()
    bg.color = Tokens.PANEL_DEEP
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
    back.pressed.connect(func(): done.emit())
    top.add_child(back)
    var title := Label.new()
    title.text = "    THE COMPENDIUM"
    title.add_theme_color_override("font_color", Tokens.BRASS_HI)
    Tokens.display(title, 20)
    top.add_child(title)
    var spacer := Control.new()
    spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    top.add_child(spacer)
    _pct = Label.new()
    _pct.add_theme_color_override("font_color", Tokens.BRASS_HI)
    top.add_child(_pct)

    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    root.add_child(scroll)
    _grid = HFlowContainer.new()
    _grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _grid.add_theme_constant_override("h_separation", 10)
    _grid.add_theme_constant_override("v_separation", 10)
    scroll.add_child(_grid)

func refresh_from_player() -> void:
    for c in _grid.get_children():
        c.queue_free()
    var all: Array = Catalog.all()
    var found := 0
    for pd in all:
        var known: bool = player.compendium.has(String(pd.id))
        if known:
            found += 1
        _grid.add_child(_make_card(pd, known))
    var total := all.size()
    var pct := 0
    if total > 0:
        pct = int(round(100.0 * float(found) / float(total)))
    _pct.text = "%d / %d discovered · %d%%" % [found, total, pct]

func _make_card(pd: PartData, known: bool) -> Control:
    var card := PanelContainer.new()
    card.custom_minimum_size = Vector2(150, 92)
    var sb := StyleBoxFlat.new()
    sb.bg_color = Tokens.PANEL_FILL if known else Tokens.PANEL_DEEP
    sb.set_border_width_all(2)
    sb.border_color = Tokens.rarity_frame(pd.rarity) if known else Color(Tokens.BRASS, 0.25)
    sb.set_corner_radius_all(6)
    sb.content_margin_left = 10
    sb.content_margin_right = 10
    sb.content_margin_top = 8
    sb.content_margin_bottom = 8
    card.add_theme_stylebox_override("panel", sb)

    var v := VBoxContainer.new()
    v.add_theme_constant_override("separation", 3)
    card.add_child(v)
    var head := HBoxContainer.new()
    head.add_theme_constant_override("separation", 6)
    v.add_child(head)
    if known:
        # discovered bits show their real face - the collection payoff (studio gate)
        var icon_path := "res://art/icons/%s.png" % String(pd.id)
        if ResourceLoader.exists(icon_path):
            var ir := TextureRect.new()
            ir.texture = load(icon_path)
            ir.custom_minimum_size = Vector2(34, 34)
            ir.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
            ir.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
            ir.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
            head.add_child(ir)
    var glyph := Label.new()
    glyph.text = Tokens.slot_glyph(pd.slot)
    glyph.add_theme_color_override("font_color", Tokens.rarity_frame(pd.rarity) if known else Color(Tokens.BRASS, 0.3))
    glyph.add_theme_font_size_override("font_size", 20)
    head.add_child(glyph)
    var nm := Label.new()
    nm.text = pd.display_name if known else "？ ？ ？"
    nm.add_theme_color_override("font_color", Tokens.PARCHMENT if known else Color(Tokens.PARCHMENT, 0.3))
    v.add_child(nm)
    var sub := Label.new()
    sub.text = ("%s · %s" % [Tokens.slot_word(pd.slot), pd.rarity]) if known else "undiscovered"
    sub.add_theme_font_size_override("font_size", 12)
    sub.add_theme_color_override("font_color", Color(Tokens.PARCHMENT, 0.75 if known else 0.65))
    v.add_child(sub)
    return card
