extends SceneTree
# SESSION-TRACE PLAYTEST HARNESS (playtest-panel lane). READ-ONLY on game state: never touches
# PlayerState saves or user://. The aggregate sims (sim_ladder / sim_roster / economy_sim) give
# win-rate tables; THIS instrument produces NARRATIVE SESSION TRACES - what one full play session
# actually feels like, turn by turn - at three skill tiers across the three real journeys.
#
# It reuses the shipped drive pattern (Combat.new -> start -> ai_take_turn / perform -> advance_turn,
# same loop as smoke_kit_sim.gd + sim_ladder.gd) and the shipped run helpers (RunState._make_map ->
# choose -> RunMods.pre_fight_mend / consume_core_pad / note_win, Challengers.make(entry, mod_id)).
# Nothing here is a parallel combat implementation - a trace vouches for the shipped path.
#
# THREE SKILL TIERS (build quality AND move quality both scale - a novice brings a worse build AND
# plays it worse; the kit journey holds the box fixed so it isolates PLAY skill):
#   novice  - cheap/random-ish COMMON builds; shipped greedy AI (first non-GUARD move in slot order,
#             lowest-HP non-core target, never guards, never races the core). Junctions picked blind.
#   average - mid tuned COMMON/RARE builds; picks the highest-damage move, focus-breaks the lowest-HP
#             part, GUARDs when its core falls 0.15 behind. Junctions avoid the heavier lane.
#   expert  - strong RARE/EPIC builds; the core-aiming lens (best can_target_core SINGLE when it
#             out-damages the part-break line) + GUARD-when-behind. Junctions minimise foe strength.
#
# THREE JOURNEYS:
#   (a) LADDER  - a Proving BOUT climb up ch[0..8]; each rung is an independent full-HP bout (foe does
#                 NOT aim the core - bout rule); climb stops at the first non-WIN. Stake charged per rung.
#   (b) VENTURE - an OWN-BUILD run down the 5-node road with junction choices; damage PERSISTS, rests
#                 repair for scrap, elite/boss AIM THE CORE (DEATH ends the run + loses the build).
#   (c) KIT     - a Box-of-Scrap run across grades (Dud..Gleaming, seeds bucketed for even coverage);
#                 free repairs, satchel purses, Gleaner's Due spill on death. Same road rules.
#
# Output: G:/ClaudeApps/manabit/tools/sim/out/sessions.json (rich structured traces) +
#         G:/ClaudeApps/manabit/tools/sim/out/session_transcripts.txt (4-6 human play-by-plays).
# Run: & "G:/Godot/Godot_v4.7-stable_win64_console.exe" --headless --path G:/ClaudeApps/manabit -s "res://tools/sim/playtest_session.gd"

const OUT_DIR := "G:/ClaudeApps/manabit/tools/sim/out"
const OUT_JSON := "G:/ClaudeApps/manabit/tools/sim/out/sessions.json"
const OUT_TXT := "G:/ClaudeApps/manabit/tools/sim/out/session_transcripts.txt"
const TURN_CAP := 120                 # actor-turns; unresolved = "stall", counted honestly
const N_SESSIONS := 36                # per tier per journey (task band 30-60)

const TIERS := ["novice", "average", "expert"]
const JOURNEYS := ["ladder", "venture", "kit"]

# Tier -> the two archetype generators it draws builds from (ladder + own venture; kit overrides).
const TIER_ARCHES := {"novice": [0, 1], "average": [2, 3], "expert": [4, 5]}

var _logs: Dictionary = {}            # sid -> Array of per-fight battle_log arrays (transcripts only)

func _initialize() -> void:
    var t0 := Time.get_ticks_msec()
    DirAccess.make_dir_recursive_absolute(OUT_DIR)
    print("MANABIT playtest_session - %d sessions/tier/journey, 3 tiers, 3 journeys" % N_SESSIONS)

    var sessions: Array = []
    var kit_seeds := _kit_seeds(N_SESSIONS)     # grade-balanced box seeds, shared across tiers
    for journey in JOURNEYS:
        for tier in TIERS:
            for i in N_SESSIONS:
                var sid := sessions.size()
                var s: Dictionary
                match journey:
                    "ladder":
                        s = _ladder_session(tier, i, sid)
                    "venture":
                        s = _venture_session(tier, i, sid, false, 0)
                    _:
                        var ks: Dictionary = kit_seeds[i]
                        s = _venture_session(tier, i, sid, true, int(ks["seed"]))
                        s["box_grade"] = String(ks["grade"])
                sessions.append(s)
            print("  %-8s %-8s done (%d sessions)" % [journey, tier, N_SESSIONS])

    var agg := _aggregate(sessions)
    var report := {
        "meta": {
            "generated": Time.get_datetime_string_from_system(),
            "n_sessions_per_cell": N_SESSIONS,
            "tiers": TIERS,
            "journeys": JOURNEYS,
            "turn_cap_actor_turns": TURN_CAP,
            "read_only_note": "no PlayerState save / user:// access; fresh ManabitState + RunState per session",
            "combat_note": "combat.gd is deterministic; variance is seeded build/box generation only",
            "tier_note": "novice=shipped greedy AI + cheap builds; average=best-damage + focus-break + guard-when-behind + mid builds; expert=core-aiming lens + strong builds",
            "ladder_note": "each rung is an independent full-HP bout (foe aims_core=false); climb stops at first non-WIN; stake charged per rung",
            "venture_note": "own-build ventures pay NO purse (KIT_PURSE is kit-only); net scrap = forfeit salvage + gleaners wreck - repairs",
            "kit_note": "kit runs: free repairs, satchel purse per fight tier won, Gleaner's Due spill on death, box grade balanced across Dud..Gleaming",
        },
        "aggregate": agg,
        "sessions": sessions,
    }

    var f := FileAccess.open(OUT_JSON, FileAccess.WRITE)
    var ok := f != null
    if ok:
        f.store_string(JSON.stringify(report, "  "))
        f.close()
    # second-read parity check (Godot side)
    var reparse = JSON.parse_string(FileAccess.get_file_as_string(OUT_JSON))
    var parses := typeof(reparse) == TYPE_DICTIONARY
    _write_transcripts(sessions)
    _print_headline(agg)
    print("")
    print("json: %s (%s, re-parse %s)" % [OUT_JSON, "OK" if ok else "WRITE FAILED", "OK" if parses else "FAILED"])
    print("txt : %s" % OUT_TXT)
    print("elapsed: %.1fs   total sessions: %d" % [(Time.get_ticks_msec() - t0) / 1000.0, sessions.size()])
    print("PLAYTEST PASS" if (ok and parses) else "PLAYTEST FAIL")
    quit(0 if (ok and parses) else 1)

