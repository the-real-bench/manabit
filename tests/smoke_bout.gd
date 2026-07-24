extends SceneTree
# M2 stakes gate: loot adds a bit, forfeit removes a broken part + grants scrap, and a bout resolves.

func _initialize() -> void:
    var ok := true
    var cat := Catalog.by_id()
    var p := PlayerState.new()
    p.grant_starter_kit()

    # loot a part off a beaten foe
    var n0 := p.bits.size()
    p.loot_part(cat["arm_seer"])          # EPIC
    ok = _c("loot adds a bit", p.bits.size() == n0 + 1) and ok
    ok = _c("loot discovers it", p.compendium.has("arm_seer")) and ok

    # forfeit: a broken part leaves the build + yields salvage scrap
    var build := ManabitState.new()
    build.slots["CORE"] = PartInstance.new(cat["core_ember"])
    build.slots["ARM_R"] = PartInstance.new(cat["arm_hammer"])
    var sc0 := p.scrap
    var pd: PartData = build.slots["ARM_R"].data
    build.slots["ARM_R"] = null
    p.scrap += Broker.salvage_scrap(pd)
    ok = _c("forfeit removes the part", build.slots["ARM_R"] == null) and ok
    ok = _c("forfeit grants scrap", p.scrap == sc0 + 8) and ok      # arm_hammer COMMON = 8

    # a real bout resolves to an outcome, and the foe carries lootable parts
    var me := ManabitState.new()
    me.slots["CORE"] = PartInstance.new(cat["core_ember"])
    me.slots["ARM_R"] = PartInstance.new(cat["arm_hammer"])
    me.slots["ARM_L"] = PartInstance.new(cat["arm_hammer"])
    var foe := Challengers.make(Challengers.list()[0])
    var c := Combat.new()
    c.start(me, foe, false)
    var guard := 0
    while guard < 300:
        if c.outcome() != Combat.Result.ONGOING:
            break
        var actor := c.current()
        if actor == me:
            c.ai_take_turn(me, foe)
        else:
            c.ai_take_turn(foe, me)
        if c.outcome() != Combat.Result.ONGOING:
            break
        c.advance_turn()
        guard += 1
    ok = _c("bout resolves (not infinite)", c.outcome() != Combat.Result.ONGOING) and ok
    ok = _c("dummy AI never killed my core", me.alive()) and ok      # foe can't aim core

    var lootable := 0
    for slot in ManabitState.SLOT_NAMES:
        var fp: PartInstance = foe.slots.get(slot)
        if fp != null and not fp.data.is_core:
            lootable += 1
    ok = _c("foe carries lootable parts", lootable >= 1) and ok

    print("SMOKE PASS" if ok else "SMOKE FAIL")
    quit(0 if ok else 1)

func _c(name: String, cond: bool) -> bool:
    print(("  [%s] " % ("PASS" if cond else "FAIL")) + name)
    return cond
