extends SceneTree

func _initialize() -> void:
    var ok := true
    ok = _run("assemble + derived", _t_assemble) and ok
    ok = _run("win -> loot enemy part", _t_win_loot) and ok
    ok = _run("survivable loss -> forfeit disabled part", _t_survivable_loss) and ok
    ok = _run("death ends run", _t_death) and ok
    ok = _run("save -> reload roundtrip", _t_save_reload) and ok
    print("SMOKE PASS" if ok else "SMOKE FAIL")
    quit(0 if ok else 1)

func _mk_ability(arch: String, power: int, hits: int, cost: int) -> AbilityData:
    var a := AbilityData.new()
    a.archetype = arch; a.power = power; a.hit_count = hits; a.mana_cost = cost
    return a

func _mk_part(id: String, slot: String, hp: int, atk: int, df: int, spd: int, wt: int, en: int, ab: AbilityData) -> PartData:
    var p := PartData.new()
    p.id = id; p.slot = slot; p.max_hp = hp
    p.attack = atk; p.defense = df; p.speed = spd; p.weight = wt; p.energy = en
    p.ability = ab; p.is_core = (slot == "CORE")
    return p

func _mk_manabit(core_hp: int) -> ManabitState:
    var m := ManabitState.new()
    m.slots["CORE"]  = PartInstance.new(_mk_part("core", "CORE", core_hp, 0, 2, 2, 10, 6, null))
    m.slots["ARM_R"] = PartInstance.new(_mk_part("hammer", "ARM_R", 8, 5, 0, 3, 40, 0, _mk_ability("SINGLE", 4, 1, 1)))
    m.slots["ARM_L"] = PartInstance.new(_mk_part("flail", "ARM_L", 6, 3, 0, 3, 30, 0, _mk_ability("MULTI", 2, 3, 2)))
    m.slots["LEGS"]  = PartInstance.new(_mk_part("legs", "LEGS", 10, 0, 1, 6, 30, 0, null))
    m.start_fight()
    return m

func _t_assemble() -> bool:
    var m := _mk_manabit(30)
    var d := m.derived()
    return m.alive() and m.has_offensive_move() and d.attack == 8 and d.speed == 4

func _t_win_loot() -> bool:
    var enemy := _mk_manabit(1)
    enemy.core().take_damage(5)
    if enemy.alive():
        return false
    var lootable := []
    for pi in enemy.slots.values():
        if pi != null and not pi.data.is_core:
            lootable.append(pi.data.id)
    return lootable.has(&"hammer")

func _t_survivable_loss() -> bool:
    var me := _mk_manabit(30)
    me.slots["ARM_R"].take_damage(99)
    me.slots["ARM_L"].take_damage(99)
    var forced := (not me.has_offensive_move()) and me.alive()
    var disabled := []
    for pi in me.slots.values():
        if pi != null and pi.disabled:
            disabled.append(pi.data.id)
    return forced and disabled.size() >= 1

func _t_death() -> bool:
    var me := _mk_manabit(4)
    me.core().take_damage(4)
    return not me.alive()

func _t_save_reload() -> bool:
    var save := {
        "version": 1,
        "garage": [{ "core_id": "core", "parts": [{ "id": "hammer", "current_hp": 3 }] }],
        "scrap": 7,
    }
    var path := "user://smoke_save.json"
    var f := FileAccess.open(path, FileAccess.WRITE)
    f.store_string(JSON.stringify(save)); f.close()
    var raw := FileAccess.get_file_as_string(path)
    var back = JSON.parse_string(raw)
    return back != null and int(back["scrap"]) == 7 \
        and back["garage"][0]["parts"][0]["id"] == "hammer" \
        and int(back["garage"][0]["parts"][0]["current_hp"]) == 3

func _run(name: String, fn: Callable) -> bool:
    var res = fn.call()
    var pass_ok: bool = (res == true)
    print(("  [%s] " % ("PASS" if pass_ok else "FAIL")) + name)
    return pass_ok
