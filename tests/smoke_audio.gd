extends SceneTree
# Audio gate, two stages:
#   A (always): seam-name canon - every MANIFEST seam is KNOWN, every Sfx.play() call site in
#     the combat director uses a KNOWN seam (catches &"hit_corre" typos the day they land).
#   A2 (wave 4a): registry integrity - no seam registered twice, every MANIFEST file resolves
#     to a wav ON DISK (kills part_settle-vs-parts_settle drift, Q2, permanently), every
#     literal play() site across the wired UI screens names a KNOWN seam, and a headless
#     play() stays inert (no pool node is ever built here).
#   B (armed because muted == false): stream presence + wav format/duration/peak bands for
#     every shipped combat file. Headless-safe: parses files, never plays them.

var _ok := true

const DUR_BANDS := {
    "attack_whoosh_0": [200, 300], "hit_0": [100, 200], "hit_1": [100, 200], "hit_2": [100, 200],
    "hit_core_0": [450, 700], "part_break_0": [300, 450], "part_break_1": [300, 450],
    "guard_up_0": [350, 500], "mend_0": [550, 750], "victory_chord_0": [1200, 1800],
    "loss_settle_0": [750, 1000], "death_winddown_0": [500, 900],   # MUST be decayed pre-silence
    "invalid_clunk_0": [80, 200], "core_peril_0": [650, 900],
}

func _initialize() -> void:
    # --- stage A: seam canon ---
    for seam in Sfx.MANIFEST.keys():
        _c("manifest seam known: %s" % String(seam), Sfx.KNOWN_SEAMS.has(seam))
    var combat_seams := [&"hit", &"hit_core", &"part_break", &"attack_whoosh", &"guard_up",
        &"mend", &"core_peril", &"victory_chord", &"loss_settle", &"death_winddown", &"invalid_clunk"]
    for s in combat_seams:
        _c("combat seam in canon: %s" % String(s), Sfx.KNOWN_SEAMS.has(s))
        _c("combat seam has foley: %s" % String(s), Sfx.MANIFEST.has(s))
    # every play() site in the director names a known seam
    var src := FileAccess.get_file_as_string("res://ui/combat_screen.gd")
    var rx := RegEx.new()
    rx.compile("Sfx\\.play\\(&\"([a-z_]+)\"")
    var sites := 0
    for m in rx.search_all(src):
        sites += 1
        var seam_name := StringName(m.get_string(1))
        _c("director seam known: %s" % m.get_string(1), Sfx.KNOWN_SEAMS.has(seam_name))
    _c("director wires >= 9 seam sites (found %d)" % sites, sites >= 9)

    # --- stage A2 (wave 4a): registry integrity ---
    # 1) no seam registered twice
    var seen := {}
    for s3: StringName in Sfx.KNOWN_SEAMS:
        _c("seam registered once: %s" % String(s3), not seen.has(s3))
        seen[s3] = true
    # 2) every MANIFEST file resolves to a wav on disk AT ITS DECLARED DIR (name-drift killer:
    #    a filename that moves under a seam, a seam spelled part_settle, OR a loop row pointing
    #    at the wrong dir - all fail here the same day). This asserts EVERY row unconditionally:
    #    the old "pending" tolerance masked a wave-4b dir mismatch that left the whole ambience/
    #    hum/peril layer silent while the gate stayed green. No tolerance - if a row is registered,
    #    its file must resolve where the row says it lives.
    for s4: StringName in Sfx.MANIFEST.keys():
        var m4: Dictionary = Sfx.MANIFEST[s4]
        var dir4: String = m4.get("dir", Sfx.AUDIO_DIR)
        for fb: String in m4["files"]:
            var path4 := "%s%s.wav" % [dir4, fb]
            _c("wav resolves: %s (seam %s)" % [path4, String(s4)], FileAccess.file_exists(path4))
    # 3) every literal play() site across the wired UI screens names a KNOWN seam, and no
    #    screen regresses to stringly-typed play("...") calls the regex cannot see
    for fpath: String in ["res://ui/workshop.gd", "res://ui/chest_screen.gd",
            "res://ui/broker_screen.gd", "res://ui/run_screen.gd", "res://ui/slot_field.gd"]:
        var src2 := FileAccess.get_file_as_string(fpath)
        var fname := fpath.get_file()
        for m2: RegExMatch in rx.search_all(src2):
            _c("ui seam known: %s (%s)" % [m2.get_string(1), fname],
                Sfx.KNOWN_SEAMS.has(StringName(m2.get_string(1))))
        _c("no stringly play() in %s" % fname, not src2.contains("Sfx.play(\""))
    # 4) headless-inert still holds: play() here must no-op without ever building the pool
    Sfx.play(&"hit")
    _c("headless play flagged inert", Sfx._inert)
    _c("headless play built no pool", Sfx._pool == null)

    # --- stage A3 (wave 4b): bus tree table + duck engine + stillness gate (pure/headless) ---
    _check_bus_table()
    _check_hero_and_duck_sanity()
    _check_stillness_gate()
    _check_duck_refcount()
    _check_single_writer()
    _check_wave4b_registry()
    _c("headless inert intact after wave-4b api calls", Sfx._inert and Sfx._pool == null)

    # --- stage B: armed the moment muted flips false ---
    if Sfx.muted:
        print("  [SKIP] stage B (muted) - flip Sfx.muted=false to arm")
    else:
        for s2: StringName in Sfx.MANIFEST.keys():
            # every registered seam must load a real AudioStream (the definitive not-silent net:
            # a loop row pointing at a missing/mis-dir'd file returns null here and FAILS)
            var st := Sfx.stream_for(s2)
            _c("stream_for(%s) loads" % String(s2), st != null and st is AudioStream)
        for base in DUR_BANDS.keys():
            _check_wav(String(base))
    print("SMOKE PASS" if _ok else "SMOKE FAIL")
    quit(0 if _ok else 1)