# ============================ JOURNEY A - PROVING LADDER CLIMB ============================

func _ladder_session(tier: String, i: int, sid: int) -> Dictionary:
    var seed := 500009 + i * 104729 + TIERS.find(tier) * 7919
    var rng := RandomNumberGenerator.new()
    rng.seed = seed
    var build := _tier_build(tier, rng)
    var open_build := _build_snapshot(build)
    var ch := Challengers.list()
    var fights: Array = []
    var flogs: Array = []
    var stake_paid := 0
    var loot_melt := 0
    var parts_lost := 0
    var cleared := 0
    var wall := ""
    var wall_tier := ""
    for ci in ch.size():
        var entry: Dictionary = ch[ci]
        var stake: int = PlayerState.bout_stake(entry)
        stake_paid += stake
        var foe := Challengers.make(entry)
        var fresh := _clone(build)                       # each bout: repaired bench Manabit, full HP
        var fr := _run_fight(fresh, foe, false, tier, String(entry["name"]),
            _tier_of_challenger(ci), "")
        fights.append(fr["trace"])
        flogs.append(fr["log"])
        var res: int = int(fr["result"])
        if res == Combat.Result.WIN:
            cleared += 1
            var pd := _best_loot(foe)
            if pd != null:
                loot_melt += Broker.salvage_scrap(pd)
        else:
            wall = String(entry["name"])
            wall_tier = _tier_of_challenger(ci)
            if res == Combat.Result.SURVIVABLE_LOSS:
                var fslot := _forfeit_pick(fresh)
                if fslot != "":
                    parts_lost += 1
            break
    _logs[sid] = flogs
    var primary := _session_flag(fights, false)
    return {
        "sid": sid, "journey": "ladder", "tier": tier, "seed": seed,
        "opening_build": open_build,
        "rungs_cleared": cleared,
        "wall": wall, "wall_tier": wall_tier,
        "reached_top": cleared == ch.size(),
        "economy": {
            "stake_paid_scrap": stake_paid, "loot_melt_value_scrap": loot_melt,
            "parts_lost": parts_lost,
            "net_ev_scrap": _r(float(loot_melt - stake_paid)),
        },
        "fights": fights,
        "primary_flag": primary,
        "n_fights": fights.size(),
    }

# ============================ JOURNEYS B/C - THE ROAD (own build + kit) ============================

