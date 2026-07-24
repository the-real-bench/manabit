extends SceneTree
# LADDER + VENTURE SIM (encounter-designer + qa lane). READ-ONLY on game state: never touches
# PlayerState saves or user://. Reuses the smoke_kit_sim fight-loop pattern (both-sides shipped AI
# via combat.ai_take_turn) and the shipped run helpers (RunState._make_map -> choose ->
# RunMods.pre_fight_mend / note_win + consume_core_pad -> Challengers.make(entry, mod_id, rider)).
#
# Part A - THE LADDER: each of the 9 challengers vs 6 seeded archetype build generators
# (cheap 3-slot COMMON up to full EPIC-core flagship), SEEDS_A seeds each. Records win rate,
# mean actor-turns, mean player parts broken per fight. Verifies the ladder hardens
# monotonically (regulars < elites < bosses in player win rate) and quantifies rung gaps.
#
# Part B - THE VENTURE: full 5-node road Monte Carlo for OWN-BUILD ventures (kit runs belong to
# smoke_kit_sim). Mid + strong builds x both road templates x all 4 junction lane pairs x SEEDS_B
# seeds. Policy model (deterministic): always repair fully at rests (wallet assumed, spend
# tracked); loot the highest-melt foe bit on WIN; forfeit the lowest-melt broken bit on a
# survivable loss; press on to the end (extraction measured as trigger rates + death-ahead odds,
# not acted on). NOTE: own-build ventures pay NO WIN purse in shipped code (PlayerState.KIT_PURSE
# is Box-of-Scrap only), so scrap economy here = forfeit salvage - repairs, with loot melt value
# reported separately.
#
# Plus controlled junction-modifier experiments (same seeds both arms, single variable):
#   rusted / overgrown - foe-side, full-HP player, modded vs clean foe;
#   tailwind - player enters the boss lane pre-damaged (skipped repairs), mend-4 vs no mend;
#   second_wind - win the elite lane, mend-3 vs not, then fight the boss UNREPAIRED.
#
# Wave-3 G0 additions (design/economy/venture-depth-wave3.md, PREDICTIVE - no game code exists
# yet): part B emits own-wreck + death-HP-fraction under the Gleaner's Due formula computed
# offline from the run traces; a wave3_g0 block models the spec's shrine mix / heap dig /
# Gleaner's canon, runs a paired event-road experiment on Template A, and measures the D12
# re-time candidates for the dead tailwind / second_wind rules.
#
# Output: G:/ClaudeApps/manabit/tools/sim/out/ladder.json + printed human summary.
# Run: & "G:/Godot/Godot_v4.7-stable_win64_console.exe" --headless --path G:/ClaudeApps/manabit -s "res://tools/sim/sim_ladder.gd"

const OUT_DIR := "G:/ClaudeApps/manabit/tools/sim/out"
const OUT_PATH := "G:/ClaudeApps/manabit/tools/sim/out/ladder.json"
const TURN_CAP := 600              # actor-turns; unresolved at cap = "stall", counted honestly
const SEEDS_A := 48                # seeds per (challenger x archetype) rung fight
const SEEDS_B := 64                # seeds per venture config and per experiment arm
const SEEDS_C := 48                # Part C bout mode: seeds per (challenger x archetype)

const ARCHS := [
    {"id": "sprout_3slot",      "desc": "COMMON core + COMMON weapon arm + COMMON legs (cheap 3-slot)"},
    {"id": "common_kit_5slot",  "desc": "COMMON core + COMMON head/arms/legs, no back (5-slot)"},
    {"id": "tuned_mixed_6slot", "desc": "COMMON core, COMMON-or-RARE bits in all 6 sockets (mid tier)"},
    {"id": "rare_core_6slot",   "desc": "RARE core, RARE-first fill in all 6 sockets"},
    {"id": "rare_epic_weapon",  "desc": "RARE core + top-power EPIC weapon arm + RARE-first fill (strong)"},
    {"id": "epic_flagship",     "desc": "EPIC Regalia core + EPIC centerpiece + EPIC-first budget fill (ceiling)"},
]
const MID_ARCH := 2                # Part B "mid-tier build" generator
const STRONG_ARCH := 4             # Part B "strong build" generator

const REGULARS := [0, 1, 2]
const ELITES := [3, 5, 6, 7]
const BOSSES := [4, 8]

func _initialize() -> void:
    var t0 := Time.get_ticks_msec()
    DirAccess.make_dir_recursive_absolute(OUT_DIR)

    print("MANABIT sim_ladder - Part A ladder (%d challengers x %d archetypes x %d seeds)" % [
        Challengers.list().size(), ARCHS.size(), SEEDS_A])
    var part_a := _run_ladder()
    print("Part B venture (2 builds x 2 templates x 4 lane pairs x %d seeds)" % SEEDS_B)
    var part_b := _run_venture()
    print("Modifier experiments (controlled, %d seeds per arm)" % SEEDS_B)
    var mods := _run_mod_experiments()
    print("Part C bout mode (%d challengers x %d archetypes x %d seeds, foe never aims the core)" % [
        Challengers.list().size(), ARCHS.size(), SEEDS_C])
    var part_c := _run_bouts()
    print("Wave-3 G0 models (shrine/heap/gleaners predictions + event roads + D12 re-time)")
    var wave3 := _run_wave3()

    var report := {
        "meta": {
            "generated": Time.get_datetime_string_from_system(),
            "seeds_part_a": SEEDS_A,
            "seeds_part_b": SEEDS_B,
            "turn_cap_actor_turns": TURN_CAP,
            "combat_note": "combat.gd is fully deterministic; all variance comes from seeded build generation",
            "ai_note": "both sides use the shipped combat.ai_take_turn (first affordable non-GUARD move in slot order, HEAD first); this understates optimized human play on both sides equally",
            "aims_core_note": "part A uses entry.elite as aims_core (run-context rule); regulars never aim the core",
            "purse_note": "own-build ventures pay NO win purse in shipped code (PlayerState.KIT_PURSE is kit-only); net scrap = forfeit salvage - repairs, loot melt value reported separately",
            "policy_note": "venture policy: repair fully at every rest, loot highest-melt bit, forfeit lowest-melt broken bit, never extract (extraction reported as trigger + death-ahead rates)",
        },
        "part_a_ladder": part_a,
        "part_b_venture": part_b,
        "modifier_experiments": mods,
        "part_c_bout": part_c,
        "wave3_g0": wave3,
    }
    report["headline"] = _headline(part_a, part_b, mods)

    var f := FileAccess.open(OUT_PATH, FileAccess.WRITE)
    var ok := f != null
    if ok:
        f.store_string(JSON.stringify(report, "  "))
        f.close()
    print("")
    _print_summary(part_a, part_b, mods)
    _print_bout_summary(part_c)
    _print_wave3(wave3, part_b)
    print("")
    print("json written: %s (%s)" % [OUT_PATH, "OK" if ok else "WRITE FAILED"])
    print("elapsed: %.1fs" % ((Time.get_ticks_msec() - t0) / 1000.0))
    print("SIM PASS" if ok else "SIM FAIL")
    quit(0 if ok else 1)

# ================================ PART A - THE LADDER ================================

func _run_ladder() -> Dictionary:
    var ch := Challengers.list()
    # builds are generated once per (archetype, seed) and cloned per fight - the SAME spread of
    # player builds walks every rung, so rung deltas are paired, not resampled.
    var builds: Array = []
    for ai in ARCHS.size():
        var per_seed: Array = []
        for s in SEEDS_A:
            var bseed: int = 700001 + ai * 331 + s * 104729
            per_seed.append(_build_archetype(ai, bseed))
        builds.append(per_seed)

    var challengers_out: Array = []
    for ci in ch.size():
        var entry: Dictionary = ch[ci]
        var aims: bool = bool(entry.get("elite", false))
        var tier := "boss" if BOSSES.has(ci) else ("elite" if ELITES.has(ci) else "regular")
        var agg := _acc()
        var per_arch := {}
        for ai in ARCHS.size():
            var acc := _acc()
            for s in SEEDS_A:
                var me: ManabitState = _clone(builds[ai][s])
                var foe: ManabitState = Challengers.make(entry)
                var r := _fight(me, foe, aims)
                _acc_add(acc, r)
                _acc_add(agg, r)
            per_arch[String(ARCHS[ai]["id"])] = _acc_out(acc)
        var out := {
            "index": ci,
            "name": String(entry.get("name", "")),
            "tier": tier,
            "aims_core": aims,
            "aggregate": _acc_out(agg),
            "per_archetype": per_arch,
        }
        challengers_out.append(out)
        var a: Dictionary = out["aggregate"]
        print("  ch[%d] %-38s win %.3f  death %.3f  turns %5.1f  broken %.2f" % [
            ci, String(entry.get("name", "")).left(38), float(a["win_rate"]),
            float(a["death_rate"]), float(a["mean_actor_turns"]), float(a["mean_parts_broken"])])

    # monotonicity: sorted by player win rate (softest first) + tier separation checks
    var order: Array = []
    for c in challengers_out:
        order.append({"index": int(c["index"]), "name": String(c["name"]), "tier": String(c["tier"]),
            "win_rate": float((c["aggregate"] as Dictionary)["win_rate"])})
    order.sort_custom(func(x, y): return float(x["win_rate"]) > float(y["win_rate"]))
    var gaps: Array = []
    for i in range(order.size() - 1):
        var hi: Dictionary = order[i]
        var lo: Dictionary = order[i + 1]
        gaps.append({"from": String(hi["name"]), "to": String(lo["name"]),
            "win_rate_drop": _r(float(hi["win_rate"]) - float(lo["win_rate"]))})

    var wr := func(idx: int) -> float:
        for c in challengers_out:
            if int(c["index"]) == idx:
                return float((c["aggregate"] as Dictionary)["win_rate"])
        return -1.0
    var reg_rates: Array = []
    for i in REGULARS:
        reg_rates.append(wr.call(i))
    var eli_rates: Array = []
    for i in ELITES:
        eli_rates.append(wr.call(i))
    var bos_rates: Array = []
    for i in BOSSES:
        bos_rates.append(wr.call(i))
    var checks := {
        "rusty_is_softest": float(order[0]["index"] == 0),
        "regulars_in_order_0_1_2": float(reg_rates[0] >= reg_rates[1] and reg_rates[1] >= reg_rates[2]),
        "every_regular_softer_than_every_elite": float(reg_rates.min() >= eli_rates.max()),
        "every_elite_softer_than_every_boss": float(eli_rates.min() >= bos_rates.max()),
        "regular_to_elite_gap": _r(float(reg_rates.min()) - float(eli_rates.max())),
        "elite_to_boss_gap": _r(float(eli_rates.min()) - float(bos_rates.max())),
    }
    var samples := {}
    for ai in ARCHS.size():
        samples[String(ARCHS[ai]["id"])] = _build_ids(builds[ai][0])
    return {
        "archetypes": ARCHS,
        "sample_builds_seed0": samples,
        "challengers": challengers_out,
        "ladder_softest_to_cruelest": order,
        "rung_gaps": gaps,
        "monotonic_checks": checks,
    }

