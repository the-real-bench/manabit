extends SceneTree
# ROSTER SIM - measures the REAL combat value of every catalog bit (systems-design + QA lane).
# Method: 5 canonical archetype templates (budget-legal per derived() weight rules, built from
# widely-available COMMON bits). Every catalog bit is swapped into the one slot it fits on every
# template it is not already part of; the modified template then fights the other 4 templates
# across N_SEEDS seeded opponent variants (alternating which side is the Combat "player" so the
# role asymmetries in ai_take_turn/outcome cancel), and the win-rate delta vs that template's
# own baseline is recorded. Also produces a per-family aggregate win matrix from greedy
# budget-legal family signature builds, and the intransitive pentagon check over
# boldheart / grumble_co / whirligig / thicket_fang / silksteel.
# NOTE on seeds: combat/combat.gd resolution is fully deterministic, so all run-to-run variation
# comes from explicitly seeded RandomNumberGenerator draws that vary the OPPONENT loadout
# (per-slot jitter from a pool of widely-available commons) plus role alternation by seed parity.
# The same seeded opponent variant is used for the baseline and for every candidate at that seed,
# so deltas are apples-to-apples. Read-only on game state: fresh ManabitState instances per
# fight, no user:// access, no save writes.
# Output: res://tools/sim/out/roster.json + a printed human summary.
# Run:
#   & "G:\Godot\Godot_v4.7-stable_win64_console.exe" --headless --path G:\ClaudeApps\manabit -s "res://tools/sim/sim_roster.gd"

const N_SEEDS := 30
const TURN_CAP := 100
const JITTER_RATE := 0.35
const RNG_BASE := 424243
const OUT_DIR := "res://tools/sim/out"
const OUT_PATH := "res://tools/sim/out/roster.json"
const RARITY_RANK := {"COMMON": 0, "RARE": 1, "EPIC": 2}
const PENTAGON := ["boldheart", "grumble_co", "whirligig", "thicket_fang", "silksteel"]

# --- ROSTER v2 instrument additions (QA-ordered, wave 1 change order section D) ---
# All ADDITIVE: the v1 measurement paths above keep their exact seeds and AI so pre/post
# deltas stay apples-to-apples. v2 adds a core-aiming + GUARD-when-behind player policy
# lens, per-pair stall counts, a 200-seed pentagon pass, and a cross-family
# greatest-hits build row.
const PENT_V2_SEEDS := 200
const GREATEST_HITS := {"HEAD": "sovereign_brass_head_herald", "CORE": "sovereign_brass_core_regalia",
    "ARM_L": "grumble_co_girder_fist", "ARM_R": "sovereign_brass_arm_pistonfist",
    "LEGS": "cobble_sons_legs_bedrock"}

# 5 canonical archetype templates - all COMMON, all budget-legal (weight <= capacity, asserted).
const TEMPLATES := [
    {"name": "Nuke", "ids": {"HEAD": "everykit_standard_cowl", "CORE": "core_ember",
        "ARM_L": "grumble_co_girder_fist", "ARM_R": "thicket_fang_arm_gnashmaw",
        "LEGS": "pocketful_legs_stubby", "BACK": "boldheart_back_rocketspine"}},
    {"name": "Wall", "ids": {"HEAD": "grumble_co_anvil_cowl", "CORE": "core_bulwark",
        "ARM_L": "errant_arm_warder", "ARM_R": "cobble_sons_arm_ratchet",
        "LEGS": "tinbox_legs_trusty", "BACK": "grumble_co_furnace_pack"}},
    {"name": "Tempo", "ids": {"HEAD": "whirligig_head_windshear", "CORE": "whirligig_core_quickstart",
        "ARM_L": "pocketful_arm_weefist", "ARM_R": "quivergear_salvo_fist",
        "LEGS": "silksteel_legs_slip", "BACK": "whirligig_back_slipfin"}},
    {"name": "Swarm", "ids": {"HEAD": "chatterbox_prattle_dome", "CORE": "core_font",
        "ARM_L": "thicket_fang_arm_rendclaw", "ARM_R": "quivergear_salvo_fist",
        "LEGS": "thicket_fang_legs_haunch", "BACK": "quivergear_volley_pod"}},
    {"name": "Sniper", "ids": {"HEAD": "silksteel_head_gauze", "CORE": "core_font",
        "ARM_L": "pocketful_arm_weefist", "ARM_R": "silksteel_arm_needle",
        "LEGS": "silksteel_legs_slip", "BACK": "chatterbox_notion_pack"}},
]

