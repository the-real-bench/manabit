extends SceneTree
# OPTIMIZER PROBE (read-only, seeded, no user:// writes). Drives shipped combat.gd via the same
# pattern as sim_roster/sim_kit. Questions:
#  Q1 build depth: what is the strongest LEGAL build, and how much do the 3 "dominant" bits
#     (Bedrock Legs / Girder Fist / Regalia Core) matter vs the best build WITHOUT them?
#  Q2 core option: RARE Keystone (+carry) vs EPIC Regalia (+stat) - which fields the stronger legal build?
#  Q3 boss ceiling under OPTIMAL play: pilot the flagship (core-aim + guard policy, same lens as
#     roster v2 pentagon_v2) vs Brassmore(idx4) & Gildfall(idx8), foe hunts the core. True skill ceiling.
#  Q4 unbeatable wall / one-shot: max-DEF wall vs a boss (can it be killed / can it win?), and a
#     glass sniper's fastest kill.

const TURN_CAP := 100
const RARITY_RANK := {"COMMON": 0, "RARE": 1, "EPIC": 2}
const N := 200

func _initialize() -> void:
    var byid: Dictionary = Catalog.by_id()
    var all_bits: Array = Catalog.all()

    # ---- Q1/Q2 greedy strongest legal build under different core choices ----
    print("== Q1/Q2 strongest LEGAL build search ==")
    var cores := ["sovereign_brass_core_regalia", "grumble_co_keystone_core", "core_bulwark", "errant_core_pledge"]
    var builds := {}
    for cid in cores:
        var b := _greedy_legal(all_bits, byid, cid, [])
        builds[cid] = b
        _print_build("core=%s" % cid, b, byid)
    # exclude the dominant trio
    var ban := ["cobble_sons_legs_bedrock", "grumble_co_girder_fist"]
    var b_noban := _greedy_legal(all_bits, byid, "grumble_co_keystone_core", ban)
    builds["keystone_NOBEDROCK_NOGIRDER"] = b_noban
    _print_build("core=keystone, BAN bedrock+girder", b_noban, byid)

    # ---- measure each build vs the 5 canonical templates under optimal policy (both sides) ----
    print("\n== win rate vs 5 templates (policy lens, both sides core-aim+guard) ==")
    var templates := _templates()
    for key in builds.keys():
        var wr := _vs_templates(builds[key]["ids"], byid, templates)
        print("  %-34s  win %.3f  (weight %d/%d)" % [key, wr, builds[key]["weight"], builds[key]["cap"]])

    # ---- Q3 boss ceiling under optimal play ----
    print("\n== Q3 boss ceiling: flagship piloted OPTIMALLY vs bosses (foe hunts core) ==")
    var flagship_ids: Dictionary = builds["grumble_co_keystone_core"]["ids"]
    var ch := Challengers.list()
    for idx in [3, 4, 8]:   # Cogsworth(elite), Brassmore(boss), Gildfall(boss)
        var foe0 := Challengers.make(ch[idx])
        var r := _policy_fight(_mk(flagship_ids, byid), foe0, true)
        print("  [fixed flagship] vs %-40s -> %s  (turns %d, your core %d/%d, foe core %d/%d)" % [
            ch[idx]["name"], _rname(r["res"]), r["turns"],
            r["my_core"], r["my_core_max"], r["foe_core"], r["foe_core_max"]])
    # rate over jittered strong builds, policy vs shipped-AI-core-hunt foe
    print("  -- win rate over %d jittered STRONG builds vs shipped core-hunt foe --" % N)
    print("     (GUARD policy = core-aim+guard-when-behind ; RACE policy = pure aggression, never guard)")
    for idx in [3, 4, 8]:
        var wg := 0; var dg := 0; var sg := 0
        var wr := 0; var dr := 0; var sr := 0
        for i in N:
            var seed := 90001 + i * 6301
            var ids := _jitter_strong(flagship_ids, byid, seed)
            var rg := _policy_fight_shipfoe(_mk(ids, byid), Challengers.make(ch[idx]), true, false)
            if rg == Combat.Result.WIN: wg += 1
            elif rg == Combat.Result.DEATH: dg += 1
            else: sg += 1
            var rr := _policy_fight_shipfoe(_mk(ids, byid), Challengers.make(ch[idx]), true, true)
            if rr == Combat.Result.WIN: wr += 1
            elif rr == Combat.Result.DEATH: dr += 1
            else: sr += 1
        print("     vs %-38s GUARD win %.3f death %.3f stall %.3f | RACE win %.3f death %.3f stall %.3f" % [
            ch[idx]["name"], float(wg)/N, float(dg)/N, float(sg)/N, float(wr)/N, float(dr)/N, float(sr)/N])

    # ---- Q4 unbeatable wall / glass cannon ----
    print("\n== Q4 max-DEF wall vs Brassmore (can it survive/win?) & glass sniper speed ==")
    var wall := _greedy_stat(all_bits, byid, "core_bulwark", "defense")
    _print_build("MAX-DEF wall", wall, byid)
    var rw := _policy_fight(_mk(wall["ids"], byid), Challengers.make(ch[4]), true)
    print("  wall vs Brassmore -> %s  (turns %d, your core %d/%d, foe core %d/%d)" % [
        _rname(rw["res"]), rw["turns"], rw["my_core"], rw["my_core_max"], rw["foe_core"], rw["foe_core_max"]])
    # wall attrition without foe core-aim (pure bout): does it out-turtle or stall?
    var rw2 := _policy_fight(_mk(wall["ids"], byid), Challengers.make(ch[4]), false)
    print("  wall vs Brassmore [bout, no core-aim] -> %s  (turns %d, foe core %d/%d)" % [
        _rname(rw2["res"]), rw2["turns"], rw2["foe_core"], rw2["foe_core_max"]])

    print("\nOPT PROBE DONE")
    quit(0)