# ================================ PART B - THE VENTURE ================================

func _run_venture() -> Dictionary:
    var lane_labels := _lane_labels()
    var configs: Array = []
    var lane_stats := {}               # label -> {n, win, sl, death, stall}
    var tier_agg := {"mid": [], "strong": []}
    var tt_agg := {}                   # "<tier>_T<t>" -> rows (per-template safe-end/clear, G0)
    for bt in ["mid", "strong"]:
        var arch: int = MID_ARCH if bt == "mid" else STRONG_ARCH
        for t in RunState.TEMPLATES.size():
            for el in 2:
                for bl in 2:
                    var rows: Array = []
                    for s in SEEDS_B:
                        var bseed: int = 810001 + arch * 613 + s * 104729
                        var build := _build_archetype(arch, bseed)
                        var row := _venture(build, t, el, bl, lane_stats, lane_labels)
                        rows.append(row)
                        (tier_agg[bt] as Array).append(row)
                        var tk := "%s_T%d" % [bt, t]
                        if not tt_agg.has(tk):
                            tt_agg[tk] = []
                        (tt_agg[tk] as Array).append(row)
                    var cfg := _venture_agg(rows)
                    cfg["build_tier"] = bt
                    cfg["template"] = t
                    cfg["template_name"] = String((RunState.TEMPLATES[t] as Dictionary)["name"])
                    cfg["elite_lane"] = String(lane_labels["%d_2_%d" % [t, el]])
                    cfg["boss_lane"] = String(lane_labels["%d_4_%d" % [t, bl]])
                    configs.append(cfg)
                    print("  %-6s T%d  elite=%-34s boss=%-34s survive %.3f" % [
                        bt, t, String(cfg["elite_lane"]).left(34), String(cfg["boss_lane"]).left(34),
                        float(cfg["survival_rate"])])
    var lanes_out := {}
    for k in lane_stats.keys():
        var st: Dictionary = lane_stats[k]
        var n: int = int(st["n"])
        lanes_out[k] = {
            "n_fought": n,
            "win_rate": _r(float(st["win"]) / n) if n > 0 else 0.0,
            "death_rate": _r(float(st["death"]) / n) if n > 0 else 0.0,
            "survivable_loss_rate": _r(float(st["sl"]) / n) if n > 0 else 0.0,
        }
    var by_tt := {}
    for tk in tt_agg.keys():
        var agg: Dictionary = _venture_agg(tt_agg[tk])
        # own-build press-on policy: safe-end == clear == survival (extraction never acted on)
        by_tt[tk] = {
            "n": int(agg["n"]),
            "safe_end_rate": float(agg["survival_rate"]),
            "clear_rate": float(agg["survival_rate"]),
            "death_rate_elite": float(agg["death_rate_elite"]),
            "death_rate_boss": float(agg["death_rate_boss"]),
            "own_wreck_mean_per_run": float(agg["own_wreck_mean_per_run"]),
            "mean_net_scrap_with_gleaners_wreck": float(agg["mean_net_scrap_with_gleaners_wreck"]),
        }
    return {
        "policy": "repair-always, press-on, loot best, forfeit cheapest broken",
        "configs": configs,
        "by_build_tier": {
            "mid": _venture_agg(tier_agg["mid"]),
            "strong": _venture_agg(tier_agg["strong"]),
        },
        "by_tier_template": by_tt,
        "lane_observational": lanes_out,
    }

# one full 5-node road walk under the deterministic policy; mutates nothing shared
func _venture(build: ManabitState, t: int, elite_lane: int, boss_lane: int,
        lane_stats: Dictionary, lane_labels: Dictionary) -> Dictionary:
    var run := RunState.new()
    run.carried = _clone(build)
    run.map = run._make_map(t)
    run.pos = 0
    var out := {
        "survived": 0, "death_tier": "", "repairs_paid": 0, "forfeit_salvage": 0,
        "loot_melt": 0, "bits_looted": 0, "bits_lost": 0, "stalls": 0,
        "rest1": 0, "rest2": 0, "extract_trigger1": 0, "extract_trigger2": 0,
        "wreck_scrap": 0, "death_h_frac": 0.0,
    }
    while not run.over:
        var nd: Dictionary = run.node()
        var ntype := String(nd.get("type", ""))
        if ntype == "REST":
            if run.pos == 1:
                out["rest1"] = 1
                out["extract_trigger1"] = 1 if int(out["bits_lost"]) > 0 else 0
            else:
                out["rest2"] = 1
                out["extract_trigger2"] = 1 if int(out["bits_lost"]) > 0 else 0
            out["repairs_paid"] = int(out["repairs_paid"]) + run.repair_cost()
            run.repair_all()
            run.advance()
            continue
        if ntype == "JUNCTION":
            run.choose(elite_lane if run.pos == 2 else boss_lane)
            continue
        # FIGHT - shipped hooks: tailwind pre-mend + second_wind core pad, foe-side modifier
        RunMods.pre_fight_mend(run)
        RunMods.consume_core_pad(run)      # shipped D12 rule: the pad lands at the next bell
        var nd2: Dictionary = run.node()
        var mod_id := String((nd2.get("modifier", {}) as Dictionary).get("id", ""))
        var foe: ManabitState = Challengers.make(nd2["challenger"], mod_id)
        var aims := bool(nd2.get("aims_core", false))
        var r := _fight(run.carried, foe, aims)
        var res: int = int(r["result"])
        if bool(r["stalled"]):
            out["stalls"] = int(out["stalls"]) + 1
        var tier := String(nd2.get("tier", ""))
        var key := "%d_%d_%d" % [t, run.pos, (elite_lane if run.pos == 2 else boss_lane)]
        if tier != "skirmish":
            var label := String(lane_labels.get(key, key))
            if not lane_stats.has(label):
                lane_stats[label] = {"n": 0, "win": 0, "sl": 0, "death": 0}
            var st: Dictionary = lane_stats[label]
            st["n"] = int(st["n"]) + 1
        if res == Combat.Result.WIN:
            if tier != "skirmish":
                var stw: Dictionary = lane_stats[String(lane_labels.get(key, key))]
                stw["win"] = int(stw["win"]) + 1
            var loot_pd := _best_loot(foe)
            if loot_pd != null:
                out["loot_melt"] = int(out["loot_melt"]) + Broker.salvage_scrap(loot_pd)
                out["bits_looted"] = int(out["bits_looted"]) + 1
            RunMods.note_win(run)          # second_wind banks its core pad, pre-advance (shipped order)
            run.advance()
        elif res == Combat.Result.DEATH:
            if tier != "skirmish":
                var std: Dictionary = lane_stats[String(lane_labels.get(key, key))]
                std["death"] = int(std["death"]) + 1
            out["death_tier"] = tier
            var seated := 0
            for slot in ManabitState.SLOT_NAMES:
                var pi: PartInstance = run.carried.slots.get(slot)
                if pi != null:
                    seated += 1
            out["bits_lost"] = int(out["bits_lost"]) + seated
            # Wave-3 Gleaner's Due: own wreck now computed through the SHIPPED statics
            # (RunState.gleaners_wreck - own-build K halved per the G9 out-of-band action).
            out["wreck_scrap"] = RunState.gleaners_wreck(run.carried, tier)
            out["death_h_frac"] = RunState.death_h(run.carried)
            run.over = true
        else:
            # SURVIVABLE_LOSS (or stall artifact): forfeit the cheapest broken bit, salvage paid
            if tier != "skirmish":
                var sts: Dictionary = lane_stats[String(lane_labels.get(key, key))]
                sts["sl"] = int(sts["sl"]) + 1
            if res == Combat.Result.SURVIVABLE_LOSS:
                var fslot := _forfeit_pick(run.carried)
                if fslot != "":
                    var fpi: PartInstance = run.carried.slots[fslot]
                    out["forfeit_salvage"] = int(out["forfeit_salvage"]) + Broker.salvage_scrap(fpi.data)
                    out["bits_lost"] = int(out["bits_lost"]) + 1
                    run.carried.slots[fslot] = null
            run.advance()
    out["survived"] = 1 if String(out["death_tier"]) == "" else 0
    return out

