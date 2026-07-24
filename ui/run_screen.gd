class_name RunScreen extends Control
# THE RUN - carry one Manabit down the branching road. Fights damage it (persists); rests repair
# (scrap) and offer extraction (bank to Menagerie); core-death ends the run and loses the
# construct. Junctions (DESIGN.md 8) fork the road: two PathCards, a two-step commit, and one
# honest modifier per lane. tailwind/second_wind mends run HERE (outside combat.gd) via RunMods.

signal done                          # run finished -> back to the Workshop
signal fight_requested(node)         # ask root to launch a run fight

var player: PlayerState
var run: RunState
var _end_msg := ""

var _title: Label
var _mod_banner: PanelContainer      # ModifierBanner - the lane rule pill (DESIGN.md 8)
var _route_bed: PanelContainer       # RouteBed - fixed-height map strip
var _route_rail: RouteRail           # rail draw pass under the chips
var _route_cols: HBoxContainer       # five 150px chip columns
var _stage: ManabitStage
var _parts: VBoxContainer
var _action: VBoxContainer
var _status: Label
var _abandon_btn: Button
var _sel_lane := -1                  # PathCard selection (two-step commit)
var _sel_pos := -1                   # which junction the selection belongs to
var _death_faded := false            # run-over death glow fade fired once
var _shrine_open := false            # Wayside Shrine vignette open (screen state, not button state)
var _shrine_sel := -1                # EventCard selection (two-step commit, PathCard discipline)
var _abandon_armed := false          # own-build two-step abandon (screen state - refresh disarms)

func setup(p: PlayerState) -> RunScreen:
    player = p
    return self

func _ready() -> void:
    _build_layout()
    visibility_changed.connect(_on_visibility_changed)

# The Run bed = amb_run (dry road wind + leather creak). Rides visibility with a 200ms fade that
# crosses the outgoing screen through near-silence (audio-full-game.md section 4). During a run
# fight the Run screen hides and the bed fades out - combat has no bed of its own (its room tone
# is the two core hums, lane B2) - then fades back when the fight returns to the road.
func _on_visibility_changed() -> void:
    if visible:
        Sfx.loop_start(&"amb_run", 0.2)
    else:
        Sfx.loop_stop(&"amb_run", 0.2)

func begin(r: RunState) -> void:
    run = r
    _end_msg = ""
    _sel_lane = -1
    _sel_pos = -1
    _death_faded = false
    _shrine_open = false
    _shrine_sel = -1
    _abandon_armed = false
    refresh()

func _build_layout() -> void:
    set_anchors_preset(Control.PRESET_FULL_RECT)
    var bg := ColorRect.new()
    bg.color = Tokens.BENCH_LO
    bg.set_anchors_preset(Control.PRESET_FULL_RECT)
    bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(bg)

    var root := VBoxContainer.new()
    root.set_anchors_preset(Control.PRESET_FULL_RECT)
    root.offset_left = 18
    root.offset_top = 12
    root.offset_right = -18
    root.offset_bottom = -14
    root.add_theme_constant_override("separation", 10)
    add_child(root)

    var top := HBoxContainer.new()
    top.add_theme_constant_override("separation", 12)
    root.add_child(top)
    _title = Label.new()
    _title.add_theme_color_override("font_color", Tokens.BRASS_HI)
    _title.add_theme_font_size_override("font_size", 18)
    top.add_child(_title)
    # ModifierBanner (DESIGN.md 8): the current lane's rule, between the title and Abandon
    _mod_banner = PanelContainer.new()
    _mod_banner.custom_minimum_size = Vector2(0, 26)
    var pill := StyleBoxFlat.new()
    pill.bg_color = Tokens.PANEL_FILL
    pill.set_border_width_all(2)
    pill.border_color = Color(Tokens.BRASS, 0.6)
    pill.set_corner_radius_all(13)
    pill.content_margin_left = 10
    pill.content_margin_right = 10
    pill.content_margin_top = 2
    pill.content_margin_bottom = 2
    _mod_banner.add_theme_stylebox_override("panel", pill)
    _mod_banner.visible = false
    top.add_child(_mod_banner)
    var sp := Control.new()
    sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    top.add_child(sp)
    _abandon_btn = Button.new()
    _abandon_btn.text = "Abandon run"
    _abandon_btn.pressed.connect(_on_abandon)
    top.add_child(_abandon_btn)

    # RouteBed (DESIGN.md 8): FIXED 108px strip - rail draw pass under five mouse-ignored columns
    _route_bed = PanelContainer.new()
    _route_bed.custom_minimum_size = Vector2(0, 108)
    var bed := StyleBoxFlat.new()
    bed.bg_color = Tokens.PANEL_DEEP
    bed.set_border_width_all(2)
    bed.border_color = Color(Tokens.BRASS, 0.4)
    bed.set_corner_radius_all(8)
    bed.content_margin_left = 12
    bed.content_margin_right = 12
    bed.content_margin_top = 6
    bed.content_margin_bottom = 6
    _route_bed.add_theme_stylebox_override("panel", bed)
    root.add_child(_route_bed)
    _route_rail = RouteRail.new()
    _route_rail.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _route_bed.add_child(_route_rail)
    var center := CenterContainer.new()
    center.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _route_bed.add_child(center)
    _route_cols = HBoxContainer.new()
    _route_cols.add_theme_constant_override("separation", 8)
    _route_cols.mouse_filter = Control.MOUSE_FILTER_IGNORE
    center.add_child(_route_cols)

    var mid := HBoxContainer.new()
    mid.size_flags_vertical = Control.SIZE_EXPAND_FILL
    mid.add_theme_constant_override("separation", 16)
    root.add_child(mid)

    var carried_col := VBoxContainer.new()
    carried_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    carried_col.add_theme_constant_override("separation", 6)
    mid.add_child(carried_col)
    var ct := Label.new()
    ct.text = "YOUR MANABIT"
    ct.add_theme_color_override("font_color", Tokens.BRASS_HI)
    ct.add_theme_font_size_override("font_size", 14)
    carried_col.add_child(ct)
    _stage = ManabitStage.new()
    _stage.custom_minimum_size = Vector2(0, 240)
    _stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
    carried_col.add_child(_stage)
    _parts = VBoxContainer.new()
    _parts.add_theme_constant_override("separation", 4)
    carried_col.add_child(_parts)

    var right := PanelContainer.new()
    right.custom_minimum_size = Vector2(380, 0)
    right.add_theme_stylebox_override("panel", _pnl(Tokens.PANEL_FILL, Tokens.BRASS))
    mid.add_child(right)
    _action = VBoxContainer.new()
    _action.add_theme_constant_override("separation", 10)
    right.add_child(_action)

    _status = Label.new()
    _status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _status.add_theme_color_override("font_color", Tokens.LAMP_KEY)
    root.add_child(_status)

