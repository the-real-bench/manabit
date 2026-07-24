class_name Music extends RefCounted
# THE WOUND SPRING - the music-box runtime (audio-full-game.md section 4.3, task T21).
# A music box the Artificer wound: ONE bench motif rendered by lane C into four sample-locked
# stems (melody / bells / pad / pulse). We mix them live by thinning stem volumes per screen -
# bench = full quartet, shop/nook = bells + pad, run = pulse + melody, combat = pulse only. The
# tension curve is the room going QUIET, never a drum layer added.
#
# Tech ruling (4.1): all four stems ride ONE AudioStreamSynchronized in ONE AudioStreamPlayer on
# the MusicDuck bus - sample-locked by construction, no four-players drift race. Whole-music
# ducking / slider / stillness gate stay on the bus (lane A / Sfx owns those); we only ever write
# PER-STEM volumes via set_sync_stream_volume and the player's own volume - NEVER an AudioServer
# bus volume (the single-writer law; the smoke_audio scan enforces it over ui/*.gd).
#
# Contract mirrors Sfx:
#   - Headless = inert forever. No player, no node, no tween exists headless (gates untouched);
#     logical state (current state, peril flag, unlock flag) still updates so the wiring is safe.
#   - HTML5 first-tap: music does NOT start until notify_first_input() (root fires it on the first
#     real input on web, on ready on desktop) - the music box winds up when a hand touches the bench.
#   - Every public method is lazy-safe: call order does not matter, ensure() self-bootstraps.

enum State { BENCH, SHOP, RUN, COMBAT, COMBAT_TENSE, WAKING, SILENT }

# Stem order == AudioStreamSynchronized member index. Files land in res://audio/music/ (lane C).
const STEMS: Array[String] = ["mus_bench_melody", "mus_bench_bells", "mus_bench_pad", "mus_bench_pulse"]
const MELODY := 0
const BELLS := 1
const PAD := 2
const PULSE := 3

const MUSIC_DIR := "res://audio/music/"
const MANIFEST_PATH := "res://audio/music/stems_manifest.json"
const OFF_DB := -60.0            # a stem "musically off" (tech plan 4.3)
const FADE_S := 0.8             # musical transition, not abrupt (4.3)
const WIND_UP_S := 1.2         # the box winding back up (first tap / post-mourning rewind)

# STEM_TARGETS per state (dB): [melody, bells, pad, pulse]. Verbatim from tech plan 4.3.
# COMBAT and COMBAT_TENSE are identical pulse-only (the melody is already off; peril + fragment
# are the only in-combat movers). WAKING keeps the player RUNNING all-off so music re-enters at
# the right bar when the reveal ladder finishes. SILENT stops the player.
const STEM_TARGETS := {
    State.BENCH:        [0.0,    0.0,    0.0,    0.0],
    State.SHOP:         [OFF_DB, 0.0,    0.0,    OFF_DB],
    State.RUN:          [0.0,    OFF_DB, OFF_DB, 0.0],
    State.COMBAT:       [OFF_DB, OFF_DB, OFF_DB, 0.0],
    State.COMBAT_TENSE: [OFF_DB, OFF_DB, OFF_DB, 0.0],
    State.WAKING:       [OFF_DB, OFF_DB, OFF_DB, OFF_DB],
    State.SILENT:       [OFF_DB, OFF_DB, OFF_DB, OFF_DB],
}

static var _inert := false
static var _checked_headless := false
static var _built := false
static var _pool: Node = null
static var _player: AudioStreamPlayer = null
static var _sync: AudioStreamSynchronized = null
static var _stem_tweens: Array = [null, null, null, null]
static var _cur_db: Array = [OFF_DB, OFF_DB, OFF_DB, OFF_DB]   # live stem volumes (tween-from)

static var _state: int = State.SILENT
static var _peril := false
static var _trim_db := 0.0                # survivable-loss subdue offset (added to live stems)
static var _unlocked := false            # first-tap gate (HTML5 autoplay policy)
static var _fragment_open := false       # a melody fragment window is open (COMBAT only)
static var _fragment_gen := 0            # cancels a stale fragment close if state moved on

# Musical geometry, read from the stem manifest at build (fallbacks are the 80 BPM canon).
static var victory_half_beat_ms := 375.0
static var _beat_ms := 750.0
static var _bar_s := 3.0                  # 4 beats * 0.75 s

# ==========================================================================================
# PUBLIC API
# ==========================================================================================

