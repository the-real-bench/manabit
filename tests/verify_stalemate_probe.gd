extends SceneTree
# INDEPENDENT verify probe (not the shipped gate). Two things the shipped gate does not isolate:
#   A. The EXACT owner scenario shape: a BOSS (enemy_can_aim_core=true) whose offensive arms have
#      BROKEN OFF mid-fight (a disabled SINGLE arm + a live GUARD arm) vs a player holding an
#      offensive arm whose cost > energy. outcome() must sit at ONGOING and no damage land; the
#      driver must time it out to SURVIVABLE_LOSS.
#   B. An EXPLICIT turn-cap safety net (500) proving the driver never runs forever - not the
#      wall-clock timeout the gate uses. We assert the fight ended AND turn_index stayed small.

func _initialize() -> void:
    _run()

func _run() -> void:
    var ok := true

    # ---- Resolver-only: prove the owner-shape stalemate is real and NEVER self-terminates ----
    var pair := _owner_pair()
    var me: ManabitState = pair[0]
    var foe: ManabitState = pair[1]
    var c := Combat.new()
    c.start(me, foe, true)                    # BOSS: enemy_can_aim_core = true
    var hp0 := _sum(me) + _sum(foe)
    var TURN_CAP := 500
    var reached_cap := false
    var t := 0
    while c.outcome() == Combat.Result.ONGOING:
        var actor := c.current()
        if actor == me:
            c.ai_take_turn(me, foe)
        else:
            c.ai_take_turn(foe, me)
        if c.outcome() != Combat.Result.ONGOING:
            break
        c.advance_turn()
        t += 1
        if t >= TURN_CAP:
            reached_cap = true
            break
    ok = _c("resolver-only owner-shape runs to the 500 cap (never self-terminates)", reached_cap) and ok
    ok = _c("resolver-only: outcome still ONGOING at the cap", c.outcome() == Combat.Result.ONGOING) and ok
    ok = _c("resolver-only: zero damage landed (combined HP flat)", _sum(me) + _sum(foe) == hp0) and ok
    ok = _c("resolver-only: player STILL has an offensive bit (so NOT SURVIVABLE_LOSS)", me.has_offensive_move()) and ok

    # ---- Driver: same owner-shape through the REAL combat_screen loop, explicit turn cap ----
    var p2 := _owner_pair()
    var me2: ManabitState = p2[0]
    var foe2: ManabitState = p2[1]
    var player := PlayerState.new()
    var scrap0 := player.scrap
    var screen := CombatScreen.new()
    screen.setup(player)
    get_root().add_child(screen)
    await process_frame
    await process_frame
    screen._me = me2
    screen._foe = foe2
    screen._foe_name = "Boss (arms broken off)"
    screen._stakes = true
    screen._run_mode = false
    screen._real_build = me2
    screen._kit_run = null
    screen._auto = true
    screen._title.text = "OWNER SHAPE"
    var dhp0 := _sum(me2) + _sum(foe2)
    screen._start(true)                       # foe aims core (boss)

    # Poll with an explicit budget: STALEMATE_LIMIT is 10 turns; each turn ~ a couple frames +
    # short auto think. 1200 polls * 40ms = 48s ceiling is a safety net only.
    var ended := false
    var polls := 0
    while polls < 1200:
        if screen._state == "over":
            ended = true
            break
        await create_timer(0.04).timeout
        polls += 1
    ok = _c("driver: owner-shape fight ENDED (did not hang)", ended) and ok
    await create_timer(1.0).timeout

    ok = _c("driver: resolved to SURVIVABLE_LOSS", screen.last_result == Combat.Result.SURVIVABLE_LOSS) and ok
    ok = _c("driver: flagged as stalemate", screen._stalemate) and ok
    ok = _c("driver: fired at exactly STALEMATE_LIMIT (%d) no-progress turns" % CombatScreen.STALEMATE_LIMIT, screen._noprog_turns == CombatScreen.STALEMATE_LIMIT) and ok
    ok = _c("driver: combat.turn_index stayed well under the 500 cap (was %d)" % screen.combat.turn_index, screen.combat.turn_index < 40) and ok
    ok = _c("driver: both cores alive (cozy-fair, nobody unmade)", me2.alive() and foe2.alive()) and ok
    ok = _c("driver: zero damage landed across the whole fight", _sum(me2) + _sum(foe2) == dhp0) and ok
    ok = _c("driver: no scrap moved", player.scrap == scrap0) and ok

    print("PROBE PASS" if ok else "PROBE FAIL")
    quit(0 if ok else 1)

# Owner shape: BOSS foe whose offensive arm has BROKEN OFF (disabled SINGLE) leaving only a GUARD arm;
# player holds a nuke arm whose cost (8) exceeds its energy (3) -> never affordable.
func _owner_pair() -> Array:
    var me := ManabitState.new()
    me.slots["CORE"] = PartInstance.new(_core(3, 40, "attack"))
    me.slots["ARM_R"] = PartInstance.new(_weapon("ARM_R", 20, 8, 10))   # cost 8 > energy 3
    var foe := ManabitState.new()
    foe.slots["CORE"] = PartInstance.new(_core(21, 40, "defense"))       # a real boss energy
    foe.slots["ARM_L"] = PartInstance.new(_guard("ARM_L", 2, 1, 8))      # live GUARD arm
    var brokenarm := PartInstance.new(_weapon("ARM_R", 15, 3, 8))        # the boss's offensive arm ...
    brokenarm.current_hp = 0
    brokenarm.disabled = true                                            # ... BROKEN OFF mid-fight
    foe.slots["ARM_R"] = brokenarm
    return [me, foe]

func _core(energy: int, hp: int, aff: String) -> PartData:
    var p := PartData.new()
    p.id = &"vp_core"; p.display_name = "VP Core"; p.slot = "CORE"; p.is_core = true
    p.affinity = aff; p.max_hp = hp; p.energy = energy; p.rarity = "COMMON"
    return p

func _weapon(slot: String, power: int, cost: int, hp: int) -> PartData:
    var p := PartData.new()
    p.id = &"vp_weapon"; p.display_name = "VP Nuke"; p.slot = slot; p.max_hp = hp
    var a := AbilityData.new()
    a.archetype = "SINGLE"; a.display_name = "Nuke"; a.power = power; a.mana_cost = cost; a.can_target_core = true
    p.ability = a
    return p

func _guard(slot: String, amount: int, cost: int, hp: int) -> PartData:
    var p := PartData.new()
    p.id = &"vp_guard"; p.display_name = "VP Buckler"; p.slot = slot; p.max_hp = hp
    var a := AbilityData.new()
    a.archetype = "GUARD"; a.guard_kind = "DEF_BUFF"; a.guard_amount = amount; a.mana_cost = cost
    p.ability = a
    return p

func _sum(m: ManabitState) -> int:
    var s := 0
    for slot in ManabitState.SLOT_NAMES:
        var pi = m.slots.get(slot)
        if pi != null:
            s += pi.current_hp
    return s

func _c(name: String, cond: bool) -> bool:
    print(("  [%s] " % ("PASS" if cond else "FAIL")) + name)
    return cond