func _venture_session(tier: String, i: int, sid: int, is_kit: bool, box_seed: int) -> Dictionary:
    var seed := (600011 + i * 104729 + TIERS.find(tier) * 7919) if not is_kit else box_seed
    var rng := RandomNumberGenerator.new()
    rng.seed = seed + 13
    var build: ManabitState
    if is_kit:
        build = BoxRoller.roll(box_seed)
    else:
        build = _tier_build(tier, rng)
    var open_build := _build_snapshot(build)

    var run := RunState.new()
    run.carried = _clone(build)
    run.is_kit = is_kit
    var template := i % RunState.TEMPLATES.size()
    run.map = run._make_map(template)
    run.pos = 0

    var path: Array = []
    var fights: Array = []
    var flogs: Array = []
    var repairs_paid := 0
    var loot_melt := 0
    var forfeit_salvage := 0
    var bits_looted := 0
    var bits_lost := 0
    var satchel := 0
    var gleaners_kept := 0
    var wreck_scrap := 0
    var death := {}
    var death_h := 0.0

    while not run.over:
        var nd: Dictionary = run.node()
        var ntype := String(nd.get("type", ""))
        if ntype == "REST":
            var cost := run.repair_cost()
            if not is_kit:
                repairs_paid += cost
            run.repair_all()
            path.append({"pos": run.pos, "type": "REST", "label": String(nd.get("label", "")),
                "flavor": String(nd.get("flavor", "camp")), "repair_scrap": (0 if is_kit else cost)})
            run.advance()
            continue
        if ntype == "JUNCTION":
            var idx := _junction_pick(run, tier, rng)
            var chosen: Dictionary = (run.choices()[idx] as Dictionary)
            path.append({"pos": run.pos, "type": "JUNCTION", "tier": String(nd.get("tier", "")),
                "chose": String(chosen.get("lane_name", "")),
                "mod": String((chosen.get("modifier", {}) as Dictionary).get("id", "")),
                "spurned": String((run.choices()[(idx + 1) % run.choices().size()] as Dictionary).get("lane_name", ""))})
            run.choose(idx)
            continue
        # FIGHT - shipped player-side hooks then the bell
        RunMods.pre_fight_mend(run)
        RunMods.consume_core_pad(run)
        var nd2: Dictionary = run.node()
        var mod_id := String((nd2.get("modifier", {}) as Dictionary).get("id", ""))
        var tier_n := String(nd2.get("tier", ""))
        var aims := bool(nd2.get("aims_core", false))
        var foe := Challengers.make(nd2["challenger"], mod_id)
        var fname := String((nd2.get("challenger", {}) as Dictionary).get("name", "")).get_slice(",", 0)
        var fr := _run_fight(run.carried, foe, aims, tier, fname, tier_n, mod_id)
        fights.append(fr["trace"])
        flogs.append(fr["log"])
        path.append({"pos": run.pos, "type": "FIGHT", "tier": tier_n, "foe": fname,
            "mod": mod_id, "result": _res_word(int(fr["result"])),
            "flag": String((fr["trace"] as Dictionary)["flag"])})
        var res: int = int(fr["result"])
        if res == Combat.Result.WIN:
            var pd := _best_loot(foe)
            if pd != null:
                loot_melt += Broker.salvage_scrap(pd)
                bits_looted += 1
            if is_kit:
                satchel += int(PlayerState.KIT_PURSE.get(tier_n, 0))
            RunMods.note_win(run)
            run.advance()
        elif res == Combat.Result.DEATH:
            death_h = RunState.death_h(run.carried)
            if is_kit:
                gleaners_kept = RunState.gleaners_kept(satchel, tier_n, death_h)
            else:
                wreck_scrap = RunState.gleaners_wreck(run.carried, tier_n)
            death = {
                "pos": run.pos, "node_tier": tier_n, "foe": fname, "mod": mod_id,
                "killing_blow": (fr["trace"] as Dictionary).get("killing_blow", {}),
                "foe_core_hp_left_frac": _r(float((fr["trace"] as Dictionary).get("foe_end_frac", 0.0))),
                "your_hp_frac_at_death": _r(death_h),
                "satchel_spilled": satchel, "gleaners_kept": gleaners_kept,
            }
            run.over = true
        else:
            var fslot := _forfeit_pick(run.carried)
            if fslot != "":
                var fpi: PartInstance = run.carried.slots[fslot]
                forfeit_salvage += Broker.salvage_scrap(fpi.data)
                bits_lost += 1
                run.carried.slots[fslot] = null
            run.advance()
    _logs[sid] = flogs

    var survived := death.is_empty()
    var net: float
    if is_kit:
        net = float(satchel) if survived else float(gleaners_kept)
    else:
        net = float(forfeit_salvage + wreck_scrap - repairs_paid)
    return {
        "sid": sid, "journey": ("kit" if is_kit else "venture"), "tier": tier, "seed": seed,
        "template": template, "template_name": String((RunState.TEMPLATES[template] as Dictionary)["name"]),
        "opening_build": open_build,
        "survived": survived,
        "death": death,
        "path": path,
        "economy": {
            "repairs_paid_scrap": repairs_paid, "loot_melt_value_scrap": loot_melt,
            "forfeit_salvage_scrap": forfeit_salvage, "bits_looted": bits_looted,
            "bits_lost": bits_lost, "satchel_scrap": satchel,
            "gleaners_kept_scrap": gleaners_kept, "own_wreck_scrap": wreck_scrap,
            "net_scrap": _r(net),
        },
        "fights": fights,
        "primary_flag": _session_flag(fights, not survived),
        "n_fights": fights.size(),
    }

# Junction choice by tier. novice: blind (rng). average: avoid the heavier/overgrown lane.
# expert: minimise a quick foe-strength proxy, crediting player-favourable modifiers.
func _junction_pick(run: RunState, tier: String, rng: RandomNumberGenerator) -> int:
    var paths: Array = run.choices()
    if paths.size() <= 1:
        return 0
    if tier == "novice":
        return rng.randi() % paths.size()
    var best_i := 0
    var best_score := 1e18
    for li in paths.size():
        var p: Dictionary = paths[li]
        var mod := String((p.get("modifier", {}) as Dictionary).get("id", ""))
        var foe := Challengers.make((p["node"] as Dictionary)["challenger"], mod)
        var d: Dictionary = foe.derived()
        var core: PartInstance = foe.core()
        var proxy := float(int(d["attack"]) * 2 + (core.current_hp if core != null else 0))
        # player-side favourable mods do not show up foe-side; credit them by hand
        if mod == "tailwind":
            proxy -= 8.0
        elif mod == "second_wind":
            proxy -= 4.0
        if tier == "average" and mod == "overgrown":
            proxy += 100.0        # average just knows "heavier lane = bad"
        if proxy < best_score:
            best_score = proxy
            best_i = li
    return best_i

