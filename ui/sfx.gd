class_name Sfx extends RefCounted
# DESIGN.md §5 SFX seams - LIVE as of the combat-juice push (2026-07-18).
# Combat foley is procedurally synthesized (tools/audio/make_sfx.py, seed 7) into
# res://audio/sfx/. Files are peak-normalized to -3 dBFS; ALL mix gain lives in MANIFEST
# below, so the mix re-tunes without regenerating.
#
# Contract:
#   - play(seam, pitch, pan): all pre-existing 1-arg call sites compile untouched.
#   - UNKNOWN SEAM or MISSING FILE = SILENT NO-OP (one push_warning per seam in debug) -
#     workshop/chest/broker seams stay quietly waiting for the wave-2 foley pack.
#   - Headless = inert forever (gates untouched).
#   - Buses Sfx / SfxBig created in code (no bus layout file); SfxBig plays duck the Sfx
#     bus -4 dB (hold 120ms, recover 180ms, REF-COUNTED so break chains never stick).
#   - Voice steal = longest-playing; per-seam poly cap + cooldown kills same-frame doubles;
#     round-robin variants with no-immediate-repeat.
#   - pan is quantized to three code-created panner sub-buses (L/-0.25, center, R/+0.25) -
#     exactly the values combat passes.

static var muted := false            # the master switch - flipping this false was the go-live

# Every seam the game is allowed to reference. smoke_audio asserts each combat play() site
# uses one of these - catches &"hit_corre" typos the day they are written.
static var KNOWN_SEAMS: Array[StringName] = [
    # combat canon (this push - files shipped)
    &"hit", &"hit_core", &"part_break", &"invalid_clunk", &"attack_whoosh", &"guard_up",
    &"mend", &"core_peril", &"victory_chord", &"loss_settle", &"death_winddown",
    # bench / chest / broker / run seams (wired, awaiting wave-2 foley - silent no-ops)
    &"core_wake", &"snap", &"seal_channel", &"seal_crack", &"lid_spring",
    &"reveal_common", &"reveal_rare", &"reveal_epic", &"route_step", &"fork_reveal",
    &"switch_throw", &"ledger_open", &"fettle_greet", &"wax_stamp", &"fettle_appraise",
    &"doorstep_untie", &"forge_melt", &"still_drip", &"coin_scrap",
    # audio wave 4a (audio-full-game.md groups 2-4): BIND flow + furniture + UI micro +
    # the Q8 bookkeeping fix. Canonical name is parts_settle - NEVER part_settle (Q2 ruling).
    &"bind_press", &"bound_chord", &"drawer_slide", &"drawer_tuck", &"medallion_tap",
    &"ui_tap", &"ink_wipe", &"tag_untie", &"inspect_open", &"inspect_close", &"toast_pin",
    &"box_crack", &"grade_reveal", &"parts_settle", &"fettle_apologise",
    # audio wave 4b (audio-full-game.md groups 5-7): the sustained/looped layer. These are
    # PRE-REGISTERED by Foundation lane A so the Wire lanes never touch sfx.gd; their wavs are
    # rendered in parallel by lane C (make_sfx.py) and land in res://audio/sfx/. Loop/stem seams
    # play via loop_start(), NEVER play() (guarded below). Rows carry "pending": true so the
    # smoke gate is pending-tolerant until lane C's files land (then it auto-strictens).
    #   ambience beds (group 5): amb_nook reuses the workshop bed at -6 dB; combat has NO bed
    #   (its room tone IS the two core hums, group 5 wiring-only row), so amb_combat is absent.
    &"amb_workshop", &"amb_nook", &"amb_barrow", &"amb_run",
    #   state loops (group 7): one soul hum; core_hum is a pre-detuned PAIR (me = core_hum_0 pan L,
    #   foe = core_hum_1 pan R = two souls, not one); peril_bed is the promoted core_peril STATE.
    &"soul_hum", &"core_hum_me", &"core_hum_foe", &"peril_bed",
    #   music stems (group 6, The Wound Spring bench motif): B3 mixes them via
    #   AudioStreamSynchronized, but their Music/MusicDuck bus + duck plumbing is lane A's.
    &"mus_bench_melody", &"mus_bench_bells", &"mus_bench_pad", &"mus_bench_pulse",
]

# Outcome punctuation plays straight - no pitch humanize.
const OUTCOME_SEAMS := [&"victory_chord", &"loss_settle", &"death_winddown"]

# wave-4b loop directories (declared before MANIFEST so the const dict can reference them).
const AMB_DIR := "res://audio/ambience/"   # ambience beds + state loops (hums, peril bed)
const MUS_DIR := "res://audio/music/"      # Wound Spring stems (documentary rows; music_box loads directly)