func _venture_agg(rows: Array) -> Dictionary:
    var n := rows.size()
    if n == 0:
        return {}
    var sums := {"survived": 0, "repairs_paid": 0, "forfeit_salvage": 0, "loot_melt": 0,
        "bits_looted": 0, "bits_lost": 0, "stalls": 0, "rest1": 0, "rest2": 0,
        "extract_trigger1": 0, "extract_trigger2": 0, "wreck_scrap": 0}
    var death_elite := 0
    var death_boss := 0
    var death_ahead1 := 0
    var death_ahead2 := 0
    var wreck_elite := 0
    var wreck_boss := 0
    var h_sum := 0.0
    for row in rows:
        var rr: Dictionary = row
        for k in sums.keys():
            sums[k] = int(sums[k]) + int(rr[k])
        var dt := String(rr["death_tier"])
        if dt == "elite":
            death_elite += 1
            wreck_elite += int(rr["wreck_scrap"])
        elif dt == "boss":
            death_boss += 1
            wreck_boss += int(rr["wreck_scrap"])
        if dt != "":
            h_sum += float(rr["death_h_frac"])
        if int(rr["rest1"]) == 1 and dt != "":
            death_ahead1 += 1
        if int(rr["rest2"]) == 1 and dt != "":
            death_ahead2 += 1
    var n_death: int = death_elite + death_boss
    var r1: int = int(sums["rest1"])
    var r2: int = int(sums["rest2"])
    return {
        "n": n,
        "survival_rate": _r(float(sums["survived"]) / n),
        "death_rate_elite": _r(float(death_elite) / n),
        "death_rate_boss": _r(float(death_boss) / n),
        "death_ahead_if_pressing_from_rest1": _r(float(death_ahead1) / r1) if r1 > 0 else 0.0,
        "death_ahead_if_pressing_from_rest2": _r(float(death_ahead2) / r2) if r2 > 0 else 0.0,
        "reach_rest1_rate": _r(float(r1) / n),
        "reach_rest2_rate": _r(float(r2) / n),
        "extract_trigger_rate_rest1": _r(float(sums["extract_trigger1"]) / r1) if r1 > 0 else 0.0,
        "extract_trigger_rate_rest2": _r(float(sums["extract_trigger2"]) / r2) if r2 > 0 else 0.0,
        "mean_repairs_paid_scrap": _r(float(sums["repairs_paid"]) / n),
        "mean_forfeit_salvage_scrap": _r(float(sums["forfeit_salvage"]) / n),
        "mean_net_scrap_purse_plus_salvage_minus_repairs": _r((0.0 + float(sums["forfeit_salvage"]) - float(sums["repairs_paid"])) / n),
        "mean_loot_melt_value_scrap": _r(float(sums["loot_melt"]) / n),
        "mean_bits_looted": _r(float(sums["bits_looted"]) / n),
        "mean_bits_lost": _r(float(sums["bits_lost"]) / n),
        "stalled_fights": int(sums["stalls"]),
        "own_wreck_mean_per_run": _r(float(sums["wreck_scrap"]) / n),
        "own_wreck_mean_per_death": _r(float(sums["wreck_scrap"]) / n_death) if n_death > 0 else 0.0,
        "own_wreck_mean_elite_death": _r(float(wreck_elite) / death_elite) if death_elite > 0 else 0.0,
        "own_wreck_mean_boss_death": _r(float(wreck_boss) / death_boss) if death_boss > 0 else 0.0,
        "death_h_frac_mean": _r(h_sum / n_death) if n_death > 0 else 0.0,
        "mean_net_scrap_with_gleaners_wreck": _r((float(sums["forfeit_salvage"]) + float(sums["wreck_scrap"]) - float(sums["repairs_paid"])) / n),
    }

func _lane_labels() -> Dictionary:
    var out := {}
    for t in RunState.TEMPLATES.size():
        var m: Array = RunState.new()._make_map(t)
        for p in m.size():
            var step: Dictionary = m[p]
            if String(step.get("type", "")) != "JUNCTION":
                continue
            var paths: Array = step["paths"]
            for li in paths.size():
                var ln: Dictionary = paths[li]
                var nd: Dictionary = ln["node"]
                var cname := String((nd.get("challenger", {}) as Dictionary).get("name", "")).get_slice(",", 0)
                out["%d_%d_%d" % [t, p, li]] = "T%d %s %s [%s] (%s)" % [
                    t, String(nd.get("tier", "")), String(ln.get("lane_name", "")),
                    String((ln.get("modifier", {}) as Dictionary).get("id", "")), cname]
    return out

# ================================ PART C - BOUT MODE (v2 instrument) ================================
# Proving Grounds economics: every challenger with aims_core=false (begin_bout rule) vs a
# core-aiming player proxy. Prices CH-08/CH-09 and sizes D7. EV model matches shipped post-wave-1
# code: WIN loots the best non-core foe bit (melt value), survivable loss pays ZERO salvage,
# the tier stake (PlayerState.bout_stake) is charged win or lose.

func _run_bouts() -> Dictionary:
    var ch := Challengers.list()
    var builds: Array = []
    for ai in ARCHS.size():
        var per_seed: Array = []
        for s in SEEDS_C:
            var bseed: int = 940001 + ai * 331 + s * 104729
            per_seed.append(_build_archetype(ai, bseed))
        builds.append(per_seed)
    var rows: Array = []
    for ci in ch.size():
        var entry: Dictionary = ch[ci]
        var stake: int = PlayerState.bout_stake(entry)
        var best_pd: PartData = _best_loot(Challengers.make(entry))
        var best_melt: int = Broker.salvage_scrap(best_pd) if best_pd != null else 0
        var wins: int = 0
        var sls: int = 0
        var stalls: int = 0
        var turns_sum: int = 0
        var loot_sum: int = 0
        var n: int = 0
        var per_arch := {}
        for ai in ARCHS.size():
            var awins: int = 0
            for s in SEEDS_C:
                var me: ManabitState = _clone(builds[ai][s])
                var foe: ManabitState = Challengers.make(entry)
                var r := _fight_bout(me, foe)
                n += 1
                turns_sum += int(r["turns"])
                var res: int = int(r["result"])
                if res == Combat.Result.WIN:
                    wins += 1
                    awins += 1
                    var pd: PartData = _best_loot(foe)
                    loot_sum += Broker.salvage_scrap(pd) if pd != null else 0
                elif res == Combat.Result.SURVIVABLE_LOSS:
                    sls += 1
                elif bool(r["stalled"]):
                    stalls += 1
            per_arch[String(ARCHS[ai]["id"])] = _r(float(awins) / SEEDS_C)
        var win_rate: float = float(wins) / n
        var ev: float = (float(loot_sum) / n) - float(stake)
        var row := {
            "index": ci,
            "name": String(entry.get("name", "")),
            "stake": stake,
            "best_loot_melt": best_melt,
            "n": n,
            "win_rate": _r(win_rate),
            "survivable_loss_rate": _r(float(sls) / n),
            "stall_rate": _r(float(stalls) / n),
            "mean_turns_per_bout": _r(float(turns_sum) / n),
            "ev_scrap_per_bout_measured": _r(ev),
            "ev_scrap_at_half_prior": _r(0.5 * float(best_melt) - float(stake)),
            "win_rate_per_archetype": per_arch,
        }
        rows.append(row)
        print("  bout ch[%d] %-38s win %.3f  EV %+6.1f scrap  (stake %d, best loot %d, turns %.1f)" % [
            ci, String(entry.get("name", "")).left(38), win_rate, ev, stake, best_melt,
            float(turns_sum) / n])
    return {
        "design": "foe aims_core=false (begin_bout), player proxy = core-aiming policy (best affordable can_target_core SINGLE when it out-damages the part-break line, GUARD-when-behind); EV = mean best-loot melt on WIN - tier stake; survivable loss pays 0 (CH-09)",
        "stakes": {"regular": PlayerState.BOUT_STAKE_REGULAR, "elite": PlayerState.BOUT_STAKE_ELITE, "boss": PlayerState.BOUT_STAKE_BOSS},
        "rows": rows,
    }

func _print_bout_summary(part_c: Dictionary) -> void:
    print("==================== PART C BOUT SUMMARY ====================")
    for row in part_c["rows"]:
        var rr: Dictionary = row
        print("  %-40s win %.3f  EV %+6.1f (at-0.5-prior %+6.1f)  stake %d  turns %.1f" % [
            String(rr["name"]).left(40), float(rr["win_rate"]), float(rr["ev_scrap_per_bout_measured"]),
            float(rr["ev_scrap_at_half_prior"]), int(rr["stake"]), float(rr["mean_turns_per_bout"])])

# Bout fight: player side uses the core-aiming policy, foe uses the shipped AI with no core aim.
func _fight_bout(me: ManabitState, foe: ManabitState) -> Dictionary:
    var c := Combat.new()
    c.start(me, foe, false)
    var pstate: Dictionary = {}
    var guard := 0
    while c.outcome() == Combat.Result.ONGOING and guard < TURN_CAP:
        var actor: ManabitState = c.current()
        if actor == me:
            _policy_take_turn(c, me, foe, pstate)
        else:
            c.ai_take_turn(foe, me)
        if c.outcome() == Combat.Result.ONGOING:
            c.advance_turn()
        guard += 1
    var res: int = c.outcome()
    return {"result": res, "turns": guard, "stalled": res == Combat.Result.ONGOING}

