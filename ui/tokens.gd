class_name Tokens extends RefCounted
# DESIGN.md tokens in code. static vars so Color("hex") init is legal.

static var BENCH_WALNUT := Color("6B4A2F")
static var BENCH_HI := Color("8A6440")
static var BENCH_LO := Color("3E2A1A")
static var PANEL_FILL := Color("3A2E24")
static var PANEL_DEEP := Color("2A211B")
static var FELT_TEAL := Color("2C4A44")
static var BRASS := Color("B08D57")
static var BRASS_HI := Color("E8C87E")
static var LAMP_KEY := Color("FFD9A0")
static var PARCHMENT := Color("EAD9B0")
static var GLOW_BASE := Color("FFB347")
static var AFF_ATTACK := Color("C05A3E")
static var AFF_DEFENSE := Color("5A7A9A")
static var AFF_MANA := Color("3FA890")
static var TIN := Color("AEB6B8")
static var COBALT := Color("4A90D9")
static var RUNEWOOD := Color("C9A24E")
static var AMETHYST := Color("B857C9")
static var STAT_ATK := Color("D9663E")
static var STAT_DEF := Color("5A8FBF")
static var STAT_SPD := Color("6FCF97")
static var STAT_WEIGHT := Color("D9A441")
static var STAT_WEIGHT_OVER := Color("E8503A")
static var STAT_ENERGY := Color("3FD0C0")
static var DELTA_POS := Color("7FC96B")
static var DELTA_NEG := Color("E8503A")
static var VALID := Color("86D98F")
static var INVALID := Color("E0673F")
static var WAX := Color("B4472E")

# text-tier variants: same hue family, lightened to >=4.5:1 on --panel-fill (a11y gate).
# Use for LABELS/TEXT on dark panels; the base tokens stay for fills/bars/accents.
static var STAT_ATK_TEXT := Color("F08A5E")
static var STAT_DEF_TEXT := Color("7FA9D4")
static var VALID_TEXT := Color("A8E8B0")
static var STRAIN_TEXT := Color("FF8A66")

# affinity text-tier variants (combat color law): same hue family as the AFF_* glow tokens,
# lightened to >=4.5:1 on --panel-deep, for core damage numbers / chips on dark ground.
static var AFF_ATTACK_TEXT := Color("F0906A")
static var AFF_DEFENSE_TEXT := Color("8FB4D9")
static var AFF_MANA_TEXT := Color("6FD0B8")

static func rarity_frame(r: String) -> Color:
    match r:
        "RARE": return BRASS
        "EPIC": return RUNEWOOD
        _: return TIN

static func rarity_accent(r: String) -> Color:
    match r:
        "RARE": return COBALT
        "EPIC": return AMETHYST
        _: return Color(0, 0, 0, 0)

static func affinity_color(a: String) -> Color:
    match a:
        "attack": return AFF_ATTACK
        "defense": return AFF_DEFENSE
        "mana": return AFF_MANA
        _: return GLOW_BASE

static func affinity_text(a: String) -> Color:
    match a:
        "attack": return AFF_ATTACK_TEXT
        "defense": return AFF_DEFENSE_TEXT
        "mana": return AFF_MANA_TEXT
        _: return GLOW_BASE

static func slot_word(slot: String) -> String:
    # player-facing slot vocabulary - never leak the internal enum (studio gate)
    match slot:
        "HEAD": return "Head"
        "CORE": return "Core"
        "ARM_L": return "Left Arm"
        "ARM_R": return "Right Arm"
        "LEGS": return "Legs"
        "BACK": return "Back"
        _: return slot.capitalize()

static func slot_glyph(slot: String) -> String:
    match slot:
        "HEAD": return "◉"
        "CORE": return "❖"
        "ARM_L", "ARM_R": return "✦"
        "LEGS": return "▟"
        "BACK": return "▚"
        _: return "?"

# --- display type (DESIGN.md §2: warm hand-lettered display for headers/nameplate) ------

static var _display_font: Font = null

static func display_font() -> Font:
    if _display_font == null and ResourceLoader.exists("res://art/fonts/Baloo2.ttf"):
        _display_font = load("res://art/fonts/Baloo2.ttf")
    return _display_font

static func display(c: Control, size: int = 0) -> void:
    # apply the warm display face to a header/nameplate control (falls back to default sans)
    var f := display_font()
    if f != null:
        c.add_theme_font_override("font", f)
    if size > 0:
        c.add_theme_font_size_override("font_size", size)

# --- studio-gate helpers (DESIGN.md §6 'primary buttons' + panel materials) -------------

static func shadow(sb: StyleBoxFlat, sz: int = 6) -> StyleBoxFlat:
    # soft drop shadow under panels - part of the warm material pass, never harsh
    sb.shadow_color = Color(0, 0, 0, 0.28)
    sb.shadow_size = sz
    sb.shadow_offset = Vector2(0, 3)
    return sb

static func brass_button(btn: Button) -> void:
    # PRIMARY action treatment: brass plate + brass-hi top bevel + dark-walnut text.
    # One brass tier per screen - everything else stays on charcoal plates.
    var mk := func(fill: Color, border: Color) -> StyleBoxFlat:
        var sb := StyleBoxFlat.new()
        sb.bg_color = fill
        sb.set_corner_radius_all(6)
        sb.border_width_top = 2
        sb.border_color = border
        sb.content_margin_left = 16
        sb.content_margin_right = 16
        sb.content_margin_top = 9
        sb.content_margin_bottom = 9
        return shadow(sb, 4)
    btn.add_theme_stylebox_override("normal", mk.call(BRASS, BRASS_HI))
    btn.add_theme_stylebox_override("hover", mk.call(BRASS.lightened(0.10), GLOW_BASE))
    btn.add_theme_stylebox_override("pressed", mk.call(BRASS.darkened(0.12), BRASS_HI))
    for st in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
        btn.add_theme_color_override(st, BENCH_LO)