# seam -> {files, bus, gain_db, poly, cooldown_ms}   (the MIX TABLE)
const MANIFEST := {
    &"hit":            {"files": ["hit_0", "hit_1", "hit_2"], "bus": "Sfx", "gain_db": -6.0, "poly": 3, "cooldown_ms": 40},
    &"attack_whoosh":  {"files": ["attack_whoosh_0"], "bus": "Sfx", "gain_db": -12.0, "poly": 2, "cooldown_ms": 80},
    &"guard_up":       {"files": ["guard_up_0"], "bus": "Sfx", "gain_db": -8.0, "poly": 1, "cooldown_ms": 100},
    &"mend":           {"files": ["mend_0"], "bus": "Sfx", "gain_db": -8.0, "poly": 1, "cooldown_ms": 100},
    &"invalid_clunk":  {"files": ["invalid_clunk_0"], "bus": "Sfx", "gain_db": -8.0, "poly": 1, "cooldown_ms": 120},
    &"core_peril":     {"files": ["core_peril_0"], "bus": "Sfx", "gain_db": -18.0, "poly": 1, "cooldown_ms": 400},
    &"hit_core":       {"files": ["hit_core_0"], "bus": "SfxBig", "gain_db": -3.0, "poly": 2, "cooldown_ms": 60},
    &"part_break":     {"files": ["part_break_0", "part_break_1"], "bus": "SfxBig", "gain_db": -4.0, "poly": 2, "cooldown_ms": 60},
    &"victory_chord":  {"files": ["victory_chord_0"], "bus": "SfxBig", "gain_db": -6.0, "poly": 1, "cooldown_ms": 500},
    &"loss_settle":    {"files": ["loss_settle_0"], "bus": "SfxBig", "gain_db": -10.0, "poly": 1, "cooldown_ms": 500},
    &"death_winddown": {"files": ["death_winddown_0"], "bus": "SfxBig", "gain_db": -6.0, "poly": 1, "cooldown_ms": 500},
    # --- wave 4a P0 foley (audio-full-game.md section 2; gains = inventory Vol column;
    # "jitter" = per-seam pitch humanize, 0.0 for hero/ritual/reveal rows which play straight.
    # Filenames are the synthesis lane's canon; smoke_audio asserts each resolves on disk.
    # UI-tier rows (medallion_tap, ui_tap) ride the Sfx bus until the wave-4b Ui bus lands. ---
    &"core_wake":      {"files": ["core_wake_0"], "bus": "Sfx", "gain_db": -8.0, "poly": 1, "cooldown_ms": 250, "jitter": 0.0},
    &"snap":           {"files": ["snap_0", "snap_1"], "bus": "SfxBig", "gain_db": -3.0, "poly": 2, "cooldown_ms": 40, "jitter": 0.0},
    &"seal_channel":   {"files": ["seal_channel_0"], "bus": "Sfx", "gain_db": -8.0, "poly": 1, "cooldown_ms": 300, "jitter": 0.0},
    &"seal_crack":     {"files": ["seal_crack_0"], "bus": "SfxBig", "gain_db": -4.0, "poly": 1, "cooldown_ms": 200, "jitter": 0.0},
    &"lid_spring":     {"files": ["lid_spring_0"], "bus": "Sfx", "gain_db": -10.0, "poly": 1, "cooldown_ms": 150, "jitter": 0.02},
    &"reveal_common":  {"files": ["reveal_common_0"], "bus": "Sfx", "gain_db": -8.0, "poly": 2, "cooldown_ms": 100, "jitter": 0.0},
    &"reveal_rare":    {"files": ["reveal_rare_0"], "bus": "Sfx", "gain_db": -6.0, "poly": 2, "cooldown_ms": 100, "jitter": 0.0},
    &"reveal_epic":    {"files": ["reveal_epic_0"], "bus": "SfxBig", "gain_db": -4.0, "poly": 1, "cooldown_ms": 300, "jitter": 0.0},
    &"route_step":     {"files": ["route_step_0", "route_step_1"], "bus": "Sfx", "gain_db": -10.0, "poly": 2, "cooldown_ms": 80, "jitter": 0.03},
    &"fork_reveal":    {"files": ["fork_reveal_0"], "bus": "Sfx", "gain_db": -12.0, "poly": 1, "cooldown_ms": 200, "jitter": 0.02},
    &"switch_throw":   {"files": ["switch_throw_0"], "bus": "Sfx", "gain_db": -6.0, "poly": 1, "cooldown_ms": 150, "jitter": 0.02},
    &"wax_stamp":      {"files": ["wax_stamp_0"], "bus": "SfxBig", "gain_db": -6.0, "poly": 1, "cooldown_ms": 250, "jitter": 0.0},
    &"still_drip":     {"files": ["still_drip_0", "still_drip_1", "still_drip_2"], "bus": "Sfx", "gain_db": -10.0, "poly": 2, "cooldown_ms": 60, "jitter": 0.06},
    &"coin_scrap":     {"files": ["coin_scrap_0", "coin_scrap_1"], "bus": "Sfx", "gain_db": -12.0, "poly": 2, "cooldown_ms": 80, "jitter": 0.03},
    &"bind_press":     {"files": ["bind_press_0"], "bus": "Sfx", "gain_db": -6.0, "poly": 1, "cooldown_ms": 300, "jitter": 0.0},
    &"bound_chord":    {"files": ["bound_chord_0"], "bus": "SfxBig", "gain_db": -4.0, "poly": 1, "cooldown_ms": 500, "jitter": 0.0},
    &"drawer_slide":   {"files": ["drawer_slide_0"], "bus": "Sfx", "gain_db": -10.0, "poly": 1, "cooldown_ms": 120, "jitter": 0.03},
    &"drawer_tuck":    {"files": ["drawer_tuck_0"], "bus": "Sfx", "gain_db": -10.0, "poly": 1, "cooldown_ms": 120, "jitter": 0.03},
    # UI-tier gain math (verifier fix, wave 4a): these files are peak-normalized to -12 dBFS
    # in-file per the tech-plan UI law, but the inventory Vol column assumed -3 dBFS files.
    # gain_db = inventory Vol + 9 so the effective level matches the ratified spec.
    # UI-tier one-shots rehomed Sfx -> Ui now that the wave-4b Ui bus exists (the wave-4a note
    # promised medallion_tap/ui_tap would move when it landed). Effective loudness is unchanged
    # (Ui -> SFX -> Master at 0 trim, same as Sfx -> SFX -> Master); the win is the stillness gate
    # now mutes tap tails structurally. Ui seams never pass pan (no Ui panner sub-buses).
    &"medallion_tap":  {"files": ["medallion_tap_0", "medallion_tap_1"], "bus": "Ui", "gain_db": -3.0, "poly": 2, "cooldown_ms": 60, "jitter": 0.02},
    &"ui_tap":         {"files": ["ui_tap_0", "ui_tap_1"], "bus": "Ui", "gain_db": -7.0, "poly": 2, "cooldown_ms": 50, "jitter": 0.05},
    &"parts_settle":   {"files": ["parts_settle_0", "parts_settle_1"], "bus": "Sfx", "gain_db": -12.0, "poly": 1, "cooldown_ms": 400, "jitter": 0.03},
    &"fettle_apologise": {"files": ["fettle_apologise_0"], "bus": "Sfx", "gain_db": -12.0, "poly": 1, "cooldown_ms": 300, "jitter": 0.02},
    # --- P1 rows whose wavs the synthesis lane landed early (call sites were already live;
    # a produced file never sits unmapped). Parchment-tier files ship at -12 dBFS peak. ---
    &"ledger_open":    {"files": ["ledger_open_0"], "bus": "Ui", "gain_db": -5.0, "poly": 1, "cooldown_ms": 300, "jitter": 0.05},  # -12 dBFS file, Vol -14 + 9
    &"fettle_greet":   {"files": ["fettle_greet_0"], "bus": "Sfx", "gain_db": -10.0, "poly": 1, "cooldown_ms": 400, "jitter": 0.02},
    &"fettle_appraise": {"files": ["fettle_appraise_0"], "bus": "Sfx", "gain_db": -12.0, "poly": 1, "cooldown_ms": 200, "jitter": 0.02},
    &"doorstep_untie": {"files": ["doorstep_untie_0"], "bus": "Sfx", "gain_db": -10.0, "poly": 1, "cooldown_ms": 300, "jitter": 0.05},
    &"forge_melt":     {"files": ["forge_melt_0"], "bus": "Sfx", "gain_db": -8.0, "poly": 1, "cooldown_ms": 300, "jitter": 0.03},
    &"ink_wipe":       {"files": ["ink_wipe_0"], "bus": "Ui", "gain_db": -7.0, "poly": 1, "cooldown_ms": 150, "jitter": 0.05},  # -12 dBFS file, Vol -16 + 9
    &"tag_untie":      {"files": ["tag_untie_0"], "bus": "Sfx", "gain_db": -10.0, "poly": 1, "cooldown_ms": 500, "jitter": 0.0},
    &"toast_pin":      {"files": ["toast_pin_0"], "bus": "Ui", "gain_db": -5.0, "poly": 2, "cooldown_ms": 120, "jitter": 0.05},  # -12 dBFS file, Vol -14 + 9
    # --- wave 4b loop/stem rows (groups 5-7). "loop": true => routed via loop_start(), not the
    # one-shot pool. "pending": true => smoke gate is file-tolerant until lane C renders the wav.
    # Gains are the inventory Vol column (player-volume trims; category LUFS lives on the buses).
    # Ambience beds + state hums live on AmbDuck (ducked by peril/ritual, muted by the gate via
    # Ambience). Music stems live on MusicDuck (ducked by hero/ritual, muted by the gate via Music).
    # wave-4b loops live in audio/ambience/ (dir key); core_hum ships as a pre-detuned PAIR
    # (core_hum_0 = 110 Hz, core_hum_1 = 111 Hz), so no runtime pitch detune. amb_nook bakes
    # the -6 dB into the file (peak -24 vs workshop -18), so its gain matches workshop's -38.
    &"amb_workshop":      {"files": ["amb_workshop"], "dir": AMB_DIR, "bus": "AmbDuck",  "gain_db": -38.0, "loop": true},
    &"amb_nook":          {"files": ["amb_nook"],     "dir": AMB_DIR, "bus": "AmbDuck",  "gain_db": -38.0, "loop": true},  # -6 dB baked into the file
    &"amb_barrow":        {"files": ["amb_barrow"],   "dir": AMB_DIR, "bus": "AmbDuck",  "gain_db": -36.0, "loop": true},
    &"amb_run":           {"files": ["amb_run"],      "dir": AMB_DIR, "bus": "AmbDuck",  "gain_db": -36.0, "loop": true},
    &"soul_hum":          {"files": ["soul_hum"],     "dir": AMB_DIR, "bus": "AmbDuck",  "gain_db": -30.0, "loop": true},
    &"core_hum_me":       {"files": ["core_hum_0"],   "dir": AMB_DIR, "bus": "AmbDuck",  "gain_db": -32.0, "loop": true, "pan": -0.25},
    &"core_hum_foe":      {"files": ["core_hum_1"],   "dir": AMB_DIR, "bus": "AmbDuck",  "gain_db": -32.0, "loop": true, "pan": 0.25},
    &"peril_bed":         {"files": ["peril_bed"],    "dir": AMB_DIR, "bus": "AmbDuck",  "gain_db": -26.0, "loop": true},  # Q9 sanctioned exception, capped -26
    # music stems live in audio/music/; documentary rows - music_box.gd loads them directly.
    &"mus_bench_melody":  {"files": ["mus_bench_melody"], "dir": MUS_DIR, "bus": "MusicDuck", "gain_db": 0.0, "loop": true},
    &"mus_bench_bells":   {"files": ["mus_bench_bells"],  "dir": MUS_DIR, "bus": "MusicDuck", "gain_db": 0.0, "loop": true},
    &"mus_bench_pad":     {"files": ["mus_bench_pad"],    "dir": MUS_DIR, "bus": "MusicDuck", "gain_db": 0.0, "loop": true},
    &"mus_bench_pulse":   {"files": ["mus_bench_pulse"],  "dir": MUS_DIR, "bus": "MusicDuck", "gain_db": 0.0, "loop": true},
}

