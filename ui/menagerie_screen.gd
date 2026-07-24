class_name MenagerieScreen extends Control
# THE MENAGERIE - gallery of bound Manabits. Click one to INSPECT it (3D + aggregate stats),
# then click a part to focus that part's stats.

signal done

var player: PlayerState
var _back: Button
var _count: Label
var _content: VBoxContainer

var _mode := "list"                 # list | detail
var _entry: Dictionary = {}
var _manabit: ManabitState
var _focus_pane: VBoxContainer

func setup(p: PlayerState) -> MenagerieScreen:
    player = p
    return self

func _ready() -> void:
    if player == null:
        player = PlayerState.new()
    _build_shell()
    call_deferred("refresh_from_player")

func _build_shell() -> void:
    set_anchors_preset(Control.PRESET_FULL_RECT)
    var bg := ColorRect.new()
    bg.color = Tokens.BENCH_WALNUT.darkened(0.1)
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
    _back = Button.new()
    _back.pressed.connect(_on_back)
    top.add_child(_back)
    var title := Label.new()
    title.text = "    THE MENAGERIE"
    title.add_theme_color_override("font_color", Tokens.BRASS_HI)
    Tokens.display(title, 20)
    top.add_child(title)
    var sp := Control.new()
    sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    top.add_child(sp)
    _count = Label.new()
    _count.add_theme_color_override("font_color", Tokens.BRASS_HI)
    top.add_child(_count)

    _content = VBoxContainer.new()
    _content.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _content.add_theme_constant_override("separation", 10)
    root.add_child(_content)

func _on_back() -> void:
    if _mode == "detail":
        _mode = "list"
        _entry = {}
        refresh_from_player()
    else:
        done.emit()

func refresh_from_player() -> void:
    _count.text = "%d bound" % player.menagerie.size()
    _clear(_content)
    if _mode == "detail" and not _entry.is_empty():
        _back.text = "◂  All Manabits"
        _build_detail()
    else:
        _mode = "list"
        _back.text = "◂  Back to the Workshop"
        _build_list()

# --- list ---
func _build_list() -> void:
    if player.menagerie.is_empty():
        # centered warm empty state with a real CTA (studio gate) - not a lone grey sentence
        var box := VBoxContainer.new()
        box.alignment = BoxContainer.ALIGNMENT_CENTER
        box.size_flags_vertical = Control.SIZE_EXPAND_FILL
        box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        box.add_theme_constant_override("separation", 10)
        _content.add_child(box)
        var ghost := Label.new()
        ghost.text = "❖"
        ghost.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        ghost.add_theme_font_size_override("font_size", 72)
        ghost.add_theme_color_override("font_color", Color(Tokens.GLOW_BASE, 0.18))
        box.add_child(ghost)
        var empty := Label.new()
        empty.text = "No Manabits bound yet."
        empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        empty.add_theme_font_size_override("font_size", 18)
        empty.add_theme_color_override("font_color", Tokens.PARCHMENT)
        box.add_child(empty)
        var cta := Button.new()
        cta.text = "⬛  Go bind one in the Workshop"
        cta.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        cta.pressed.connect(func(): done.emit())
        Tokens.brass_button(cta)
        Tokens.pad_target(cta)
        box.add_child(cta)
        return
    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    _content.add_child(scroll)
    var grid := HFlowContainer.new()
    grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    grid.add_theme_constant_override("h_separation", 10)
    grid.add_theme_constant_override("v_separation", 10)
    scroll.add_child(grid)
    for entry in player.menagerie:
        grid.add_child(_list_card(entry))

func _list_card(entry: Dictionary) -> Control:
    var card := PanelContainer.new()
    card.custom_minimum_size = Vector2(214, 122)
    card.mouse_filter = Control.MOUSE_FILTER_STOP
    card.add_theme_stylebox_override("panel", _pnl(Tokens.PANEL_FILL, Tokens.BRASS))
    card.gui_input.connect(func(e: InputEvent):
        if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
            _open(entry))
    var v := VBoxContainer.new()
    v.add_theme_constant_override("separation", 4)
    card.add_child(v)
    var nm := Label.new()
    nm.text = "❖ " + String(entry.get("name", "Manabit"))
    nm.add_theme_color_override("font_color", Tokens.LAMP_KEY)
    nm.add_theme_font_size_override("font_size", 16)
    v.add_child(nm)
    var arch := Label.new()
    arch.text = _archetype(entry)
    arch.add_theme_color_override("font_color", Tokens.BRASS_HI)
    arch.add_theme_font_size_override("font_size", 12)
    v.add_child(arch)
    var stats := Label.new()
    stats.text = "ATK %d   DEF %d   SPD %d   MANA %d" % [int(entry.get("atk", 0)), int(entry.get("def", 0)), int(entry.get("spd", 0)), int(entry.get("mana", 0))]
    stats.add_theme_color_override("font_color", Tokens.PARCHMENT)
    stats.add_theme_font_size_override("font_size", 12)
    v.add_child(stats)
    var hint := Label.new()
    hint.text = "click to inspect ▸"
    hint.add_theme_color_override("font_color", Color(Tokens.PARCHMENT, 0.5))
    hint.add_theme_font_size_override("font_size", 11)
    v.add_child(hint)
    return card

func _open(entry: Dictionary) -> void:
    _mode = "detail"
    _entry = entry
    refresh_from_player()

