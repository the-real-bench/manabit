class_name FettlePortrait extends Control
# Fettle drawn cheaply: a pot-bellied brass cabinet-automaton with a glowing forge-belly,
# a loupe-eye, a wind-up key, and drawer handles. Placeholder for real low-poly art later.

var _pulse := 0.0        # transient brighten on a sale
var _dim := 0.0          # transient apologetic dim on a refusal
var _tex: Texture2D = null   # painted portrait (drop-in), glow still animates on top

func _ready() -> void:
    custom_minimum_size = Vector2(128, 156)
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    if ResourceLoader.exists("res://art/portraits/fettle.png"):
        _tex = load("res://art/portraits/fettle.png")
    set_process(true)

func pulse(a: float = 0.35) -> void:
    _pulse = a

func apologise() -> void:
    _dim = 0.35

func _process(delta: float) -> void:
    _pulse = maxf(0.0, _pulse - delta * 1.8)
    _dim = maxf(0.0, _dim - delta * 2.4)
    queue_redraw()

func _draw() -> void:
    if size.x <= 0.0:
        return
    var w := size.x
    var h := size.y
    var pulse := clampf(0.55 + 0.3 * sin(Time.get_ticks_msec() / 520.0) + _pulse - _dim, 0.1, 1.4)
    # painted portrait if it dropped in: draw it, then the live glow overlays (eye + forge) on top
    if _tex != null:
        draw_texture_rect(_tex, Rect2(0.0, 0.0, w, h), false)
        draw_circle(Vector2(w * 0.5, h * 0.27), w * 0.055, Color(Tokens.GLOW_BASE, pulse * 0.7))
        draw_circle(Vector2(w * 0.5, h * 0.70), w * 0.11, Color(Tokens.AFF_ATTACK, 0.45 * pulse))
        draw_circle(Vector2(w * 0.5, h * 0.70), w * 0.06, Color(Tokens.GLOW_BASE, pulse * 0.6))
        return
    # wind-up key (behind, right)
    draw_line(Vector2(w * 0.78, h * 0.28), Vector2(w * 0.95, h * 0.28), Tokens.BRASS_HI, 3.0)
    draw_circle(Vector2(w * 0.95, h * 0.28), w * 0.05, Tokens.BRASS_HI)
    # cabinet body
    draw_rect(Rect2(w * 0.2, h * 0.2, w * 0.6, h * 0.72), Tokens.BRASS.darkened(0.18), true)
    draw_rect(Rect2(w * 0.2, h * 0.2, w * 0.6, h * 0.72), Tokens.BRASS_HI, false, 2.0)
    # head
    draw_rect(Rect2(w * 0.33, h * 0.05, w * 0.34, h * 0.2), Tokens.BRASS.darkened(0.1), true)
    draw_rect(Rect2(w * 0.33, h * 0.05, w * 0.34, h * 0.2), Tokens.BRASS_HI, false, 1.5)
    # loupe eye (glowing)
    draw_circle(Vector2(w * 0.5, h * 0.15), w * 0.06, Color(Tokens.GLOW_BASE, pulse))
    # drawer handles across the chest
    for i in 3:
        var y := h * (0.32 + i * 0.11)
        draw_line(Vector2(w * 0.34, y), Vector2(w * 0.66, y), Tokens.BRASS_HI, 1.5)
    # forge-belly (big glow)
    draw_circle(Vector2(w * 0.5, h * 0.74), w * 0.15, Color(Tokens.AFF_ATTACK, 0.9))
    draw_circle(Vector2(w * 0.5, h * 0.74), w * 0.09, Color(Tokens.GLOW_BASE, pulse))
    # little music-box wheels
    draw_circle(Vector2(w * 0.33, h * 0.93), w * 0.05, Tokens.BRASS.darkened(0.1))
    draw_circle(Vector2(w * 0.67, h * 0.93), w * 0.05, Tokens.BRASS.darkened(0.1))
