extends SceneTree
# NEWCOMER PROBE (read-only, deterministic). Builds the cheapest legal Manabits a first-hour
# player would field and fights the tutorial (Rusty ch0) + the first elites (Cogsworth ch3,
# Thornlash ch5). Combat.gd is deterministic so one fight per matchup is the answer.

const TURN_CAP := 120

func _initialize() -> void:
    var ch := Challengers.list()

    var specs := {
        "MINIMAL core+1arm  ": {"CORE":"core_ember", "ARM_L":"arm_hammer"},
        "SPROUT ember       ": {"CORE":"core_ember", "ARM_L":"arm_hammer", "LEGS":"legs_light"},
        "SPROUT bulwark     ": {"CORE":"core_bulwark","ARM_L":"arm_hammer", "LEGS":"legs_light"},
        "SPROUT font        ": {"CORE":"core_font",   "ARM_L":"arm_hammer", "LEGS":"legs_light"},
        "HEAD-ONLY weak     ": {"CORE":"core_ember", "HEAD":"head_optic"},
        "TWO-ARM cheap      ": {"CORE":"core_ember","ARM_L":"arm_hammer","ARM_R":"everykit_standard_fist","LEGS":"legs_light"},
        "TWO-ARM+head cheap ": {"HEAD":"head_optic","CORE":"core_ember","ARM_L":"arm_hammer","ARM_R":"everykit_standard_fist","LEGS":"legs_light"},
        "5SLOT common kit   ": {"HEAD":"head_optic","CORE":"core_ember","ARM_L":"arm_hammer","ARM_R":"arm_buckler","LEGS":"legs_light"},
    }

    var foes := [
        {"name":"Rusty  tutorial ch0 ", "ch":0, "aim":false},
        {"name":"Cogsworth elite ch3 ", "ch":3, "aim":true},
        {"name":"Thornlash elite ch5 ", "ch":5, "aim":true},
    ]

    for bname in specs:
        var d: Dictionary = _mk(specs[bname]).derived()
        var cm := _mk(specs[bname])
        var chp := cm.core().current_hp
        print("\n=== BUILD: %s  ATK %d DEF %d SPD %d mana %d coreHP %d wt %d/%d ===" % [
            bname.strip_edges(), int(d["attack"]), int(d["defense"]), int(d["speed"]),
            int(d["energy"]), chp, int(d["weight"]), int(d["capacity"])])
        for f in foes:
            var me := _mk(specs[bname])
            var foe := Challengers.make(ch[int(f["ch"])])
            var c := Combat.new()
            c.start(me, foe, bool(f["aim"]))
            var g := 0
            while c.outcome() == Combat.Result.ONGOING and g < TURN_CAP:
                var a := c.current()
                if a == me: c.ai_take_turn(me, foe)
                else: c.ai_take_turn(foe, me)
                if c.outcome() == Combat.Result.ONGOING: c.advance_turn()
                g += 1
            var res := c.outcome()
            var word: String = ["ONGOING","WIN","SURV_LOSS","DEATH"][res]
            var yc := me.core()
            var fc := foe.core()
            var you_frac := 100.0 * float(yc.current_hp) / maxf(1.0, float(yc.data.max_hp))
            var foe_frac := 100.0 * float(fc.current_hp) / maxf(1.0, float(fc.data.max_hp))
            var broke := 0
            for s in ManabitState.SLOT_NAMES:
                var pi = me.slots.get(s)
                if pi != null and pi.disabled: broke += 1
            print("   vs %s -> %-10s turns=%3d  yourCore=%3.0f%% foeCore=%3.0f%% yourBitsBroke=%d" % [
                f["name"], word, g, you_frac, foe_frac, broke])

    # Battle log for the truly-minimal build vs the tutorial (the confusing turn-1 loss)
    print("\n--- LOG: MINIMAL core+1arm vs Rusty (tutorial) ---")
    var mm := _mk({"CORE":"core_ember", "ARM_L":"arm_hammer"})
    var rr := Challengers.make(ch[0])
    var cc := Combat.new()
    cc.start(mm, rr, false)
    var gg := 0
    while cc.outcome() == Combat.Result.ONGOING and gg < TURN_CAP:
        var a := cc.current()
        if a == mm: cc.ai_take_turn(mm, rr)
        else: cc.ai_take_turn(rr, mm)
        if cc.outcome() == Combat.Result.ONGOING: cc.advance_turn()
        gg += 1
    for line in cc.battle_log:
        print("   " + str(line))
    print("   OUTCOME: " + ["ONGOING","WIN","SURV_LOSS","DEATH"][cc.outcome()])
    quit(0)

func _mk(spec: Dictionary) -> ManabitState:
    var m := ManabitState.new()
    var cat := Catalog.by_id()
    for slot in spec:
        var pd: PartData = cat.get(String(spec[slot]))
        if pd == null:
            push_error("missing part " + String(spec[slot]))
            continue
        m.slots[slot] = PartInstance.new(pd)
    return m
