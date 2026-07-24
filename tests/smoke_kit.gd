extends SceneTree
# Box of Scrap (rolled free kit) + The Binding gate - locks the team-ratified invariants:
# every seed rolls a DEPLOYABLE box that never touches player.bits; the roll is DETERMINISTIC
# (crack-reveal == run, and no free re-roll); the box never leaks a discovery or a satchel bit;
# satchel flush/spill, purse halving, core faucet @⚙60, no bind->melt arbitrage, v4 save roundtrip.
# (The challenger power-band sim lives in tests/smoke_kit_sim.gd - heavier, run separately.)

func _initialize() -> void:
    var ok := true
    ok = _run("every seed rolls a deployable box (4-5 body bits)", _t_box_deployable_every_seed) and ok
    ok = _run("roll is deterministic (same seed -> same box)", _t_box_deterministic) and ok
    ok = _run("box never touches player.bits", _t_box_isolated) and ok
    ok = _run("box never _discover()s its contents / no free satchel bit", _t_box_no_discover_no_satchel) and ok
    ok = _run("kit run: no extract, free mend, 5 nodes", _t_kit_run_rules) and ok
    ok = _run("kit map is nonce-deterministic (same seed -> same lanes)", _t_kit_map_deterministic) and ok
    ok = _run("purse pays full x2 then halves, never zero", _t_purse_halving) and ok
    ok = _run("salvage flushes on safe end", _t_satchel_flush) and ok
    ok = _run("death spill: zeroed salvage flushes nothing", _t_satchel_spill) and ok
    ok = _run("gleaners due: paid boss death keeps 17/35, loses the bit, burns a slot", _t_gleaners_paid_death) and ok
    ok = _run("gleaners due: empty-handed death pays nothing, burns nothing", _t_gleaners_unpaid_death) and ok
    ok = _run("binding mints chosen core for 60", _t_binding_mints) and ok
    ok = _run("binding refuses: short scrap / non-core id", _t_binding_refuses) and ok
    ok = _run("no bind->melt arbitrage (cores melt for 0)", _t_no_arbitrage) and ok
    ok = _run("v4 save: kit_box_nonce roundtrips", _t_save_roundtrip) and ok
    print("SMOKE PASS" if ok else "SMOKE FAIL")
    quit(0 if ok else 1)

func _body_count(m: ManabitState) -> int:
    var n := 0
    for slot in ManabitState.SLOT_NAMES:
        var pi: PartInstance = m.slots.get(slot)
        if pi != null and not pi.data.is_core:
            n += 1
    return n

func _first_body(m: ManabitState) -> PartInstance:
    for slot in ManabitState.SLOT_NAMES:
        var pi: PartInstance = m.slots.get(slot)
        if pi != null and not pi.data.is_core:
            return pi
    return null

func _t_box_deployable_every_seed() -> bool:
    for seed in [1, 7, 42, 99, 1234, 20260717, 88888]:
        var m := RunState.kit_build(seed)
        if not (m.alive() and m.has_offensive_move() and m.core() != null):
            return false
        var bc := _body_count(m)
        if bc < 4 or bc > 5:
            return false
    return true

func _t_box_deterministic() -> bool:
    if BoxRoller.grade(42) != BoxRoller.grade(42):
        return false
    var a := RunState.kit_build(42)
    var b := RunState.kit_build(42)
    var da := a.derived()
    var db := b.derived()
    if int(da.attack) != int(db.attack) or int(da.defense) != int(db.defense) \
        or int(da.speed) != int(db.speed) or int(da.weight) != int(db.weight) or int(da.energy) != int(db.energy):
        return false
    for slot in ManabitState.SLOT_NAMES:
        if (a.slots.get(slot) == null) != (b.slots.get(slot) == null):
            return false
    return true

func _t_box_isolated() -> bool:
    var p := PlayerState.new()
    p.grant_starter_kit()
    var before := p.bits.size()
    var _m := RunState.kit_build(7)
    var r := RunState.new()
    r.start_kit(7)
    return p.bits.size() == before and r.carried.core() != null

func _t_box_no_discover_no_satchel() -> bool:
    var p := PlayerState.new()
    var before := p.compendium.size()
    var r := RunState.new()
    r.start_kit(20260717)
    return p.compendium.size() == before and r.satchel_bit_id == ""

func _t_kit_run_rules() -> bool:
    var r := RunState.new()
    r.start_kit(7)
    if r.map.size() != 5 or not r.is_kit or r.mname != RunState.KIT_NAME:
        return false
    # the branching road: JUNCTION steps at 2 and 4, on kit runs too
    if String((r.map[2] as Dictionary).get("type", "")) != "JUNCTION":
        return false
    if String((r.map[4] as Dictionary).get("type", "")) != "JUNCTION":
        return false
    r.advance()                                   # pos 1 = REST
    if r.can_extract():
        return false                              # a Box is never yours to bank
    var bit := _first_body(r.carried)             # a rolled ARM_R may be null - grab any body bit
    if bit == null:
        return false
    bit.take_damage(3)
    if not r.is_damaged():
        return false
    r.repair_all()                                # the free mend path
    return not r.is_damaged() and int(bit.current_hp) == bit.data.max_hp

