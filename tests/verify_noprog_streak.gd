extends SceneTree
# FALSE-POSITIVE instrument for the StalemateBreaker. The driver fires when _noprog_turns reaches
# STALEMATE_LIMIT (10) - where a no-progress turn is one across which the COMBINED current-HP of both
# fighters did NOT decrease (ui/combat_screen.gd:_combined_hp / _apply). This probe measures, across
# thousands of NORMAL winnable/losable fights, the MAX consecutive no-progress streak that actually
# occurs - the false-positive headroom. If that max stays < 10, no normal fight can trip the breaker.
#
# It reuses the SHIPPED roster (Challengers) + SHIPPED catalog (Catalog) and drives combat.gd exactly
# as the auto-mode driver does (ai_take_turn each actor turn, both sides), plus a GUARD-heavy expert
# policy (the human-ish worst case for long guard runs). Read-only; touches nothing frozen.

const TURN_CAP := 400

func _initialize() -> void:
    var global_max := 0            # max streak among RESOLVED-by-damage fights (the false-positive number)
    var worst := ""
    var fights := 0
    var stalls := 0                # genuine stalemates (unresolved at cap) - the breaker SHOULD catch these
    var stall_min_streak := 1 << 30 # smallest max-streak among the genuine stalemates
    var resolved_over_limit := 0   # RESOLVED fights whose streak reached the limit (true false positives)
    var streak_hist := {}          # streak length -> count of RESOLVED fights with that max
    var ge5 := 0                   # resolved fights whose max no-progress streak >= 5 (getting close)

    var rng := RandomNumberGenerator.new()
    var ch := Challengers.list()
    var mods := ["", "rusted", "overgrown", "tailwind", "second_wind"]

    # 6000 fights: 3000 greedy-vs-greedy (auto-mode faithful) + 3000 guard-heavy-expert-vs-greedy.
    for policy in ["greedy", "guardy"]:
        for i in 3000:
            var seed := 424243 + i * 2654435761 + (0 if policy == "greedy" else 1000000007)
            rng.seed = seed
            var me := _rand_build(rng)
            var entry: Dictionary = ch[rng.randi() % ch.size()]
            var mod: String = mods[rng.randi() % mods.size()]
            var foe: ManabitState = Challengers.make(entry, mod, 0)
            var aims := rng.randi() % 2 == 0
            var r := _fight(me, foe, aims, policy)
            fights += 1
            var mx: int = r["max_streak"]
            if r["stalled"]:
                # genuine stalemate (never resolved by damage) - exactly what the breaker exists for
                stalls += 1
                stall_min_streak = mini(stall_min_streak, mx)
                continue
            # RESOLVED by damage: this is a normal winnable/losable fight
            if mx >= CombatScreen.STALEMATE_LIMIT:
                resolved_over_limit += 1
            if mx >= 5:
                ge5 += 1
            streak_hist[mx] = int(streak_hist.get(mx, 0)) + 1
            if mx > global_max:
                global_max = mx
                worst = "%s vs %s (mod=%s aims=%s policy=%s) result=%s turns=%d" % [
                    _desc(me), String(entry.get("name", "")), mod, str(aims), policy,
                    _res_word(int(r["result"])), int(r["turns"])]

    var resolved := fights - stalls
    print("=== NO-PROGRESS STREAK PROBE (%d fights: %d resolved-by-damage, %d genuine stalemates) ===" % [fights, resolved, stalls])
    print("STALEMATE_LIMIT (breaker fires at) = %d" % CombatScreen.STALEMATE_LIMIT)
    print("--- RESOLVED (normal winnable/losable) fights ---")
    print("MAX consecutive no-progress streak among RESOLVED fights = %d" % global_max)
    print("resolved fights that reached the limit (TRUE false positives) = %d" % resolved_over_limit)
    print("resolved fights with max-streak >= 5 = %d (%.2f%%)" % [ge5, 100.0 * ge5 / maxi(1, resolved)])
    print("worst resolved case: %s" % worst)
    var keys := streak_hist.keys()
    keys.sort()
    for k in keys:
        print("   resolved streak %2d : %d fights" % [int(k), int(streak_hist[k])])
    print("--- GENUINE stalemates (the breaker SHOULD catch these) ---")
    print("count = %d ; smallest max-streak among them = %d (>> limit %d, so all are caught well before cap)" % [
        stalls, (0 if stalls == 0 else stall_min_streak), CombatScreen.STALEMATE_LIMIT])
    var headroom := CombatScreen.STALEMATE_LIMIT - global_max
    # PASS: no RESOLVED (normal) fight ever reaches the limit, AND every genuine stalemate's streak
    # is far above the limit (a clean separation -> the breaker never fires on a normal fight).
    var ok := resolved_over_limit == 0 and global_max < CombatScreen.STALEMATE_LIMIT \
        and (stalls == 0 or stall_min_streak > CombatScreen.STALEMATE_LIMIT)
    print("FALSE-POSITIVE HEADROOM = %d (limit %d - worst resolved streak %d)" % [headroom, CombatScreen.STALEMATE_LIMIT, global_max])
    print("STREAK PASS" if ok else "STREAK FAIL")
    quit(0 if ok else 1)

