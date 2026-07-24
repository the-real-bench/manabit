extends SceneTree
# Cadence/QA contract gate for the combat playback planner. plan() is PURE and deterministic,
# so this asserts the ladder, the anti-strobe caps, and the cadence budgets headless.
# KNOWN GAP (stated honestly): this proves the PLAN, not wall-clock playback - the director's
# commit-vs-control debug print + the windowed harness cover the wall clock.

var _ok := true

func _initialize() -> void:
    var cs: CombatScreen = CombatScreen.new()   # never added to tree: plan() touches no scene state

    var ctx_s := _ctx("SINGLE", false, false)
    var ctx_m := _ctx("MULTI", false, false)
    var man := {"auto": false, "reduce_motion": false}
    var aut := {"auto": true, "reduce_motion": false}
    var rm := {"auto": false, "reduce_motion": true}

    # fixtures
    var f_single := [_ev("ARM_L", 6, false, false)]
    var f_break := [_ev("ARM_L", 6, true, false)]
    var f_core := [_ev("CORE", 9, false, true)]
    var f_multi4 := [_ev("ARM_L", 3, false, false), _ev("HEAD", 3, true, false), _ev("LEGS", 3, false, false), _ev("ARM_R", 3, false, false)]
    var f_worst := [_ev("ARM_L", 3, true, false), _ev("HEAD", 3, false, false), _ev("LEGS", 3, true, false), _ev("BACK", 3, false, false), _ev("CORE", 5, false, true)]
    var f_strobe := [_ev("ARM_L", 3, true, false), _ev("HEAD", 3, true, false), _ev("LEGS", 3, true, false), _ev("BACK", 3, true, false), _ev("ARM_R", 3, true, false), _ev("CORE", 3, false, true)]

    # 1. structure: one impact + one number per event, monotonic t, settle last
    for fx in [[f_single, ctx_s], [f_multi4, ctx_m], [f_worst, ctx_m], [f_strobe, ctx_m]]:
        var beats: Array = cs.plan(fx[0], fx[1], man)
        _c("monotonic t", _monotonic(beats))
        _c("settle is last", beats[beats.size() - 1]["kind"] == &"settle")
        var evn: Array = fx[0]
        _c("one impact per event", _count_for_events(beats, &"impact", evn.size()))
        _c("one number per event", _count_for_events(beats, &"number", evn.size()))
        var breaks := 0
        for e in evn:
            if bool(e["broke"]):
                breaks += 1
        _c("one break per broke", _count(beats, &"break") == breaks)

    # 2. one full-screen core flash per turn, max
    var b_core: Array = cs.plan(f_core, ctx_s, man)
    _c("core turn has exactly one core_flash", _count(b_core, &"core_flash") == 1)
    var b_worst: Array = cs.plan(f_worst, ctx_m, man)
    _c("worst case still one core_flash", _count(b_worst, &"core_flash") <= 1)

    # 3. anti-strobe: pane flashes <= 3 per action, >= 250ms apart (checked on the plan)
    var b_strobe: Array = cs.plan(f_strobe, ctx_m, man)
    var flash_ts: Array = []
    for b in b_strobe:
        if b["kind"] == &"impact" and bool((b["data"] as Dictionary).get("pane_flash", false)):
            flash_ts.append(float(b["t"]))
    _c("pane flashes <= 3 per action", flash_ts.size() <= 3)
    var spaced := true
    for i in range(1, flash_ts.size()):
        if float(flash_ts[i]) - float(flash_ts[i - 1]) < 250.0:
            spaced = false
    _c("pane flashes >= 250ms apart", spaced)
    _c("demoted flashes keep their impact+number", _count_for_events(b_strobe, &"impact", f_strobe.size()) and _count_for_events(b_strobe, &"number", f_strobe.size()))

    # 4. budgets: normal <= 1500 for every fixture incl the 5-hit worst case; auto <= 800;
    #    first impact <= 450. (f_strobe is a beyond-spec strobe-cap fixture, not a cadence one.)
    for fx2 in [[f_single, ctx_s], [f_break, ctx_s], [f_core, ctx_s], [f_multi4, ctx_m], [f_worst, ctx_m]]:
        var bm: Array = cs.plan(fx2[0], fx2[1], man)
        var ba: Array = cs.plan(fx2[0], fx2[1], aut)
        _c("manual total <= 1500 (%d)" % int(_total(bm)), _total(bm) <= 1500.0)
        _c("auto total <= 800 (%d)" % int(_total(ba)), _total(ba) <= 800.0)
        _c("first impact <= 450 manual", _first_t(bm, &"impact") <= 450.0)
        _c("first impact <= 450 auto", _first_t(ba, &"impact") <= 450.0)

    # 5. reduce-motion: never longer than normal for the same fixture; information intact
    for fx3 in [[f_single, ctx_s], [f_worst, ctx_m]]:
        var bn: Array = cs.plan(fx3[0], fx3[1], man)
        var br: Array = cs.plan(fx3[0], fx3[1], rm)
        _c("reduce-motion total <= normal", _total(br) <= _total(bn))
        var evs: Array = fx3[0]
        _c("reduce-motion keeps numbers", _count_for_events(br, &"number", evs.size()))
        _c("reduce-motion keeps recovers (bar rolls)", _count(br, &"recover") == evs.size())

    # 6. telegraph: inserted only for the foe core-hunt SINGLE, floored in auto
    var ctx_tel := _ctx("SINGLE", false, true)
    ctx_tel["attacker_is_me"] = false
    var b_tel: Array = cs.plan(f_core, ctx_tel, man)
    _c("telegraph beat first", b_tel[0]["kind"] == &"telegraph")
    _c("telegraph manual 250ms", absf(float((b_tel[0]["data"] as Dictionary)["dur"]) - 250.0) < 1.0)
    _c("telegraph + core impact <= 450", _first_t(b_tel, &"impact") <= 450.0)
    var b_tel_a: Array = cs.plan(f_core, ctx_tel, aut)
    _c("telegraph auto floored at 200ms", float((b_tel_a[0]["data"] as Dictionary)["dur"]) >= 200.0)
    var b_no_tel: Array = cs.plan(f_core, ctx_s, man)
    _c("no telegraph for the player", b_no_tel[0]["kind"] != &"telegraph")

    # 7. guard / mend / empty lanes
    var ctx_g := _ctx("GUARD", false, false)
    ctx_g["guard_kind"] = "DEF_BUFF"
    ctx_g["guard_amount"] = 5
    var b_g: Array = cs.plan([], ctx_g, man)
    _c("guard lane: guard beat + settle", _count(b_g, &"guard") == 1 and _total(b_g) <= 500.0)
    var ctx_mend := _ctx("GUARD", false, false)
    ctx_mend["guard_kind"] = "PART_RESTORE"
    ctx_mend["mend_slot"] = "ARM_L"
    ctx_mend["amount"] = 4
    var b_mend: Array = cs.plan([], ctx_mend, man)
    _c("mend lane: mend beat + settle", _count(b_mend, &"mend") == 1 and _total(b_mend) <= 600.0)
    var b_empty: Array = cs.plan([], ctx_s, man)
    _c("empty events <= 100ms", _total(b_empty) <= 100.0)

    # 8. hit-stop cap: total non-kill stop <= 300ms per turn
    var stop_sum := 0.0
    for b in b_strobe:
        if b["kind"] == &"impact":
            stop_sum += float((b["data"] as Dictionary).get("stop", 0.0))
    _c("total hit-stop <= 300ms (%d)" % int(stop_sum), stop_sum <= 300.0)

    # 9. kill rung: T4 stop on the killing core blow, budget-exempt
    var ctx_kill := _ctx("SINGLE", true, false)
    var b_kill: Array = cs.plan(f_core, ctx_kill, man)
    var kill_stop := 0.0
    for b in b_kill:
        if b["kind"] == &"impact":
            kill_stop = float((b["data"] as Dictionary).get("stop", 0.0))
    _c("kill blow carries the 280ms stop", absf(kill_stop - 280.0) < 1.0)

    # 10. determinism: plan() deep-equals itself on a repeat run
    var p1: Array = cs.plan(f_worst, ctx_m, man)
    var p2: Array = cs.plan(f_worst, ctx_m, man)
    _c("plan() is deterministic (deep-equal)", p1 == p2)

    cs.free()
    print("SMOKE PASS" if _ok else "SMOKE FAIL")
    quit(0 if _ok else 1)