# Seeded opponent jitter pools - widely-available commons per slot. CORE is never jittered so
# capacity (and therefore budget legality) of the opponent frame stays stable.
const JITTER_POOLS := {
    "HEAD": ["head_optic", "pith_sinew_caul_hood", "pocketful_head_bonce"],
    "ARM_L": ["everykit_standard_piston", "cobble_sons_arm_mendclaw", "pocketful_arm_weefist"],
    "ARM_R": ["everykit_standard_fist", "cobble_sons_arm_ratchet", "quivergear_salvo_fist"],
    "LEGS": ["legs_light", "tinbox_legs_trusty", "pocketful_legs_stubby"],
    "BACK": ["back_bellows", "chatterbox_notion_pack", "everykit_standard_cell"],
}

# Light neutral frame used to fill the slots a family does not cover (total weight 48).
const FILLER := {"HEAD": "everykit_standard_cowl", "CORE": "core_ember",
    "ARM_L": "pocketful_arm_weefist", "ARM_R": "quivergear_salvo_fist",
    "LEGS": "pocketful_legs_stubby", "BACK": "chatterbox_notion_pack"}

var _total_fights: int = 0
var _draws: int = 0
var _wins: int = 0
var _losses: int = 0
var _last_stalled: bool = false     # set by _fight, read by the per-pair stall counters (v2)