const AUDIO_DIR := "res://audio/sfx/"
const VOICES := 8
const DUCK_DB := -4.0
const DUCK_HOLD_S := 0.12
const DUCK_RECOVER_S := 0.18

static var _inert := false
static var _checked_headless := false
static var _pool: Node = null
static var _players: Array = []
static var _streams := {}            # file base -> AudioStream (lazy cache)
static var _last_play := {}          # seam -> ticks ms
static var _last_variant := {}       # seam -> last file index (no-immediate-repeat)
static var _warned := {}
static var _duck_holds := 0
static var _duck_tween: Tween = null

# --- wave 4b: full bus tree + duck engine + stillness gate + loop players + settings sliders ---
# Bus tree (all code-created, no default_bus_layout.tres; parents FIRST so every send resolves):
#   Master
#     Music / MusicDuck            MusicDuck = duck tween target; B3's stem player lives here
#     Ambience / AmbDuck (+PanL/R) AmbDuck  = duck tween target; beds / hums / peril players here
#     SFX                          the SFX slider covers everything below it
#       Sfx (+PanL/R)              existing pool bus; internal SfxBig->Sfx -4 dB duck target
#       SfxBig (+PanL/R)           hero + outcome punctuation; THE DEATH CHANNEL - never gate-muted
#       Ui                         UI micro seams; gate-muted; rides the SFX slider for free
# SINGLE-WRITER LAW: AudioServer.set_bus_volume_db / set_bus_mute are called ONLY inside this file.
# Wire lanes B1/B2/B3 use the additive API (loop_start/loop_stop/loop_gain, duck_claim/duck_release,
# stillness, set_bus_volume/get_bus_volume) and never touch AudioServer bus volumes themselves.
const BUSES := [
    {"name": "Music",       "send": "Master",   "pan": 0.0},
    {"name": "MusicDuck",   "send": "Music",    "pan": 0.0},
    {"name": "Ambience",    "send": "Master",   "pan": 0.0},
    {"name": "AmbDuck",     "send": "Ambience", "pan": 0.0},
    {"name": "AmbDuckPanL", "send": "AmbDuck",  "pan": -0.25},
    {"name": "AmbDuckPanR", "send": "AmbDuck",  "pan": 0.25},
    {"name": "SFX",         "send": "Master",   "pan": 0.0},
    {"name": "Sfx",         "send": "SFX",      "pan": 0.0},
    {"name": "SfxPanL",     "send": "Sfx",      "pan": -0.25},
    {"name": "SfxPanR",     "send": "Sfx",      "pan": 0.25},
    {"name": "SfxBig",      "send": "SFX",      "pan": 0.0},
    {"name": "SfxBigPanL",  "send": "SfxBig",   "pan": -0.25},
    {"name": "SfxBigPanR",  "send": "SfxBig",   "pan": 0.25},
    {"name": "Ui",          "send": "SFX",      "pan": 0.0},
]

