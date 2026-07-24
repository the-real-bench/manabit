extends SceneTree
# Box of Scrap POWER-BAND sim over the BRANCHING map (heavier - run separately, not the fast gate).
# Drives combat.gd both-sides-AI per LANE with its template modifier applied through the SAME
# shipped helpers (RunState.choose -> RunMods.pre_fight_mend -> Challengers.make(entry, mod_id)) -
# no parallel sim implementation, so a green here vouches for the shipped path.
#   - node0 (Rusty, fixed pos 0, never branched, no core-aim): clear >= 0.90 and zero deaths.
#   - every boss lane (Brassmore / Gildfall under its template's modifier): Gleaming win >= 0.60,
#     Dud win <= 0.15, and Dud dies more than it wins (real stakes).
#   - every elite lane (loose v1 band): Gleaming win >= 0.50, and no elite lane out-cozies node0.

const N := 340
const TURN_CAP := 100

func _initialize() -> void:
    var ok := true

    # structural pre-check: every template's step 0 is a plain Rusty FIGHT with an empty modifier
    for t in RunState.TEMPLATES.size():
        var m: Array = RunState.new()._make_map(t)
        var n0: Dictionary = m[0]
        var clean: bool = String(n0.get("type", "")) == "FIGHT" \
            and String((n0.get("challenger", {}) as Dictionary).get("name", "")) == "Scrap-Pup Rusty" \
            and (n0.get("modifier", {}) as Dictionary).is_empty() \
            and not bool(n0.get("aims_core", false))
        ok = _c("template %d step 0 is a clean Rusty fight" % t, clean) and ok

    # static audit: every TABLE rule magnitude within its declared bounds, and the card text
    # carries the same number (the label IS the rule - no lying labels)
    ok = _c("modifier magnitudes match declared bounds (mend 4/3, wear 2)",
        RunMods.MEND_PRE == 4 and RunMods.MEND_POST == 3 and RunMods.WEAR == 2
        and String(RunMods.TABLE["tailwind"]["blurb"]).contains("4")
        and String(RunMods.TABLE["second_wind"]["blurb"]).contains("3")
        and String(RunMods.TABLE["rusted"]["blurb"]).contains("2")) and ok

    # collect every junction lane from both templates: {t, pos, lane, tier, label}
    var lanes: Array = []
    for t in RunState.TEMPLATES.size():
        var m2: Array = RunState.new()._make_map(t)
        for p in m2.size():
            var step: Dictionary = m2[p]
            if String(step.get("type", "")) != "JUNCTION":
                continue
            var paths: Array = step["paths"]
            for li in paths.size():
                var ln: Dictionary = paths[li]
                var nd: Dictionary = ln["node"]
                lanes.append({
                    "t": t, "pos": p, "lane": li,
                    "tier": String(nd.get("tier", "")),
                    "label": "T%d %-11s %-22s %-11s" % [t, String(ln.get("lane_name", "")),
                        String((nd.get("challenger", {}) as Dictionary).get("name", "")).get_slice(",", 0),
                        String(ln["modifier"]["id"])],
                })

    var ch := Challengers.list()
    var nl := lanes.size()
    var win0 := 0
    var die0 := 0
    var win := []
    var die := []
    var gwin := []
    var dwin := []
    var ddie := []
    var drwin := []                  # G7 arm: Dud + forced best-case RARE lend, boss lanes only
    var fwin := []                   # D2 re-pin: Fair (the 32% modal roll) must be risky-but-winnable
    var fdie := []
    for k in nl:
        win.append(0)
        die.append(0)
        gwin.append(0)
        dwin.append(0)
        ddie.append(0)
        drwin.append(0)
        fwin.append(0)
        fdie.append(0)
    var gn := 0
    var dn := 0
    var fn := 0

    for i in range(N):
        var seed := 100003 + i * 7919
        var g := BoxRoller.grade(seed)
        var is_g := (g == "Gleaming")
        var is_d := (g == "Dud")
        var is_f := (g == "Fair")
        if is_g: gn += 1
        if is_d: dn += 1
        if is_f: fn += 1
        # node0: the fixed clean Rusty skirmish
        var me0 := RunState.kit_build(seed)
        var r0 := _fight(me0, Challengers.make(ch[0]), false)
        if r0 == Combat.Result.WIN:
            win0 += 1
        elif r0 == Combat.Result.DEATH:
            die0 += 1
        # every lane, through the shipped collapse + modifier path
        for k in nl:
            var L: Dictionary = lanes[k]
            var run := RunState.new()
            run.carried = RunState.kit_build(seed)
            run.is_kit = true
            run.map = run._make_map(int(L["t"]))
            run.pos = int(L["pos"])
            run.choose(int(L["lane"]))
            RunMods.pre_fight_mend(run)                     # shipped tailwind hook (pre-bell)
            var nd2: Dictionary = run.node()
            var mod_id := String((nd2.get("modifier", {}) as Dictionary).get("id", ""))
            var foe := Challengers.make(nd2["challenger"], mod_id)   # shipped rusted/overgrown
            var res := _fight(run.carried, foe, bool(nd2.get("aims_core", true)))
            if res == Combat.Result.WIN:
                win[k] += 1
                if is_g: gwin[k] += 1
                if is_d: dwin[k] += 1
                if is_f: fwin[k] += 1
            elif res == Combat.Result.DEATH:
                die[k] += 1
                if is_d: ddie[k] += 1
                if is_f: fdie[k] += 1
            # G7 arm (wave 3): a Dud box handed the heap's BEST-CASE RARE lend must still be
            # shy of the boss gate - the lend upgrades a Dud, it never carries one.
            if is_d and String(L["tier"]) == "boss":
                var rrun := RunState.new()
                rrun.carried = RunState.kit_build(seed)
                _seat_rare_lend(rrun.carried)
                rrun.is_kit = true
                rrun.map = rrun._make_map(int(L["t"]))
                rrun.pos = int(L["pos"])
                rrun.choose(int(L["lane"]))
                RunMods.pre_fight_mend(rrun)
                var ndr: Dictionary = rrun.node()
                var rmod := String((ndr.get("modifier", {}) as Dictionary).get("id", ""))
                var rfoe := Challengers.make(ndr["challenger"], rmod)
                if _fight(rrun.carried, rfoe, true) == Combat.Result.WIN:
                    drwin[k] += 1

    print("  grade mix over %d: Dud=%d  Gleaming=%d" % [N, dn, gn])
    print("  node0 Rusty  win %.2f  die %.2f" % [float(win0) / N, float(die0) / N])
    for k in nl:
        print("  %s  win %.2f  die %.2f   | Gleaming win %.2f  Fair win %.2f die %.2f  Dud win %.2f  Dud die %.2f" % [
            String(lanes[k]["label"]), float(win[k]) / N, float(die[k]) / N,
            (float(gwin[k]) / gn) if gn > 0 else 0.0,
            (float(fwin[k]) / fn) if fn > 0 else 0.0,
            (float(fdie[k]) / fn) if fn > 0 else 0.0,
            (float(dwin[k]) / dn) if dn > 0 else 0.0,
            (float(ddie[k]) / dn) if dn > 0 else 0.0])

    ok = _c("node0 clear >= 0.90 (floor holds)", float(win0) / N >= 0.90) and ok
    ok = _c("node0 losses are cozy (no core-hunt death there)", die0 == 0) and ok
    for k in nl:
        var L2: Dictionary = lanes[k]
        var tag := String(L2["label"]).strip_edges()
        if String(L2["tier"]) == "boss":
            if gn > 0:
                ok = _c("%s: Gleaming near-guarantees (>= 0.60)" % tag, float(gwin[k]) / gn >= 0.60) and ok
            if dn > 0:
                ok = _c("%s: Dud rarely clears (<= 0.15)" % tag, float(dwin[k]) / dn <= 0.15) and ok
                ok = _c("%s: Dud dies more than it wins" % tag, ddie[k] > dwin[k]) and ok
                ok = _c("%s: Dud + best-case RARE lend boss win %.2f <= 0.20 (G7)" % [tag, float(drwin[k]) / dn],
                    float(drwin[k]) / dn <= 0.20) and ok
            if fn > 0:
                # D2 re-pin: Fair is the 32% MODAL first-box roll. New intended shape - the boss is
                # a real gamble, not a guaranteed loss (was ~0.01 win) and not a near-guarantee.
                ok = _c("%s: Fair boss is WINNABLE (>= 0.12, was ~0.01)" % tag, float(fwin[k]) / fn >= 0.12) and ok
                ok = _c("%s: Fair boss stays RISKY (<= 0.55, below Keen - not flattened)" % tag, float(fwin[k]) / fn <= 0.55) and ok
                ok = _c("%s: Fair boss dies more than it wins (honest risk)" % tag, fdie[k] >= fwin[k]) and ok
        else:
            if gn > 0:
                ok = _c("%s: Gleaming clears (>= 0.50)" % tag, float(gwin[k]) / gn >= 0.50) and ok
            ok = _c("%s: no cozier than node0" % tag, win[k] <= win0) and ok
    print("SMOKE PASS" if ok else "SMOKE FAIL")
    quit(0 if ok else 1)

