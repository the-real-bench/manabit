class_name ManaSigil2D extends Control
# The flipped power-button mana rune as a slow-spinning 2D backdrop - one full sweep a minute,
# echoing the 3D sigil that hangs behind a seated Manabit. Decorative and mouse-transparent:
# a broken glowing ring (gap + stroke at the bottom) that rotates so the break sweeps like a
# clock hand. Reduce-motion holds it still.

const SPIN := TAU / 60.0            # one full sweep per minute (matches the 3D backdrop)

var color: Color = Tokens.GLOW_BASE
var radius_px: float = 150.0
var flipped: bool = true            # gap + stroke at the BOTTOM (down)
var _rot := 0.0

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
    if Juice.reduce_motion:
        return
    _rot += SPIN * delta
    queue_redraw()

func _draw() -> void:
    if size.x <= 0.0:
        return
    var ctr := size * 0.5
    var r := radius_px
    var gap_half := deg_to_rad(30.0)
    var gap_c := ((PI * 0.5) if flipped else (-PI * 0.5)) + _rot   # 2D y-down: bottom = +PI/2
    var dir := Vector2(cos(gap_c), sin(gap_c))
    # glow: a few passes, wide-and-dim under narrow-and-bright, so it reads as one soft line
    for p in [[8.0, 0.06], [4.5, 0.14], [2.2, 0.40]]:
        var w: float = p[0]
        var a: float = p[1]
        var col := Color(color, a)
        draw_arc(ctr, r, gap_c + gap_half, gap_c + TAU - gap_half, 72, col, w, true)   # broken ring
        draw_line(ctr + dir * (r * 0.06), ctr + dir * (r * 1.15), col, w, true)        # stroke through the gap
