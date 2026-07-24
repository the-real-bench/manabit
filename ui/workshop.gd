class_name WorkshopScreen extends Control
# THE WORKSHOP - where you assemble a whole MANABIT from your BITS. Assembly only.
# Opening chests is a SEPARATE screen (ChestScreen). Binds to BuildSession / §13.
# Drag a bit from YOUR BITS onto a socket, or tap-select a bit then tap a socket.
# Hover a bit to project before->after deltas in the Ledger.

signal open_chests_requested
signal open_menagerie_requested
signal open_compendium_requested
signal open_broker_requested
signal spar_requested(build)
signal open_proving_requested
signal venture_requested(mname)
signal kit_venture_requested          # take Trundle out - needs no core, touches no bench build

var player: PlayerState
var _scrap_chip: Label
var _glimmer_chip: Label
var session: BuildSession
var stage: ManabitStage
var ledger: Ledger
var tray_box: HBoxContainer
var slot_fields: Dictionary = {}
var selected_card: PartCard = null
var _rig: SocketRig
var _warmth: Warmth
var _stage_area: Control
var _hover_slot := ""             # slot warmed by the current tray-card hover (move 3)

var _chests_btn: Button
var _bank_btn: Button
var _bank_note: Label
var _name_edit: LineEdit
var _name_plate: Button          # engraved brass nameplate shown at rest (calm spec 6)
var _top_row: HBoxContainer      # exposed for the smoke_layout gate
var _bank_row: HBoxContainer

# Status-note action (calm spec 7.2): what a tap on the note does. Widens the old
# _note_opens_binding bool - the contract (_set_note, 72-char cap, toast escalation,
# tappable note) is otherwise unchanged.
enum NoteAct { NONE, BINDING, FILTER_CORE }
var _note_act: int = NoteAct.NONE

# The drawer assembly (calm spec section 2): ONE two-state piece of furniture replacing
# the old toolbar row + tray panel. CLOSED (rest default, 50px lip) / OPEN (216 = lip + well).
var _drawer: PanelContainer
var _well: MarginContainer
var _lip: Button                 # the whole lip is one >=44px tap target
var _lip_closed: HBoxContainer   # handle + count tag + spines face
var _lip_open: HBoxContainer     # the toolbar contents + tuck chevron
var _lip_face: LipFace
var _lip_count: Label
var _lip_new: Label
var _drawer_open := false
var _drawer_tween: Tween = null
var _seen_bits := -1             # bits seen with the drawer open (NEW-stamp derivation)
var _bits_at_hide := -1          # inventory size when the screen was left (Wake-return auto-open)
var _dragging := false           # a tray-card drag is in flight (tag + invite suppression)
var _away_press := Vector2.INF   # tap-away guard: press origin on the stage/wall

# The Work-Order Tag (calm spec section 3): the single teaching voice, alive only while
# player.binds_total == 0. State machine T1-T6, first match wins, exactly one alive.
var _tag: WorkOrderTag
var _tag_state := 0              # 0 = no tag
var _tag_slot := ""              # T7 target: first empty socket the player owns a fitting bit for
var _tag_slot_shown := ""        # last slot the T7 copy was inked with (re-ink on change)
var _tag_gone := false           # untie played this session - never returns
var _t6_sheened := false         # the T6/T8 BIND-plate sheen fires once per state entry
const TAG_COPY := {
    1: ["This one's still asleep.", "Seat a core"],
    2: ["A body needs a soul.", "Bind a core - ⚙60"],
    3: ["Sleeping scrap waits.", "Wake a Coffer"],
    4: ["A few filings short.", "Crack the Box of Scrap"],
    5: ["Awake, but empty-handed.", "Give it an arm"],
    6: ["She's ready.", "Press the seal"],
    7: ["Still some empty pegs.", "Fit the %s"],   # action line formatted with slot_word(_tag_slot)
    8: ["She'll fight as she stands.", "Press the seal"],
}

# Tray filter/sort (TrayToolbar in DESIGN.md). One filter state shared by chips + socket-taps.
const CHIP_KEYS := ["", "HEAD", "CORE", "ARMS", "LEGS", "BACK"]   # "" = All
const SORT_NAMES := ["Newest", "Rarity", "Weight", "Attack", "Name"]
var _filter_slot := ""            # "" all · HEAD/CORE/ARMS/LEGS/BACK
var _filter_rarity := ""          # "" all · COMMON/RARE/EPIC
var _sort_mode := 0               # index into SORT_NAMES
var _tray_title: Label
var _slot_chips: Dictionary = {}  # chip key -> Button
var _rarity_opt: OptionButton
var _sort_opt: OptionButton

# --- Lane B1 room ambience (audio-full-game.md section 4) --------------------------------
# The workshop bed (amb_workshop) rides screen visibility; the soul_hum loops ONLY while an
# awake core is seated (dormant bench = silence, the emptiness IS the signal), breath-AM'd off
# the shared engine clock. All calls route through the pre-registered Sfx loop API - sfx.gd is
# never touched here, and every call is headless-inert.
var _soul_hum_on := false            # true while the seated-core hum is live
var _soul_hum_since := 0             # ms of the last (re)start; AM waits out the fade-in first
const SOUL_HUM_AM_DB := 1.5          # gentle breath depth (+/- dB) around the manifest gain
const SOUL_HUM_BREATH_S := 4.0       # matches the soul_hum loop + the stage soul-light cadence
const SOUL_HUM_AM_DELAY_MS := 400    # > the 0.3s fade-in, so the AM never fights the fade tween

func setup(p: PlayerState) -> WorkshopScreen:
    player = p
    return self

func _ready() -> void:
    if player == null:
        player = PlayerState.new()
        player.grant_starter_kit()
    session = BuildSession.new()
    session.inventory = player.bits          # share the collection by reference
    _build_layout()
    visibility_changed.connect(_on_visibility_changed)
    call_deferred("refresh_from_player")
    _boot_room_audio.call_deferred()   # workshop is visible from frame 0 - the signal never fires

func _build_layout() -> void:
    set_anchors_preset(Control.PRESET_FULL_RECT)

    var bg := ColorRect.new()
    bg.color = Tokens.BENCH_WALNUT
    bg.set_anchors_preset(Control.PRESET_FULL_RECT)
    bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(bg)
    _warmth = Warmth.apply(self)   # lamp glow + vignette + grain + woodgrain wash (move 12)
    _warmth.props_enabled = true   # the Workshop is the room the corner props belong to

    # Row budget (ratified 2026-07-18, reskin pass): 6+44+6+386+6+44+6+44+6+166+6 = 720
    # exactly. Action-row demotion (move 7) freed 4px (48 -> 44, still >=44 targets); the
    # stage row - the ONLY vertical expander - absorbs them. One horizontal expander per
    # row, capped labels.
    var root := VBoxContainer.new()
    root.set_anchors_preset(Control.PRESET_FULL_RECT)
    root.offset_left = 16
    root.offset_top = 6
    root.offset_right = -16
    root.offset_bottom = -6
    root.add_theme_constant_override("separation", 6)
    add_child(root)

    _top_row = HBoxContainer.new()
    _top_row.custom_minimum_size = Vector2(0, 44)
    root.add_child(_top_row)
    var brand := Label.new()
    brand.text = "THE WORKSHOP"
    brand.custom_minimum_size = Vector2(150, 0)
    brand.add_theme_color_override("font_color", Tokens.BRASS_HI)
    Tokens.display(brand, 18)   # warm display face (DESIGN.md section 2)
    _shade(brand)               # move 14: display text never sits naked on the ground
    _top_row.add_child(brand)
    _name_edit = LineEdit.new()
    _name_edit.text = "Cogsworth-7"
    _name_edit.max_length = 16
    _name_edit.placeholder_text = "Name your Manabit"
    _name_edit.custom_minimum_size = Vector2(180, 0)
    Tokens.display(_name_edit, 17)   # the nameplate is display type (DESIGN.md section 2)
    _name_edit.visible = false       # calm spec 6: the raw form field appears only on tap
    _name_edit.focus_exited.connect(_commit_name)
    _name_edit.text_submitted.connect(func(_t): _commit_name())
    _top_row.add_child(_name_edit)
    # At rest the name renders as an ENGRAVED BRASS NAMEPLATE (brass = nameplate material
    # per DESIGN.md section 1 - the hero-action brass TIER stays the BIND plate alone).
    _name_plate = Button.new()
    _name_plate.text = _name_edit.text
    _name_plate.custom_minimum_size = Vector2(180, 0)
    _name_plate.tooltip_text = "Tap to rename your Manabit."
    Tokens.display(_name_plate, 17)
    var npmk := func(fill: Color) -> StyleBoxFlat:
        var sb := StyleBoxFlat.new()
        sb.bg_color = fill
        sb.set_corner_radius_all(6)
        sb.set_border_width_all(1)
        sb.border_color = Color(Tokens.BENCH_LO, 0.6)
        sb.content_margin_left = 10
        sb.content_margin_right = 10
        sb.content_margin_top = 5
        sb.content_margin_bottom = 5
        return sb
    _name_plate.add_theme_stylebox_override("normal", npmk.call(Tokens.BRASS))
    _name_plate.add_theme_stylebox_override("hover", npmk.call(Tokens.BRASS.lightened(0.08)))
    _name_plate.add_theme_stylebox_override("pressed", npmk.call(Tokens.BRASS.darkened(0.10)))
    for npst in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
        _name_plate.add_theme_color_override(npst, Tokens.BENCH_LO)
    Tokens.pad_target(_name_plate)
    _name_plate.pressed.connect(_on_name_plate_tapped)
    _top_row.add_child(_name_plate)
    _scrap_chip = _make_chip(Tokens.BRASS_HI, 66)
    _top_row.add_child(_scrap_chip)
    _glimmer_chip = _make_chip(Tokens.STAT_ENERGY, 56)
    _top_row.add_child(_glimmer_chip)
    var spacer := Control.new()
    spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL   # the row's ONE expander
    _top_row.add_child(spacer)
    var men_btn := Button.new()
    men_btn.text = "Menagerie"
    men_btn.custom_minimum_size = Vector2(100, 0)
    men_btn.pressed.connect(func(): Sfx.play(&"ui_tap"); open_menagerie_requested.emit())
    Tokens.pad_target(men_btn)
    _top_row.add_child(men_btn)
    var comp_btn := Button.new()
    comp_btn.text = "Compendium"
    comp_btn.custom_minimum_size = Vector2(110, 0)
    comp_btn.pressed.connect(func(): Sfx.play(&"ui_tap"); open_compendium_requested.emit())
    Tokens.pad_target(comp_btn)
    _top_row.add_child(comp_btn)
    var broker_btn := Button.new()
    broker_btn.text = "Fettle's Cart"
    broker_btn.custom_minimum_size = Vector2(120, 0)
    broker_btn.pressed.connect(func(): Sfx.play(&"ui_tap"); open_broker_requested.emit())
    Tokens.pad_target(broker_btn)
    _top_row.add_child(broker_btn)
    _chests_btn = Button.new()
    _chests_btn.custom_minimum_size = Vector2(176, 0)
    _chests_btn.pressed.connect(func(): Sfx.play(&"ui_tap"); open_chests_requested.emit())
    Tokens.pad_target(_chests_btn)
    _top_row.add_child(_chests_btn)

    var mid := HBoxContainer.new()
    mid.size_flags_vertical = Control.SIZE_EXPAND_FILL
    mid.add_theme_constant_override("separation", 14)
    root.add_child(mid)

    var stage_area := Control.new()
    stage_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    stage_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
    stage_area.custom_minimum_size = Vector2(560, 380)
    mid.add_child(stage_area)
    _stage_area = stage_area

    # Move 2 (2D half): the stage is a display STAND, not a viewport - the 3D texture is
    # inset 10px top/bottom so warm walnut wall shows on all four edges (the 4:3 aspect
    # already leaves wall at the sides), and a StandFrame draws the rounded felt corners,
    # brass rim, stitched seam, and lamp pool over it.
    stage = ManabitStage.new()
    stage.set_anchors_preset(Control.PRESET_FULL_RECT)
    stage.offset_top = 10
    stage.offset_bottom = -10
    stage_area.add_child(stage)
    var frame := StandFrame.new()
    frame.set_anchors_preset(Control.PRESET_FULL_RECT)
    frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
    stage_area.add_child(frame)

    _rig = SocketRig.new().setup(session)
    _rig.set_anchors_preset(Control.PRESET_FULL_RECT)
    stage_area.add_child(_rig)
    slot_fields = _rig.slot_fields
    for sname in slot_fields:
        slot_fields[sname].equip_requested.connect(_on_equip_requested)
        slot_fields[sname].tapped.connect(_on_slot_tapped)
        slot_fields[sname].hovered.connect(_on_socket_hovered)
        slot_fields[sname].inspect_requested.connect(_on_slot_inspect)

    # The Work-Order Tag (calm spec 3): parchment swing-tag on the stand's brass rim,
    # bottom-left inside the stage area, clear of the CORE medallion (x starts past its
    # right edge) and the plinth. STOP filter: its input never reaches the drag-rotate
    # stage or the tap-away close handler.
    _tag = WorkOrderTag.new()
    _tag.visible = false
    _tag.tapped.connect(_on_tag_tapped)
    stage_area.add_child(_tag)

    # Move 12: the blueprint watermark lives on the wall band beside the stand (behind an
    # opaque stage texture it would be invisible), re-placed whenever the stand resizes.
    stage_area.resized.connect(_place_watermark)
    stage_area.resized.connect(_place_tag)
    call_deferred("_place_watermark")
    call_deferred("_place_tag")

    # Tap-away (calm spec 2.4.3): a clean press-release on the stage or wall first cancels
    # a tap-place selection, then closes the drawer. Guarded against drag releases and
    # >6px rotation travel. A stationary stage click did nothing before - this input is free.
    stage.gui_input.connect(_on_stage_gui)
    stage_area.gui_input.connect(_on_stage_gui)

    ledger = Ledger.new()
    ledger.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    mid.add_child(ledger)

    # Move 7: ONE hero action. BIND is a stamped brass plate with a wax-seal press; the
    # other four demote to quiet ink-and-underline links. Handlers and gating unchanged.
    _bank_row = HBoxContainer.new()
    _bank_row.custom_minimum_size = Vector2(0, 44)
    _bank_row.add_theme_constant_override("separation", 8)
    root.add_child(_bank_row)
    _bank_btn = Button.new()
    _bank_btn.text = "BIND MANABIT"
    _bank_btn.custom_minimum_size = Vector2(190, 0)
    _bank_btn.pressed.connect(_on_bank)
    _brass_plate(_bank_btn)          # the screen's ONE primary brass action (hero tier)
    Tokens.pad_target(_bank_btn)
    var seal := WaxSeal.new()
    seal.set_anchors_preset(Control.PRESET_CENTER_LEFT)
    seal.offset_left = 8
    seal.offset_right = 32
    seal.offset_top = -12
    seal.offset_bottom = 12
    seal.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _bank_btn.add_child(seal)
    _bank_row.add_child(_bank_btn)
    var spar_btn := Button.new()
    spar_btn.text = "Spar"
    spar_btn.custom_minimum_size = Vector2(96, 0)
    spar_btn.pressed.connect(_on_spar)
    _ink_link(spar_btn)
    _bank_row.add_child(spar_btn)
    var bout_btn := Button.new()
    bout_btn.text = "Bout"
    bout_btn.custom_minimum_size = Vector2(96, 0)
    bout_btn.pressed.connect(_on_bout)
    _ink_link(bout_btn)
    _bank_row.add_child(bout_btn)
    var venture_btn := Button.new()
    venture_btn.text = "Venture"
    venture_btn.custom_minimum_size = Vector2(128, 0)
    venture_btn.pressed.connect(_on_venture)
    _ink_link(venture_btn)
    _bank_row.add_child(venture_btn)
    var kit_btn := Button.new()
    kit_btn.text = "Box of Scrap"
    kit_btn.custom_minimum_size = Vector2(156, 0)
    kit_btn.tooltip_text = "Crack a free Box of Scrap - needs no core, full of who-knows-what.\nSome boxes clear a whole run; some get you got. Crack it and see."
    kit_btn.pressed.connect(_open_box_reveal)
    _ink_link(kit_btn)
    _bank_row.add_child(kit_btn)
    # BIND CORE lives in the tray now (BindCoreCard on the CORE filter) - not a seventh button.
    _bank_note = Label.new()
    _bank_note.add_theme_font_size_override("font_size", 13)
    _bank_note.tooltip_text = ""
    Tokens.squeeze_label(_bank_note, 320)   # the row's ONE expander; ellipsizes, never pushes
    _bank_note.gui_input.connect(_on_note_tapped)
    _bank_note.mouse_filter = Control.MOUSE_FILTER_STOP
    _bank_row.add_child(_bank_note)

    _build_drawer(root)