# ---------- build helpers ----------
func _mk(ids: Dictionary, byid: Dictionary) -> ManabitState:
    var m := ManabitState.new()
    for slot in ManabitState.SLOT_NAMES:
        var id: String = String(ids.get(slot, ""))
        m.slots[slot] = PartInstance.new(byid[id]) if byid.has(id) else null
    return m

func _statsum(pd: PartData) -> int:
    return pd.max_hp + pd.attack + pd.defense + pd.speed + pd.energy

func _order(a, b) -> bool:
    var ra: int = int(RARITY_RANK.get(String(a.rarity), 0))
    var rb: int = int(RARITY_RANK.get(String(b.rarity), 0))
    if ra != rb: return ra > rb
    var sa := _statsum(a)
    var sb := _statsum(b)
    if sa != sb: return sa > sb
    return String(a.id) < String(b.id)

# greedy: seat core, then fill each other slot with best rarity+stat bit that keeps weight<=capacity
func _greedy_legal(all_bits: Array, byid: Dictionary, core_id: String, ban: Array) -> Dictionary:
    var ids := {"HEAD": "", "CORE": core_id, "ARM_L": "", "ARM_R": "", "LEGS": "", "BACK": ""}
    var pool := all_bits.duplicate()
    pool.sort_custom(_order)
    for slot in ["HEAD", "ARM_L", "ARM_R", "LEGS", "BACK"]:
        for pd in pool:
            if String(pd.slot) != slot: continue
            if String(pd.id) in ban: continue
            if pd.is_core: continue
            var trial := ids.duplicate()
            trial[slot] = String(pd.id)
            var d := _mk(trial, byid).derived()
            if int(d.weight) <= int(d.capacity):
                ids[slot] = String(pd.id)
                break
    var dd := _mk(ids, byid).derived()
    return {"ids": ids, "weight": int(dd.weight), "cap": int(dd.capacity), "d": dd}

