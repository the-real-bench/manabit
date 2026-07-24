extends SceneTree
# M3 run gate: branching map (2 templates x 2 junctions, collapse-in-place), carried clone,
# no-auto-heal + repair, extraction eligibility, banking, and the template validator -
# tier-per-route uniqueness (byte-identical purse caps), lane rules, modifier validity.

func _initialize() -> void:
    var ok := true
    var cat := Catalog.by_id()
    var build := ManabitState.new()
    build.slots["CORE"] = PartInstance.new(cat["core_ember"])
    build.slots["ARM_R"] = PartInstance.new(cat["arm_hammer"])   # max_hp 10

    var r := RunState.new()
    r.start(build, "Testbot")
    ok = _c("map has 5 steps", r.map.size() == 5) and ok
    r.map = r._make_map(0)   # pin template A (The Old Road) for the deterministic walk
    r.pos = 0

    var n0 := r.node()
    var ch0: Dictionary = n0.get("challenger", {})
    ok = _c("step 0 is FIGHT tier skirmish", String(n0.get("type", "")) == "FIGHT" and String(n0.get("tier", "")) == "skirmish") and ok
    ok = _c("step 0 is clean Rusty (no core-aim, no modifier, no fork)",
        String(ch0.get("name", "")) == "Scrap-Pup Rusty" and not bool(n0.get("aims_core", true))
        and (n0.get("modifier", {}) as Dictionary).is_empty() and not r.at_junction()) and ok
    ok = _c("carried is a clone", r.carried != build and r.carried.slots["ARM_R"] != build.slots["ARM_R"]) and ok

    # no auto-heal: damage persists; repair costs and restores
    r.carried.slots["ARM_R"].take_damage(5)
    ok = _c("damage persists on carried", int(r.carried.slots["ARM_R"].current_hp) == 5) and ok
    ok = _c("repair cost > 0 when hurt", r.repair_cost() > 0) and ok
    r.repair_all()
    ok = _c("repair restores + zero cost", int(r.carried.slots["ARM_R"].current_hp) == 10 and r.repair_cost() == 0) and ok

    # choose() at a non-junction pos is a no-op
    r.choose(0)
    ok = _c("choose at a non-junction is a no-op", String(r.node().get("type", "")) == "FIGHT") and ok

    # walk the map
    r.advance()
    ok = _c("pos 1 is REST + can extract", r.at_rest() and r.can_extract()) and ok
    r.advance()   # pos 2 JUNCTION (elite)
    ok = _c("pos 2 is a junction with 2 choices", r.at_junction() and r.choices().size() == 2) and ok
    var lanes := r.choices()
    var l0: Dictionary = lanes[0]
    var l1: Dictionary = lanes[1]
    var ln0: Dictionary = l0["node"]
    var ln1: Dictionary = l1["node"]
    ok = _c("both lanes tier elite + aim the core",
        String(ln0.get("tier", "")) == "elite" and String(ln1.get("tier", "")) == "elite"
        and bool(ln0.get("aims_core", false)) and bool(ln1.get("aims_core", false))) and ok
    var na := String((ln0.get("challenger", {}) as Dictionary).get("name", ""))
    var nb := String((ln1.get("challenger", {}) as Dictionary).get("name", ""))
    ok = _c("lane challengers differ (name + style family)",
        na != nb and na != "" and _family(ln0.get("challenger", {})) != _family(ln1.get("challenger", {}))) and ok
    var ida := String((l0.get("modifier", {}) as Dictionary).get("id", ""))
    var idb := String((l1.get("modifier", {}) as Dictionary).get("id", ""))
    ok = _c("lane modifier ids differ + exist in RunMods.TABLE",
        ida != idb and RunMods.TABLE.has(ida) and RunMods.TABLE.has(idb)) and ok
    ok = _c("junction step has no challenger pre-choice", not r.node().has("challenger")) and ok
    ok = _c("cannot extract at a junction", not r.can_extract()) and ok
    r.choose(-1)
    r.choose(2)
    ok = _c("out-of-range choose is a no-op", r.at_junction()) and ok
    r.choose(0)
    ok = _c("choose(0) collapses in place to a FIGHT", not r.at_junction() and String(r.node().get("type", "")) == "FIGHT") and ok
    ok = _c("collapsed node carries lane 0's modifier",
        String((r.node().get("modifier", {}) as Dictionary).get("id", "")) == ida) and ok
    ok = _c("road_not_taken stamped + choices now empty",
        String(r.node().get("road_not_taken", "")) != "" and r.choices().is_empty()) and ok
    r.advance()
    ok = _c("pos 3 is REST + can extract", r.at_rest() and r.can_extract()) and ok
    r.advance()   # pos 4 JUNCTION (boss)
    ok = _c("pos 4 is the boss junction", r.at_junction() and r.choices().size() == 2) and ok
    var bl := r.choices()
    var b0: Dictionary = bl[0]["node"]
    var b1: Dictionary = bl[1]["node"]
    var bnames := [String((b0.get("challenger", {}) as Dictionary).get("name", "")),
        String((b1.get("challenger", {}) as Dictionary).get("name", ""))]
    ok = _c("both boss lanes are boss tier + boss true",
        String(b0.get("tier", "")) == "boss" and String(b1.get("tier", "")) == "boss"
        and bool(b0.get("boss", false)) and bool(b1.get("boss", false))) and ok
    ok = _c("boss junction is always Brassmore vs Gildfall",
        bnames.has("Sunking Brassmore, the Undethroned") and bnames.has("Prince Gildfall, the Heir-Apparent")) and ok
    r.choose(1)
    ok = _c("boss lane collapses to a boss fight", bool(r.node().get("boss", false))) and ok
    ok = _c("cannot extract at a fight", not r.can_extract()) and ok
    r.advance()
    ok = _c("run over past the boss", r.over) and ok

    # banking the survivor
    var p := PlayerState.new()
    p.grant_starter_kit()
    var m0 := p.menagerie.size()
    p.bank_manabit(r.mname, r.carried)
    ok = _c("bank adds to menagerie", p.menagerie.size() == m0 + 1) and ok

    ok = _validate_templates() and ok
    ok = _wave3_checks() and ok

    print("SMOKE PASS" if ok else "SMOKE FAIL")
    quit(0 if ok else 1)

