extends SceneTree
# Catalog-integrity gate: the merged base+JSON catalog is large, valid, unique, and self-consistent.

func _initialize() -> void:
    var ok := true
    var all := Catalog.all()
    # pin raised 70 -> 95 with wave 2 (20 retro-hero bits; merged catalog is now 100)
    ok = _c("catalog is large (>=95)", all.size() >= 95) and ok

    var ids := {}
    var bad := 0
    var valid_rarity := {"COMMON": true, "RARE": true, "EPIC": true}
    for pd in all:
        var id := String(pd.id)
        if id == "" or ids.has(id):
            bad += 1
        ids[id] = true
        if pd.max_hp < 1 or String(pd.slot) == "" or not valid_rarity.has(String(pd.rarity)):
            bad += 1
    ok = _c("no duplicate / invalid bits", bad == 0) and ok

    var aff := {}
    for pd2 in Catalog.cores():
        if String(pd2.affinity) != "":
            aff[String(pd2.affinity)] = true
    ok = _c("cores span 3 affinities", aff.size() >= 3) and ok
    # pin raised 55 -> 85 with wave 2 (19 new body bits; body pool is now 89)
    ok = _c("body pool is deep (>=85)", Catalog.body_pool().size() >= 85) and ok

    var cat := Catalog.by_id()
    var miss := 0
    var chs := Challengers.list()
    for c in chs:
        for spec in c["loadout"]:
            if not cat.has(spec[1]):
                miss += 1
        # modifier swap lists (overgrown etc.) must resolve too - protects against catalog drift
        var mods: Dictionary = c.get("mods", {})
        for key in mods:
            for swap in mods[key]:
                if not cat.has(swap[1]):
                    miss += 1
    ok = _c("all challenger loadout ids resolve", miss == 0) and ok
    ok = _c("all 9 challenger entries + mod swap ids present", chs.size() == 9 and miss == 0) and ok

    # base fixtures still present (test/demo/dummy stability)
    var base := ["core_ember", "core_bulwark", "core_font", "arm_hammer", "head_optic", "legs_light", "arm_buckler"]
    var base_ok := true
    for b in base:
        if not cat.has(b):
            base_ok = false
    ok = _c("base fixtures preserved", base_ok) and ok

    print("SMOKE PASS" if ok else "SMOKE FAIL")
    quit(0 if ok else 1)

func _c(name: String, cond: bool) -> bool:
    print(("  [%s] " % ("PASS" if cond else "FAIL")) + name)
    return cond