# The four ducking relationships as ref-counted deterministic bus tweens (DEEPEST-WINS per bus,
# never summed: two -6 claims give -6). Relationship 4 (THE UNMAKING) is the stillness gate, NOT a
# duck - a different mechanism (mute flag). The melody-stem-mute half of peril is B3's stem target
# change, not a bus duck, so it is not modeled here.
#   hero   = hero SFX duck Music -6 dB (auto-timed inside play() for HERO_SEAMS, ref-counted)
#   peril  = peril state ducks Ambience -6 dB (state-held: duck_claim on entry, release on mend/kill)
#   ritual = seal / BIND / epic-hold duck BOTH Music and Ambience -6 dB (state-held)
const DUCK_RULES := {
    &"hero":   {"targets": ["MusicDuck"],            "depth": -6.0, "attack_ms": 50,  "release_ms": 400},
    &"peril":  {"targets": ["AmbDuck"],              "depth": -6.0, "attack_ms": 120, "release_ms": 1000},
    &"ritual": {"targets": ["MusicDuck", "AmbDuck"], "depth": -6.0, "attack_ms": 80,  "release_ms": 400},
}
const HERO_PROTECT_MS := 250

# Hero seams trigger the Music duck AND get pool-steal protection (a hero voice younger than
# HERO_PROTECT_MS is unstealable by a non-hero seam - the snap always finishes its moment).
# Q3 IS OPEN: the sfx-spec omits hit_core / part_break and adds binding_strike / box_crack; this
# follows tech-plan T10 (combat-feel set). The audio-director flips this one constant to re-decide.
const HERO_SEAMS: Array[StringName] = [
    &"snap", &"seal_crack", &"reveal_epic", &"wax_stamp", &"bound_chord",
    &"victory_chord", &"hit_core", &"part_break",
]