func refresh() -> void:
    if run == null:
        return
    _abandon_armed = false           # any other interaction disarms the two-step abandon (never a timer)
    if run.is_kit:
        var salvage := "⚙%d" % run.satchel_scrap
        if run.satchel_bit_id != "":
            salvage += " + 1 bit"
        _title.text = "THE RUN  -  Box of Scrap  ·  salvage %s" % salvage
        _abandon_btn.text = "Head home  ▸"
    else:
        _title.text = "THE RUN  -  %s" % run.mname
        _abandon_btn.text = "Abandon run"
    _stage.rebuild(run.carried)
    _build_map()
    _build_mod_banner()
    _build_parts()
    _build_action()
    _status.text = _end_msg

# --- RouteBed (DESIGN.md 8) -------------------------------------------------------------------

func _build_map() -> void:
    for c in _route_cols.get_children():
        c.queue_free()
    var cols: Array = []
    for i in run.map.size():
        var nd: Dictionary = run.map[i]
        var col := VBoxContainer.new()
        col.custom_minimum_size = Vector2(150, 0)
        col.alignment = BoxContainer.ALIGNMENT_CENTER
        col.add_theme_constant_override("separation", 8)
        col.mouse_filter = Control.MOUSE_FILTER_IGNORE
        var meta := {"kind": "single", "a": null, "b": null}
        if String(nd.get("type", "")) == "JUNCTION":
            # forked chip: two 44px lane chips with modifier straps, until chosen
            var paths: Array = nd.get("paths", [])
            var la := _lane_chip(paths[0], i, 0)
            var lb := _lane_chip(paths[1], i, 1)
            col.add_child(la)
            col.add_child(lb)
            meta = {"kind": "split", "a": la, "b": lb}
        else:
            var chip := _node_chip(nd, i)
            col.add_child(chip)
            meta = {"kind": "single", "a": chip, "b": null}
            if nd.has("road_not_taken"):
                # the unchosen lane stays as a ghost chip forever - honest history
                var ghost := _ghost_chip(String(nd.get("road_not_taken", "")), nd)
                col.add_child(ghost)
                meta = {"kind": "collapsed", "a": chip, "b": ghost}
        cols.append(meta)
        _route_cols.add_child(col)
    _route_rail.cols = cols
    _route_rail.walked = run.pos
    _route_rail.preview_col = run.pos if (run.at_junction() and _sel_pos == run.pos) else -1
    _route_rail.preview_lane = _sel_lane if _route_rail.preview_col >= 0 else -1
    if run.over and not run.banked:
        # run-over death: 400ms glow fade, instant under reduce-motion
        if not _death_faded:
            _death_faded = true
            if Juice.reduce_motion:
                _route_rail.glow_a = 0.25
            else:
                var setter := func(v: float):
                    _route_rail.glow_a = v
                    _route_rail.queue_redraw()
                _route_rail.create_tween().tween_method(setter, 0.6, 0.25, 0.4)
    else:
        _route_rail.glow_a = 0.6     # banked or mid-run: the glow stays warm
    _route_rail.queue_redraw()

