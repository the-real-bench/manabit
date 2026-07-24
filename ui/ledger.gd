class_name Ledger extends PanelContainer
# The theorycraft panel, reskinned per the Workshop style direction (moves 5 + 6 + 13):
# a parchment spec card with a brass clip. Each stat line = etched stat icon + name in the
# display face + a segmented brass-pip lozenge + the number in a circular end-cap. Hover or
# drag-preview shows the honest whole-column delta 'ATK 15 -> 19 (+4)' with a stitched arrow.
# The Balance is a drawn brass steelyard that visibly tips into a red-wax overload zone.
# Reads BuildSession.current_derived() / preview_derived_with() only - no stat math here.

var _atk: StatGauge
var _def: StatGauge
var _spd: StatGauge
var _mana: StatGauge
var _balance: BalanceMeter
var _balance_note: Label
var _kit: Label
var _arche: Label

# Contrast-safe on-dark text variant, kept for back-compat (canonical home: Tokens.STRAIN_TEXT)
static var STRAIN_TEXT := Tokens.STRAIN_TEXT

# Ink tiers for the parchment card ground (the on-dark text tiers flip on a light card):
# deep leaf and deepened wax both checked >=4.5:1 on --parchment.
static var NOTE_OK := Tokens.STAT_SPD.darkened(0.5)      # leaf = SPD, deepened for parchment
static var NOTE_STRAIN := Tokens.WAX.darkened(0.15)      # red-wax strain ink on parchment