func _greedy_stat(all_bits: Array, byid: Dictionary, core_id: String, stat: String) -> Dictionary:
    var ids := {"HEAD": "", "CORE": core_id, "ARM_L": "", "ARM_R": "", "LEGS": "", "BACK": ""}
    for slot in ["HEAD", "ARM_L", "ARM_R", "LEGS", "BACK"]:
        var best: PartData = null
        for pd in all_bits:
            if String(pd.slot) != slot or pd.is_core: continue
            var trial := ids.duplicate()
            trial[slot] = String(pd.id)
            if int(_mk(trial, byid).derived().weight) > int(_mk(trial, byid).derived().capacity): continue
            if best == null or int(pd.get(stat)) > int(best.get(stat)):
                best = pd
        if best != null: ids[slot] = String(best.id)
    var dd := _mk(ids, byid).derived()
    return {"ids": ids, "weight": int(dd.weight), "cap": int(dd.capacity), "d": dd}

func _jitter_strong(base: Dictionary, byid: Dictionary, seed: int) -> Dictionary:
    # keep CORE + the strongest weapon; jitter HEAD/LEGS/BACK among strong commons/rares to make a band
    var rng := RandomNumberGenerator.new()
    rng.seed = seed
    var out := base.duplicate()
    var pools := {
        "HEAD": ["sovereign_brass_head_herald", "grumble_co_anvil_cowl", "chatterbox_bigeye_dome", "head_hornet"],
        "LEGS": ["cobble_sons_legs_bedrock", "thicket_fang_legs_haunch", "everykit_standard_strider_legs", "errant_legs_rampart"],
        "BACK": ["pith_sinew_deep_pulse_sac", "quivergear_payload_rack", "grumble_co_furnace_pack", "chatterbox_notion_pack"],
    }
    for slot in pools.keys():
        var pool: Array = pools[slot]
        var pick := String(pool[rng.randi() % pool.size()])
        var trial := out.duplicate()
        trial[slot] = pick
        if int(_mk(trial, byid).derived().weight) <= int(_mk(trial, byid).derived().capacity):
            out[slot] = pick
    return out

func _print_build(label: String, b: Dictionary, byid: Dictionary) -> void:
    var d: Dictionary = b["d"]
    print("  %s  [w %d/%d spd %d atk %d def %d hp(core) %d]" % [label, b["weight"], b["cap"],
        int(d.speed), int(d.attack), int(d.defense), int(d.get("core_hp", 0))])
    for slot in ManabitState.SLOT_NAMES:
        var id: String = String(b["ids"].get(slot, ""))
        if id != "" and byid.has(id):
            print("      %-6s %s (%s)" % [slot, byid[id].display_name, byid[id].rarity])

# ---------- combat drivers ----------
func _templates() -> Array:
    return [
        {"HEAD": "everykit_standard_cowl", "CORE": "core_ember", "ARM_L": "grumble_co_girder_fist",
            "ARM_R": "thicket_fang_arm_gnashmaw", "LEGS": "pocketful_legs_stubby", "BACK": "boldheart_back_rocketspine"},
        {"HEAD": "grumble_co_anvil_cowl", "CORE": "core_bulwark", "ARM_L": "errant_arm_warder",
            "ARM_R": "cobble_sons_arm_ratchet", "LEGS": "tinbox_legs_trusty", "BACK": "grumble_co_furnace_pack"},
        {"HEAD": "whirligig_head_windshear", "CORE": "whirligig_core_quickstart", "ARM_L": "pocketful_arm_weefist",
            "ARM_R": "quivergear_salvo_fist", "LEGS": "silksteel_legs_slip", "BACK": "whirligig_back_slipfin"},
        {"HEAD": "chatterbox_prattle_dome", "CORE": "core_font", "ARM_L": "thicket_fang_arm_rendclaw",
            "ARM_R": "quivergear_salvo_fist", "LEGS": "thicket_fang_legs_haunch", "BACK": "quivergear_volley_pod"},
        {"HEAD": "silksteel_head_gauze", "CORE": "core_font", "ARM_L": "pocketful_arm_weefist",
            "ARM_R": "silksteel_arm_needle", "LEGS": "silksteel_legs_slip", "BACK": "chatterbox_notion_pack"},
    ]