# Core-aiming + GUARD-when-behind player proxy (same lens as sim_roster v2 - instrument, not shipped AI).
func _policy_take_turn(c: Combat, attacker: ManabitState, defender: ManabitState, pstate: Dictionary) -> void:
    var moves: Array = c.moves_for(attacker)
    if moves.is_empty():
        return
    var default_mv: Dictionary = moves[0]
    for mv in moves:
        var mvd: Dictionary = mv
        if (mvd["ability"] as AbilityData).archetype != "GUARD":
            default_mv = mvd
            break
    var atk: int = int(attacker.derived().attack)
    var dfn: int = int(defender.derived().defense) + defender.guard_bonus
    var core_mv: Dictionary = {}
    var core_dmg: int = 0
    for mv2 in moves:
        var mvd2: Dictionary = mv2
        var a2: AbilityData = mvd2["ability"]
        if a2.archetype == "SINGLE" and a2.can_target_core:
            var d2: int = maxi(1, atk + a2.power - dfn)
            if d2 > core_dmg:
                core_dmg = d2
                core_mv = mvd2
    var def_ab: AbilityData = default_mv["ability"]
    var def_dmg: int = 0
    if def_ab.archetype != "GUARD":
        def_dmg = maxi(1, atk + def_ab.power - dfn) * maxi(1, def_ab.hit_count)
    if not core_mv.is_empty() and core_dmg > def_dmg:
        c.perform(attacker, core_mv["ability"], defender, "CORE")
        pstate["guarded"] = false
        return
    var mc: PartInstance = attacker.slots.get("CORE")
    var fc: PartInstance = defender.slots.get("CORE")
    if mc != null and fc != null and not bool(pstate.get("guarded", false)):
        var my_r: float = float(mc.current_hp) / float(mc.data.max_hp)
        var foe_r: float = float(fc.current_hp) / float(fc.data.max_hp)
        if my_r + 0.15 < foe_r:
            for mv3 in moves:
                var mvd3: Dictionary = mv3
                var a3: AbilityData = mvd3["ability"]
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

# ========================= CONTROLLED MODIFIER EXPERIMENTS =========================

func _run_mod_experiments() -> Dictionary:
    var out := {}
    var lanes := _junction_lanes()
    # rusted / overgrown: foe-side - full-HP player, modded foe vs clean foe, same seeds
    for mod in ["rusted", "overgrown"]:
        var rows: Array = []
        for L in lanes:
            var lane: Dictionary = L
            if String(lane["mod"]) != mod:
                continue
            for bt in ["mid", "strong"]:
                var arch: int = MID_ARCH if bt == "mid" else STRONG_ARCH
                var wins_mod := 0
                var wins_clean := 0
                var deaths_mod := 0
                var deaths_clean := 0
                for s in SEEDS_B:
                    var bseed: int = 910001 + arch * 613 + s * 104729
                    var build := _build_archetype(arch, bseed)
                    var rm := _fight(_clone(build), Challengers.make(lane["entry"], mod), true)
                    var rc := _fight(_clone(build), Challengers.make(lane["entry"], ""), true)
                    if int(rm["result"]) == Combat.Result.WIN:
                        wins_mod += 1
                    if int(rc["result"]) == Combat.Result.WIN:
                        wins_clean += 1
                    if int(rm["result"]) == Combat.Result.DEATH:
                        deaths_mod += 1
                    if int(rc["result"]) == Combat.Result.DEATH:
                        deaths_clean += 1
                rows.append({
                    "lane": String(lane["label"]), "build_tier": bt, "n": SEEDS_B,
                    "win_rate_with_mod": _r(float(wins_mod) / SEEDS_B),
                    "win_rate_clean": _r(float(wins_clean) / SEEDS_B),
                    "win_rate_delta": _r(float(wins_mod - wins_clean) / SEEDS_B),
                    "death_rate_with_mod": _r(float(deaths_mod) / SEEDS_B),
                    "death_rate_clean": _r(float(deaths_clean) / SEEDS_B),
                })
        out[mod] = {"design": "same player build + seed, foe with vs without the modifier, aims_core true", "rows": rows}

    # tailwind: matters only when entering damaged (a repaired build mends 0). Pre-damage via a
    # clean Rusty fight, then boss lane with vs without the shipped pre-mend, same damaged state.
    var tw_rows: Array = []
    var ch := Challengers.list()
    for L in lanes:
        var lane: Dictionary = L
        if String(lane["mod"]) != "tailwind":
            continue
        for bt in ["mid", "strong"]:
            var arch: int = MID_ARCH if bt == "mid" else STRONG_ARCH
            var used := 0
            var wins_a := 0
            var wins_b := 0
            var mend_sum := 0
            var missing_sum := 0
            for s in SEEDS_B:
                var bseed: int = 920001 + arch * 613 + s * 104729
                var build := _build_archetype(arch, bseed)
                var damaged := _clone(build)
                var r0 := _fight(damaged, Challengers.make(ch[0]), false)
                if int(r0["result"]) != Combat.Result.WIN or _missing_hp(damaged) == 0:
                    continue
                used += 1
                missing_sum += _missing_hp(damaged)
                # arm A: shipped tailwind pre-mend on the collapsed lane
                var runA := RunState.new()
                runA.carried = _clone_hp(damaged)
                runA.map = runA._make_map(int(lane["t"]))
                runA.pos = int(lane["pos"])
                runA.choose(int(lane["lane"]))
                mend_sum += RunMods.pre_fight_mend(runA)
                var ndA: Dictionary = runA.node()
                var modA := String((ndA.get("modifier", {}) as Dictionary).get("id", ""))
                var ra := _fight(runA.carried, Challengers.make(ndA["challenger"], modA), true)
                if int(ra["result"]) == Combat.Result.WIN:
                    wins_a += 1
                # arm B: identical damaged state, no mend
                var meB := _clone_hp(damaged)
                var rb := _fight(meB, Challengers.make(ndA["challenger"], modA), true)
                if int(rb["result"]) == Combat.Result.WIN:
                    wins_b += 1
            tw_rows.append({
                "lane": String(lane["label"]), "build_tier": bt, "n_damaged_entrants": used,
                "win_rate_with_tailwind": _r(float(wins_a) / used) if used > 0 else 0.0,
                "win_rate_without": _r(float(wins_b) / used) if used > 0 else 0.0,
                "win_rate_delta": _r(float(wins_a - wins_b) / used) if used > 0 else 0.0,
                "mean_hp_mended": _r(float(mend_sum) / used) if used > 0 else 0.0,
                "mean_hp_missing_at_entry": _r(float(missing_sum) / used) if used > 0 else 0.0,
            })
    out["tailwind"] = {"design": "enter the boss lane damaged (unrepaired Rusty fight), shipped pre-mend vs none; under the repair-always policy tailwind mends 0 by construction", "rows": tw_rows}

    # second_wind: win the elite lane, shipped post-mend vs none, then the boss UNREPAIRED
    # (boss lane chosen as the template's non-tailwind lane so both arms face the same foe).
    var sw_rows: Array = []
    for L in lanes:
        var lane: Dictionary = L
        if String(lane["mod"]) != "second_wind":
            continue
        var t: int = int(lane["t"])
        var boss_lane := -1
        for L2 in lanes:
            var l2: Dictionary = L2
            if int(l2["t"]) == t and int(l2["pos"]) == 4 and String(l2["mod"]) != "tailwind":
                boss_lane = int(l2["lane"])
        for bt in ["mid", "strong"]:
            var arch: int = MID_ARCH if bt == "mid" else STRONG_ARCH
            var used := 0
            var boss_wins_a := 0
            var boss_wins_b := 0
            var mend_sum := 0
            var scrap_saved_sum := 0
            for s in SEEDS_B:
                var bseed: int = 930001 + arch * 613 + s * 104729
                var build := _build_archetype(arch, bseed)
                var run := RunState.new()
                run.carried = _clone(build)
                run.map = run._make_map(t)
                run.pos = int(lane["pos"])
                run.choose(int(lane["lane"]))
                var nd: Dictionary = run.node()
                var mod_id := String((nd.get("modifier", {}) as Dictionary).get("id", ""))
                var re := _fight(run.carried, Challengers.make(nd["challenger"], mod_id), true)
                if int(re["result"]) != Combat.Result.WIN:
                    continue
                used += 1
                var snap := _clone_hp(run.carried)          # arm B keeps the padless state
                mend_sum += RunMods.note_win(run)           # arm A: shipped second_wind core pad
                var cost_a := run.repair_cost()
                var runB := RunState.new()
                runB.carried = snap
                scrap_saved_sum += runB.repair_cost() - cost_a
                # both arms: press to the boss junction unrepaired, same lane, same foe
                run.pos = 4
                run.choose(boss_lane)
                RunMods.consume_core_pad(run)               # arm A: the pad lands at the boss bell
                var ndb: Dictionary = run.node()
                var bmod := String((ndb.get("modifier", {}) as Dictionary).get("id", ""))
                var ra2 := _fight(run.carried, Challengers.make(ndb["challenger"], bmod), true)
                if int(ra2["result"]) == Combat.Result.WIN:
                    boss_wins_a += 1
                var rb2 := _fight(snap, Challengers.make(ndb["challenger"], bmod), true)
                if int(rb2["result"]) == Combat.Result.WIN:
                    boss_wins_b += 1
            sw_rows.append({
                "lane": String(lane["label"]), "build_tier": bt, "n_elite_wins": used,
                "boss_win_rate_with_mend": _r(float(boss_wins_a) / used) if used > 0 else 0.0,
                "boss_win_rate_without": _r(float(boss_wins_b) / used) if used > 0 else 0.0,
                "boss_win_rate_delta": _r(float(boss_wins_a - boss_wins_b) / used) if used > 0 else 0.0,
                "mean_hp_mended": _r(float(mend_sum) / used) if used > 0 else 0.0,
                "mean_repair_scrap_saved": _r(float(scrap_saved_sum) / used) if used > 0 else 0.0,
            })
    out["second_wind"] = {"design": "win the second_wind elite, shipped post-mend vs none, then the same non-tailwind boss lane unrepaired; for a repairing player the whole value is the repair scrap saved", "rows": sw_rows}
    return out

func _junction_lanes() -> Array:
    var out: Array = []
    for t in RunState.TEMPLATES.size():
        var m: Array = RunState.new()._make_map(t)
        for p in m.size():
            var step: Dictionary = m[p]
            if String(step.get("type", "")) != "JUNCTION":
                continue
            var paths: Array = step["paths"]
            for li in paths.size():
                var ln: Dictionary = paths[li]
                var nd: Dictionary = ln["node"]
                out.append({
                    "t": t, "pos": p, "lane": li,
                    "mod": String((ln.get("modifier", {}) as Dictionary).get("id", "")),
                    "entry": nd["challenger"],
                    "label": "T%d %s %s (%s)" % [t, String(nd.get("tier", "")),
                        String(ln.get("lane_name", "")),
                        String((nd.get("challenger", {}) as Dictionary).get("name", "")).get_slice(",", 0)],
                })
    return out

