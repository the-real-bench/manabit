class_name BrokerScreen extends Control
# THE BARROW - Fettle's Cart. Buy sealed Coffers + Today's Finds, salvage spares at the Melt & Still,
# claim the Doorstep Coffer. Warm refusals (never silent grey). Buying shows NO reveal (that lives in
# the Coffer Nook). Binds the shared PlayerState; transactions save immediately.

signal done

var player: PlayerState
var _scrap_chip: Label
var _glimmer_chip: Label
var _bark: Label
var _cartboard: VBoxContainer
var _finds: VBoxContainer
var _doorstep: VBoxContainer
var _salvage_box: HBoxContainer
var _fettle: FettlePortrait
var _fx: Control
var _shown_scrap := 0
var _shown_glimmer := 0

const GREET := "Ah - a maker at my counter. Mind the cart; every cog on it was somebody's someday."

func setup(p: PlayerState) -> BrokerScreen:
    player = p
    return self

func _ready() -> void:
    if player == null:
        player = PlayerState.new()
        player.grant_starter_kit()
    _build_layout()
    _shown_scrap = player.scrap
    _shown_glimmer = player.glimmer
    Sfx.play(&"ledger_open")
    Sfx.play(&"fettle_greet")
    if _fettle != null:
        _fettle.pulse(0.3)
    visibility_changed.connect(_on_visibility_changed)
    call_deferred("refresh_from_player")

# The Barrow bed = amb_barrow (canvas wind + bellows ember + cart creak). Rides visibility with a
# 200ms fade that crosses the outgoing screen through near-silence. still_drip stays a one-shot
# garnish on the Still (already wired in _on_distill) - no loop here.
func _on_visibility_changed() -> void:
    if visible:
        Sfx.loop_start(&"amb_barrow", 0.2)
    else:
        Sfx.loop_stop(&"amb_barrow", 0.2)

func _today() -> int:
    return int(Time.get_unix_time_from_system() / 86400.0)

func _panel(fill: Color, border: Color) -> StyleBoxFlat:
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

func _build_layout() -> void:
    set_anchors_preset(Control.PRESET_FULL_RECT)
    var bg := ColorRect.new()
    bg.color = Tokens.BENCH_WALNUT.darkened(0.05)
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

    # top bar
    var top := HBoxContainer.new()
    root.add_child(top)
    var back := Button.new()
    back.text = "◂  Back to the Workshop"
    Tokens.pad_target(back)
    back.pressed.connect(func(): Sfx.play(&"ui_tap"); done.emit())
    top.add_child(back)
    var title := Label.new()
    title.text = "    THE BARROW  -  Fettle's Cart"
    title.add_theme_color_override("font_color", Tokens.BRASS_HI)
    Tokens.display(title, 20)
    top.add_child(title)
    var spacer := Control.new()
    spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    top.add_child(spacer)
    _scrap_chip = _chip(Tokens.BRASS_HI)
    top.add_child(_scrap_chip)
    _glimmer_chip = _chip(Tokens.STAT_ENERGY)
    top.add_child(_glimmer_chip)

    # Fettle row
    var frow := HBoxContainer.new()
    frow.add_theme_constant_override("separation", 12)
    root.add_child(frow)
    _fettle = FettlePortrait.new()
    frow.add_child(_fettle)
    var fbox := VBoxContainer.new()
    fbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    fbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    frow.add_child(fbox)
    var fname := Label.new()
    fname.text = "FETTLE - the first Manabit"
    fname.add_theme_color_override("font_color", Tokens.LAMP_KEY)
    Tokens.display(fname, 18)
    fbox.add_child(fname)
    # BarkRibbon: parchment ground (DESIGN.md §7) so Fettle's voice reads as HIS line, not a form field
    var ribbon := PanelContainer.new()
    var rib_sb := _panel(Tokens.PARCHMENT, Tokens.BRASS)
    ribbon.add_theme_stylebox_override("panel", rib_sb)
    fbox.add_child(ribbon)
    _bark = Label.new()
    _bark.text = GREET
    _bark.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _bark.add_theme_color_override("font_color", Tokens.BENCH_LO)   # dark walnut ink on parchment
    ribbon.add_child(_bark)

    # wares row
    var wares := HBoxContainer.new()
    wares.size_flags_vertical = Control.SIZE_EXPAND_FILL
    wares.add_theme_constant_override("separation", 12)
    root.add_child(wares)
    _cartboard = _ware_column(wares, "THE CARTBOARD  ·  sealed Coffers", 300)
    _finds = _ware_column(wares, "TODAY'S FINDS  ·  woken bits, one each", 340)
    _doorstep = _ware_column(wares, "THE DOORSTEP", 220)

    # salvage strip
    var shead := HBoxContainer.new()
    root.add_child(shead)
    var sh := Label.new()
    sh.text = "THE MELT & THE STILL  -  tap a spare to melt for Scrap, or distill an enchanted one for Glimmer"
    sh.add_theme_font_size_override("font_size", 12)
    sh.add_theme_color_override("font_color", Tokens.BRASS_HI)
    shead.add_child(sh)
    var ssp := Control.new()
    ssp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    shead.add_child(ssp)
    var meltall := Button.new()
    meltall.text = "Melt all common spares  ⚙"
    meltall.pressed.connect(_on_melt_all)
    Tokens.pad_target(meltall)   # destructive bulk action - full target
    shead.add_child(meltall)

    var spanel := PanelContainer.new()
    spanel.custom_minimum_size = Vector2(0, 150)
    spanel.add_theme_stylebox_override("panel", _panel(Tokens.PANEL_DEEP, Color(Tokens.BRASS, 0.3)))
    root.add_child(spanel)
    var scroll := ScrollContainer.new()
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
    scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    spanel.add_child(scroll)
    _salvage_box = HBoxContainer.new()
    _salvage_box.add_theme_constant_override("separation", 8)
    scroll.add_child(_salvage_box)

    _fx = Control.new()                 # persistent juice overlay - stamps/toasts survive rebuilds
    _fx.set_anchors_preset(Control.PRESET_FULL_RECT)
    _fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_fx)