# --- stage A3 helpers (wave 4b) - all pure/headless: they inspect static tables + pure logic ------

func _bus_send(nm: String) -> String:
    for spec in Sfx.BUSES:
        if String(spec["name"]) == nm:
            return String(spec["send"])
    return ""

func _reaches_master(nm: String) -> bool:
    var cur := nm
    var hops := 0
    while hops < Sfx.BUSES.size() + 2:
        if cur == "Master":
            return true
        var nxt := _bus_send(cur)
        if nxt == "":
            return false
        cur = nxt
        hops += 1
    return false

func _check_bus_table() -> void:
    var names := {}
    for spec in Sfx.BUSES:
        names[String(spec["name"])] = true
    for spec in Sfx.BUSES:
        var nm := String(spec["name"])
        var snd := String(spec["send"])
        _c("bus parent exists: %s -> %s" % [nm, snd], snd == "Master" or names.has(snd))
        _c("bus not self-send: %s" % nm, nm != snd)
        _c("bus reaches Master (no cycle): %s" % nm, _reaches_master(nm))
    for req: String in ["Music", "MusicDuck", "Ambience", "AmbDuck", "SFX", "Sfx", "SfxBig", "Ui"]:
        _c("bus present in table: %s" % req, names.has(req))
    # duck buses are children of their category; the SFX migration routes Sfx/SfxBig/Ui under SFX
    _c("MusicDuck child of Music", _bus_send("MusicDuck") == "Music")
    _c("AmbDuck child of Ambience", _bus_send("AmbDuck") == "Ambience")
    _c("Music routes to Master", _bus_send("Music") == "Master")
    _c("Ambience routes to Master", _bus_send("Ambience") == "Master")
    _c("SFX routes to Master", _bus_send("SFX") == "Master")
    _c("Sfx routes to SFX", _bus_send("Sfx") == "SFX")
    _c("SfxBig routes to SFX", _bus_send("SfxBig") == "SFX")
    _c("Ui routes to SFX", _bus_send("Ui") == "SFX")