# ============================ THE FIGHT (traced) ============================
# One fight, foe uses the shipped AI, player uses its tier policy. Emits a full turn-by-turn trace,
# the raw battle_log (for transcripts), the killing blow, and a grounded feel flag.
func _run_fight(me: ManabitState, foe: ManabitState, foe_aims_core: bool, tier: String,
        foe_name: String, node_tier: String, mod_id: String) -> Dictionary:
    var c := Combat.new()
    c.start(me, foe, foe_aims_core)
    var you_max := maxi(1, me.core().data.max_hp)
    var foe_max := maxi(1, foe.core().data.max_hp)
    var turns: Array = []
    var pstate: Dictionary = {}
    var guard := 0
    var min_you := 1.0
    var min_foe := 1.0
    var you_broken := 0
    var foe_broken := 0
    var killing := {}
    while c.outcome() == Combat.Result.ONGOING and guard < TURN_CAP:
        var actor: ManabitState = c.current()
        var is_you := actor == me
        if is_you:
            match tier:
                "novice":
                    c.ai_take_turn(me, foe)
                "average":
                    _avg_take_turn(c, me, foe, pstate)
                _:
                    _exp_take_turn(c, me, foe, pstate)
        else:
            c.ai_take_turn(foe, me)
        var la: Dictionary = c.last_action
        var ev: Array = c.last_events.duplicate()
        var rec := {"actor": ("You" if is_you else "Foe")}
        var arche := String(la.get("archetype", ""))
        if arche == "GUARD":
            rec["act"] = "GUARD:" + String(la.get("guard_kind", ""))
            rec["dmg"] = 0
            rec["tgt"] = ""
            rec["brk"] = []
        else:
            var total := 0
            var breaks: Array = []
            var tgt := ""
            var core_hit := false
            for e in ev:
                var ed: Dictionary = e
                total += int(ed.get("damage", 0))
                tgt = String(ed.get("slot", tgt))
                if bool(ed.get("broke", false)):
                    breaks.append(String(ed.get("slot", "")))
                if bool(ed.get("is_core", false)):
                    core_hit = true
            rec["act"] = (arche if arche != "" else "-")
            rec["dmg"] = total
            rec["tgt"] = tgt
            rec["brk"] = breaks
            if core_hit:
                rec["core_hit"] = true
            if is_you:
                foe_broken += breaks.size()
            else:
                you_broken += breaks.size()
        rec["slot"] = String(la.get("actor_slot", ""))
        var yc: PartInstance = me.core()
        var fc: PartInstance = foe.core()
        var yhp := (yc.current_hp if yc != null else 0)
        var fhp := (fc.current_hp if fc != null else 0)
        rec["yc"] = yhp
        rec["fc"] = fhp
        rec["mana"] = (me.mana if is_you else foe.mana)
        turns.append(rec)
        min_you = minf(min_you, float(maxi(0, yhp)) / you_max)
        min_foe = minf(min_foe, float(maxi(0, fhp)) / foe_max)
        if not is_you and c.outcome() == Combat.Result.DEATH and killing.is_empty():
            killing = {"foe_move": rec["act"], "foe_slot": rec["slot"], "dmg": rec["dmg"],
                "foe_core_hp": fhp, "foe_core_frac": _r(float(fhp) / foe_max)}
        if c.outcome() == Combat.Result.ONGOING:
            c.advance_turn()
        guard += 1

    var res: int = c.outcome()
    var yc2: PartInstance = me.core()
    var fc2: PartInstance = foe.core()
    var you_end := _r(float(maxi(0, (yc2.current_hp if yc2 != null else 0))) / you_max)
    var foe_end := _r(float(maxi(0, (fc2.current_hp if fc2 != null else 0))) / foe_max)
    var flag := _fight_flag(res, you_end, foe_end, min_you, min_foe, you_broken, foe_broken)
    var trace := {
        "foe": foe_name, "node_tier": node_tier, "mod": mod_id,
        "you_core_max": you_max, "foe_core_max": foe_max,
        "result": res, "result_word": _res_word(res), "actor_turns": guard,
        "you_end_frac": you_end, "foe_end_frac": foe_end,
        "min_you_frac": _r(min_you), "min_foe_frac": _r(min_foe),
        "you_parts_broken": you_broken, "foe_parts_broken": foe_broken,
        "flag": flag, "turns": turns,
    }
    if not killing.is_empty():
        trace["killing_blow"] = killing
    return {"result": res, "trace": trace, "log": c.battle_log.duplicate()}

# ============================ PLAYER POLICIES (instrument lenses, NOT shipped AI) ============================

# average: highest-damage non-GUARD move, focus-break the lowest-HP non-core part, GUARD once when
# the core falls 0.15 behind. Does NOT snipe the core - that is the skill gap the expert closes.
func _avg_take_turn(c: Combat, me: ManabitState, foe: ManabitState, pstate: Dictionary) -> void:
    var moves := c.moves_for(me)
    if moves.is_empty():
        return
    var atk := int(me.derived().attack)
    var dfn := int(foe.derived().defense) + foe.guard_bonus
    var mc: PartInstance = me.core()
    var fc: PartInstance = foe.core()
    if mc != null and fc != null and not bool(pstate.get("guarded", false)):
        var my_r := float(mc.current_hp) / float(mc.data.max_hp)
        var fo_r := float(fc.current_hp) / float(fc.data.max_hp)
        if my_r + 0.15 < fo_r:
            for mv in moves:
                if (mv["ability"] as AbilityData).archetype == "GUARD":
                    c.perform(me, mv["ability"], foe, "")
                    c.last_action["actor_slot"] = String(mv["slot"])
                    pstate["guarded"] = true
                    return
    var best_mv: Dictionary = {}
    var best_dmg := -1
    for mv2 in moves:
        var a2: AbilityData = mv2["ability"]
        if a2.archetype == "GUARD":
            continue
        var d := maxi(1, atk + a2.power - dfn) * maxi(1, a2.hit_count)
        if d > best_dmg:
            best_dmg = d
            best_mv = mv2
    pstate["guarded"] = false
    if best_mv.is_empty():
        c.perform(me, moves[0]["ability"], foe, "")
        c.last_action["actor_slot"] = String(moves[0]["slot"])
        pstate["guarded"] = true
        return
    var ab: AbilityData = best_mv["ability"]
    if ab.archetype == "MULTI":
        c.perform(me, ab, foe, c._multi_target(foe))
    else:
        c.perform(me, ab, foe, _lowest_noncore(foe))
    c.last_action["actor_slot"] = String(best_mv["slot"])