# Build the player + synchronized stream. Idempotent; live-only. Safe to call before or after
# any state set - set_state stores intent and ensure() applies it.
static func ensure() -> void:
    if not _live():
        return
    _build()

# Set the screen mix. Stores the logical state even headless / pre-unlock so root wiring is
# order-free; only tweens stem volumes once built and unlocked.
static func set_state(state: int) -> void:
    _state = state
    if state == State.SILENT:
        _stop()
        return
    if not _live():
        return
    _build()
    if not _unlocked:
        return              # nothing plays before the first tap; _apply lands on unlock
    _fragment_open = false  # a state change closes any open combat fragment
    _play_if_needed()
    _apply_targets(FADE_S)

# Instant hard stop - a hand lifted off the box, not a fade. Used by THE UNMAKING (via root's
# death handling) and the victory half-beat cut (combat beat planner, when it wires this).
static func stop_hard() -> void:
    _state = State.SILENT
    _stop()

# Peril overlay (adaptive rule 2): forces the melody stem to -60 regardless of state until
# released, as a max-mute so a state change during peril cannot resurrect the melody.
static func set_peril(on: bool) -> void:
    if _peril == on:
        return
    _peril = on
    if not _live() or not _unlocked:
        return
    _apply_targets(FADE_S)

# COMBAT only: open the melody stem for ONE 2-bar window, bar-quantized from the current playback
# position (deterministic from the call, never random-timed). Occasional warmth over the pulse.
static func allow_fragment() -> void:
    if _state != State.COMBAT and _state != State.COMBAT_TENSE:
        return
    if not _live() or not _unlocked or _peril:
        return
    if _player == null or not is_instance_valid(_player) or not _player.playing:
        return
    _fragment_gen += 1
    var gen := _fragment_gen
    var pos := _player.get_playback_position()
    var delay := maxf(0.0, (floorf(pos / _bar_s) + 1.0) * _bar_s - pos)
    var t := _timer(delay)
    if t != null:
        t.timeout.connect(func(): _open_fragment(gen))

static func _open_fragment(gen: int) -> void:
    if gen != _fragment_gen:
        return
    if _state != State.COMBAT and _state != State.COMBAT_TENSE:
        return
    _fragment_open = true
    _apply_targets(0.2)
    var t := _timer(_bar_s * 2.0)
    if t != null:
        t.timeout.connect(func(): _close_fragment(gen))

static func _close_fragment(gen: int) -> void:
    if gen != _fragment_gen:
        return
    _fragment_open = false
    _apply_targets(FADE_S)

# Survivable-loss return: the whole motif comes back subdued (db below its targets) for `secs`,
# then restores. loss_settle rings alone; the room does not punish, just quiets (adaptive rule).
static func subdue(db: float, secs: float) -> void:
    _trim_db = db
    if not _live() or not _unlocked:
        return
    _apply_targets(FADE_S)
    var t := _timer(secs)
    if t == null:
        return
    t.timeout.connect(func(): _end_subdue())

static func _end_subdue() -> void:
    _trim_db = 0.0
    if _live() and _unlocked and _state != State.SILENT:
        _apply_targets(2.0)     # ease the subdue off gently

# The first-tap unlock (HTML5) / desktop wind-up. Idempotent. Winds the box up into the state
# that was already set, so the fiction is "touch the bench, the music box starts."
static func notify_first_input() -> void:
    if _unlocked:
        return
    _unlocked = true
    if not _live():
        return
    _build()
    if _state == State.SILENT:
        return
    _play_if_needed()
    _apply_from(OFF_DB, WIND_UP_S)   # wind up from silence into the current mix

# Rewind the music box to bar 0 and start `state` fresh (post-death mourning is over). Session
# gesture only - never persisted.
static func wind_up(state: int) -> void:
    _state = state
    if not _live() or not _unlocked or state == State.SILENT:
        return
    _build()
    if _player != null and is_instance_valid(_player):
        _player.stop()
        _cur_db = [OFF_DB, OFF_DB, OFF_DB, OFF_DB]
        for i in STEMS.size():
            if _sync != null:
                _sync.set_sync_stream_volume(i, OFF_DB)
        _player.play()
    _apply_from(OFF_DB, WIND_UP_S)

static func is_playing() -> bool:
    return _player != null and is_instance_valid(_player) and _player.playing

static func is_unlocked() -> bool:
    return _unlocked

# ==========================================================================================
# INTERNALS
# ==========================================================================================

# Set-once headless latch, identical means to Sfx: no player/node/tween ever exists headless.
static func _live() -> bool:
    if not _checked_headless:
        _checked_headless = true
        _inert = DisplayServer.get_name() == "headless"
    return not _inert