# THE STILLNESS GATE allowlist. parts_settle is CANONICAL (NEVER part_settle - Q2 ruling): if the
# allowlist and the seam registration disagreed by one letter the gate would refuse its own exit
# sound and THE UNMAKING would deadlock silent. While the gate is closed, play() refuses EVERY seam
# except these three - the death channel (death_winddown, loss_settle: both on SfxBig, which is
# never muted) plus the sanctioned exit sound (parts_settle, on Sfx). Released ONLY by an explicit
# stillness(false) call - the parts-settle beat, owned by the combat beat planner (lane B2).
const GATE_ALLOW: Array[StringName] = [&"death_winddown", &"parts_settle", &"loss_settle"]
const GATE_BUSES := ["Music", "Ambience", "Ui"]   # muted while closed; SfxBig + Sfx stay live

static var _stillness_on := false
static var _duck_refs := {&"hero": 0, &"peril": 0, &"ritual": 0}
static var _duck_bus_tweens := {}    # bus name -> Tween (exactly one per duck bus)
static var _loops := {}              # seam -> AudioStreamPlayer (dedicated loop / stem player)
static var _loop_tweens := {}        # seam -> Tween
static var _user_frac := {}          # bus -> last linear slider value (get_bus_volume returns this)
static var _user_db := {}            # bus -> resolved volume_db from the perceptual taper
static var _user_muted := {}         # bus -> user mute flag (gate release restores THIS, not false)

static func play(seam, pitch: float = 1.0, pan: float = 0.0) -> void:
    if muted:
        return
    if not _live():
        return
    var sn := StringName(seam)
    if not gate_allows(sn):
        return              # THE UNMAKING stillness gate refuses every non-death-channel seam
    if not KNOWN_SEAMS.has(sn):
        _warn_once(sn, "unknown seam")
        return
    if not MANIFEST.has(sn):
        return              # known seam, no foley yet (wave 2) - silent no-op by design
    var m: Dictionary = MANIFEST[sn]
    if m.get("loop", false):
        return              # loop / stem seams play via loop_start(), never the one-shot pool
    var now := Time.get_ticks_msec()
    var last: int = _last_play.get(sn, -100000)
    if now - last < int(m["cooldown_ms"]):
        return
    var stream := _stream_for_variant(sn, m)
    if stream == null:
        _warn_once(sn, "missing file")
        return
    _ensure_pool()
    if _pool == null or not _pool.is_inside_tree():
        return              # first-frame plays before the pool lands are dropped, never crash
    var p := _grab_voice(sn, int(m["poly"]))
    if p == null:
        return
    _last_play[sn] = now
    var bus := String(m["bus"])
    if bus == "Sfx" or bus == "SfxBig":   # only these two tiers have panner sub-buses; Ui rides center
        if pan < -0.05:
            bus += "PanL"
        elif pan > 0.05:
            bus += "PanR"
    if not OUTCOME_SEAMS.has(sn):
        var jit := float(m.get("jitter", 0.04))   # per-seam humanize; hero/ritual rows pin 0.0
        if jit > 0.0:
            pitch *= 1.0 + randf_range(-jit, jit)  # punctuation + hero + ritual play straight
    p.stream = stream
    p.bus = bus
    p.volume_db = float(m["gain_db"])
    p.pitch_scale = clampf(pitch, 0.5, 2.0)
    p.set_meta("seam", sn)
    p.set_meta("started", now)
    p.set_meta("hero", HERO_SEAMS.has(sn))
    p.play()
    if String(m["bus"]) == "SfxBig":
        _duck()
    if HERO_SEAMS.has(sn):
        _hero_duck()        # duck Music -6 dB, ref-counted, auto-release after HERO_PROTECT_MS

# QA registry: the stream a seam would play (first variant), or null while silent.
static func stream_for(seam) -> AudioStream:
    if muted:
        return null
    var sn := StringName(seam)
    if not MANIFEST.has(sn):
        return null
    var m: Dictionary = MANIFEST[sn]
    var files: Array = m["files"]
    if files.is_empty():
        return null
    return _load_stream(String(files[0]), m.get("dir", AUDIO_DIR))

