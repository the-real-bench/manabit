class_name CombatScreen extends Control
# Turn-based part-targeted combat. Two modes:
#   SPAR  - no stakes, vs the Tinker's Dummy (clone, nothing lost).
#   BOUT  - real stakes vs an authored challenger: WIN loots a part off the loser (§6),
#           SURVIVABLE-LOSS forfeits one of YOUR broken parts + scrap. (Fought on a clone, so the
#           build's HP isn't spent yet - repair economy is later; only the wager is real.)
#
# PLAYBACK DIRECTOR (2026-07-18 combat-juice push): resolution stays instant (combat.perform),
# presentation replays it - plan() turns last_events into a pure, deterministic beat schedule
# (ladder rungs, hit-stops, anti-strobe caps), _play() executes it on awaited SceneTreeTimers
# with a display-HP snapshot (_disp) so bars drop per hit. Truth wins at every turn boundary
# (_aftermath reconciles). Changing anything here NEVER touches the resolver.

signal done

# ==================== JuiceTuning ====================
# Single greppable source for every combat-juice number. All *_MS are manual-mode milliseconds;
# Auto mode multiplies durations by JT_AUTO_SCALE, halves hit-stops, floors MULTI gaps at 90
# and the telegraph at 200. Fight-end beats never scale.
const JT_AUTO_SCALE := 0.6
const JT_THINK_MANUAL_MS := 350.0        # foe think, outside the playback budget (was _delay 0.5)
const JT_THINK_AUTO_MS := 120.0          # auto think (was _delay 0.2)
const JT_ANTICIPATION_MS := 120.0        # SINGLE pull-away
const JT_LUNGE_MS := 70.0                # SINGLE drive to impact (impact frame at 190)
const JT_STOP_T1_MS := 60.0              # normal hit stop (0 on MULTI mid-hits)
const JT_STOP_T2_MS := 120.0             # first part-break stop (later breaks 60)
const JT_STOP_T3_MS := 150.0             # first core-hit stop (later core hits 60)
const JT_STOP_T4_MS := 280.0             # core kill stop (budget-exempt)
const JT_STOP_CAP_MS := 300.0            # total hit-stop per turn (kill exempt)
const JT_MULTI_WINDUP_MS := 140.0        # one shared flurry wind-up
const JT_GAP_BASE_MS := 210.0            # gap_i = max(floor, 210 - 45*(i-1))
const JT_GAP_STEP_MS := 45.0
const JT_GAP_FLOOR_MS := 110.0
const JT_GAP_FLOOR_AUTO_MS := 90.0
const JT_RECOVER_DWELL_MS := 160.0       # read-the-result dwell before the return
const JT_BREAK_DWELL_MS := 90.0          # extra dwell when a part broke
const JT_CORE_DWELL_MS := 120.0          # extra dwell when the core was struck
const JT_RETURN_MS := 180.0              # attacker return-to-rest
const JT_TELEGRAPH_MS := 250.0           # core-hunt telegraph insert
const JT_TELEGRAPH_FLOOR_MS := 200.0     # legibility never scales to zero
const JT_GUARD_SETTLE_MS := 320.0
const JT_GUARD_END_MS := 420.0
const JT_MEND_SETTLE_MS := 380.0
const JT_MEND_END_MS := 520.0
const JT_EMPTY_END_MS := 50.0            # no-event action playback cap
const JT_BUDGET_MANUAL_MS := 1500.0      # planner-enforced cadence caps (QA contract)
const JT_BUDGET_AUTO_MS := 800.0
const JT_PANE_FLASH_MAX := 3             # per action; extras DEMOTED to part blips, never dropped
const JT_PANE_FLASH_SPACING_MS := 250.0
const JT_PANE_FLASH_A := 0.15            # warm white, break only
const JT_FS_FLASH_A := 0.20              # full-screen, struck core's affinity, once per turn
const JT_BAR_ROLL_S := 0.12
const JT_MEND_ROLL_S := 0.2              # the only up-roll in combat - ALWAYS plays
const JT_NUM_RISE_PX := 48.0
const JT_KILL_HANG_MS := 200.0
const JT_PUNCH_PART := 1.06
const JT_PUNCH_CORE := 1.10
const JT_SHAKE_BREAK_PX := 6.0
const JT_SHAKE_BREAK_S := 0.15
const JT_SHAKE_CORE_PX := 8.0
const JT_SHAKE_CORE_S := 0.18
const JT_SHAKE_KILL_PX := 10.0
const JT_SHAKE_KILL_S := 0.22
# --- B2 combat presence: the two core hums, the peril STATE, and the R1 sustained peril visual ---
const JT_PERIL_RATIO := 0.35             # player core display-HP ratio below which peril holds
const JT_HUM_FULL_DB := -32.0            # core-hum player volume at full soul (matches Sfx MANIFEST)
const JT_HUM_FADE_DB := -20.0            # extra attenuation folded in as the soul fades to nothing
const JT_PERIL_HZ := 2.0                 # the shared 2 Hz clock the peril bed AM + this visual ride
const JT_PERIL_VIG_BASE_A := 0.45        # held peril vignette modulate.a floor ...
const JT_PERIL_VIG_SWING_A := 0.42       # ... breathing up by this much at 2 Hz (warm, never strobing)
# =====================================================

# ==================== StalemateBreaker ====================
# Driver-level no-progress timeout for the mutual-GUARD softlock (design/balance/stalemate-breaker.md).
# combat/combat.gd + the section-13 resolver stay BYTE-UNTOUCHED: the driver times out a no-progress
# loop to the EXISTING Combat.Result.SURVIVABLE_LOSS (no new outcome, no resolver change). A turn is
# "no-progress" when the COMBINED current-HP of both fighters did not decrease across it (HP-delta, not
# last_events - which goes STALE on the AI early-return paths). STALEMATE_LIMIT consecutive no-progress
# turns -> soft called-draw: SURVIVABLE_LOSS, but the in-combat forfeit UI is SKIPPED (both cores are
# alive by construction, nothing was earned). Tunable via this single const; do not scale it by Auto.
const STALEMATE_LIMIT := 10
# ==========================================================

var player: PlayerState
var combat: Combat
var _me: ManabitState
var _foe: ManabitState
var _real_build: ManabitState = null       # bout: the actual bench build, so forfeits stick
var _foe_name := ""
var _stakes := false
var _run_mode := false
var _kit_run: RunState = null              # set on Trundle run-fights: loot capped, forfeits pay ⚙0
var last_result := Combat.Result.ONGOING
var _outcome := Combat.Result.ONGOING
var _resolved := false
var _pending: Dictionary = {}
var _auto := false
var _state := "idle"                        # idle | choose_move | choose_target | busy | over

var _title: Label
var _turn_label: Label
var _me_stage: ManabitStage
var _foe_stage: ManabitStage
var _me_title: Label
var _foe_title: Label
var _me_panel: VBoxContainer
var _foe_panel: VBoxContainer
var _moves_box: HBoxContainer
var _log_label: Label
var _auto_btn: CheckButton
var _banner: Label
var _fx: Control
var _arena: HBoxContainer

# director state
var _gen := 0                               # generation guard: bumped per fight, checked after awaits
var _playing := false
var _rows := {"me": {}, "foe": {}}          # side -> slot -> {row, bar, hp, tag, btn}
var _disp := {"me": {}, "foe": {}}          # display HP snapshot (per-hit replay source)
var _row_tweens := {}
var _log_shown := 0
var _unmake_active := false
var _unmake_skip := false
var _unmake_t0 := 0
# B2 combat-presence state
var _hums_on := false
var _peril_on := false
var _peril_edges: Array = []
var _unmake_gate := false          # true only while THE UNMAKING stillness gate is held closed
# StalemateBreaker driver state (see the StalemateBreaker const block)
var _noprog_turns := 0             # consecutive turns across which combined HP did not decrease
var _stalemate := false            # this fight ended via the no-progress breaker (called draw)

func setup(p: PlayerState) -> CombatScreen:
    player = p
    return self

func _ready() -> void:
    _build_layout()

func begin_spar(source: ManabitState) -> void:
    _stakes = false
    _run_mode = false
    _real_build = null
    _kit_run = null
    _foe_name = "Strawjack - the Tinker's Dummy"
    _foe = _make_dummy()
    _me = _clone(source)                # spar/bout fight a clone (nothing lost)
    _title.text = "    THE SPARRING"
    _start(false)

func begin_bout(source: ManabitState, challenger: Dictionary) -> void:
    _stakes = true
    _run_mode = false
    _real_build = source
    _kit_run = null
    _foe_name = String(challenger.get("name", "Challenger"))
    _foe = Challengers.make(challenger)
    _me = _clone(source)
    _title.text = "    THE BOUT"
    # Wave 1 CH-08: the stake is charged the moment the bout begins, non-refundable.
    # Proving Grounds rows gate on affordability; the clamp is belt-and-braces only.
    var stake := PlayerState.bout_stake(challenger)
    player.scrap = maxi(0, player.scrap - stake)
    player.save()
    _start(false)                       # M2 bouts don't aim the core
func begin_run_fight(carried: ManabitState, challenger: Dictionary, aims_core: bool, kit_run: RunState = null, mod_id: String = "", rider: int = 0) -> void:
    _stakes = true
    _run_mode = true
    _real_build = carried
    _kit_run = kit_run                  # Trundle context: loot capped to 1 COMMON, forfeits pay ⚙0
    _foe_name = String(challenger.get("name", "Challenger"))
    _foe = Challengers.make(challenger, mod_id, rider)   # lane modifier + shrine rider (MAX-NOT-SUM) - foe-side only
    _me = carried                       # REAL carried Manabit - damage persists, no clone
    _title.text = "    " + ("★ " if bool(challenger.get("boss", false)) else "") + String(challenger.get("label", "Bout"))
    _start(aims_core)