# ============================ WAVE 3 G0 MODELS (venture-depth-wave3.md) ============================
# PREDICTIVE ONLY - the game code for events / the heap / the Gleaner's Due does not exist yet.
# These blocks model the ratified spec's exact tables and formulas offline so the
# post-implementation run can compare predicted vs actual. Nothing here touches game state.

const EVENT_SAMPLE_N := 60000      # pure-mix sample; even seeds = Template A (event), odd = B (heap)
                                   # sized so se < 0.7pp per event - a G4 breach here is hash bias, not noise
const W3_K_BOSS := 0.5             # Gleaner's Due K_tier (ASSUMED, G8)
const W3_K_ELITE := 0.25
const W3_WEAR_ORDER := ["ARM_R", "ARM_L", "LEGS", "BACK", "HEAD"]   # spec 2.4 fixed slot order
# spec 2.6 launch set: weight (COMMON 3 / UNCOMMON 2 / RARE 1, total 23), printed-odds threshold,
# and the three-verb effect payloads (mend / wear / next-foe-worn rider)
const W3_EVENTS := [
    {"id": "clockwork_wren", "w": 3, "thr": 67, "safe": {"mend": 2}, "good": {"mend": 4}, "bad": {"wear": 2}},
    {"id": "toll_doll", "w": 3, "thr": 67, "safe": {"rider": 1}, "good": {"rider": 2}, "bad": {"wear": 2}},
    {"id": "kettle_sprite", "w": 3, "thr": 67, "safe": {"mend": 3}, "good": {"mend": 5}, "bad": {"wear": 1}},
    {"id": "sleepy_signpost", "w": 3, "thr": 67, "safe": {"rider": 1}, "good": {"rider": 1, "mend": 3}, "bad": {"wear": 3}},
    {"id": "rain_soaked_coffer", "w": 3, "thr": 50, "safe": {"mend": 2}, "good": {"mend": 6}, "bad": {"wear": 4}},
    {"id": "moss_kept_milestone", "w": 2, "thr": 67, "safe": {"rider": 1}, "good": {"rider": 2, "mend": 2}, "bad": {"wear": 2}},
    {"id": "button_merchant", "w": 2, "thr": 67, "safe": {"mend": 2}, "good": {"rider": 2}, "bad": {}},
    {"id": "rust_rooks", "w": 2, "thr": 67, "safe": {"mend": 2}, "good": {"mend": 4}, "bad": {"wear": 2}},
    {"id": "gearwrights_ghost_light", "w": 1, "thr": 50, "safe": {"mend": 3}, "good": {"mend": 6}, "bad": {"wear": 4}},
    {"id": "barrow_wisp", "w": 1, "thr": 50, "safe": {"rider": 1}, "good": {"rider": 2, "mend": 3}, "bad": {"wear": 2}},
]

# splitmix64 finalizer masked to 63 bits - THE reference for the game's mix()/mix2().
# Crack-and-see parity law: the game implementation must reproduce these exact values so
# same box = same road = same shrine = same heap. mix2(seed) = mix(mix(seed)).
func _w3_ushr(z: int, n: int) -> int:
    return (z >> n) & ~((-1) << (64 - n))

func _w3_mix(x: int) -> int:
    var z: int = x + -0x61C8864680B583EB                 # 0x9E3779B97F4A7C15 as signed int64
    z = (z ^ _w3_ushr(z, 30)) * -0x40A7B892E31B1A47   # 0xBF58476D1CE4E5B9 as signed int64
    z = (z ^ _w3_ushr(z, 27)) * -0x6B2FB644ECCEEE15   # 0x94D049BB133111EB as signed int64
    z = z ^ _w3_ushr(z, 31)
    return z & 0x7FFFFFFFFFFFFFFF

@warning_ignore("integer_division")
func _w3_event_pick(map_seed: int) -> Dictionary:
    var h := _w3_mix(map_seed)
    var d2: int = h % 23
    var d3: int = (h / 100) % 100
    var acc := 0
    for ev in W3_EVENTS:
        var e: Dictionary = ev
        acc += int(e["w"])
        if d2 < acc:
            return {"event": e, "roll": d3}
    return {"event": W3_EVENTS[0], "roll": d3}

func _w3_heap_dig(map_seed: int) -> String:
    var g := _w3_mix(_w3_mix(map_seed))
    var r1: int = g % 100
    if r1 < 55:
        return "lend_common"
    if r1 < 85:
        return "filings"
    return "lend_rare"

func _w3_kept(s: int, k: float, h: float) -> int:
    return int(floor(float(s) * k * (0.5 + 0.5 * h)))

# spec 2.4 wear rail: total <= 4 HP, fixed slot order, floor 1 HP per bit, never CORE,
# never disables - events are never lethal by construction
func _w3_event_wear(m: ManabitState, total: int) -> void:
    var pool := total
    for slot in W3_WEAR_ORDER:
        if pool <= 0:
            return
        var pi: PartInstance = m.slots.get(slot)
        if pi == null or pi.disabled:
            continue
        var cut: int = mini(pool, pi.current_hp - 1)
        if cut <= 0:
            continue
        pi.current_hp -= cut
        pool -= cut

func _w3_pure_models() -> Dictionary:
    var per := {}
    for ev in W3_EVENTS:
        per[String((ev as Dictionary)["id"])] = {"n": 0, "push_good": 0}
    var n_event := 0
    var heap := {"lend_common": 0, "filings": 0, "lend_rare": 0}
    var n_heap := 0
    for i in EVENT_SAMPLE_N:
        if i % 2 == 0:
            var pick := _w3_event_pick(i)
            var e: Dictionary = pick["event"]
            var st: Dictionary = per[String(e["id"])]
            st["n"] = int(st["n"]) + 1
            if int(pick["roll"]) < int(e["thr"]):
                st["push_good"] = int(st["push_good"]) + 1
            n_event += 1
        else:
            var dig := _w3_heap_dig(i)
            heap[dig] = int(heap[dig]) + 1
            n_heap += 1
    var events_out := {}
    var g4_ok := true
    var g5_ok := true
    for ev2 in W3_EVENTS:
        var e2: Dictionary = ev2
        var st2: Dictionary = per[String(e2["id"])]
        var n: int = int(st2["n"])
        var share := float(n) / n_event
        var pg: float = (float(st2["push_good"]) / n) if n > 0 else 0.0
        if absf(pg - float(e2["thr"]) / 100.0) > 0.05:
            g4_ok = false
        if share < 0.03 or share > 0.20:
            g5_ok = false
        events_out[String(e2["id"])] = {"weight": int(e2["w"]), "n": n, "share": _r(share),
            "expected_share": _r(float(e2["w"]) / 23.0), "printed_odds": int(e2["thr"]),
            "push_good_rate": _r(pg)}
    var heap_out := {}
    for k in heap.keys():
        heap_out[k] = {"n": int(heap[k]), "share": _r(float(heap[k]) / n_heap)}
    var canon_ok: bool = _w3_kept(35, W3_K_BOSS, 1.0) == 17 and _w3_kept(35, W3_K_ELITE, 1.0) == 8 \
        and _w3_kept(35, W3_K_BOSS, 0.0) == 8 and _w3_kept(35, W3_K_ELITE, 0.0) == 4
    var sweep_violations := 0
    for s in 76:
        for hh in [0.0, 0.5, 1.0]:
            if _w3_kept(s, W3_K_BOSS, float(hh)) > int(floor(float(s) / 2.0)):
                sweep_violations += 1
    return {
        "mix_reference": "splitmix64 finalizer masked to 63 bits; d2 = h mod 23, d3 = (h div 100) mod 100; mix2(seed) = mix(mix(seed))",
        "sample_n_event_roads": n_event,
        "sample_n_heap_roads": n_heap,
        "event_model": events_out,
        "g4_printed_odds_within_5pp": g4_ok,
        "g5_every_event_3_to_20_pct": g5_ok,
        "heap_model": heap_out,
        "gleaners_canon_ok": canon_ok,
        "gleaners_sting_sweep_violations": sweep_violations,
    }

# One Template A road walk with a shrine effect applied ON DEPARTURE from the pos1 rest
# (after the bench repairs - the spec's teeth ruling). Repair-always, press-on policy.
func _w3_event_walk(build: ManabitState, el: int, bl: int, eff: Dictionary) -> Dictionary:
    var run := RunState.new()
    run.carried = _clone(build)
    run.map = run._make_map(0)         # abs(0) % 2 = 0 -> Template A, the event road
    run.pos = 0
    var rider: int = int(eff.get("rider", 0))
    var out := {"node0_win": 0, "elite_win": 0, "elite_death": 0, "boss_death": 0, "clear": 0}
    while not run.over:
        var nd: Dictionary = run.node()
        var ntype := String(nd.get("type", ""))
        if ntype == "REST":
            run.repair_all()
            if run.pos == 1 and not eff.is_empty():
                RunMods._mend(run.carried, int(eff.get("mend", 0)))
                _w3_event_wear(run.carried, int(eff.get("wear", 0)))
            run.advance()
            continue
        if ntype == "JUNCTION":
            run.choose(el if run.pos == 2 else bl)
            continue
        RunMods.pre_fight_mend(run)
        RunMods.consume_core_pad(run)      # shipped D12 rule: the pad lands at the next bell
        var nd2: Dictionary = run.node()
        var mod_id := String((nd2.get("modifier", {}) as Dictionary).get("id", ""))
        var tier := String(nd2.get("tier", ""))
        # MAX-NOT-SUM vs the lane modifier now lives in the SHIPPED Challengers.make rider path
        var bell_rider: int = rider if tier == "elite" else 0
        if bell_rider > 0:
            rider = 0                   # consumed at the bell, one fight only
        var foe: ManabitState = Challengers.make(nd2["challenger"], mod_id, bell_rider)
        var r := _fight(run.carried, foe, bool(nd2.get("aims_core", false)))
        var res: int = int(r["result"])
        if res == Combat.Result.WIN:
            if tier == "skirmish":
                out["node0_win"] = 1
            elif tier == "elite":
                out["elite_win"] = 1
            RunMods.note_win(run)
            run.advance()
        elif res == Combat.Result.DEATH:
            if tier == "elite":
                out["elite_death"] = 1
            elif tier == "boss":
                out["boss_death"] = 1
            return out
        else:
            var fslot := _forfeit_pick(run.carried)
            if fslot != "":
                run.carried.slots[fslot] = null
            run.advance()
    out["clear"] = 1
    return out