func _ev(slot: String, dmg: int, broke: bool, is_core: bool) -> Dictionary:
    return {"slot": slot, "damage": dmg, "broke": broke, "is_core": is_core, "target_is_me": false}

func _ctx(arch: String, kill: bool, telegraph: bool) -> Dictionary:
    return {"attacker_is_me": true, "archetype": arch, "guard_kind": "DEF_BUFF",
        "guard_amount": 0, "mend_slot": "", "amount": 0, "kill": kill, "telegraph": telegraph,
        "defender_affinity": "attack", "my_affinity": "attack", "whoosh_pitch": 1.0}

func _monotonic(beats: Array) -> bool:
    var last := -1.0
    for b in beats:
        var t := float(b["t"])
        if t < last:
            return false
        last = t
    return true

func _count(beats: Array, kind: StringName) -> int:
    var n := 0
    for b in beats:
        if b["kind"] == kind:
            n += 1
    return n

func _count_for_events(beats: Array, kind: StringName, n_events: int) -> bool:
    # exactly one <kind> per event_index 0..n-1
    var seen := {}
    for b in beats:
        if b["kind"] == kind:
            var i := int(b["event_index"])
            if seen.has(i):
                return false
            seen[i] = true
    return seen.size() == n_events

func _total(beats: Array) -> float:
    if beats.is_empty():
        return 0.0
    var last: Dictionary = beats[beats.size() - 1]
    return float(last["t"]) + float((last["data"] as Dictionary).get("dur", 0.0))

func _first_t(beats: Array, kind: StringName) -> float:
    for b in beats:
        if b["kind"] == kind:
            return float(b["t"])
    return 1e9

func _c(name: String, cond: bool) -> void:
    print(("  [%s] " % ("PASS" if cond else "FAIL")) + name)
    _ok = _ok and cond
