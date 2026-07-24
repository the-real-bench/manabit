extends SceneTree
# QA LEAD VERIFICATION PROBE (read-only, seeded, no user:// writes). Drives shipped combat.gd via
# the same pattern as smoke_kit_sim. Reconstructs the QA Hunter repros to CONFIRM/REFUTE:
#  1 Pindrop (ch6) toothless: does it EVER deliver DEATH when aims_core=true? + print its archetypes.
#  2 Sable (ch7) toothless: same.
#  3 Thornlash overgrown (ch5 + swap) vs Wardens Wall Cogsworth (ch3): elite lane death rates.
#  4 No turn cap / grind: Cogsworth mirror aims_core=false to a HUGE cap - finite grind or infinite?
#  5 TRUE softlock hunt: mending-wall stalemate (Sir Vance vs Sir Vance, low-atk player) to huge cap.
#  6 Single-offensive-part forfeit (Q5): core_bulwark + one weapon arm vs Rusty.

const KIT_LO := 400000
const KIT_STEP := 131
const KIT_N := 60

func _initialize() -> void:
    var ch := Challengers.list()

    print("== ARCHETYPE AUDIT (core-hunt fires ONLY for archetype==SINGLE, combat.gd:146-152) ==")
    for idx in [6, 7, 5, 3]:
        var foe := Challengers.make(ch[idx])
        var singles := 0
        var line := "  %-26s: " % String(ch[idx]["name"]).get_slice(",", 0)
        for slot in ManabitState.SLOT_NAMES:
            var pi: PartInstance = foe.slots.get(slot)
            if pi == null or pi.data.ability == null:
                continue
            var a: AbilityData = pi.data.ability
            line += "%s=%s(p%d%s) " % [slot, a.archetype, a.power, "*C" if a.can_target_core else ""]
            if a.archetype == "SINGLE":
                singles += 1
        print(line + "  -> SINGLE moves: %d" % singles)
    # overgrown swap applied
    var tf := Challengers.make(ch[5], "overgrown")
    var os := 0
    var oline := "  %-26s: " % "Thornlash [OVERGROWN]"
    for slot in ManabitState.SLOT_NAMES:
        var pi: PartInstance = tf.slots.get(slot)
        if pi == null or pi.data.ability == null:
            continue
        var a: AbilityData = pi.data.ability
        oline += "%s=%s(p%d%s) " % [slot, a.archetype, a.power, "*C" if a.can_target_core else ""]
        if a.archetype == "SINGLE":
            os += 1
    print(oline + "  -> SINGLE moves: %d" % os)

    print("\n== ELITE CORE-AIM LETHALITY over %d kit builds (aims_core=true) ==" % KIT_N)
    _lethality("Pindrop (ch6)", ch[6], "")
    _lethality("Sable (ch7)", ch[7], "")
    _lethality("Thornlash (ch5) base", ch[5], "")
    _lethality("Thornlash (ch5) OVERGROWN", ch[5], "overgrown")
    _lethality("Cogsworth (ch3)", ch[3], "")
    _lethality("Brassmore (ch4) boss", ch[4], "")
    _lethality("Gildfall (ch8) boss", ch[8], "")

    print("\n== NO-TURN-CAP GRIND: does a fight terminate? (huge cap 200000) ==")
    _grind("Cogsworth mirror (bout, no core-aim)", ch[3], ch[3], false, 200000)
    _grind("Sir Vance mirror (bout, no core-aim)", ch[2], ch[2], false, 200000)

    print("\n== TRUE-SOFTLOCK HUNT: low-attack mender player vs mending wall, bout, cap 500000 ==")
    _softlock_hunt()

    print("\n== SINGLE-OFFENSIVE-PART FORFEIT (Q5): bulwark + 1 weapon arm + legs vs Rusty ==")
    var me := ManabitState.new()
    var cat := Catalog.by_id()
    me.slots["CORE"] = PartInstance.new(cat.get("core_bulwark"))
    me.slots["ARM_R"] = PartInstance.new(cat.get("everykit_standard_fist"))
    me.slots["LEGS"] = PartInstance.new(cat.get("everykit_standard_strider_legs"))
    var r := _drive(me, Challengers.make(ch[0]), false, 200)
    print("  result=%s turns=%d yourCore=%d%% (has_offensive_move at end=%s)" % [
        _rn(r["res"]), r["turns"],
        int(100.0 * r["my_core"] / maxf(1.0, r["my_core_max"])), str(me.has_offensive_move())])
    for l in r["log"]:
        print("     " + str(l))

    print("\nQA VERIFY DONE")
    quit(0)

func _lethality(label: String, entry: Dictionary, mod_id: String) -> void:
    var w := 0; var sl := 0; var dd := 0
    for i in KIT_N:
        var seed := KIT_LO + i * KIT_STEP
        var me := RunState.kit_build(seed)
        var foe := Challengers.make(entry, mod_id)
        var r := _drive(me, foe, true, 300)
        match r["res"]:
            Combat.Result.WIN: w += 1
            Combat.Result.SURVIVABLE_LOSS: sl += 1
            Combat.Result.DEATH: dd += 1
    print("  %-30s  WIN %2d  SURV_LOSS %2d  DEATH %2d   (death rate %.2f)" % [
        label, w, sl, dd, float(dd) / KIT_N])

func _grind(label: String, a_entry: Dictionary, b_entry: Dictionary, aim: bool, cap: int) -> void:
    var me := Challengers.make(a_entry)
    var foe := Challengers.make(b_entry)
    var r := _drive(me, foe, aim, cap)
    var word := _rn(r["res"])
    if r["res"] == Combat.Result.ONGOING:
        word = "STILL-ONGOING@cap"
    print("  %-40s -> %-18s at turn %d" % [label, word, r["turns"]])

func _softlock_hunt() -> void:
    # A build that ONLY guards + mends, vs a mending foe, bout (core never targetable).
    # If neither can disable the other's parts faster than they mend, outcome() loops ONGOING forever.
    var cat := Catalog.by_id()
    # player: a pure warder+cell defensive body with a live core and NO offensive part disabled-yet.
    # Use Sir Vance's own mender loadout as the wall on both sides.
    var me := Challengers.make(Challengers.list()[2])   # Sir Vance (has PART_RESTORE mend)
    var foe := Challengers.make(Challengers.list()[2])
    var r := _drive(me, foe, false, 500000)
    var word := _rn(r["res"])
    if r["res"] == Combat.Result.ONGOING:
        word = "STILL-ONGOING@cap (NON-TERMINATING)"
    print("  Sir Vance vs Sir Vance, bout -> %s at turn %d" % [word, r["turns"]])

func _drive(me: ManabitState, foe: ManabitState, aim: bool, cap: int) -> Dictionary:
    var c := Combat.new()
    c.start(me, foe, aim)
    var g := 0
    while c.outcome() == Combat.Result.ONGOING and g < cap:
        var actor := c.current()
        if actor == me: c.ai_take_turn(me, foe)
        else: c.ai_take_turn(foe, me)
        if c.outcome() == Combat.Result.ONGOING: c.advance_turn()
        g += 1
    var mc: PartInstance = me.slots.get("CORE")
    return {"res": c.outcome(), "turns": g,
        "my_core": float(mc.current_hp) if mc else 0.0,
        "my_core_max": float(mc.data.max_hp) if mc else 1.0,
        "log": c.battle_log}

func _rn(r: int) -> String:
    match r:
        Combat.Result.WIN: return "WIN"
        Combat.Result.DEATH: return "DEATH"
        Combat.Result.SURVIVABLE_LOSS: return "SURVIVABLE_LOSS"
        _: return "ONGOING"
