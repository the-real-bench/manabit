class_name Warmth extends Control
# The cozy-craft material pass (studio AD gate): a warm lamp-key glow from top-center,
# dark-walnut vignette at the edges (never black), and faint film grain. Purely decorative,
# ignores the mouse, costs one draw pass. One call per screen, right after its bg:
#   Warmth.apply(self)
#
# Move 12 (Workshop reskin) - the room-wide material layer. Still one Control, no per-frame
# work (redraws only on resize or a property change), never intercepts input:
#   - a low-contrast woodgrain wash across the whole background (always on; one tiny
#     generated seamless tile, tiled at draw time - it must never fight content)
#   - an optional blueprint-style Manabit silhouette watermark, off by default; the
#     Workshop enables and positions it behind the stage area:
#         var w := Warmth.apply(self)
#         w.watermark_enabled = true
#         w.watermark_rect = stage_area_rect   # screen-local px
#   - optional static corner props (thread spool, pencil, tea-ring stain, screwdriver):
#     desaturated line-art confined to the margins, off by default, enable per screen:
#         w.props_enabled = true

static func apply(screen: Control) -> Warmth:
	var w := Warmth.new()
	w.set_anchors_preset(Control.PRESET_FULL_RECT)
	w.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(w)
	return w

# blueprint watermark: off everywhere by default; the Workshop opts in and places it
var watermark_enabled := false:
	set(v):
		watermark_enabled = v
		queue_redraw()
var watermark_rect := Rect2():
	set(v):
		watermark_rect = v
		queue_redraw()
# corner bench props: off by default, enabled per screen
var props_enabled := false:
	set(v):
		props_enabled = v
		queue_redraw()

var _grain: ImageTexture
var _wood: ImageTexture

func _ready() -> void:
	resized.connect(queue_redraw)
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for y in 64:
		for x in 64:
			var v := rng.randf()
			img.set_pixel(x, y, Color(v, v, v, 0.035))
	_grain = ImageTexture.create_from_image(img)
	_wood = _make_woodgrain()

func _make_woodgrain() -> ImageTexture:
	# One tiny seamless tile of low-contrast horizontal grain (a planed walnut wall).
	# The sine frequencies are whole cycles per tile so it wraps on both axes; the
	# per-pixel jitter is noise and needs no wrap. Generated once, tiled in _draw.
	var sz := 128
	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for y in sz:
		var fy := float(y) / sz
		for x in sz:
			var fx := float(x) / sz
			# the bands drift along x so the streaks read hand-planed, not ruled
			var drift := sin(TAU * fx * 2.0) * 0.045 + sin(TAU * (fx * 5.0 + 0.37)) * 0.02
			var v := sin(TAU * (fy + drift) * 6.0) * 0.6 + sin(TAU * ((fy + drift) * 13.0 + 0.61)) * 0.4
			v += (rng.randf() - 0.5) * 0.55
			if v >= 0.0:
				img.set_pixel(x, y, Color(Tokens.BENCH_HI, clampf(v, 0.0, 1.0) * 0.05))
			else:
				img.set_pixel(x, y, Color(Tokens.BENCH_LO, clampf(-v, 0.0, 1.0) * 0.07))
	return ImageTexture.create_from_image(img)

func _draw() -> void:
	if size.x <= 0.0:
		return
	# room material wash: low-contrast woodgrain under everything (move 12)
	if _wood != null:
		draw_texture_rect(_wood, Rect2(Vector2.ZERO, size), true)
	if watermark_enabled:
		_draw_watermark()
	if props_enabled:
		_draw_props()
	# lamp glow: stacked soft discs from above top-center (cheap radial falloff)
	var c := Vector2(size.x * 0.5, -size.y * 0.18)
	for i in range(6, 0, -1):
		draw_circle(c, size.y * 0.24 * i, Color(Tokens.LAMP_KEY, 0.016))
	# vignette (dark walnut, never black)
	var vt := Tokens.BENCH_LO
	var dv := size.y * 0.16
	var dh := size.x * 0.09
	_grad_v(Rect2(0, 0, size.x, dv), vt, 0.26, false)
	_grad_v(Rect2(0, size.y - dv, size.x, dv), vt, 0.32, true)
	_grad_h(Rect2(0, 0, dh, size.y), vt, 0.28, false)
	_grad_h(Rect2(size.x - dh, 0, dh, size.y), vt, 0.28, true)
	# film grain, tiled at native res
	if _grain != null:
		draw_texture_rect(_grain, Rect2(Vector2.ZERO, size), true)

