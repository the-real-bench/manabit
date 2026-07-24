class_name Catalog extends RefCounted
# The bit catalog. BASE bits (hardcoded, stable - tests/demo/dummy reference these exact ids/stats)
# are merged with the large team-authored catalog loaded from res://parts/catalog_extra.json.
# Base wins on any id collision (keeps the starter cores + smoke-test fixtures deterministic).

const EXTRA_PATH := "res://parts/catalog_extra.json"

static var _all_cache: Array = []
static var _by_id_cache: Dictionary = {}

static func _ab(arch: String, power: int, hits: int, guard: int, cost: int) -> AbilityData:
    var a := AbilityData.new()
    a.archetype = arch
    a.power = power
    a.hit_count = hits
    a.guard_amount = guard
    a.mana_cost = cost
    a.display_name = arch.capitalize()
    return a

static func _part(id: String, name: String, slot: String, rarity: String, hp: int, atk: int, df: int, spd: int, wt: int, en: int, ab: AbilityData, is_core: bool = false, affinity: String = "") -> PartData:
    var p := PartData.new()
    p.id = id
    p.display_name = name
    p.slot = slot
    p.rarity = rarity
    p.max_hp = hp
    p.attack = atk
    p.defense = df
    p.speed = spd
    p.weight = wt
    p.energy = en
    p.ability = ab
    p.is_core = is_core
    p.affinity = affinity
    return p

# The 3 starter cores (one per affinity) - never come from Coffers; the Apprentice's Kit grant.
static func starter_cores() -> Array:
    var out := [
        _part("core_ember",   "Ember Core",   "CORE", "COMMON", 30, 2, 1, 2, 12,  8, null, true, "attack"),
        _part("core_bulwark", "Bulwark Core", "CORE", "COMMON", 34, 1, 3, 1, 16,  6, null, true, "defense"),
        _part("core_font",    "Font Core",    "CORE", "COMMON", 28, 1, 1, 2, 10, 12, null, true, "mana"),
    ]
    out[1].carry = 6   # Bulwark carries +6 (capacity 106) - the sturdy soul takes more on its back
    return out

# Lent-only cores for a TOP-grade Box of Scrap (Keen/Gleaming). Deliberately OUTSIDE the registry:
# not in all()/by_id(), not bindable (BINDABLE_CORES), not in coffers/shelf (body_pool), not in the
# dex. They exist only inside a rolled box and vanish when the run ends - never enter player.bits,
# never kept. Distinct ids/names from the canonical Sovereign Brass "Regalia Core" (a dex bit) - a
# god-roll lends a lucky salvaged soul, not the king's own.
static func box_core(rarity: String) -> PartData:
    var p: PartData = null
    match rarity:
        "EPIC":
            p = _part("core_heirloom", "Heirloom Core", "CORE", "EPIC", 80, 5, 4, 2, 18, 18, null, true, "attack")
            p.carry = 15   # the god-roll ceiling (capacity 115) - sim-gated
        "RARE":
            p = _part("core_bastion",  "Bastion Core",  "CORE", "RARE", 54, 3, 3, 1, 16, 12, null, true, "defense")
            p.carry = 8
    return p

