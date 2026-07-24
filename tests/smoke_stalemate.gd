extends SceneTree
# StalemateBreaker gate (design/balance/stalemate-breaker.md): the mutual-GUARD softlock fix.
#
# Forced repro (from the grounded diagnosis): a player build with an offensive arm whose mana_cost
# EXCEEDS the build's energy (never affordable -> can only GUARD) vs a foe carrying ONLY a GUARD part
# (its AI can only guard). combat.outcome() sits at ONGOING forever and no damage ever lands - the
# resolver alone can never end it. The DRIVER (ui/combat_screen.gd) must time the no-progress loop out
# to the EXISTING Combat.Result.SURVIVABLE_LOSS within STALEMATE_LIMIT turns, as a soft called-draw
# (forfeit UI skipped, both cores alive). A normal winnable fight must still resolve by DAMAGE.
#
# Drives the REAL combat_screen turn loop (auto mode) - not a re-implementation of it.
# combat/combat.gd + the section-13 classes are BYTE-UNTOUCHED; this test only reads them.

func _initialize() -> void:
    _run()                               # async: quit() is called from the coroutine when done

func _run() -> void:
    var ok := true

    # --- 1. Baseline: prove the stalemate is real and the resolver alone never ends it ---
    var base := _stalemate_pair()
    var bme: ManabitState = base[0]
    var bfoe: ManabitState = base[1]
    var bc := Combat.new()
    bc.start(bme, bfoe, false)
    var base_hp0 := _sum_hp(bme) + _sum_hp(bfoe)
    var stayed_ongoing := true
    for i in 40:
        if bc.outcome() != Combat.Result.ONGOING:
            stayed_ongoing = false
            break
        var actor := bc.current()
        if actor == bme:
            bc.ai_take_turn(bme, bfoe)
        else:
            bc.ai_take_turn(bfoe, bme)
        if bc.outcome() != Combat.Result.ONGOING:
            stayed_ongoing = false
            break
        bc.advance_turn()
    ok = _c("resolver alone never ends the stalemate (stays ONGOING over 40 turns)", stayed_ongoing and bc.outcome() == Combat.Result.ONGOING) and ok
    ok = _c("no damage ever lands in the stalemate (combined HP flat)", _sum_hp(bme) + _sum_hp(bfoe) == base_hp0) and ok
    ok = _c("player still HAS an offensive bit (ONGOING, not SURVIVABLE_LOSS)", bme.has_offensive_move()) and ok

    # --- 2. Drive the forced repro through the REAL combat_screen turn loop ---
    var pair := _stalemate_pair()
    var me: ManabitState = pair[0]
    var foe: ManabitState = pair[1]
    var player := PlayerState.new()
    var scrap0 := player.scrap
    var screen := CombatScreen.new()
    screen.setup(player)
    get_root().add_child(screen)
    await process_frame                   # add_child during _initialize DEFERS _ready to the first
    await process_frame                   # idle frame - wait so _build_layout() has run (labels exist)
    screen._me = me
    screen._foe = foe
    screen._foe_name = "Guard-Only Dummy"
    screen._stakes = true                 # stakes on: a normal SURVIVABLE_LOSS would offer a forfeit
    screen._run_mode = false
    screen._real_build = me               # so the broken HEAD below is a real forfeitable part
    screen._kit_run = null
    screen._auto = true                   # both sides AI-driven, no human input
    screen._title.text = "TEST STALEMATE"
    var hp_start := _sum_hp(me) + _sum_hp(foe)
    screen._start(false)

    var ended := await _wait_until_over(screen, 30.0)
    ok = _c("the fight actually ended (breaker did not hang)", ended) and ok
    await create_timer(1.5).timeout       # let the loss choreography + outcome fill run

    ok = _c("driver fired the breaker -> SURVIVABLE_LOSS", screen.last_result == Combat.Result.SURVIVABLE_LOSS) and ok
    ok = _c("the fight is flagged as a stalemate", screen._stalemate) and ok
    ok = _c("combat state is over", screen._state == "over") and ok
    ok = _c("fired at exactly STALEMATE_LIMIT no-progress turns", screen._noprog_turns == CombatScreen.STALEMATE_LIMIT) and ok
    ok = _c("neither core was unmade (both alive - cozy-fair)", me.alive() and foe.alive()) and ok
    ok = _c("no damage landed (combined HP unchanged through the fight)", _sum_hp(me) + _sum_hp(foe) == hp_start) and ok
    ok = _c("no scrap changed hands", player.scrap == scrap0) and ok

    var texts := _outcome_texts(screen)
    ok = _c("called-draw line is shown", _has(texts, "Nobody landed the finish")) and ok
    ok = _c("forfeit list is SKIPPED (no 'Forfeit a broken part')", not _has(texts, "Forfeit a broken part")) and ok
    ok = _c("the incidentally-broken bit is NOT forfeited", not _has(texts, "Cracked Visor")) and ok

    # --- 3. A normal winnable fight must resolve by DAMAGE, never trip the breaker ---
    var npair := _normal_pair()
    var nme: ManabitState = npair[0]
    var nfoe: ManabitState = npair[1]
    var screen2 := CombatScreen.new()
    screen2.setup(PlayerState.new())
    get_root().add_child(screen2)
    await process_frame                   # wait for the deferred _ready (see above)
    await process_frame
    screen2._me = nme
    screen2._foe = nfoe
    screen2._foe_name = "Glass Dummy"
    screen2._stakes = false
    screen2._run_mode = false
    screen2._real_build = null
    screen2._kit_run = null
    screen2._auto = true
    screen2._title.text = "TEST NORMAL"
    screen2._start(false)

    var ended2 := await _wait_until_over(screen2, 30.0)
    ok = _c("the normal fight ended", ended2) and ok
    await create_timer(0.3).timeout
    ok = _c("normal fight resolves by damage (WIN)", screen2.last_result == Combat.Result.WIN) and ok
    ok = _c("normal fight did NOT use the breaker", not screen2._stalemate) and ok

    print("SMOKE PASS" if ok else "SMOKE FAIL")
    quit(0 if ok else 1)

