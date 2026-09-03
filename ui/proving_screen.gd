class_name ProvingScreen extends Control
# THE PROVING GROUNDS - pick a challenger to BOUT (real stakes). Loadouts are shown (you loot what you beat).

signal done
signal fight_requested(entry)

var player: PlayerState
var session: BuildSession        # the build that actually fights (wired by root)
var _list: VBoxContainer
var _yours: Label
var _stake_rows: Array = []      # [{entry, btn, need}] - affordability gating (CH-08)

func setup(p: PlayerState) -> ProvingScreen:
    player = p
    return self

func _ready() -> void:
    _build_layout()

func refresh_from_player() -> void:
    # the wager isn't blind on YOUR side either (studio gate): show the build you'd field
    if _yours == null:
        return
    if session == null:
        _yours.text = ""
        return
    var d := session.manabit.derived()
    _yours.text = "YOUR MANABIT   ATK %d · DEF %d · SPD %d · MANA %d" % [int(d.attack), int(d.defense), int(d.speed), int(d.energy)]
    _refresh_stakes()

# CH-08: rows gate on stake affordability - existing dim + "need N more" cue pattern.
func _refresh_stakes() -> void:
    for r in _stake_rows:
        var rd: Dictionary = r
        var stake := PlayerState.bout_stake(rd["entry"])
        var afford := player.scrap >= stake
        var btn: Button = rd["btn"]
        btn.disabled = not afford
        btn.modulate = Color.WHITE if afford else Color(1, 1, 1, 0.45)
        var need: Label = rd["need"]
        need.visible = not afford
        if not afford:
            need.text = "need ⚙%d more" % (stake - player.scrap)

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
    back.pressed.connect(func(): done.emit())
    top.add_child(back)
    var title := Label.new()
    title.text = "    THE PROVING GROUNDS"
    title.add_theme_color_override("font_color", Tokens.BRASS_HI)
    Tokens.display(title, 20)
    top.add_child(title)

    var sub := Label.new()
    sub.text = "Wager your Manabit. Win: loot one of the loser's bits. Lose: forfeit one of your broken bits.  ·  ★ = elite (tougher, richer spoils)"
    sub.add_theme_color_override("font_color", Color(Tokens.PARCHMENT, 0.75))
    root.add_child(sub)

    _yours = Label.new()
    _yours.add_theme_font_size_override("font_size", 14)
    _yours.add_theme_color_override("font_color", Tokens.LAMP_KEY)
    root.add_child(_yours)

    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    root.add_child(scroll)
    _list = VBoxContainer.new()
    _list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _list.add_theme_constant_override("separation", 10)
    scroll.add_child(_list)

    var cat := Catalog.by_id()
    for entry in Challengers.list():
        _list.add_child(_card(entry, cat))
    _refresh_stakes()