# expert: the core-aiming lens (sim_ladder / sim_roster v2). Best affordable can_target_core SINGLE
# when its core damage out-damages the part-break line; GUARD-when-behind (never twice); else default.
func _exp_take_turn(c: Combat, me: ManabitState, foe: ManabitState, pstate: Dictionary) -> void:
    var moves := c.moves_for(me)
    if moves.is_empty():
        return
    var default_mv: Dictionary = moves[0]
    for mv in moves:
        if (mv["ability"] as AbilityData).archetype != "GUARD":
            default_mv = mv
            break
    var atk := int(me.derived().attack)
    var dfn := int(foe.derived().defense) + foe.guard_bonus
    var core_mv: Dictionary = {}
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
        c.perform(me, core_mv["ability"], foe, "CORE")
        c.last_action["actor_slot"] = String(core_mv["slot"])
        pstate["guarded"] = false
        return
    var mc: PartInstance = me.core()
    var fc: PartInstance = foe.core()
    if mc != null and fc != null and not bool(pstate.get("guarded", false)):
        var my_r := float(mc.current_hp) / float(mc.data.max_hp)
        var fo_r := float(fc.current_hp) / float(fc.data.max_hp)
        if my_r + 0.15 < fo_r:
            for mv3 in moves:
                var a3: AbilityData = mv3["ability"]
                if a3.archetype == "GUARD":
                    c.perform(me, a3, foe, "")
                    c.last_action["actor_slot"] = String(mv3["slot"])
                    pstate["guarded"] = true
                    return
    if def_ab.archetype == "GUARD":
        c.perform(me, def_ab, foe, "")
        c.last_action["actor_slot"] = String(default_mv["slot"])
        pstate["guarded"] = true
        return
    c.perform(me, def_ab, foe, c._multi_target(foe))
    c.last_action["actor_slot"] = String(default_mv["slot"])
    pstate["guarded"] = false

func _lowest_noncore(defender: ManabitState) -> String:
    var best := ""
    var best_hp := 1 << 30
    for slot in ManabitState.SLOT_NAMES:
        if slot == "CORE":
            continue
        var pi: PartInstance = defender.slots.get(slot)
        if pi != null and not pi.disabled and pi.current_hp < best_hp:
            best_hp = pi.current_hp
            best = slot
    return best if best != "" else "CORE"

# ============================ FEEL FLAGS (grounded, not vibes) ============================

func _fight_flag(res: int, you_end: float, foe_end: float, min_you: float, min_foe: float,
        you_broken: int, foe_broken: int) -> String:
    if res == Combat.Result.ONGOING:
        return "stall"
    if res == Combat.Result.WIN:
        if min_you < 0.30:
            return "comeback"          # dipped near death, still closed the win
        if you_end <= 0.25:
            return "nailbiter"         # limped over the line
        if you_end >= 0.80 and you_broken == 0:
            return "blowout"           # took almost nothing
        if you_broken == 0 and foe_broken >= 2:
            return "snowball"          # dismantled them, lost nothing
        return "clean_win"
    if res == Combat.Result.DEATH:
        if foe_end <= 0.25:
            return "heartbreak"        # you almost had them when the core caved
        if foe_end >= 0.75:
            return "outclassed"        # never in it
        return "death"
    return "survivable_loss"

# Session-level flag: a death dominates; else surface the scariest moment.
func _session_flag(fights: Array, died: bool) -> String:
    if fights.is_empty():
        return "empty"
    if died:
        return String((fights[fights.size() - 1] as Dictionary).get("flag", "death"))
    var order := ["stall", "comeback", "nailbiter", "heartbreak", "snowball", "blowout", "clean_win", "survivable_loss"]
    var seen := {}
    for fr in fights:
        seen[String((fr as Dictionary).get("flag", ""))] = true
    for k in order:
        if seen.has(k):
            if k == "blowout":
                # only call the run a blowout if EVERY fight was one
                var all_blow := true
                for fr in fights:
                    if String((fr as Dictionary).get("flag", "")) != "blowout":
                        all_blow = false
                        break
                return "blowout_run" if all_blow else "steady"
            return k
    return "steady"

# ============================ BUILD GENERATORS (ported from sim_ladder) ============================

func _tier_build(tier: String, rng: RandomNumberGenerator) -> ManabitState:
    var arches: Array = TIER_ARCHES[tier]
    var idx: int = arches[rng.randi() % arches.size()]
    return _build_archetype(idx, rng)

func _build_archetype(idx: int, rng: RandomNumberGenerator) -> ManabitState:
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
    if pool.is_empty():
        return
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
            maxp = maxi(maxp, (pd2 as PartData).ability.power)
        var top: Array = []
        for pd3 in pool:
            if (pd3 as PartData).ability.power >= maxp - 1:
                top.append(pd3)
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

# ============================ SMALL HELPERS ============================

func _tier_of_challenger(ci: int) -> String:
    # frozen roster tiers (challengers.gd): ch0-2 regular, ch3/5/6/7 elite, ch4/8 boss
    if ci == 4 or ci == 8:
        return "boss"
    if ci == 0 or ci == 1 or ci == 2:
        return "regular"
    return "elite"