func _start(foe_aims_core: bool) -> void:
    _gen += 1
    _teardown_combat_audio()            # a restart never leaks the prior fight's loops / gate
    combat = Combat.new()
    combat.start(_me, _foe, foe_aims_core)
    _pending = {}
    _resolved = false
    _outcome = Combat.Result.ONGOING
    last_result = Combat.Result.ONGOING
    _state = "idle"
    _playing = false
    _noprog_turns = 0                   # StalemateBreaker: fresh no-progress counter per fight
    _stalemate = false
    _unmake_active = false
    _unmake_skip = false
    _banner.text = ""
    _banner.rotation = 0.0
    _banner.modulate = Color.WHITE
    _me_title.text = "YOUR MANABIT"
    _foe_title.text = _foe_name
    _reset_pane(_me_stage)
    _reset_pane(_foe_stage)
    _me_stage.reset_pose()              # loss slump / death dim never leak into the next fight
    _foe_stage.reset_pose()
    _me_stage.lock_framing(true)        # frame the starting build once, then HOLD - breaks
    _foe_stage.lock_framing(true)       # shrinking the AABB must never re-zoom mid-fight
    if _arena != null:
        _arena.queue_sort()
    _row_tweens.clear()
    _build_rows(_me_panel, _me, "me")
    _build_rows(_foe_panel, _foe, "foe")
    _start_core_hums()                  # the combat room tone: two detuned souls (me / foe)
    _log_shown = combat.battle_log.size()
    _next()

func _reset_pane(st: Control) -> void:
    st.rotation = 0.0
    st.scale = Vector2.ONE
    st.modulate = Color.WHITE

# --- layout ---
func _build_layout() -> void:
    set_anchors_preset(Control.PRESET_FULL_RECT)
    var bg := ColorRect.new()
    bg.color = Tokens.BENCH_LO
    bg.set_anchors_preset(Control.PRESET_FULL_RECT)
    bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(bg)
    Warmth.apply(self)

    var root := VBoxContainer.new()
    root.set_anchors_preset(Control.PRESET_FULL_RECT)
    root.offset_left = 18
    root.offset_top = 12
    root.offset_right = -18
    root.offset_bottom = -14
    root.add_theme_constant_override("separation", 8)
    add_child(root)

    var top := HBoxContainer.new()
    root.add_child(top)
    var back := Button.new()
    back.text = "◂  Leave"
    back.pressed.connect(func(): done.emit())
    top.add_child(back)
    _title = Label.new()
    _title.text = "    THE SPARRING"
    _title.add_theme_color_override("font_color", Tokens.BRASS_HI)
    _title.add_theme_font_size_override("font_size", 18)
    top.add_child(_title)
    var sp := Control.new()
    sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    top.add_child(sp)
    _auto_btn = CheckButton.new()
    _auto_btn.text = "Auto"
    _auto_btn.toggled.connect(_on_auto)
    top.add_child(_auto_btn)

    _banner = Label.new()
    _banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _banner.add_theme_color_override("font_color", Tokens.LAMP_KEY)
    _banner.add_theme_font_size_override("font_size", 18)
    root.add_child(_banner)

    _arena = HBoxContainer.new()
    _arena.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _arena.add_theme_constant_override("separation", 16)
    root.add_child(_arena)
    var mine := _make_column(_arena)
    _me_title = mine[0]
    _me_stage = mine[1]
    _me_panel = mine[2]
    var theirs := _make_column(_arena)
    _foe_title = theirs[0]
    _foe_stage = theirs[1]
    _foe_panel = theirs[2]

    _turn_label = Label.new()
    _turn_label.add_theme_color_override("font_color", Tokens.LAMP_KEY)
    root.add_child(_turn_label)

    var mv_wrap := PanelContainer.new()
    mv_wrap.custom_minimum_size = Vector2(0, 56)
    mv_wrap.add_theme_stylebox_override("panel", _pnl(Tokens.PANEL_FILL))
    root.add_child(mv_wrap)
    _moves_box = HBoxContainer.new()
    _moves_box.add_theme_constant_override("separation", 8)
    mv_wrap.add_child(_moves_box)

    var log_wrap := PanelContainer.new()
    log_wrap.custom_minimum_size = Vector2(0, 92)
    log_wrap.add_theme_stylebox_override("panel", _pnl(Tokens.PANEL_DEEP))
    root.add_child(log_wrap)
    _log_label = Label.new()
    _log_label.add_theme_color_override("font_color", Color(Tokens.PARCHMENT, 0.85))
    _log_label.add_theme_font_size_override("font_size", 12)
    log_wrap.add_child(_log_label)

    _fx = Control.new()              # transient juice layer, above everything
    _fx.set_anchors_preset(Control.PRESET_FULL_RECT)
    _fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_fx)

func _make_column(parent: HBoxContainer) -> Array:
    var col := VBoxContainer.new()
    col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    col.add_theme_constant_override("separation", 6)
    parent.add_child(col)
    var t := Label.new()
    t.add_theme_color_override("font_color", Tokens.BRASS_HI)
    t.add_theme_font_size_override("font_size", 14)
    col.add_child(t)
    var stage := ManabitStage.new()
    stage.custom_minimum_size = Vector2(0, 190)
    stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
    col.add_child(stage)
    var body := VBoxContainer.new()
    body.add_theme_constant_override("separation", 5)
    col.add_child(body)
    return [t, stage, body]

# --- turn driver ---
func _next() -> void:
    _refresh()
    var res := combat.outcome()
    if res != Combat.Result.ONGOING:
        _finish(res)
        return
    var actor := combat.current()
    if actor == _foe or _auto:
        _state = "busy"
        _refresh_hud()
        var gen := _gen
        await get_tree().create_timer((JT_THINK_AUTO_MS if _auto else JT_THINK_MANUAL_MS) / 1000.0).timeout
        if not is_inside_tree() or gen != _gen:
            return
        if actor == _foe:
            await _apply(func(): combat.ai_take_turn(_foe, _me), _foe)
        else:
            await _apply(func(): combat.ai_take_turn(_me, _foe), _me)
    else:
        _state = "choose_move"
        _refresh_hud()

func _apply(action: Callable, attacker: ManabitState) -> void:
    var gen := _gen
    # Warmup guard: the fight's opening frames can stall (shader/glb pipeline compile on the
    # first visible stage frame), and time-based tweens + timers leapfrog a stalled frame -
    # measured: the first lunge of a fight TELEPORTS to full extension. Two process-frame
    # waits let any stall pass BEFORE beats exist; on warm frames this costs ~33ms.
    await get_tree().process_frame
    await get_tree().process_frame
    if not is_inside_tree() or gen != _gen:
        return
    var commit := Time.get_ticks_msec()
    _snap_disp()
    _log_shown = combat.battle_log.size()
    var hp_before := _combined_hp()     # StalemateBreaker: HP-delta signal, snapped either side of the action
    action.call()                       # instant resolution - outcome banked before one frame plays
    # progress = a blow landed (combined HP fell). A GUARD/idle leaves HP flat, a mend RAISES it -
    # both are no-progress. HP-delta is staleness-immune (last_events goes stale on AI early-returns).
    if _combined_hp() < hp_before:
        _noprog_turns = 0
    else:
        _noprog_turns += 1
    var events := _digest_events(combat.last_events)
    var ctx := _make_ctx(attacker, events)
    var beats := plan(events, ctx, {"auto": _auto, "reduce_motion": Juice.reduce_motion})
    var planned := 0.0
    if not beats.is_empty():
        var last: Dictionary = beats[beats.size() - 1]
        planned = float(last["t"]) + float((last["data"] as Dictionary).get("dur", 0.0))
    await _play(beats, ctx)
    if not is_inside_tree() or gen != _gen:
        return
    print("[juice] commit->control %d ms (planned %d ms, auto=%s rm=%s)" % [Time.get_ticks_msec() - commit, int(planned), str(_auto), str(Juice.reduce_motion)])
    _aftermath()
    _after()

func _after() -> void:
    # StalemateBreaker: before the normal outcome check, time out a no-progress loop the resolver
    # can never end (mutual GUARD / mend / hang-back) to the EXISTING SURVIVABLE_LOSS. Both cores
    # are alive here (outcome is still ONGOING), so the called draw unmakes nobody.
    if combat.outcome() == Combat.Result.ONGOING and _noprog_turns >= STALEMATE_LIMIT:
        _stalemate = true
        _finish(Combat.Result.SURVIVABLE_LOSS)
        return
    if combat.outcome() != Combat.Result.ONGOING:
        _next()
        return
    combat.advance_turn()
    _next()

func _wait_turn() -> void:
    # The player-Wait path bypasses _apply (no action.call()), so its no-progress increment lives here.
    _noprog_turns += 1
    _after()

func _combined_hp() -> int:
    # StalemateBreaker signal source: sum of current_hp over every seated slot of both fighters.
    # Read-only - touches nothing frozen. A landed strike always deals >= 1, so a decrease means
    # the fight moved toward a finish; GUARD holds it flat, a mend raises it (both no-progress).
    var total := 0
    for m in [_me, _foe]:
        if m == null:
            continue
        for slot in ManabitState.SLOT_NAMES:
            var pi: PartInstance = m.slots.get(slot)
            if pi != null:
                total += pi.current_hp
    return total

func _on_move(move: Dictionary) -> void:
    if _state != "choose_move":
        return
    var ability: AbilityData = move["ability"]
    if ability.archetype == "SINGLE":
        _pending = move
        _state = "choose_target"
        _refresh_hud()
    else:
        _state = "busy"
        _refresh_hud()
        var slot := String(move["slot"])
        var act := func():
            combat.perform(_me, ability, _foe, "")
            combat.last_action["actor_slot"] = slot
        await _apply(act, _me)