class StatGauge extends Control:
    # One spec-card stat line (move 5): etched stat icon in a soft color blob + name in the
    # display face + a segmented brass-pip lozenge (a glance gauge only - the end-cap number
    # is the truth) + a circular end-cap. Projecting draws the whole-column preview
    # 'cur -> proj (+N)' with a stitched up/down arrow in the delta colors (move 13:
    # icon + pip + capsule, never letter-code soup - every number stays visible).
    const PIPS := 8
    const PIP_SCALE := 20.0     # one pip per 2.5 stat points - a display scale, not data
    const NAME_X := 26.0
    const CAPSULE_X := 72.0
    var stat_name := ""
    var icon_kind := ""         # "atk" | "def" | "spd" | "mana"
    var color := Color.WHITE    # the locked --stat-* token for this line
    var value := 0
    var projected := -999       # -999 = static (no preview)

    func _ready() -> void:
        custom_minimum_size = Vector2(0, 24)
        mouse_filter = Control.MOUSE_FILTER_IGNORE   # the old rows were Labels - stay inert

    func set_value(cur: int, proj: int) -> void:
        value = cur
        projected = proj
        queue_redraw()

    func _projecting() -> bool:
        return projected != -999 and projected != value

    func _pip_count(v: int) -> int:
        return clampi(int(round(float(v) / PIP_SCALE * float(PIPS))), 0, PIPS)

    func _draw() -> void:
        var h := size.y
        var cy := h * 0.5
        # etched icon in a soft circular color blob (drawn shapes - no glyph-fallback risk)
        draw_circle(Vector2(10.0, cy), 9.0, Color(color, 0.30))
        _draw_icon(Vector2(10.0, cy), Tokens.BENCH_LO)
        # the stat name in the display face, ink on parchment
        var df := Tokens.display_font()
        var sans := get_theme_default_font()
        if df == null:
            df = sans
        var name_y := cy + (df.get_ascent(13) - df.get_descent(13)) * 0.5
        draw_string(df, Vector2(NAME_X, name_y), stat_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Tokens.BENCH_LO)
        # the lozenge: deep inset capsule with a quiet brass frame
        var cap_r := h * 0.5 - 2.0
        var cap_c := Vector2(size.x - cap_r - 2.0, cy)
        var loz := StyleBoxFlat.new()
        loz.bg_color = Tokens.PANEL_DEEP
        loz.set_corner_radius_all(int(cap_r))
        loz.set_border_width_all(1)
        loz.border_color = Color(Tokens.BRASS, 0.75)
        loz.draw(get_canvas_item(), Rect2(CAPSULE_X, 2.0, size.x - CAPSULE_X, h - 4.0))
        # projecting: the honest whole-column preview + stitched arrow (AC6 current >> new)
        var pip_right := cap_c.x - cap_r - 6.0
        if _projecting():
            var diff := projected - value
            var sgn := "+" if diff > 0 else ""
            var txt := "%d → %d (%s%d)" % [value, projected, sgn, diff]
            var dc := Tokens.DELTA_POS if diff > 0 else Tokens.DELTA_NEG
            var tw := sans.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
            var tx := cap_c.x - cap_r - 6.0 - tw
            var ty := cy + (sans.get_ascent(12) - sans.get_descent(12)) * 0.5
            draw_string(sans, Vector2(tx, ty), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, dc)
            _draw_stitched_arrow(Vector2(tx - 9.0, cy), diff > 0, dc)
            pip_right = tx - 18.0
        # brass-pip segments (skipped when the preview text leaves no honest room)
        var pip_left := CAPSULE_X + 5.0
        var zone := pip_right - pip_left
        if zone >= 34.0:
            var pw := (zone - float(PIPS - 1) * 2.0) / float(PIPS)
            var cur_p := _pip_count(value)
            var lo := cur_p
            var hi := cur_p
            if _projecting():
                var proj_p := _pip_count(projected)
                lo = mini(cur_p, proj_p)
                hi = maxi(cur_p, proj_p)
            for i in PIPS:
                var pc := Color(Tokens.PARCHMENT, 0.10)      # empty segment slot
                if i < lo:
                    pc = color
                elif i < hi:
                    pc = Color(Tokens.LAMP_KEY, 0.35)        # ghost preview segment
                draw_rect(Rect2(pip_left + float(i) * (pw + 2.0), cy - 6.0, pw, 12.0), pc, true)
        # circular end-cap: the number is the truth (projected while previewing)
        var shown := projected if _projecting() else value
        var ring := color
        if _projecting():
            ring = Tokens.DELTA_POS if projected > value else Tokens.DELTA_NEG
        draw_circle(cap_c, cap_r, Tokens.BENCH_LO)
        draw_arc(cap_c, cap_r - 0.5, 0.0, TAU, 24, ring, 1.5, true)
        var ns := str(shown)
        var nfs := 12 if ns.length() <= 2 else 10
        var nw := sans.get_string_size(ns, HORIZONTAL_ALIGNMENT_LEFT, -1, nfs).x
        var ny := cy + (sans.get_ascent(nfs) - sans.get_descent(nfs)) * 0.5
        draw_string(sans, Vector2(cap_c.x - nw * 0.5, ny), ns, HORIZONTAL_ALIGNMENT_LEFT, -1, nfs, Tokens.PARCHMENT)

    func _draw_icon(c: Vector2, ink: Color) -> void:
        match icon_kind:
            "atk":      # a little etched sword
                draw_line(c + Vector2(-3.5, 3.5), c + Vector2(3.5, -3.5), ink, 1.8, true)
                draw_line(c + Vector2(-3.4, -0.4), c + Vector2(0.4, 3.4), ink, 1.6, true)
                draw_circle(c + Vector2(-4.2, 4.2), 1.2, ink)
            "def":      # a shield
                draw_colored_polygon(PackedVector2Array([
                    c + Vector2(-4.0, -3.6), c + Vector2(4.0, -3.6), c + Vector2(4.0, 0.6),
                    c + Vector2(0.0, 4.6), c + Vector2(-4.0, 0.6)]), ink)
            "spd":      # double chevron
                draw_polyline(PackedVector2Array([
                    c + Vector2(-4.2, -3.2), c + Vector2(-1.2, 0.0), c + Vector2(-4.2, 3.2)]), ink, 1.8, true)
                draw_polyline(PackedVector2Array([
                    c + Vector2(0.2, -3.2), c + Vector2(3.2, 0.0), c + Vector2(0.2, 3.2)]), ink, 1.8, true)
            "mana":     # four-point mana star
                draw_colored_polygon(PackedVector2Array([
                    c + Vector2(0.0, -4.6), c + Vector2(1.3, -1.3), c + Vector2(4.6, 0.0),
                    c + Vector2(1.3, 1.3), c + Vector2(0.0, 4.6), c + Vector2(-1.3, 1.3),
                    c + Vector2(-4.6, 0.0), c + Vector2(-1.3, -1.3)]), ink)

    func _draw_stitched_arrow(at: Vector2, up: bool, dc: Color) -> void:
        # stitched chevron: dashed strokes read as thread (the --stitch-detail voice)
        var apex := -3.0 if up else 3.0
        draw_dashed_line(at + Vector2(-4.0, -apex), at + Vector2(0.0, apex), dc, 1.5, 2.0)
        draw_dashed_line(at + Vector2(0.0, apex), at + Vector2(4.0, -apex), dc, 1.5, 2.0)