# --- internals --------------------------------------------------------------------------
static func _warn_once(sn: StringName, why: String) -> void:
    if _warned.has(sn):
        return
    _warned[sn] = true
    if OS.is_debug_build():
        push_warning("Sfx: %s (%s) - silent no-op" % [String(sn), why])

static func _load_stream(base: String, dir: String = AUDIO_DIR) -> AudioStream:
    var key := dir + base
    if _streams.has(key):
        return _streams[key]
    var path := dir + base + ".wav"
    if not ResourceLoader.exists(path):
        return null
    var st = load(path)
    if st is AudioStream:
        _streams[key] = st
        return st
    return null

static func _stream_for_variant(sn: StringName, m: Dictionary) -> AudioStream:
    var files: Array = m["files"]
    if files.is_empty():
        return null
    var idx := 0
    if files.size() > 1:
        var last: int = _last_variant.get(sn, -1)
        idx = randi() % files.size()
        if idx == last:
            idx = (idx + 1) % files.size()     # round-robin-ish, no immediate repeat
    _last_variant[sn] = idx
    return _load_stream(String(files[idx]), m.get("dir", AUDIO_DIR))

static func _ensure_pool() -> void:
    if _pool != null and is_instance_valid(_pool):
        return
    var ml := Engine.get_main_loop()
    if not (ml is SceneTree):
        return
    var tree := ml as SceneTree
    _ensure_buses()
    _pool = Node.new()
    _pool.name = "SfxPool"
    _players = []
    for i in VOICES:
        var p := AudioStreamPlayer.new()
        p.bus = "Sfx"
        _pool.add_child(p)
        _players.append(p)
    tree.root.add_child.call_deferred(_pool)

static func _ensure_buses() -> void:
    # Idempotent, parents-first (the BUSES table is ordered so every send target already exists).
    # Buses are code-created fresh every run, so the Sfx/SfxBig reparent SFX<-Master is just a table
    # ordering, never a data migration.
    for spec in BUSES:
        _make_bus(String(spec["name"]), String(spec["send"]), float(spec["pan"]))

static func _make_bus(bus_name: String, send_to: String, pan: float) -> void:
    if AudioServer.get_bus_index(bus_name) != -1:
        return
    var idx := AudioServer.bus_count
    AudioServer.add_bus(idx)
    AudioServer.set_bus_name(idx, bus_name)
    AudioServer.set_bus_send(idx, send_to)
    if absf(pan) > 0.01:
        var fx := AudioEffectPanner.new()
        fx.pan = pan
        AudioServer.add_bus_effect(idx, fx)

static func _grab_voice(sn: StringName, poly: int) -> AudioStreamPlayer:
    # per-seam poly cap: steal the oldest voice of this seam when at cap
    # hero protection: a HERO_SEAMS voice younger than HERO_PROTECT_MS is UNSTEALABLE by a non-hero
    # seam (the snap always finishes its moment); heroes still steal exactly as before.
    var now := Time.get_ticks_msec()
    var incoming_hero := HERO_SEAMS.has(sn)
    var same: Array = []
    var free: AudioStreamPlayer = null
    var oldest: AudioStreamPlayer = null
    var oldest_t := 1 << 62
    for pv in _players:
        var p := pv as AudioStreamPlayer
        if p == null or not is_instance_valid(p):
            continue
        if not p.playing:
            if free == null:
                free = p
            continue
        var t := int(p.get_meta("started", 0))
        var protected := (not incoming_hero) and bool(p.get_meta("hero", false)) and (now - t < HERO_PROTECT_MS)
        if not protected and t < oldest_t:
            oldest_t = t
            oldest = p
        if p.get_meta("seam", &"") == sn:
            same.append(p)
    if same.size() >= poly:
        var steal: AudioStreamPlayer = same[0]
        var st_t := 1 << 62
        for pv in same:
            var p2 := pv as AudioStreamPlayer
            var t2 := int(p2.get_meta("started", 0))
            if t2 < st_t:
                st_t = t2
                steal = p2
        steal.stop()
        return steal
    if free != null:
        return free
    if oldest != null:
        oldest.stop()          # global steal = longest-playing
    return oldest

static func _duck() -> void:
    # Ref-counted duck: every SfxBig play increments; only the LAST release starts recovery,
    # so MULTI break chains never leave the bus stuck at -4 dB.
    var idx := AudioServer.get_bus_index("Sfx")
    if idx == -1 or _pool == null or not is_instance_valid(_pool) or not _pool.is_inside_tree():
        return
    _duck_holds += 1
    if _duck_tween != null and _duck_tween.is_valid():
        _duck_tween.kill()
    AudioServer.set_bus_volume_db(idx, DUCK_DB)
    var timer := _pool.get_tree().create_timer(DUCK_HOLD_S)
    timer.timeout.connect(_duck_release)

static func _duck_release() -> void:
    _duck_holds = maxi(0, _duck_holds - 1)
    if _duck_holds > 0:
        return
    var idx := AudioServer.get_bus_index("Sfx")
    if idx == -1 or _pool == null or not is_instance_valid(_pool):
        return
    if _duck_tween != null and _duck_tween.is_valid():
        _duck_tween.kill()
    _duck_tween = _pool.create_tween()
    var from_db := AudioServer.get_bus_volume_db(idx)
    _duck_tween.tween_method(func(v: float): AudioServer.set_bus_volume_db(idx, v), from_db, 0.0, DUCK_RECOVER_S)