func _ware_column(parent: HBoxContainer, title: String, min_w: float) -> VBoxContainer:
    var col := VBoxContainer.new()
    col.custom_minimum_size = Vector2(min_w, 0)
    col.add_theme_constant_override("separation", 8)
    parent.add_child(col)
    var t := Label.new()
    t.text = title
    t.add_theme_font_size_override("font_size", 12)
    t.add_theme_color_override("font_color", Tokens.BRASS_HI)
    col.add_child(t)
    var body := VBoxContainer.new()
    body.add_theme_constant_override("separation", 8)
    col.add_child(body)
    return body

func refresh_from_player() -> void:
    var today := _today()
    player.refresh_broker(today)
    _roll_chip(_scrap_chip, _shown_scrap, player.scrap, "⚙", Tokens.BRASS_HI)
    _roll_chip(_glimmer_chip, _shown_glimmer, player.glimmer, "✦", Tokens.STAT_ENERGY)
    _shown_scrap = player.scrap
    _shown_glimmer = player.glimmer
    _rebuild_cartboard()
    _rebuild_finds()
    _rebuild_doorstep(today)
    _rebuild_salvage()

func _rebuild_cartboard() -> void:
    _clear(_cartboard)
    _cartboard.add_child(_coffer_ware("tin", "Tin Coffer", PackRoller.odds_line("tin"), Broker.TIN_PRICE))
    _cartboard.add_child(_coffer_ware("brass", "Brass Coffer", PackRoller.odds_line("brass"), Broker.BRASS_PRICE))

func _coffer_ware(kind: String, name: String, odds: String, price: int) -> Control:
    var card := PanelContainer.new()
    card.add_theme_stylebox_override("panel", _panel(Tokens.PANEL_FILL, Tokens.BRASS))
    var v := VBoxContainer.new()
    v.add_theme_constant_override("separation", 3)
    card.add_child(v)
    var nm := Label.new()
    nm.text = "◈ " + name
    nm.add_theme_color_override("font_color", Tokens.PARCHMENT)
    nm.add_theme_font_size_override("font_size", 15)
    v.add_child(nm)
    var od := Label.new()
    od.text = odds
    od.add_theme_font_size_override("font_size", 11)
    od.add_theme_color_override("font_color", Color(Tokens.PARCHMENT, 0.6))
    v.add_child(od)
    var pity := PackRoller.pity_line(kind)
    if pity != "":
        var pl := Label.new()
        pl.text = pity
        pl.add_theme_font_size_override("font_size", 10)
        pl.add_theme_color_override("font_color", Color(Tokens.PARCHMENT, 0.5))
        v.add_child(pl)
    var row := HBoxContainer.new()
    v.add_child(row)
    var afford := player.scrap >= price
    var tag := Label.new()
    tag.text = "⚙ %d" % price
    tag.add_theme_color_override("font_color", Tokens.BRASS_HI if afford else Tokens.STRAIN_TEXT)
    row.add_child(tag)
    if not afford:
        var need := Label.new()
        need.text = "  need ⚙%d more" % (price - player.scrap)
        need.add_theme_font_size_override("font_size", 11)
        need.add_theme_color_override("font_color", Tokens.STRAIN_TEXT)
        row.add_child(need)
    var sp := Control.new()
    sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(sp)
    var buy := Button.new()
    buy.text = "Take it home"
    buy.pressed.connect(_on_buy_coffer.bind(kind, card))
    Tokens.brass_button(buy)   # primary purchase action
    Tokens.pad_target(buy)
    if not afford:
        buy.modulate = Color(1, 1, 1, 0.45)   # same treatment as FindCard; tap still gets Fettle's refusal
    row.add_child(buy)
    return card

