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

    # Take to the bench: unbank returns the same bits (carried HP intact) and empties the slot.
    q.menagerie[0]["parts"][1]["current_hp"] = 1
    var back := q.unbank_manabit(q.menagerie[0])
    ok = _check("unbank removes from menagerie", q.menagerie.is_empty()) and ok
    ok = _check("unbank returns core + arm", back.has("CORE") and back.has("ARM_R")) and ok
    ok = _check("unbank keeps carried HP", back.has("ARM_R") and (back["ARM_R"] as PartInstance).current_hp == 1) and ok
    ok = _check("unbank leaves binds_total", q.binds_total == 1) and ok

    # The bench saves: a Manabit taken out to fight survives a reload in exactly one place.
    q.bench = ManabitState.new()
    for s in back:
        q.bench.slots[s] = back[s]
    q.save()
    var b := PlayerState.new()
    SaveManager.load_into(b)
    ok = _check("bench roundtrips", b.bench != null and b.bench.slots.get("CORE") != null and b.bench.slots.get("ARM_R") != null) and ok
    ok = _check("bench keeps carried HP", b.bench.slots.get("ARM_R") != null and (b.bench.slots["ARM_R"] as PartInstance).current_hp == 1) and ok
    ok = _check("benched Manabit not also in menagerie", b.menagerie.is_empty()) and ok

    print("SMOKE PASS" if ok else "SMOKE FAIL")
    quit(0 if ok else 1)

func _check(name: String, cond: bool) -> bool:
    print(("  [%s] " % ("PASS" if cond else "FAIL")) + name)
    return cond