class BalanceMeter extends Control:
    # The Balance as a drawn brass steelyard (move 6): a fulcrum post, a beam that visibly
    # tips as weight approaches capacity, a sliding poise riding out the arm, and the beam
    # tip as the needle sweeping a graduated arc into a red-wax overload zone. Every honest
    # element of the old bar maps 1:1 onto the arc: amber fill sweep, brass budget tick,
    # HATCHED overflow segment (pattern, not color alone), lamp-ghost projection that
    # pre-glows red past capacity. The exact numbers live in the note below - unchanged.
    const SCALE_MAX := 140.0
    var budget := 100.0        # dynamic: derived().capacity (CARRY rider) - never hardcode 100
    var weight := 0
    var projected := 0

    func _ready() -> void:
        custom_minimum_size = Vector2(0, 40)

    func set_weight(w: int, pw: int, cap: int = 100) -> void:
        weight = w
        projected = pw
        budget = float(cap)
        queue_redraw()

    func _angle(v: float) -> float:
        # linear weight -> sweep angle: the same honest 0..SCALE_MAX mapping the old bar's
        # _px() used, bent around the fulcrum so magnitude still reads proportionally
        var arm := size.x - 24.0
        var max_a := asin(clampf((size.y - 12.0) / maxf(arm, 1.0), 0.05, 0.5))
        return max_a * clampf(v / SCALE_MAX, 0.0, 1.0)

    func _on_arc(pivot: Vector2, arm: float, v: float) -> Vector2:
        var a := _angle(v)
        return pivot + Vector2(cos(a), sin(a)) * arm

    func _draw() -> void:
        var pivot := Vector2(12.0, 8.0)
        var arm := size.x - 24.0
        # the graduated gauge band: a deep inset arc (the lozenges' material grammar) so the
        # amber fill keeps its honest contrast on the light parchment card
        draw_arc(pivot, arm, 0.0, _angle(SCALE_MAX), 24, Tokens.PANEL_DEEP, 12.0, true)
        draw_arc(pivot, arm - 7.0, 0.0, _angle(SCALE_MAX), 24, Color(Tokens.BRASS, 0.6), 1.0, true)
        draw_arc(pivot, arm + 7.0, 0.0, _angle(SCALE_MAX), 24, Color(Tokens.BRASS, 0.6), 1.0, true)
        # the red-wax overload zone: everything past capacity, always visible
        draw_arc(pivot, arm, _angle(budget), _angle(SCALE_MAX), 12, Color(Tokens.WAX, 0.50), 10.0, true)
        # honest amber fill sweep up to min(weight, budget)
        if weight > 0:
            draw_arc(pivot, arm, 0.0, _angle(minf(weight, budget)), 20, Tokens.STAT_WEIGHT, 8.0, true)
        # hatched overflow segment past the budget tick (pattern, not color alone)
        if weight > budget:
            draw_arc(pivot, arm, _angle(budget), _angle(weight), 12, Tokens.STAT_WEIGHT_OVER, 10.0, true)
            var v := budget
            while v < minf(weight, SCALE_MAX):
                var hp := _on_arc(pivot, arm, v)
                var hr := (hp - pivot).normalized()
                draw_line(hp - hr * 5.0, hp + hr * 5.0, Tokens.PANEL_DEEP, 1.5, true)
                v += 6.0
        # projected ghost sweep (hover preview) - pre-glows red past capacity
        if projected != weight:
            var g0 := minf(weight, projected)
            var g1 := maxf(weight, projected)
            var gsplit := clampf(budget, g0, g1)
            if gsplit > g0:
                draw_arc(pivot, arm, _angle(g0), _angle(gsplit), 12, Color(Tokens.LAMP_KEY, 0.45), 8.0, true)
            if g1 > gsplit:
                draw_arc(pivot, arm, _angle(gsplit), _angle(g1), 12, Color(Tokens.STAT_WEIGHT_OVER, 0.55), 8.0, true)
        # the capacity tick, always on top of the band
        var bt := _on_arc(pivot, arm, budget)
        var br := (bt - pivot).normalized()
        draw_line(bt - br * 7.0, bt + br * 7.0, Tokens.BRASS_HI, 2.0, true)
        # the instrument itself: fulcrum post + foot, tipping beam, needle head, poise
        draw_line(Vector2(12.0, size.y - 2.0), Vector2(12.0, 8.0), Tokens.BRASS, 3.0, true)
        draw_line(Vector2(6.0, size.y - 2.0), Vector2(18.0, size.y - 2.0), Tokens.BRASS, 2.5, true)
        var beam_dir := Vector2(cos(_angle(weight)), sin(_angle(weight)))
        var tip := pivot + beam_dir * arm
        draw_line(pivot, tip, Tokens.BRASS, 2.5, true)
        var perp := Vector2(-beam_dir.y, beam_dir.x)
        draw_colored_polygon(PackedVector2Array([tip + beam_dir * 7.0, tip + perp * 3.0, tip - perp * 3.0]), Tokens.BRASS)
        # the sliding poise rides out the arm with the load - how a steelyard reads weight
        var ppos := pivot + beam_dir * (arm * (0.15 + 0.75 * clampf(weight / SCALE_MAX, 0.0, 1.0)))
        draw_circle(ppos, 3.5, Tokens.BRASS)
        draw_circle(ppos, 1.5, Tokens.BENCH_LO)
        # pivot pin
        draw_circle(pivot, 2.5, Tokens.BRASS)
        draw_circle(pivot, 1.0, Tokens.BENCH_LO)