func _rebuild_finds() -> void:
    _clear(_finds)
    if player.broker_shelf.is_empty():
        _finds.add_child(_muted("Wake a few Coffers first - Fettle only trades in what you've already met."))
        return
    var cat := Catalog.by_id()
    for i in player.broker_shelf.size():
        var entry: Dictionary = player.broker_shelf[i]
        var pd: PartData = cat.get(String(entry.get("id", "")))
        if pd == null:
            continue
        _finds.add_child(_find_card(i, pd, bool(entry.get("sold", false))))

func _find_card(index: int, pd: PartData, sold: bool) -> Control:
    var card := PanelContainer.new()
    card.add_theme_stylebox_override("panel", _panel(Tokens.PANEL_FILL, Tokens.rarity_frame(pd.rarity)))
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 8)
    card.add_child(row)
    # bit thumbnail (drop-in icon) so the ware is SEEN, not just named
    var icon_path := "res://art/icons/%s.png" % String(pd.id)
    if ResourceLoader.exists(icon_path):
        var ir := TextureRect.new()
        ir.texture = load(icon_path)
        ir.custom_minimum_size = Vector2(44, 44)
        ir.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        ir.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        ir.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        if sold:
            ir.modulate = Color(1, 1, 1, 0.35)
        row.add_child(ir)
    var info := VBoxContainer.new()
    info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(info)
    var nm := Label.new()
    nm.text = "%s %s" % [Tokens.slot_glyph(pd.slot), pd.display_name]
    nm.add_theme_color_override("font_color", Tokens.PARCHMENT if not sold else Color(Tokens.PARCHMENT, 0.4))
    info.add_child(nm)
    var price := Broker.find_price(pd)
    var glim: bool = price["currency"] == "glimmer"
    var afford: bool = (player.glimmer if glim else player.scrap) >= int(price["amount"])
    var tag := Label.new()
    # price keeps its currency color regardless of wallet (emphasis = rarity/ware, NOT affordability)
    tag.text = "%s %d  ·  %s" % ["✦" if glim else "⚙", int(price["amount"]), pd.rarity]
    tag.add_theme_font_size_override("font_size", 12)
    tag.add_theme_color_override("font_color", (Tokens.STAT_ENERGY if glim else Tokens.BRASS_HI) if not sold else Color(Tokens.PARCHMENT, 0.4))
    info.add_child(tag)
    if not afford and not sold:
        # non-color affordability cue (a11y): say exactly what's missing
        var need := Label.new()
        var short := int(price["amount"]) - (player.glimmer if glim else player.scrap)
        need.text = "need %s%d more" % ["✦" if glim else "⚙", short]
        need.add_theme_font_size_override("font_size", 11)
        need.add_theme_color_override("font_color", Ledger.STRAIN_TEXT)
        info.add_child(need)
    if sold:
        var s := Label.new()
        s.text = "- taken -"
        s.add_theme_color_override("font_color", Color(Tokens.WAX, 0.9))
        row.add_child(s)
    else:
        var buy := Button.new()
        buy.text = "BUY"
        buy.pressed.connect(_on_buy_find.bind(index, card))
        Tokens.pad_target(buy)
        if not afford:
            buy.modulate = Color(1, 1, 1, 0.45)   # visibly dimmed; tap still gets Fettle's warm refusal
        row.add_child(buy)
    return card