# --- detail ---
func _build_detail() -> void:
    _manabit = _reconstruct(_entry)
    var nm := Label.new()
    nm.text = "❖ " + String(_entry.get("name", "Manabit")) + "   ·   " + _archetype(_entry)
    nm.add_theme_color_override("font_color", Tokens.LAMP_KEY)
    nm.add_theme_font_size_override("font_size", 20)
    _content.add_child(nm)

    var row := HBoxContainer.new()
    row.size_flags_vertical = Control.SIZE_EXPAND_FILL
    row.add_theme_constant_override("separation", 16)
    _content.add_child(row)

    var stage := ManabitStage.new()
    stage.custom_minimum_size = Vector2(320, 300)
    stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
    row.add_child(stage)
    stage.call_deferred("rebuild", _manabit)

    var info := VBoxContainer.new()
    info.custom_minimum_size = Vector2(360, 0)
    info.add_theme_constant_override("separation", 8)
    row.add_child(info)

    var d := _manabit.derived()
    var agg := Label.new()
    agg.text = "ATK %d    DEF %d    SPD %d\nMANA %d    WEIGHT %d" % [int(d.attack), int(d.defense), int(d.speed), int(d.energy), int(d.weight)]
    agg.add_theme_color_override("font_color", Tokens.PARCHMENT)
    agg.add_theme_font_size_override("font_size", 16)
    info.add_child(agg)

    var ph := Label.new()
    ph.text = "PARTS  -  click one to inspect"
    ph.add_theme_font_size_override("font_size", 12)
    ph.add_theme_color_override("font_color", Tokens.BRASS_HI)
    info.add_child(ph)
    var parts := HFlowContainer.new()
    parts.add_theme_constant_override("h_separation", 6)
    parts.add_theme_constant_override("v_separation", 6)
    info.add_child(parts)
    for slot in ManabitState.SLOT_NAMES:
        var pi: PartInstance = _manabit.slots.get(slot)
        if pi == null:
            continue
        var b := Button.new()
        b.text = "%s %s" % [Tokens.slot_glyph(slot), pi.data.display_name]
        b.pressed.connect(_focus_part.bind(slot))
        Tokens.pad_target(b, 44.0)   # a11y gate: tappable part chip gets the full target
        parts.add_child(b)

    var focus_wrap := PanelContainer.new()
    focus_wrap.add_theme_stylebox_override("panel", _pnl(Tokens.PANEL_DEEP, Color(Tokens.BRASS, 0.4)))
    focus_wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
    info.add_child(focus_wrap)
    _focus_pane = VBoxContainer.new()
    focus_wrap.add_child(_focus_pane)
    _focus_hint()

func _focus_hint() -> void:
    _clear(_focus_pane)
    var l := Label.new()
    l.text = "Click a part above to see its stats."
    l.add_theme_color_override("font_color", Color(Tokens.PARCHMENT, 0.5))
    _focus_pane.add_child(l)

func _focus_part(slot: String) -> void:
    var pi: PartInstance = _manabit.slots.get(slot)
    if pi == null:
        return
    _clear(_focus_pane)
    var d := pi.data
    var head := Label.new()
    head.text = "%s %s   (%s · %s)" % [Tokens.slot_glyph(slot), d.display_name, slot, d.rarity]
    head.add_theme_color_override("font_color", Tokens.rarity_frame(d.rarity))
    head.add_theme_font_size_override("font_size", 16)
    _focus_pane.add_child(head)
    var body := Label.new()
    var lines := []
    lines.append("HP %d/%d" % [pi.current_hp, d.max_hp])
    lines.append("ATK %d   DEF %d   SPD %d" % [d.attack, d.defense, d.speed])
    lines.append("WEIGHT %d   ENERGY %d" % [d.weight, d.energy])
    if d.is_core:
        lines.append("Mana core · affinity: %s" % String(d.affinity))
    if d.ability != null:
        var a := d.ability
        var extra := ""
        if a.archetype == "MULTI":
            extra = " ×%d hits" % a.hit_count
        elif a.archetype == "GUARD":
            extra = " (%+d)" % a.guard_amount
        lines.append("Move: %s  pow %d%s  ✦%d" % [a.archetype, a.power, extra, a.mana_cost])
    body.text = "\n".join(lines)
    body.add_theme_color_override("font_color", Tokens.PARCHMENT)
    _focus_pane.add_child(body)

# --- helpers ---
func _reconstruct(entry: Dictionary) -> ManabitState:
    var m := ManabitState.new()
    var cat := Catalog.by_id()
    for p in entry.get("parts", []):
        var pd: PartData = cat.get(String(p.get("id", "")))
        if pd == null:
            continue
        var pi := PartInstance.new(pd)
        pi.current_hp = int(p.get("current_hp", pd.max_hp))
        m.slots[String(p.get("slot", ""))] = pi
    return m

func _archetype(entry: Dictionary) -> String:
    var atk := int(entry.get("atk", 0))
    var df := int(entry.get("def", 0))
    var spd := int(entry.get("spd", 0))
    var en := int(entry.get("mana", 0))
    if df >= atk + 3 and df >= spd:
        return "▸ Bulwark"
    if en >= 16 and en >= atk:
        return "▸ Battery"
    if spd >= atk + 3:
        return "▸ Skirmisher"
    if atk >= 8 and df <= 1:
        return "▸ Glass Cannon"
    if atk >= df + 4:
        return "▸ Bruiser"
    return "▸ All-rounder"

func _pnl(fill: Color, border: Color) -> StyleBoxFlat:
    var sb := StyleBoxFlat.new()
    sb.bg_color = fill
    sb.set_border_width_all(2)
    sb.border_color = border
    sb.set_corner_radius_all(8)
    sb.content_margin_left = 12
    sb.content_margin_right = 12
    sb.content_margin_top = 10
    sb.content_margin_bottom = 10
    return sb

func _clear(box: Node) -> void:
    for c in box.get_children():
        c.queue_free()