# --- fixtures (synthetic parts - deterministic, no catalog dependency) ---
func _core(energy: int, hp: int, aff: String) -> PartData:
    var p := PartData.new()
    p.id = &"test_core"
    p.display_name = "Test Core"
    p.slot = "CORE"
    p.is_core = true
    p.affinity = aff
    p.max_hp = hp
    p.energy = energy
    p.rarity = "COMMON"
    return p

func _weapon(slot: String, power: int, cost: int, hp: int) -> PartData:
    var p := PartData.new()
    p.id = &"test_weapon"
    p.display_name = "Test Nuke"
    p.slot = slot
    p.max_hp = hp
    var a := AbilityData.new()
    a.archetype = "SINGLE"
    a.display_name = "Nuke"
    a.power = power
    a.mana_cost = cost
    a.can_target_core = true
    p.ability = a
    return p

func _guard(slot: String, amount: int, cost: int, hp: int) -> PartData:
    var p := PartData.new()
    p.id = &"test_guard"
    p.display_name = "Test Buckler"
    p.slot = slot
    p.max_hp = hp
    var a := AbilityData.new()
    a.archetype = "GUARD"
    a.guard_kind = "DEF_BUFF"
    a.guard_amount = amount
    a.mana_cost = cost
    p.ability = a
    return p

func _plain(slot: String, name: String, hp: int) -> PartData:
    var p := PartData.new()
    p.id = &"test_plain"
    p.display_name = name
    p.slot = slot
    p.max_hp = hp
    return p

func _stalemate_pair() -> Array:
    var me := ManabitState.new()
    me.slots["CORE"] = PartInstance.new(_core(3, 40, "attack"))
    me.slots["ARM_R"] = PartInstance.new(_weapon("ARM_R", 20, 8, 10))    # cost 8 > energy 3: NEVER affordable
    var head := PartInstance.new(_plain("HEAD", "Cracked Visor", 6))
    head.current_hp = 0
    head.disabled = true                                                 # an incidentally-broken non-weapon
    me.slots["HEAD"] = head
    var foe := ManabitState.new()
    foe.slots["CORE"] = PartInstance.new(_core(10, 40, "defense"))
    foe.slots["ARM_L"] = PartInstance.new(_guard("ARM_L", 2, 1, 8))      # GUARD only -> foe AI can only guard
    return [me, foe]

func _normal_pair() -> Array:
    var me := ManabitState.new()
    me.slots["CORE"] = PartInstance.new(_core(10, 40, "attack"))
    me.slots["ARM_R"] = PartInstance.new(_weapon("ARM_R", 12, 2, 10))    # affordable -> lands damage
    var foe := ManabitState.new()
    foe.slots["CORE"] = PartInstance.new(_core(10, 6, "defense"))        # glass core - dies fast
    foe.slots["ARM_L"] = PartInstance.new(_guard("ARM_L", 2, 1, 4))
    return [me, foe]

# --- helpers ---
func _sum_hp(m: ManabitState) -> int:
    var t := 0
    for s in ManabitState.SLOT_NAMES:
        var pi = m.slots.get(s)
        if pi != null:
            t += pi.current_hp
    return t

func _wait_until_over(screen, timeout_s: float) -> bool:
    var t0 := Time.get_ticks_msec()
    while screen._state != "over":
        await create_timer(0.05).timeout
        if float(Time.get_ticks_msec() - t0) / 1000.0 > timeout_s:
            return false
    return true

func _outcome_texts(screen) -> Array:
    var out := []
    for c in screen._moves_box.get_children():
        if c is Label:
            out.append((c as Label).text)
        elif c is Button:
            out.append((c as Button).text)
    return out

func _has(arr: Array, sub: String) -> bool:
    for t in arr:
        if sub in String(t):
            return true
    return false

func _c(name: String, cond: bool) -> bool:
    print(("  [%s] " % ("PASS" if cond else "FAIL")) + name)
    return cond