func _on_target(slot: String) -> void:
    if _state != "choose_target":
        return
    var ability: AbilityData = _pending["ability"]
    var actor_slot := String(_pending.get("slot", ""))
    _pending = {}
    _state = "busy"
    _refresh_hud()
    var act := func():
        combat.perform(_me, ability, _foe, slot)
        combat.last_action["actor_slot"] = actor_slot
    await _apply(act, _me)

# --- the planner: pure + deterministic (no randf in beat times; jitter at play time only) ---
# events: [{slot, damage, broke, is_core, target_is_me}] (digested from combat.last_events)
# ctx:    {attacker_is_me, archetype, guard_kind, guard_amount, mend_slot, amount, kill,
#          telegraph, defender_affinity, my_affinity, whoosh_pitch}
# opts:   {auto, reduce_motion}
# Returns beats [{t (ms), kind, event_index, data}] sorted by t; the last beat is always
# &"settle" and carries data.dur = the return time, so total = settle.t + settle.data.dur.
func plan(events: Array, ctx: Dictionary, opts: Dictionary) -> Array:
    var auto := bool(opts.get("auto", false))
    var rm := bool(opts.get("reduce_motion", false))
    var s := JT_AUTO_SCALE if auto else 1.0
    var arch := String(ctx.get("archetype", "SINGLE"))
    var beats: Array = []
    if arch == "GUARD":
        if String(ctx.get("guard_kind", "DEF_BUFF")) == "PART_RESTORE" and String(ctx.get("mend_slot", "")) != "":
            beats.append({"t": 0.0, "kind": &"mend", "event_index": -1, "data": {"slot": String(ctx.get("mend_slot", "")), "amount": int(ctx.get("amount", 0))}})
            beats.append({"t": JT_MEND_SETTLE_MS * s, "kind": &"settle", "event_index": -1, "data": {"dur": (JT_MEND_END_MS - JT_MEND_SETTLE_MS) * s}})
        else:
            beats.append({"t": 0.0, "kind": &"guard", "event_index": -1, "data": {"amount": int(ctx.get("guard_amount", 0))}})
            beats.append({"t": JT_GUARD_SETTLE_MS * s, "kind": &"settle", "event_index": -1, "data": {"dur": (JT_GUARD_END_MS - JT_GUARD_SETTLE_MS) * s}})
        return beats
    if events.is_empty():
        beats.append({"t": 0.0, "kind": &"settle", "event_index": -1, "data": {"dur": JT_EMPTY_END_MS}})
        return beats
    var t := 0.0
    var kill := bool(ctx.get("kill", false))
    if bool(ctx.get("telegraph", false)):
        var tele := maxf(JT_TELEGRAPH_MS * s, JT_TELEGRAPH_FLOOR_MS)
        beats.append({"t": 0.0, "kind": &"telegraph", "event_index": -1, "data": {"dur": tele}})
        t = tele
    var multi := arch == "MULTI" and events.size() > 1
    var stop_scale := 0.5 if auto else 1.0
    var stop_budget := JT_STOP_CAP_MS * stop_scale
    var used_stop := 0.0
    var pane_flash_times: Array = []
    var fs_done := false
    var first_break_done := false
    var first_core_done := false
    var any_break := false
    var any_core := false
    var kill_idx := -1
    if kill:
        for i in events.size():
            if bool(events[i]["is_core"]):
                kill_idx = i
    beats.append({"t": t, "kind": &"windup", "event_index": -1, "data": {"multi": multi}})
    if multi:
        t += JT_MULTI_WINDUP_MS * s
    else:
        t += (JT_ANTICIPATION_MS + JT_LUNGE_MS) * s
    var gap_floor := JT_GAP_FLOOR_AUTO_MS if auto else JT_GAP_FLOOR_MS
    var wp := float(ctx.get("whoosh_pitch", 1.0))
    var last_recover := t
    for i in events.size():
        var e: Dictionary = events[i]
        if multi and i > 0:
            t += maxf(gap_floor, (JT_GAP_BASE_MS - JT_GAP_STEP_MS * float(i - 1)) * s)
        var mid := multi and i < events.size() - 1
        if multi:
            if mid:
                beats.append({"t": maxf(0.0, t - 40.0 * s), "kind": &"jab", "event_index": i, "data": {}})
            else:
                beats.append({"t": maxf(0.0, t - JT_LUNGE_MS * s), "kind": &"lunge", "event_index": i, "data": {}})
        var is_core := bool(e["is_core"])
        var broke := bool(e["broke"])
        var stop := 0.0
        var rung := 1
        var pane_flash := false
        var fs_flash := false
        if kill and i == kill_idx:
            rung = 4
            stop = JT_STOP_T4_MS * stop_scale       # kill exempt from the stop cap
        elif is_core:
            rung = 3
            stop = (JT_STOP_T3_MS if not first_core_done else JT_STOP_T1_MS) * stop_scale
            fs_flash = not fs_done and not first_core_done
        elif broke:
            rung = 2
            stop = (JT_STOP_T2_MS if not first_break_done else JT_STOP_T1_MS) * stop_scale
            # anti-strobe caps: >=250ms apart, max 3 per action; over-cap DEMOTES to a part
            # glow blip (stamp + number still play - information is never dropped).
            # MULTI mid-hits never pane-flash regardless.
            pane_flash = pane_flash_times.size() < JT_PANE_FLASH_MAX
            for pt in pane_flash_times:
                if absf(t - float(pt)) < JT_PANE_FLASH_SPACING_MS:
                    pane_flash = false
        else:
            stop = 0.0 if mid else JT_STOP_T1_MS * stop_scale
        if rung != 4:
            stop = minf(stop, maxf(0.0, stop_budget - used_stop))
            used_stop += stop
        if rm:
            stop = 0.0        # hit-stops are motion: fully off under reduce motion
        var pitch := wp * minf(1.25, 1.0 + 0.05 * float(i))
        beats.append({"t": t, "kind": &"impact", "event_index": i, "data": {
            "slot": String(e["slot"]), "is_core": is_core, "broke": broke,
            "damage": int(e["damage"]), "target_is_me": bool(e["target_is_me"]),
            "rung": rung, "stop": stop, "pane_flash": pane_flash and not rm, "mid": mid,
            "pitch": pitch}})
        beats.append({"t": t, "kind": &"number", "event_index": i, "data": {
            "damage": int(e["damage"]), "is_core": is_core, "mid": mid, "kill": rung == 4,
            "target_is_me": bool(e["target_is_me"]),
            "y_off": 3.0 if i % 2 == 0 else -3.0}})
        if fs_flash:
            beats.append({"t": t, "kind": &"core_flash", "event_index": i, "data": {}})
            fs_done = true
        if pane_flash:
            pane_flash_times.append(t)
        var rec_t := t + stop
        if broke:
            beats.append({"t": rec_t, "kind": &"break", "event_index": i, "data": {
                "slot": String(e["slot"]), "target_is_me": bool(e["target_is_me"])}})
            first_break_done = true
            any_break = true
        if is_core:
            first_core_done = true
            any_core = true
        beats.append({"t": rec_t, "kind": &"recover", "event_index": i, "data": {
            "slot": String(e["slot"]), "target_is_me": bool(e["target_is_me"]),
            "damage": int(e["damage"]), "rung": rung, "kill": rung == 4, "mid": mid}})
        last_recover = rec_t
        t = rec_t
    var dwell := JT_RECOVER_DWELL_MS * s
    if not auto:
        if any_break:
            dwell += JT_BREAK_DWELL_MS
        if any_core:
            dwell += JT_CORE_DWELL_MS
    var settle_t := last_recover + dwell
    var ret := JT_RETURN_MS * s
    if not kill:
        # planner-enforced cadence budget: the fixture never exceeds the QA table
        var cap := JT_BUDGET_AUTO_MS if auto else JT_BUDGET_MANUAL_MS
        if settle_t + ret > cap:
            settle_t = maxf(last_recover + 40.0, cap - ret)
    beats.append({"t": settle_t, "kind": &"settle", "event_index": -1, "data": {"dur": ret}})
    return beats

# --- the executor ---
func _play(beats: Array, ctx: Dictionary) -> void:
    _playing = true
    var gen := _gen
    # Beat waits anchor to the REAL clock: SceneTreeTimers overshoot by up to a frame each,
    # and accumulating requested durations lets that error compound through a flurry until
    # impacts lag the stage tweens. Re-anchoring per beat keeps playback tween-true.
    # (Assumes no SceneTree pause mid-playback - revisit when the pause screen lands.)
    var t0 := Time.get_ticks_msec()
    var numbers := {}      # event_index -> {lbl, mid, kill}
    var settle_dur := 0.0
    for b in beats:
        var bt: float = b["t"]
        var now := float(Time.get_ticks_msec() - t0)
        if bt > now:
            await get_tree().create_timer((bt - now) / 1000.0).timeout
            if not is_inside_tree() or gen != _gen:
                return
        var d: Dictionary = b["data"]
        match b["kind"]:
            &"telegraph":
                _beat_telegraph(ctx, d)
            &"windup":
                _beat_windup(ctx, d)
            &"lunge":
                _attacker_stage(ctx).lunge(_dir(ctx), _ts(), true)
            &"jab":
                _attacker_stage(ctx).jab(_dir(ctx), _ts())
            &"impact":
                _beat_impact(ctx, d)
            &"number":
                numbers[int(b["event_index"])] = {
                    "lbl": _spawn_number(ctx, d), "mid": bool(d.get("mid", false)),
                    "kill": bool(d.get("kill", false))}
            &"core_flash":
                _core_flash(Tokens.affinity_color(String(ctx.get("defender_affinity", "attack"))))
            &"break":
                _beat_break(ctx, d)
            &"guard":
                _beat_guard(ctx, d)
            &"mend":
                _beat_mend(ctx, d)
            &"recover":
                _beat_recover(ctx, b, numbers)
            &"settle":
                settle_dur = float(d.get("dur", JT_RETURN_MS))
                _beat_settle(ctx)
    if settle_dur > 0.0:
        await get_tree().create_timer(settle_dur / 1000.0).timeout
        if not is_inside_tree() or gen != _gen:
            return
    _playing = false