func _ready() -> void:
    custom_minimum_size = Vector2(238, 0)
    # move 5: the whole panel is a parchment spec card from the shared material sandwich
    add_theme_stylebox_override("panel", Tokens.sandwich("parchment"))

    var v := VBoxContainer.new()
    v.add_theme_constant_override("separation", 7)
    add_child(v)

    var title := Label.new()
    title.text = "THE LEDGER"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER   # centered under the clip
    title.add_theme_color_override("font_color", Tokens.BENCH_LO)   # ink on parchment
    Tokens.display(title, 17)
    v.add_child(title)

    _atk = _stat_row(v, "ATK", "atk", Tokens.STAT_ATK)
    _def = _stat_row(v, "DEF", "def", Tokens.STAT_DEF)
    _spd = _stat_row(v, "SPD", "spd", Tokens.STAT_SPD)
    _mana = _stat_row(v, "MANA", "mana", Tokens.STAT_ENERGY)

    var bl := Label.new()
    bl.text = "⚖  THE BALANCE"
    bl.add_theme_color_override("font_color", Tokens.BENCH_LO)
    Tokens.display(bl, 14)
    v.add_child(bl)
    _balance = BalanceMeter.new()
    v.add_child(_balance)
    _balance_note = Label.new()
    _balance_note.add_theme_font_size_override("font_size", 12)
    v.add_child(_balance_note)

    _kit = Label.new()
    _kit.add_theme_font_size_override("font_size", 12)
    _kit.add_theme_color_override("font_color", Tokens.BENCH_WALNUT)   # soft ink on parchment
    v.add_child(_kit)

    _arche = Label.new()
    _arche.add_theme_color_override("font_color", Tokens.BENCH_WALNUT)
    Tokens.display(_arche, 19)
    v.add_child(_arche)