# WAVE 3 (design/economy/venture-depth-wave3.md 7): rest flavors, the shrine table, the rider
# seam, the Gleaner's Due, and Magpie's Heap - T1-T8, 32 -> 40 checks. The original 32 pass
# UNTOUCHED above: a flavored rest is still a REST, which is the proof the flavor ruling
# preserved the frozen node()/advance()/can_extract() semantics.
func _wave3_checks() -> bool:
    var ok := true
    ok = _c("T1 pos 3 rest is The Last Lantern, plain camp, both templates", _t1()) and ok
    ok = _c("T2 pos 1 rest carries a flavor and flavors differ across templates", _t2()) and ok
    ok = _c("T3 crack-and-see parity: same seed stamps identical shrine + heap draws", _t3()) and ok
    ok = _c("T4 event table validator: rails, weights 23, printed odds, no money fields", _t4()) and ok
    ok = _c("T5 resolve() irreversible + idempotent; safe ignores the roll; no-ops hold", _t5()) and ok
    ok = _c("T6 rider is MAX-NOT-SUM vs the lane modifier; consumed after one fight", _t6()) and ok
    ok = _c("T7 Gleaner's Due ordering law: canonical keeps, sting sweep, bit + slot", _t7()) and ok
    ok = _c("T8 Magpie's Heap: seed-pure dig, once per run, lends never reach the player", _t8()) and ok
    return ok

func _t1() -> bool:
    for t in RunState.TEMPLATES.size():
        var m: Array = RunState.new()._make_map(t)
        var nd: Dictionary = m[3]
        if String(nd.get("type", "")) != "REST" or String(nd.get("label", "")) != "The Last Lantern":
            return false
        if String(nd.get("flavor", "")) != "camp" or nd.has("event_id") or nd.has("dig"):
            return false
    return true

func _t2() -> bool:
    var a: Dictionary = RunState.new()._make_map(0)[1]
    var b: Dictionary = RunState.new()._make_map(1)[1]
    return String(a.get("type", "")) == "REST" and String(a.get("flavor", "")) == "event" \
        and String(a.get("label", "")) == "Wayside Shrine" \
        and a.has("event_id") and a.has("roll") and not bool(a.get("resolved", true)) \
        and String(b.get("type", "")) == "REST" and String(b.get("flavor", "")) == "scrapyard" \
        and String(b.get("label", "")) == "Magpie's Heap" and b.has("dig") and b.has("dig_pick")