# Drive combat.gd turn-by-turn; count the max run of consecutive actor-turns across which combined
# current-HP did NOT decrease - identical to the driver's _noprog_turns accounting.
func _fight(me: ManabitState, foe: ManabitState, aims: bool, policy: String) -> Dictionary:
    var c := Combat.new()
    c.start(me, foe, aims)
    var pstate := {}
    var guard := 0
    var streak := 0
    var maxs := 0
    while c.outcome() == Combat.Result.ONGOING and guard < TURN_CAP:
        var actor: ManabitState = c.current()
        var hp_before := _combined(me, foe)
        if actor == me and policy == "guardy":
            _guardy_turn(c, me, foe, pstate)
        else:
            c.ai_take_turn(actor, foe if actor == me else me)
        if _combined(me, foe) < hp_before:
            streak = 0
        else:
            streak += 1
            maxs = maxi(maxs, streak)
        if c.outcome() == Combat.Result.ONGOING:
            c.advance_turn()
        guard += 1
    var res: int = c.outcome()
    return {"result": res, "turns": guard, "max_streak": maxs, "stalled": res == Combat.Result.ONGOING}

# GUARD-heavy human-ish lens: GUARD whenever the core is even slightly behind (models a cautious
# player who over-guards) - the worst realistic case for long no-damage runs. Never a parallel
# resolver; only calls the shipped moves_for/perform.
func _guardy_turn(c: Combat, me: ManabitState, foe: ManabitState, pstate: Dictionary) -> void:
    var moves := c.moves_for(me)
    if moves.is_empty():
        return
    var mc: PartInstance = me.core()
    var fc: PartInstance = foe.core()
    if mc != null and fc != null:
        var my_r := float(mc.current_hp) / float(mc.data.max_hp)
        var fo_r := float(fc.current_hp) / float(fc.data.max_hp)
        # over-guard: any deficit AND not guarded last turn -> guard again (still capped to alternate)
        if my_r < fo_r and not bool(pstate.get("guarded", false)):
            for mv in moves:
                if (mv["ability"] as AbilityData).archetype == "GUARD":
                    c.perform(me, mv["ability"], foe, "")
                    pstate["guarded"] = true
                    return
    pstate["guarded"] = false
    var chosen: Dictionary = moves[0]
    for mv2 in moves:
        if (mv2["ability"] as AbilityData).archetype != "GUARD":
            chosen = mv2
            break
    var ab: AbilityData = chosen["ability"]
    if ab.archetype == "GUARD":
        c.perform(me, ab, foe, "")
    elif ab.archetype == "MULTI":
        c.perform(me, ab, foe, c._multi_target(foe))
    else:
        c.perform(me, ab, foe, c._multi_target(foe))

func _combined(a: ManabitState, b: ManabitState) -> int:
    var t := 0
    for m in [a, b]:
        for slot in ManabitState.SLOT_NAMES:
            var pi = m.slots.get(slot)
            if pi != null:
                t += pi.current_hp
    return t

# Random LEGAL build off the real catalog: a core + 1..5 body bits, kept within capacity, always at
# least one offensive bit so it is a normal fightable build (not a stalemate trap).
func _rand_build(rng: RandomNumberGenerator) -> ManabitState:
    var m := ManabitState.new()
    for s in ManabitState.SLOT_NAMES:
        m.slots[s] = null
    var cores: Array = Catalog.cores()
    m.slots["CORE"] = PartInstance.new(cores[rng.randi() % cores.size()])
    var body: Array = Catalog.body_pool()
    var slots := ["ARM_R", "ARM_L", "HEAD", "LEGS", "BACK"]
    var nfill := 1 + rng.randi() % 5
    for k in nfill:
        var slot: String = slots[k]
        var pool: Array = []
        for pd in body:
            var p: PartData = pd
            if _fits(slot, p) and int(p.weight) <= _budget(m):
                pool.append(p)
        if not pool.is_empty():
            m.slots[slot] = PartInstance.new(pool[rng.randi() % pool.size()])
    if not m.has_offensive_move():
        for pd in body:
            var p: PartData = pd
            if _fits("ARM_R", p) and p.ability != null and p.ability.archetype != "GUARD" and int(p.weight) <= _budget(m):
                m.slots["ARM_R"] = PartInstance.new(p)
                break
    return m

func _fits(slot: String, pd: PartData) -> bool:
    if slot == "ARM_L" or slot == "ARM_R":
        return pd.slot == "ARM_L" or pd.slot == "ARM_R"
    return pd.slot == slot

func _budget(m: ManabitState) -> int:
    var d: Dictionary = m.derived()
    return int(d["capacity"]) - int(d["weight"])

func _desc(m: ManabitState) -> String:
    var d: Dictionary = m.derived()
    return "build(ATK%d DEF%d SPD%d E%d)" % [int(d["attack"]), int(d["defense"]), int(d["speed"]), int(d["energy"])]

func _res_word(res: int) -> String:
    match res:
        Combat.Result.WIN: return "WIN"
        Combat.Result.DEATH: return "DEATH"
        Combat.Result.SURVIVABLE_LOSS: return "SURVIVABLE_LOSS"
        _: return "STALL"