# Paired event-road experiment: same build + lanes, three arms (no shrine / safe-always /
# push-always). Predicts G1 (clear drop <= 5pp), G2 (elite-death delta <= +3pp) and G3
# (rider-carrying elite win <= node0 win).
func _run_event_roads() -> Dictionary:
    var per_event := {}
    for ev in W3_EVENTS:
        per_event[String((ev as Dictionary)["id"])] = {"n": 0, "push_good": 0}
    var rows: Array = []
    for bt in ["mid", "strong"]:
        var arch: int = MID_ARCH if bt == "mid" else STRONG_ARCH
        var n := 0
        var acc := {}
        for arm in ["base", "safe", "push"]:
            acc[arm] = {"node0_win": 0, "elite_win": 0, "elite_death": 0, "boss_death": 0, "clear": 0}
        var rider_n := 0
        var rider_elite_win := 0
        for el in 2:
            for bl in 2:
                for s in SEEDS_B:
                    var bseed: int = 810001 + arch * 613 + s * 104729
                    var build := _build_archetype(arch, bseed)
                    var mseed: int = bseed * 4 + el * 2 + bl   # stand-in for the run's map randi()
                    var pick := _w3_event_pick(mseed)
                    var e: Dictionary = pick["event"]
                    var good: bool = int(pick["roll"]) < int(e["thr"])
                    var st: Dictionary = per_event[String(e["id"])]
                    st["n"] = int(st["n"]) + 1
                    if good:
                        st["push_good"] = int(st["push_good"]) + 1
                    var effs := {"base": {}, "safe": e["safe"] as Dictionary,
                        "push": (e["good"] as Dictionary) if good else (e["bad"] as Dictionary)}
                    n += 1
                    for arm in ["base", "safe", "push"]:
                        var eff: Dictionary = effs[arm]
                        var r := _w3_event_walk(build, el, bl, eff)
                        var a: Dictionary = acc[arm]
                        for k in a.keys():
                            a[k] = int(a[k]) + int(r[k])
                        if arm != "base" and int(eff.get("rider", 0)) > 0:
                            rider_n += 1
                            rider_elite_win += int(r["elite_win"])
        var base: Dictionary = acc["base"]
        var safe: Dictionary = acc["safe"]
        var push: Dictionary = acc["push"]
        var node0_rate := float(base["node0_win"]) / n
        var rider_rate: float = (float(rider_elite_win) / rider_n) if rider_n > 0 else 0.0
        rows.append({
            "build_tier": bt, "n_per_arm": n,
            "clear_rate_base": _r(float(base["clear"]) / n),
            "clear_rate_safe": _r(float(safe["clear"]) / n),
            "clear_rate_push": _r(float(push["clear"]) / n),
            "clear_delta_push_vs_base": _r(float(int(push["clear"]) - int(base["clear"])) / n),
            "elite_death_base": _r(float(base["elite_death"]) / n),
            "elite_death_safe": _r(float(safe["elite_death"]) / n),
            "elite_death_push": _r(float(push["elite_death"]) / n),
            "elite_death_delta_push_vs_base": _r(float(int(push["elite_death"]) - int(base["elite_death"])) / n),
            "elite_win_base": _r(float(base["elite_win"]) / n),
            "rider_carrying_elite_win": _r(rider_rate),
            "node0_win_rate": _r(node0_rate),
            "g3_rider_not_cozier_than_node0": rider_rate <= node0_rate,
        })
    var per_out := {}
    for k in per_event.keys():
        var st2: Dictionary = per_event[k]
        var en: int = int(st2["n"])
        per_out[k] = {"n": en, "push_good_realized": _r((float(st2["push_good"]) / en)) if en > 0 else 0.0}
    return {
        "design": "Template A paired walk, arms: no shrine vs safe-always vs push-always; shrine resolves on departure AFTER the pos1 repair, wear rides into the elite; rider is MAX-NOT-SUM vs the lane modifier and consumed at one bell",
        "rows": rows,
        "per_event_trace_tally": per_out,
    }

# D12 re-time candidates for the dead tailwind / second_wind rules (+0.0pp measured).
# Candidate A (plain re-timed mend at the bell) is STRUCTURALLY 0 under repair-always -
# a full-HP box mends 0 - so it is reported analytically, not fought. Candidate B reads the
# card's "mended N before the bell" as N instance-local core HP at the bell (the only mend
# that can matter in a core-race meta). Gate: paired-seed delta in [+2pp, +12pp], never negative.
func _run_d12_retime() -> Dictionary:
    var lanes := _junction_lanes()
    var tw_rows: Array = []
    var sw_rows: Array = []
    for L in lanes:
        var lane: Dictionary = L
        if String(lane["mod"]) == "tailwind":
            for bt in ["mid", "strong"]:
                var arch: int = MID_ARCH if bt == "mid" else STRONG_ARCH
                var wins_pad := 0
                var wins_clean := 0
                for s in SEEDS_B:
                    var bseed: int = 950001 + arch * 613 + s * 104729
                    var build := _build_archetype(arch, bseed)
                    var me_pad := _clone(build)
                    var cpi: PartInstance = me_pad.slots.get("CORE")
                    if cpi != null:
                        cpi.current_hp += RunMods.MEND_PRE   # instance-local pad, PartData untouched
                    var rp := _fight(me_pad, Challengers.make(lane["entry"], ""), true)
                    var rc := _fight(_clone(build), Challengers.make(lane["entry"], ""), true)
                    if int(rp["result"]) == Combat.Result.WIN:
                        wins_pad += 1
                    if int(rc["result"]) == Combat.Result.WIN:
                        wins_clean += 1
                var delta := _r(float(wins_pad - wins_clean) / SEEDS_B)
                tw_rows.append({"lane": String(lane["label"]), "build_tier": bt, "n": SEEDS_B,
                    "win_rate_with_pad": _r(float(wins_pad) / SEEDS_B),
                    "win_rate_clean": _r(float(wins_clean) / SEEDS_B),
                    "win_rate_delta": delta,
                    "in_gate_band_2_to_12pp": delta >= 0.02 and delta <= 0.12})
        elif String(lane["mod"]) == "second_wind":
            var t: int = int(lane["t"])
            var boss_lane := -1
            for L2 in lanes:
                var l2: Dictionary = L2
                if int(l2["t"]) == t and int(l2["pos"]) == 4 and String(l2["mod"]) != "tailwind":
                    boss_lane = int(l2["lane"])
            for bt in ["mid", "strong"]:
                var arch: int = MID_ARCH if bt == "mid" else STRONG_ARCH
                var used := 0
                var wins_pad := 0
                var wins_clean := 0
                for s in SEEDS_B:
                    var bseed: int = 960001 + arch * 613 + s * 104729
                    var build := _build_archetype(arch, bseed)
                    var run := RunState.new()
                    run.carried = _clone(build)
                    run.map = run._make_map(t)
                    run.pos = 2
                    run.choose(int(lane["lane"]))
                    var nd: Dictionary = run.node()
                    var mod_id := String((nd.get("modifier", {}) as Dictionary).get("id", ""))
                    var re := _fight(run.carried, Challengers.make(nd["challenger"], mod_id), true)
                    if int(re["result"]) != Combat.Result.WIN:
                        continue
                    used += 1
                    run.repair_all()                     # repair-always: The Last Lantern mends all
                    run.pos = 4
                    run.choose(boss_lane)
                    var ndb: Dictionary = run.node()
                    var bmod := String((ndb.get("modifier", {}) as Dictionary).get("id", ""))
                    var me_pad := _clone_hp(run.carried)
                    var cpi2: PartInstance = me_pad.slots.get("CORE")
                    if cpi2 != null:
                        cpi2.current_hp += RunMods.MEND_POST
                    var rp2 := _fight(me_pad, Challengers.make(ndb["challenger"], bmod), true)
                    var rc2 := _fight(_clone_hp(run.carried), Challengers.make(ndb["challenger"], bmod), true)
                    if int(rp2["result"]) == Combat.Result.WIN:
                        wins_pad += 1
                    if int(rc2["result"]) == Combat.Result.WIN:
                        wins_clean += 1
                var delta2: float = _r(float(wins_pad - wins_clean) / used) if used > 0 else 0.0
                sw_rows.append({"lane": String(lane["label"]), "build_tier": bt, "n_elite_wins": used,
                    "boss_win_rate_with_pad": _r(float(wins_pad) / used) if used > 0 else 0.0,
                    "boss_win_rate_clean": _r(float(wins_clean) / used) if used > 0 else 0.0,
                    "boss_win_rate_delta": delta2,
                    "in_gate_band_2_to_12pp": delta2 >= 0.02 and delta2 <= 0.12})
    return {
        "design": "candidate B core-pad reading: tailwind = +4 core HP at the modified boss lane's bell; second_wind = win the elite on the lane, carry +3 core HP into the boss bell (after a full repair, the repair-always reality)",
        "candidate_a_retimed_mend": {"win_rate_delta": 0.0,
            "note": "a plain mend re-timed to the bell is 0 by arithmetic after a full repair - re-timing alone cannot revive the rule (matches the measured +0.0pp cells)"},
        "tailwind_core_pad": tw_rows,
        "second_wind_core_pad": sw_rows,
    }