func _check_hero_and_duck_sanity() -> void:
    for h: StringName in Sfx.HERO_SEAMS:
        _c("hero seam in canon: %s" % String(h), Sfx.KNOWN_SEAMS.has(h))
        var mm: Dictionary = Sfx.MANIFEST.get(h, {})
        var b := String(mm.get("bus", ""))
        _c("hero seam not on Ui: %s (bus %s)" % [String(h), b], b != "Ui")
        _c("hero seam routes Sfx/SfxBig: %s (bus %s)" % [String(h), b], b == "Sfx" or b == "SfxBig")
    var bus_names := {}
    for spec in Sfx.BUSES:
        bus_names[String(spec["name"])] = true
    for k: StringName in Sfx.DUCK_RULES:
        var r: Dictionary = Sfx.DUCK_RULES[k]
        for t: String in r["targets"]:
            _c("duck target exists: %s -> %s" % [String(k), t], bus_names.has(t))
        var depth := float(r["depth"])
        _c("duck depth in [-12,0): %s" % String(k), depth < 0.0 and depth >= -12.0)
        _c("duck attack <= 200ms: %s" % String(k), float(r["attack_ms"]) <= 200.0)
        _c("duck release <= 1200ms: %s" % String(k), float(r["release_ms"]) <= 1200.0)

func _check_stillness_gate() -> void:
    for g: StringName in Sfx.GATE_ALLOW:
        _c("GATE_ALLOW subset of KNOWN_SEAMS: %s" % String(g), Sfx.KNOWN_SEAMS.has(g))
    _c("parts_settle canonical (in GATE_ALLOW)", Sfx.GATE_ALLOW.has(&"parts_settle"))
    _c("part_settle drift killed (absent from allowlist and canon)",
        not Sfx.GATE_ALLOW.has(&"part_settle") and not Sfx.KNOWN_SEAMS.has(&"part_settle"))
    _c("gate open by default admits ui_tap", Sfx.gate_allows(&"ui_tap"))
    # close the gate: refuse every non-allowlisted seam, admit the death channel + the exit sound
    Sfx.stillness(true)
    _c("gate closed refuses ui_tap", not Sfx.gate_allows(&"ui_tap"))
    _c("gate closed refuses snap (a hero seam)", not Sfx.gate_allows(&"snap"))
    _c("gate closed refuses soul_hum (a loop)", not Sfx.gate_allows(&"soul_hum"))
    _c("gate closed admits death_winddown", Sfx.gate_allows(&"death_winddown"))
    _c("gate closed admits parts_settle (the exit sound)", Sfx.gate_allows(&"parts_settle"))
    _c("gate closed admits loss_settle", Sfx.gate_allows(&"loss_settle"))
    # play() honors the gate and stays headless-inert (no pool built, no crash)
    Sfx.play(&"ui_tap")
    Sfx.play(&"parts_settle")
    _c("headless inert under closed gate", Sfx._inert and Sfx._pool == null)
    # released ONLY explicitly - reopen and confirm
    Sfx.stillness(false)
    _c("gate reopened admits ui_tap", Sfx.gate_allows(&"ui_tap"))

func _check_duck_refcount() -> void:
    var base := int(Sfx._duck_refs.get(&"hero", 0))
    Sfx.duck_claim(&"hero")
    Sfx.duck_claim(&"hero")
    _c("duck claim x2 => ref +2", int(Sfx._duck_refs.get(&"hero", 0)) == base + 2)
    Sfx.duck_release(&"hero")
    _c("duck claim x2 release x1 => still ducked (ref +1)", int(Sfx._duck_refs.get(&"hero", 0)) == base + 1)
    Sfx.duck_release(&"hero")
    _c("duck released fully => back to base", int(Sfx._duck_refs.get(&"hero", 0)) == base)
    Sfx.duck_release(&"hero")   # underflow guard
    _c("duck release underflow clamps at 0", int(Sfx._duck_refs.get(&"hero", 0)) == 0)
    _c("headless inert after duck ops", Sfx._pool == null)

func _check_single_writer() -> void:
    # AudioServer.set_bus_volume_db / set_bus_mute may appear ONLY in ui/sfx.gd (the single writer).
    var dir := DirAccess.open("res://ui")
    if dir == null:
        _c("ui dir opens for single-writer scan", false)
        return
    dir.list_dir_begin()
    var fn := dir.get_next()
    while fn != "":
        if fn.ends_with(".gd") and fn != "sfx.gd":
            var src := FileAccess.get_file_as_string("res://ui/%s" % fn)
            _c("no AudioServer.set_bus_volume_db in ui/%s" % fn, not src.contains("AudioServer.set_bus_volume_db"))
            _c("no AudioServer.set_bus_mute in ui/%s" % fn, not src.contains("AudioServer.set_bus_mute"))
        fn = dir.get_next()
    dir.list_dir_end()