func _res_word(res: int) -> String:
    match res:
        Combat.Result.WIN: return "WIN"
        Combat.Result.DEATH: return "DEATH"
        Combat.Result.SURVIVABLE_LOSS: return "SURVIVABLE_LOSS"
        _: return "STALL"

func _build_snapshot(m: ManabitState) -> Dictionary:
    var bits: Array = []
    for slot in ManabitState.SLOT_NAMES:
        var pi: PartInstance = m.slots.get(slot)
        if pi != null:
            bits.append({"slot": slot, "id": String(pi.data.id),
                "name": String(pi.data.display_name), "rarity": String(pi.data.rarity),
                "family": String(pi.data.family), "hp": pi.data.max_hp})
    var d: Dictionary = m.derived()
    var core: PartInstance = m.core()
    return {
        "bits": bits,
        "attack": int(d["attack"]), "defense": int(d["defense"]), "speed": int(d["speed"]),
        "energy": int(d["energy"]), "weight": int(d["weight"]), "capacity": int(d["capacity"]),
        "core_id": (String(core.data.id) if core != null else ""),
        "core_hp": (core.data.max_hp if core != null else 0),
        "core_rarity": (String(core.data.rarity) if core != null else ""),
        "socket_fill": bits.size(),
        "legal": int(d["weight"]) <= int(d["capacity"]),
    }

func _clone(src: ManabitState) -> ManabitState:
    var m := ManabitState.new()
    for slot in ManabitState.SLOT_NAMES:
        var pi: PartInstance = src.slots.get(slot)
        m.slots[slot] = PartInstance.new(pi.data) if pi != null else null
    return m

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

# Grade-balanced box seeds: scan seeds, bucket by BoxRoller.grade, take an even spread so the kit
# journey covers Dud..Gleaming (the natural roll is 12/28/32/20/8, thin at the tails).
func _kit_seeds(n: int) -> Array:
    var grades := ["Dud", "Rough", "Fair", "Keen", "Gleaming"]
    var per := int(ceil(float(n) / grades.size()))
    var buckets := {}
    for g in grades:
        buckets[g] = []
    var seed := 100003
    var filled := 0
    while filled < grades.size() * per and seed < 100003 + 4000000:
        var g := BoxRoller.grade(seed)
        var b: Array = buckets[g]
        if b.size() < per:
            b.append(seed)
            if b.size() == per:
                filled += 1
        seed += 7919
    var out: Array = []
    for gi in per:
        for g in grades:
            var b: Array = buckets[g]
            if gi < b.size():
                out.append({"seed": int(b[gi]), "grade": g})
    out.resize(n)
    return out

func _r(v: float) -> float:
    return snappedf(v, 0.001)

# ============================ AGGREGATE + HEADLINE ============================

func _aggregate(sessions: Array) -> Dictionary:
    var cells := {}
    for s in sessions:
        var sd: Dictionary = s
        var key := "%s/%s" % [String(sd["journey"]), String(sd["tier"])]
        if not cells.has(key):
            cells[key] = {"n": 0, "win_or_survive": 0, "close": 0, "stall": 0,
                "rungs_sum": 0, "reached_top": 0, "deaths": 0,
                "death_by_pos": {}, "death_by_tier": {}, "grade_win": {}, "grade_n": {},
                "net_sum": 0.0, "flags": {}}
        var cell: Dictionary = cells[key]
        cell["n"] = int(cell["n"]) + 1
        var flag := String(sd.get("primary_flag", ""))
        cell["flags"][flag] = int((cell["flags"] as Dictionary).get(flag, 0)) + 1
        if ["comeback", "nailbiter", "heartbreak"].has(flag):
            cell["close"] = int(cell["close"]) + 1
        if flag == "stall":
            cell["stall"] = int(cell["stall"]) + 1
        var econ: Dictionary = sd["economy"]
        var net_v: float = float(econ.get("net_scrap", econ.get("net_ev_scrap", 0.0)))
        cell["net_sum"] = float(cell["net_sum"]) + net_v
        if String(sd["journey"]) == "ladder":
            cell["rungs_sum"] = int(cell["rungs_sum"]) + int(sd["rungs_cleared"])
            if bool(sd["reached_top"]):
                cell["reached_top"] = int(cell["reached_top"]) + 1
            # a ladder "win" = cleared at least the 3 regular rungs
            if int(sd["rungs_cleared"]) >= 3:
                cell["win_or_survive"] = int(cell["win_or_survive"]) + 1
        else:
            if bool(sd["survived"]):
                cell["win_or_survive"] = int(cell["win_or_survive"]) + 1
            else:
                cell["deaths"] = int(cell["deaths"]) + 1
                var dd: Dictionary = sd["death"]
                var pk := "pos%d" % int(dd.get("pos", -1))
                var tk := String(dd.get("node_tier", "?"))
                cell["death_by_pos"][pk] = int((cell["death_by_pos"] as Dictionary).get(pk, 0)) + 1
                cell["death_by_tier"][tk] = int((cell["death_by_tier"] as Dictionary).get(tk, 0)) + 1
            if String(sd["journey"]) == "kit":
                var g := String(sd.get("box_grade", "?"))
                cell["grade_n"][g] = int((cell["grade_n"] as Dictionary).get(g, 0)) + 1
                if bool(sd["survived"]):
                    cell["grade_win"][g] = int((cell["grade_win"] as Dictionary).get(g, 0)) + 1
    var out := {}
    for key in cells.keys():
        var cell: Dictionary = cells[key]
        var n: int = int(cell["n"])
        var row := {
            "n": n,
            "win_or_survive_rate": _r(float(cell["win_or_survive"]) / n),
            "close_call_rate": _r(float(cell["close"]) / n),
            "stall_rate": _r(float(cell["stall"]) / n),
            "mean_net_scrap": _r(float(cell["net_sum"]) / n),
            "flag_mix": cell["flags"],
        }
        if key.begins_with("ladder"):
            row["mean_rungs_cleared"] = _r(float(cell["rungs_sum"]) / n)
            row["reached_top_rate"] = _r(float(cell["reached_top"]) / n)
        else:
            row["death_rate"] = _r(float(cell["deaths"]) / n)
            row["death_by_pos"] = cell["death_by_pos"]
            row["death_by_node_tier"] = cell["death_by_tier"]
            if key.begins_with("kit"):
                var gw := {}
                for g in (cell["grade_n"] as Dictionary).keys():
                    var gn: int = int((cell["grade_n"] as Dictionary)[g])
                    gw[g] = {"n": gn, "survive_rate": _r(float((cell["grade_win"] as Dictionary).get(g, 0)) / gn)}
                row["by_grade"] = gw
        out[key] = row
    return out