# ==========================================================================================
# WAVE 4B PUBLIC API  (headless-inert; the wire lanes call these, never AudioServer directly)
# ==========================================================================================

# Set-once headless latch: state (refcounts, gate flag, slider prefs) updates even headless so the
# pure logic is testable, but every AudioServer / node / tween side effect sits behind this.
static func _live() -> bool:
    if not _checked_headless:
        _checked_headless = true
        _inert = DisplayServer.get_name() == "headless"
    return not _inert

# --- (2) LOOP / STREAM PLAYERS: registry-driven, one dedicated player per active loop seam -------
# Ambience beds + state hums (AmbDuck) and music stems (MusicDuck) start / stop / re-gain here.
# A loop whose wav is not yet rendered (pending) silently no-ops until lane C lands the file.
static func loop_start(seam, fade_s: float = 0.5) -> void:
    if muted:
        return
    if not _live():
        return
    var sn := StringName(seam)
    if not MANIFEST.has(sn):
        return
    var m: Dictionary = MANIFEST[sn]
    if not m.get("loop", false):
        return              # loop_start is only for loop / stem rows
    _ensure_pool()
    if _pool == null or not _pool.is_inside_tree():
        return              # pool lands next frame; screen-enter calls arrive well after frame 0
    var pl := _loop_player(sn, m)
    if pl == null:
        return              # wav not rendered yet (pending) - silent until it lands
    var gain := float(m["gain_db"])
    if fade_s <= 0.0:
        pl.volume_db = gain
        if not pl.playing:
            pl.play()
        return
    if not pl.playing:
        pl.volume_db = -60.0
        pl.play()
    _loop_tween_to(sn, pl, gain, fade_s)

static func loop_stop(seam, fade_s: float = 0.5) -> void:
    if not _live():
        return
    var sn := StringName(seam)
    var pl: AudioStreamPlayer = _loops.get(sn)
    if pl == null or not is_instance_valid(pl):
        return
    if fade_s <= 0.0 or not pl.is_inside_tree():
        pl.stop()
        return
    var tw := _new_loop_tween(sn)
    tw.tween_method(func(v: float): pl.volume_db = v, pl.volume_db, -60.0, fade_s)
    tw.tween_callback(pl.stop)

static func loop_gain(seam, db: float, tween_s: float = 0.2) -> void:
    if not _live():
        return
    var sn := StringName(seam)
    var pl: AudioStreamPlayer = _loops.get(sn)
    if pl == null or not is_instance_valid(pl):
        return
    if tween_s <= 0.0 or not pl.is_inside_tree():
        pl.volume_db = db
        return
    var tw := _new_loop_tween(sn)
    tw.tween_method(func(v: float): pl.volume_db = v, pl.volume_db, db, tween_s)

static func _loop_player(sn: StringName, m: Dictionary) -> AudioStreamPlayer:
    var existing: AudioStreamPlayer = _loops.get(sn)
    if existing != null and is_instance_valid(existing):
        return existing
    var files: Array = m["files"]
    if files.is_empty():
        return null
    var st := _load_stream(String(files[0]), m.get("dir", AUDIO_DIR))
    if st == null:
        return null         # pending row whose wav lane C has not rendered yet
    var pl := AudioStreamPlayer.new()
    pl.stream = st
    var bus := String(m["bus"])
    var pan := float(m.get("pan", 0.0))
    if bus == "AmbDuck":    # the only duck bus with panner sub-buses (core-hum L/R detune)
        if pan < -0.05:
            bus = "AmbDuckPanL"
        elif pan > 0.05:
            bus = "AmbDuckPanR"
    pl.bus = bus
    pl.pitch_scale = float(m.get("pitch", 1.0))
    _pool.add_child(pl)
    _loops[sn] = pl
    return pl

static func _loop_tween_to(sn: StringName, pl: AudioStreamPlayer, db: float, dur: float) -> void:
    var tw := _new_loop_tween(sn)
    tw.tween_method(func(v: float): pl.volume_db = v, pl.volume_db, db, dur)

static func _new_loop_tween(sn: StringName) -> Tween:
    var old: Tween = _loop_tweens.get(sn)
    if old != null and old.is_valid():
        old.kill()
    var tw := _pool.create_tween()
    _loop_tweens[sn] = tw
    return tw

# --- (3) THE FOUR DUCKINGS as ref-counted deterministic bus tweens (deepest-wins per bus) --------
static func duck_claim(kind) -> void:
    var k := StringName(kind)
    if not DUCK_RULES.has(k):
        return
    _duck_refs[k] = int(_duck_refs.get(k, 0)) + 1
    if not _live():
        return
    for b in DUCK_RULES[k]["targets"]:
        _retarget_duck(String(b))

static func duck_release(kind) -> void:
    var k := StringName(kind)
    if not DUCK_RULES.has(k):
        return
    _duck_refs[k] = maxi(0, int(_duck_refs.get(k, 0)) - 1)
    if not _live():
        return
    for b in DUCK_RULES[k]["targets"]:
        _retarget_duck(String(b))

