extends SceneTree
# Economy / Broker gate: prices, faucets, sinks, anti-arbitrage, in-place refs, v2 + v1 migration.

const DAY := 20300

func _initialize() -> void:
    var ok := true

    # --- starter kit seeds ---
    var p := PlayerState.new()
    p.grant_starter_kit()
    ok = _c("starter scrap = 50", p.scrap == 50) and ok
    ok = _c("starter coffers tin1/brass2", int(p.coffers["tin"]) == 1 and int(p.coffers["brass"]) == 2) and ok
    ok = _c("coffer_count = 3", p.coffer_count() == 3) and ok

    # --- buy a coffer (scrap sink) ---
    var before_scrap := p.scrap
    ok = _c("buy tin ok", p.buy_coffer("tin")) and ok
    ok = _c("tin cost 40", p.scrap == before_scrap - 40) and ok
    ok = _c("tin count up", int(p.coffers["tin"]) == 2) and ok
    p.scrap = 10
    ok = _c("cant afford brass", not p.buy_coffer("brass")) and ok

    # --- open a coffer (faucet) mutates bits IN PLACE ---
    var ref := p.bits                 # capture the SAME array reference
    var n0 := p.bits.size()
    var rolled := p.open_coffer("brass")
    ok = _c("brass opened 5 bits", rolled.size() == 5) and ok
    ok = _c("bits grew in place", p.bits.size() == n0 + 5 and p.bits == ref) and ok

    # --- the Melt: salvage a common -> scrap ---
    var common := _first(p, "COMMON", false)
    if common != null:
        var s0 := p.scrap
        var g := p.melt_bit(common)
        ok = _c("melt common = 8 scrap", g == 8 and p.scrap == s0 + 8) and ok
        ok = _c("melted bit gone", not p.bits.has(common)) and ok
    # cores refuse to melt
    var core := _first(p, "", true)
    ok = _c("core cannot melt", p.melt_bit(core) == 0 and p.bits.has(core)) and ok

    # --- the Still: distill a rare/epic -> glimmer (commons yield 0) ---
    p.bits.append(PartInstance.new(Catalog.by_id()["arm_seer"]))   # EPIC
    var epic := _first(p, "EPIC", false)
    var gl0 := p.glimmer
    ok = _c("distill epic = 3 glimmer", p.distill_bit(epic) == 3 and p.glimmer == gl0 + 3) and ok

    # --- anti-arbitrage: buying a Tin then melting it back is NET NEGATIVE ---
    ok = _c("tin buy>melt (no arbitrage)", _tin_melt_value() < Broker.TIN_PRICE) and ok

    # --- Today's Finds: discovered-only, buy deducts correct currency ---
    p.scrap = 100                     # ensure affordable for the common-Find assertion
    p.refresh_broker(DAY)
    ok = _c("shelf has finds", p.broker_shelf.size() >= 1) and ok
    var idx := _find_common_slot(p)
    if idx >= 0:
        var sc0 := p.scrap
        var bought := p.buy_find(idx)
        ok = _c("buy common Find -25 scrap", bought != null and p.scrap == sc0 - 25) and ok
        ok = _c("find slot marked sold", bool(p.broker_shelf[idx]["sold"])) and ok

    # --- Doorstep Coffer: once per day ---
    var t0 := int(p.coffers["tin"])
    ok = _c("doorstep claim adds tin", p.claim_doorstep(DAY) and int(p.coffers["tin"]) == t0 + 1) and ok
    ok = _c("doorstep same day blocked", not p.claim_doorstep(DAY)) and ok
    ok = _c("doorstep next day ok", p.claim_doorstep(DAY + 1)) and ok

    # --- save v2 roundtrip ---
    p.save()
    var q := PlayerState.new()
    SaveManager.load_into(q)
    ok = _c("v2 glimmer roundtrip", q.glimmer == p.glimmer) and ok
    ok = _c("v2 typed coffers roundtrip", q.coffer_count() == p.coffer_count()) and ok
    ok = _c("v2 gift/shelf day roundtrip", q.last_gift_day == p.last_gift_day and q.last_shelf_day == p.last_shelf_day) and ok

    # --- v1 -> v2 migration (old int coffers) ---
    _write_v1_save()
    var r := PlayerState.new()
    SaveManager.load_into(r)
    ok = _c("v1 int coffers migrate to brass", int(r.coffers["brass"]) == 3 and int(r.coffers["tin"]) == 0) and ok
    ok = _c("v1 glimmer defaults 0", r.glimmer == 0) and ok

    # --- printed coffer odds match the roll, verbatim ---
    # Same law the run events hold to (smoke_run.gd T4). The label is DERIVED from
    # PackRoller's thresholds, so this asserts the derivation, not a copied string:
    # retune a threshold and the printed line must move with it or this goes red.
    for kind: String in ["tin", "brass"]:
        var brass: bool = kind == "brass"
        var rare_t: float = PackRoller.BRASS_RARE if brass else PackRoller.TIN_RARE
        var epic_t: float = PackRoller.BRASS_EPIC if brass else PackRoller.TIN_EPIC
        var count: int = PackRoller.BRASS_COUNT if brass else PackRoller.TIN_COUNT
        var line := PackRoller.odds_line(kind)
        var c := int(round(rare_t * 100.0))
        var e := int(round((1.0 - epic_t) * 100.0))
        ok = _c("%s odds: common %d%% printed" % [kind, c], line.contains("C%d%%" % c)) and ok
        ok = _c("%s odds: rare %d%% printed" % [kind, 100 - c - e], line.contains("R%d%%" % (100 - c - e))) and ok
        ok = _c("%s odds: epic %d%% printed" % [kind, e], line.contains("E%d%%" % e)) and ok
        ok = _c("%s odds: bit count printed" % kind, line.begins_with("%d bits" % count)) and ok
        # the three figures must sum to 100 - a label that does not add up is a lie
        ok = _c("%s odds sum to 100" % kind, c + (100 - c - e) + e == 100) and ok
        # every figure carries its own unit: no bare trailing %% governing at a distance
        ok = _c("%s odds: no stray trailing unit" % kind,
                line.count("%") == 3 and not line.contains(" %")) and ok

    # --- EMPIRICAL: does the printed line match what the coffer actually rolls? ---
    # The assertions above are structural - label and threshold are derived from the
    # same constant, so they cannot disagree and cannot go red. This one can. Tin has
    # no rare+ guarantee and no pity, so its realized mix IS its base rate and is a
    # true independent check: retune TIN_RARE without the label following and this
    # fails. (Brass is deliberately NOT asserted here: its pity-at-9 drives realized
    # EPIC to ~14.8%% against a printed 8%% - see loop/backlog.json L-15, which is
    # entangled with the unpersisted pity counter, D5, and is owner-gated.)
    var probe := PackRoller.new(20260711)
    var tally := {"COMMON": 0, "RARE": 0, "EPIC": 0}
    var bits := 0
    for i in range(4000):
        for pi in probe.roll_tin():
            tally[pi.data.rarity] = int(tally[pi.data.rarity]) + 1
            bits += 1
    var printed_c := int(round(PackRoller.TIN_RARE * 100.0))
    var printed_e := int(round((1.0 - PackRoller.TIN_EPIC) * 100.0))
    var real_c := 100.0 * float(tally["COMMON"]) / float(bits)
    var real_e := 100.0 * float(tally["EPIC"]) / float(bits)
    ok = _c("tin printed COMMON %d%% matches rolled %.1f%% (+/-2pp)" % [printed_c, real_c],
            absf(real_c - float(printed_c)) <= 2.0) and ok
    ok = _c("tin printed EPIC %d%% matches rolled %.1f%% (+/-2pp)" % [printed_e, real_e],
            absf(real_e - float(printed_e)) <= 2.0) and ok
    ok = _c("brass prints its rare+ guarantee", PackRoller.odds_line("brass").contains("rare+ guaranteed")) and ok
    ok = _c("tin claims no guarantee it does not keep", not PackRoller.odds_line("tin").contains("guaranteed")) and ok

    # --- the pity promise is DERIVED from the rule, and tin makes no claim ---
    # Brass realized EPIC runs ~14.8%% against a printed 8%% because of pity-at-9
    # (measured, tools/sim/odds_probe.gd). The gap is owner-gated on save v5 (D5,
    # pity is not persisted), so what ships now is disclosure of the mechanism.
    # This asserts the WORDS track the CONSTANT: change BRASS_PITY without the copy
    # following and this goes red.
    ok = _c("brass discloses its pity at the real threshold",
            PackRoller.pity_line("brass").contains("%d bits" % PackRoller.BRASS_PITY)) and ok
    ok = _c("tin promises no pity it does not have", PackRoller.pity_line("tin") == "") and ok

    print("SMOKE PASS" if ok else "SMOKE FAIL")
    quit(0 if ok else 1)

func _tin_melt_value() -> float:
    # expected melt value of a Tin (3 bits @ ~85/12/3) vs its 40 price
    return 3.0 * (0.85 * 8.0 + 0.12 * 20.0 + 0.03 * 45.0)

func _first(p: PlayerState, rarity: String, want_core: bool) -> PartInstance:
    for pi in p.bits:
        if pi.data.is_core != want_core:
            continue
        if rarity == "" or pi.data.rarity == rarity:
            return pi
    return null

func _find_common_slot(p: PlayerState) -> int:
    for i in p.broker_shelf.size():
        var pd = Catalog.by_id().get(String(p.broker_shelf[i]["id"]))
        if pd != null and pd.rarity == "COMMON":
            return i
    return -1

func _write_v1_save() -> void:
    var v1 := {"version": 1, "scrap": 12, "coffers": 3, "loose_bits": [], "garage": [], "compendium": ["arm_hammer"]}
    var f := FileAccess.open(SaveManager.PATH, FileAccess.WRITE)
    f.store_string(JSON.stringify(v1))
    f.close()

func _c(name: String, cond: bool) -> bool:
    print(("  [%s] " % ("PASS" if cond else "FAIL")) + name)
    return cond