func _initialize() -> void:
    var t0: int = Time.get_ticks_msec()
    var byid: Dictionary = Catalog.by_id()
    var all_bits: Array = Catalog.all()
    print("ROSTER SIM - catalog bits: %d  templates: %d  seeds/pairing: %d" % [all_bits.size(), TEMPLATES.size(), N_SEEDS])

    # --- sanity: every referenced id resolves --------------------------------------------------
    var missing: Array = []
    for t in TEMPLATES:
        var td: Dictionary = t
        for slot in ManabitState.SLOT_NAMES:
            var id: String = String((td["ids"] as Dictionary)[slot])
            if not byid.has(id):
                missing.append(id)
    for pool_slot in JITTER_POOLS.keys():
        for jid in JITTER_POOLS[pool_slot]:
            if not byid.has(String(jid)):
                missing.append(String(jid))
    for fslot in FILLER.keys():
        if not byid.has(String(FILLER[fslot])):
            missing.append(String(FILLER[fslot]))
    for gslot in GREATEST_HITS.keys():
        if not byid.has(String(GREATEST_HITS[gslot])):
            missing.append(String(GREATEST_HITS[gslot]))
    if not missing.is_empty():
        print("FATAL - unresolved ids: %s" % str(missing))
        quit(1)
        return

    # --- template legality (budget-legal per derived() weight rules) ---------------------------
    var template_meta: Array = []
    for ti in TEMPLATES.size():
        var ids: Dictionary = TEMPLATES[ti]["ids"]
        var d: Dictionary = _derived_of(ids)
        var legal: bool = int(d.weight) <= int(d.capacity)
        template_meta.append({"name": String(TEMPLATES[ti]["name"]), "ids": ids,
            "weight": int(d.weight), "capacity": int(d.capacity), "speed": int(d.speed), "legal": legal})
        print("  template %-6s weight %3d / cap %3d  spd %2d  %s" % [String(TEMPLATES[ti]["name"]),
            int(d.weight), int(d.capacity), int(d.speed), "LEGAL" if legal else "OVERWEIGHT"])
        if not legal:
            print("FATAL - template %s is not budget-legal" % String(TEMPLATES[ti]["name"]))
            quit(1)
            return

    # --- precompute seeded opponent variants: opp_ids[u][k] ------------------------------------
    var nt: int = TEMPLATES.size()
    var opp_ids: Array = []
    for u in nt:
        var per_seed: Array = []
        for k in N_SEEDS:
            var rng := RandomNumberGenerator.new()
            rng.seed = RNG_BASE + u * 1000003 + k * 7919
            per_seed.append(_jitter(TEMPLATES[u]["ids"], rng, {}))
        opp_ids.append(per_seed)

    # --- baseline: canonical template t vs seeded variants of every other template u -----------
    var base_score: Array = []      # base_score[t][u][k] -> float (0 / 0.5 / 1 for side t)
    var base_mean: Array = []       # base_mean[t][u] -> float, diag null
    var base_stalls: Array = []     # base_stalls[t][u] -> int stall count (v2), diag null
    for t2 in nt:
        var row_s: Array = []
        var row_m: Array = []
        var row_st: Array = []
        for u2 in nt:
            if u2 == t2:
                row_s.append([])
                row_m.append(null)
                row_st.append(null)
                continue
            var scores: Array = []
            var acc: float = 0.0
            var stalls: int = 0
            for k2 in N_SEEDS:
                var s: float = _fight(TEMPLATES[t2]["ids"], opp_ids[u2][k2], k2 % 2 == 0)
                scores.append(s)
                acc += s
                if _last_stalled:
                    stalls += 1
            row_s.append(scores)
            row_m.append(acc / float(N_SEEDS))
            row_st.append(stalls)
        base_score.append(row_s)
        base_mean.append(row_m)
        base_stalls.append(row_st)
    print("baseline template win-table done (%d fights, %.1fs)" % [_total_fights, (Time.get_ticks_msec() - t0) / 1000.0])

    # --- per-bit: swap into every template slot it fits, fight the other templates -------------
    var fam_order: Array = []
    var bits_by_fam: Dictionary = {}
    for v in all_bits:
        var pd: PartData = v
        var fam: String = String(pd.family)
        if not bits_by_fam.has(fam):
            bits_by_fam[fam] = []
            fam_order.append(fam)
        (bits_by_fam[fam] as Array).append(pd)

    var bit_rows: Array = []
    for fam2 in fam_order:
        var fam_t0: int = Time.get_ticks_msec()
        var fam_fights0: int = _total_fights
        for v2 in bits_by_fam[fam2]:
            var pd2: PartData = v2
            var slot2: String = String(pd2.slot)
            var bid: String = String(pd2.id)
            var delta_sum: float = 0.0
            var n: int = 0
            var per_template: Dictionary = {}
            for t3 in nt:
                var t_ids: Dictionary = TEMPLATES[t3]["ids"]
                if String(t_ids[slot2]) == bid:
                    continue    # already the template's own bit - zero-delta by construction, skip
                var mod_ids: Dictionary = t_ids.duplicate()
                mod_ids[slot2] = bid
                var t_delta: float = 0.0
                var t_n: int = 0
                for u3 in nt:
                    if u3 == t3:
                        continue
                    for k3 in N_SEEDS:
                        var ms: float = _fight(mod_ids, opp_ids[u3][k3], k3 % 2 == 0)
                        var bs: float = base_score[t3][u3][k3]
                        t_delta += ms - bs
                        t_n += 1
                delta_sum += t_delta
                n += t_n
                per_template[String(TEMPLATES[t3]["name"])] = t_delta / float(t_n)
            bit_rows.append({"id": bid, "name": String(pd2.display_name), "family": fam2,
                "slot": slot2, "rarity": String(pd2.rarity),
                "mean_delta": (delta_sum / float(n)) if n > 0 else 0.0,
                "n": n, "per_template": per_template})
        print("family %-18s %2d bits  %6d fights  %.1fs" % [fam2, (bits_by_fam[fam2] as Array).size(),
            _total_fights - fam_fights0, (Time.get_ticks_msec() - fam_t0) / 1000.0])

    # --- family signature builds + family vs family aggregate win matrix -----------------------
    var fam_builds: Dictionary = {}
    for fam3 in fam_order:
        fam_builds[fam3] = _family_build(bits_by_fam[fam3])
        var fd: Dictionary = _derived_of(fam_builds[fam3]["ids"])
        fam_builds[fam3]["weight"] = int(fd.weight)
        fam_builds[fam3]["capacity"] = int(fd.capacity)
        fam_builds[fam3]["legal"] = int(fd.weight) <= int(fd.capacity)

    var fam_matrix: Dictionary = {}
    var fam_stalls: Dictionary = {}
    var mat_t0: int = Time.get_ticks_msec()
    for ai in fam_order.size():
        var fa: String = fam_order[ai]
        fam_matrix[fa] = {}
        fam_stalls[fa] = {}
        for bi in fam_order.size():
            if bi == ai:
                continue
            var fb: String = fam_order[bi]
            var acc2: float = 0.0
            var stalls2: int = 0
            for k4 in N_SEEDS:
                var rng2 := RandomNumberGenerator.new()
                rng2.seed = 900001 + (ai * 37 + bi) * 1009 + k4 * 7919
                var a_jit: Dictionary = _jitter(fam_builds[fa]["ids"], rng2, fam_builds[fa]["owned"])
                var b_jit: Dictionary = _jitter(fam_builds[fb]["ids"], rng2, fam_builds[fb]["owned"])
                acc2 += _fight(a_jit, b_jit, k4 % 2 == 0)
                if _last_stalled:
                    stalls2 += 1
            (fam_matrix[fa] as Dictionary)[fb] = acc2 / float(N_SEEDS)
            (fam_stalls[fa] as Dictionary)[fb] = stalls2
    print("family matrix done (%d families, %.1fs)" % [fam_order.size(), (Time.get_ticks_msec() - mat_t0) / 1000.0])

    # --- pentagon check: symmetric dominance + search for a full 5-cycle -----------------------
    var pent_pairs: Array = []
    var dom: Dictionary = {}
    for pa in PENTAGON:
        dom[pa] = {}
    for pi in PENTAGON.size():
        for pj in PENTAGON.size():
            if pi == pj:
                continue
            var a4: String = PENTAGON[pi]
            var b4: String = PENTAGON[pj]
            var w_ab: float = float((fam_matrix[a4] as Dictionary)[b4])
            var w_ba: float = float((fam_matrix[b4] as Dictionary)[a4])
            (dom[a4] as Dictionary)[b4] = (w_ab + (1.0 - w_ba)) / 2.0
    for pi2 in PENTAGON.size():
        for pj2 in range(pi2 + 1, PENTAGON.size()):
            var a5: String = PENTAGON[pi2]
            var b5: String = PENTAGON[pj2]
            var d5: float = float((dom[a5] as Dictionary)[b5])
            pent_pairs.append({"a": a5, "b": b5, "dom_a_over_b": d5,
                "direction": ("%s > %s" % [a5, b5]) if d5 > 0.5 else (("%s > %s" % [b5, a5]) if d5 < 0.5 else "even")})
    var cycles: Array = []
    for perm in _perms([1, 2, 3, 4]):
        var order: Array = [0]
        var p_arr: Array = perm
        order.append_array(p_arr)
        var ok: bool = true
        for i5 in 5:
            var ca: String = PENTAGON[order[i5]]
            var cb: String = PENTAGON[order[(i5 + 1) % 5]]
            if float((dom[ca] as Dictionary)[cb]) <= 0.5:
                ok = false
                break
        if ok:
            var names: Array = []
            for oi in order:
                var oint: int = oi
                names.append(PENTAGON[oint])
            cycles.append(" > ".join(names) + " > " + PENTAGON[0])

    # --- v2 (c): 200-seed pentagon under the core-aiming + GUARD-when-behind player policy ------
    var pent_v2_t0: int = Time.get_ticks_msec()
    var pent_v2_fights: int = 0
    var pent_v2_cells: Array = []
    var dom_v2: Dictionary = {}
    for pa2 in PENTAGON:
        dom_v2[pa2] = {}
    var win_v2: Dictionary = {}
    for pi6 in PENTAGON.size():
        for pj6 in PENTAGON.size():
            if pi6 == pj6:
                continue
            var fa6: String = PENTAGON[pi6]
            var fb6: String = PENTAGON[pj6]
            var fai: int = fam_order.find(fa6)
            var fbi: int = fam_order.find(fb6)
            var acc6: float = 0.0
            var stalls6: int = 0
            for k6 in PENT_V2_SEEDS:
                var rng6 := RandomNumberGenerator.new()
                rng6.seed = 900001 + (fai * 37 + fbi) * 1009 + k6 * 7919
                var a_jit6: Dictionary = _jitter(fam_builds[fa6]["ids"], rng6, fam_builds[fa6]["owned"])
                var b_jit6: Dictionary = _jitter(fam_builds[fb6]["ids"], rng6, fam_builds[fb6]["owned"])
                var r6: Dictionary = _fight_policy(a_jit6, b_jit6, k6 % 2 == 0)
                acc6 += float(r6["score"])
                if bool(r6["stalled"]):
                    stalls6 += 1
                pent_v2_fights += 1
            var wr6: float = acc6 / float(PENT_V2_SEEDS)
            win_v2["%s|%s" % [fa6, fb6]] = wr6
            pent_v2_cells.append({"a": fa6, "b": fb6, "win_a": wr6, "stalls": stalls6, "n": PENT_V2_SEEDS})
    for pi7 in PENTAGON.size():
        for pj7 in PENTAGON.size():
            if pi7 == pj7:
                continue
            var a7: String = PENTAGON[pi7]
            var b7: String = PENTAGON[pj7]
            var w_ab7: float = float(win_v2["%s|%s" % [a7, b7]])
            var w_ba7: float = float(win_v2["%s|%s" % [b7, a7]])
            (dom_v2[a7] as Dictionary)[b7] = (w_ab7 + (1.0 - w_ba7)) / 2.0
    var pent_v2_pairs: Array = []
    for pi8 in PENTAGON.size():
        for pj8 in range(pi8 + 1, PENTAGON.size()):
            var a8: String = PENTAGON[pi8]
            var b8: String = PENTAGON[pj8]
            var d8: float = float((dom_v2[a8] as Dictionary)[b8])
            pent_v2_pairs.append({"a": a8, "b": b8, "dom_a_over_b": d8,
                "direction": ("%s > %s" % [a8, b8]) if d8 > 0.5 else (("%s > %s" % [b8, a8]) if d8 < 0.5 else "even")})
    print("pentagon v2 done (%d fights, %.1fs)" % [pent_v2_fights, (Time.get_ticks_msec() - pent_v2_t0) / 1000.0])

    # --- v2 (d): cross-family greatest-hits build row (shipped AI, same opponent variants) ------
    var gh_ids: Dictionary = {}
    for gslot2 in GREATEST_HITS.keys():
        gh_ids[gslot2] = String(GREATEST_HITS[gslot2])
    var gh_d: Dictionary = _derived_of(gh_ids)
    var gh_per_template: Dictionary = {}
    var gh_acc: float = 0.0
    var gh_n: int = 0
    var gh_stalls: int = 0
    for u9 in nt:
        var acc9: float = 0.0
        var st9: int = 0
        for k9 in N_SEEDS:
            var s9: float = _fight(gh_ids, opp_ids[u9][k9], k9 % 2 == 0)
            acc9 += s9
            if _last_stalled:
                st9 += 1
        gh_per_template[String(TEMPLATES[u9]["name"])] = acc9 / float(N_SEEDS)
        gh_acc += acc9
        gh_n += N_SEEDS
        gh_stalls += st9
    var greatest_hits_out: Dictionary = {
        "ids": gh_ids,
        "weight": int(gh_d.weight), "capacity": int(gh_d.capacity),
        "legal": int(gh_d.weight) <= int(gh_d.capacity),
        "mean_win_rate_vs_templates": gh_acc / float(gh_n),
        "per_template": gh_per_template,
        "stalls": gh_stalls, "n": gh_n,
        "note": "Regalia Core + Bedrock Legs + Pistonfist + Girder Fist + Herald Crown, BACK empty; fought vs the same seeded opponent variants as the bit rows (shipped AI).",
    }

    # --- write JSON ----------------------------------------------------------------------------
    var out: Dictionary = {
        "meta": {
            "generated": Time.get_datetime_string_from_system(),
            "n_seeds": N_SEEDS, "turn_cap": TURN_CAP, "jitter_rate": JITTER_RATE,
            "catalog_bits": all_bits.size(), "total_fights": _total_fights,
            "wins": _wins, "losses": _losses, "draws": _draws,
            "notes": "Combat is deterministic; variation comes from seeded per-slot opponent jitter (widely-available commons, CORE never jittered) and role alternation by seed parity. Fights run both-sides-AI with enemy_can_aim_core=true so both sides can close games. Score: WIN=1 for the player side, DEATH and SURVIVABLE_LOSS=1 for the enemy side, turn-cap stall=0.5 each. mean_delta = mean over (template, opponent, seed) of modified-template score minus that template's baseline score at the same seed.",
        },
        "templates": template_meta,
        "baseline_matrix": {"order": _template_names(), "rows": base_mean, "stalls": base_stalls},
        "bits": bit_rows,
        "family_builds": fam_builds,
        "family_matrix": fam_matrix,
        "family_matrix_stalls": fam_stalls,
        "pentagon": {"families": PENTAGON, "pairs": pent_pairs, "cycles_found": cycles,
            "cycles": cycles.size()},
        "pentagon_v2": {"families": PENTAGON, "n_seeds": PENT_V2_SEEDS,
            "policy": "both sides: best affordable can_target_core SINGLE when it out-damages the part-break line; GUARD-when-behind (core HP ratio 0.15 below the foe's, never twice in a row); shipped default line otherwise",
            "cells": pent_v2_cells, "pairs": pent_v2_pairs},
        "greatest_hits": greatest_hits_out,
    }
    var abs_dir: String = ProjectSettings.globalize_path(OUT_DIR)
    DirAccess.make_dir_recursive_absolute(abs_dir)
    var f := FileAccess.open(OUT_PATH, FileAccess.WRITE)
    if f == null:
        print("FATAL - cannot open %s for write" % OUT_PATH)
        quit(1)
        return
    f.store_string(JSON.stringify(out, "  "))
    f.close()
    var reparse = JSON.parse_string(FileAccess.get_file_as_string(OUT_PATH))
    if typeof(reparse) != TYPE_DICTIONARY:
        print("FATAL - written JSON did not re-parse")
        quit(1)
        return
    print("wrote %s (re-parse OK)" % OUT_PATH)

    # --- human summary -------------------------------------------------------------------------
    var ranked: Array = bit_rows.duplicate()
    ranked.sort_custom(func(a, b): return float(a["mean_delta"]) > float(b["mean_delta"]))
    print("\nTOP 10 OVERPOWERED (win-rate delta when swapped into a template):")
    for i6 in mini(10, ranked.size()):
        var r: Dictionary = ranked[i6]
        print("  %+6.1f%%  %-32s %-6s %-6s %s" % [float(r["mean_delta"]) * 100.0, String(r["id"]),
            String(r["slot"]), String(r["rarity"]), String(r["family"])])
    print("BOTTOM 10 DEAD:")
    for i7 in mini(10, ranked.size()):
        var r2: Dictionary = ranked[ranked.size() - 1 - i7]
        print("  %+6.1f%%  %-32s %-6s %-6s %s" % [float(r2["mean_delta"]) * 100.0, String(r2["id"]),
            String(r2["slot"]), String(r2["rarity"]), String(r2["family"])])
    print("\nPENTAGON (symmetric dominance, >0.5 = row family wins the pair):")
    for pp in pent_pairs:
        var ppd: Dictionary = pp
        print("  %-14s vs %-14s dom=%.2f  -> %s" % [String(ppd["a"]), String(ppd["b"]),
            float(ppd["dom_a_over_b"]), String(ppd["direction"])])
    if cycles.is_empty():
        print("  NO full 5-cycle found - the intended intransitive wheel does NOT cycle as-is.")
    else:
        print("  5-cycle(s) found: %d" % cycles.size())
        for c6 in cycles:
            print("    " + String(c6))
    print("\nPENTAGON v2 (core-aiming policy, %d seeds, symmetric dominance):" % PENT_V2_SEEDS)
    for pp2 in pent_v2_pairs:
        var ppd2: Dictionary = pp2
        print("  %-14s vs %-14s dom=%.3f  -> %s" % [String(ppd2["a"]), String(ppd2["b"]),
            float(ppd2["dom_a_over_b"]), String(ppd2["direction"])])
    print("GREATEST-HITS build: mean win %.3f  weight %d/%d %s  stalls %d/%d" % [
        float(greatest_hits_out["mean_win_rate_vs_templates"]), int(greatest_hits_out["weight"]),
        int(greatest_hits_out["capacity"]), "LEGAL" if bool(greatest_hits_out["legal"]) else "OVERWEIGHT",
        int(greatest_hits_out["stalls"]), int(greatest_hits_out["n"])])
    print("\ntotal fights %d (W %d / L %d / draw %d)  runtime %.1fs" % [_total_fights, _wins, _losses, _draws,
        (Time.get_ticks_msec() - t0) / 1000.0])
    print("ROSTER SIM PASS")
    quit(0)