func _vs_templates(ids: Dictionary, byid: Dictionary, templates: Array) -> float:
    var w := 0.0
    var n := 0
    for t in templates:
        # play both sides to cancel role asymmetry
        var r1 := _policy_fight(_mk(ids, byid), _mk(t, byid), true)
        w += 1.0 if r1["res"] == Combat.Result.WIN else (0.5 if r1["res"] == Combat.Result.ONGOING else 0.0)
        n += 1
    return w / n

# player uses optimal policy; foe uses optimal policy too (mirror ceiling)
func _policy_fight(me: ManabitState, foe: ManabitState, foe_aims_core: bool) -> Dictionary:
    var c := Combat.new()
    c.start(me, foe, foe_aims_core)
    var ps := {}
    var es := {}
    var g := 0
    while c.outcome() == Combat.Result.ONGOING and g < TURN_CAP:
        var actor := c.current()
        if actor == me: _policy_turn(c, me, foe, ps)
        else: _policy_turn(c, foe, me, es)
        if c.outcome() == Combat.Result.ONGOING: c.advance_turn()
        g += 1
    var mc: PartInstance = me.slots.get("CORE")
    var fc: PartInstance = foe.slots.get("CORE")
    return {"res": c.outcome(), "turns": g,
        "my_core": mc.current_hp if mc else 0, "my_core_max": mc.data.max_hp if mc else 0,
        "foe_core": fc.current_hp if fc else 0, "foe_core_max": fc.data.max_hp if fc else 0}

# player policy vs shipped-AI foe (the real in-game foe brain that core-hunts). race=true -> pure aggression.
func _policy_fight_shipfoe(me: ManabitState, foe: ManabitState, foe_aims_core: bool, race: bool) -> int:
    var c := Combat.new()
    c.start(me, foe, foe_aims_core)
    var ps := {}
    var g := 0
    while c.outcome() == Combat.Result.ONGOING and g < TURN_CAP:
        var actor := c.current()
        if actor == me:
            if race: _race_turn(c, me, foe)
            else: _policy_turn(c, me, foe, ps)
        else: c.ai_take_turn(foe, me)
        if c.outcome() == Combat.Result.ONGOING: c.advance_turn()
        g += 1
    return c.outcome()

# pure aggression: always the best core-aim SINGLE if any can target core, else best damage line. Never guard.
func _race_turn(c: Combat, attacker: ManabitState, defender: ManabitState) -> void:
    var moves: Array = c.moves_for(attacker)
    if moves.is_empty(): return
    var atk := int(attacker.derived().attack)
    var dfn := int(defender.derived().defense) + defender.guard_bonus
    var core_mv := {}; var core_dmg := 0
    for mv in moves:
        var a: AbilityData = mv["ability"]
        if a.archetype == "SINGLE" and a.can_target_core:
            var d := maxi(1, atk + a.power - dfn)
            if d > core_dmg: core_dmg = d; core_mv = mv
    if not core_mv.is_empty():
        c.perform(attacker, core_mv["ability"], defender, "CORE")
        return
    var best := {}
    for mv2 in moves:
        if (mv2["ability"] as AbilityData).archetype != "GUARD": best = mv2; break
    if best.is_empty(): best = moves[0]
    c.perform(attacker, best["ability"], defender, c._multi_target(defender))

# same core-aim + GUARD-when-behind policy as sim_roster v2 pentagon_v2
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

func _rname(r: int) -> String:
    match r:
        Combat.Result.WIN: return "WIN"
        Combat.Result.DEATH: return "DEATH"
        Combat.Result.SURVIVABLE_LOSS: return "SURVIVABLE_LOSS"
        _: return "STALL/ONGOING"
