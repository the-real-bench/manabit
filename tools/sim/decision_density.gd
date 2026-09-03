extends SceneTree
# How many DECISIONS does the Workshop actually contain? (L-10)
#
# The Optimizer persona scores 5/10 on the claim that "the legal build collapses to
# one greedy answer identical across every core" and "the soul pick is nearly
# cosmetic". This measures that instead of arguing about it.
#
# METHOD: for each core, a knapsack over the five free slots (HEAD, ARM_L, ARM_R,
# LEGS, BACK) under that core's real capacity (100 + its carry), maximising summed
# per-bit value. Then, for every slot, count how many DIFFERENT bits appear in any
# build within TOL of the optimum. A slot whose count is 1 is not a decision.
#
# THE VALUE SIGNAL AND ITS LIMIT - read this before quoting any number below.
# Value is the measured `mean_delta` from tools/sim/out/roster-post.json: each bit's
# contribution to win rate over 480-600 real fights. That is measurement, not a
# heuristic. BUT each bit was measured IN ISOLATION, one swap into a baseline, so
# summing six of them is an ADDITIVE APPROXIMATION that ignores every interaction
# between parts. This reports build diversity UNDER AN ADDITIVE MODEL. It is
# decisive if the space collapses; if it does not, the question needs real fights.
const TOL := 0.05          # "near-optimal" = within 5% of the best achievable value
const SLOTS := ["HEAD", "ARM_L", "ARM_R", "LEGS", "BACK"]

func _initialize() -> void:
    var deltas := _load_deltas()
    if deltas.is_empty():
        print("BLOCKED: no mean_delta data in tools/sim/out/roster-post.json")
        quit(1); return

    var by_slot := {}
    var cores: Array = []
    for pd in Catalog.all():
        if pd.is_core:
            cores.append(pd)
            continue
        var s := String(pd.slot)
        if not by_slot.has(s):
            by_slot[s] = []
        (by_slot[s] as Array).append(pd)
    # arms are interchangeable in the rig, so both arm slots draw the same pool
    var arms: Array = (by_slot.get("ARM_L", []) as Array).duplicate()
    for pd in (by_slot.get("ARM_R", []) as Array):
        if not arms.has(pd): arms.append(pd)
    by_slot["ARM_L"] = arms
    by_slot["ARM_R"] = arms

    print("DECISION DENSITY  (additive model over measured mean_delta - see header)")
    print("%-26s %4s %8s   %s" % ["CORE", "CAP", "BEST", "distinct bits per slot within 5%"])
    var collapsed := 0
    var total_slots := 0
    for core in cores:
        var cap: int = 100 + int(core.get("carry") if core.get("carry") != null else 0)
        var res := _solve(by_slot, deltas, cap)
        var counts: Array = res["counts"]
        var line := ""
        for i in SLOTS.size():
            line += "%s:%d " % [SLOTS[i].substr(0, 4), int(counts[i])]
            total_slots += 1
            if int(counts[i]) <= 1: collapsed += 1
        print("%-26s %4d %8.3f   %s" % [String(core.display_name).substr(0, 26), cap, float(res["best"]), line])
    print("")
    print("slots that offer NO choice at 5%% tolerance: %d of %d" % [collapsed, total_slots])
    print("NOTE: additive approximation. Interactions between parts are NOT modelled.")
    quit(0)

func _load_deltas() -> Dictionary:
    var f := FileAccess.open("res://tools/sim/out/roster-post.json", FileAccess.READ)
    if f == null: return {}
    var data = JSON.parse_string(f.get_as_text())
    f.close()
    if typeof(data) != TYPE_DICTIONARY or not data.has("bits"): return {}
    var out := {}
    for b in data["bits"]:
        if typeof(b) == TYPE_DICTIONARY and b.has("id") and b.has("mean_delta"):
            out[String(b["id"])] = float(b["mean_delta"])
    return out

# Knapsack over the five slots. dp[w] = best value reachable using exactly the slots
# processed so far at total weight w. Then a backward sweep marks every bit that can
# appear in some build within TOL of the optimum.
func _solve(by_slot: Dictionary, deltas: Dictionary, cap: int) -> Dictionary:
    var layers := []
    for s in SLOTS:
        var opts := []
        for pd in (by_slot.get(s, []) as Array):
            opts.append({"id": String(pd.id), "w": int(pd.weight), "v": float(deltas.get(String(pd.id), 0.0))})
        layers.append(opts)

    var NEG := -1.0e9
    var dp := []            # dp[i][w] = best value using slots i.. onward within budget w
    for i in range(SLOTS.size() + 1):
        var row := []
        for w in range(cap + 1): row.append(NEG)
        dp.append(row)
    for w in range(cap + 1): dp[SLOTS.size()][w] = 0.0
    for i in range(SLOTS.size() - 1, -1, -1):
        for w in range(cap + 1):
            var best := NEG
            for o in layers[i]:
                var ow: int = o["w"]
                if ow <= w:
                    var cand: float = float(o["v"]) + float(dp[i + 1][w - ow])
                    if cand > best: best = cand
            dp[i][w] = best
    var optimum: float = dp[0][cap]
    var floor_v: float = optimum - absf(optimum) * TOL

    # forward sweep: which bits can start a build that still reaches the floor?
    var counts := []
    for i in SLOTS.size(): counts.append(0)
    var reach := {}         # weight -> value already spent, for slots before i
    reach[0] = 0.0
    for i in SLOTS.size():
        var seen := {}
        var nxt := {}
        for w in reach:
            var spent: float = float(reach[w])
            for o in layers[i]:
                var nw: int = int(w) + int(o["w"])
                if nw > cap: continue
                # dp is indexed by REMAINING budget, not by weight already spent
                var total: float = spent + float(o["v"]) + float(dp[i + 1][cap - nw])
                if total >= floor_v:
                    seen[o["id"]] = true
                    var acc: float = spent + float(o["v"])
                    if not nxt.has(nw) or float(nxt[nw]) < acc: nxt[nw] = acc
        counts[i] = seen.size()
        if seen.is_empty():
            push_error("slot %s reached no near-optimal bit - the sweep is broken, not the game" % SLOTS[i])
        reach = nxt
    return {"best": optimum, "counts": counts}