func _rebuild_doorstep(today: int) -> void:
    _clear(_doorstep)
    var card := PanelContainer.new()
    card.add_theme_stylebox_override("panel", _panel(Tokens.PANEL_FILL, Tokens.BRASS))
    var v := VBoxContainer.new()
    v.add_theme_constant_override("separation", 4)
    card.add_child(v)
    if player.doorstep_available(today):
        var l := Label.new()
        l.text = "◈  A Tin Coffer, left on your step this morning."
        l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        l.add_theme_color_override("font_color", Tokens.PARCHMENT)
        v.add_child(l)
        var claim := Button.new()
        claim.text = "Take the day's gift"
        claim.pressed.connect(_on_claim_doorstep.bind(card))
        Tokens.brass_button(claim)   # free daily claim = always-correct action, deserves brass
        Tokens.pad_target(claim)
        v.add_child(claim)
    else:
        var l := Label.new()
        l.text = "You've got today's. Fettle always leaves one - come back tomorrow."
        l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        l.add_theme_color_override("font_color", Color(Tokens.PARCHMENT, 0.55))
        v.add_child(l)
    _doorstep.add_child(card)

func _rebuild_salvage() -> void:
    _clear(_salvage_box)
    var any := false
    for pi in player.bits:
        if pi.data.is_core:
            continue
        any = true
        _salvage_box.add_child(_salvage_bit(pi))
    if not any:
        _salvage_box.add_child(_muted("No spare bits to melt right now."))

func _salvage_bit(pi: PartInstance) -> Control:
    var card := PanelContainer.new()
    card.custom_minimum_size = Vector2(150, 0)
    card.add_theme_stylebox_override("panel", _panel(Tokens.PANEL_FILL, Tokens.rarity_frame(pi.data.rarity)))
    var v := VBoxContainer.new()
    v.add_theme_constant_override("separation", 3)
    card.add_child(v)
    var nm := Label.new()
    nm.text = pi.data.display_name
    nm.add_theme_font_size_override("font_size", 12)
    nm.add_theme_color_override("font_color", Tokens.PARCHMENT)
    v.add_child(nm)
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 6)
    v.add_child(row)
    var melt := Button.new()
    melt.text = "Melt ⚙%d" % Broker.salvage_scrap(pi.data)
    melt.pressed.connect(_on_melt.bind(pi, card))
    Tokens.pad_target(melt)   # destructive action - full 48dp target (a11y gate)
    row.add_child(melt)
    if Broker.distill_glimmer(pi.data) > 0:
        var still := Button.new()
        still.text = "Still ✦%d" % Broker.distill_glimmer(pi.data)
        still.pressed.connect(_on_distill.bind(pi, card))
        Tokens.pad_target(still)
        row.add_child(still)
    return card

# --- transactions ---  (toasts/stamps read the card rect BEFORE refresh frees it; they live on _fx)
func _on_buy_coffer(kind: String, card: Control) -> void:
    var price := Broker.BRASS_PRICE if kind == "brass" else Broker.TIN_PRICE
    if player.scrap < price:
        _refuse("A few filings short, maker. No shame - melt a spare, or take the day's gift.")
        return
    player.buy_coffer(kind)
    player.save()
    Sfx.play(&"wax_stamp")
    Sfx.play(&"fettle_appraise")
    if _fettle != null:
        _fettle.pulse()
    _stamp(card, "SEALED")
    _toast("−⚙%d" % price, Tokens.WAX, card)
    _bark_say("Salvaged this one a few spirals over. Yours to wake, at your own bench - I never peek.")
    refresh_from_player()

func _on_buy_find(index: int, card: Control) -> void:
    var pd := player.buy_find(index)
    if pd == null:
        _refuse("A little short for that one, maker. The bound ones ask for Glimmer - distill a spare.")
        return
    player.save()
    Sfx.play(&"wax_stamp")
    Sfx.play(&"fettle_appraise")
    if _fettle != null:
        _fettle.pulse()
    _stamp(card, "TAKEN")
    var price := Broker.find_price(pd)
    _toast("−%s%d" % ["✦" if price["currency"] == "glimmer" else "⚙", int(price["amount"])], Tokens.WAX, card)
    _toast("＋1 to the bench", Tokens.BRASS_HI, card, 62.0)
    _bark_say("Good eye. Off it goes to a maker who'll wake it proper.")
    refresh_from_player()

func _on_claim_doorstep(card: Control) -> void:
    if player.claim_doorstep(_today()):
        player.save()
        Sfx.play(&"doorstep_untie")
        if _fettle != null:
            _fettle.pulse()
        _toast("＋◈ Tin", Tokens.BRASS_HI, card)
        _bark_say("Left one on your step this morning. Always do.")
        refresh_from_player()