# LAYOUT LAW (DESIGN.md section 3): no Label may ever drive a row's min width. A squeezed label
# expands into leftover space, ellipsizes, and carries its full text as a tooltip.
static func squeeze_label(l: Label, floor_w: float = 320.0) -> Label:
    l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    l.custom_minimum_size.x = floor_w
    return l

static func pad_target(c: Control, min_h: float = 44.0) -> void:
    # a11y gate: >=48dp hit area (44px @720p scale) without changing the visual weight
    c.custom_minimum_size.y = maxf(c.custom_minimum_size.y, min_h)

# --- Workshop reskin foundation (DESIGN.md section 9: material sandwich + color economy) -
# Added 2026-07-18. Everything below is ADDITIVE - existing tokens/functions unchanged.

# Slot-family pastels: muted category tints for bit-card title strips and family accents.
# They sit on the warm parchment/walnut ground - never candy-bright, never color-alone
# (always ride the slot glyph). All five checked >=4.5:1 with BENCH_LO text on top.
static var SLOT_HEAD := Color("C9938A")   # Head - dusty rose
static var SLOT_CORE := Color("A893B8")   # Core - heather lilac
static var SLOT_ARMS := Color("9CB08C")   # Arms - sage
static var SLOT_LEGS := Color("C4A76F")   # Legs - warm sand
static var SLOT_BACK := Color("8CA3B8")   # Back - dusty harbor blue

# Material tokens - the shared recipe (one shadow direction, one radius, one seam)
const RADIUS_CARD := 10                       # --radius-card: shared container corner radius
static var SHADOW_SOFT := Color("3E2A1A", 0.40)   # --shadow-soft: dark walnut at 40%, never black
static var STITCH_COLOR := Color("EAD9B0", 0.35)  # --stitch-detail: parchment thread at 35%
const STITCH_DASH := 4.0                      # --stitch-detail: 4px dash / 4px gap
const STITCH_INSET := 3.0                     # --stitch-detail: seam sits 3px inside the rim

static func slot_family(slot: String) -> Color:
    # pastel family tint for a socket family (ARM_L/ARM_R share the Arms pastel)
    match slot:
        "HEAD": return SLOT_HEAD
        "CORE": return SLOT_CORE
        "ARM_L", "ARM_R": return SLOT_ARMS
        "LEGS": return SLOT_LEGS
        "BACK": return SLOT_BACK
        _: return PARCHMENT

static func shadow_soft(sb: StyleBoxFlat, sz: int = 6) -> StyleBoxFlat:
    # --shadow-soft: the ONE shared shadow on every container - offset 0/3px, dark walnut 40%
    sb.shadow_color = SHADOW_SOFT
    sb.shadow_size = sz
    sb.shadow_offset = Vector2(0, 3)
    return sb

static func card_radius(sb: StyleBoxFlat) -> StyleBoxFlat:
    # --radius-card: shared container corner radius
    sb.set_corner_radius_all(RADIUS_CARD)
    return sb

static func sandwich(kind: String = "parchment") -> StyleBoxFlat:
    # The material-sandwich recipe (DESIGN.md section 9 RULE): walnut frame + inset fill +
    # the shared soft shadow + card radius. EVERY container pulls this instead of
    # hand-rolling a box. Component lanes add at most ONE brass accent detail on top
    # (a rivet, a clip, a stitched tab) - the factory stays generic.
    # Kinds: "parchment" (spec card, default) - "deep" (recessed panel) -
    # "brass" (stamped plate, hero-action tier ONLY, one per screen) - "felt" (felt-lined well).
    var sb := StyleBoxFlat.new()
    sb.set_corner_radius_all(RADIUS_CARD)
    sb.set_border_width_all(2)
    sb.content_margin_left = 12
    sb.content_margin_right = 12
    sb.content_margin_top = 12
    sb.content_margin_bottom = 12
    match kind:
        "deep":
            sb.bg_color = PANEL_DEEP
            sb.border_color = BENCH_LO
        "brass":
            sb.bg_color = BRASS
            sb.border_color = BRASS_HI
        "felt":
            sb.bg_color = FELT_TEAL
            sb.border_color = BENCH_WALNUT
        _:   # "parchment" and any unknown kind fall back to the parchment card
            sb.bg_color = PARCHMENT
            sb.border_color = BENCH_WALNUT
    return shadow_soft(sb)

static func draw_stitch(ci: CanvasItem, a: Vector2, b: Vector2, color: Color = Color(0, 0, 0, 0)) -> void:
    # --stitch-detail seam: hand-sewn dashed line (cheap custom _draw work).
    # Zero-alpha color = use the STITCH_COLOR token (GDScript defaults must be const).
    var c := STITCH_COLOR if color.a <= 0.0 else color
    ci.draw_dashed_line(a, b, c, 1.0, STITCH_DASH)

static func draw_stitch_rect(ci: CanvasItem, rect: Rect2, color: Color = Color(0, 0, 0, 0)) -> void:
    # --stitch-detail rim: stitched seam inset STITCH_INSET px inside a container edge
    var r := rect.grow(-STITCH_INSET)
    draw_stitch(ci, r.position, Vector2(r.end.x, r.position.y), color)
    draw_stitch(ci, Vector2(r.end.x, r.position.y), r.end, color)
    draw_stitch(ci, r.end, Vector2(r.position.x, r.end.y), color)
    draw_stitch(ci, Vector2(r.position.x, r.end.y), r.position, color)