func refresh_from_player() -> void:
    _scrap_chip.text = "⚙ %s" % _cap_amount(player.scrap)
    _glimmer_chip.text = "✦ %s" % _cap_amount(player.glimmer)
    var cn := player.coffer_count()
    _chests_btn.text = "◈ Wake Coffers (x%s)" % ("9+" if cn > 9 else str(cn))
    stage.rebuild(session.manabit)
    _hover_slot = ""                 # stage rebuild clears highlights; forget stale hovers
    var core_missing := session.manabit.core() == null
    var no_weapon := not session.manabit.has_offensive_move()
    for sname in slot_fields:
        slot_fields[sname].refresh()
        slot_fields[sname].set_eligibility(false, false)
        # amber ! pip: mark what blocks the bind right now (core first, then a weapon arm)
        if sname == "CORE":
            slot_fields[sname].set_needed(core_missing)
        elif sname == "ARM_L" or sname == "ARM_R":
            slot_fields[sname].set_needed(not core_missing and no_weapon)
    ledger.show_build(session)
    _refresh_tray()
    _refresh_tag()      # one teaching voice - computed BEFORE the bank note (one-voice rule)
    _refresh_bank()
    _refresh_calm()
    _update_soul_hum()  # a core just seated/pulled changes whether the bench has a soul to hum

# --- The drawer assembly (calm spec section 2) ------------------------------------------
# One PanelContainer: a 50px walnut LIP over the 166px felt WELL, internal separation 0 -
# one piece of furniture, the felt runs up under the lip. Binary machine: CLOSED (rest
# default) / OPEN (work). The old TrayToolbar contents live on the OPEN lip; the well is
# the old tray byte-for-byte (same PartCard grid, tilt, BindCoreCard, slim scroll, notes).
const LIP_H := 50.0
const WELL_H := 166.0
const LIP_TIP := "Slide the drawer open - your bits live in here."

func _build_drawer(root: VBoxContainer) -> void:
    _drawer = PanelContainer.new()
    var tsb := Tokens.sandwich("felt")
    tsb.bg_color = Tokens.FELT_TEAL.darkened(0.18)   # drawer felt sits deeper than the stand
    tsb.set_border_width_all(3)
    tsb.content_margin_left = 0      # tight drawer - margins live on the well wrapper now
    tsb.content_margin_right = 0
    tsb.content_margin_top = 0
    tsb.content_margin_bottom = 0
    _drawer.add_theme_stylebox_override("panel", tsb)
    root.add_child(_drawer)
    var dv := VBoxContainer.new()
    dv.add_theme_constant_override("separation", 0)
    _drawer.add_child(dv)

    # THE LIP: one Button = one >=44px tap target (closed: opens; open: background tap
    # closes - chips/dropdowns/chevron are STOP children and consume their own input).
    _lip = Button.new()
    _lip.custom_minimum_size = Vector2(0, LIP_H)
    _lip.focus_mode = Control.FOCUS_ALL      # keyboard / gamepad accept opens (trigger 5)
    _lip.tooltip_text = LIP_TIP
    var lipmk := func(fill: Color) -> StyleBoxFlat:
        var sb := StyleBoxFlat.new()
        sb.bg_color = fill
        sb.corner_radius_top_left = Tokens.RADIUS_CARD - 3
        sb.corner_radius_top_right = Tokens.RADIUS_CARD - 3
        return sb
    _lip.add_theme_stylebox_override("normal", lipmk.call(Tokens.BENCH_WALNUT.darkened(0.06)))
    _lip.add_theme_stylebox_override("hover", lipmk.call(Tokens.BENCH_WALNUT))
    _lip.add_theme_stylebox_override("pressed", lipmk.call(Tokens.BENCH_WALNUT.darkened(0.18)))
    _lip.add_theme_stylebox_override("hover_pressed", lipmk.call(Tokens.BENCH_WALNUT.darkened(0.12)))
    var lfoc := StyleBoxFlat.new()
    lfoc.draw_center = false
    lfoc.set_border_width_all(2)
    lfoc.border_color = Color(Tokens.LAMP_KEY, 0.7)
    lfoc.corner_radius_top_left = Tokens.RADIUS_CARD - 3
    lfoc.corner_radius_top_right = Tokens.RADIUS_CARD - 3
    _lip.add_theme_stylebox_override("focus", lfoc)
    _lip.pressed.connect(_on_lip_pressed)
    _lip.mouse_entered.connect(func(): _lip_face.hover = true; _lip_face.queue_redraw())
    _lip.mouse_exited.connect(func(): _lip_face.hover = false; _lip_face.queue_redraw())
    dv.add_child(_lip)
    _lip_face = LipFace.new()
    _lip_face.set_anchors_preset(Control.PRESET_FULL_RECT)
    _lip_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _lip.add_child(_lip_face)

    # CLOSED face: parchment count tag + paper NEW stamp (handle + spines drawn by LipFace).
    _lip_closed = HBoxContainer.new()
    _lip_closed.set_anchors_preset(Control.PRESET_FULL_RECT)
    _lip_closed.offset_left = 12
    _lip_closed.offset_right = -12
    _lip_closed.offset_top = 3
    _lip_closed.offset_bottom = -3
    _lip_closed.add_theme_constant_override("separation", 10)
    _lip_closed.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _lip.add_child(_lip_closed)
    _lip_count = Label.new()
    Tokens.display(_lip_count, 12)
    _lip_count.add_theme_color_override("font_color", Tokens.BENCH_LO)
    var cts := StyleBoxFlat.new()
    cts.bg_color = Tokens.PARCHMENT
    cts.set_corner_radius_all(4)
    cts.set_border_width_all(1)
    cts.border_color = Color(Tokens.BENCH_WALNUT, 0.7)
    cts.content_margin_left = 8
    cts.content_margin_right = 8
    cts.content_margin_top = 2
    cts.content_margin_bottom = 2
    _lip_count.add_theme_stylebox_override("normal", cts)
    _lip_count.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    _lip_count.rotation_degrees = -1.0      # a tied-on parchment tag, not a printed rule
    _lip_count.pivot_offset = Vector2(0, 12)
    _lip_closed.add_child(_lip_count)
    _lip_new = Label.new()
    Tokens.display(_lip_new, 10)
    _lip_new.add_theme_color_override("font_color", Tokens.BENCH_LO)
    var nsb := StyleBoxFlat.new()
    nsb.bg_color = Tokens.PARCHMENT
    nsb.set_corner_radius_all(3)
    nsb.set_border_width_all(1)
    nsb.border_color = Color(Tokens.BENCH_WALNUT, 0.6)
    nsb.content_margin_left = 5
    nsb.content_margin_right = 5
    nsb.content_margin_top = 1
    nsb.content_margin_bottom = 1
    _lip_new.add_theme_stylebox_override("normal", nsb)
    _lip_new.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    _lip_new.rotation_degrees = -3.0
    _lip_new.visible = false
    _lip_closed.add_child(_lip_new)

    # OPEN face: the toolbar moved onto the lip (same controls, same state machine - only
    # their container moved) + the 44px brass tuck chevron. No control reparents at runtime.
    _lip_open = HBoxContainer.new()
    _lip_open.set_anchors_preset(Control.PRESET_FULL_RECT)
    _lip_open.offset_left = 8
    _lip_open.offset_right = -8
    _lip_open.offset_top = 3
    _lip_open.offset_bottom = -3
    _lip_open.add_theme_constant_override("separation", 8)
    _lip_open.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _lip_open.visible = false
    _lip.add_child(_lip_open)
    _tray_title = Label.new()
    _tray_title.add_theme_font_size_override("font_size", 12)
    _tray_title.add_theme_color_override("font_color", Tokens.BRASS_HI)
    _tray_title.custom_minimum_size = Vector2(150, 0)
    _tray_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _lip_open.add_child(_tray_title)
    for key in CHIP_KEYS:
        var chip := Button.new()
        chip.toggle_mode = true
        chip.text = _chip_label(key)
        chip.add_theme_font_size_override("font_size", 12)
        chip.pressed.connect(_on_filter_chip.bind(key))
        _file_tab(chip)              # move 9: chips read as skewed file-tabs on the drawer lip
        Tokens.pad_target(chip)
        _lip_open.add_child(chip)
        _slot_chips[key] = chip
    var sp := Control.new()
    sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    sp.mouse_filter = Control.MOUSE_FILTER_IGNORE   # background here = the lip (tap closes)
    _lip_open.add_child(sp)
    _rarity_opt = OptionButton.new()
    for r in ["Any rarity", "Common", "Rare", "Epic"]:
        _rarity_opt.add_item(r)
    _rarity_opt.item_selected.connect(_on_rarity_selected)
    _lip_open.add_child(_rarity_opt)
    _sort_opt = OptionButton.new()
    for s in SORT_NAMES:
        _sort_opt.add_item("Sort: " + s)
    _sort_opt.item_selected.connect(_on_sort_selected)
    _lip_open.add_child(_sort_opt)
    var chev := Button.new()
    chev.text = "▾"
    chev.custom_minimum_size = Vector2(44, 0)
    chev.tooltip_text = "Tuck the drawer away."
    Tokens.brass_button(chev)
    Tokens.pad_target(chev)
    chev.pressed.connect(func(): _set_drawer(false))
    _lip_open.add_child(chev)

    # THE WELL: the old tray, unchanged - felt margins on a wrapper so the closed drawer
    # is exactly the 50px lip. Vertical scroll is SHOW_NEVER (not DISABLED) so the well's
    # min height never fights the 180ms min-height slide; at rest OPEN the 166px well
    # holds the full cards exactly as before.
    _well = MarginContainer.new()
    _well.custom_minimum_size = Vector2(0, WELL_H)
    _well.add_theme_constant_override("margin_left", 6)
    _well.add_theme_constant_override("margin_right", 6)
    _well.add_theme_constant_override("margin_top", 4)
    _well.add_theme_constant_override("margin_bottom", 6)
    _well.visible = false
    dv.add_child(_well)
    var scroll := ScrollContainer.new()
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
    scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
    var hbar := scroll.get_h_scroll_bar()
    if hbar != null:
        hbar.custom_minimum_size = Vector2(0, 4)   # slim overlay-style indicator, not an 8px bar
        var hsb := StyleBoxFlat.new()
        hsb.bg_color = Color(Tokens.BRASS, 0.55)
        hsb.set_corner_radius_all(2)
        hbar.add_theme_stylebox_override("grabber", hsb)
        var track := StyleBoxFlat.new()
        track.bg_color = Color(0, 0, 0, 0.0)
        hbar.add_theme_stylebox_override("scroll", track)
    _well.add_child(scroll)
    tray_box = HBoxContainer.new()
    tray_box.add_theme_constant_override("separation", 8)
    scroll.add_child(tray_box)
    var chrome := DrawerChrome.new()
    chrome.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _drawer.add_child(chrome)     # carved brackets + dovetail teeth over the whole drawer