# Auto-timed hero duck fired from play() for HERO_SEAMS: claim on play, release after the protect
# window. Ref-counted, so flurries and MULTI break chains never leave Music stuck ducked.
static func _hero_duck() -> void:
    if _pool == null or not is_instance_valid(_pool) or not _pool.is_inside_tree():
        return
    duck_claim(&"hero")
    var t := _pool.get_tree().create_timer(float(HERO_PROTECT_MS) / 1000.0)
    t.timeout.connect(func(): duck_release(&"hero"))

static func _deepest_for(bus: String) -> float:
    var d := 0.0
    for k in DUCK_RULES:
        if int(_duck_refs.get(k, 0)) <= 0:
            continue
        if not (DUCK_RULES[k]["targets"] as Array).has(bus):
            continue
        d = minf(d, float(DUCK_RULES[k]["depth"]))
    return d

static func _duck_dur(bus: String, deepening: bool) -> float:
    var ms := 0.0
    var found := false
    for k in DUCK_RULES:
        if not (DUCK_RULES[k]["targets"] as Array).has(bus):
            continue
        if deepening:
            if int(_duck_refs.get(k, 0)) <= 0:
                continue        # deepening rate = fastest attack among ACTIVE rules on this bus
            var a := float(DUCK_RULES[k]["attack_ms"])
            ms = a if not found else minf(ms, a)
        else:
            var r := float(DUCK_RULES[k]["release_ms"])
            ms = r if not found else maxf(ms, r)   # recovery = slowest release on this bus (peril 1s)
        found = true
    if not found:
        ms = 50.0
    return ms / 1000.0

static func _retarget_duck(bus: String) -> void:
    var idx := AudioServer.get_bus_index(bus)
    if idx == -1:
        return
    var target := _deepest_for(bus)
    if _pool == null or not is_instance_valid(_pool) or not _pool.is_inside_tree():
        AudioServer.set_bus_volume_db(idx, target)
        return
    var cur := AudioServer.get_bus_volume_db(idx)
    var deepening := target < cur - 0.01
    var dur := _duck_dur(bus, deepening)
    var old: Tween = _duck_bus_tweens.get(bus)
    if old != null and old.is_valid():
        old.kill()
    if dur <= 0.0:
        AudioServer.set_bus_volume_db(idx, target)
        return
    var tw := _pool.create_tween()
    tw.tween_method(func(v: float): AudioServer.set_bus_volume_db(idx, v), cur, target, dur)
    _duck_bus_tweens[bus] = tw

# --- (4) THE STILLNESS GATE: a master latch that hard-mutes Music/Ambience/Ui and refuses play() --
# for every seam except GATE_ALLOW (the death channel + parts_settle exit). Only the UNMAKING uses
# it; released only by an explicit stillness(false) from the parts-settle beat (lane B2).
static func stillness(on: bool) -> void:
    if _stillness_on == on:
        return
    _stillness_on = on
    if not _live():
        return
    if on:
        _gate_close()
    else:
        _gate_open()

static func gate_allows(seam) -> bool:
    return (not _stillness_on) or GATE_ALLOW.has(StringName(seam))

static func _gate_close() -> void:
    # Freeze every duck tween (a pre-claim recovery tween must not restore volume mid-stillness),
    # then instantly mute the gated buses - the hand lifted off, not a fade. SfxBig is exempt (the
    # death channel: death_winddown is already ringing on it); Sfx stays live so parts_settle lands.
    for b in _duck_bus_tweens.keys():
        var tw: Tween = _duck_bus_tweens[b]
        if tw != null and tw.is_valid():
            tw.kill()
    for b: String in GATE_BUSES:
        var idx := AudioServer.get_bus_index(b)
        if idx != -1:
            AudioServer.set_bus_mute(idx, true)

static func _gate_open() -> void:
    # Restore each gated bus to its USER mute state (a slider-muted bus stays muted), never blindly
    # false. Music does NOT auto-resume - that timing is the workshop screen's (lane B3), not the gate's.
    for b: String in GATE_BUSES:
        _apply_user_bus(b)

# --- (5) SETTINGS SLIDER SEAMS: four sliders (Master / Music / Ambience / SFX; Ui rides SFX) ------
# frac 0 => mute; else a perceptual taper. get_bus_volume returns the raw linear the slider set.
static func set_bus_volume(bus, linear: float) -> void:
    var b := String(bus)
    _user_frac[b] = linear
    var is_muted := linear <= 0.0005
    _user_muted[b] = is_muted
    if not is_muted:
        _user_db[b] = clampf(linear_to_db(pow(linear, 1.5)), -38.0, 0.0)
    if not _live():
        return
    if _stillness_on and GATE_BUSES.has(b):
        return              # gate owns this bus's mute right now; _gate_open() will apply the pref
    _apply_user_bus(b)

static func get_bus_volume(bus) -> float:
    return float(_user_frac.get(String(bus), 1.0))

static func _apply_user_bus(b: String) -> void:
    var idx := AudioServer.get_bus_index(b)
    if idx == -1:
        return
    var is_muted := bool(_user_muted.get(b, false))
    AudioServer.set_bus_mute(idx, is_muted)
    if not is_muted:
        AudioServer.set_bus_volume_db(idx, float(_user_db.get(b, 0.0)))
