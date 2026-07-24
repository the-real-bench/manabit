class_name ChargeRing extends Control
# Radial charge meter for the Coffer Waking. progress 0..1 fills the ring clockwise from top.

var progress: float = 0.0:
    set(value):
        progress = clampf(value, 0.0, 1.0)
        queue_redraw()

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
    if size.x <= 0.0:
        return
    var c := size / 2.0
    var r := minf(size.x, size.y) * 0.46
    draw_arc(c, r, 0.0, TAU, 56, Color(Tokens.BRASS, 0.22), 4.0, true)
    if progress > 0.0:
        var col := Tokens.GLOW_BASE if progress < 0.999 else Tokens.LAMP_KEY
        draw_arc(c, r, -PI / 2.0, -PI / 2.0 + TAU * progress, 56, col, 6.0, true)
