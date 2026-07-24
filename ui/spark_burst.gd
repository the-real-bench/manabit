class_name SparkBurst extends Control
# One-shot radial spark ring that draws itself, then frees. Fires on seat / rare-kindle.
# fire() = outward burst; fire_in() = inward-contracting ring (the guard dome snapping shut).

var _t := 0.0
var _dur := 0.28
var _color: Color = Color(1, 1, 1, 1)
var _n := 10
var _inward := false
var _alpha := 1.0

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_process(true)

func fire(color: Color) -> void:
    _color = color

func fire_in(color: Color) -> void:
    _color = color
    _inward = true
    _alpha = 0.22

func _process(delta: float) -> void:
    _t += delta
    queue_redraw()
    if _t >= _dur:
        queue_free()

func _draw() -> void:
    if size.x <= 0.0:
        return
    var p := clampf(_t / _dur, 0.0, 1.0)
    var c := size / 2.0
    var rad := lerpf(46.0, 18.0, p) if _inward else lerpf(6.0, 46.0, p)
    var a := (1.0 - p) * _alpha
    for i in _n:
        var ang := TAU * float(i) / float(_n)
        var pos := c + Vector2(cos(ang), sin(ang)) * rad
        draw_circle(pos, lerpf(4.0, 1.0, p), Color(_color, a))