# nonce parity now covers the road: the same seed deals the same box AND the same lanes.
func _t_kit_map_deterministic() -> bool:
    var a := RunState.new()
    a.start_kit(7)
    var b := RunState.new()
    b.start_kit(7)
    for i in [2, 4]:
        var pa: Array = (a.map[i] as Dictionary).get("paths", [])
        var pb: Array = (b.map[i] as Dictionary).get("paths", [])
        if pa.size() != 2 or pb.size() != 2:
            return false
        for k in 2:
            var ca: Dictionary = pa[k]["node"]["challenger"]
            var cb: Dictionary = pb[k]["node"]["challenger"]
            if String(ca.get("name", "")) != String(cb.get("name", "")):
                return false
    return true

func _t_purse_halving() -> bool:
    var p := PlayerState.new()
    var day := 100
    if p.kit_purse("skirmish", day) != 10 or p.kit_purse("elite", day) != 25 or p.kit_purse("boss", day) != 40:
        return false
    p.note_kit_run(day)
    p.note_kit_run(day)
    if p.kit_purse("skirmish", day) != 5 or p.kit_purse("elite", day) != 12 or p.kit_purse("boss", day) != 20:
        return false
    if p.kit_purse("bogus", day) != 0:
        return false                              # unknown tier pays 0 - the fail-safe holds
    return p.kit_purse("skirmish", day + 1) == 10 # a new day rolls back to full rate

func _t_satchel_flush() -> bool:
    var p := PlayerState.new()
    var before_bits := p.bits.size()
    var r := RunState.new()
    r.start_kit(7)
    r.satchel_scrap = 35
    r.satchel_bit_id = "arm_hammer"
    p.flush_satchel(r)
    return p.scrap == 35 and p.bits.size() == before_bits + 1 and p.compendium.has("arm_hammer")

func _t_satchel_spill() -> bool:
    var p := PlayerState.new()
    var r := RunState.new()
    r.start_kit(7)
    r.satchel_scrap = 35
    r.satchel_bit_id = "arm_hammer"
    r.satchel_scrap = 0                           # DEATH zeroes before any flush
    r.satchel_bit_id = ""
    p.flush_satchel(r)
    return p.scrap == 0 and p.bits.is_empty()

# Wave 3 - the Gleaner's Due death-keep fixtures. A paid death (kept > 0) credits the wallet
# AND burns a daily full-rate slot via note_kit_run (the G10 halving-loophole closure - a
# budgeted, deliberate change to the old free-death behavior). The tucked bit is always lost.
func _t_gleaners_paid_death() -> bool:
    var p := PlayerState.new()
    var r := RunState.new()
    r.start_kit(7)
    r.satchel_scrap = 35
    r.satchel_bit_id = "arm_hammer"
    var kept := r.kit_death_spill("boss")             # full-HP survivors -> H = 1 -> keeps 17
    p.gleaners_pay(kept, 200)
    if kept != 17 or p.scrap != 17 or p.kit_runs_today != 1:
        return false
    if r.satchel_scrap != 0 or r.satchel_bit_id != "":
        return false
    p.flush_satchel(r)                                # the spilled satchel carries nothing extra
    return p.scrap == 17 and p.bits.is_empty()

func _t_gleaners_unpaid_death() -> bool:
    var p := PlayerState.new()
    var r := RunState.new()
    r.start_kit(7)
    r.satchel_scrap = 0
    r.satchel_bit_id = "arm_hammer"
    var kept := r.kit_death_spill("elite")
    p.gleaners_pay(kept, 200)
    return kept == 0 and p.scrap == 0 and p.kit_runs_today == 0 and r.satchel_bit_id == ""

func _t_binding_mints() -> bool:
    var p := PlayerState.new()
    p.scrap = 60
    var before := p.bits.size()
    if not p.bind_core("core_bulwark"):
        return false
    if p.scrap != 0 or p.bits.size() != before + 1:
        return false
    var minted: PartInstance = p.bits[p.bits.size() - 1]
    return minted.data.is_core and String(minted.data.id) == "core_bulwark" and p.compendium.has("core_bulwark")

func _t_binding_refuses() -> bool:
    var p := PlayerState.new()
    p.scrap = 59
    if p.bind_core("core_ember"):
        return false
    p.scrap = 200
    if p.bind_core("arm_hammer"):
        return false
    return p.scrap == 200 and p.bits.is_empty()

func _t_no_arbitrage() -> bool:
    var p := PlayerState.new()
    p.scrap = 60
    p.bind_core("core_ember")
    var core: PartInstance = p.bits[0]
    return p.melt_bit(core) == 0 and p.distill_bit(core) == 0 and p.bits.size() == 1

func _t_save_roundtrip() -> bool:
    var p := PlayerState.new()
    p.grant_starter_kit()
    p.note_kit_run(123)
    p.note_kit_run(123)
    p.kit_box_nonce = 5
    p.save()
    var q := PlayerState.new()
    if not SaveManager.load_into(q):
        return false
    return q.kit_runs_today == 2 and q.last_kit_run_day == 123 and q.kit_box_nonce == 5 \
        and PlayerState.new().kit_box_nonce == 0

func _run(name: String, fn: Callable) -> bool:
    var res = fn.call()
    var pass_ok: bool = (res == true)
    print(("  [%s] " % ("PASS" if pass_ok else "FAIL")) + name)
    return pass_ok