# a normal walked-road chip (FIGHT / REST / collapsed junction lane)
func _node_chip(nd: Dictionary, i: int) -> PanelContainer:
    var chip := PanelContainer.new()
    chip.custom_minimum_size = Vector2(150, 0)
    chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var current := (i == run.pos and not run.over)
    var passed := (i < run.pos or run.over)
    var col := Tokens.BRASS if current else Color(Tokens.BRASS, 0.3 if not passed else 0.5)
    chip.add_theme_stylebox_override("panel", _chip_pnl(Tokens.PANEL_FILL if current else Tokens.PANEL_DEEP, col))
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 4)
    row.mouse_filter = Control.MOUSE_FILTER_IGNORE
    chip.add_child(row)
    if current:
        # CoreLightMarker: glow dot from the carried core's affinity color
        var core := run.carried.core() if run.carried != null else null
        if core != null:
            var dot := Label.new()
            dot.text = "●"
            dot.add_theme_font_size_override("font_size", 12)
            dot.add_theme_color_override("font_color", Tokens.affinity_color(String(core.data.affinity)))
            row.add_child(dot)
    var l := Label.new()
    var mark := "▸ " if current else ("✓ " if passed else "")
    var icon := "★" if bool(nd.get("boss", false)) else ("⚔" if nd.get("type", "") == "FIGHT" else _rest_glyph(nd))
    l.text = "%s%s %s" % [mark, icon, String(nd.get("label", ""))]
    l.add_theme_font_size_override("font_size", 12)
    l.add_theme_color_override("font_color", Tokens.LAMP_KEY if current else Color(Tokens.PARCHMENT, 0.6 if passed else 0.35))
    row.add_child(l)
    if current and not Juice.reduce_motion:
        # --chip-breath ~2s loop
        var tw := chip.create_tween().set_loops()
        tw.tween_property(chip, "modulate:a", 0.82, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
        tw.tween_property(chip, "modulate:a", 1.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    return chip

# one 44px junction lane chip: modifier strap over the node line
func _lane_chip(lane: Dictionary, i: int, lane_i: int) -> PanelContainer:
    var nd: Dictionary = lane["node"]
    var mod: Dictionary = lane["modifier"]
    var chip := PanelContainer.new()
    chip.custom_minimum_size = Vector2(150, 44)
    chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var current := (i == run.pos and not run.over)
    var selected := current and _sel_pos == run.pos and _sel_lane == lane_i
    var border := Tokens.BRASS_HI if selected else (Tokens.BRASS if current else Color(Tokens.BRASS, 0.3))
    var sb := _chip_pnl(Tokens.PANEL_FILL if current else Tokens.PANEL_DEEP, border)
    sb.content_margin_top = 3
    sb.content_margin_bottom = 3
    chip.add_theme_stylebox_override("panel", sb)
    var v := VBoxContainer.new()
    v.add_theme_constant_override("separation", 0)
    v.mouse_filter = Control.MOUSE_FILTER_IGNORE
    chip.add_child(v)
    var strap := Label.new()
    strap.text = "%s %s" % [String(mod.get("glyph", "")), String(mod.get("name", "")).to_upper()]
    strap.add_theme_font_size_override("font_size", 10)
    strap.add_theme_color_override("font_color", Tokens.BRASS_HI)   # 9.8:1 on PANEL_DEEP - passes
    v.add_child(strap)
    var line := Label.new()
    var icon := "★" if bool(nd.get("boss", false)) else "⚔"
    line.text = "%s %s" % [icon, String(lane.get("lane_name", ""))]
    line.add_theme_font_size_override("font_size", 12)
    line.add_theme_color_override("font_color", Tokens.LAMP_KEY if current else Color(Tokens.PARCHMENT, 0.5))
    v.add_child(line)
    return chip

# the road not taken - a bypassed ghost chip at 0.15 alpha, forever
func _ghost_chip(lane_name: String, nd: Dictionary) -> PanelContainer:
    var chip := PanelContainer.new()
    chip.custom_minimum_size = Vector2(150, 44)
    chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
    chip.modulate.a = 0.15
    chip.add_theme_stylebox_override("panel", _chip_pnl(Tokens.PANEL_DEEP, Color(Tokens.BRASS, 0.5)))
    var l := Label.new()
    var icon := "★" if bool(nd.get("boss", false)) else "⚔"
    l.text = "%s %s" % [icon, lane_name]
    l.add_theme_font_size_override("font_size", 12)
    l.add_theme_color_override("font_color", Tokens.PARCHMENT)
    chip.add_child(l)
    return chip

func _chip_pnl(fill: Color, border: Color) -> StyleBoxFlat:
    var sb := StyleBoxFlat.new()
    sb.bg_color = fill
    sb.set_border_width_all(2)
    sb.border_color = border
    sb.set_corner_radius_all(8)
    sb.content_margin_left = 8
    sb.content_margin_right = 8
    sb.content_margin_top = 6
    sb.content_margin_bottom = 6
    return sb

func _build_mod_banner() -> void:
    for c in _mod_banner.get_children():
        c.queue_free()
    var show := false
    if run != null and not run.over and not run.at_junction():
        var mod: Dictionary = run.node().get("modifier", {})
        if not mod.is_empty():
            show = true
            var l := Label.new()
            l.text = "%s %s - %s" % [String(mod.get("glyph", "")), String(mod.get("name", "")), String(mod.get("blurb", ""))]
            l.add_theme_font_size_override("font_size", 12)
            l.add_theme_color_override("font_color", Tokens.BRASS_HI)
            _mod_banner.add_child(l)
    _mod_banner.visible = show

func _build_parts() -> void:
    for c in _parts.get_children():
        c.queue_free()
    for slot in ManabitState.SLOT_NAMES:
        var pi: PartInstance = run.carried.slots.get(slot)
        if pi == null:
            continue
        var row := HBoxContainer.new()
        row.add_theme_constant_override("separation", 6)
        var is_core := pi.data.is_core
        var tag := Label.new()
        tag.text = "%s %s" % [Tokens.slot_glyph(slot), ("CORE ❤" if is_core else pi.data.display_name)]
        tag.custom_minimum_size = Vector2(150, 0)
        tag.add_theme_font_size_override("font_size", 12)
        tag.add_theme_color_override("font_color", Tokens.LAMP_KEY if is_core else (Color(Tokens.PARCHMENT, 0.35) if pi.disabled else Tokens.PARCHMENT))
        row.add_child(tag)
        var bar := ProgressBar.new()
        bar.custom_minimum_size = Vector2(120, 13)
        bar.min_value = 0
        bar.max_value = pi.data.max_hp
        bar.value = pi.current_hp
        bar.show_percentage = false
        bar.modulate = Tokens.STAT_ATK if is_core else (Color(0.5, 0.5, 0.5) if pi.disabled else Tokens.STAT_SPD)
        row.add_child(bar)
        var hp := Label.new()
        hp.text = "%d/%d" % [pi.current_hp, pi.data.max_hp]
        hp.add_theme_font_size_override("font_size", 11)
        hp.add_theme_color_override("font_color", Color(Tokens.PARCHMENT, 0.7))
        row.add_child(hp)
        _parts.add_child(row)

func _build_action() -> void:
    for c in _action.get_children():
        c.queue_free()
    if run.over:
        var l := Label.new()
        l.text = _end_msg if _end_msg != "" else "The run is over."
        l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        l.add_theme_color_override("font_color", Tokens.LAMP_KEY)
        l.add_theme_font_size_override("font_size", 16)
        _action.add_child(l)
        var back := Button.new()
        back.text = "◂  Return to the Workshop"
        back.pressed.connect(func(): Sfx.play(&"ui_tap"); done.emit())
        _action.add_child(back)
        return

    var nd := run.node()
    var ntype := String(nd.get("type", ""))
    if ntype == "JUNCTION":
        _build_junction(nd)
        return
    if ntype == "REST" and _shrine_open and String(nd.get("flavor", "")) == "event":
        _build_shrine(nd)            # the shrine speaks on the way OUT - the bench worked first
        return
    var head := Label.new()
    head.text = ("★ " if bool(nd.get("boss", false)) else "") + String(nd.get("label", ""))
    head.add_theme_color_override("font_color", Tokens.LAMP_KEY)
    head.add_theme_font_size_override("font_size", 18)
    _action.add_child(head)

    if ntype == "FIGHT":
        var ch: Dictionary = nd.get("challenger", {})
        var desc := Label.new()
        desc.text = "%s\n%s" % [String(ch.get("name", "")), String(ch.get("blurb", ""))]
        desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        desc.add_theme_color_override("font_color", Color(Tokens.PARCHMENT, 0.8))
        _action.add_child(desc)
        if bool(nd.get("aims_core", false)):
            var warn := Label.new()
            warn.text = "⚠ This one aims for the core - losing here unmakes your Manabit."
            warn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
            warn.add_theme_color_override("font_color", Tokens.STAT_WEIGHT_OVER)
            warn.add_theme_font_size_override("font_size", 12)
            _action.add_child(warn)
        var fight := Button.new()
        fight.text = "Fight  ▸"
        fight.pressed.connect(_on_fight.bind(nd))
        _action.add_child(fight)
    else:   # REST
        var flavor := String(nd.get("flavor", "camp"))
        var last_lantern := run.pos == 3
        var rest := Label.new()
        if last_lantern and not run.is_kit:
            # honest-information copy (5.3a): the final exit is named from the bench itself
            rest.text = "The last lantern. Past this bench, the road only goes to the gate."
        elif run.is_kit:
            rest.text = "A quiet workbench. You paw through the box for something to patch it with."
        else:
            rest.text = "A quiet workbench. Patch your Manabit up, or bank it and walk away."
        rest.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        rest.add_theme_color_override("font_color", Color(Tokens.PARCHMENT, 0.8))
        _action.add_child(rest)
        if run.is_damaged():
            if run.is_kit:
                # Free mend: a ⚙0 player can never dead-end mid-recovery.
                var mend := Button.new()
                mend.text = "Cobble it back together  ▸  (free - it's only scrap)"
                mend.pressed.connect(func(): run.repair_all(); _status.text = "Mended - good as new."; refresh())
                _action.add_child(mend)
            else:
                var cost := run.repair_cost()
                var rep := Button.new()
                rep.text = "Repair all  ⚙%d" % cost
                rep.pressed.connect(_on_repair.bind(cost))
                _action.add_child(rep)
        else:
            var full := Label.new()
            full.text = "Fully mended."
            full.add_theme_color_override("font_color", Tokens.DELTA_POS)
            _action.add_child(full)
        if flavor == "scrapyard":
            _build_heap_stall(nd)    # one stall row above Press on - the bench IS the heap
        if run.is_kit:
            # No Extract - a Box is never yours to bank. Head home keeps the salvage.
            var home := Button.new()
            home.text = "Head home - pocket the salvage  ▸"
            home.pressed.connect(func(): _finish_kit(true, "Home safe - you tip the salvage onto your bench."))
            _action.add_child(home)
        else:
            var extract := Button.new()
            extract.text = "Extract  -  bank %s to the Menagerie  ▸" % run.mname
            extract.pressed.connect(func(): _finish(true, "Extracted - %s is safe in your Menagerie." % run.mname))
            _action.add_child(extract)
        var press := Button.new()
        if last_lantern and not run.is_kit:
            press.text = "Press on - no way back after this  ▸"   # honest-information copy (5.3b)
        else:
            press.text = "Press on  ▸"
        if flavor == "event" and not bool(nd.get("resolved", false)):
            # only the FORWARD verb passes the shrine - extract / Head home walk away freely
            press.pressed.connect(func():
                Sfx.play(&"fork_reveal")
                _shrine_open = true
                _shrine_sel = -1
                refresh())
        else:
            press.pressed.connect(func(): Sfx.play(&"route_step"); run.advance(); refresh())
        _action.add_child(press)

# Fight button: tailwind mends BEFORE the bell and the banked Second Wind core pad lands at the
# same pre-bell seam (outside combat.gd), then the fight launches. The shrine rider is consumed
# by root at the same seam, on its way into Challengers.make.
func _on_fight(nd: Dictionary) -> void:
    var mended := RunMods.pre_fight_mend(run)
    var padded := RunMods.consume_core_pad(run)
    if mended > 0 or padded > 0:
        _build_parts()               # the HP rows are the stakes readout - show the mend
        var msgs: Array[String] = []
        if mended > 0:
            msgs.append("Tail-Wind - mended %d HP before the bell." % mended)
        if padded > 0:
            msgs.append("Second Wind - your core steps in carrying +%d HP." % padded)
        _status.text = "  ".join(msgs)
    fight_requested.emit(nd)

# --- The Wayside Shrine (wave 3, spec 2): departure-side vignette + two EventCards ------------

func _rest_glyph(nd: Dictionary) -> String:
    match String(nd.get("flavor", "")):
        "event":
            return "✶"
        "scrapyard":
            return "⚒"
        _:
            return "⛺"

func _build_shrine(nd: Dictionary) -> void:
    var e := RunEvents.event(String(nd.get("event_id", "")))
    if e.is_empty():
        # fail-safe: a bad id must never gate the road (G13 - the forward verb stays alive)
        _shrine_open = false
        run.advance()
        refresh()
        return
    var head := Label.new()
    head.text = String(e["name"])
    head.add_theme_color_override("font_color", Tokens.LAMP_KEY)
    head.add_theme_font_size_override("font_size", 18)
    _action.add_child(head)
    var vig := Label.new()
    var lines: Array = e["vignette"]
    vig.text = "\n".join(PackedStringArray(lines))
    vig.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    vig.add_theme_color_override("font_color", Color(Tokens.PARCHMENT, 0.8))
    _action.add_child(vig)
    if bool(nd.get("resolved", false)):
        var res := Label.new()
        res.text = String(nd.get("result_text", ""))
        res.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        res.add_theme_color_override("font_color", Tokens.LAMP_KEY)
        _action.add_child(res)
        var onward := Button.new()
        onward.custom_minimum_size = Vector2(0, 48)
        onward.text = "Onward  ▸"
        Tokens.brass_button(onward)
        onward.pressed.connect(func():
            Sfx.play(&"route_step")
            _shrine_open = false
            run.advance()
            refresh())
        _action.add_child(onward)
        return
    _action.add_child(_event_card(e["safe"], 0))
    _action.add_child(_event_card(e["push"], 1))
    var commit := Button.new()
    commit.custom_minimum_size = Vector2(0, 48)
    if _shrine_sel >= 0:
        commit.text = "Choose  ▸"
        Tokens.brass_button(commit)
        commit.pressed.connect(_on_shrine_commit)
    else:
        commit.text = "Pick one first"
        commit.disabled = true
    _action.add_child(commit)

# One EventCard: choice title + the honest stakes line (the stakes line IS the rule, verbatim).
# Exact PathCard discipline: tap-select BRASS_HI border, then the brass Choose commits.
func _event_card(choice: Dictionary, i: int) -> Button:
    var selected := (i == _shrine_sel)
    var card := Button.new()
    card.custom_minimum_size = Vector2(356, 78)
    var border := Tokens.BRASS_HI if selected else Color(Tokens.BRASS, 0.5)
    card.add_theme_stylebox_override("normal", _card_pnl(Tokens.PANEL_FILL, border))
    card.add_theme_stylebox_override("hover", _card_pnl(Tokens.PANEL_FILL.lightened(0.04), border))
    card.add_theme_stylebox_override("pressed", _card_pnl(Tokens.PANEL_FILL.darkened(0.06), Tokens.BRASS_HI))
    card.add_theme_stylebox_override("focus", _card_pnl(Tokens.PANEL_FILL, Tokens.BRASS_HI))
    card.pressed.connect(func(): Sfx.play(&"ui_tap"); _shrine_sel = i; refresh())
    var v := VBoxContainer.new()
    v.set_anchors_preset(Control.PRESET_FULL_RECT)
    v.add_theme_constant_override("separation", 2)
    v.mouse_filter = Control.MOUSE_FILTER_IGNORE
    card.add_child(v)
    var nm := Label.new()
    nm.text = String(choice.get("title", ""))
    Tokens.display(nm, 16)
    nm.add_theme_color_override("font_color", Tokens.LAMP_KEY)
    nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
    v.add_child(nm)
    var st := Label.new()
    st.text = String(choice.get("stakes", ""))
    st.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    st.add_theme_font_size_override("font_size", 12)
    st.add_theme_color_override("font_color", Color(Tokens.PARCHMENT, 0.8))
    st.mouse_filter = Control.MOUSE_FILTER_IGNORE
    v.add_child(st)
    return card

func _on_shrine_commit() -> void:
    if _shrine_sel < 0:
        return
    Sfx.play(&"switch_throw")
    var res := RunEvents.resolve(run, _shrine_sel)
    _shrine_sel = -1
    refresh()
    if res.is_empty():
        return
    Sfx.play(&"ui_tap" if String(res["result_id"]) == "bad" else &"reveal_rare")
    var msgs: Array[String] = []
    if int(res.get("mended", 0)) > 0:
        msgs.append("mended %d HP" % int(res["mended"]))
    if int(res.get("wore", 0)) > 0:
        msgs.append("wore %d HP" % int(res["wore"]))
    if int(res.get("rider", 0)) > 0:
        msgs.append("the next foe steps in worn %d" % int(res["rider"]))
    if not msgs.is_empty():
        _status.text = "The shrine's due - " + ", ".join(msgs) + "."

# --- Magpie's Heap (wave 3, spec 3): the rummage stall on the Template B pos1 rest ------------

func _build_heap_stall(nd: Dictionary) -> void:
    if not run.is_kit:
        # own builds see the plain rest plus one line of heap flavor - no stalls (spec 3.1)
        var flav := Label.new()
        flav.text = "The magpie's heap shifts and settles. Whatever it keeps, it keeps for the scrap-boxes."
        flav.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        flav.add_theme_font_size_override("font_size", 12)
        flav.add_theme_color_override("font_color", Color(Tokens.PARCHMENT, 0.7))
        _action.add_child(flav)
        return
    if run.heap_rummaged or bool(nd.get("rummaged", false)):
        return                       # once per run - the result already landed in _status
    var stall := Label.new()
    stall.text = "The heap shifts when you look at it. Something in there is still good."
    stall.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    stall.add_theme_color_override("font_color", Color(Tokens.PARCHMENT, 0.8))
    _action.add_child(stall)
    var dig := Button.new()
    dig.custom_minimum_size = Vector2(0, 44)
    dig.text = "Rummage the heap  ⚙8"
    if run.satchel_scrap < RunState.RUMMAGE_PRICE:
        dig.disabled = true
        _action.add_child(dig)
        var broke := Label.new()
        broke.text = "The magpie eyes your light satchel and shakes its head. Kindly.  (need ⚙%d more)" \
            % (RunState.RUMMAGE_PRICE - run.satchel_scrap)
        broke.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        broke.add_theme_font_size_override("font_size", 11)
        broke.add_theme_color_override("font_color", Color(Tokens.PARCHMENT, 0.6))
        _action.add_child(broke)
    else:
        dig.pressed.connect(_on_rummage)
        _action.add_child(dig)

func _on_rummage() -> void:
    var res := run.rummage(player.compendium)
    if res.is_empty():
        return
    refresh()
    if String(res["kind"]) == "filings":
        Sfx.play(&"coin_scrap")
        _status.text = "Mostly rust. ＋⚙4 in filings, at least."
    else:
        Sfx.play(&"reveal_rare")
        _status.text = "Buried treasure - a %s! It rides with the box til home." % String(res["name"])

# --- The junction action panel (DESIGN.md 8): two PathCards + a two-step commit ---------------

func _build_junction(nd: Dictionary) -> void:
    if _sel_pos != run.pos:
        _sel_pos = run.pos
        _sel_lane = -1
        Sfx.play(&"fork_reveal")
    var head := Label.new()
    head.text = "The road forks here"
    head.add_theme_color_override("font_color", Tokens.BRASS_HI)
    head.add_theme_font_size_override("font_size", 14)
    _action.add_child(head)
    if not run.is_kit and String(nd.get("tier", "")) == "boss":
        # honest-information copy (5.3c) - scoped to the construct, not the loot; do not tighten
        var sub := Label.new()
        sub.text = "The road only goes forward from here."
        sub.add_theme_font_size_override("font_size", 12)
        sub.add_theme_color_override("font_color", Color(Tokens.PARCHMENT, 0.8))
        _action.add_child(sub)
    var paths: Array = nd.get("paths", [])
    for i in paths.size():
        _action.add_child(_path_card(paths[i], i))
    var commit := Button.new()
    commit.custom_minimum_size = Vector2(0, 48)
    if _sel_lane >= 0:
        commit.text = "Take this path"
        Tokens.brass_button(commit)
        commit.pressed.connect(_on_commit_path)
    else:
        commit.text = "Pick a path first"
        commit.disabled = true
    _action.add_child(commit)

func _path_card(lane: Dictionary, i: int) -> Button:
    var nd: Dictionary = lane["node"]
    var entry: Dictionary = nd.get("challenger", {})
    var mod: Dictionary = lane["modifier"]
    var selected := (i == _sel_lane)
    var card := Button.new()
    card.custom_minimum_size = Vector2(356, 120)
    var border := Tokens.BRASS_HI if selected else Color(Tokens.BRASS, 0.5)
    card.add_theme_stylebox_override("normal", _card_pnl(Tokens.PANEL_FILL, border))
    card.add_theme_stylebox_override("hover", _card_pnl(Tokens.PANEL_FILL.lightened(0.04), border))
    card.add_theme_stylebox_override("pressed", _card_pnl(Tokens.PANEL_FILL.darkened(0.06), Tokens.BRASS_HI))
    card.add_theme_stylebox_override("focus", _card_pnl(Tokens.PANEL_FILL, Tokens.BRASS_HI))
    card.pressed.connect(func(): Sfx.play(&"ui_tap"); _sel_lane = i; _sel_pos = run.pos; refresh())
    var v := VBoxContainer.new()
    v.set_anchors_preset(Control.PRESET_FULL_RECT)
    v.add_theme_constant_override("separation", 2)
    v.mouse_filter = Control.MOUSE_FILTER_IGNORE
    card.add_child(v)
    var nm := Label.new()
    nm.text = String(lane.get("lane_name", ""))
    Tokens.display(nm, 16)
    nm.add_theme_color_override("font_color", Tokens.LAMP_KEY)
    nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
    v.add_child(nm)
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 8)
    row.mouse_filter = Control.MOUSE_FILTER_IGNORE
    v.add_child(row)
    # challenger face: its HEAD bit's icon - the same asset path the Proving rows use
    var cat := Catalog.by_id()
    for spec in entry.get("loadout", []):
        var pd0: PartData = cat.get(spec[1])
        if pd0 != null and String(pd0.slot) == "HEAD":
            var icon_path := "res://art/icons/%s.png" % String(pd0.id)
            if ResourceLoader.exists(icon_path):
                var ir := TextureRect.new()
                ir.texture = load(icon_path)
                ir.custom_minimum_size = Vector2(40, 40)
                ir.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
                ir.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
                ir.mouse_filter = Control.MOUSE_FILTER_IGNORE
                row.add_child(ir)
            break
    var cn := Label.new()
    cn.text = String(entry.get("name", ""))
    cn.add_theme_font_size_override("font_size", 13)
    cn.add_theme_color_override("font_color", Tokens.PARCHMENT)
    cn.mouse_filter = Control.MOUSE_FILTER_IGNORE
    row.add_child(cn)
    # modifier line: the rule text IS the card text, verbatim from RunMods.TABLE
    var ml := HBoxContainer.new()
    ml.add_theme_constant_override("separation", 0)
    ml.mouse_filter = Control.MOUSE_FILTER_IGNORE
    v.add_child(ml)
    var mn := Label.new()
    mn.text = String(mod.get("name", ""))
    mn.add_theme_font_size_override("font_size", 13)
    mn.add_theme_color_override("font_color", Tokens.BRASS_HI)
    mn.mouse_filter = Control.MOUSE_FILTER_IGNORE
    ml.add_child(mn)
    var mr := Label.new()
    mr.text = " - " + String(mod.get("blurb", ""))
    mr.add_theme_font_size_override("font_size", 12)
    mr.add_theme_color_override("font_color", Color(Tokens.PARCHMENT, 0.8))
    mr.mouse_filter = Control.MOUSE_FILTER_IGNORE
    ml.add_child(mr)
    # both lanes aim the core at every junction - word and glyph, never color alone
    var warn := Label.new()
    warn.text = "⚠ This one aims for the core - losing here unmakes your Manabit."
    warn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    warn.add_theme_font_size_override("font_size", 11)
    warn.add_theme_color_override("font_color", Tokens.STAT_WEIGHT_OVER)
    warn.mouse_filter = Control.MOUSE_FILTER_IGNORE
    v.add_child(warn)
    if run.is_kit:
        # equal on both lanes by design - the choice is flavor, not money
        var fut := Label.new()
        fut.text = "WIN: +%d to your satchel" % player.kit_purse(String(nd.get("tier", "")), _today())
        fut.add_theme_font_size_override("font_size", 11)
        fut.add_theme_color_override("font_color", Color(Tokens.PARCHMENT, 0.7))
        fut.mouse_filter = Control.MOUSE_FILTER_IGNORE
        v.add_child(fut)
    return card

func _card_pnl(fill: Color, border: Color) -> StyleBoxFlat:
    var sb := StyleBoxFlat.new()
    sb.bg_color = fill
    sb.set_border_width_all(2)
    sb.border_color = border
    sb.set_corner_radius_all(8)
    sb.content_margin_left = 10
    sb.content_margin_right = 10
    sb.content_margin_top = 8
    sb.content_margin_bottom = 8
    return sb

func _on_commit_path() -> void:
    if _sel_lane < 0 or not run.at_junction():
        return
    Sfx.play(&"switch_throw")
    run.choose(_sel_lane)            # irreversible - the switch throws
    _sel_lane = -1
    _sel_pos = -1
    refresh()

func _on_repair(cost: int) -> void:
    if player.scrap < cost:
        _status.text = "Not enough scrap to mend - you have ⚙%d." % player.scrap
        return
    player.scrap -= cost
    run.repair_all()
    player.save()
    _status.text = "Mended. (−⚙%d)" % cost
    refresh()

func resolve_fight(result: int) -> void:
    if run.is_kit:
        _resolve_kit_fight(result)
        return
    if result == Combat.Result.DEATH:
        # The Gleaner's Due (spec 4.3): HP-scaled own-build wreck salvage. Run-death credit
        # ONLY - bouts keep the CH-08/CH-09 forfeit-pays-zero law (this path never runs there).
        var tier := String(run.node().get("tier", ""))
        var wreck := RunState.gleaners_wreck(run.carried, tier)
        if wreck > 0:
            player.scrap += wreck
            _finish(false, "Word from the gleaners: ⚙%d pulled from the wreck. The core is gone." % wreck)
        else:
            _finish(false, "Your Manabit was unmade. The run ends - but you keep what you looted.")
        refresh()
        return
    var pad := 0
    if result == Combat.Result.WIN:
        pad = RunMods.note_win(run)   # second_wind banks its core pad BEFORE we leave this lane
    run.advance()                 # WIN or SURVIVABLE-LOSS: press on (weaker if you lost)
    if run.over:
        _finish(true, "You cleared the run! %s is banked to your Menagerie." % run.mname)
    refresh()
    if pad > 0 and not run.over:
        _status.text = "Second Wind - your core will carry +%d HP into the next bell." % pad

# Trundle outcomes: WIN pays a purse into the satchel and presses on; SURVIVABLE_LOSS ends the
# run keeping the satchel; DEATH spills it. The wallet is never touched mid-run.
# The purse is keyed by the fought node's TIER - read from the collapsed node BEFORE advancing.
func _resolve_kit_fight(result: int) -> void:
    if result == Combat.Result.WIN:
        var tier := String(run.node().get("tier", ""))
        var purse := player.kit_purse(tier, _today())
        var pad := RunMods.note_win(run)   # second_wind: this lane's rule, pre-advance
        run.satchel_scrap += purse
        run.advance()
        if run.over:
            _finish_kit(true, "You haul the box home, salvage rattling - clean run!")
        else:
            refresh()
            var msg := "＋⚙%d to your salvage." % purse
            if pad > 0:
                msg += "  Second Wind - your core will carry +%d HP into the next bell." % pad
            _status.text = msg
        return
    if result == Combat.Result.DEATH:
        # The Gleaner's Due (spec 4.2): the pickers glean an HP-scaled cut of the satchel.
        # kept <= floor(S/2) by the formula; the tucked bit NEVER survives; a death that
        # pays burns a daily full-rate slot (G10 - the halving-loophole closure).
        var dtier := String(run.node().get("tier", ""))
        var kept := run.kit_death_spill(dtier)
        player.gleaners_pay(kept, _today())
        if kept <= 0:
            _finish_kit(false, "The scrap scatters where it fell - you walk home empty-handed.")
        elif dtier == "boss":
            _finish_kit(false, "The pickers drag back what they could - ⚙%d of your salvage." % kept)
        else:
            _finish_kit(false, "Scattered where it fell. The pickers glean ⚙%d." % kept)
    else:
        _finish_kit(true, "You limp home - but the salvage is safe.")

func _finish(banked: bool, msg: String) -> void:
    run.over = true
    run.banked = banked
    if banked and not run.is_kit and run.carried != null:
        player.bank_manabit(run.mname, run.carried)
    player.save()
    _end_msg = msg
    refresh()

# End a kit run. keep=true flushes the satchel to the player; DEATH passes keep=false (spilled).
func _finish_kit(keep: bool, msg: String) -> void:
    run.over = true
    run.banked = false                # Trundle is never banked to the Menagerie
    if keep:
        player.flush_satchel(run)
        player.note_kit_run(_today())
    player.save()
    _end_msg = msg
    refresh()

# Two-step armed abandon (spec 5.4, own builds only): the first press ARMS the button; a second
# press while armed confirms; any other interaction disarms (refresh() resets the flag - never a
# timer, a timer races refresh). The armed flag lives on the SCREEN, not the button - refresh()
# rebuilds children every call. Kit "Head home" stays one-tap: it is safe by construction.
func _on_abandon() -> void:
    if run != null and run.is_kit:
        # Safe between fights - heading home keeps the salvage; the wager window is only in a fight.
        _finish_kit(true, "Home safe - you tip the salvage onto your bench.")
        return
    if not _abandon_armed:
        _abandon_armed = true
        _abandon_btn.text = "Leave them behind? Tap again"
        return
    _abandon_armed = false
    _finish(false, "You abandoned the run - the construct is left behind.")

func _today() -> int:
    return int(Time.get_unix_time_from_system() / 86400.0)

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

# --- RouteRail: the brass rail draw pass under the RouteBed chips (DESIGN.md 8) ---------------
# 3px BRASS 0.5 through chip centers; S-curve split at junction columns with a 20px SwitchPoint
# Y-glyph; traveled segments overdraw 5px GLOW_BASE; the road_not_taken branch ghosts at 0.15.
class RouteRail extends Control:
    var cols: Array = []          # per column: {"kind": "single"|"split"|"collapsed", "a", "b"}
    var walked := 0               # segments into columns <= this index are traveled
    var preview_col := -1         # uncollapsed junction column being previewed (-1 = none)
    var preview_lane := -1
    var glow_a := 0.6             # traveled-glow alpha (fades to 0.25 on a death end)

    # Redraw every frame: refresh() queue_frees the old chip columns and adds the new ones in
    # the SAME frame, so a one-shot draw catches the chips mid-layout (rail curves running off
    # the right edge, or missing segments while rects are still zero). Chasing live positions
    # each frame is a handful of polylines - cheap - and the death fade already tweens glow_a.
    func _process(_delta: float) -> void:
        queue_redraw()

    func _pt(c: Control) -> Vector2:
        return get_global_transform().affine_inverse() * c.get_global_rect().get_center()

    func _live(c) -> bool:
        if c == null or not (c is Control) or not is_instance_valid(c):
            return false
        return (c as Control).get_global_rect().size.y > 1.0   # skip pre-layout zero rects

    func _curve(a: Vector2, b: Vector2, col: Color, w: float) -> void:
        if absf(a.y - b.y) < 2.0:
            draw_line(a, b, col, w)
            return
        var c0 := Vector2(lerpf(a.x, b.x, 0.5), a.y)
        var c1 := Vector2(lerpf(a.x, b.x, 0.5), b.y)
        var pts := PackedVector2Array()
        for k in 13:
            pts.append(a.bezier_interpolate(c0, c1, b, float(k) / 12.0))
        draw_polyline(pts, col, w)

    func _switch_glyph(p: Vector2, col_i: int) -> void:
        draw_circle(p, 4.0, Tokens.BRASS)
        var ang := 0.0             # SwitchPoint needle - tilts toward the previewed lane
        if col_i == preview_col and preview_lane >= 0:
            ang = -0.5 if preview_lane == 0 else 0.5
        draw_line(p, p + Vector2(20, 0).rotated(ang), Color(Tokens.BRASS_HI, 0.9), 2.0)

    func _draw() -> void:
        if cols.size() < 2:
            return
        var base := Color(Tokens.BRASS, 0.5)
        var ghost := Color(Tokens.BRASS, 0.15)
        var glow := Color(Tokens.GLOW_BASE, glow_a)
        for i in cols.size() - 1:
            var L: Dictionary = cols[i]
            var R: Dictionary = cols[i + 1]
            if not (_live(L["a"]) and _live(R["a"])):
                continue
            var p0 := _pt(L["a"])
            var p1 := _pt(R["a"])
            var traveled := (i + 1) <= walked
            var rkind := String(R["kind"])
            if rkind == "split":
                # diverge to both live lanes - neither is history yet
                _curve(p0, p1, base, 3.0)
                if _live(R["b"]):
                    _curve(p0, _pt(R["b"]), base, 3.0)
                    if i + 1 == preview_col and preview_lane >= 0:
                        var tgt = R["a"] if preview_lane == 0 else R["b"]
                        if _live(tgt):
                            _curve(p0, _pt(tgt), Color(Tokens.GLOW_BASE, 0.35), 5.0)
                _switch_glyph(p0, i + 1)
            elif rkind == "collapsed":
                # the chosen branch is the road; the other stays a ghost forever
                _curve(p0, p1, base, 3.0)
                if traveled:
                    _curve(p0, p1, glow, 5.0)
                if _live(R["b"]):
                    _curve(p0, _pt(R["b"]), ghost, 3.0)
                _switch_glyph(p0, i + 1)
            else:
                # converge into a single column (L may be a fork's far side)
                _curve(p0, p1, base, 3.0)
                if traveled:
                    _curve(p0, p1, glow, 5.0)
                if _live(L["b"]):
                    _curve(_pt(L["b"]), p1, ghost if String(L["kind"]) == "collapsed" else base, 3.0)