func _t3() -> bool:
    for seed in [20260718, 20260719]:    # one even (Template A), one odd (Template B)
        var a: Dictionary = RunState.new()._make_map(seed)[1]
        var b: Dictionary = RunState.new()._make_map(seed)[1]
        for k in ["flavor", "event_id", "roll", "dig", "dig_pick"]:
            if a.get(k) != b.get(k):
                return false
        if a.has("event_id"):
            # the static probe pins the same pick without walking a map
            var pk := RunEvents.pick(seed)
            if String(pk["event_id"]) != String(a["event_id"]) or int(pk["roll"]) != int(a["roll"]):
                return false
    return true

func _t4() -> bool:
    if RunEvents.TABLE.size() != 10:
        return false
    var wsum := 0
    var seen := {}
    for ev in RunEvents.TABLE:
        var e: Dictionary = ev
        var w: int = int(e.get("weight", 0))
        if w <= 0 or seen.has(String(e.get("id", ""))):
            return false
        wsum += w
        seen[String(e["id"])] = true
        if not (e.has("safe") and e.has("push")):
            return false             # exactly 2 choices
        var safe: Dictionary = e["safe"]
        var push: Dictionary = e["push"]
        if safe.has("thr"):
            return false             # the safe choice is deterministic by rule
        var thr: int = int(push.get("thr", -1))
        var stakes := String(push.get("stakes", ""))
        if thr == 67:
            if not stakes.begins_with("2 in 3"):
                return false         # printed odds match the threshold, verbatim
        elif thr == 50:
            if not stakes.begins_with("1 in 2"):
                return false
        else:
            return false
        if not String(safe.get("stakes", "")).begins_with("Sure:"):
            return false
        if String(safe.get("title", "")).length() > 28 or String(push.get("title", "")).length() > 28:
            return false
        if String(safe.get("stakes", "")).length() > 72 or stakes.length() > 72:
            return false
        var effs := [safe["effect"], (push["good"] as Dictionary)["effect"], (push["bad"] as Dictionary)["effect"]]
        for eff0 in effs:
            var eff: Dictionary = eff0
            for k in eff.keys():
                if not ["mend", "wear", "at", "rider"].has(String(k)):
                    return false     # NO money fields anywhere in the table (money-neutral v1)
            if eff.has("mend") and (int(eff["mend"]) < 1 or int(eff["mend"]) > 6):
                return false
            var at := String(eff.get("at", ""))
            if not ["", "ARM", "ARMS", "LEGS"].has(at):
                return false         # never CORE - the wear rail cannot even express it
            if eff.has("wear"):
                var wear: int = int(eff["wear"])
                var total: int = wear * (2 if at == "ARMS" else 1)
                if wear < 1 or total > 4:
                    return false
            if int(eff.get("rider", 0)) > RunMods.WEAR:
                return false         # rider <= 2, never above rusted's magnitude
    if wsum != 23:
        return false
    # never disables, floor 1 HP: even wear 4 leaves every bit alive and the core untouched
    var m := RunState.kit_build(3)
    for slot in ManabitState.SLOT_NAMES:
        var pi: PartInstance = m.slots.get(slot)
        if pi != null:
            pi.current_hp = 2
    RunEvents._apply_wear(m, {"wear": 4})
    for slot2 in ManabitState.SLOT_NAMES:
        var pi2: PartInstance = m.slots.get(slot2)
        if pi2 == null:
            continue
        if pi2.data.is_core and pi2.current_hp != 2:
            return false
        if pi2.current_hp < 1 or pi2.disabled:
            return false
    return true

func _t5() -> bool:
    var r := RunState.new()
    r.carried = RunState.kit_build(5)
    r.map = r._make_map(0)
    r.pos = 1
    var nd: Dictionary = r.node()
    nd["event_id"] = "toll_doll"     # pin a rider-safe event (full-HP independent)
    nd["roll"] = 99                  # push would be BAD - the safe choice must ignore this
    r.pos = 0
    if not RunEvents.resolve(r, 0).is_empty():
        return false                 # no-op at a non-event node
    r.pos = 1
    if not RunEvents.resolve(r, 2).is_empty() or bool(nd.get("resolved", false)):
        return false                 # no-op for choice_i outside {0, 1}
    var res := RunEvents.resolve(r, 0)
    if res.is_empty() or String(res["result_id"]) != "safe" or r.next_fight_rider != 1:
        return false                 # the safe choice ignored the roll
    if not bool(nd.get("resolved", false)) or int(nd.get("chose", -1)) != 0:
        return false
    if not RunEvents.resolve(r, 1).is_empty():
        return false                 # irreversible + idempotent on re-call
    return r.next_fight_rider == 1 and String(nd.get("result_id", "")) == "safe"