func _ts() -> float:
    return JT_AUTO_SCALE if _auto else 1.0

func _dir(ctx: Dictionary) -> int:
    return 1 if bool(ctx.get("attacker_is_me", true)) else -1

func _attacker_stage(ctx: Dictionary) -> ManabitStage:
    return _me_stage if bool(ctx.get("attacker_is_me", true)) else _foe_stage

func _defender_stage_of(target_is_me: bool) -> ManabitStage:
    return _me_stage if target_is_me else _foe_stage

func _digest_events(raw: Array) -> Array:
    var out := []
    for e in raw:
        out.append({"slot": String(e["slot"]), "damage": int(e["damage"]),
            "broke": bool(e["broke"]), "is_core": bool(e["is_core"]),
            "target_is_me": e["target"] == _me})
    return out

func _make_ctx(attacker: ManabitState, events: Array) -> Dictionary:
    var la: Dictionary = combat.last_action
    var am := attacker == _me
    var defender := _foe if am else _me
    var res := combat.outcome()
    var kill := res == Combat.Result.WIN or res == Combat.Result.DEATH
    var dw: Dictionary = attacker.derived()
    var def_core: PartInstance = defender.slots.get("CORE")
    return {
        "attacker_is_me": am,
        "archetype": String(la.get("archetype", "SINGLE")),
        "guard_kind": String(la.get("guard_kind", "DEF_BUFF")),
        "guard_amount": int(la.get("guard_amount", 0)),
        "mend_slot": String(la.get("mend_slot", "")),
        "amount": int(la.get("amount", 0)),
        "kill": kill,
        # core-hunt telegraph: detected AFTER instant resolution, zero resolver changes
        "telegraph": (not am) and combat.enemy_can_aim_core
            and String(la.get("archetype", "")) == "SINGLE"
            and events.size() > 0 and bool(events[0]["is_core"]),
        "defender_affinity": String(def_core.data.affinity) if def_core != null else "attack",
        "my_affinity": _core_affinity(_me),
        "whoosh_pitch": clampf(1.35 - 0.005 * float(int(dw["weight"])), 0.85, 1.20),
    }

