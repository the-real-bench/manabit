extends SceneTree
# res://tests/smoke_builder.gd - builder-logic gate (mirrors §13.7 discipline).
# Run: godot --headless --path . --import   (once)
#      godot --headless --path . -s res://tests/smoke_builder.gd

func _initialize() -> void:
    var ok := true
    ok = _run("slot-fit rules", _t_slot_fit) and ok
    ok = _run("equip drives derived() + overweight SPD", _t_derived) and ok
    ok = _run("preview_derived_with is non-mutating", _t_preview) and ok
    ok = _run("swap conserves parts (displacement)", _t_swap_conserve) and ok
    ok = _run("deployability invariant (§13.2)", _t_deployable) and ok
    print("SMOKE PASS" if ok else "SMOKE FAIL")
    quit(0 if ok else 1)

func _stock(session: BuildSession) -> Dictionary:
    var map := {}
    for pd in Catalog.starter_cores():
        var pi := PartInstance.new(pd); session.add_to_inventory(pi); map[String(pd.id)] = pi
    for pd2 in Catalog.body_pool():
        var pi2 := PartInstance.new(pd2); session.add_to_inventory(pi2); map[String(pd2.id)] = pi2
    return map

func _t_slot_fit() -> bool:
    var s := BuildSession.new()
    var m := _stock(s)
    var core: PartInstance = m["core_ember"]
    var hammer: PartInstance = m["arm_hammer"]     # authored slot ARM_L
    var head: PartInstance = m["head_optic"]
    return s.slot_accepts("CORE", core) \
        and not s.slot_accepts("HEAD", core) \
        and s.slot_accepts("ARM_L", hammer) and s.slot_accepts("ARM_R", hammer) \
        and not s.slot_accepts("CORE", hammer) \
        and s.slot_accepts("HEAD", head) and not s.slot_accepts("ARM_L", head)

func _t_derived() -> bool:
    var s := BuildSession.new()
    var m := _stock(s)
    var d0 := s.current_derived()
    if int(d0.capacity) != 100:
        return false                               # no core seated -> flat base capacity
    s.equip("CORE", m["core_bulwark"])             # wt16 atk1 def3 spd1 en6, CARRY +6 -> capacity 106
    s.equip("ARM_L", m["arm_hammer"])              # wt40 atk6 spd1
    s.equip("LEGS", m["legs_tread"])               # wt44 def3 spd2
    var d := s.current_derived()
    if int(d.weight) != 100 or int(d.attack) != 7:
        return false                               # under the raised budget, no penalty
    s.equip("HEAD", m["head_optic"])               # wt8 -> 108
    var d2 := s.current_derived()
    # core_bulwark CARRY +6 -> budget 106; 108 over by 2 -> base spd 6 - 2 = 4
    return int(d2.weight) == 108 and int(d2.speed) == 4 and int(d2.capacity) == 106

func _t_preview() -> bool:
    var s := BuildSession.new()
    var m := _stock(s)
    s.equip("CORE", m["core_ember"])               # atk2
    var before: int = int(s.current_derived().attack)
    var proj := s.preview_derived_with("ARM_L", m["arm_hammer"])   # +6 atk projected
    var after: int = int(s.current_derived().attack)
    return before == after and int(proj.attack) == before + 6

func _t_swap_conserve() -> bool:
    var s := BuildSession.new()
    var m := _stock(s)
    var inv0: int = s.inventory.size()
    s.equip("ARM_L", m["arm_hammer"])
    var displaced := s.equip("ARM_L", m["arm_flail"])   # displaces hammer back to tray
    var equipped := 0
    for sn in ManabitState.SLOT_NAMES:
        if s.manabit.slots.get(sn) != null:
            equipped += 1
    return displaced == m["arm_hammer"] and equipped == 1 \
        and s.inventory.size() == inv0 - 1 \
        and s.inventory.has(m["arm_hammer"])

func _t_deployable() -> bool:
    var s := BuildSession.new()
    var m := _stock(s)
    if s.is_deployable():
        return false                               # empty build -> no
    s.equip("CORE", m["core_ember"])
    if s.is_deployable():
        return false                               # core only, no offensive part -> no
    s.equip("ARM_L", m["arm_hammer"])              # a SINGLE attack
    return s.is_deployable()                        # live core + offensive -> yes

func _run(name: String, fn: Callable) -> bool:
    var res = fn.call()
    var pass_ok: bool = (res == true)
    print(("  [%s] " % ("PASS" if pass_ok else "FAIL")) + name)
    return pass_ok