func _t6() -> bool:
    var entry: Dictionary = Challengers.list()[3]
    var rust := Challengers.make(entry, "rusted", 0)
    var both := Challengers.make(entry, "rusted", 2)   # rusted(2) + rider(2) = 2, never 4
    var ride := Challengers.make(entry, "", 2)         # rider alone wears like rusted
    for slot in ManabitState.SLOT_NAMES:
        var a: PartInstance = rust.slots.get(slot)
        var b: PartInstance = both.slots.get(slot)
        var c: PartInstance = ride.slots.get(slot)
        if (a == null) != (b == null) or (a == null) != (c == null):
            return false
        if a != null and (a.current_hp != b.current_hp or a.current_hp != c.current_hp):
            return false
    var r := RunState.new()
    r.next_fight_rider = 2
    if r.take_fight_rider() != 2 or r.next_fight_rider != 0 or r.take_fight_rider() != 0:
        return false                 # consumed and cleared after one fight
    r.next_fight_rider = 9
    return r.take_fight_rider() == RunMods.WEAR        # capped at rusted's magnitude

func _t7() -> bool:
    # canonical keeps (spec 4.2): S=35, H=1 -> boss 17 / elite 8; H=0 -> boss 8 / elite 4
    if RunState.gleaners_kept(35, "boss", 1.0) != 17 or RunState.gleaners_kept(35, "elite", 1.0) != 8:
        return false
    if RunState.gleaners_kept(35, "boss", 0.0) != 8 or RunState.gleaners_kept(35, "elite", 0.0) != 4:
        return false
    if RunState.gleaners_kept(35, "skirmish", 1.0) != 0:
        return false                 # the skirmish cannot kill - fail-safe zero
    for s in 76:
        for h in [0.0, 0.5, 1.0]:
            for tier in ["boss", "elite"]:
                if RunState.gleaners_kept(s, String(tier), float(h)) > int(floor(float(s) / 2.0)):
                    return false     # the guaranteed sting: death never keeps more than floor(S/2)
    var r := RunState.new()
    r.start_kit(7)
    r.satchel_scrap = 35
    r.satchel_bit_id = "arm_hammer"
    var kept := r.kit_death_spill("boss")              # full-HP survivors -> H = 1
    if kept != 17 or r.satchel_scrap != 0 or r.satchel_bit_id != "":
        return false                 # the tucked bit never survives the pickers
    var p := PlayerState.new()
    p.gleaners_pay(kept, 500)
    if p.scrap != 17 or p.kit_runs_today != 1:
        return false                 # a paid death burns a daily full-rate slot (G10)
    p.gleaners_pay(0, 500)
    if p.kit_runs_today != 1:
        return false                 # an empty-handed death burns nothing
    # own wreck (spec 4.3, G9-halved K): the core pays 0; a full-HP RARE bit (melt 20) pays 5/2
    var m := ManabitState.new()
    var cat := Catalog.by_id()
    m.slots["CORE"] = PartInstance.new(cat["core_ember"])
    if RunState.gleaners_wreck(m, "boss") != 0:
        return false
    m.slots["LEGS"] = PartInstance.new(cat["legs_tread"])
    return RunState.gleaners_wreck(m, "boss") == 5 and RunState.gleaners_wreck(m, "elite") == 2

func _t8() -> bool:
    # deterministic scan for an odd seed (Template B) whose stamped dig is a COMMON lend
    var seed := -1
    for s in range(1, 400, 2):
        if int(RunEvents.heap_dig(s)["r1"]) < 55:
            seed = s
            break
    if seed < 0:
        return false
    var a := RunState.new()
    a.start_kit(seed)
    var b := RunState.new()
    b.start_kit(seed)
    var na: Dictionary = a.map[1]
    var nb: Dictionary = b.map[1]
    if String(na.get("flavor", "")) != "scrapyard" or na.get("dig") != nb.get("dig") \
        or na.get("dig_pick") != nb.get("dig_pick"):
        return false                 # leave and return: the dig is seed-pure
    var p := PlayerState.new()       # empty dex - the COMMON pool falls back to the base fixtures
    a.pos = 1
    a.satchel_scrap = 10
    var ra := a.rummage(p.compendium)
    b.pos = 1
    b.satchel_scrap = 10
    var rb := b.rummage(p.compendium)
    if String(ra.get("kind", "")) != "lend" or String(ra.get("id", "")) != String(rb.get("id", "?")):
        return false                 # same seed = same heap treasure
    if a.satchel_scrap != 2:
        return false                 # 10 - 8 paid; a lend pays no filings
    a.satchel_scrap = 20
    if not a.rummage(p.compendium).is_empty():
        return false                 # RUMMAGE is once per run
    # the lent bit rides the box but NEVER reaches player.bits - after safe-end flush AND death
    var before := p.bits.size()
    p.flush_satchel(a)
    if p.bits.size() != before:
        return false
    b.kit_death_spill("elite")
    return p.bits.size() == before and p.compendium.is_empty()

