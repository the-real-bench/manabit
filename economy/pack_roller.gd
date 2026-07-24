class_name PackRoller extends RefCounted
# Seedable Coffer roller.
#   Brass: 5 bits, ~70/22/8 common/rare/epic, GUARANTEED >=1 RARE+, epic-pity at 9.
#   Tin:   3 bits, own common-heavy ~85/12/3 table (keeps buy-Tin->Melt net-NEGATIVE; anti-arbitrage).

var _rng := RandomNumberGenerator.new()
var pity: int = 0   # opens since last EPIC

func _init(seed_val: int = 0) -> void:
    if seed_val != 0:
        _rng.seed = seed_val
    else:
        _rng.randomize()

func roll_brass() -> Array[PartInstance]:
    return _roll(5, true, 0.70, 0.92)

func roll_tin() -> Array[PartInstance]:
    return _roll(3, false, 0.85, 0.97)

func _roll(count: int, guarantee_rare: bool, rare_thresh: float, epic_thresh: float) -> Array[PartInstance]:
    var pool := Catalog.body_pool()
    var out: Array[PartInstance] = []
    var got_rare := false
    for i in range(count):
        var force_epic := guarantee_rare and pity >= 9
        var pd := _pick(pool, force_epic, rare_thresh, epic_thresh)
        if pd.rarity != "COMMON":
            got_rare = true
        if pd.rarity == "EPIC":
            pity = 0
        elif guarantee_rare:
            pity += 1
        out.append(PartInstance.new(pd))
    if guarantee_rare and not got_rare and out.size() > 0:
        out[_rng.randi_range(0, out.size() - 1)] = PartInstance.new(_pick_min_rare(pool))
    return out

func _pick(pool: Array, force_epic: bool, rare_thresh: float, epic_thresh: float) -> PartData:
    if force_epic:
        return _by_rarity(pool, "EPIC")
    var r := _rng.randf()
    var rarity := "COMMON"
    if r > epic_thresh:
        rarity = "EPIC"
    elif r > rare_thresh:
        rarity = "RARE"
    return _by_rarity(pool, rarity)

func _by_rarity(pool: Array, rarity: String) -> PartData:
    var matches := []
    for pd in pool:
        if pd.rarity == rarity:
            matches.append(pd)
    if matches.is_empty():
        matches = pool
    return matches[_rng.randi_range(0, matches.size() - 1)]

func _pick_min_rare(pool: Array) -> PartData:
    var matches := []
    for pd in pool:
        if pd.rarity != "COMMON":
            matches.append(pd)
    if matches.is_empty():
        matches = pool
    return matches[_rng.randi_range(0, matches.size() - 1)]