func _draw() -> void:
    # stitched seam just inside the parchment rim - walnut thread on the light ground
    # (the stitch token's parchment thread is for dark felt; pass explicit ink here)
    Tokens.draw_stitch_rect(self, Rect2(Vector2.ZERO, size), Color(Tokens.BENCH_WALNUT, 0.35))
    # the card's ONE brass accent (section 9 RULE): a spec-card clip astride the top edge
    var cx := size.x * 0.5
    var clip := StyleBoxFlat.new()
    clip.bg_color = Tokens.BRASS
    clip.set_corner_radius_all(5)
    clip.border_width_top = 2
    clip.border_color = Tokens.BRASS_HI
    clip.draw(get_canvas_item(), Rect2(cx - 24.0, -6.0, 48.0, 15.0))
    draw_line(Vector2(cx - 13.0, 3.0), Vector2(cx + 13.0, 3.0), Color(Tokens.BENCH_LO, 0.45), 2.0)

func _stat_row(parent: VBoxContainer, stat_name: String, icon_kind: String, color: Color) -> StatGauge:
    var g := StatGauge.new()
    g.stat_name = stat_name
    g.icon_kind = icon_kind
    g.color = color
    parent.add_child(g)
    return g

func show_build(session: BuildSession, proj: Dictionary = {}) -> void:
    var d := session.current_derived()
    _set_stat(_atk, int(d.attack), int(proj.get("attack", -999)))
    _set_stat(_def, int(d.defense), int(proj.get("defense", -999)))
    _set_stat(_spd, int(d.speed), int(proj.get("speed", -999)))
    _set_stat(_mana, int(d.energy), int(proj.get("energy", -999)))

    var seated := 0
    for slot0 in ManabitState.SLOT_NAMES:
        if session.manabit.slots.get(slot0) != null:
            seated += 1

    var w := int(d.weight)
    var pw := int(proj.get("weight", w))
    var cap := int(d.get("capacity", 100))
    var pcap := int(proj.get("capacity", cap))     # a hovered core previews its new ceiling
    _balance.set_weight(w, pw, pcap if not proj.is_empty() else cap)
    var over := w - cap
    if over > 0:
        # honest overweight readout: what SPD actually becomes (studio gate) - the copy is
        # warm register, the numbers are untouchable
        var spd_now := int(d.speed)
        _balance_note.text = "She'll wheeze - too much to haul\nSTRAIN %d/%d · SPD %d → %d (-%d)" % [w, cap, spd_now + over, spd_now, over]
        _balance_note.add_theme_color_override("font_color", NOTE_STRAIN)
    else:
        var carry_chip := "  (+%d carry)" % (cap - 100) if cap > 100 else ""
        var word := "Trim - loaded right to the line" if w == cap else "Rides light and lively"
        if seated == 0:
            # honest-quiet empty verdict (calm spec 6): no cheerful verdict about nothing;
            # the 0/100 numbers stay - honest data untouched
            word = "Nothing on the stand yet."
        _balance_note.text = "%s\n%d / %d · 0 SPD penalty%s" % [word, w, cap, carry_chip]
        _balance_note.add_theme_color_override("font_color", NOTE_OK)

    var s := 0
    var m := 0
    var g := 0
    for slot in ManabitState.SLOT_NAMES:
        var pi: PartInstance = session.manabit.slots.get(slot)
        if pi != null and pi.data.ability != null:
            match pi.data.ability.archetype:
                "SINGLE": s += 1
                "MULTI": m += 1
                "GUARD": g += 1
    _kit.text = "Kit:  %d Single · %d Multi · %d Guard" % [s, m, g]
    _arche.text = "▸ " + _archetype(d, s, m, g)
    _arche.visible = seated > 0    # no archetype claim about an empty stand (calm spec 6)

func _set_stat(gauge: StatGauge, cur: int, proj: int) -> void:
    gauge.set_value(cur, proj)

func _archetype(d: Dictionary, s: int, m: int, g: int) -> String:
    var atk := int(d.attack)
    var df := int(d.defense)
    var spd := int(d.speed)
    var en := int(d.energy)
    if g >= 2 or (df >= atk + 3 and df >= spd):
        return "Bulwark"
    if en >= 16 and en >= atk:
        return "Battery"
    if spd >= atk + 3:
        return "Skirmisher"
    if atk >= 8 and df <= 1:
        return "Glass Cannon"
    if atk >= df + 4:
        return "Bruiser"
    return "All-rounder"