func _grad_v(r: Rect2, col: Color, a: float, strong_at_bottom: bool) -> void:
	var steps := 8
	var sh := r.size.y / steps
	for i in steps:
		var t := float(i) / (steps - 1)
		var alpha := a * (t if strong_at_bottom else 1.0 - t)
		draw_rect(Rect2(r.position.x, r.position.y + i * sh, r.size.x, sh + 1.0), Color(col, alpha), true)

func _grad_h(r: Rect2, col: Color, a: float, strong_at_right: bool) -> void:
	var steps := 8
	var sw := r.size.x / steps
	for i in steps:
		var t := float(i) / (steps - 1)
		var alpha := a * (t if strong_at_right else 1.0 - t)
		draw_rect(Rect2(r.position.x + i * sw, r.position.y, sw + 1.0, r.size.y), Color(col, alpha), true)

# --- move 12: blueprint watermark -------------------------------------------------------

func _draw_watermark() -> void:
	# Faint blueprint-style Manabit figure (the Medabots honeycomb lesson: give the empty
	# ground a motif). Parchment chalk lines at watermark alpha - never fights content,
	# never glows (the anti-casino guard: no gold, no brass, no ambient shine).
	var r := watermark_rect
	if r.size.x < 40.0 or r.size.y < 40.0:
		return
	var line := Color(Tokens.PARCHMENT, 0.10)
	var faint := Color(Tokens.PARCHMENT, 0.06)
	# fit the figure box (0.72 wide : 1 tall) centered in the rect
	var h := minf(r.size.y, r.size.x / 0.72) * 0.92
	var w := h * 0.72
	var o := r.position + (r.size - Vector2(w, h)) * 0.5
	# dashed symmetry axis
	draw_dashed_line(Vector2(o.x + w * 0.5, o.y - h * 0.03), Vector2(o.x + w * 0.5, o.y + h * 1.03), faint, 1.0, 6.0)
	# body plan: head / torso / arms / legs as open construction boxes
	_bp_rect(Rect2(o.x + w * 0.30, o.y, w * 0.40, h * 0.20), line)
	_bp_rect(Rect2(o.x + w * 0.22, o.y + h * 0.24, w * 0.56, h * 0.36), line)
	_bp_rect(Rect2(o.x + w * 0.02, o.y + h * 0.26, w * 0.16, h * 0.30), line)
	_bp_rect(Rect2(o.x + w * 0.82, o.y + h * 0.26, w * 0.16, h * 0.30), line)
	_bp_rect(Rect2(o.x + w * 0.30, o.y + h * 0.64, w * 0.14, h * 0.34), line)
	_bp_rect(Rect2(o.x + w * 0.56, o.y + h * 0.64, w * 0.14, h * 0.34), line)
	# the core socket: circled, with register ticks
	var cc := Vector2(o.x + w * 0.5, o.y + h * 0.42)
	var cr := h * 0.085
	draw_arc(cc, cr, 0.0, TAU, 28, line, 1.5)
	draw_line(cc + Vector2(-cr - 4.0, 0.0), cc + Vector2(-cr + 5.0, 0.0), line, 1.0)
	draw_line(cc + Vector2(cr - 5.0, 0.0), cc + Vector2(cr + 4.0, 0.0), line, 1.0)
	draw_line(cc + Vector2(0.0, -cr - 4.0), cc + Vector2(0.0, -cr + 5.0), line, 1.0)
	draw_line(cc + Vector2(0.0, cr - 5.0), cc + Vector2(0.0, cr + 4.0), line, 1.0)
	# the other five socket points (head, arms, legs, back), circled blueprint-style
	var sr := maxf(h * 0.028, 3.0)
	for p in [Vector2(0.50, 0.10), Vector2(0.10, 0.31), Vector2(0.90, 0.31), Vector2(0.50, 0.62), Vector2(0.78, 0.245)]:
		draw_arc(o + Vector2(p.x * w, p.y * h), sr, 0.0, TAU, 16, line, 1.0)