# TEMPLATE VALIDATOR: both templates x all 4 routes. Every route fields exactly one fight of each
# tier (so the purse cap is byte-identical on every road: 75 full / 37 halved); junction lanes
# never share a challenger, style family, or modifier id; second_wind never rides a boss lane;
# every overgrown lane's challenger carries a mods.overgrown swap list.
func _validate_templates() -> bool:
    var tiers_ok := true
    var purse_ok := true
    var lanes_ok := true
    var boss_ok := true
    var over_ok := true
    var full := PlayerState.new()
    var halved := PlayerState.new()
    halved.note_kit_run(7777)
    halved.note_kit_run(7777)
    for t in RunState.TEMPLATES.size():
        # route sweep: collapse every lane pair and audit the walked road
        for a in 2:
            for b in 2:
                var r := RunState.new()
                r.map = r._make_map(t)
                r.pos = 2
                r.choose(a)
                r.pos = 4
                r.choose(b)
                var seen := {}
                var pf := 0
                var ph := 0
                for nd in r.map:
                    if String((nd as Dictionary).get("type", "")) != "FIGHT":
                        continue
                    var tier := String((nd as Dictionary).get("tier", ""))
                    seen[tier] = int(seen.get(tier, 0)) + 1
                    pf += full.kit_purse(tier, 7777)
                    ph += halved.kit_purse(tier, 7777)
                if int(seen.get("skirmish", 0)) != 1 or int(seen.get("elite", 0)) != 1 or int(seen.get("boss", 0)) != 1:
                    tiers_ok = false
                if pf != 75 or ph != 37:
                    purse_ok = false
        # lane rules on the uncollapsed template
        var m := RunState.new()._make_map(t)
        for nd2 in m:
            var step: Dictionary = nd2
            if String(step.get("type", "")) != "JUNCTION":
                continue
            var paths: Array = step["paths"]
            var la: Dictionary = paths[0]
            var lb: Dictionary = paths[1]
            var ea: Dictionary = la["node"]["challenger"]
            var eb: Dictionary = lb["node"]["challenger"]
            var ia := String(la["modifier"]["id"])
            var ib := String(lb["modifier"]["id"])
            if String(ea.get("name", "")) == String(eb.get("name", "")) or _family(ea) == _family(eb) \
                or ia == ib or not RunMods.TABLE.has(ia) or not RunMods.TABLE.has(ib):
                lanes_ok = false
            if String(step.get("tier", "")) == "boss":
                if ia == "second_wind" or ib == "second_wind":
                    boss_ok = false
                var names := [String(ea.get("name", "")), String(eb.get("name", ""))]
                if not (names.has("Sunking Brassmore, the Undethroned") and names.has("Prince Gildfall, the Heir-Apparent")):
                    boss_ok = false
            for lane in paths:
                var ln: Dictionary = lane
                if String(ln["modifier"]["id"]) != "overgrown":
                    continue
                var entry: Dictionary = ln["node"]["challenger"]
                var mods: Dictionary = entry.get("mods", {})
                var swaps: Array = mods.get("overgrown", [])
                if swaps.is_empty():
                    over_ok = false
    var ok := true
    ok = _c("both templates x 4 routes: exactly one fight per tier", tiers_ok) and ok
    ok = _c("route purse caps byte-identical (75 full / 37 halved)", purse_ok) and ok
    ok = _c("junction lanes: unique challenger + family + modifier", lanes_ok) and ok
    ok = _c("boss junctions: Brassmore vs Gildfall, no second_wind", boss_ok) and ok
    ok = _c("overgrown lanes carry a mods.overgrown swap list", over_ok) and ok
    return ok

# style-family proxy: the leading token of the CORE loadout id (pith / grumble / boldheart /
# sovereign / quivergear / core...) - cheap, stable, and catches same-family lane pairs.
func _family(entry: Dictionary) -> String:
    for spec in entry.get("loadout", []):
        if String(spec[0]) == "CORE":
            return String(spec[1]).get_slice("_", 0)
    return ""

func _c(name: String, cond: bool) -> bool:
    print(("  [%s] " % ("PASS" if cond else "FAIL")) + name)
    return cond
