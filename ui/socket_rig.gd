class_name SocketRig extends Control
# The crafted slot rail (workshop-style-direction move 1): six brass socket medallions
# docked along the display stand's rim - three per side, top-to-bottom in body order -
# plus the parchment anatomy inset (move 11) on the wall beside the rail.
# The old perimeter label-plates and every leader line are GONE (the #1 debug tell).
# Sits transparent over the ManabitStage; medallions handle all input themselves.

var slot_fields: Dictionary = {}
var anatomy: AnatomyInset
var _session: BuildSession

const MED := SlotField.MEDALLION
static var RAIL := {             # [side (-1 left / +1 right), t down the stand height]
    "HEAD":  [-1, 0.14],
    "ARM_L": [-1, 0.44],
    "CORE":  [-1, 0.74],
    "BACK":  [ 1, 0.14],
    "ARM_R": [ 1, 0.44],
    "LEGS":  [ 1, 0.74],
}

# The display stand's felt rect: the ManabitStage texture keeps its 4:3 viewport aspect,
# centered, inset 10px top and bottom so warm walnut wall shows on all four edges (move 2).
# Shared by the rig (medallion docking) and the workshop's StandFrame (rim + corners).
static func stand_rect(sz: Vector2) -> Rect2:
    var h := sz.y - 20.0
    var w := minf(sz.x, h * 4.0 / 3.0)
    return Rect2(Vector2((sz.x - w) * 0.5, 10.0), Vector2(w, h))

func setup(session: BuildSession) -> SocketRig:
    _session = session
    return self

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    anatomy = AnatomyInset.new()
    add_child(anatomy)               # added first so medallions layer over its corner
    for sname in ManabitState.SLOT_NAMES:
        var sf := SlotField.new().setup(sname, _session)
        add_child(sf)
        slot_fields[sname] = sf
    resized.connect(_relayout)
    call_deferred("_relayout")

func _relayout() -> void:
    var fr := stand_rect(size)
    for sname in slot_fields:
        var sf: SlotField = slot_fields[sname]
        sf.size = Vector2(MED, MED)
        var side: int = RAIL[sname][0]
        var t: float = RAIL[sname][1]
        var cx := fr.position.x if side < 0 else fr.end.x
        var cy := fr.position.y + fr.size.y * t
        sf.position = Vector2(cx, cy) - Vector2(MED, MED) * 0.5
    # anatomy inset: on the wall, tucked left of the rail, resting on the stand's foot line
    anatomy.position = Vector2(
        maxf(6.0, fr.position.x - MED * 0.5 - anatomy.size.x - 8.0),
        clampf(fr.end.y - anatomy.size.y, 6.0, size.y - anatomy.size.y - 2.0))

func set_active_slot(chip_key: String) -> void:
    # ink the active socket(s) on the anatomy legend ("" = none; "ARMS" lights both arms)
    anatomy.set_active(chip_key)

func set_work_mode(on: bool) -> void:
    # Calm spec 6: the anatomy inset is work-mode chrome - the drag legend appears exactly
    # when dragging is possible (drawer open OR a drag / tap-place in flight), never at rest.
    anatomy.visible = on

# --- move 11: the parchment anatomy inset (gunpla-manual figure) ------------------------
class AnatomyInset extends Control:
    const W := 140.0
    const H := 150.0
    const FOOT_H := 26.0     # reserved foot band for the two etched manual print lines
    # figure-space socket points (fractions of the drawn figure box) + legend letters
    const POINTS := {
        "HEAD":  [Vector2(0.50, 0.07), "H", "HEAD"],
        "CORE":  [Vector2(0.50, 0.44), "C", "CORE"],
        "ARM_L": [Vector2(0.07, 0.32), "A", "ARMS"],
        "ARM_R": [Vector2(0.93, 0.32), "A", "ARMS"],
        "LEGS":  [Vector2(0.50, 0.93), "L", "LEGS"],
        "BACK":  [Vector2(0.80, 0.20), "B", "BACK"],
    }
    var active := ""
    var _card: StyleBoxFlat

    func _ready() -> void:
        mouse_filter = Control.MOUSE_FILTER_IGNORE
        custom_minimum_size = Vector2(W, H)
        size = Vector2(W, H)
        _card = Tokens.sandwich("parchment")

    func set_active(chip_key: String) -> void:
        if active == chip_key:
            return
        active = chip_key
        queue_redraw()

    func _draw() -> void:
        _card.draw(get_canvas_item(), Rect2(Vector2.ZERO, size))
        Tokens.draw_stitch_rect(self, Rect2(Vector2.ZERO, size), Color(Tokens.BENCH_WALNUT, 0.45))
        var ink := Color(Tokens.BENCH_LO, 0.65)
        # figure box inside the card margins (the foot band is reserved for the print lines)
        var o := Vector2(20.0, 14.0)
        var fw := size.x - 40.0
        var fh := size.y - 28.0 - FOOT_H
        # construction outline: head / torso / arms / legs (open boxes, manual-figure style)
        draw_rect(Rect2(o.x + fw * 0.32, o.y, fw * 0.36, fh * 0.17), ink, false, 1.2)
        draw_rect(Rect2(o.x + fw * 0.24, o.y + fh * 0.21, fw * 0.52, fh * 0.34), ink, false, 1.2)
        draw_rect(Rect2(o.x + fw * 0.02, o.y + fh * 0.23, fw * 0.16, fh * 0.26), ink, false, 1.2)
        draw_rect(Rect2(o.x + fw * 0.82, o.y + fh * 0.23, fw * 0.16, fh * 0.26), ink, false, 1.2)
        draw_rect(Rect2(o.x + fw * 0.30, o.y + fh * 0.59, fw * 0.15, fh * 0.38), ink, false, 1.2)
        draw_rect(Rect2(o.x + fw * 0.55, o.y + fh * 0.59, fw * 0.15, fh * 0.38), ink, false, 1.2)
        # circled socket letters; the active socket is inked in its family tint
        var f := get_theme_default_font()
        for sname in POINTS:
            var p: Vector2 = POINTS[sname][0]
            var letter: String = POINTS[sname][1]
            var key: String = POINTS[sname][2]
            var at := o + Vector2(p.x * fw, p.y * fh)
            if active != "" and active == key:
                draw_circle(at, 7.0, Tokens.slot_family(sname))
                draw_arc(at, 7.0, 0.0, TAU, 20, Color(Tokens.BENCH_LO, 0.85), 1.2, true)
                _letter(f, letter, at, Tokens.BENCH_LO)
            else:
                draw_circle(at, 7.0, Color(Tokens.PARCHMENT, 0.9))
                draw_arc(at, 7.0, 0.0, TAU, 20, ink, 1.2, true)
                _letter(f, letter, at, ink)
        # The permanent quiet reference (calm spec 3.4): two 9sp etched manual print lines -
        # this is a gunpla manual, print belongs on it. The ONLY teaching residue a veteran
        # can ever see.
        var ly := size.y - FOOT_H
        for line in ["tap a socket - see what fits", "hold a bit - read its tag"]:
            draw_string(f, Vector2(6.0, ly + f.get_ascent(9)), String(line),
                HORIZONTAL_ALIGNMENT_CENTER, size.x - 12.0, 9, Color(Tokens.BENCH_LO, 0.6))
            ly += 11.0

    func _letter(f: Font, txt: String, at: Vector2, col: Color) -> void:
        var px := 8
        var base_y := at.y - f.get_height(px) * 0.5 + f.get_ascent(px)
        draw_string(f, Vector2(at.x - 7.0, base_y), txt, HORIZONTAL_ALIGNMENT_CENTER, 14.0, px, col)