# --- helpers -----------------------------------------------------------------------------------

func _template_names() -> Array:
    var out: Array = []
    for t in TEMPLATES:
        var td: Dictionary = t
        out.append(String(td["name"]))
    return out

func _build(ids: Dictionary) -> ManabitState:
    var byid: Dictionary = Catalog.by_id()
    var m := ManabitState.new()
    for slot in ManabitState.SLOT_NAMES:
        var id: String = String(ids.get(slot, ""))
        m.slots[slot] = PartInstance.new(byid[id]) if byid.has(id) else null
    return m

func _derived_of(ids: Dictionary) -> Dictionary:
    return _build(ids).derived()

# Seeded per-slot jitter: each non-protected, non-CORE slot swaps to a widely-available common
# with probability JITTER_RATE. Deterministic for a given rng state.
func _jitter(base_ids: Dictionary, rng: RandomNumberGenerator, protected: Dictionary) -> Dictionary:
    var out: Dictionary = base_ids.duplicate()
    for slot in JITTER_POOLS.keys():
        if protected.has(slot):
            continue
        var roll: float = rng.randf()
        var pick: int = rng.randi()     # always draw both so protection does not shift the stream
        if roll < JITTER_RATE:
            var pool: Array = JITTER_POOLS[slot]
            out[slot] = String(pool[pick % pool.size()])
    return out