func _print_headline(agg: Dictionary) -> void:
    print("")
    print("==================== HEADLINE (per journey / tier) ====================")
    for journey in JOURNEYS:
        print("  -- %s --" % journey)
        for tier in TIERS:
            var key := "%s/%s" % [journey, tier]
            if not agg.has(key):
                continue
            var r: Dictionary = agg[key]
            if journey == "ladder":
                print("    %-8s win(>=3rungs) %.2f  mean rungs %.2f/9  top %.2f  close %.2f  net %+6.1f" % [
                    tier, float(r["win_or_survive_rate"]), float(r["mean_rungs_cleared"]),
                    float(r["reached_top_rate"]), float(r["close_call_rate"]), float(r["mean_net_scrap"])])
            else:
                var extra := ""
                if r.has("by_grade"):
                    var parts: Array = []
                    for g in ["Dud", "Rough", "Fair", "Keen", "Gleaming"]:
                        if (r["by_grade"] as Dictionary).has(g):
                            var gr: Dictionary = (r["by_grade"] as Dictionary)[g]
                            parts.append("%s %.2f" % [g.left(4), float(gr["survive_rate"])])
                    extra = "  grade[" + ", ".join(parts) + "]"
                print("    %-8s survive %.2f  death %.2f  close %.2f  stall %.2f  net %+6.1f  deaths@%s%s" % [
                    tier, float(r["win_or_survive_rate"]), float(r["death_rate"]),
                    float(r["close_call_rate"]), float(r["stall_rate"]), float(r["mean_net_scrap"]),
                    JSON.stringify(r["death_by_node_tier"]), extra])

# ============================ TRANSCRIPTS ============================

func _write_transcripts(sessions: Array) -> void:
    var picks := _pick_transcripts(sessions)
    var lines: Array = []
    lines.append("MANABIT - SESSION TRANSCRIPTS (playtest play-by-play)")
    lines.append("Generated %s   |   %d sessions total, %d transcribed below" % [
        Time.get_datetime_string_from_system(), sessions.size(), picks.size()])
    lines.append("Each line: actor, move, target, damage; core HP shown as You/Foe after the blow.")
    lines.append("=".repeat(78))
    for pick in picks:
        var sid: int = int(pick["sid"])
        var reason: String = String(pick["reason"])
        lines.append_array(_transcript_for(sessions[sid], reason))
        lines.append("")
        lines.append("=".repeat(78))
    var f := FileAccess.open(OUT_TXT, FileAccess.WRITE)
    if f != null:
        f.store_string("\n".join(lines))
        f.close()

func _pick_transcripts(sessions: Array) -> Array:
    var picks: Array = []
    var want := [
        {"journey": "ladder", "tier": "novice", "reason": "novice ladder - the early wall"},
        {"journey": "ladder", "tier": "expert", "reason": "expert ladder - a deep climb"},
        {"journey": "venture", "tier": "expert", "flag_any": ["heartbreak", "death", "outclassed"], "reason": "expert own-build venture - a core-hunt DEATH"},
        {"journey": "venture", "tier": "average", "survived": true, "reason": "average own-build venture - a road cleared"},
        {"journey": "kit", "grade": "Gleaming", "reason": "Gleaming box - the near-guarantee"},
        {"journey": "kit", "grade": "Dud", "reason": "Dud box - a weak box gets got"},
    ]
    for w in want:
        var wd: Dictionary = w
        var best := -1
        var best_score := -1
        for si in sessions.size():
            var sd: Dictionary = sessions[si]
            if String(sd["journey"]) != String(wd["journey"]):
                continue
            if wd.has("tier") and String(sd["tier"]) != String(wd["tier"]):
                continue
            if wd.has("grade") and String(sd.get("box_grade", "")) != String(wd["grade"]):
                continue
            if wd.has("survived") and bool(sd.get("survived", false)) != bool(wd["survived"]):
                continue
            var score := 1
            if wd.has("flag_any"):
                if (wd["flag_any"] as Array).has(String(sd.get("primary_flag", ""))):
                    score = 5
                else:
                    score = 0
            # prefer sessions with more fights (richer play-by-play)
            score = score * 100 + int(sd.get("n_fights", 0))
            if score > best_score:
                best_score = score
                best = si
        if best >= 0:
            picks.append({"sid": best, "reason": String(wd["reason"])})
    return picks

