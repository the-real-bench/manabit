extends SceneTree
# OPTIMIZER PROBE 2: is there real build DEPTH? Compare 3 legal builds under correct RACE play:
#  A NAIVE   - rarity-then-statsum greedy (what an in-game player sees: pick the shiniest EPICs)
#  B INFORMED- roster-post top-delta bits made weight-legal (theorycrafted from the sim numbers)
#  C SNIPER  - a light glass build (speed axis test: does going first matter?)
# vs all 9 challengers (foe hunts core where it does in-run). Also: fastest kill (skill ceiling).

const TURN_CAP := 100

func _initialize() -> void:
    var byid: Dictionary = Catalog.by_id()
    var A := {"HEAD": "steadfast_beacon_brow", "CORE": "grumble_co_keystone_core", "ARM_L": "grumble_co_bastion_fist",
        "ARM_R": "arm_seer", "LEGS": "pocketful_legs_stubby", "BACK": "pocketful_back_pippack"}
    # fall back if the steadfast head id differs
    if not byid.has("steadfast_beacon_brow"):
        A["HEAD"] = "sovereign_brass_head_herald"
    var B := {"HEAD": "sovereign_brass_head_herald", "CORE": "grumble_co_keystone_core", "ARM_L": "grumble_co_girder_fist",
        "ARM_R": "sovereign_brass_arm_pistonfist", "LEGS": "cobble_sons_legs_bedrock", "BACK": "pith_sinew_deep_pulse_sac"}
    var C := {"HEAD": "head_optic", "CORE": "core_ember", "ARM_L": "boldheart_arm_sunder",
        "ARM_R": "sovereign_brass_arm_pistonfist", "LEGS": "legs_light", "BACK": "chatterbox_notion_pack"}
    for pair in [["A NAIVE(rarity)", A], ["B INFORMED(delta)", B], ["C SNIPER(light)", C]]:
        _legal(pair[0], pair[1], byid)

    var ch := Challengers.list()
    print("\n== RACE play (pure aggression, strong build) vs each challenger; run-aim where elite/boss ==")
    print("   %-16s | %-14s %-14s %-14s" % ["challenger", "A naive", "B informed", "C sniper"])
    for i in ch.size():
        var aims := bool(ch[i].get("elite", false))
        var ra := _race(_mk(A, byid), Challengers.make(ch[i]), aims)
        var rb := _race(_mk(B, byid), Challengers.make(ch[i]), aims)
        var rc := _race(_mk(C, byid), Challengers.make(ch[i]), aims)
        print("   %-16s | %-14s %-14s %-14s" % [String(ch[i]["name"]).get_slice(",", 0),
            "%s t%d" % [_rn(ra["res"]), ra["turns"]],
            "%s t%d" % [_rn(rb["res"]), rb["turns"]],
            "%s t%d" % [_rn(rc["res"]), rc["turns"]]])

    # head-to-head A vs B (both RACE) both role orders
    print("\n== head-to-head A naive vs B informed (RACE, both role orders) ==")
    var h1 := _race(_mk(A, byid), _mk(B, byid), true)
    var h2 := _race(_mk(B, byid), _mk(A, byid), true)
    print("   A(player) vs B(foe): %s t%d   |   B(player) vs A(foe): %s t%d" % [
        _rn(h1["res"]), h1["turns"], _rn(h2["res"]), h2["turns"]])

    # fastest kill: A races Rusty
    var rk := _race(_mk(B, byid), Challengers.make(ch[0]), false)
    print("\n== fastest kill: B informed vs Scrap-Pup Rusty -> %s in %d actor-turns ==" % [_rn(rk["res"]), rk["turns"]])
    print("OPT PROBE2 DONE")
    quit(0)

func _mk(ids: Dictionary, byid: Dictionary) -> ManabitState:
    var m := ManabitState.new()
    for slot in ManabitState.SLOT_NAMES:
        var id: String = String(ids.get(slot, ""))
        m.slots[slot] = PartInstance.new(byid[id]) if byid.has(id) else null
    return m

func _legal(label: String, ids: Dictionary, byid: Dictionary) -> void:
    var d := _mk(ids, byid).derived()
    var ok := int(d.weight) <= int(d.capacity)
    print("  %-18s w %d/%d spd %d atk %d def %d  %s" % [label, int(d.weight), int(d.capacity),
        int(d.speed), int(d.attack), int(d.defense), "LEGAL" if ok else "!!OVERWEIGHT!!"])

func _race(me: ManabitState, foe: ManabitState, foe_aims: bool) -> Dictionary:
    var c := Combat.new()
    c.start(me, foe, foe_aims)
    var g := 0
    while c.outcome() == Combat.Result.ONGOING and g < TURN_CAP:
        var actor := c.current()
        if actor == me: _race_turn(c, me, foe)
        else: c.ai_take_turn(foe, me)  # foe = shipped brain
        if c.outcome() == Combat.Result.ONGOING: c.advance_turn()
        g += 1
    return {"res": c.outcome(), "turns": g}

func _race_turn(c: Combat, attacker: ManabitState, defender: ManabitState) -> void:
    var moves: Array = c.moves_for(attacker)
    if moves.is_empty(): return
    var atk := int(attacker.derived().attack)
    var dfn := int(defender.derived().defense) + defender.guard_bonus
    var core_mv := {}; var core_dmg := 0
    for mv in moves:
        var a: AbilityData = mv["ability"]
        if a.archetype == "SINGLE" and a.can_target_core:
            var dd := maxi(1, atk + a.power - dfn)
            if dd > core_dmg: core_dmg = dd; core_mv = mv
    if not core_mv.is_empty():
        c.perform(attacker, core_mv["ability"], defender, "CORE"); return
    var best := {}
    for mv2 in moves:
        if (mv2["ability"] as AbilityData).archetype != "GUARD": best = mv2; break
    if best.is_empty(): best = moves[0]
    c.perform(attacker, best["ability"], defender, c._multi_target(defender))

func _rn(r: int) -> String:
    match r:
        Combat.Result.WIN: return "WIN"
        Combat.Result.DEATH: return "DEATH"
        Combat.Result.SURVIVABLE_LOSS: return "S-LOSS"
        _: return "STALL"
