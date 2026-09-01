class_name PackRoller extends RefCounted
# Seedable Coffer roller.
#   Brass: 5 bits, ~70/22/8 common/rare/epic, GUARANTEED >=1 RARE+, epic-pity at 9.
#   Tin:   3 bits, own common-heavy ~85/12/3 table (keeps buy-Tin->Melt net-NEGATIVE; anti-arbitrage).

# The roll thresholds, named once. The printed odds on the coffer face and on
# Fettle's cartboard are DERIVED from these by odds_line() - never hand-copied -
# so a tuning pass cannot leave the label telling a lie the roll does not keep.
# Same law the run events already hold to (tests/smoke_run.gd:174, "printed odds
# match the threshold, verbatim").
const BRASS_COUNT := 5
const BRASS_RARE := 0.70    # below this = COMMON
const BRASS_EPIC := 0.92    # at or above this = EPIC
const TIN_COUNT := 3
const TIN_RARE := 0.85
const TIN_EPIC := 0.97

var _rng := RandomNumberGenerator.new()
var pity: int = 0   # opens since last EPIC

# The printed odds for a coffer kind, built from the thresholds above.
# Each figure carries its own unit so the line reads as three percentages
# rather than three bare numbers trailed by a stray glyph.
static func odds_line(kind: String) -> String:
    var brass := kind == "brass"
    var count := BRASS_COUNT if brass else TIN_COUNT
    var rare_t := BRASS_RARE if brass else TIN_RARE
    var epic_t := BRASS_EPIC if brass else TIN_EPIC
    var c := int(round(rare_t * 100.0))
    var e := int(round((1.0 - epic_t) * 100.0))
    var r := 100 - c - e
    var line := "%d bits · C%d%% R%d%% E%d%%" % [count, c, r, e]
    if brass:
        line += " · rare+ guaranteed"
    return line

func _init(seed_val: int = 0) -> void:
    if seed_val != 0:
        _rng.seed = seed_val
    else:
        _rng.randomize()

func roll_brass() -> Array[PartInstance]:
    return _roll(BRASS_COUNT, true, BRASS_RARE, BRASS_EPIC)

func roll_tin() -> Array[PartInstance]:
    return _roll(TIN_COUNT, false, TIN_RARE, TIN_EPIC)

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
