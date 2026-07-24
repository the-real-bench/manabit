extends SceneTree
# Settle D13 severity: is the GUARD-when-behind stall (opt_probe) a TRUE non-terminating fight
# (latent softlock) or just capped at 100? Run the SAME guard-when-behind policy vs the shipped
# Brassmore/Gildfall AI to a 1,000,000 cap. Also a maximally-degenerate mutual-mend/guard case.

func _initialize() -> void:
    var byid := Catalog.by_id()
    var ch := Challengers.list()
    var flagship := {"HEAD": "steadfast_beacon_brow", "CORE": "grumble_co_keystone_core",
        "ARM_L": "grumble_co_bastion_fist", "ARM_R": "arm_seer",
        "LEGS": "pocketful_legs_stubby", "BACK": "pocketful_back_pippack"}
    if not byid.has("steadfast_beacon_brow"):
        flagship["HEAD"] = "sovereign_brass_head_herald"

    for idx in [4, 8]:
        var res := _guard_vs_ship(_mk(flagship, byid), Challengers.make(ch[idx]), true, 1000000)
        var word := _rn(res["res"])
        if res["res"] == Combat.Result.ONGOING:
            word = "STILL-ONGOING@1M (NON-TERMINATING)"
        print("  GUARD-policy flagship vs %-30s -> %s at turn %d (myCore %d/%d foeCore %d/%d)" % [
            String(ch[idx]["name"]).get_slice(",", 0), word, res["turns"],
            res["mc"], res["mcm"], res["fc"], res["fcm"]])

    print("QA STALL DONE")
    quit(0)

func _mk(ids: Dictionary, byid: Dictionary) -> ManabitState:
    var m := ManabitState.new()
    for slot in ManabitState.SLOT_NAMES:
        var id: String = String(ids.get(slot, ""))
        m.slots[slot] = PartInstance.new(byid[id]) if byid.has(id) else null
    return m

func _guard_vs_ship(me: ManabitState, foe: ManabitState, aim: bool, cap: int) -> Dictionary:
    var c := Combat.new()
    c.start(me, foe, aim)
    var ps := {}
    var g := 0
    while c.outcome() == Combat.Result.ONGOING and g < cap:
        var actor := c.current()
        if actor == me: _policy_turn(c, me, foe, ps)
        else: c.ai_take_turn(foe, me)
        if c.outcome() == Combat.Result.ONGOING: c.advance_turn()
        g += 1
    var mc: PartInstance = me.slots.get("CORE")
    var fc: PartInstance = foe.slots.get("CORE")
    return {"res": c.outcome(), "turns": g,
        "mc": mc.current_hp if mc else 0, "mcm": mc.data.max_hp if mc else 0,
        "fc": fc.current_hp if fc else 0, "fcm": fc.data.max_hp if fc else 0}

# EXACT copy of opt_probe.gd _policy_turn (core-aim + guard-when-behind), the pentagon_v2 lens.
func _policy_turn(c: Combat, attacker: ManabitState, defender: ManabitState, pstate: Dictionary) -> void:
    var moves: Array = c.moves_for(attacker)
    if moves.is_empty(): return
    var default_mv: Dictionary = moves[0]
    for mv in moves:
        if (mv["ability"] as AbilityData).archetype != "GUARD":
            default_mv = mv
            break
    var atk := int(attacker.derived().attack)
    var dfn := int(defender.derived().defense) + defender.guard_bonus
    var core_mv := {}
    var core_dmg := 0
    for mv2 in moves:
        var a2: AbilityData = mv2["ability"]
        if a2.archetype == "SINGLE" and a2.can_target_core:
            var d2 := maxi(1, atk + a2.power - dfn)
            if d2 > core_dmg:
                core_dmg = d2
                core_mv = mv2
    var def_ab: AbilityData = default_mv["ability"]
    var def_dmg := 0
    if def_ab.archetype != "GUARD":
        def_dmg = maxi(1, atk + def_ab.power - dfn) * maxi(1, def_ab.hit_count)
    if not core_mv.is_empty() and core_dmg > def_dmg:
        c.perform(attacker, core_mv["ability"], defender, "CORE")
        pstate["guarded"] = false
        return
    var mc: PartInstance = attacker.slots.get("CORE")
    var fc: PartInstance = defender.slots.get("CORE")
    if mc != null and fc != null and not bool(pstate.get("guarded", false)):
        var my_r := float(mc.current_hp) / float(mc.data.max_hp)
        var foe_r := float(fc.current_hp) / float(fc.data.max_hp)
        if my_r + 0.15 < foe_r:
            for mv3 in moves:
                var a3: AbilityData = mv3["ability"]
                if a3.archetype == "GUARD":
                    c.perform(attacker, a3, defender, "")
                    pstate["guarded"] = true
                    return
    if def_ab.archetype == "GUARD":
        c.perform(attacker, def_ab, defender, "")
        pstate["guarded"] = true
        return
    c.perform(attacker, def_ab, defender, c._multi_target(defender))
    pstate["guarded"] = false

func _rn(r: int) -> String:
    match r:
        Combat.Result.WIN: return "WIN"
        Combat.Result.DEATH: return "DEATH"
        Combat.Result.SURVIVABLE_LOSS: return "SURVIVABLE_LOSS"
        _: return "ONGOING"