func _run_wave3() -> Dictionary:
    return {
        "spec": "design/economy/venture-depth-wave3.md",
        "predictive_note": "no game code for wave 3 exists yet - every number here is the sim modeling the spec's ASSUMED values offline; the post-implementation run compares predicted vs actual",
        "pure_models": _w3_pure_models(),
        "event_road_experiment": _run_event_roads(),
        "d12_retime_candidates": _run_d12_retime(),
    }

func _print_wave3(wave3: Dictionary, part_b: Dictionary) -> void:
    print("==================== WAVE 3 G0 (PREDICTIVE) ====================")
    var pure: Dictionary = wave3["pure_models"]
    print("  mix: G4 printed-odds within 5pp = %s   G5 shares 3-20pct = %s   (n=%d event roads)" % [
        "YES" if bool(pure["g4_printed_odds_within_5pp"]) else "NO",
        "YES" if bool(pure["g5_every_event_3_to_20_pct"]) else "NO",
        int(pure["sample_n_event_roads"])])
    var hm: Dictionary = pure["heap_model"]
    print("  heap dig shares: lend_common %.3f  filings %.3f  lend_rare %.3f (spec 0.55/0.30/0.15)" % [
        float((hm["lend_common"] as Dictionary)["share"]), float((hm["filings"] as Dictionary)["share"]),
        float((hm["lend_rare"] as Dictionary)["share"])])
    print("  gleaners canon ok = %s   sting sweep violations = %d" % [
        "YES" if bool(pure["gleaners_canon_ok"]) else "NO", int(pure["gleaners_sting_sweep_violations"])])
    var roads: Dictionary = wave3["event_road_experiment"]
    for row in roads["rows"]:
        var rr: Dictionary = row
        print("  event road %-6s clear base/safe/push %.3f/%.3f/%.3f  eliteDeath dPush %+.3f  rider elite win %.3f vs node0 %.3f" % [
            String(rr["build_tier"]), float(rr["clear_rate_base"]), float(rr["clear_rate_safe"]),
            float(rr["clear_rate_push"]), float(rr["elite_death_delta_push_vs_base"]),
            float(rr["rider_carrying_elite_win"]), float(rr["node0_win_rate"])])
    var d12: Dictionary = wave3["d12_retime_candidates"]
    for row2 in d12["tailwind_core_pad"]:
        var tr: Dictionary = row2
        print("  D12 tailwind pad  %-44s %-6s dWin %+.3f  band[2-12pp]=%s" % [
            String(tr["lane"]).left(44), String(tr["build_tier"]), float(tr["win_rate_delta"]),
            "YES" if bool(tr["in_gate_band_2_to_12pp"]) else "NO"])
    for row3 in d12["second_wind_core_pad"]:
        var sr: Dictionary = row3
        print("  D12 2nd-wind pad  %-44s %-6s dBossWin %+.3f  band[2-12pp]=%s (n=%d)" % [
            String(sr["lane"]).left(44), String(sr["build_tier"]), float(sr["boss_win_rate_delta"]),
            "YES" if bool(sr["in_gate_band_2_to_12pp"]) else "NO", int(sr["n_elite_wins"])])
    var tt: Dictionary = part_b["by_tier_template"]
    var tks: Array = tt.keys()
    tks.sort()
    for tk in tks:
        var tv: Dictionary = tt[tk]
        print("  own %-10s safe-end %.3f  wreck/run %.1f  net+wreck %+.1f" % [
            String(tk), float(tv["safe_end_rate"]), float(tv["own_wreck_mean_per_run"]),
            float(tv["mean_net_scrap_with_gleaners_wreck"])])

# ================================ BUILD GENERATORS ================================

func _build_archetype(idx: int, sd: int) -> ManabitState:
    var rng := RandomNumberGenerator.new()
    rng.seed = sd
    var m := ManabitState.new()
    for s in ManabitState.SLOT_NAMES:
        m.slots[s] = null
    match idx:
        0:
            _seat_core(m, "COMMON", rng)
            _fill_pref(m, "ARM_R", [["COMMON"]], true, rng)
            _fill_pref(m, "LEGS", [["COMMON"]], false, rng)
        1:
            _seat_core(m, "COMMON", rng)
            _fill_pref(m, "ARM_R", [["COMMON"]], true, rng)
            _fill_pref(m, "LEGS", [["COMMON"]], false, rng)
            _fill_pref(m, "HEAD", [["COMMON"]], false, rng)
            _fill_pref(m, "ARM_L", [["COMMON"]], false, rng)
        2:
            _seat_core(m, "COMMON", rng)
            _fill_pref(m, "ARM_R", [["COMMON", "RARE"]], true, rng)
            _fill_pref(m, "LEGS", [["COMMON", "RARE"]], false, rng)
            _fill_pref(m, "HEAD", [["COMMON", "RARE"]], false, rng)
            _fill_pref(m, "ARM_L", [["COMMON", "RARE"]], false, rng)
            _fill_pref(m, "BACK", [["COMMON", "RARE"]], false, rng)
        3:
            _seat_core(m, "RARE", rng)
            _fill_pref(m, "ARM_R", [["RARE"], ["COMMON"]], true, rng)
            _fill_pref(m, "LEGS", [["RARE"], ["COMMON"]], false, rng)
            _fill_pref(m, "HEAD", [["RARE"], ["COMMON"]], false, rng)
            _fill_pref(m, "ARM_L", [["RARE"], ["COMMON"]], false, rng)
            _fill_pref(m, "BACK", [["RARE"], ["COMMON"]], false, rng)
        4:
            _seat_core(m, "RARE", rng)
            _seat_centerpiece(m, rng)
            _fill_pref(m, "LEGS", [["RARE"], ["COMMON"]], false, rng)
            _fill_pref(m, "HEAD", [["RARE"], ["COMMON"]], false, rng)
            _fill_pref(m, "ARM_L", [["RARE"], ["COMMON"]], false, rng)
            _fill_pref(m, "BACK", [["RARE"], ["COMMON"]], false, rng)
        _:
            _seat_core(m, "EPIC", rng)
            _seat_centerpiece(m, rng)
            _fill_pref(m, "LEGS", [["EPIC"], ["RARE"], ["COMMON"]], false, rng)
            _fill_pref(m, "HEAD", [["EPIC"], ["RARE"], ["COMMON"]], false, rng)
            _fill_pref(m, "ARM_L", [["EPIC"], ["RARE"], ["COMMON"]], false, rng)
            _fill_pref(m, "BACK", [["EPIC"], ["RARE"], ["COMMON"]], false, rng)
    if not m.has_offensive_move():
        # safety valve: the lightest COMMON weapon arm (weefist-class) always fits
        var pool := _pool("ARM_R", ["COMMON"], true)
        var best: PartData = null
        for pd in pool:
            var p: PartData = pd
            if best == null or p.weight < best.weight:
                best = p
        if best != null:
            m.slots["ARM_R"] = PartInstance.new(best)
    return m

func _seat_core(m: ManabitState, rarity: String, rng: RandomNumberGenerator) -> void:
    var pool: Array = []
    for pd in Catalog.cores():
        var p: PartData = pd
        if String(p.rarity) == rarity:
            pool.append(p)
    m.slots["CORE"] = PartInstance.new(pool[rng.randi_range(0, pool.size() - 1)])

func _seat_centerpiece(m: ManabitState, rng: RandomNumberGenerator) -> void:
    for rr in ["EPIC", "RARE", "COMMON"]:
        var pool: Array = []
        for pd in _pool("ARM_R", [rr], true):
            var p: PartData = pd
            if p.weight <= _budget_left(m):
                pool.append(p)
        if pool.is_empty():
            continue
        var maxp := 0
        for pd2 in pool:
            var p2: PartData = pd2
            maxp = maxi(maxp, p2.ability.power)
        var top: Array = []
        for pd3 in pool:
            var p3: PartData = pd3
            if p3.ability.power >= maxp - 1:
                top.append(p3)
        m.slots["ARM_R"] = PartInstance.new(top[rng.randi_range(0, top.size() - 1)])
        return

func _fill_pref(m: ManabitState, slot: String, tiers: Array, offensive: bool, rng: RandomNumberGenerator) -> void:
    for tier in tiers:
        var pool: Array = []
        for pd in _pool(slot, tier, offensive):
            var p: PartData = pd
            if p.weight <= _budget_left(m):
                pool.append(p)
        if pool.is_empty():
            continue
        m.slots[slot] = PartInstance.new(pool[rng.randi_range(0, pool.size() - 1)])
        return

func _pool(slot: String, rarities: Array, offensive_only: bool) -> Array:
    var out: Array = []
    for pd in Catalog.body_pool():
        var p: PartData = pd
        if not _fits(slot, p):
            continue
        if not rarities.has(String(p.rarity)):
            continue
        if offensive_only and not _is_offensive(p):
            continue
        out.append(p)
    return out

func _fits(slot: String, pd: PartData) -> bool:
    if slot == "ARM_L" or slot == "ARM_R":
        return pd.slot == "ARM_L" or pd.slot == "ARM_R"
    return pd.slot == slot

func _is_offensive(pd: PartData) -> bool:
    return pd.ability != null and pd.ability.archetype != "GUARD"

func _budget_left(m: ManabitState) -> int:
    var d: Dictionary = m.derived()
    return int(d["capacity"]) - int(d["weight"])

# ================================ FIGHT + SMALL HELPERS ================================