static func _build() -> void:
    if _built:
        return
    var ml := Engine.get_main_loop()
    if not (ml is SceneTree):
        return
    var tree := ml as SceneTree
    _load_manifest()
    _sync = AudioStreamSynchronized.new()
    _sync.set_stream_count(STEMS.size())
    var any := false
    for i in STEMS.size():
        var st := _load_stem(STEMS[i])
        if st != null:
            _sync.set_sync_stream(i, st)
            any = true
        _sync.set_sync_stream_volume(i, OFF_DB)
    if not any:
        return              # stems not rendered yet - do not mark built; retry on next call
    _pool = Node.new()
    _pool.name = "MusicBox"
    _player = AudioStreamPlayer.new()
    _player.stream = _sync
    _player.bus = "MusicDuck"
    _player.volume_db = 0.0
    # Safety net: if AudioStreamSynchronized ever reports finished (member loops should make it
    # endless), restart so the bench never falls silent mid-session.
    _player.finished.connect(_on_player_finished)
    _pool.add_child(_player)
    tree.root.add_child.call_deferred(_pool)
    _built = true

static func _on_player_finished() -> void:
    if _unlocked and _state != State.SILENT and _player != null and is_instance_valid(_player):
        _player.play()
        _apply_targets(0.0)

static func _load_stem(base: String) -> AudioStream:
    var path := MUSIC_DIR + base + ".wav"
    if not ResourceLoader.exists(path):
        return null
    var st = load(path)
    return st if st is AudioStream else null

static func _load_manifest() -> void:
    if not FileAccess.file_exists(MANIFEST_PATH):
        return
    var txt := FileAccess.get_file_as_string(MANIFEST_PATH)
    var data = JSON.parse_string(txt)
    if not (data is Dictionary):
        return
    if data.has("victory_half_beat_ms"):
        victory_half_beat_ms = float(data["victory_half_beat_ms"])
    if data.has("beat_ms"):
        _beat_ms = float(data["beat_ms"])
    var bpb := float(data.get("beats_per_bar", 4))
    _bar_s = (_beat_ms / 1000.0) * bpb

static func _play_if_needed() -> void:
    if _player == null or not is_instance_valid(_player):
        return
    if not _player.playing:
        _player.play()

static func _stop() -> void:
    if _player != null and is_instance_valid(_player):
        _player.stop()

# The dB a stem should sit at right now: its state target, plus the survivable-loss trim, with
# the peril + off rules winning. A stem whose base is OFF stays OFF (trim can't un-mute it).
static func _target_for(i: int) -> float:
    var base: float = STEM_TARGETS[_state][i]
    if _peril and i == MELODY:
        return OFF_DB
    if _fragment_open and i == MELODY and (_state == State.COMBAT or _state == State.COMBAT_TENSE):
        base = 0.0
    if base <= OFF_DB:
        return OFF_DB
    return base + _trim_db

static func _apply_targets(dur: float) -> void:
    for i in STEMS.size():
        _tween_stem(i, _target_for(i), dur)

# Wind-up helper: snap every live stem to `from_db` then ease to targets (used on first-tap and
# rewind so the whole box swells up together).
static func _apply_from(from_db: float, dur: float) -> void:
    if _sync == null:
        return
    for i in STEMS.size():
        _cur_db[i] = from_db
        _sync.set_sync_stream_volume(i, from_db)
    _apply_targets(dur)

static func _tween_stem(i: int, target_db: float, dur: float) -> void:
    if _sync == null:
        return
    var old: Tween = _stem_tweens[i]
    if old != null and old.is_valid():
        old.kill()
    if dur <= 0.0 or _pool == null or not is_instance_valid(_pool) or not _pool.is_inside_tree():
        _write_stem(i, target_db)
        return
    var from_db: float = _cur_db[i]
    var tw := _pool.create_tween()
    tw.tween_method(func(v: float): _write_stem(i, v), from_db, target_db, dur)
    _stem_tweens[i] = tw

# The single-writer point for a stem's live volume: our per-stem set (NOT an AudioServer bus write).
static func _write_stem(i: int, v: float) -> void:
    _cur_db[i] = v
    if _sync != null:
        _sync.set_sync_stream_volume(i, v)

static func _timer(secs: float) -> SceneTreeTimer:
    if _pool == null or not is_instance_valid(_pool) or not _pool.is_inside_tree():
        return null
    return _pool.get_tree().create_timer(secs)