func _bp_rect(r: Rect2, c: Color) -> void:
	draw_rect(r, c, false, 1.5)

# --- move 12: corner bench props (Unpacking desk garnish) -------------------------------

func _draw_props() -> void:
	# Static, desaturated line-art confined to the screen margins - thin strokes, low
	# alpha, so they never compete with interactive objects. Drawn under the UI layer
	# (Warmth sits right above the bg), so panels naturally overlap them.
	var ink := Color(Tokens.PARCHMENT, 0.16)
	_draw_spool(Vector2(48.0, size.y * 0.155), ink)
	_draw_pencil(Vector2(92.0, size.y * 0.33), 1.15, ink)
	_draw_tea_ring(Vector2(66.0, size.y * 0.565))
	_draw_screwdriver(Vector2(size.x - 150.0, size.y * 0.585), -0.28, ink)

func _draw_tea_ring(at: Vector2) -> void:
	# the ghost of a mug that once sat here: two broken arcs, slightly darker than the wall
	var stain := Color(Tokens.BENCH_LO, 0.30)
	draw_arc(at, 24.0, 0.35, 2.75, 20, stain, 2.5)
	draw_arc(at, 22.5, 3.05, 5.95, 22, stain, 2.0)

func _draw_spool(at: Vector2, ink: Color) -> void:
	# side-on thread spool: two flanges, a wound band, a loose thread end
	var fh := 30.0
	var bw := 26.0
	var bh := 20.0
	draw_rect(Rect2(at.x - bw * 0.5 - 5.0, at.y - fh * 0.5, 5.0, fh), ink, false, 1.5)
	draw_rect(Rect2(at.x + bw * 0.5, at.y - fh * 0.5, 5.0, fh), ink, false, 1.5)
	draw_rect(Rect2(at.x - bw * 0.5, at.y - bh * 0.5, bw, bh), ink, false, 1.5)
	for i in 3:
		var ty := at.y - bh * 0.5 + bh * 0.25 * (i + 1)
		draw_line(Vector2(at.x - bw * 0.5 + 2.0, ty), Vector2(at.x + bw * 0.5 - 2.0, ty), Color(ink, ink.a * 0.7), 1.0)
	var thread := PackedVector2Array([
		Vector2(at.x + bw * 0.5 + 5.0, at.y + 4.0),
		Vector2(at.x + bw * 0.5 + 16.0, at.y + 12.0),
		Vector2(at.x + bw * 0.5 + 12.0, at.y + 22.0),
	])
	draw_polyline(thread, ink, 1.0)

func _draw_pencil(at: Vector2, rot: float, ink: Color) -> void:
	# workshop pencil: body, facet edge, carved point, ferrule band
	draw_set_transform(at, rot, Vector2.ONE)
	draw_rect(Rect2(-30.0, -4.0, 48.0, 8.0), ink, false, 1.5)
	draw_line(Vector2(-30.0, 0.0), Vector2(18.0, 0.0), Color(ink, ink.a * 0.6), 1.0)
	draw_line(Vector2(18.0, -4.0), Vector2(30.0, 0.0), ink, 1.5)
	draw_line(Vector2(18.0, 4.0), Vector2(30.0, 0.0), ink, 1.5)
	draw_line(Vector2(-26.0, -4.0), Vector2(-26.0, 4.0), ink, 1.5)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_screwdriver(at: Vector2, rot: float, ink: Color) -> void:
	# flat-head screwdriver at rest: handle with grip lines, shaft, flat tip
	draw_set_transform(at, rot, Vector2.ONE)
	draw_rect(Rect2(-45.0, -7.0, 34.0, 14.0), ink, false, 1.5)
	draw_line(Vector2(-37.0, -7.0), Vector2(-37.0, 7.0), Color(ink, ink.a * 0.7), 1.0)
	draw_line(Vector2(-31.0, -7.0), Vector2(-31.0, 7.0), Color(ink, ink.a * 0.7), 1.0)
	draw_line(Vector2(-11.0, 0.0), Vector2(33.0, 0.0), ink, 2.0)
	draw_rect(Rect2(33.0, -3.0, 9.0, 6.0), ink, false, 1.5)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