func _fight(me: ManabitState, foe: ManabitState, foe_aims_core: bool) -> Dictionary:
    var c := Combat.new()
    c.start(me, foe, foe_aims_core)
    var guard := 0
    while c.outcome() == Combat.Result.ONGOING and guard < TURN_CAP:
        var actor: ManabitState = c.current()
        if actor == me:
            c.ai_take_turn(me, foe)
        else:
            c.ai_take_turn(foe, me)
        if c.outcome() == Combat.Result.ONGOING:
            c.advance_turn()
        guard += 1
    var res: int = c.outcome()
    var broken := 0
    for slot in ManabitState.SLOT_NAMES:
        if slot == "CORE":
            continue
        var pi: PartInstance = me.slots.get(slot)
        if pi != null and pi.disabled:
            broken += 1
    return {"result": res, "turns": guard, "broken": broken, "stalled": res == Combat.Result.ONGOING}

func _clone(src: ManabitState) -> ManabitState:
    var m := ManabitState.new()
    for slot in ManabitState.SLOT_NAMES:
        var pi: PartInstance = src.slots.get(slot)
        m.slots[slot] = PartInstance.new(pi.data) if pi != null else null
    return m

func _clone_hp(src: ManabitState) -> ManabitState:
    var m := ManabitState.new()
    for slot in ManabitState.SLOT_NAMES:
        var pi: PartInstance = src.slots.get(slot)
        if pi == null:
            m.slots[slot] = null
        else:
            var np := PartInstance.new(pi.data)
            np.current_hp = pi.current_hp
            np.disabled = pi.disabled
            m.slots[slot] = np
    return m

func _missing_hp(m: ManabitState) -> int:
    var miss := 0
    for slot in ManabitState.SLOT_NAMES:
        var pi: PartInstance = m.slots.get(slot)
        if pi != null:
            miss += pi.data.max_hp - pi.current_hp
    return miss

func _best_loot(foe: ManabitState) -> PartData:
    var best: PartData = null
    for slot in ManabitState.SLOT_NAMES:
        if slot == "CORE":
            continue
        var pi: PartInstance = foe.slots.get(slot)
        if pi == null or pi.data.is_core:
            continue
        if best == null or Broker.salvage_scrap(pi.data) > Broker.salvage_scrap(best):
            best = pi.data
    return best

func _forfeit_pick(m: ManabitState) -> String:
    var best_slot := ""
    var best_val := 1 << 30
    for slot in ManabitState.SLOT_NAMES:
        if slot == "CORE":
            continue
        var pi: PartInstance = m.slots.get(slot)
        if pi != null and pi.disabled and Broker.salvage_scrap(pi.data) < best_val:
            best_val = Broker.salvage_scrap(pi.data)
            best_slot = slot
    return best_slot

func _build_ids(m: ManabitState) -> Array:
    var out: Array = []
    for slot in ManabitState.SLOT_NAMES:
        var pi: PartInstance = m.slots.get(slot)
        if pi != null:
            out.append("%s:%s" % [slot, String(pi.data.id)])
    return out

func _acc() -> Dictionary:
    return {"n": 0, "win": 0, "sl": 0, "death": 0, "stall": 0, "turns": 0, "broken": 0}

func _acc_add(acc: Dictionary, r: Dictionary) -> void:
    acc["n"] = int(acc["n"]) + 1
    acc["turns"] = int(acc["turns"]) + int(r["turns"])
    acc["broken"] = int(acc["broken"]) + int(r["broken"])
    var res: int = int(r["result"])
    if res == Combat.Result.WIN:
        acc["win"] = int(acc["win"]) + 1
    elif res == Combat.Result.DEATH:
        acc["death"] = int(acc["death"]) + 1
    elif res == Combat.Result.SURVIVABLE_LOSS:
        acc["sl"] = int(acc["sl"]) + 1
    else:
        acc["stall"] = int(acc["stall"]) + 1

func _acc_out(acc: Dictionary) -> Dictionary:
    var n: int = int(acc["n"])
    if n == 0:
        return {}
    return {
        "n": n,
        "win_rate": _r(float(acc["win"]) / n),
        "survivable_loss_rate": _r(float(acc["sl"]) / n),
        "death_rate": _r(float(acc["death"]) / n),
        "stall_rate": _r(float(acc["stall"]) / n),
        "mean_actor_turns": _r(float(acc["turns"]) / n),
        "mean_parts_broken": _r(float(acc["broken"]) / n),
    }

func _r(v: float) -> float:
    return snappedf(v, 0.001)

# ================================ SUMMARY ================================

func _headline(part_a: Dictionary, part_b: Dictionary, mods: Dictionary) -> Dictionary:
    var order: Array = part_a["ladder_softest_to_cruelest"]
    var soft: Dictionary = order[0]
    var cruel: Dictionary = order[order.size() - 1]
    var gaps: Array = part_a["rung_gaps"]
    var big: Dictionary = gaps[0]
    for g in gaps:
        if float((g as Dictionary)["win_rate_drop"]) > float(big["win_rate_drop"]):
            big = g
    var configs: Array = part_b["configs"]
    var best: Dictionary = configs[0]
    var worst: Dictionary = configs[0]
    for c in configs:
        var cc: Dictionary = c
        if float(cc["survival_rate"]) > float(best["survival_rate"]):
            best = cc
        if float(cc["survival_rate"]) < float(worst["survival_rate"]):
            worst = cc
    return {
        "softest_rung": {"name": String(soft["name"]), "win_rate": float(soft["win_rate"])},
        "cruelest_rung": {"name": String(cruel["name"]), "win_rate": float(cruel["win_rate"])},
        "biggest_rung_gap": big,
        "best_venture_config": {"build": String(best["build_tier"]), "template": String(best["template_name"]),
            "elite": String(best["elite_lane"]), "boss": String(best["boss_lane"]),
            "survival_rate": float(best["survival_rate"])},
        "worst_venture_config": {"build": String(worst["build_tier"]), "template": String(worst["template_name"]),
            "elite": String(worst["elite_lane"]), "boss": String(worst["boss_lane"]),
            "survival_rate": float(worst["survival_rate"])},
    }

func _print_summary(part_a: Dictionary, part_b: Dictionary, mods: Dictionary) -> void:
    print("==================== LADDER SUMMARY ====================")
    var order: Array = part_a["ladder_softest_to_cruelest"]
    for i in order.size():
        var o: Dictionary = order[i]
        var gap := ""
        if i > 0:
            var prev: Dictionary = order[i - 1]
            gap = "  (drop %.3f)" % (float(prev["win_rate"]) - float(o["win_rate"]))
        print("  %d. %-40s %-8s win %.3f%s" % [i + 1, String(o["name"]).left(40), String(o["tier"]), float(o["win_rate"]), gap])
    var mc: Dictionary = part_a["monotonic_checks"]
    print("  checks: rusty softest=%s  regulars 0>=1>=2=%s  regulars>elites=%s  elites>bosses=%s" % [
        _yn(mc["rusty_is_softest"]), _yn(mc["regulars_in_order_0_1_2"]),
        _yn(mc["every_regular_softer_than_every_elite"]), _yn(mc["every_elite_softer_than_every_boss"])])
    print("  tier gaps: regular->elite %.3f   elite->boss %.3f" % [
        float(mc["regular_to_elite_gap"]), float(mc["elite_to_boss_gap"])])
    print("==================== VENTURE SUMMARY ====================")
    var by: Dictionary = part_b["by_build_tier"]
    for bt in ["mid", "strong"]:
        var a: Dictionary = by[bt]
        print("  %-6s survive %.3f  death@elite %.3f  death@boss %.3f  net scrap %+.1f  loot melt %.1f  bits lost %.2f" % [
            bt, float(a["survival_rate"]), float(a["death_rate_elite"]), float(a["death_rate_boss"]),
            float(a["mean_net_scrap_purse_plus_salvage_minus_repairs"]),
            float(a["mean_loot_melt_value_scrap"]), float(a["mean_bits_lost"])])
        print("         death-ahead pressing from rest1 %.3f / rest2 %.3f   repairs %.1f scrap/run" % [
            float(a["death_ahead_if_pressing_from_rest1"]), float(a["death_ahead_if_pressing_from_rest2"]),
            float(a["mean_repairs_paid_scrap"])])
    print("  lanes (observational, within the walked roads):")
    var lanes: Dictionary = part_b["lane_observational"]
    var keys: Array = lanes.keys()
    keys.sort()
    for k in keys:
        var st: Dictionary = lanes[k]
        print("    %-58s win %.3f  death %.3f  (n=%d)" % [String(k).left(58), float(st["win_rate"]), float(st["death_rate"]), int(st["n_fought"])])
    print("==================== MODIFIER EFFECTS (controlled) ====================")
    for mod in ["rusted", "overgrown", "tailwind", "second_wind"]:
        var blk: Dictionary = mods[mod]
        print("  %s:" % mod)
        for row in blk["rows"]:
            var rr: Dictionary = row
            if mod == "tailwind":
                print("    %-44s %-6s dWin %+.3f (with %.3f vs %.3f, mend %.1f HP, dmg-in %.1f, n=%d)" % [
                    String(rr["lane"]).left(44), String(rr["build_tier"]), float(rr["win_rate_delta"]),
                    float(rr["win_rate_with_tailwind"]), float(rr["win_rate_without"]),
                    float(rr["mean_hp_mended"]), float(rr["mean_hp_missing_at_entry"]), int(rr["n_damaged_entrants"])])
            elif mod == "second_wind":
                print("    %-44s %-6s dBossWin %+.3f (mend %.1f HP, repair scrap saved %.1f, n=%d)" % [
                    String(rr["lane"]).left(44), String(rr["build_tier"]), float(rr["boss_win_rate_delta"]),
                    float(rr["mean_hp_mended"]), float(rr["mean_repair_scrap_saved"]), int(rr["n_elite_wins"])])
            else:
                print("    %-44s %-6s dWin %+.3f (with %.3f vs clean %.3f)" % [
                    String(rr["lane"]).left(44), String(rr["build_tier"]), float(rr["win_rate_delta"]),
                    float(rr["win_rate_with_mod"]), float(rr["win_rate_clean"])])

func _yn(v) -> String:
    return "YES" if float(v) > 0.5 else "NO"
