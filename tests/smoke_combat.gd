extends SceneTree
# M1 combat gate: §13.4 formula, part-break, MULTI->core redirect, can_target_core, GUARD,
# mana gating, the three outcomes, initiative, and the ordinary-AI core-gate.

func _initialize() -> void:
    var ok := true

    # 1. SINGLE damage routes through the formula onto the chosen part
    var c := Combat.new()
    var me := _fighter("core_ember", [["ARM_R", "arm_hammer"], ["HEAD", "head_optic"]])
    var foe := _fighter("core_bulwark", [["ARM_L", "arm_buckler"]])
    c.start(me, foe)
    var hammer: AbilityData = me.slots["ARM_R"].data.ability
    var tgt: PartInstance = foe.slots["ARM_L"]
    var hp0 := tgt.current_hp
    var expected := maxi(1, int(me.derived().attack) + hammer.power - int(foe.derived().defense))
    c.perform(me, hammer, foe, "ARM_L")
    ok = _c("SINGLE dmg = formula", tgt.current_hp == hp0 - expected) and ok

    # 2. part HP -> 0 disables the slot
    c.perform(me, hammer, foe, "ARM_L")
    ok = _c("part breaks at 0 HP", tgt.disabled and tgt.current_hp == 0) and ok

    # 3. aiming the core to 0 -> WIN
    var guard := 0
    while c.outcome() == Combat.Result.ONGOING and guard < 8:
        c.perform(me, hammer, foe, "CORE")
        guard += 1
    ok = _c("core -> 0 = WIN", c.outcome() == Combat.Result.WIN) and ok

    # 4. can_target_core = false excludes the core while a non-core part lives
    var ab := AbilityData.new()
    ab.archetype = "SINGLE"
    ab.can_target_core = false
    var foe2 := _fighter("core_bulwark", [["ARM_L", "arm_buckler"]])
    var t := Combat.new().targets_for(foe2, ab)
    ok = _c("can_target_core=false hides core", not t.has("CORE") and t.has("ARM_L")) and ok

    # 5. MULTI redirects to the core once the foe is stripped of non-core parts
    var multi := AbilityData.new()
    multi.archetype = "MULTI"
    multi.hit_count = 2
    multi.power = 1
    var foe3 := _fighter("core_bulwark", [])            # core only
    var me3 := _fighter("core_ember", [["ARM_R", "arm_hammer"]])
    var c3 := Combat.new()
    c3.start(me3, foe3)
    var core_before: int = foe3.slots["CORE"].current_hp
    c3.perform(me3, multi, foe3, "")
    ok = _c("MULTI -> core when stripped", foe3.slots["CORE"].current_hp < core_before) and ok

    # 6. GUARD raises guard_bonus and the formula honours it
    var d := _fighter("core_bulwark", [])
    var a := _fighter("core_ember", [["ARM_R", "arm_hammer"]])
    var cc := Combat.new()
    cc.start(a, d)
    var base := maxi(1, int(a.derived().attack) + 5 - int(d.derived().defense))
    var g := AbilityData.new()
    g.archetype = "GUARD"
    g.guard_kind = "DEF_BUFF"
    g.guard_amount = 5
    cc.perform(d, g, a, "")
    var guarded := maxi(1, int(a.derived().attack) + 5 - (int(d.derived().defense) + d.guard_bonus))
    ok = _c("GUARD sets +5 DEF", d.guard_bonus == 5) and ok
    ok = _c("guard reduces damage", guarded < base) and ok

    # 7. mana gates the move list
    var mm := _fighter("core_font", [["ARM_R", "arm_seer"]])   # arm_seer costs 2 mana
    var c4 := Combat.new()
    mm.mana = 0
    ok = _c("no mana -> no moves", c4.moves_for(mm).is_empty()) and ok
    mm.mana = 5
    ok = _c("mana -> move appears", c4.moves_for(mm).size() >= 1) and ok

    # 8. no offensive move but a live core -> SURVIVABLE_LOSS
    var p := _fighter("core_ember", [["ARM_R", "arm_buckler"]])   # buckler = GUARD only
    var e := _fighter("core_bulwark", [["ARM_L", "arm_hammer"]])
    var c5 := Combat.new()
    c5.start(p, e)
    ok = _c("no weapon = SURVIVABLE_LOSS", c5.outcome() == Combat.Result.SURVIVABLE_LOSS) and ok

    # 9. an ordinary enemy will not deliver the killing core blow
    var foeA := _fighter("core_bulwark", [["ARM_L", "arm_hammer"]])
    var meA := _fighter("core_ember", [])                          # only a core
    var c6 := Combat.new()
    c6.start(meA, foeA, false)
    var mycore: int = meA.slots["CORE"].current_hp
    c6.ai_take_turn(foeA, meA)
    ok = _c("ordinary AI spares the core", meA.slots["CORE"].current_hp == mycore) and ok

    # 10. initiative by SPD
    var fast := _fighter("core_ember", [["LEGS", "legs_light"]])   # +6 spd
    var slow := _fighter("core_bulwark", [])
    var c7 := Combat.new()
    c7.start(fast, slow)
    ok = _c("faster player acts first", c7.current() == fast) and ok
    var c8 := Combat.new()
    c8.start(slow, fast)
    ok = _c("faster enemy acts first", c8.current() == fast) and ok

    print("SMOKE PASS" if ok else "SMOKE FAIL")
    quit(0 if ok else 1)

func _fighter(core_id: String, specs: Array) -> ManabitState:
    var m := ManabitState.new()
    var cat := Catalog.by_id()
    m.slots["CORE"] = PartInstance.new(cat[core_id])
    for spec in specs:
        m.slots[spec[0]] = PartInstance.new(cat[spec[1]])
    m.start_fight()
    return m

func _c(name: String, cond: bool) -> bool:
    print(("  [%s] " % ("PASS" if cond else "FAIL")) + name)
    return cond