func _transcript_for(s: Dictionary, reason: String) -> Array:
    var out: Array = []
    var sid: int = int(s["sid"])
    out.append("SESSION #%d  [%s]" % [sid, reason])
    out.append("journey=%s  tier=%s  seed=%d%s" % [String(s["journey"]), String(s["tier"]), int(s["seed"]),
        ("  grade=" + String(s["box_grade"]) if s.has("box_grade") else "")])
    var ob: Dictionary = s["opening_build"]
    out.append("OPENING BUILD  (ATK %d / DEF %d / SPD %d / mana %d, weight %d/%d, core %s hp%d %s):" % [
        int(ob["attack"]), int(ob["defense"]), int(ob["speed"]), int(ob["energy"]),
        int(ob["weight"]), int(ob["capacity"]), String(ob["core_id"]), int(ob["core_hp"]), String(ob["core_rarity"])])
    for b in ob["bits"]:
        var bd: Dictionary = b
        out.append("    %-6s %-30s %-6s hp%d" % [String(bd["slot"]), String(bd["id"]), String(bd["rarity"]), int(bd["hp"])])
    out.append("-".repeat(60))
    var flogs: Array = _logs.get(sid, [])
    var fights: Array = s["fights"]
    if String(s["journey"]) == "ladder":
        for fi in fights.size():
            var fr: Dictionary = fights[fi]
            out.append(">> RUNG %d: %s  (%s)" % [fi + 1, String(fr["foe"]), String(fr["node_tier"])])
            _append_fight_lines(out, fr, flogs[fi] if fi < flogs.size() else [])
        out.append("CLIMB: cleared %d/9 rungs; wall = %s (%s)" % [
            int(s["rungs_cleared"]), (String(s["wall"]) if String(s["wall"]) != "" else "none - topped out"),
            String(s["wall_tier"])])
        var e: Dictionary = s["economy"]
        out.append("ECONOMY: stake paid %d scrap, loot melt %d, parts lost %d, net EV %+d" % [
            int(e["stake_paid_scrap"]), int(e["loot_melt_value_scrap"]), int(e["parts_lost"]), int(e["net_ev_scrap"])])
    else:
        var fi := 0
        for step in s["path"]:
            var st: Dictionary = step
            if String(st["type"]) == "REST":
                out.append("[ REST pos%d: %s (%s)%s ]" % [int(st["pos"]), String(st["label"]),
                    String(st["flavor"]), ("  repair -" + str(int(st["repair_scrap"])) + " scrap" if int(st.get("repair_scrap", 0)) > 0 else "  (free mend)")])
            elif String(st["type"]) == "JUNCTION":
                out.append("[ JUNCTION pos%d %s: chose '%s' [%s], spurned '%s' ]" % [int(st["pos"]),
                    String(st["tier"]), String(st["chose"]), String(st["mod"]), String(st["spurned"])])
            else:
                var fr: Dictionary = fights[fi]
                out.append(">> FIGHT pos%d: %s  (%s%s)" % [int(st["pos"]), String(fr["foe"]),
                    String(fr["node_tier"]), ("  mod=" + String(fr["mod"]) if String(fr["mod"]) != "" else "")])
                _append_fight_lines(out, fr, flogs[fi] if fi < flogs.size() else [])
                fi += 1
        if bool(s["survived"]):
            out.append("OUTCOME: SURVIVED the road.")
        else:
            var dd: Dictionary = s["death"]
            var kb: Dictionary = dd.get("killing_blow", {})
            out.append("OUTCOME: DEATH at pos%d (%s, %s). Killing blow: foe %s from %s for %d; foe core left %.0f%%. Your body was at %.0f%% HP." % [
                int(dd["pos"]), String(dd["node_tier"]), String(dd["foe"]),
                String(kb.get("foe_move", "?")), String(kb.get("foe_slot", "?")), int(kb.get("dmg", 0)),
                float(kb.get("foe_core_frac", 0.0)) * 100.0, float(dd["your_hp_frac_at_death"]) * 100.0])
        var e2: Dictionary = s["economy"]
        out.append("ECONOMY: net %+d scrap (repairs -%d, loot melt %d, forfeit +%d, satchel %d, gleaners +%d, wreck +%d)" % [
            int(e2["net_scrap"]), int(e2["repairs_paid_scrap"]), int(e2["loot_melt_value_scrap"]),
            int(e2["forfeit_salvage_scrap"]), int(e2["satchel_scrap"]), int(e2["gleaners_kept_scrap"]), int(e2["own_wreck_scrap"])])
    return out

func _append_fight_lines(out: Array, fr: Dictionary, log: Array) -> void:
    # prefer the shipped battle_log (has the flavor lines); fall back to the structured trace
    if not log.is_empty():
        for ln in log:
            out.append("     " + String(ln))
    else:
        for t in fr["turns"]:
            var td: Dictionary = t
            out.append("     %-3s %-14s -> %-5s dmg %d  (You %d / Foe %d)" % [
                String(td["actor"]), String(td["act"]), String(td["tgt"]), int(td["dmg"]),
                int(td["yc"]), int(td["fc"])])
    out.append("     result: %s  [%s]  turns %d  (you ended %.0f%%, foe %.0f%%)" % [
        String(fr["result_word"]), String(fr["flag"]), int(fr["actor_turns"]),
        float(fr["you_end_frac"]) * 100.0, float(fr["foe_end_frac"]) * 100.0])