# The heap's best case: the strongest RARE offensive arm in the catalog, seated fresh at ARM_R
# (deterministic - max power, id tie-break). What a lend can EVER hand a Dud.
func _seat_rare_lend(m: ManabitState) -> void:
    var best: PartData = null
    for pd in Catalog.body_pool():
        if String(pd.rarity) != "RARE":
            continue
        if not (pd.slot == "ARM_L" or pd.slot == "ARM_R"):
            continue
        var ab = pd.ability
        if ab == null or ab.archetype == "GUARD" or ab.archetype == "NONE":
            continue
        if best == null or ab.power > best.ability.power \
            or (ab.power == best.ability.power and String(pd.id) < String(best.id)):
            best = pd
    if best != null:
        m.slots["ARM_R"] = PartInstance.new(best)

func _fight(me: ManabitState, foe: ManabitState, foe_aims_core: bool) -> int:
    var c := Combat.new()
    c.start(me, foe, foe_aims_core)
    var guard := 0
    while c.outcome() == Combat.Result.ONGOING and guard < TURN_CAP:
        var actor := c.current()
        if actor == me:
            c.ai_take_turn(me, foe)
        else:
            c.ai_take_turn(foe, me)
        if c.outcome() == Combat.Result.ONGOING:
            c.advance_turn()
        guard += 1
    return c.outcome()

func _c(name: String, cond: bool) -> bool:
    print(("  [%s] " % ("PASS" if cond else "FAIL")) + name)
    return cond