func _on_lip_pressed() -> void:
    _set_drawer(not _drawer_open)

# The drawer state machine. NEVER called by equip/unequip/filter/sort/drag-end paths -
# building stays iterative (calm spec 2.4). Closing always clears any live selection.
func _set_drawer(open: bool, animate: bool = true) -> void:
    if _drawer_open == open:
        return
    _drawer_open = open
    _lip_closed.visible = not open
    _lip_open.visible = open
    _lip_face.open = open
    _lip_face.queue_redraw()
    _lip.tooltip_text = "" if open else LIP_TIP
    if _drawer_tween != null and _drawer_tween.is_valid():
        _drawer_tween.kill()
    _drawer_tween = null
    if open:
        Sfx.play(&"drawer_slide")        # wood-on-felt slide (audio wave 4a group 4)
        _seen_bits = session.inventory.size()   # opening = seeing your bits (NEW stamp clears)
        _well.visible = true
        if Juice.reduce_motion or not animate:
            _well.custom_minimum_size.y = WELL_H
        else:
            _well.custom_minimum_size.y = 16.0
            _drawer_tween = create_tween()
            _drawer_tween.tween_property(_well, "custom_minimum_size:y", WELL_H, 0.18) \
                .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
        _refresh_lip()   # the filtered title re-presents before the slide finishes (2.5)
    else:
        Sfx.play(&"drawer_tuck")         # felt-damped clunk on the tuck
        _clear_selection()
        if Juice.reduce_motion or not animate:
            _well.visible = false
            _well.custom_minimum_size.y = WELL_H
        else:
            _drawer_tween = create_tween()
            _drawer_tween.tween_property(_well, "custom_minimum_size:y", 16.0, 0.18) \
                .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
            _drawer_tween.tween_callback(_finish_drawer_close)
        _refresh_lip()
    _refresh_calm()

func _finish_drawer_close() -> void:
    if not _drawer_open:
        _well.visible = false
        _well.custom_minimum_size.y = WELL_H

# THE drawer seam (calm spec 3.3): every teaching action that needs the drawer routes
# through here - set filter + ensure open + light the medallion (set_lit rides the
# existing _sync_filter_chips). If the drawer were backed out this degrades to filter-only.
func _focus_slot_in_tray(chip_key: String) -> void:
    _filter_slot = chip_key
    _set_drawer(true)
    _refresh_tray()
    _maybe_nudge()

# Screen entry/exit (calm spec 2.3): entry-time auto-open for a Wake-return with new bits;
# every other entry starts CLOSED. Open state is never persisted.
func _on_visibility_changed() -> void:
    # Room bed rides visibility: 200ms fade-in on enter crosses the outgoing screen's fade
    # through near-silence (both beds near -60 dB mid-swap); fade-out with the room on exit.
    if visible:
        Sfx.loop_start(&"amb_workshop", 0.2)
    else:
        Sfx.loop_stop(&"amb_workshop", 0.2)
        Sfx.loop_stop(&"soul_hum", 0.2)   # the soul leaves with the room
        _soul_hum_on = false              # the shared _process drops the breath tick next idle
    if session == null or _drawer == null:
        return
    if visible:
        if _bits_at_hide >= 0 and session.inventory.size() > _bits_at_hide:
            _set_drawer(true, false)     # trigger 3: new bits up front (Newest is the default sort)
        else:
            _set_drawer(false, false)
        _update_soul_hum()
    else:
        _bits_at_hide = session.inventory.size()
        _close_inspect()   # never carry a held inspect (stage z 40 + scale) across screens

# The seated-core hum: live ONLY while an awake core is on the bench (same predicate the stage's
# soul light uses - core seated and not disabled). A dormant bench stays silent; the emptiness
# itself is the signal. Transition-driven so the per-frame breath AM below never fights a fade.
func _update_soul_hum() -> void:
    var core: PartInstance = session.manabit.core() if session != null else null
    var want := visible and core != null and not core.disabled
    if want != _soul_hum_on:
        _soul_hum_on = want
        if want:
            Sfx.loop_start(&"soul_hum", 0.3)
            _soul_hum_since = Time.get_ticks_msec()
        else:
            Sfx.loop_stop(&"soul_hum", 0.3)
    if _soul_hum_on and not Juice.reduce_motion:
        set_process(true)   # the shared _process self-disables once no hold/breath is live

# Breath AM: a gentle amplitude sway around the manifest gain, sampled from the shared engine
# clock (like the slot-ring / cavity-rim heartbeats) so it reads as the same breath the toy takes.
# loop_gain(..., 0.0) is a direct volume_db set - cheap, no tween - so this is not a second tween
# system. Driven from the shared _process tick (below); it keeps _process alive while the hum is
# live and applies the sway once the fade-in tween has finished. Skipped under reduce-motion
# (constant hum then - reduce-motion never disables audio, it only stills the sway).
func _breathe_soul_hum() -> void:
    var base := float(Sfx.MANIFEST[&"soul_hum"].get("gain_db", -30.0))
    var ph := float(Time.get_ticks_msec()) / 1000.0 * TAU / SOUL_HUM_BREATH_S
    Sfx.loop_gain(&"soul_hum", base + SOUL_HUM_AM_DB * sin(ph), 0.0)

# Boot start (workshop only): the workshop is visible from frame 0, so visibility_changed never
# fires for it, AND the Sfx voice pool enters the tree a deferred frame after the first loop_start
# so the very first call is dropped. Re-issue across a few frames until the pool is live; the loop
# API is idempotent (a re-fade to the same gain), and _soul_hum_on is reset so the seated-core hum
# also (re)starts once the pool lands. Confined to the first frames of boot only.
func _boot_room_audio() -> void:
    for _i in 4:
        if not visible:
            return
        Sfx.loop_start(&"amb_workshop", 0.2)
        _soul_hum_on = false
        _update_soul_hum()
        await get_tree().process_frame