func _card(entry: Dictionary, cat: Dictionary) -> Control:
    var card := PanelContainer.new()
    var border := Tokens.RUNEWOOD if bool(entry.get("elite", false)) else Tokens.BRASS
    var sb := StyleBoxFlat.new()
    sb.bg_color = Tokens.PANEL_FILL
    sb.set_border_width_all(2)
    sb.border_color = border
    sb.set_corner_radius_all(8)
    sb.content_margin_left = 14
    sb.content_margin_right = 14
    sb.content_margin_top = 12
    sb.content_margin_bottom = 12
    card.add_theme_stylebox_override("panel", sb)

    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 12)
    card.add_child(row)
    # challenger "face": its HEAD bit's icon (drop-in), falls back to nothing
    for spec in entry["loadout"]:
        var pd0: PartData = cat.get(spec[1])
        if pd0 != null and String(pd0.slot) == "HEAD":
            var icon_path := "res://art/icons/%s.png" % String(pd0.id)
            if ResourceLoader.exists(icon_path):
                var ir := TextureRect.new()
                ir.texture = load(icon_path)
                ir.custom_minimum_size = Vector2(64, 64)
                ir.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
                ir.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
                ir.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
                ir.size_flags_vertical = Control.SIZE_SHRINK_CENTER
                row.add_child(ir)
            break
    var info := VBoxContainer.new()
    info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    info.add_theme_constant_override("separation", 3)
    row.add_child(info)
    var nm := Label.new()
    nm.text = ("★ " if bool(entry.get("elite", false)) else "") + String(entry.get("name", "Challenger"))
    nm.add_theme_color_override("font_color", Tokens.LAMP_KEY)
    nm.add_theme_font_size_override("font_size", 16)
    info.add_child(nm)
    var blurb := Label.new()
    blurb.text = String(entry.get("blurb", ""))
    blurb.add_theme_color_override("font_color", Color(Tokens.PARCHMENT, 0.75))
    blurb.add_theme_font_size_override("font_size", 12)
    info.add_child(blurb)
    # the wager is not blind (studio gate): show what you're actually fighting
    var foe := Challengers.make(entry)
    var fd := foe.derived()
    var stats := HBoxContainer.new()
    stats.add_theme_constant_override("separation", 10)
    info.add_child(stats)
    for pair in [["ATK %d" % int(fd.attack), Tokens.STAT_ATK], ["DEF %d" % int(fd.defense), Tokens.STAT_DEF], ["SPD %d" % int(fd.speed), Tokens.STAT_SPD], ["MANA %d" % int(fd.energy), Tokens.STAT_ENERGY]]:
        var sl := Label.new()
        sl.text = pair[0]
        sl.add_theme_font_size_override("font_size", 12)
        sl.add_theme_color_override("font_color", pair[1])
        stats.add_child(sl)
    # An informed wager needs BOTH numbers. The stake is printed in scrap; the
    # spoils were printed as a list of nouns, so there was nothing to weigh it
    # against. Worth is DERIVED from Broker.salvage_scrap - the same rule the Melt
    # pays out - so the row cannot advertise a value the bit does not carry.
    # You loot exactly ONE bit on a win, so the honest figure is the RANGE across
    # what is lootable, not a total you will never receive.
    var loot := []
    var worths := []
    for spec in entry["loadout"]:
        var pd: PartData = cat.get(spec[1])
        if pd != null and not pd.is_core:
            loot.append(pd.display_name)
            worths.append(Broker.salvage_scrap(pd))
    var spoils := Label.new()
    spoils.text = "Spoils: " + " · ".join(loot)
    if not worths.is_empty():
        var lo: int = worths.min()
        var hi: int = worths.max()
        spoils.text += ("  (melts for ⚙%d)" % lo) if lo == hi else ("  (melts for ⚙%d-%d)" % [lo, hi])
    spoils.add_theme_color_override("font_color", Tokens.BRASS_HI)
    spoils.add_theme_font_size_override("font_size", 12)
    info.add_child(spoils)
    var stake_cost := PlayerState.bout_stake(entry)
    var stake := Label.new()
    stake.text = "Stake: ⚙%d to enter · win to loot one bit · lose and forfeit a broken bit" % stake_cost
    stake.add_theme_font_size_override("font_size", 11)
    stake.add_theme_color_override("font_color", Color(Tokens.PARCHMENT, 0.8))
    info.add_child(stake)

    var side := VBoxContainer.new()
    side.add_theme_constant_override("separation", 3)
    side.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    row.add_child(side)
    var fight := Button.new()
    fight.text = "Fight  ▸  ⚙%d" % stake_cost
    fight.custom_minimum_size = Vector2(120, 0)
    fight.pressed.connect(func(): fight_requested.emit(entry))
    Tokens.brass_button(fight)   # the screen's primary action
    Tokens.pad_target(fight)
    side.add_child(fight)
    var need := Label.new()
    need.add_theme_font_size_override("font_size", 11)
    need.add_theme_color_override("font_color", Tokens.STRAIN_TEXT)
    need.visible = false
    side.add_child(need)
    _stake_rows.append({"entry": entry, "btn": fight, "need": need})
    return card