# One fight, both sides AI, elite-style stakes (enemy may aim the core) so games close.
# Returns the score for side a: 1 win, 0 loss, 0.5 turn-cap stall.
func _fight(a_ids: Dictionary, b_ids: Dictionary, a_is_player: bool) -> float:
    var a := _build(a_ids)
    var b := _build(b_ids)
    var p: ManabitState = a if a_is_player else b
    var e: ManabitState = b if a_is_player else a
    var c := Combat.new()
    c.start(p, e, true)
    var guard: int = 0
    while c.outcome() == Combat.Result.ONGOING and guard < TURN_CAP:
        var actor: ManabitState = c.current()
        if actor == p:
            c.ai_take_turn(p, e)
        else:
            c.ai_take_turn(e, p)
        if c.outcome() == Combat.Result.ONGOING:
            c.advance_turn()
        guard += 1
    _total_fights += 1
    var res: int = c.outcome()
    _last_stalled = false
    if res == Combat.Result.ONGOING:
        _draws += 1
        _last_stalled = true
        return 0.5
    var player_won: bool = (res == Combat.Result.WIN)
    var a_won: bool = player_won if a_is_player else not player_won
    if a_won:
        _wins += 1
    else:
        _losses += 1
    return 1.0 if a_won else 0.0

# --- v2 (a): core-aiming + GUARD-when-behind policy (instrument lens, NOT shipped AI) -----------
# Take the best affordable can_target_core SINGLE when its core damage out-damages the shipped
# part-break line; GUARD when behind on core HP ratio (0.15 margin) and the last own action was
# not already a GUARD (anti-turtle); otherwise fall through to the shipped default line.
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