# --- beat handlers (fire-and-forget; the plan schedule owns all timing) ---
func _beat_telegraph(ctx: Dictionary, d: Dictionary) -> void:
    Sfx.play(&"core_peril")
    _reveal_log_line()                      # "lunges for your core!"
    _pulse_row(true, "CORE")                # your core row brightens - stays under reduce motion
    if Juice.reduce_motion:
        return                              # loom + vignette drop; brighten + drone stay
    var st: Control = _foe_stage
    st.pivot_offset = st.size / 2.0
    var base_y := st.position.y
    var tw := st.create_tween()
    tw.tween_property(st, "scale", Vector2(1.06, 1.06), 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    tw.parallel().tween_property(st, "position:y", base_y - 4.0, 0.22)
    tw.tween_property(st, "scale", Vector2.ONE, 0.08)
    tw.parallel().tween_property(st, "position:y", base_y, 0.08)
    _vignette(Tokens.affinity_color(String(ctx.get("my_affinity", "attack"))), float(d.get("dur", JT_TELEGRAPH_MS)) / 1000.0)

func _beat_windup(ctx: Dictionary, d: Dictionary) -> void:
    var stage := _attacker_stage(ctx)
    var wp := float(ctx.get("whoosh_pitch", 1.0))
    if bool(d.get("multi", false)):
        Sfx.play(&"attack_whoosh", wp * 1.15)   # spun variant is a pitch tweak, not a file
        stage.windup(_dir(ctx), _ts())
    else:
        Sfx.play(&"attack_whoosh", wp)
        stage.lunge(_dir(ctx), _ts())

func _beat_impact(ctx: Dictionary, d: Dictionary) -> void:
    var target_me := bool(d["target_is_me"])
    var dstage := _defender_stage_of(target_me)
    var pan := -0.25 if target_me else 0.25
    var pitch := float(d.get("pitch", 1.0))
    # audio leads video (~a frame): the seam fires before the visuals of the same beat
    if bool(d["is_core"]):
        Sfx.play(&"hit_core", 1.0, pan)
    else:
        Sfx.play(&"hit", pitch, pan)
        if bool(d["broke"]):
            Sfx.play(&"part_break", 1.0, pan)   # layered OVER hit, never replacing
    var slot := String(d["slot"])
    if bool(d["is_core"]):
        dstage.hit_react("CORE", JT_PUNCH_CORE)
        _pulse_row(target_me, "CORE")
        var aff := Tokens.affinity_color(String(ctx.get("defender_affinity", "attack")))
        dstage.spawn_fx("fx_impact_star", "CORE", aff)
    else:
        dstage.hit_react(slot, JT_PUNCH_PART)   # T1 workhorse: part punch + glow blip
    if bool(d.get("pane_flash", false)):
        _flash_stage(dstage)

func _spawn_number(ctx: Dictionary, d: Dictionary) -> Label:
    var target_me := bool(d["target_is_me"])
    var stage: Control = _defender_stage_of(target_me)
    return _float_damage(stage, int(d["damage"]), d, String(ctx.get("defender_affinity", "attack")))

func _beat_break(_ctx: Dictionary, d: Dictionary) -> void:
    var target_me := bool(d["target_is_me"])
    var dstage := _defender_stage_of(target_me)
    var slot := String(d["slot"])
    dstage.detach_part(slot)                 # one snapped piece tumbles off the peg
    dstage.spawn_fx("fx_ring_hex", slot, Tokens.WAX.lightened(0.15))
    _break_pop(dstage)
    _update_row("me" if target_me else "foe", slot, true)   # row greys the moment it snaps
    _reveal_log_line()

func _beat_guard(ctx: Dictionary, d: Dictionary) -> void:
    var stage := _attacker_stage(ctx)
    Sfx.play(&"guard_up")
    _reveal_log_line()
    var amt := int(d.get("amount", 0))
    if Juice.reduce_motion:
        _pane_tint_swell(stage, Tokens.AFF_DEFENSE)
    else:
        stage.brace(_ts())
        var burst := SparkBurst.new()
        burst.size = Vector2(92, 92)
        _fx.add_child(burst)
        var r := stage.get_global_rect()
        burst.global_position = r.position + r.size * 0.5 - Vector2(46, 46)
        burst.fire_in(Tokens.AFF_DEFENSE)    # the dome snapping shut - NEVER a flash/stop/shake
    if amt > 0:
        _chip(stage, "+%d DEF" % amt, Tokens.STAT_DEF_TEXT)

func _beat_mend(ctx: Dictionary, d: Dictionary) -> void:
    var am := bool(ctx.get("attacker_is_me", true))
    var side := "me" if am else "foe"
    var stage := _attacker_stage(ctx)
    Sfx.play(&"mend")
    _reveal_log_line()
    var slot := String(d.get("slot", ""))
    var amt := int(d.get("amount", 0))
    if not Juice.reduce_motion:
        stage.brace(_ts())
        _pane_tint_swell(stage, Color(1.05, 1.0, 0.92))
    var rowsd: Dictionary = _rows[side]
    var rd: Dictionary = rowsd.get(slot, {})
    if not rd.is_empty():
        var m := _state_for(side)
        var pi: PartInstance = m.slots.get(slot)
        if pi != null:
            var dd: Dictionary = _disp[side]
            dd[slot] = pi.current_hp
            _update_row(side, slot, true, JT_MEND_ROLL_S)   # the ONLY up-roll - ALWAYS plays
        if not Juice.reduce_motion:
            _mend_motes(stage, rd)
        _chip(rd.get("row"), "+%d" % amt, Tokens.AFF_MANA_TEXT)
    if slot == "CORE":
        _refresh_core_audio()           # a mended soul swells its hum; peril may clear

func _beat_recover(_ctx: Dictionary, b: Dictionary, numbers: Dictionary) -> void:
    var d: Dictionary = b["data"]
    var target_me := bool(d["target_is_me"])
    var side := "me" if target_me else "foe"
    var slot := String(d["slot"])
    var dstage: Control = _defender_stage_of(target_me)
    # shake is the release, never overlapped with the freeze
    var rung := int(d["rung"])
    if bool(d.get("kill", false)):
        Juice.shake(_arena, JT_SHAKE_KILL_PX, JT_SHAKE_KILL_S)
    elif rung == 3:
        Juice.shake(dstage, JT_SHAKE_CORE_PX, JT_SHAKE_CORE_S)
    elif rung == 2:
        Juice.shake(dstage, JT_SHAKE_BREAK_PX, JT_SHAKE_BREAK_S)
    # true per-hit drop from the pre-action snapshot (odometer pattern)
    var dd: Dictionary = _disp[side]
    var cur: int = dd.get(slot, 0)
    dd[slot] = maxi(0, cur - int(d["damage"]))
    _update_row(side, slot, true)
    var nrec: Dictionary = numbers.get(int(b["event_index"]), {})
    if not nrec.is_empty():
        _rise_number(nrec.get("lbl"), bool(nrec.get("kill", false)), bool(nrec.get("mid", false)))
    _reveal_log_line()
    if slot == "CORE":
        _refresh_core_audio()           # the struck soul quietens its hum; peril re-evaluated

func _beat_settle(ctx: Dictionary) -> void:
    var stage := _attacker_stage(ctx)
    stage.settle(_ts())
    if String(ctx.get("archetype", "")) != "GUARD":
        Juice.squash_pop(stage, 0.12)

# --- juice helpers (information layer always plays; motion honors reduce_motion) ---
func _float_damage(stage: Control, amount: int, d: Dictionary, aff: String) -> Label:
    var mid := bool(d.get("mid", false))
    var is_core := bool(d.get("is_core", false))
    var kill := bool(d.get("kill", false))
    var lbl := Label.new()
    lbl.text = "-%d" % amount
    var fs := 22
    if kill:
        fs = 34
    elif is_core:
        fs = 30
    elif mid:
        fs = 18
    lbl.add_theme_font_size_override("font_size", fs)
    lbl.add_theme_color_override("font_color", Tokens.affinity_text(aff) if (is_core or kill) else Tokens.LAMP_KEY)
    _fx.add_child(lbl)
    var r := stage.get_global_rect()
    var jitter := randf_range(-18.0, 18.0) if mid else randf_range(-45.0, 45.0)
    var y_off := float(d.get("y_off", 0.0)) if mid else 0.0
    lbl.global_position = r.position + Vector2(r.size.x * 0.5 + jitter, r.size.y * 0.4 + y_off)
    lbl.reset_size()
    lbl.pivot_offset = lbl.size / 2.0
    # spawns at the impact frame HELD at 1.15 scale; the rise starts post-stop (_rise_number)
    if Juice.reduce_motion:
        lbl.scale = Vector2.ONE * (0.8 if mid else 1.0)
    else:
        lbl.scale = Vector2.ONE * (0.92 if mid else 1.15)
    return lbl

func _rise_number(lbl: Label, kill: bool, mid: bool) -> void:
    if lbl == null or not is_instance_valid(lbl):
        return
    var rise := 24.0 if Juice.reduce_motion else JT_NUM_RISE_PX
    var tw := lbl.create_tween()
    if kill and not Juice.reduce_motion:
        tw.tween_interval(JT_KILL_HANG_MS / 1000.0)      # the kill number hangs
    tw.tween_property(lbl, "scale", Vector2.ONE * (0.8 if mid else 1.0), 0.08)
    tw.parallel().tween_property(lbl, "position:y", lbl.position.y - rise, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.55).set_delay(0.15)
    tw.chain().tween_callback(lbl.queue_free)

func _flash_stage(stage: Control) -> void:
    # Pane flash: BREAK ONLY (the one pane-rect blink meaning left), warm white, never pure white.
    if Juice.reduce_motion:
        return
    var f := ColorRect.new()
    f.color = Color(1.0, 0.95, 0.85, 0.0)
    f.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _fx.add_child(f)
    var r := stage.get_global_rect()
    f.global_position = r.position
    f.size = r.size
    var tw := f.create_tween()
    tw.tween_property(f, "color:a", JT_PANE_FLASH_A, 0.05)
    tw.tween_property(f, "color:a", 0.0, 0.16)
    tw.tween_callback(f.queue_free)

func _core_flash(color: Color) -> void:
    # Full-screen flash in the STRUCK core's affinity color - once per turn, never white.
    if Juice.reduce_motion:
        return
    var f := ColorRect.new()
    f.color = Color(color, 0.0)
    f.set_anchors_preset(Control.PRESET_FULL_RECT)
    f.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _fx.add_child(f)
    var tw := f.create_tween()
    tw.tween_property(f, "color:a", JT_FS_FLASH_A, 0.05)
    tw.tween_property(f, "color:a", 0.0, 0.22)
    tw.tween_callback(f.queue_free)

func _break_pop(stage: Control) -> void:
    var r := stage.get_global_rect()
    var lbl := Label.new()
    lbl.text = "BROKEN!"
    lbl.add_theme_color_override("font_color", Tokens.WAX)
    lbl.add_theme_font_size_override("font_size", 20)
    _fx.add_child(lbl)
    lbl.global_position = r.position + Vector2(r.size.x * 0.5 - 42, r.size.y * 0.58)
    Juice.stamp_thunk(lbl, 0.2)
    var tw := lbl.create_tween()
    tw.tween_interval(0.4)
    tw.tween_property(lbl, "modulate:a", 0.0, 0.3)
    tw.tween_callback(lbl.queue_free)
    if not Juice.reduce_motion:
        var burst := SparkBurst.new()
        burst._n = 4                              # 3-5 chunky motes, never shrapnel
        burst.size = Vector2(90, 90)
        _fx.add_child(burst)
        burst.global_position = r.position + r.size * 0.5 - Vector2(45, 45)
        burst.fire(Tokens.WAX.lightened(0.15))    # break beats own WAX (color law)

func _pulse_row(target_me: bool, slot: String) -> void:
    var side := "me" if target_me else "foe"
    var rowsd: Dictionary = _rows[side]
    var rd: Dictionary = rowsd.get(slot, {})
    if rd.is_empty():
        return
    var row: Control = rd["row"]
    var tw := row.create_tween()
    tw.tween_property(row, "modulate", Color(1.35, 1.3, 1.2), 0.1)
    tw.tween_property(row, "modulate", Color.WHITE, 0.25)

func _vignette(color: Color, dur: float) -> void:
    # Core-peril dread: 4 edge gradients tinted the PLAYER core's affinity - edges only,
    # never a full-screen wash, never stat-red.
    if Juice.reduce_motion:
        return
    var sz := _fx.size
    var w := sz.x * 0.12
    var h := sz.y * 0.16
    var edges := [
        {"rect": Rect2(Vector2.ZERO, Vector2(w, sz.y)), "from": Vector2(0.0, 0.5), "to": Vector2(1.0, 0.5)},
        {"rect": Rect2(Vector2(sz.x - w, 0), Vector2(w, sz.y)), "from": Vector2(1.0, 0.5), "to": Vector2(0.0, 0.5)},
        {"rect": Rect2(Vector2.ZERO, Vector2(sz.x, h)), "from": Vector2(0.5, 0.0), "to": Vector2(0.5, 1.0)},
        {"rect": Rect2(Vector2(0, sz.y - h), Vector2(sz.x, h)), "from": Vector2(0.5, 1.0), "to": Vector2(0.5, 0.0)},
    ]
    for ed in edges:
        var tr := TextureRect.new()
        var gt := GradientTexture2D.new()
        var g := Gradient.new()
        g.set_color(0, Color(color, 0.10))
        g.set_color(1, Color(color, 0.0))
        gt.gradient = g
        gt.fill_from = ed["from"]
        gt.fill_to = ed["to"]
        tr.texture = gt
        tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        tr.stretch_mode = TextureRect.STRETCH_SCALE
        tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
        var rc: Rect2 = ed["rect"]
        tr.position = rc.position
        tr.size = rc.size
        tr.modulate.a = 0.0
        _fx.add_child(tr)
        var tw := tr.create_tween()
        tw.tween_property(tr, "modulate:a", 1.0, 0.12)
        tw.tween_property(tr, "modulate:a", 0.0, maxf(0.13, dur - 0.12))
        tw.tween_callback(tr.queue_free)

func _mend_motes(stage: Control, rd: Dictionary) -> void:
    var row: Control = rd["row"]
    var from := stage.get_global_rect()
    var to := row.get_global_rect().get_center()
    for i in 4:
        var q := ColorRect.new()
        q.color = Tokens.AFF_MANA
        q.size = Vector2(6, 6)
        q.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _fx.add_child(q)
        q.global_position = from.position + Vector2(randf_range(0.3, 0.7) * from.size.x, randf_range(0.3, 0.7) * from.size.y)
        var tw := q.create_tween()
        tw.tween_interval(0.05 * float(i) + 0.01)
        tw.tween_property(q, "global_position", to, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
        tw.parallel().tween_property(q, "modulate:a", 0.2, 0.3)
        tw.chain().tween_callback(q.queue_free)

func _soul_motes(stage: Control, color: Color) -> void:
    # 4-6 chunky soul-motes rising from the core - the Waking in reverse.
    if Juice.reduce_motion:
        return
    var r := stage.get_global_rect()
    var c := r.position + r.size * 0.5
    for i in 5:
        var q := ColorRect.new()
        q.color = color
        q.size = Vector2(6, 6)
        q.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _fx.add_child(q)
        q.global_position = c + Vector2(randf_range(-24.0, 24.0), randf_range(-8.0, 8.0))
        var tw := q.create_tween()
        tw.tween_interval(0.09 * float(i) + 0.01)
        tw.tween_property(q, "position:y", q.position.y - 60.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
        tw.parallel().tween_property(q, "modulate:a", 0.0, 0.5).set_delay(0.2)
        tw.chain().tween_callback(q.queue_free)

func _chip(anchor: Control, text: String, color: Color) -> void:
    if anchor == null or not is_instance_valid(anchor):
        return
    var lbl := Label.new()
    lbl.text = text
    lbl.add_theme_font_size_override("font_size", 18)
    lbl.add_theme_color_override("font_color", color)
    _fx.add_child(lbl)
    var r := anchor.get_global_rect()
    lbl.global_position = r.position + Vector2(r.size.x * 0.5, r.size.y * 0.35)
    var tw := lbl.create_tween()
    tw.tween_property(lbl, "position:y", lbl.position.y - 32.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.45).set_delay(0.15)
    tw.chain().tween_callback(lbl.queue_free)

func _pane_tint_swell(stage: Control, color: Color) -> void:
    var tw := stage.create_tween()
    tw.tween_property(stage, "modulate", Color.WHITE.lerp(color, 0.25), 0.075)
    tw.tween_property(stage, "modulate", Color.WHITE, 0.075)

func _on_auto(on: bool) -> void:
    _auto = on
    if on and _state == "choose_move":
        _next()

# --- fight-end choreography (never scaled by Auto) ---
func _finish(res: int) -> void:
    _outcome = res
    last_result = res
    _state = "over"
    _exit_peril()                       # the verdict lands: peril state never survives it
    if res != Combat.Result.DEATH:
        _stop_core_hums()               # DEATH stops the hums inside _unmaking (they die AT it)
    _refresh_hud()
    var gen := _gen
    if res == Combat.Result.DEATH:
        await _unmaking(gen)
    elif res == Combat.Result.WIN:
        await _victory(gen)
    else:
        await _loss_slump(gen)
    if not is_inside_tree() or gen != _gen:
        return
    _refresh()
    _stagger_outcome_rows()

func _banner_text(res: int) -> String:
    if _stalemate:
        # Soft called-draw copy (warm register, hyphens only) - overrides the SL "defanged" line.
        if not _stakes:
            return "The duel is called - neither could land the finish. Back to the bench."
        return "The duel is called - neither could land the finish. You both limp off, even."
    if res == Combat.Result.DEATH:
        return "✖ The scrap scatters." if _kit_run != null else "✖ Your Manabit is UNMADE."
    if not _stakes:
        return "✦ Your Manabit stands! ✦  A fine spar." if res == Combat.Result.WIN else "Spar over - back to the bench."
    if res == Combat.Result.WIN:
        if _kit_run != null:
            return "✦ VICTORY ✦  A purse goes into your salvage."
        return "✦ VICTORY ✦  You beat %s - take a piece of it." % _foe_name
    # D3: a SURVIVABLE_LOSS is always has_offensive_move()==false (combat.gd:172) - name the trap.
    return "Defanged - it lost its only way to fight. The victor claims one of your broken parts."

func _victory(gen: int) -> void:
    # foe winds down first, then the flourish. NO 360 spin, banner lands LEVEL.
    Sfx.play(&"victory_chord")
    _foe_stage.soul_flare(0.0, 0.3)
    if not Juice.reduce_motion:
        var tw := _foe_stage.create_tween()
        tw.tween_property(_foe_stage, "modulate", Color(0.9, 0.9, 0.9), 0.3)
    await get_tree().create_timer(0.3).timeout
    if not is_inside_tree() or gen != _gen:
        return
    _banner.text = _banner_text(Combat.Result.WIN)
    if Juice.reduce_motion:
        _banner.modulate.a = 0.0
        _banner.create_tween().tween_property(_banner, "modulate:a", 1.0, 0.2)
        await get_tree().create_timer(0.25).timeout
        return
    Juice.stamp_thunk(_banner, 0.14)
    _banner.rotation = 0.0        # a combat verdict lands straight; the -14 deg tilt stays wax/commerce
    var st: Control = _me_stage
    var base_y := st.position.y
    var tw2 := st.create_tween()
    tw2.tween_property(st, "position:y", base_y - 10.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    tw2.tween_property(st, "position:y", base_y, 0.10)
    tw2.tween_callback(func(): Juice.squash_pop(st, 0.16))
    await get_tree().create_timer(0.08).timeout
    if not is_inside_tree() or gen != _gen:
        return
    var bsz := 120.0 if _stakes else 90.0
    var burst := SparkBurst.new()
    burst.size = Vector2(bsz, bsz)
    _fx.add_child(burst)
    var r := st.get_global_rect()
    burst.global_position = r.position + r.size * 0.5 - Vector2(bsz / 2.0, bsz / 2.0)
    burst.fire(Tokens.GLOW_BASE)
    await get_tree().create_timer(0.5).timeout

func _loss_slump(gen: int) -> void:
    # the pane sighs - defeat gets no celebration mechanics
    Sfx.play(&"loss_settle")
    var st: Control = _me_stage
    if not Juice.reduce_motion:
        st.pivot_offset = st.size / 2.0
        var tw := st.create_tween()
        tw.set_parallel(true)
        tw.tween_property(st, "rotation", deg_to_rad(2.5), 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
        tw.tween_property(st, "scale", Vector2(0.98, 0.98), 0.45)
        tw.tween_property(st, "modulate", Color(0.92, 0.90, 0.86), 0.45)
    _banner.text = _banner_text(Combat.Result.SURVIVABLE_LOSS)
    _banner.modulate.a = 0.0
    _banner.create_tween().tween_property(_banner, "modulate:a", 1.0, 0.25)
    await get_tree().create_timer(0.8).timeout
    if not is_inside_tree() or gen != _gen:
        return

func _unmaking(gen: int) -> void:
    # THE UNMAKING (~1900ms, once per run, budget-exempt). Phases B-D are flash-free,
    # shake-free, burst-free - the quiet IS the consequence.
    _unmake_active = true
    _unmake_skip = false
    _unmake_t0 = Time.get_ticks_msec()
    _exit_peril()                       # peril never bleeds into the silence
    _stop_core_hums(0.12)               # both souls' hums die AT the unmaking
    _unmake_gate = true
    Sfx.stillness(true)                 # first beat: the gate refuses all but the death channel
    var st: ManabitStage = _me_stage
    if Juice.reduce_motion:
        # one slow light dim + staggered scale-pops; motes dropped, the silence and copy remain
        Sfx.play(&"death_winddown")
        st.soul_flare(0.0, 0.3)
        st.light_dim(0.55, 0.3, 0.3)
        st.unmake(0.09)
        await get_tree().create_timer(0.6).timeout
        _unmake_active = false
        if not is_inside_tree() or gen != _gen:
            return
        _parts_settle_beat()            # the pieces settle: gate releases, exit sound admitted
        _show_death_banner()
        return
    # A (0-280) was the T4 rung inside _play. B: the soul flares once, then gutters - light only.
    Sfx.play(&"death_winddown")                # asset <= 900ms: fully decayed before the silence
    st.soul_flare(2.0, 0.12)
    await _unmake_wait(0.12, gen)
    if _unmake_done(gen):
        return
    st.soul_flare(0.0, 0.28)
    st.light_dim(0.55, 0.3, 0.28)
    await _unmake_wait(0.28, gen)
    if _unmake_done(gen):
        return
    # C: the Waking in reverse - gentle staggered release, soul-motes, 6% push-in, NO roll
    st.unmake(0.09)
    _soul_motes(st, Tokens.affinity_color(_core_affinity(_me)))
    st.camera_push(0.06, 0.9)
    await _unmake_wait(0.64, gen)
    if _unmake_done(gen):
        return
    # D: total stillness and silence
    await _unmake_wait(0.30, gen)
    if _unmake_done(gen):
        return
    _unmake_active = false
    _parts_settle_beat()                # the pieces settle: gate releases, exit sound admitted
    _show_death_banner()

func _unmake_wait(dur: float, gen: int) -> void:
    var t := 0.0
    while t < dur:
        var step := minf(0.1, dur - t)
        await get_tree().create_timer(step).timeout
        if not is_inside_tree() or gen != _gen:
            return
        t += step
        if _unmake_skip:
            return

func _unmake_done(gen: int) -> bool:
    if not is_inside_tree() or gen != _gen:
        _unmake_active = false
        return true
    if _unmake_skip:
        # input-skip: jump to the dim end-state + banner
        _me_stage.soul_flare(0.0, 0.05)
        _me_stage.light_dim(0.55, 0.3, 0.05)
        _unmake_active = false
        _parts_settle_beat()            # skip still releases the gate through its one exit sound
        _show_death_banner()
        return true
    return false

func _show_death_banner() -> void:
    _banner.text = _banner_text(Combat.Result.DEATH)
    _banner.modulate.a = 0.0
    _banner.create_tween().tween_property(_banner, "modulate:a", 1.0, 0.2)

func _input(event: InputEvent) -> void:
    if not _unmake_active:
        return
    if Time.get_ticks_msec() - _unmake_t0 < 600:
        return
    if (event is InputEventMouseButton and event.pressed) or (event is InputEventKey and event.pressed):
        _unmake_skip = true

func _stagger_outcome_rows() -> void:
    if Juice.reduce_motion:
        return
    var i := 0
    for c in _moves_box.get_children():
        if c is Control:
            var ct := c as Control
            ct.modulate.a = 0.0
            var tw := ct.create_tween()
            tw.tween_interval(0.04 * float(i) + 0.01)
            tw.tween_property(ct, "modulate:a", 1.0, 0.12)
            i += 1

# === B2: combat presence (core hums), the peril STATE, and the R1 sustained peril visual ========
# Single-writer law honored: this lane calls ONLY the additive Sfx API (loop_*, duck_*, stillness);
# no lane but sfx.gd ever touches AudioServer bus volumes. Everything here is headless-inert through
# Sfx; the only side effects that run headless are node/label changes, which the smoke gates tolerate.

func _start_core_hums() -> void:
    # The combat room tone IS the two detuned core hums (there is deliberately no amb_combat bed):
    # me pitch 1.0 pan L, foe pitch 1.01 pan R. Each rides its own soul's display HP from frame one.
    if _hums_on:
        return
    _hums_on = true
    Sfx.loop_start(&"core_hum_me")
    Sfx.loop_start(&"core_hum_foe")
    _update_core_hums()

func _stop_core_hums(fade_s: float = 0.3) -> void:
    if not _hums_on:
        return
    _hums_on = false
    Sfx.loop_stop(&"core_hum_me", fade_s)
    Sfx.loop_stop(&"core_hum_foe", fade_s)

func _refresh_core_audio() -> void:
    # Called ONLY where a core's DISPLAY hp actually changed (per-hit recover on CORE, a core mend,
    # or the turn-boundary reconcile) - never per-frame. Each call is one bus tween, not a poll.
    _update_core_hums()
    _eval_peril()

func _update_core_hums() -> void:
    if not _hums_on:
        return
    Sfx.loop_gain(&"core_hum_me", _hum_db_for("me"))
    Sfx.loop_gain(&"core_hum_foe", _hum_db_for("foe"))

func _hum_db_for(side: String) -> float:
    # Full soul = the MANIFEST gain; the hum quietens smoothly toward silence as the core fades.
    return JT_HUM_FULL_DB + (1.0 - _core_ratio(side)) * JT_HUM_FADE_DB

func _core_ratio(side: String) -> float:
    var m := _state_for(side)
    var pi: PartInstance = m.slots.get("CORE") if m != null else null
    if pi == null or pi.data.max_hp <= 0:
        return 0.0
    var dd: Dictionary = _disp[side]
    var shown: int = int(dd.get("CORE", pi.current_hp))
    return clampf(float(shown) / float(pi.data.max_hp), 0.0, 1.0)

func _eval_peril() -> void:
    # Peril holds while YOUR soul's display ratio sits in (0, threshold) and the fight is live.
    # Zero HP is death, not peril; THE UNMAKING and the verdict force it off (never during unmaking).
    var want := false
    if _state != "over" and not _unmake_active and combat != null and combat.outcome() == Combat.Result.ONGOING:
        var r := _core_ratio("me")
        want = r > 0.0 and r < JT_PERIL_RATIO
    if want and not _peril_on:
        _enter_peril()
    elif not want and _peril_on:
        _exit_peril()

func _enter_peril() -> void:
    _peril_on = true
    Sfx.loop_start(&"peril_bed")         # the low sustained peril tone (Q9-sanctioned bed)
    Sfx.duck_claim(&"peril")             # peril ducks the ambience bed while it holds
    _apply_core_peril_tag()
    if not Juice.reduce_motion:
        _build_peril_vignette()          # the 2 Hz breathing edges (photosensitivity-capped)

func _exit_peril() -> void:
    _clear_peril_vignette()
    if not _peril_on:
        return
    _peril_on = false
    Sfx.loop_stop(&"peril_bed")
    Sfx.duck_release(&"peril")
    _apply_core_peril_tag()              # restores the me-core row tag to its calm state

func _apply_core_peril_tag() -> void:
    # The reduce-motion-safe half of R1: a STATIC high-contrast PERIL tag on your core row, so the
    # peril bed never carries the information alone. _style_row reads _peril_on and paints it.
    if _rows["me"].has("CORE"):
        _style_row("me", "CORE")

func _parts_settle_beat() -> void:
    # THE UNMAKING's only exit: the pieces come to rest, parts_settle sounds THROUGH the gate's
    # allowlist, and the stillness window is released. Guarded so it fires exactly once per death.
    if not _unmake_gate:
        return
    _unmake_gate = false
    Sfx.play(&"parts_settle")
    Sfx.stillness(false)

func _teardown_combat_audio() -> void:
    # A new fight or a screen exit must never leave a loop humming or the gate stuck closed.
    _stop_core_hums(0.0)
    _exit_peril()
    if _unmake_gate:
        _unmake_gate = false
        Sfx.stillness(false)

func _build_peril_vignette() -> void:
    # R1 sustained peril visual (motion half): four warm edge gradients in the PLAYER core's
    # affinity, held and breathed at JT_PERIL_HZ by _process. Small alpha swing, never strobing;
    # the four edges mirror the transient telegraph vignette, but sustained instead of one-shot.
    _clear_peril_vignette()
    if _fx == null:
        return
    var color := Tokens.affinity_color(_core_affinity(_me))
    var sz := _fx.size
    var w := sz.x * 0.12
    var h := sz.y * 0.16
    var edges := [
        {"rect": Rect2(Vector2.ZERO, Vector2(w, sz.y)), "from": Vector2(0.0, 0.5), "to": Vector2(1.0, 0.5)},
        {"rect": Rect2(Vector2(sz.x - w, 0), Vector2(w, sz.y)), "from": Vector2(1.0, 0.5), "to": Vector2(0.0, 0.5)},
        {"rect": Rect2(Vector2.ZERO, Vector2(sz.x, h)), "from": Vector2(0.5, 0.0), "to": Vector2(0.5, 1.0)},
        {"rect": Rect2(Vector2(0, sz.y - h), Vector2(sz.x, h)), "from": Vector2(0.5, 1.0), "to": Vector2(0.5, 0.0)},
    ]
    for ed in edges:
        var tr := TextureRect.new()
        var gt := GradientTexture2D.new()
        var g := Gradient.new()
        g.set_color(0, Color(color, 0.10))
        g.set_color(1, Color(color, 0.0))
        gt.gradient = g
        gt.fill_from = ed["from"]
        gt.fill_to = ed["to"]
        tr.texture = gt
        tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        tr.stretch_mode = TextureRect.STRETCH_SCALE
        tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
        var rc: Rect2 = ed["rect"]
        tr.position = rc.position
        tr.size = rc.size
        tr.modulate.a = JT_PERIL_VIG_BASE_A
        _fx.add_child(tr)
        _peril_edges.append(tr)

func _clear_peril_vignette() -> void:
    for e in _peril_edges:
        if e != null and is_instance_valid(e):
            e.queue_free()
    _peril_edges.clear()

func _process(_delta: float) -> void:
    # Drives ONLY the held peril vignette's 2 Hz breath (motion half of R1), sampling the same
    # engine clock the peril bed's AM rides. The static tag + audio carry the state when idle, so
    # reduce-motion loses nothing. Small warm swing, capped well under a strobe.
    if not _peril_on or Juice.reduce_motion or _peril_edges.is_empty():
        return
    var s := 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) / 1000.0 * TAU * JT_PERIL_HZ)
    var a := JT_PERIL_VIG_BASE_A + JT_PERIL_VIG_SWING_A * s
    for e in _peril_edges:
        if e != null and is_instance_valid(e):
            (e as CanvasItem).modulate.a = a

func _exit_tree() -> void:
    _teardown_combat_audio()

func _loot(pd: PartData) -> void:
    if _kit_run != null:
        # The bit rides the salvage (spillable on DEATH later this run) - not the collection yet.
        _kit_run.satchel_bit_id = String(pd.id)
        _resolved = true
        _banner.text = "You toss the %s into the box." % pd.display_name
        _refresh()
        return
    player.loot_part(pd)
    player.save()
    _resolved = true
    _banner.text = "You looted the %s - it's yours now." % pd.display_name
    _refresh()

func _forfeit(slot: String) -> void:
    var pi: PartInstance = _real_build.slots.get(slot)
    if pi == null:
        return
    _real_build.slots[slot] = null            # the bit is salvaged by the victor - gone from your build
    if _kit_run != null:
        # Never yours: worth ⚙0 to you. Kills throw-the-fight salvage farming.
        _resolved = true
        _banner.text = "The victor takes the %s - it was only scrap anyway." % pi.data.display_name
        _refresh()
        return
    if not _run_mode and _stakes:
        # Wave 1 CH-09: BOUT context (clone fight, _kit_run null, stakes on) pays ZERO salvage -
        # a survivable bout loss was strictly free melt income plus a free shot at loot.
        # Same precedent as the kit-run branch above. Own-build VENTURE forfeits (run_mode)
        # still pay salvage: there the bit came off your REAL build.
        _resolved = true
        _banner.text = "You forfeit the %s to the victor." % pi.data.display_name
        _refresh()
        return
    var sc := Broker.salvage_scrap(pi.data)
    player.scrap += sc
    player.save()
    _resolved = true
    _banner.text = "You forfeit the %s to the victor.  (＋⚙%d salvage)" % [pi.data.display_name, sc]
    _refresh()

# --- rendering: persistent HP rows (built once per fight; provably fixed row set) ---
func _build_rows(box: VBoxContainer, m: ManabitState, side: String) -> void:
    for c in box.get_children():
        c.queue_free()
    _rows[side] = {}
    _disp[side] = {}
    for slot in ManabitState.SLOT_NAMES:
        var pi: PartInstance = m.slots.get(slot)
        if pi == null:
            continue
        var row := HBoxContainer.new()
        row.add_theme_constant_override("separation", 6)
        var is_core := pi.data.is_core
        var tag := Label.new()
        tag.text = "%s %s" % [Tokens.slot_glyph(slot), ("CORE ❤" if is_core else pi.data.display_name)]
        tag.custom_minimum_size = Vector2(148, 0)
        tag.add_theme_font_size_override("font_size", 12)
        row.add_child(tag)
        var bar := ProgressBar.new()
        bar.custom_minimum_size = Vector2(120, 14)
        bar.min_value = 0
        bar.max_value = pi.data.max_hp
        bar.value = pi.current_hp
        bar.show_percentage = false
        row.add_child(bar)
        var hp := Label.new()
        hp.add_theme_font_size_override("font_size", 11)
        hp.add_theme_color_override("font_color", Color(Tokens.PARCHMENT, 0.7))
        row.add_child(hp)
        var btn: Button = null
        if side == "foe":
            btn = Button.new()                  # always created; visibility-toggled by targeting
            btn.text = "▸ hit"
            btn.visible = false
            btn.pressed.connect(_on_target.bind(slot))
            row.add_child(btn)
        box.add_child(row)
        _rows[side][slot] = {"row": row, "bar": bar, "hp": hp, "tag": tag, "btn": btn}
        _disp[side][slot] = pi.current_hp
        _update_row(side, slot, false)

func _state_for(side: String) -> ManabitState:
    return _me if side == "me" else _foe

func _core_affinity(m: ManabitState) -> String:
    var c: PartInstance = m.slots.get("CORE")
    return String(c.data.affinity) if c != null else "attack"

func _snap_disp() -> void:
    for side in ["me", "foe"]:
        var m := _state_for(String(side))
        var dd: Dictionary = _disp[side]
        var rowsd: Dictionary = _rows[side]
        for slot in rowsd:
            var pi: PartInstance = m.slots.get(slot)
            if pi != null:
                dd[slot] = pi.current_hp

func _update_row(side: String, slot: String, animate: bool, dur: float = JT_BAR_ROLL_S) -> void:
    var rowsd: Dictionary = _rows[side]
    var rd: Dictionary = rowsd.get(slot, {})
    if rd.is_empty():
        return
    var m := _state_for(side)
    var pi: PartInstance = m.slots.get(slot)
    if pi == null:
        return
    var dd: Dictionary = _disp[side]
    var shown: int = dd.get(slot, pi.current_hp)
    var bar: ProgressBar = rd["bar"]
    var key := side + "/" + slot
    var old: Tween = _row_tweens.get(key)
    if old != null and old.is_valid():
        old.kill()                            # odometer: interrupt from the shown value
    if animate and int(bar.value) != shown:
        var tw := bar.create_tween()          # created on the bar so it dies with it
        tw.tween_property(bar, "value", float(shown), dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
        _row_tweens[key] = tw
    else:
        bar.value = float(shown)
    var hp: Label = rd["hp"]
    hp.text = "%d/%d" % [shown, pi.data.max_hp]
    _style_row(side, slot)

func _style_row(side: String, slot: String) -> void:
    var rowsd: Dictionary = _rows[side]
    var rd: Dictionary = rowsd.get(slot, {})
    if rd.is_empty():
        return
    var m := _state_for(side)
    var pi: PartInstance = m.slots.get(slot)
    if pi == null:
        return
    var is_core := pi.data.is_core
    var tag: Label = rd["tag"]
    if is_core and side == "me":
        # R1 static peril tag: a non-pulsing, high-contrast warm marker on YOUR core row, so the
        # peril bed never carries the information alone (reduce-motion-safe equivalent of the breathe).
        var glyph := Tokens.slot_glyph(slot)
        tag.text = ("%s CORE ❤  PERIL" % glyph) if _peril_on else ("%s CORE ❤" % glyph)
        tag.add_theme_color_override("font_color", Tokens.WAX if _peril_on else Tokens.LAMP_KEY)
    else:
        tag.add_theme_color_override("font_color", Tokens.LAMP_KEY if is_core else (Color(Tokens.PARCHMENT, 0.35) if pi.disabled else Tokens.PARCHMENT))
    var bar: ProgressBar = rd["bar"]
    if is_core:
        bar.modulate = Tokens.affinity_color(_core_affinity(m))   # the soul color IS the stake - never STAT_ATK
    else:
        bar.modulate = Color(0.5, 0.5, 0.5) if pi.disabled else Tokens.STAT_SPD

func _set_targeting(on: bool) -> void:
    var allow := combat.targets_for(_foe, _pending["ability"]) if (on and _pending.has("ability")) else []
    var rowsd: Dictionary = _rows["foe"]
    for slot in rowsd:
        var rd: Dictionary = rowsd[slot]
        var btn: Button = rd["btn"]
        if btn != null:
            btn.visible = on and allow.has(slot)

# FULL refresh: stages sync + display snapshot + all rows - turn boundaries and outcomes only.
func _refresh() -> void:
    if _me == null:
        return
    _me_stage.sync(_me)
    _foe_stage.sync(_foe)
    _snap_disp()
    for side in ["me", "foe"]:
        var rowsd: Dictionary = _rows[side]
        for slot in rowsd:
            _update_row(String(side), String(slot), false)
    _log_shown = combat.battle_log.size()
    _refresh_hud()

# HUD-only refresh: moves/targeting/log/turn label - safe mid-playback, never rebuilds a stage.
func _refresh_hud() -> void:
    if _me == null:
        return
    _set_targeting(_state == "choose_target")
    _fill_moves()
    _update_log()
    if _state == "over":
        _turn_label.text = ""
    elif _state == "choose_target":
        _turn_label.text = "Choose a part to strike  -  ✦ %d mana" % _me.mana
    elif combat.current() == _me and _state != "busy":
        _turn_label.text = "Your turn  -  ✦ %d mana" % _me.mana
    else:
        _turn_label.text = "…"

func _aftermath() -> void:
    # truth wins at every turn boundary: reconcile display to the resolver, animated
    _me_stage.sync(_me)
    _foe_stage.sync(_foe)
    _snap_disp()
    for side in ["me", "foe"]:
        var rowsd: Dictionary = _rows[side]
        for slot in rowsd:
            _update_row(String(side), String(slot), true)
    _log_shown = combat.battle_log.size()
    _update_log()
    _refresh_core_audio()               # turn boundary: reconcile hums + peril to the resolver truth

func _update_log() -> void:
    var upto := mini(_log_shown, combat.battle_log.size())
    _log_label.text = "\n".join(_tail(combat.battle_log.slice(0, upto), 5))

func _reveal_log_line() -> void:
    if _log_shown < combat.battle_log.size():
        _log_shown += 1
        _update_log()

func _fill_moves() -> void:
    for c in _moves_box.get_children():
        c.queue_free()
    if _state == "over":
        _fill_outcome()
        return
    if _state == "choose_target":
        _moves_box.add_child(_lbl("  ↳ pick a target part on the foe →", Tokens.LAMP_KEY))
        var cancel := Button.new()
        cancel.text = "cancel"
        cancel.pressed.connect(func(): _pending = {}; _state = "choose_move"; _refresh_hud())
        _moves_box.add_child(cancel)
        return
    if _state != "choose_move":
        return
    var moves := combat.moves_for(_me)
    if moves.is_empty():
        _moves_box.add_child(_lbl("  No move you can afford - mana returns each turn.", Color(Tokens.PARCHMENT, 0.6)))
        var w := Button.new()
        w.text = "Wait"
        w.pressed.connect(_wait_turn)   # StalemateBreaker: a wait bypasses _apply, so count it here
        _moves_box.add_child(w)
        return
    for mv in moves:
        var a: AbilityData = mv["ability"]
        var part: PartInstance = mv["part"]
        var b := Button.new()
        var cost := "  ✦%d" % a.mana_cost if a.mana_cost > 0 else ""
        b.text = "%s · %s%s" % [a.archetype, part.data.display_name, cost]
        b.pressed.connect(_on_move.bind(mv))
        _moves_box.add_child(b)

func _fill_outcome() -> void:
    if _stalemate:
        # Soft called-draw: SKIP the forfeit list entirely (both cores alive, nothing earned, and a
        # pure guard stall breaks no part to forfeit). Just the called-draw line + the end button.
        _moves_box.add_child(_lbl("Nobody landed the finish - no bits change hands.", Tokens.LAMP_KEY))
        _moves_box.add_child(_end_button())
        return
    if _outcome == Combat.Result.DEATH or not _stakes or _resolved:
        _moves_box.add_child(_end_button())
        return
    if _outcome == Combat.Result.WIN:
        var kit_capped := _kit_run != null
        var rows := 0
        # The box's loot rights: COMMON only, and only while the salvage has no bit yet this run.
        var kit_may_loot := kit_capped and _kit_run.satchel_bit_id == ""
        for slot in ManabitState.SLOT_NAMES:
            var pi: PartInstance = _foe.slots.get(slot)
            if pi == null or pi.data.is_core:
                continue
            if kit_capped and (not kit_may_loot or pi.data.rarity != "COMMON"):
                continue
            if rows == 0:
                _moves_box.add_child(_lbl("Grab one for the box:" if kit_capped else "Loot a part:", Tokens.LAMP_KEY))
            rows += 1
            var b := Button.new()
            b.text = "%s %s" % [Tokens.slot_glyph(slot), pi.data.display_name]
            b.pressed.connect(_loot.bind(pi.data))
            _moves_box.add_child(b)
        if rows == 0:
            if kit_capped:
                _moves_box.add_child(_lbl("The purse goes to your salvage.", Color(Tokens.PARCHMENT, 0.7)))
            _moves_box.add_child(_end_button())
    else:
        _moves_box.add_child(_lbl("Forfeit a broken part:", Tokens.LAMP_KEY))
        var any := false
        for slot in ManabitState.SLOT_NAMES:
            if slot == "CORE":
                continue
            var mine: PartInstance = _me.slots.get(slot)
            var real: PartInstance = _real_build.slots.get(slot) if _real_build != null else null
            if mine != null and mine.disabled and real != null:
                any = true
                var b := Button.new()
                if _kit_run != null:
                    b.text = "%s %s (not yours - ⚙0)" % [Tokens.slot_glyph(slot), real.data.display_name]
                elif not _run_mode:
                    # bout forfeit pays zero salvage (CH-09) - promise nothing
                    b.text = "%s %s" % [Tokens.slot_glyph(slot), real.data.display_name]
                else:
                    b.text = "%s %s (+⚙%d)" % [Tokens.slot_glyph(slot), real.data.display_name, Broker.salvage_scrap(real.data)]
                b.pressed.connect(_forfeit.bind(slot))
                _moves_box.add_child(b)
        if not any:
            _moves_box.add_child(_end_button())

func _end_button() -> Button:
    var b := Button.new()
    b.text = "Continue  ▸" if _run_mode else "◂  Back to the Workshop"
    b.pressed.connect(func(): done.emit())
    return b

# --- helpers ---
func _clone(src: ManabitState) -> ManabitState:
    var m := ManabitState.new()
    for slot in ManabitState.SLOT_NAMES:
        var pi: PartInstance = src.slots.get(slot)
        m.slots[slot] = PartInstance.new(pi.data) if pi != null else null
    return m

func _make_dummy() -> ManabitState:
    var cat := Catalog.by_id()
    var m := ManabitState.new()
    m.slots["CORE"] = PartInstance.new(cat["core_bulwark"])
    m.slots["ARM_R"] = PartInstance.new(cat["arm_buckler"])
    m.slots["HEAD"] = PartInstance.new(cat["head_optic"])
    m.slots["LEGS"] = PartInstance.new(cat["legs_light"])
    return m

func _lbl(text: String, color: Color) -> Label:
    var l := Label.new()
    l.text = text
    l.add_theme_color_override("font_color", color)
    return l

func _pnl(fill: Color) -> StyleBoxFlat:
    var sb := StyleBoxFlat.new()
    sb.bg_color = fill
    sb.set_corner_radius_all(8)
    sb.content_margin_left = 12
    sb.content_margin_right = 12
    sb.content_margin_top = 8
    sb.content_margin_bottom = 8
    return sb

func _tail(arr: Array, n: int) -> Array:
    return arr.slice(maxi(0, arr.size() - n), arr.size())

# For the screenshot harness.
func debug_autostep() -> void:
    _auto_btn.button_pressed = true