# Tap-away close (calm spec 2.4.3) - shared handler for the stage and the wall band.
func _on_stage_gui(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed:
            _away_press = get_global_mouse_position() if not get_viewport().gui_is_dragging() else Vector2.INF
            return
        var at := get_global_mouse_position()
        var clean: bool = _away_press.is_finite() and at.distance_to(_away_press) <= 6.0 \
            and not get_viewport().gui_is_dragging()
        _away_press = Vector2.INF
        if not clean:
            return
        if selected_card != null:
            _clear_selection()           # first tap-away CANCELS a tap-place selection
        elif _drawer_open:
            _set_drawer(false)

func _clear_selection() -> void:
    if selected_card != null and is_instance_valid(selected_card):
        selected_card.set_selected(false)
    selected_card = null
    for sname in slot_fields:
        slot_fields[sname].set_eligibility(false, false)
    _refresh_calm()

# Closed-lip dressing: honest TOTAL count tag, NEW stamp while unseen bits exist, spines.
func _refresh_lip() -> void:
    if _lip_count == null:
        return
    var total := session.inventory.size()
    if _seen_bits < 0:
        _seen_bits = total               # first refresh: nothing is "new" yet
    if _drawer_open:
        _seen_bits = total
    _lip_count.text = "YOUR BITS · %d" % total
    var fresh := maxi(0, total - _seen_bits)
    _lip_new.visible = fresh > 0 and not _drawer_open
    if fresh > 0:
        _lip_new.text = "NEW ·%d" % fresh
    # spines: first 6 of the current sorted view - slot-family pastel + rarity-material edge
    var spines := []
    if total > 0:
        var view := _tray_view()
        for i in mini(6, view.size()):
            var pi: PartInstance = view[i]
            spines.append([Tokens.slot_family(String(pi.data.slot)), Tokens.rarity_frame(pi.data.rarity)])
    _lip_face.spines = spines
    _lip_face.queue_redraw()

# First-fitting-card settle nudge (calm spec 3.4): tag era ONLY - veterans never see
# teaching motion. Fired by the slot-filter open paths, once per filter-open.
func _maybe_nudge() -> void:
    if player.binds_total != 0 or Juice.reduce_motion or _filter_slot == "":
        return
    _nudge_first_card()

func _nudge_first_card() -> void:
    await get_tree().process_frame       # let the container seat the fresh cards first
    for c in tray_box.get_children():
        if c is PartCard and is_instance_valid(c):
            var card := c as PartCard
            var base_y: float = card.position.y
            var tw := card.create_tween()
            tw.tween_property(card, "position:y", base_y - 8.0, 0.08) \
                .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
            tw.tween_property(card, "position:y", base_y, 0.12) \
                .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
            return

func _chip_label(key: String) -> String:
    if key == "":
        return "All"
    return "%s %s" % [Tokens.slot_glyph(_socket_for_chip(key)), key.capitalize()]

func _socket_for_chip(key: String) -> String:
    return "ARM_L" if key == "ARMS" else key    # slot_accepts covers both arms from either

func _chip_key_for(slot_name: String) -> String:
    return "ARMS" if (slot_name == "ARM_L" or slot_name == "ARM_R") else slot_name

func _on_filter_chip(key: String) -> void:
    Sfx.play(&"ui_tap")                  # file-tab chip (audio wave 4a: generic UI micro)
    _filter_slot = "" if (key == "" or _filter_slot == key) else key
    _refresh_tray()

func _on_rarity_selected(idx: int) -> void:
    Sfx.play(&"ui_tap")
    _filter_rarity = ["", "COMMON", "RARE", "EPIC"][idx]
    _refresh_tray()

func _on_sort_selected(idx: int) -> void:
    Sfx.play(&"ui_tap")
    _sort_mode = idx
    _refresh_tray()

func _sync_filter_chips() -> void:
    for key in _slot_chips:
        var on: bool = (_filter_slot == key) if key != "" else (_filter_slot == "")
        _slot_chips[key].set_pressed_no_signal(on)
    # the slot rail and anatomy legend mirror the ONE filter state (never a parallel rule)
    for sname in slot_fields:
        slot_fields[sname].set_lit(_filter_slot != "" and _chip_key_for(sname) == _filter_slot)
    if _rig != null:
        _rig.set_active_slot(_filter_slot)

func _bit_passes(pi: PartInstance) -> bool:
    if _filter_slot != "" and not session.slot_accepts(_socket_for_chip(_filter_slot), pi):
        return false
    if _filter_rarity != "" and pi.data.rarity != _filter_rarity:
        return false
    return true

# Filtered + sorted COPY of the inventory (never sort the live array - it IS player.bits).
func _tray_view() -> Array:
    var view := []
    for pi in session.inventory:
        if _bit_passes(pi):
            view.append(pi)
    match _sort_mode:
        0: view.reverse()                                     # Newest first (appends land last)
        1: view.sort_custom(func(a, b): return _rarity_rank(a) > _rarity_rank(b))
        2: view.sort_custom(func(a, b): return a.data.weight < b.data.weight)
        3: view.sort_custom(func(a, b): return a.data.attack > b.data.attack)
        4: view.sort_custom(func(a, b): return String(a.data.display_name) < String(b.data.display_name))
    return view

func _rarity_rank(pi: PartInstance) -> int:
    match pi.data.rarity:
        "EPIC": return 2
        "RARE": return 1
        _: return 0

func _refresh_tray() -> void:
    _sync_filter_chips()
    for c in tray_box.get_children():
        c.queue_free()
    var total := session.inventory.size()
    if total == 0:
        _tray_title.text = "YOUR BITS · 0"
        var empty := Label.new()
        empty.text = "  Your bench is bare. Wake a Coffer to find some bits."
        empty.add_theme_color_override("font_color", Color(Tokens.PARCHMENT, 0.5))
        tray_box.add_child(empty)
        _refresh_lip()
        return
    var view := _tray_view()
    if _filter_slot == "" and _filter_rarity == "":
        _tray_title.text = "YOUR BITS · %d" % total
    else:
        var desc := ""
        if _filter_slot != "":
            desc = "%s %s" % [Tokens.slot_glyph(_socket_for_chip(_filter_slot)), _filter_slot]
        if _filter_rarity != "":
            desc += (" · " if desc != "" else "") + _filter_rarity
        _tray_title.text = "%s · %d of %d" % [desc, view.size(), total]
    if view.is_empty():
        var none := Label.new()
        none.text = "  No spare cores on the bench." if _filter_slot == "CORE" else "  No bits match this filter - tap All to clear."
        none.add_theme_color_override("font_color", Color(Tokens.PARCHMENT, 0.5))
        tray_box.add_child(none)
    else:
        var seated_ids := {}
        for sname in ManabitState.SLOT_NAMES:
            var eq: PartInstance = session.manabit.slots.get(sname)
            if eq != null:
                seated_ids[String(eq.data.id)] = true
        for pi in view:
            var card := PartCard.new().setup(pi, "tray")
            card.selected.connect(_on_card_selected)
            card.activated.connect(_on_card_activated)      # double-click = attach to the build
            card.drag_started.connect(_on_card_drag_started)
            card.drag_ended.connect(_on_card_drag_ended)
            card.mouse_entered.connect(_on_card_hover.bind(pi))
            card.mouse_exited.connect(_on_card_unhover)
            card.gui_input.connect(_on_card_gui.bind(card))   # move 10: long-press inspect
            card.set_seated(seated_ids.has(String(pi.data.id)))   # wax dot: kin already aboard
            # move 9: bits REST in the drawer - a fixed 1-2 deg tilt seeded from the bit id
            # hash (never runtime-random, so screenshots stay stable)
            card.rotation_degrees = _card_tilt(pi)
            card.pivot_offset = card.custom_minimum_size * 0.5
            tray_box.add_child(card)
    if _filter_slot == "CORE":
        tray_box.add_child(_make_bind_core_card())   # The Binding lives here now, not the deploy bar
    _refresh_lip()

# BindCoreCard: a ghost card that opens the Binding overlay. Sits at the end of the CORE filter.
func _make_bind_core_card() -> PanelContainer:
    var p := PanelContainer.new()
    p.custom_minimum_size = Vector2(122, 150)
    p.mouse_filter = Control.MOUSE_FILTER_STOP
    var can_afford := player.scrap >= PlayerState.BIND_CORE_COST
    var sb := Tokens.sandwich("deep")            # ghost card on the sandwich recipe
    sb.bg_color = Color(Tokens.PANEL_FILL, 0.5)
    sb.border_color = Color(Tokens.BRASS, 0.65)
    sb.content_margin_left = 8
    sb.content_margin_right = 8
    sb.content_margin_top = 10
    sb.content_margin_bottom = 8
    p.add_theme_stylebox_override("panel", sb)
    var v := VBoxContainer.new()
    v.add_theme_constant_override("separation", 4)
    v.alignment = BoxContainer.ALIGNMENT_CENTER
    p.add_child(v)
    var glyph := Label.new()
    glyph.text = "❖"
    glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    glyph.add_theme_font_size_override("font_size", 26)
    glyph.add_theme_color_override("font_color", Tokens.BRASS_HI)
    v.add_child(glyph)
    var title := Label.new()
    title.text = "Bind a core"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    Tokens.display(title, 14)
    title.add_theme_color_override("font_color", Tokens.PARCHMENT)
    v.add_child(title)
    var price := Label.new()
    price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    price.add_theme_font_size_override("font_size", 12)
    if can_afford:
        price.text = "⚙%d" % PlayerState.BIND_CORE_COST
        price.add_theme_color_override("font_color", Tokens.BRASS_HI)
    else:
        price.text = "need ⚙%d more" % (PlayerState.BIND_CORE_COST - player.scrap)
        price.add_theme_color_override("font_color", Tokens.STRAIN_TEXT)
        p.modulate = Color(1, 1, 1, 0.6)
    v.add_child(price)
    p.gui_input.connect(func(e): if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT: _toggle_binding_panel())
    return p

func _refresh_bank() -> void:
    var ok := session.is_deployable()
    _bank_btn.disabled = not ok
    if ok:
        # never an unqualified all-clear while strained (studio gate): binding is legal, but say the cost
        var dd := session.current_derived()
        var w := int(dd.weight)
        var cap := int(dd.get("capacity", 100))
        var empties := 0
        for s in ManabitState.SLOT_NAMES:
            if session.manabit.slots.get(s) == null:
                empties += 1
        var lone_weapon := _offensive_count() == 1   # D3: one bit stands between it and a defang
        var cheapest := _min_attack_cost()
        var energy := int(dd.get("energy", 0))
        # a weapon it can never afford is a guaranteed mutual-GUARD stall - strictly worse than a
        # merely-fragile lone weapon, so this tier ranks ABOVE lone_weapon.
        var cant_swing := cheapest > energy          # cheapest == -1 (no weapon) can never trip this
        if cant_swing:
            _set_note("Ready to bind, but it can not swing: its cheapest weapon costs ✦%d mana and it can only hold ✦%d." % [cheapest, energy], Tokens.STRAIN_TEXT)
        elif w > cap and lone_weapon:
            _set_note("Ready to bind, but fragile: one weapon, and strained (SPD -%d). Lose that arm and it is defanged." % (w - cap), Tokens.STRAIN_TEXT)
        elif w > cap:
            _set_note("Ready to bind (strained: SPD -%d)." % (w - cap), Tokens.STRAIN_TEXT)
        elif lone_weapon:
            _set_note("Ready to bind, but fragile: it has only one weapon - lose that arm and it is defanged.", Tokens.STRAIN_TEXT)
        elif empties > 0:
            # honest partial-build read (owner call 2026-07-19): binding is legal, but never
            # an unqualified "ready" while sockets gape
            _set_note("Ready to bind - %d socket%s still empty." % [empties, "" if empties == 1 else "s"], Tokens.VALID_TEXT)
        else:
            _set_note("Ready to bind.", Tokens.VALID_TEXT)
    elif session.manabit.core() == null:
        if _tag_alive():
            _set_note("", Tokens.LAMP_KEY)   # one-voice rule: the tag carries the journey line
        elif _spare_core_owned():
            # spare-core fix (calm 7.2): never point a maker at spending ⚙60 they do not
            # need - tapping filters the drawer to CORE instead of opening the Binding
            _set_note("Seat a mana core to wake it - one waits in your drawer.", Tokens.LAMP_KEY, NoteAct.FILTER_CORE)
        else:
            # tappable: the note itself opens the Binding overlay at the exact failure moment
            _set_note("Seat a mana core to wake it - tap here to bind one (⚙%d)." % PlayerState.BIND_CORE_COST, Tokens.LAMP_KEY, NoteAct.BINDING)
    elif not session.manabit.has_offensive_move():
        if _tag_alive():
            _set_note("", Tokens.LAMP_KEY)   # one-voice rule: the tag carries the journey line
        else:
            _set_note("Bind a weapon to an arm - your Manabit needs a way to fight.", Tokens.LAMP_KEY)
    else:
        _set_note(session.deploy_block_reason(), Tokens.LAMP_KEY)

# D3 fragility cue: how many seated bits can actually deal damage (SINGLE/MULTI). At exactly one,
# the build passes is_deployable() but a single broken arm makes has_offensive_move() false ->
# SURVIVABLE_LOSS with no other warning (combat.gd:172). Read-only; mirrors the resolver's notion.
func _offensive_count() -> int:
    var n := 0
    for s in ManabitState.SLOT_NAMES:
        var pi = session.manabit.slots.get(s)
        if pi == null or pi.disabled or pi.data.ability == null:
            continue
        var arch := String(pi.data.ability.archetype)
        if arch == "SINGLE" or arch == "MULTI":
            n += 1
    return n

# Stalemate nudge (design/balance/stalemate-breaker.md sec 6): the cheapest SINGLE/MULTI mana_cost
# among seated, enabled, ability-bearing bits, or -1 if none. If this exceeds derived().energy the
# weapon can NEVER be afforded (start_fight seats mana at energy, begin_turn caps regen at energy),
# so the build can only GUARD - a guaranteed mutual-GUARD stall. Read-only; mirrors the resolver.
func _min_attack_cost() -> int:
    var best := -1
    for s in ManabitState.SLOT_NAMES:
        var pi = session.manabit.slots.get(s)
        if pi == null or pi.disabled or pi.data.ability == null:
            continue
        var arch := String(pi.data.ability.archetype)
        if arch == "SINGLE" or arch == "MULTI":
            var cost := int(pi.data.ability.mana_cost)
            if best == -1 or cost < best:
                best = cost
    return best

# "Spare core" = a bindable core sitting unequipped in player.bits. slot_accepts is the
# ONLY predicate (never a parallel rule).
func _spare_core_owned() -> bool:
    for pi in session.inventory:
        if session.slot_accepts("CORE", pi):
            return true
    return false

func _on_equip_requested(slot_name: String, pi: PartInstance) -> void:
    session.equip(slot_name, pi)
    _snap(slot_name)
    selected_card = null
    refresh_from_player()

func _on_slot_tapped(slot_name: String) -> void:
    if selected_card != null:
        if session.slot_accepts(slot_name, selected_card.pi):
            session.equip(slot_name, selected_card.pi)
            _snap(slot_name)
            selected_card = null
            refresh_from_player()
        else:
            slot_fields[slot_name].play_reject()
        return
    var key := _chip_key_for(slot_name)
    var pi: PartInstance = session.manabit.slots.get(slot_name)
    # Audio wave 4a: the medallion tap itself (filter/focus contract). The place-a-selected-
    # card path above returns before here, so this never doubles the snap or reject beat.
    Sfx.play(&"medallion_tap")
    # Calm 2.3.2: a socket tap runs the tap contract EXACTLY as before, and ensures the
    # drawer is open first so the filter result is always visible. Tap-again-clear keeps
    # the drawer open.
    _set_drawer(true)
    if pi != null:
        # Unequip AND focus the freed socket's fits, so you can immediately reslot/swap.
        session.unequip(slot_name)
        _filter_slot = key
        refresh_from_player()
        _maybe_nudge()
    else:
        # Empty socket: tap = filter the tray to bits that fit here; tap again = clear.
        var was := _filter_slot
        _filter_slot = "" if _filter_slot == key else key
        _refresh_tray()
        if _filter_slot != "" and _filter_slot != was:
            _maybe_nudge()

func _on_card_selected(card: PartCard) -> void:
    if selected_card != null and is_instance_valid(selected_card) and selected_card != card:
        selected_card.set_selected(false)   # one tap-place ring at a time
    selected_card = card
    card.set_selected(true)
    for sname in slot_fields:
        slot_fields[sname].set_eligibility(true, session.slot_accepts(sname, card.pi))
    _refresh_calm()                  # tap-place in flight = the anatomy legend applies

func _on_card_activated(card: PartCard) -> void:
    # Double-click / double-tap a tray card = attach it to the best fitting socket (empty
    # first, else swap the occupant back to the tray), reusing the exact equip + snap path
    # as drag-drop and tap-place. Owner ask 2026-07-20.
    if card == null or not is_instance_valid(card) or card.pi == null:
        return
    var slot := _first_fit_slot(card.pi)
    if slot == "":
        return                       # nothing fits (never happens for a real tray bit)
    _card_press = null               # a double-click attaches; it is never an inspect hold
    session.equip(slot, card.pi)
    _snap(slot)                      # identical seat juice + rarity-pitch snap as drag/tap-place
    selected_card = null
    refresh_from_player()

func _on_card_drag_started(card: PartCard) -> void:
    _card_press = null               # a drag is a drag - it never becomes an inspect hold
    _dragging = true
    _update_tag_suppression()        # calm: the tag + invites yield while a bit is in hand
    _refresh_calm()
    for sname in slot_fields:
        slot_fields[sname].set_eligibility(true, session.slot_accepts(sname, card.pi))

func _on_card_drag_ended() -> void:
    _dragging = false
    _update_tag_suppression()
    _refresh_calm()
    for sname in slot_fields:
        slot_fields[sname].set_eligibility(false, false)

func _on_card_hover(pi: PartInstance) -> void:
    var target := _first_fit_slot(pi)
    if target != "":
        ledger.show_build(session, session.preview_derived_with(target, pi))
        # move 3: the toy is the link - the destination medallion warms, and if a bit is
        # mounted there (a swap) it rim-lights on the toy itself
        _hover_slot = target
        if slot_fields.has(target):
            slot_fields[target].set_warm(true)
        if session.manabit.slots.get(target) != null:
            stage.highlight_slot(target, true)

func _on_card_unhover() -> void:
    ledger.show_build(session)
    if _hover_slot != "":
        if slot_fields.has(_hover_slot):
            slot_fields[_hover_slot].set_warm(false)
        if session.manabit.slots.get(_hover_slot) != null:
            stage.highlight_slot(_hover_slot, false)
        _hover_slot = ""

func _on_socket_hovered(sname: String, on: bool) -> void:
    # move 3: hovering a medallion rim-lights that part on the toy (medallion warms itself)
    if session.manabit.slots.get(sname) != null:
        stage.highlight_slot(sname, on)

func _first_fit_slot(pi: PartInstance) -> String:
    for sname in ManabitState.SLOT_NAMES:
        if session.manabit.slots.get(sname) == null and session.slot_accepts(sname, pi):
            return sname
    for sname2 in ManabitState.SLOT_NAMES:
        if session.slot_accepts(sname2, pi):
            return sname2
    return ""

func _on_bank() -> void:
    if not session.is_deployable():
        return
    Sfx.play(&"bind_press")               # the wax press lands (inventory group 4: one thunk)
    var nm := _name_edit.text
    player.bank_manabit(nm, session.manabit)   # increments binds_total - unties the tag forever
    player.save()
    session.clear()                       # bits consumed into the bound Manabit
    selected_card = null
    refresh_from_player()
    _set_drawer(false)                    # calm 2.4.4: the drawer tucks itself, the toy celebrates alone
    _set_note("BOUND!  \"%s\" joins your Menagerie." % nm, Tokens.BRASS_HI)
    Sfx.play(&"bound_chord")              # the hero owns this beat - the BOUND! toast stays silent
    _toast("✦ BOUND! ✦")

# For the screenshot harness.
func debug_bind() -> void:
    if session.is_deployable():
        _on_bank()

func _on_spar() -> void:
    if session.is_deployable():
        spar_requested.emit(session.manabit)
    else:
        # Owner call 2026-07-18: never start a fight the player did not build. Refuse like
        # Bout/Venture do; the note + tag point at the next step. (Box practice lives in the
        # Box of Scrap flow itself, not behind a silent substitute.)
        _refresh_bank()   # shows the ratified block copy (tappable bind-note on no-core)

func _on_bout() -> void:
    if session.is_deployable():
        open_proving_requested.emit()
    else:
        _refresh_bank()   # shows the ratified block copy (tappable bind-note on no-core)

func _on_venture() -> void:
    if session.is_deployable():
        venture_requested.emit(_name_edit.text)
    else:
        _refresh_bank()   # shows the ratified block copy (tappable bind-note on no-core)

func clear_build() -> void:
    session.clear()
    selected_card = null
    refresh_from_player()

# --- THE BOX OF SCRAP - crack-and-see: preview the rolled box, then take it out or leave it ---
var _box_panel: Control = null

func _open_box_reveal() -> void:
    # An open inspect holds _stage_area at z_index 40 - it would draw the bench toy OVER
    # this whole overlay (owner-hit 2026-07-19: invisible reveal, blind commit). Close first.
    _close_inspect()
    if _box_panel != null and is_instance_valid(_box_panel):
        _box_panel.queue_free()
    var seed := player.kit_box_seed()          # SAME seed root will commit - the reveal never lies
    var box := BoxRoller.roll(seed)
    var grade := BoxRoller.grade(seed)
    # Audio wave 4a: the crate cracks, then the grade ribbon reads out. grade_reveal rides
    # the inventory's wood-first ladder - Dud/Keen are pitch offsets (-2/+2 st) on it.
    Sfx.play(&"box_crack")
    var grade_pitch := 1.0
    match grade:
        "Dud":
            grade_pitch = 0.8909
        "Keen":
            grade_pitch = 1.1225
    Sfx.play(&"grade_reveal", grade_pitch)
    _box_panel = Control.new()
    _box_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(_box_panel)
    var dim := ColorRect.new()
    dim.color = Color(0.12, 0.08, 0.05, 0.5)   # walnut tint, never pure black (warm material pass)
    dim.set_anchors_preset(Control.PRESET_FULL_RECT)
    dim.gui_input.connect(func(e): if e is InputEventMouseButton and e.pressed: _close_box_reveal())
    _box_panel.add_child(dim)
    var center := CenterContainer.new()
    center.set_anchors_preset(Control.PRESET_FULL_RECT)
    center.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _box_panel.add_child(center)
    var panel := PanelContainer.new()
    var sb := Tokens.sandwich("deep")            # material sandwich; the crate's grade is its frame
    sb.set_border_width_all(3)
    sb.border_color = _grade_color(grade)
    sb.content_margin_left = 20
    sb.content_margin_right = 20
    sb.content_margin_top = 16
    sb.content_margin_bottom = 16
    panel.add_theme_stylebox_override("panel", sb)
    panel.custom_minimum_size = Vector2(460, 0)
    center.add_child(panel)
    var v := VBoxContainer.new()
    v.add_theme_constant_override("separation", 8)
    panel.add_child(v)
    var title := Label.new()
    title.text = "A BOX OF SCRAP"
    title.add_theme_color_override("font_color", Tokens.BRASS_HI)
    Tokens.display(title, 18)
    _shade(title)
    v.add_child(title)
    # The grade ribbon - the sliding-scale readout.
    var ribbon := Label.new()
    ribbon.text = "◆  %s  ◆" % grade.to_upper()
    ribbon.add_theme_color_override("font_color", _grade_color(grade))
    Tokens.display(ribbon, 26)
    _shade(ribbon)
    v.add_child(ribbon)
    # Assembled stat sheet - a stronger box literally shows a bigger sheet.
    var d := box.derived()
    var sheet := Label.new()
    sheet.text = "ATK %d   DEF %d   SPD %d   MANA %d   HP %d" % [int(d.attack), int(d.defense), int(d.speed), int(d.energy), box.core().data.max_hp]
    sheet.add_theme_color_override("font_color", Tokens.PARCHMENT)
    sheet.add_theme_font_size_override("font_size", 15)
    v.add_child(sheet)
    # What tumbled out.
    for slot in ManabitState.SLOT_NAMES:
        var pi: PartInstance = box.slots.get(slot)
        if pi == null:
            continue
        var row := Label.new()
        var acc := Tokens.rarity_frame(pi.data.rarity)
        row.text = "   %s  %s   ·   %s" % [Tokens.slot_glyph(slot), pi.data.display_name, pi.data.rarity.capitalize()]
        row.add_theme_color_override("font_color", acc)
        row.add_theme_font_size_override("font_size", 12)
        v.add_child(row)
    var verdict := Label.new()
    verdict.text = _box_verdict(grade)
    verdict.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    verdict.custom_minimum_size = Vector2(420, 0)
    verdict.add_theme_color_override("font_color", Tokens.LAMP_KEY)
    verdict.add_theme_font_size_override("font_size", 13)
    v.add_child(verdict)
    var row2 := HBoxContainer.new()
    row2.add_theme_constant_override("separation", 12)
    v.add_child(row2)
    var take := Button.new()
    take.text = "Take it out  ▸"
    Tokens.brass_button(take)
    Tokens.pad_target(take)
    take.pressed.connect(func(): _close_box_reveal(); kit_venture_requested.emit())
    row2.add_child(take)
    var leave := Button.new()
    leave.text = "Leave it on the bench"
    Tokens.pad_target(leave)
    leave.pressed.connect(_close_box_reveal)
    row2.add_child(leave)
    _update_tag_suppression()             # calm: the tag + invites yield to the overlay

func _close_box_reveal() -> void:
    if _box_panel != null and is_instance_valid(_box_panel):
        _box_panel.queue_free()
    _box_panel = null
    _update_tag_suppression()

func _grade_color(grade: String) -> Color:
    match grade:
        "Gleaming": return Tokens.RUNEWOOD
        "Keen": return Tokens.COBALT
        "Fair": return Tokens.BRASS_HI
        "Rough": return Tokens.BRASS
        _: return Tokens.TIN

func _box_verdict(grade: String) -> String:
    match grade:
        "Gleaming", "Keen":
            return "Ohh - now that's a kind box. Bolt that together and you'll give even old Brassmore a fright."
        "Fair":
            return "Fair enough scrap. It'll fight. The rest is up to your hands."
        _:
            return "Slim pickings today, young maker. Run it if you're feeling lucky - but this one might get you got."

# --- THE BINDING - craft a fresh COMMON soul at your own bench (hold to bind, like the Waking) ---
var _binding_panel: Control = null
var _binding_note: Label = null
var _bind_ring: ChargeRing = null
var _bind_target := ""            # core id being held
var _bind_charge := 0.0

func _toggle_binding_panel() -> void:
    if _binding_panel != null and is_instance_valid(_binding_panel):
        _binding_panel.queue_free()
        _binding_panel = null
        _bind_target = ""
        _update_tag_suppression()
        return
    _close_inspect()   # a held inspect (stage z 40) would draw the toy over this overlay
    _binding_panel = Control.new()
    _binding_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(_binding_panel)
    var dim := ColorRect.new()
    dim.color = Color(0.12, 0.08, 0.05, 0.5)   # walnut tint, never pure black (warm material pass)
    dim.set_anchors_preset(Control.PRESET_FULL_RECT)
    dim.gui_input.connect(func(e): if e is InputEventMouseButton and e.pressed: _toggle_binding_panel())
    _binding_panel.add_child(dim)
    var center := CenterContainer.new()
    center.set_anchors_preset(Control.PRESET_FULL_RECT)
    center.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _binding_panel.add_child(center)
    var panel := PanelContainer.new()
    var sb := Tokens.sandwich("deep")            # material sandwich (brass accent = the border)
    sb.border_color = Tokens.BRASS
    sb.content_margin_left = 18
    sb.content_margin_right = 18
    sb.content_margin_top = 14
    sb.content_margin_bottom = 14
    panel.add_theme_stylebox_override("panel", sb)
    center.add_child(panel)
    var v := VBoxContainer.new()
    v.add_theme_constant_override("separation", 8)
    panel.add_child(v)
    var title := Label.new()
    title.text = "THE BINDING"
    title.add_theme_color_override("font_color", Tokens.BRASS_HI)
    Tokens.display(title, 18)
    _shade(title)
    v.add_child(title)
    var blurb := Label.new()
    blurb.text = "A core is a soul, and souls aren't sold - you bind your own.\nA stronger soul wakes a heavier body.\nPress and HOLD an affinity to bind it.  ⚙%d" % PlayerState.BIND_CORE_COST
    blurb.add_theme_font_size_override("font_size", 12)
    blurb.add_theme_color_override("font_color", Color(Tokens.PARCHMENT, 0.8))
    v.add_child(blurb)
    var choices := [
        ["core_ember",   "❖  Ember - quick to spark", Tokens.AFF_ATTACK],
        ["core_bulwark", "❖  Bulwark - stubborn as a door - carries +6", Tokens.AFF_DEFENSE],
        ["core_font",    "❖  Font - deep and slow", Tokens.AFF_MANA],
    ]
    for c in choices:
        var b := Button.new()
        b.text = String(c[1])
        b.add_theme_color_override("font_color", c[2])
        Tokens.pad_target(b)
        b.button_down.connect(_bind_down.bind(String(c[0])))
        b.button_up.connect(_bind_up)
        v.add_child(b)
    var noterow := HBoxContainer.new()
    noterow.add_theme_constant_override("separation", 8)
    v.add_child(noterow)
    _bind_ring = ChargeRing.new()
    _bind_ring.custom_minimum_size = Vector2(36, 36)
    noterow.add_child(_bind_ring)
    _binding_note = Label.new()
    _binding_note.add_theme_font_size_override("font_size", 12)
    _binding_note.add_theme_color_override("font_color", Tokens.LAMP_KEY)
    _binding_note.text = "You carry ⚙%d." % player.scrap
    noterow.add_child(_binding_note)
    _update_tag_suppression()             # calm: the tag + invites yield to the overlay

func _bind_down(core_id: String) -> void:
    if player.scrap < PlayerState.BIND_CORE_COST:
        _binding_note.text = "A few filings short, maker - crack a Box of Scrap; it gathers."
        return
    _bind_target = core_id
    _bind_charge = 0.0
    set_process(true)

func _bind_up() -> void:
    _bind_target = ""
    _bind_charge = 0.0
    if _bind_ring != null and is_instance_valid(_bind_ring):
        _bind_ring.progress = 0.0

func _process(delta: float) -> void:
    # Three things share this tick: the Binding charge (unchanged math), the move-10 long-press
    # on a tray card, and the seated-core hum's breath AM. Processing stops when none is live.
    var busy := false
    if _soul_hum_on and not Juice.reduce_motion:
        busy = true   # keep ticking through the fade-in; apply the sway once it settles
        if Time.get_ticks_msec() - _soul_hum_since >= SOUL_HUM_AM_DELAY_MS:
            _breathe_soul_hum()
    if _bind_target != "":
        busy = true
        _bind_charge = minf(1.0, _bind_charge + delta / 0.8)
        if _bind_ring != null and is_instance_valid(_bind_ring):
            _bind_ring.progress = _bind_charge
        if _bind_charge >= 1.0:
            var id := _bind_target
            _bind_target = ""
            _do_bind(id)
    if _card_press != null:
        if is_instance_valid(_card_press):
            busy = true
            _card_press_t += delta
            if _card_press_t >= 0.45:
                var c := _card_press
                _card_press = null
                _open_inspect(c.pi, c.get_global_position() + Vector2(c.size.x * 0.5, 0.0), "")
        else:
            _card_press = null
    if not busy:
        set_process(false)

func _do_bind(core_id: String) -> void:
    if not player.bind_core(core_id):
        return
    player.save()
    Sfx.play(&"core_wake")
    _toggle_binding_panel()               # close the panel
    refresh_from_player()
    # Calm 2.3.4: Binding success auto-opens the drawer filtered to CORE - the new core is
    # the first card, one drag from the socket that needs it.
    _focus_slot_in_tray("CORE")
    _set_note("A new soul hums on your bench.", Tokens.BRASS_HI)
    Sfx.play(&"toast_pin")               # non-hero beat gets the paper pin; BOUND!/EPIC!
    _toast("❖ A new soul hums.")         # toasts stay silent - the chord IS the toast

# --- MOVE 10: dim-and-focus inspect - the informational job the old plates carried ------
# Long-press a FILLED medallion or a tray card: the room dims ~60% warm (never black),
# the toy leans toward camera, and 2-4 parchment chips tell the bit's story. Tap away to
# dismiss. No flashes - the dim is a single soft tween under the photosensitivity caps.
var _card_press: PartCard = null
var _card_press_t := 0.0
var _inspect_panel: Control = null
var _inspect_slot := ""

func _on_card_gui(event: InputEvent, card: PartCard) -> void:
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed:
            if event.double_click:
                _card_press = null       # double-click attaches (activated); never an inspect hold
                return
            _card_press = card
            _card_press_t = 0.0
            set_process(true)
        else:
            _card_press = null

func _on_slot_inspect(sname: String) -> void:
    var pi: PartInstance = session.manabit.slots.get(sname)
    if pi == null:
        return
    var sf: SlotField = slot_fields[sname]
    _open_inspect(pi, sf.get_global_position() + sf.size * 0.5, sname)

func _open_inspect(pi: PartInstance, at_global: Vector2, sname: String) -> void:
    _close_inspect()
    Sfx.play(&"inspect_open")            # paper lift + one soft bell tick (audio wave 4a)
    _inspect_slot = sname
    _inspect_panel = Control.new()
    _inspect_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
    _inspect_panel.z_index = 30
    add_child(_inspect_panel)
    var dim := ColorRect.new()
    dim.color = Color(0.23, 0.14, 0.08, 0.6)   # warm walnut dim, never black
    dim.set_anchors_preset(Control.PRESET_FULL_RECT)
    dim.gui_input.connect(func(e): if e is InputEventMouseButton and e.pressed: _close_inspect())
    _inspect_panel.add_child(dim)
    if not Juice.reduce_motion:
        dim.modulate.a = 0.0
        dim.create_tween().tween_property(dim, "modulate:a", 1.0, 0.16)
    if sname != "":
        # the toy stays lit above the dim and leans toward camera; its part keeps the rim
        _stage_area.z_index = 40
        _stage_area.pivot_offset = _stage_area.size * 0.5
        if Juice.reduce_motion:
            _stage_area.scale = Vector2(1.06, 1.06)
        else:
            create_tween().tween_property(_stage_area, "scale", Vector2(1.06, 1.06), 0.18) \
                .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
        stage.highlight_slot(sname, true)
    var chips: Array = []
    chips.append(_chip_title(pi, sname))
    chips.append(_chip_stats(pi))
    var ab := _chip_ability(pi)
    if ab != null:
        chips.append(ab)
    chips.append(_chip_flavor(pi))
    var local := at_global - global_position
    var x := clampf(local.x + 56.0, 12.0, size.x - 252.0)
    var upward := local.y > size.y * 0.55
    var y := local.y - 10.0 if upward else local.y + 10.0
    var idx := 0
    for ch in chips:
        _inspect_panel.add_child(ch)
        var csz: Vector2 = ch.get_combined_minimum_size()
        if upward:
            y -= csz.y + 8.0
            ch.position = Vector2(x + float((idx % 2) * 12 - 6), y)
        else:
            ch.position = Vector2(x + float((idx % 2) * 12 - 6), y)
            y += csz.y + 8.0
        ch.pivot_offset = csz * 0.5
        ch.rotation_degrees = -1.2 if idx % 2 == 0 else 1.0   # resting on the bench, not ruled
        if not Juice.reduce_motion:
            ch.modulate.a = 0.0
            ch.create_tween().tween_property(ch, "modulate:a", 1.0, 0.14).set_delay(0.04 * idx)
        idx += 1
    _update_tag_suppression()             # calm: the tag + invites yield to the inspect dim

func _close_inspect() -> void:
    if _inspect_panel != null and is_instance_valid(_inspect_panel):
        Sfx.play(&"inspect_close")       # only when an inspect was actually up (this is a
        _inspect_panel.queue_free()      # shared cleanup path - no phantom paper settles)
    _inspect_panel = null
    if _inspect_slot != "":
        if session.manabit.slots.get(_inspect_slot) != null:
            stage.highlight_slot(_inspect_slot, false)
        _inspect_slot = ""
    if _stage_area != null:
        _stage_area.z_index = 0
        if Juice.reduce_motion:
            _stage_area.scale = Vector2.ONE
        else:
            create_tween().tween_property(_stage_area, "scale", Vector2.ONE, 0.14) \
                .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    _update_tag_suppression()

func _inspect_chip() -> PanelContainer:
    var p := PanelContainer.new()
    var sb := Tokens.sandwich("parchment")
    sb.content_margin_top = 8
    sb.content_margin_bottom = 8
    p.add_theme_stylebox_override("panel", sb)
    p.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return p

func _chip_title(pi: PartInstance, sname: String = "") -> PanelContainer:
    var p := _inspect_chip()
    var v := VBoxContainer.new()
    v.add_theme_constant_override("separation", 1)
    p.add_child(v)
    var nm := Label.new()
    nm.text = pi.data.display_name
    Tokens.display(nm, 15)
    nm.add_theme_color_override("font_color", Tokens.BENCH_LO)   # ink on parchment
    v.add_child(nm)
    var sub := Label.new()
    # the socket it is MOUNTED on when inspected from the rail; its authored slot otherwise
    sub.text = ("%s · %s" % [pi.data.rarity.capitalize(), Tokens.slot_word(sname if sname != "" else pi.data.slot)]).to_upper()
    sub.add_theme_font_size_override("font_size", 9)
    sub.add_theme_color_override("font_color", Color(Tokens.BENCH_WALNUT, 0.95))
    v.add_child(sub)
    return p

func _chip_stats(pi: PartInstance) -> PanelContainer:
    # every number the bit carries, as colored capsules in the locked stat hues -
    # words + numbers, never letter-code soup (color economy RULE)
    var p := _inspect_chip()
    p.custom_minimum_size = Vector2(228, 0)
    var flow := HFlowContainer.new()
    flow.add_theme_constant_override("h_separation", 4)
    flow.add_theme_constant_override("v_separation", 4)
    p.add_child(flow)
    var d := pi.data
    if d.attack > 0:
        flow.add_child(_stat_pill("Attack %d" % d.attack, Tokens.STAT_ATK))
    if d.defense > 0:
        flow.add_child(_stat_pill("Defense %d" % d.defense, Tokens.STAT_DEF))
    if d.speed > 0:
        flow.add_child(_stat_pill("Speed %d" % d.speed, Tokens.STAT_SPD))
    flow.add_child(_stat_pill("Weighs %d" % d.weight, Tokens.STAT_WEIGHT))
    if d.is_core and d.energy > 0:
        flow.add_child(_stat_pill("Mana %d" % d.energy, Tokens.STAT_ENERGY))
    if d.is_core and d.carry > 0:
        flow.add_child(_stat_pill("Carry +%d" % d.carry, Tokens.STAT_WEIGHT))
    if pi.current_hp < d.max_hp:
        flow.add_child(_stat_pill("✖ %d/%d" % [pi.current_hp, d.max_hp], Tokens.DELTA_NEG))
    return p

func _stat_pill(txt: String, fill: Color) -> Label:
    var l := Label.new()
    l.text = txt
    l.add_theme_font_size_override("font_size", 11)
    l.add_theme_color_override("font_color", Tokens.BENCH_LO)
    var sb := StyleBoxFlat.new()
    sb.bg_color = fill
    sb.set_corner_radius_all(9)
    sb.content_margin_left = 7
    sb.content_margin_right = 7
    sb.content_margin_top = 2
    sb.content_margin_bottom = 2
    l.add_theme_stylebox_override("normal", sb)
    return l

func _chip_ability(pi: PartInstance) -> PanelContainer:
    if pi.data.ability == null:
        return null
    var p := _inspect_chip()
    var l := Label.new()
    match String(pi.data.ability.archetype):
        "MULTI": l.text = "Fights in a flurry of strikes"
        "GUARD": l.text = "Stands its guard for the others"
        _:       l.text = "Strikes single and true"
    l.add_theme_font_size_override("font_size", 11)
    l.add_theme_color_override("font_color", Tokens.BENCH_LO)
    p.add_child(l)
    return p

func _chip_flavor(pi: PartInstance) -> PanelContainer:
    var p := _inspect_chip()
    var l := Label.new()
    match pi.data.slot:
        "HEAD":  l.text = "Keeps the wits bolted on tight."
        "CORE":  l.text = "A soul hums in there - mind it."
        "LEGS":  l.text = "Carries the whole argument home."
        "BACK":  l.text = "Strapped on snug. It holds fast."
        _:       l.text = "Does the talking when words run out."
    l.add_theme_font_size_override("font_size", 11)
    l.add_theme_color_override("font_color", Color(Tokens.BENCH_WALNUT, 0.95))
    p.add_child(l)
    return p

# --- calm rules: instrument visibility + nameplate swap (calm spec section 6) -----------

func _seated_count() -> int:
    var n := 0
    for sname in ManabitState.SLOT_NAMES:
        if session.manabit.slots.get(sname) != null:
            n += 1
    return n

func _refresh_calm() -> void:
    if ledger == null:
        return
    # The Ledger + Balance panel is visible iff (any bit seated) OR (drawer open). Built
    # toy at rest keeps its spec card (the theorycraft pillar); an empty bench at rest
    # shows no dead instruments - the stage takes the full mid-row width.
    var show_ledger := _seated_count() > 0 or _drawer_open
    if ledger.visible != show_ledger:
        ledger.visible = show_ledger
        if show_ledger and not Juice.reduce_motion:
            ledger.modulate.a = 0.0
            ledger.create_tween().tween_property(ledger, "modulate:a", 1.0, 0.16)
        else:
            ledger.modulate.a = 1.0
    # The anatomy inset is the drag legend - work-mode chrome only.
    if _rig != null:
        _rig.set_work_mode(_drawer_open or _dragging or selected_card != null)

func _on_name_plate_tapped() -> void:
    _name_plate.visible = false
    _name_edit.visible = true
    _name_edit.grab_focus()
    _name_edit.caret_column = _name_edit.text.length()

func _commit_name() -> void:
    if not _name_edit.visible:
        return
    _name_edit.visible = false
    _name_plate.text = _name_edit.text
    _name_plate.visible = true

# --- the Work-Order Tag machine (calm spec section 3) -----------------------------------

func _overlay_up() -> bool:
    return (_binding_panel != null and is_instance_valid(_binding_panel)) \
        or (_box_panel != null and is_instance_valid(_box_panel)) \
        or (_inspect_panel != null and is_instance_valid(_inspect_panel))

func _tag_alive() -> bool:
    return player.binds_total == 0 and _tag_state != 0

# T1-T6, first match wins, exactly ONE state alive - derived purely from live save/build
# state (never a tutorial flag). Evaluated on every refresh_from_player.
func _tag_compute_state() -> int:
    if player.binds_total > 0:
        return 0
    if _seated_count() == 0:
        if _spare_core_owned():
            return 1
        if player.scrap >= PlayerState.BIND_CORE_COST:
            return 2
        if player.coffer_count() > 0:
            return 3
        return 4
    if session.manabit.core() != null and not session.manabit.has_offensive_move():
        return 5
    if session.is_deployable():
        # Owner call 2026-07-19: "She's ready" only when she IS - a deployable build with
        # empty sockets is honest about it. T7 points at the first fillable empty socket
        # (body order, slot_accepts the only predicate); T8 = deployable, sockets empty,
        # nothing owned fits them - press on with what you have.
        var empties := 0
        _tag_slot = ""
        for s in ManabitState.SLOT_NAMES:
            if session.manabit.slots.get(s) == null:
                empties += 1
                if _tag_slot == "":
                    for pi in session.inventory:
                        if session.slot_accepts(s, pi):
                            _tag_slot = s
                            break
        if empties == 0:
            return 6
        if _tag_slot != "":
            return 7
        return 8
    return 0

func _refresh_tag() -> void:
    if _tag == null:
        return
    var prev := _tag_state
    _tag_state = _tag_compute_state()
    if _tag_state != 6 and _tag_state != 8:
        _t6_sheened = false          # the T6/T8 sheen re-arms on every fresh state entry
    if _tag_state == 0:
        if prev != 0 and player.binds_total > 0 and not _tag_gone:
            _play_tag_untie()        # the first BOUND!: untie-and-slide-off, forever
        else:
            _tag.visible = false
        _apply_invites()
        return
    _tag.visible = not _overlay_up() and not _dragging
    _tag.modulate.a = 1.0
    if prev != _tag_state or (_tag_state == 7 and _tag_slot != _tag_slot_shown):
        var story: String = TAG_COPY[_tag_state][0]
        var act: String = TAG_COPY[_tag_state][1]
        if _tag_state == 7:
            act = act % Tokens.slot_word(_tag_slot).to_lower()
        _tag.set_copy(story, act, prev != 0 and _tag.visible)
        _tag_slot_shown = _tag_slot
    _apply_invites()

# At most ONE medallion invite at any time, chosen by the tag state; suppressed (with the
# tag) while a drag / inspect / overlay is live. Owned centrally - widgets are never
# trusted to self-coordinate. The dormant heartbeat runs only for T1/T2.
func _apply_invites() -> void:
    var invite := ""
    if _tag_alive() and not _overlay_up() and not _dragging:
        if _tag_state == 1 or _tag_state == 2:
            invite = "CORE"
        elif _tag_state == 5:
            invite = "ARM_L"
        elif _tag_state == 7:
            invite = _tag_slot
    for sname in slot_fields:
        slot_fields[sname].set_invite(sname == invite)
    stage.set_dormant_pulse(invite == "CORE")

# 120ms modulate fade out/in around overlays and drags (calm 3: existence rule).
func _update_tag_suppression() -> void:
    _apply_invites()
    if _tag == null or not _tag_alive() or _tag_gone:
        return
    var show := not _overlay_up() and not _dragging
    if _tag.visible == show:
        return
    if Juice.reduce_motion:
        _tag.visible = show
        _tag.modulate.a = 1.0
        return
    if show:
        _tag.visible = true
        _tag.modulate.a = 0.0
        _tag.create_tween().tween_property(_tag, "modulate:a", 1.0, 0.12)
    else:
        var tw := _tag.create_tween()
        tw.tween_property(_tag, "modulate:a", 0.0, 0.12)
        tw.tween_callback(_finish_tag_fade_out)

func _finish_tag_fade_out() -> void:
    if _tag != null and (_overlay_up() or _dragging):
        _tag.visible = false
        _tag.modulate.a = 1.0

func _on_tag_tapped() -> void:
    match _tag_state:
        1:
            # taught by doing: the tag tap literally performs the socket tap - the player
            # watches the medallion light and the drawer open filtered (calm 3.4)
            if _filter_slot == "CORE":
                _set_drawer(true)
            else:
                _on_slot_tapped("CORE")
        2:
            _toggle_binding_panel()
        3:
            open_chests_requested.emit()
        4:
            _open_box_reveal()
        5:
            _focus_slot_in_tray("ARMS")
        6:
            _sheen_bind_plate()      # the tag never binds for you
        7:
            match _tag_slot:
                "ARM_L", "ARM_R":
                    _focus_slot_in_tray("ARMS")
                "HEAD", "CORE", "LEGS", "BACK":
                    _focus_slot_in_tray(_tag_slot)
        8:
            _sheen_bind_plate()      # press on with what you have

func _sheen_bind_plate() -> void:
    # One 600ms warm sheen on the BIND brass plate - celebration register, once per T6
    # entry. Reduce-motion: no motion (the note already reads Ready to bind).
    if _t6_sheened:
        return
    _t6_sheened = true
    if Juice.reduce_motion:
        return
    var f := Panel.new()
    var sb := StyleBoxFlat.new()
    sb.bg_color = Color(Tokens.LAMP_KEY, 0.30)
    sb.set_corner_radius_all(Tokens.RADIUS_CARD)
    sb.set_border_width_all(2)
    sb.border_color = Tokens.BRASS_HI
    f.add_theme_stylebox_override("panel", sb)
    f.set_anchors_preset(Control.PRESET_FULL_RECT)
    f.mouse_filter = Control.MOUSE_FILTER_IGNORE
    f.modulate.a = 0.0
    _bank_btn.add_child(f)
    var tw := f.create_tween()
    tw.tween_property(f, "modulate:a", 1.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    tw.tween_property(f, "modulate:a", 0.0, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
    tw.tween_callback(f.queue_free)

func _play_tag_untie() -> void:
    # The one-time untie-and-slide-off (400ms). It never returns: binds_total > 0 gates
    # every future evaluation; _tag_gone guards the animation itself.
    _tag_gone = true
    Sfx.play(&"tag_untie")               # one ceremonial play per save, ever - sound is not
                                         # motion, so it fires under reduce-motion too
    if _tag == null or not _tag.visible:
        if _tag != null:
            _tag.visible = false
        return
    if Juice.reduce_motion:
        _tag.visible = false
        return
    var tw := _tag.create_tween()
    tw.set_parallel(true)
    tw.tween_property(_tag, "position:y", _tag.position.y + 90.0, 0.4) \
        .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
    tw.tween_property(_tag, "rotation_degrees", 16.0, 0.4)
    tw.tween_property(_tag, "modulate:a", 0.0, 0.4)
    tw.chain().tween_callback(_finish_tag_untie)

func _finish_tag_untie() -> void:
    if _tag != null:
        _tag.visible = false
        _tag.modulate.a = 1.0
        _tag.rotation_degrees = -2.0

func _place_tag() -> void:
    # Bottom-left inside the stage area: x starts past the CORE medallion's right edge
    # (the medallion is centered ON the stand rect's left edge, so +48 clears its +44
    # half-width at every stage size - the smoke gate asserts the non-overlap).
    if _tag == null or _stage_area == null:
        return
    var fr := SocketRig.stand_rect(_stage_area.size)
    _tag.position = Vector2(fr.position.x + 48.0, fr.end.y - _tag.size.y - 10.0)

# The parchment swing-tag widget: two lines (story 14sp walnut ink, underlined 13sp
# action), one brass rivet, a drawn twine to the stand rim. One >=44px STOP tap target.
class WorkOrderTag extends Control:
    signal tapped
    var story := ""
    var action := ""
    var _card: StyleBoxFlat

    func _ready() -> void:
        custom_minimum_size = Vector2(200, 64)
        size = custom_minimum_size
        mouse_filter = Control.MOUSE_FILTER_STOP
        rotation_degrees = -2.0
        pivot_offset = Vector2(18.0, 12.0)   # swings from the rivet
        _card = Tokens.sandwich("parchment")

    func set_copy(s: String, a: String, wipe: bool) -> void:
        # --ink-wipe 250ms between states; reduce-motion: hard swap
        if wipe:
            Sfx.play(&"ink_wipe")        # the re-ink is the event, not the motion
        if wipe and not Juice.reduce_motion:
            var tw := create_tween()
            tw.tween_property(self, "modulate:a", 0.0, 0.125)
            tw.tween_callback(_swap.bind(s, a))
            tw.tween_property(self, "modulate:a", 1.0, 0.125)
        else:
            _swap(s, a)

    func _swap(s: String, a: String) -> void:
        story = s
        action = a
        queue_redraw()

    func _gui_input(event: InputEvent) -> void:
        if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
            tapped.emit()

    func _draw() -> void:
        # twine up-left to the stand's brass rim, drawn before the card so it tucks under
        draw_line(Vector2(18, 12), Vector2(-26, -20), Color(Tokens.BENCH_LO, 0.8), 2.0, true)
        _card.draw(get_canvas_item(), Rect2(Vector2.ZERO, size))
        draw_circle(Vector2(18, 12), 5.0, Tokens.BRASS)
        draw_circle(Vector2(18, 12), 2.0, Tokens.BENCH_LO)
        var df: Font = Tokens.display_font()
        if df == null:
            df = get_theme_default_font()
        draw_string(df, Vector2(14, 28), story, HORIZONTAL_ALIGNMENT_LEFT, size.x - 26, 14, Tokens.BENCH_LO)
        draw_string(df, Vector2(14, 49), action, HORIZONTAL_ALIGNMENT_LEFT, size.x - 26, 13, Tokens.BENCH_WALNUT)
        var aw: float = minf(df.get_string_size(action, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x, size.x - 26.0)
        draw_line(Vector2(14, 52), Vector2(14 + aw, 52), Color(Tokens.BENCH_WALNUT, 0.9), 1.0)

# The closed-lip face: brass bail handle + up-to-6 card-top spines peeking from behind the
# lip. Pure drawing - the lip Button underneath is the tap target. Open state draws nothing
# (the toolbar chips carry the lip).
class LipFace extends Control:
    var open := false
    var hover := false
    var spines: Array = []      # [[family Color, rarity-edge Color], ...] first 6 of the view

    func _ready() -> void:
        resized.connect(queue_redraw)

    func _draw() -> void:
        if open or size.x <= 0.0:
            return
        # spines: rounded card-top slivers standing in the drawer, right of the handle
        var count := spines.size()
        if count > 0:
            var sw := 22.0
            var gap := 6.0
            var x0: float = size.x - 16.0 - float(count) * (sw + gap)
            for i in count:
                var x := x0 + float(i) * (sw + gap)
                var sb := StyleBoxFlat.new()
                sb.bg_color = spines[i][0]
                sb.corner_radius_top_left = 5
                sb.corner_radius_top_right = 5
                sb.draw(get_canvas_item(), Rect2(x, 5.0, sw, 10.0))
                draw_line(Vector2(x + 2.0, 5.5), Vector2(x + sw - 2.0, 5.5), spines[i][1], 2.0)
        # the brass bail handle, centered; hover warms it BRASS_HI and lifts 2px
        # (reduce-motion kills the lift, keeps the warmth)
        var hc := Vector2(size.x * 0.5, 15.0)
        if hover and not Juice.reduce_motion:
            hc.y -= 2.0
        var hcol := Tokens.BRASS_HI if hover else Tokens.BRASS
        draw_rect(Rect2(hc.x - 22.0, hc.y - 3.0, 44.0, 6.0), Tokens.BRASS.darkened(0.25))
        draw_arc(hc + Vector2(0, 2.0), 15.0, 0.15, PI - 0.15, 24, hcol, 3.5, true)

# --- reskin helpers (moves 2, 7, 9, 12, 14) ---------------------------------------------

func _place_watermark() -> void:
    # move 12: the blueprint silhouette sits on the wall band right of the stand, where it
    # can actually be seen (the stage texture is opaque)
    if _warmth == null or _stage_area == null:
        return
    var fr := SocketRig.stand_rect(_stage_area.size)
    var origin := _stage_area.global_position - global_position
    var band_x := fr.end.x + SocketRig.MED * 0.5 + 6.0
    var band_w := _stage_area.size.x - band_x - 4.0
    if band_w < 60.0:
        _warmth.watermark_enabled = false
        return
    _warmth.watermark_enabled = true
    _warmth.watermark_rect = Rect2(origin + Vector2(band_x, 14.0), Vector2(band_w, _stage_area.size.y - 28.0))

func _shade(l: Label) -> Label:
    # move 14: display text always carries a 1-2px warm dark shade (never naked)
    l.add_theme_color_override("font_shadow_color", Color(Tokens.BENCH_LO, 0.55))
    l.add_theme_constant_override("shadow_offset_x", 0)
    l.add_theme_constant_override("shadow_offset_y", 2)
    return l

func _brass_plate(btn: Button) -> void:
    # move 7: the ONE hero action - a stamped brass plate (material sandwich, brass tier)
    var mk := func(fill: Color, border: Color) -> StyleBoxFlat:
        var sb := Tokens.sandwich("brass")
        sb.bg_color = fill
        sb.border_color = border
        sb.content_margin_left = 40   # clears the wax seal
        sb.content_margin_right = 14
        sb.content_margin_top = 6
        sb.content_margin_bottom = 6
        return sb
    btn.add_theme_stylebox_override("normal", mk.call(Tokens.BRASS, Tokens.BRASS_HI))
    btn.add_theme_stylebox_override("hover", mk.call(Tokens.BRASS.lightened(0.10), Tokens.GLOW_BASE))
    btn.add_theme_stylebox_override("pressed", mk.call(Tokens.BRASS.darkened(0.12), Tokens.BRASS_HI))
    btn.add_theme_stylebox_override("disabled", mk.call(Tokens.BRASS.darkened(0.38), Color(Tokens.BRASS, 0.45)))
    for st in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
        btn.add_theme_color_override(st, Tokens.BENCH_LO)
    btn.add_theme_color_override("font_disabled_color", Color(Tokens.BENCH_LO, 0.65))
    Tokens.display(btn, 15)

func _ink_link(btn: Button) -> void:
    # move 7: demoted actions become quiet ink-and-underline links - no competing plates
    var mk := func(under: Color) -> StyleBoxFlat:
        var sb := StyleBoxFlat.new()
        sb.bg_color = Color(0, 0, 0, 0)
        sb.border_width_bottom = 1
        sb.border_color = under
        sb.content_margin_left = 10
        sb.content_margin_right = 10
        sb.content_margin_top = 6
        sb.content_margin_bottom = 6
        return sb
    btn.add_theme_stylebox_override("normal", mk.call(Color(Tokens.PARCHMENT, 0.35)))
    btn.add_theme_stylebox_override("hover", mk.call(Tokens.BRASS_HI))
    btn.add_theme_stylebox_override("pressed", mk.call(Tokens.BRASS))
    btn.add_theme_stylebox_override("focus", mk.call(Tokens.BRASS_HI))
    btn.add_theme_color_override("font_color", Color(Tokens.PARCHMENT, 0.85))
    btn.add_theme_color_override("font_hover_color", Tokens.LAMP_KEY)
    btn.add_theme_color_override("font_pressed_color", Tokens.BRASS_HI)
    btn.add_theme_color_override("font_focus_color", Color(Tokens.PARCHMENT, 0.85))
    btn.add_theme_font_size_override("font_size", 14)
    Tokens.pad_target(btn)

func _file_tab(chip: Button) -> void:
    # move 9: the filter chips read as small skewed file-tabs on the drawer lip.
    # Same toggle state machine; selected = warm fill + --brass-hi border (DESIGN.md).
    var mk := func(fill: Color, border: Color) -> StyleBoxFlat:
        var sb := StyleBoxFlat.new()
        sb.bg_color = fill
        sb.border_color = border
        sb.border_width_top = 1
        sb.border_width_left = 1
        sb.border_width_right = 1
        sb.corner_radius_top_left = 7
        sb.corner_radius_top_right = 7
        sb.skew = Vector2(0.16, 0.0)
        sb.content_margin_left = 12
        sb.content_margin_right = 12
        sb.content_margin_top = 5
        sb.content_margin_bottom = 5
        return sb
    chip.add_theme_stylebox_override("normal", mk.call(Tokens.PANEL_FILL, Color(Tokens.BRASS, 0.45)))
    chip.add_theme_stylebox_override("hover", mk.call(Tokens.PANEL_FILL.lightened(0.08), Color(Tokens.BRASS, 0.7)))
    chip.add_theme_stylebox_override("pressed", mk.call(Tokens.BRASS.darkened(0.45), Tokens.BRASS_HI))
    chip.add_theme_stylebox_override("hover_pressed", mk.call(Tokens.BRASS.darkened(0.38), Tokens.BRASS_HI))
    chip.add_theme_color_override("font_color", Color(Tokens.PARCHMENT, 0.75))
    chip.add_theme_color_override("font_hover_color", Tokens.PARCHMENT)
    chip.add_theme_color_override("font_pressed_color", Tokens.BRASS_HI)
    chip.add_theme_color_override("font_hover_pressed_color", Tokens.BRASS_HI)
    chip.add_theme_color_override("font_focus_color", Color(Tokens.PARCHMENT, 0.75))

func _card_tilt(pi: PartInstance) -> float:
    # 1-2 deg rest tilt seeded from the bit id hash - stable run to run, screenshot-safe
    var h := String(pi.data.id).hash()
    var mag := 1.0 + float(h % 97) / 96.0
    return mag if ((h >> 8) & 1) == 0 else -mag

# The wax-seal press on the BIND plate - same red-wax vocabulary as the Barrow's SOLD stamp.
class WaxSeal extends Control:
    func _draw() -> void:
        var c := size * 0.5
        draw_circle(c, 10.0, Tokens.WAX)
        draw_arc(c, 10.0, 0.0, TAU, 28, Tokens.WAX.darkened(0.25), 1.5, true)
        draw_arc(c, 6.5, 0.0, TAU, 24, Color(Tokens.BENCH_LO, 0.55), 1.3, true)
        draw_circle(c + Vector2(-3.0, -3.5), 2.0, Color(1, 1, 1, 0.20))
        var f := get_theme_default_font()
        var px := 8
        var base_y := c.y - f.get_height(px) * 0.5 + f.get_ascent(px)
        draw_string(f, Vector2(c.x - 8.0, base_y), "❖", HORIZONTAL_ALIGNMENT_CENTER, 16.0, px, Color(Tokens.BENCH_LO, 0.7))

# Move 2 chrome over the stage texture: faked rounded felt corners, brass rim, stitched
# seam, and a soft lamp pool where the toy stands. One draw pass, ignores the mouse.
class StandFrame extends Control:
    func _ready() -> void:
        resized.connect(queue_redraw)

    func _draw() -> void:
        if size.x <= 0.0:
            return
        var fr := SocketRig.stand_rect(size)
        var rad := 14.0
        # wall-colored wedges over the texture corners = rounded felt
        _corner(fr.position, 1.0, 1.0, rad)
        _corner(Vector2(fr.end.x, fr.position.y), -1.0, 1.0, rad)
        _corner(fr.end, -1.0, -1.0, rad)
        _corner(Vector2(fr.position.x, fr.end.y), 1.0, -1.0, rad)
        # soft radial lamp pool over the felt, pooled around the toy's stand
        var lp := Vector2(fr.position.x + fr.size.x * 0.5, fr.position.y + fr.size.y * 0.36)
        for i in range(5, 0, -1):
            draw_circle(lp, fr.size.y * 0.11 * i, Color(Tokens.LAMP_KEY, 0.020))
        # brass rim with a stitched felt seam just inside it
        var rim := StyleBoxFlat.new()
        rim.draw_center = false
        rim.set_corner_radius_all(int(rad))
        rim.set_border_width_all(3)
        rim.border_color = Tokens.BRASS
        rim.draw(get_canvas_item(), fr)
        var lip := StyleBoxFlat.new()
        lip.draw_center = false
        lip.set_corner_radius_all(int(rad) + 2)
        lip.set_border_width_all(1)
        lip.border_color = Color(Tokens.BENCH_LO, 0.7)
        lip.draw(get_canvas_item(), fr.grow(2.0))
        Tokens.draw_stitch_rect(self, fr.grow(-6.0))

    func _corner(at: Vector2, dirx: float, diry: float, rad: float) -> void:
        var cc := at + Vector2(dirx * rad, diry * rad)
        var a0 := 270.0 if diry > 0.0 else 90.0
        var a1 := 180.0 if dirx > 0.0 else 0.0
        if absf(a1 - a0) > 180.0:
            a1 += 360.0 * signf(a0 - a1)
        var pts := PackedVector2Array()
        pts.append(at)
        for k in 10:
            var ang := deg_to_rad(lerpf(a0, a1, float(k) / 9.0))
            pts.append(cc + Vector2(cos(ang), sin(ang)) * rad)
        draw_colored_polygon(pts, Tokens.BENCH_WALNUT)

# Move 9 chrome inside the drawer: carved bracket corners + dovetail teeth on the lip.
class DrawerChrome extends Control:
    func _ready() -> void:
        resized.connect(queue_redraw)

    func _draw() -> void:
        if size.x <= 0.0:
            return
        var carve := Color(Tokens.BENCH_LO, 0.75)
        var hi := Color(Tokens.BENCH_HI, 0.45)
        var L := 16.0
        for cx in [0.0, size.x]:
            for cy in [0.0, size.y]:
                var dx := 1.0 if cx == 0.0 else -1.0
                var dy := 1.0 if cy == 0.0 else -1.0
                var o := Vector2(cx + dx * 2.0, cy + dy * 2.0)
                draw_line(o, o + Vector2(dx * L, 0.0), carve, 3.0)
                draw_line(o, o + Vector2(0.0, dy * L), carve, 3.0)
                draw_line(o + Vector2(dx, dy), o + Vector2(dx * (L - 3.0), dy), hi, 1.0)
                draw_line(o + Vector2(dx, dy), o + Vector2(dx, dy * (L - 3.0)), hi, 1.0)
        # dovetail joinery peeking over the drawer lip
        var x := 30.0
        while x < size.x - 34.0:
            draw_rect(Rect2(x, -7.0, 9.0, 6.0), Color(Tokens.BENCH_WALNUT, 0.9))
            draw_rect(Rect2(x, -7.0, 9.0, 6.0), Color(Tokens.BENCH_LO, 0.5), false, 1.0)
            x += 34.0

func _snap(slot_name: String) -> void:
    var sf: SlotField = slot_fields.get(slot_name)
    if sf == null:
        return
    # Snap rarity pitch ladder (audio plan, concrete semitones): base file dings A4; COMMON
    # +0 / RARE +3 / EPIC +7 st arpeggiate the A minor home triad (A-C-E). No jitter - the
    # ladder pitch IS the information. Pan follows the socket side like combat does.
    var pitch := 1.0
    var pi: PartInstance = session.manabit.slots.get(slot_name)
    if pi != null:
        match String(pi.data.rarity):
            "RARE":
                pitch = 1.1892
            "EPIC":
                pitch = 1.4983
    var pan := 0.0
    if slot_name == "ARM_L":
        pan = -0.25
    elif slot_name == "ARM_R":
        pan = 0.25
    Sfx.play(&"snap", pitch, pan)
    sf.play_seat_fx()

func _make_chip(color: Color, w: float = 62.0) -> Label:
    var l := Label.new()
    l.add_theme_color_override("font_color", color)
    l.add_theme_font_size_override("font_size", 15)
    l.custom_minimum_size = Vector2(w, 0)
    return l

# Every currency/count display caps so no label ever drives a row's width (layout law).
static func _cap_amount(n: int) -> String:
    return "9999+" if n > 9999 else str(n)

# --- the status-note contract: 72 chars max, tooltip carries the rest, celebrations also toast ---
func _set_note(txt: String, col: Color, act: int = NoteAct.NONE) -> void:
    _bank_note.text = txt
    _bank_note.tooltip_text = txt
    _bank_note.add_theme_color_override("font_color", col)
    _note_act = act

func _on_note_tapped(event: InputEvent) -> void:
    if _note_act == NoteAct.NONE:
        return
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        match _note_act:
            NoteAct.BINDING:
                _toggle_binding_panel()
            NoteAct.FILTER_CORE:
                _focus_slot_in_tray("CORE")

# Celebration toast over the stage (2.5 s), for beats too big for the note line.
func _toast(txt: String) -> void:
    var t := Label.new()
    t.text = txt
    t.add_theme_color_override("font_color", Tokens.BRASS_HI)
    Tokens.display(t, 22)
    _shade(t)
    t.z_index = 40
    add_child(t)
    t.position = Vector2(size.x * 0.5 - 180, size.y * 0.30)
    var tw := t.create_tween()
    tw.tween_property(t, "position:y", t.position.y - 26.0, 2.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    tw.parallel().tween_property(t, "modulate:a", 0.0, 0.9).set_delay(1.6)
    tw.tween_callback(t.queue_free)

# Deterministic populated build for screenshots / demo.
func demo_fill() -> void:
    var cores := {}
    for pd in Catalog.starter_cores():
        cores[String(pd.id)] = pd
    var body := {}
    for pd2 in Catalog.body_pool():
        body[String(pd2.id)] = pd2
    _force_equip("CORE", cores["core_ember"])
    _force_equip("ARM_R", body["arm_hammer"])
    _force_equip("LEGS", body["legs_light"])
    _force_equip("HEAD", body["head_hornet"])
    refresh_from_player()

func _force_equip(slot: String, pd: PartData) -> void:
    var pi := PartInstance.new(pd)
    session.add_to_inventory(pi)
    session.equip(slot, pi)

# A Manabit assembled from DIFFERENT style families - shows the family-tinted placeholders.
func demo_varied() -> void:
    _equip_fam("CORE", "artificer_first")
    _equip_fam("HEAD", "grumble_co")
    _equip_fam("ARM_R", "boldheart")
    _equip_fam("ARM_L", "thicket_fang")
    _equip_fam("LEGS", "whirligig")
    _equip_fam("BACK", "chatterbox")
    refresh_from_player()

func _equip_fam(slot: String, fam: String) -> void:
    for pd in Catalog.all():
        if String(pd.family) != fam:
            continue
        var ps := String(pd.slot)
        var arm_ok := (slot == "ARM_L" or slot == "ARM_R") and (ps == "ARM_L" or ps == "ARM_R")
        if ps == slot or arm_ok:
            if slot == "CORE" and not pd.is_core:
                continue
            _force_equip(slot, pd)
            return