# One fight under the v2 policy, both sides. Separate counters (never disturbs the v1 meta).
func _fight_policy(a_ids: Dictionary, b_ids: Dictionary, a_is_player: bool) -> Dictionary:
    var a := _build(a_ids)
    var b := _build(b_ids)
    var p: ManabitState = a if a_is_player else b
    var e: ManabitState = b if a_is_player else a
    var c := Combat.new()
    c.start(p, e, true)
    var pstate: Dictionary = {}
    var estate: Dictionary = {}
    var guard: int = 0
    while c.outcome() == Combat.Result.ONGOING and guard < TURN_CAP:
        var actor: ManabitState = c.current()
        if actor == p:
            _policy_take_turn(c, p, e, pstate)
        else:
            _policy_take_turn(c, e, p, estate)
        if c.outcome() == Combat.Result.ONGOING:
            c.advance_turn()
        guard += 1
    var res: int = c.outcome()
    if res == Combat.Result.ONGOING:
        return {"score": 0.5, "stalled": true}
    var player_won: bool = (res == Combat.Result.WIN)
    var a_won: bool = player_won if a_is_player else not player_won
    return {"score": 1.0 if a_won else 0.0, "stalled": false}

# Greedy budget-legal family signature build: start from the light neutral FILLER frame, seat the
# family's best core (if any), then accept family body bits in rarity-then-stat order whenever the
# build stays weight-legal. Returns {ids, owned} where owned marks the family-identity slots.
func _family_build(fam_bits: Array) -> Dictionary:
    var ids: Dictionary = {}
    for fslot in FILLER.keys():
        ids[fslot] = String(FILLER[fslot])
    var owned: Dictionary = {}
    var sorted_bits: Array = fam_bits.duplicate()
    sorted_bits.sort_custom(_bit_order)
    for v in sorted_bits:
        var pd: PartData = v
        if pd.is_core:
            ids["CORE"] = String(pd.id)
            owned["CORE"] = true
            break
    for v2 in sorted_bits:
        var pd2: PartData = v2
        if pd2.is_core:
            continue
        var slot: String = String(pd2.slot)
        if owned.has(slot):
            continue
        var trial: Dictionary = ids.duplicate()
        trial[slot] = String(pd2.id)
        var d: Dictionary = _derived_of(trial)
        if int(d.weight) <= int(d.capacity):
            ids[slot] = String(pd2.id)
            owned[slot] = true
    return {"ids": ids, "owned": owned}

func _bit_order(a, b) -> bool:
    var pa: PartData = a
    var pb: PartData = b
    var ra: int = int(RARITY_RANK.get(String(pa.rarity), 0))
    var rb: int = int(RARITY_RANK.get(String(pb.rarity), 0))
    if ra != rb:
        return ra > rb
    var sa: int = pa.max_hp + pa.attack + pa.defense + pa.speed + pa.energy
    var sb: int = pb.max_hp + pb.attack + pb.defense + pb.speed + pb.energy
    if sa != sb:
        return sa > sb
    return String(pa.id) < String(pb.id)

func _perms(arr: Array) -> Array:
    if arr.size() <= 1:
        return [arr.duplicate()]
    var out: Array = []
    for i in arr.size():
        var rest: Array = arr.duplicate()
        var head: int = rest.pop_at(i)
        for tail in _perms(rest):
            var t_arr: Array = tail
            var one: Array = [head]
            one.append_array(t_arr)
            out.append(one)
    return out
