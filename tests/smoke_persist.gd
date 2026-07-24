extends SceneTree
# Persistence gate: bank a Manabit, save, reload into a fresh PlayerState, assert roundtrip.

func _initialize() -> void:
    var ok := true
    var p := PlayerState.new()
    p.grant_starter_kit()
    var loose_before := p.bits.size()
    var comp_before := p.compendium.size()
    var coffers_before := p.coffer_count()

    var m := ManabitState.new()
    m.slots["CORE"] = PartInstance.new(Catalog.starter_cores()[0])
    m.slots["ARM_R"] = PartInstance.new(Catalog.body_pool()[2])   # arm_hammer
    p.bank_manabit("TestBot", m)
    ok = _check("bank adds to menagerie", p.menagerie.size() == 1) and ok
    ok = _check("bank increments binds_total", p.binds_total == 1) and ok
    p.save()

    var q := PlayerState.new()
    var loaded := SaveManager.load_into(q)
    ok = _check("save file loads", loaded) and ok
    ok = _check("menagerie roundtrips", q.menagerie.size() == 1 and String(q.menagerie[0].get("name", "")) == "TestBot") and ok
    ok = _check("banked stats survive", int(q.menagerie[0].get("atk", -1)) >= 0) and ok
    ok = _check("loose bits roundtrip", q.bits.size() == loose_before) and ok
    ok = _check("compendium roundtrips", q.compendium.size() == comp_before) and ok
    ok = _check("coffers roundtrip", q.coffer_count() == coffers_before) and ok
    ok = _check("binds_total roundtrips", q.binds_total == 1) and ok

    # v4-additive migration: a save WITHOUT binds_total seeds it from the menagerie size,
    # so existing veterans (even later wiped to zero Manabits) never see the tag.
    var raw := FileAccess.get_file_as_string(SaveManager.PATH)
    var data = JSON.parse_string(raw)
    data.erase("binds_total")
    var f := FileAccess.open(SaveManager.PATH, FileAccess.WRITE)
    f.store_string(JSON.stringify(data))
    f.close()
    var r := PlayerState.new()
    SaveManager.load_into(r)
    ok = _check("absent binds_total seeds from menagerie size", r.binds_total == 1) and ok

    print("SMOKE PASS" if ok else "SMOKE FAIL")
    quit(0 if ok else 1)

func _check(name: String, cond: bool) -> bool:
    print(("  [%s] " % ("PASS" if cond else "FAIL")) + name)
    return cond