# Base body bits - the smoke-test / demo / dummy fixtures. Kept exact for determinism.
static func _base_body() -> Array:
    return [
        _part("head_optic",   "Optic Visor",    "HEAD",  "COMMON",  8, 2, 1, 2,  8, 2, _ab("SINGLE", 3, 1, 0, 1)),
        _part("head_hornet",  "Hornet Crown",   "HEAD",  "RARE",    7, 1, 0, 4,  6, 3, _ab("MULTI",  2, 3, 0, 2)),
        _part("arm_hammer",   "Iron Hammer",    "ARM_L", "COMMON", 10, 6, 0, 1, 40, 0, _ab("SINGLE", 5, 1, 0, 1)),
        _part("arm_flail",    "Chain Flail",    "ARM_L", "RARE",    8, 4, 0, 2, 30, 0, _ab("MULTI",  3, 3, 0, 2)),
        _part("arm_buckler",  "Rune Buckler",   "ARM_R", "COMMON", 12, 1, 4, 0, 26, 2, _ab("GUARD",  0, 1, 4, 2)),
        _part("arm_seer",     "Seer Gauntlet",  "ARM_R", "EPIC",    9, 3, 1, 2, 20, 5, _ab("SINGLE", 6, 1, 0, 2)),
        _part("legs_light",   "Sprinter Legs",  "LEGS",  "COMMON", 10, 0, 1, 6, 28, 0, null),
        _part("legs_tread",   "Tread Legs",     "LEGS",  "RARE",   16, 0, 3, 2, 44, 0, null),
        _part("back_bellows", "Mana Bellows",   "BACK",  "COMMON",  8, 0, 0, 1, 18, 8, _ab("GUARD",  0, 0, 3, 1)),
        _part("back_wing",    "Glider Wing",    "BACK",  "EPIC",    7, 1, 1, 5, 12, 4, null),
    ]

static func _build_all() -> Array:
    var out := []
    var seen := {}
    for pd in starter_cores():
        pd.family = "artificer_first"
        out.append(pd)
        seen[String(pd.id)] = true
    for pd2 in _base_body():
        pd2.family = "baseline"
        out.append(pd2)
        seen[String(pd2.id)] = true
    if FileAccess.file_exists(EXTRA_PATH):
        var raw := FileAccess.get_file_as_string(EXTRA_PATH)
        if raw.length() > 0 and raw.unicode_at(0) == 0xFEFF:
            raw = raw.substr(1)
        var data = JSON.parse_string(raw)
        if typeof(data) == TYPE_ARRAY:
            for d in data:
                if typeof(d) != TYPE_DICTIONARY:
                    continue
                var id := String(d.get("id", ""))
                if id == "" or seen.has(id):
                    continue
                seen[id] = true
                out.append(_from_dict(d))
    return out

static func _from_dict(d: Dictionary) -> PartData:
    var p := PartData.new()
    p.id = String(d.get("id", ""))
    p.display_name = String(d.get("name", ""))
    p.slot = String(d.get("slot", "HEAD"))
    p.rarity = String(d.get("rarity", "COMMON"))
    p.max_hp = int(d.get("max_hp", 1))
    p.attack = int(d.get("attack", 0))
    p.defense = int(d.get("defense", 0))
    p.speed = int(d.get("speed", 0))
    p.weight = int(d.get("weight", 0))
    p.energy = int(d.get("energy", 0))
    p.carry = int(d.get("carry", 0))    # int() wrap: JSON numbers arrive as floats (TD condition 2)
    p.is_core = bool(d.get("is_core", false))
    p.affinity = String(d.get("affinity", ""))
    p.family = String(d.get("family", ""))
    var ab = d.get("ability", null)
    if typeof(ab) == TYPE_DICTIONARY and String(ab.get("archetype", "NONE")) != "NONE":
        var a := AbilityData.new()
        a.archetype = String(ab.get("archetype", "SINGLE"))
        a.power = int(ab.get("power", 0))
        a.hit_count = maxi(1, int(ab.get("hit_count", 1)))
        a.guard_amount = int(ab.get("guard_amount", 0))
        a.guard_kind = String(ab.get("guard_kind", "DEF_BUFF"))
        a.mana_cost = int(ab.get("mana_cost", 0))
        a.can_target_core = bool(ab.get("can_target_core", true))
        a.display_name = a.archetype.capitalize()
        p.ability = a
    return p

static func all() -> Array:
    if _all_cache.is_empty():
        _all_cache = _build_all()
    return _all_cache

static func by_id() -> Dictionary:
    if _by_id_cache.is_empty():
        for pd in all():
            _by_id_cache[String(pd.id)] = pd
    return _by_id_cache

static func body_pool() -> Array:
    var out := []
    for pd in all():
        if not pd.is_core:
            out.append(pd)
    return out

static func cores() -> Array:
    var out := []
    for pd in all():
        if pd.is_core:
            out.append(pd)
    return out