func _on_melt(pi: PartInstance, card: Control) -> void:
    var g := player.melt_bit(pi)
    if g > 0:
        player.save()
        Sfx.play(&"forge_melt")
        if _fettle != null:
            _fettle.pulse()
        _toast("＋⚙%d" % g, Tokens.BRASS_HI, card)
        _bark_say("Down to warm filings it goes. Nothing's ever wasted here.")
        refresh_from_player()
    else:
        _refuse("Can't melt that one, maker.")

func _on_distill(pi: PartInstance, card: Control) -> void:
    var g := player.distill_bit(pi)
    if g > 0:
        player.save()
        Sfx.play(&"still_drip")
        if _fettle != null:
            _fettle.pulse()
        _toast("＋✦%d" % g, Tokens.STAT_ENERGY, card)
        _bark_say("There's a little bound-light in this one. Caught it proper.")
        refresh_from_player()
    else:
        _refuse("No bound-light in that one, maker - commons hold none.")

func _on_melt_all() -> void:
    var r := player.melt_common_dupes()
    if int(r["count"]) > 0:
        player.save()
        Sfx.play(&"forge_melt")
        if _fettle != null:
            _fettle.pulse()
        _bark_say("Melted %d common spares down.  (＋⚙%d)" % [int(r["count"]), int(r["scrap"])])
        refresh_from_player()
    else:
        _refuse("No common spares to melt, maker - you keep a tidy bench.")

func _roll_chip(chip: Label, from_i: int, to_i: int, prefix: String, home: Color) -> void:
    Juice.odometer(chip, from_i, to_i, prefix)
    if from_i == to_i:
        return
    Sfx.play(&"coin_scrap")
    chip.add_theme_color_override("font_color", Tokens.LAMP_KEY if to_i > from_i else Tokens.WAX)
    Juice.squash_pop(chip, 0.12)
    var tw := chip.create_tween()
    tw.tween_interval(0.22)
    tw.tween_callback(func(): chip.add_theme_color_override("font_color", home))

func _toast(text: String, color: Color, over: Control, rise: float = 40.0) -> void:
    if over == null or _fx == null:
        return
    var l := Label.new()
    l.text = text
    l.add_theme_color_override("font_color", color)
    l.add_theme_font_size_override("font_size", 18)
    l.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _fx.add_child(l)
    var r := over.get_global_rect()
    var start := r.position + Vector2(r.size.x * 0.5 - 20, r.size.y * 0.3)
    l.global_position = start
    var dist := 18.0 if Juice.reduce_motion else rise
    var tw := l.create_tween()
    tw.tween_property(l, "global_position", start + Vector2(0, -dist), 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    tw.parallel().tween_property(l, "modulate:a", 0.0, 0.55)
    tw.tween_callback(l.queue_free)

func _refuse(reason: String) -> void:
    _bark_say(reason)
    # Q8 ruling (audio wave 4a): the warm refusal is fettle_apologise's beat - a descending
    # wood tok pair + bellows sigh, not the combat reject clunk. One seam per beat.
    Sfx.play(&"fettle_apologise")
    if _fettle != null:
        _fettle.apologise()

func _bark_say(text: String) -> void:
    _bark.text = text

func _stamp(node: Control, text: String) -> void:
    if _fx == null or node == null:
        return
    var l := Label.new()
    l.text = text
    l.add_theme_color_override("font_color", Tokens.WAX)
    l.add_theme_font_size_override("font_size", 22)
    l.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _fx.add_child(l)                    # on the overlay, NOT the card refresh() will free
    var r := node.get_global_rect()
    l.global_position = r.position + r.size * 0.5 - Vector2(36, 14)
    Juice.stamp_thunk(l, 0.14)
    var tw := l.create_tween()
    tw.tween_interval(0.5)
    tw.tween_property(l, "modulate:a", 0.0, 0.3)
    tw.tween_callback(l.queue_free)

func _chip(color: Color) -> Label:
    var l := Label.new()
    l.add_theme_color_override("font_color", color)
    l.add_theme_font_size_override("font_size", 15)
    l.custom_minimum_size = Vector2(64, 0)
    return l

func _muted(text: String) -> Label:
    var l := Label.new()
    l.text = text
    l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    l.custom_minimum_size = Vector2(300, 0)
    l.add_theme_color_override("font_color", Color(Tokens.PARCHMENT, 0.5))
    return l

func _clear(box: Node) -> void:
    for c in box.get_children():
        c.queue_free()

# For the screenshot harness.
func debug_touch() -> void:
    refresh_from_player()

func debug_buy() -> void:
    player.scrap = 200
    refresh_from_player()
    if _cartboard.get_child_count() > 0:
        _on_buy_coffer("tin", _cartboard.get_child(0))