func _check_wave4b_registry() -> void:
    var beds_states: Array[StringName] = [&"amb_workshop", &"amb_nook", &"amb_barrow", &"amb_run",
        &"soul_hum", &"core_hum_me", &"core_hum_foe", &"peril_bed"]
    for s: StringName in beds_states:
        _c("bed/state seam registered: %s" % String(s), Sfx.KNOWN_SEAMS.has(s) and Sfx.MANIFEST.has(s))
        var m: Dictionary = Sfx.MANIFEST.get(s, {})
        _c("bed/state is loop on AmbDuck: %s" % String(s),
            m.get("loop", false) and String(m.get("bus", "")) == "AmbDuck")
        _c("bed/state lives in ambience dir: %s" % String(s), String(m.get("dir", "")) == Sfx.AMB_DIR)
    var stems: Array[StringName] = [&"mus_bench_melody", &"mus_bench_bells", &"mus_bench_pad", &"mus_bench_pulse"]
    for s: StringName in stems:
        _c("music stem registered: %s" % String(s), Sfx.KNOWN_SEAMS.has(s) and Sfx.MANIFEST.has(s))
        var m2: Dictionary = Sfx.MANIFEST.get(s, {})
        _c("music stem is loop on MusicDuck: %s" % String(s),
            m2.get("loop", false) and String(m2.get("bus", "")) == "MusicDuck")
    # core hums = a pre-detuned PAIR (me = core_hum_0 pan L, foe = core_hum_1 pan R): two souls, not one
    var me: Dictionary = Sfx.MANIFEST[&"core_hum_me"]
    var foe: Dictionary = Sfx.MANIFEST[&"core_hum_foe"]
    _c("core hums are the detuned pair (0 / 1)",
        String(me["files"][0]) == "core_hum_0" and String(foe["files"][0]) == "core_hum_1")
    _c("core hums pan opposite (L / R)", float(me.get("pan", 0.0)) < 0.0 and float(foe.get("pan", 0.0)) > 0.0)
    # amb_combat is deliberately ABSENT: combat has no bed, its room tone IS the two core hums
    _c("amb_combat absent (combat bed is the core hums)", not Sfx.KNOWN_SEAMS.has(&"amb_combat"))

func _check_wav(base: String) -> void:
    var path := "res://audio/sfx/%s.wav" % base
    var f := FileAccess.open(path, FileAccess.READ)
    if f == null:
        _c("wav exists: %s" % base, false)
        return
    var riff := f.get_buffer(4).get_string_from_ascii()
    f.get_32()                      # riff size
    var wave := f.get_buffer(4).get_string_from_ascii()
    _c("%s RIFF/WAVE header" % base, riff == "RIFF" and wave == "WAVE")
    var channels := 0
    var rate := 0
    var bits := 0
    var data_len := 0
    var peak := 0
    while f.get_position() < f.get_length() - 8:
        var cid := f.get_buffer(4).get_string_from_ascii()
        var csz := f.get_32()
        if cid == "fmt ":
            f.get_16()              # format tag
            channels = f.get_16()
            rate = f.get_32()
            f.get_32()              # byte rate
            f.get_16()              # block align
            bits = f.get_16()
            if csz > 16:
                f.seek(f.get_position() + csz - 16)
        elif cid == "data":
            data_len = csz
            var n := csz / 2
            for i in n:
                var v := f.get_16()
                if v >= 32768:
                    v -= 65536
                peak = maxi(peak, absi(v))
        else:
            f.seek(f.get_position() + csz)
    f.close()
    _c("%s is 44100Hz 16-bit mono" % base, channels == 1 and rate == 44100 and bits == 16)
    var dur_ms := 1000.0 * float(data_len / 2) / 44100.0
    var band: Array = DUR_BANDS[base]
    _c("%s duration %dms in band [%d..%d]" % [base, int(dur_ms), band[0], band[1]],
        dur_ms >= float(band[0]) and dur_ms <= float(band[1]))
    # peak-normalized to -3 dBFS: 0.708 * 32767 ~ 23197 (+/- 0.5 dB tolerance)
    _c("%s peak ~ -3 dBFS (%d)" % [base, peak], peak >= 21500 and peak <= 24600)

func _c(name: String, cond: bool) -> void:
    print(("  [%s] " % ("PASS" if cond else "FAIL")) + name)
    _ok = _ok and cond
