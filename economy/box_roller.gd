class_name BoxRoller extends RefCounted
# THE BOX OF SCRAP - the free kit's roll (team-ratified 2026-07-17). A crate of mismatched scrap
# you tip out and cobble a throwaway Manabit from. The GRADE (Dud→Gleaming) sets a sliding scale of
# power: a low roll gets you got, a high roll almost clears the run. Pure + seeded - the SAME seed
# always yields the SAME box (crack-and-see, no free re-roll). Builds a fresh ManabitState of fresh
# PartInstances and NEVER touches player.bits, so nothing it seats can be melted/looted/banked.
# §13 UNTOUCHED: all power variance is just which bits + how many sockets fill, from the live Catalog.

const GRADES := ["Dud", "Rough", "Fair", "Keen", "Gleaming"]
const FILL := [4, 4, 4, 5, 5]                                  # body bits seated (core is always +1)
const CENTER := ["COMMON", "COMMON", "RARE", "RARE", "EPIC"] # centerpiece-weapon rarity per grade
const RARE_START := [1.0, 0.85, 0.65, 0.40, 0.20]             # r < this -> COMMON
const EPIC_START := [1.0, 1.0, 0.95, 0.85, 0.65]             # r < this -> RARE, else EPIC
const FILL_ORDER := ["LEGS", "HEAD", "ARM_L", "ARM_R", "BACK"]

static func _grade_idx(g: float) -> int:
    if g < 0.12: return 0
    if g < 0.40: return 1
    if g < 0.72: return 2
    if g < 0.92: return 3
    return 4

# The grade WORD for a seed. Re-derives g as the FIRST rng draw off the seed - must match roll().
static func grade(seed: int) -> String:
    var rng := RandomNumberGenerator.new()
    rng.seed = seed
    return GRADES[_grade_idx(rng.randf())]

static func roll(seed: int) -> ManabitState:
    var rng := RandomNumberGenerator.new()
    rng.seed = seed
    var g := rng.randf()                                       # FIRST draw - grade() re-derives this
    var gi := _grade_idx(g)

    var m := ManabitState.new()
    for s in ManabitState.SLOT_NAMES:
        m.slots[s] = null

    # Core: a mid-or-better roll LENDS a stronger soul so the box can out-race a core-hunting boss
    # (Gleaming = Heirloom EPIC, Keen/Fair = Bastion RARE). Lent-only - it vanishes at run end, never
    # kept, never bindable, so The Binding faucet is untouched. D2 fix: Fair (the 32% modal first-box
    # roll) gains the RARE lend + a RARE centerpiece so it is RISKY-BUT-WINNABLE at the boss (~0.35
    # win) instead of a guaranteed loss; Dud/Rough keep the humble COMMON starter core and still die.
    var core_pd: PartData = null
    if gi == 4:
        core_pd = Catalog.box_core("EPIC")
    elif gi == 2 or gi == 3:
        core_pd = Catalog.box_core("RARE")
    if core_pd == null:
        var cores := Catalog.starter_cores()
        core_pd = cores[rng.randi_range(0, cores.size() - 1)]
    m.slots["CORE"] = PartInstance.new(core_pd)

    # Centerpiece weapon: the readable power cliff - this is what does (or doesn't) break armor.
    var filled := 0
    var cp := _pick_centerpiece(rng, CENTER[gi])
    if not cp.is_empty():
        m.slots[String(cp["slot"])] = PartInstance.new(cp["pd"])
        filled += 1

    # Fill remaining body sockets in fixed priority up to the grade's fill count.
    for slot in FILL_ORDER:
        if filled >= FILL[gi]:
            break
        if m.slots[slot] != null:
            continue
        var rarity := _roll_rarity(rng, gi)
        var pd := _pick_slot(slot, rarity, rng)
        if pd != null:
            m.slots[slot] = PartInstance.new(pd)
            filled += 1

    # Safety: a box must always be able to fight (never should trip - centerpiece is offensive).
    if not m.has_offensive_move():
        var fb := _pick_slot("ARM_R", "COMMON", rng)
        if fb != null:
            m.slots["ARM_R"] = PartInstance.new(fb)
    return m

static func _roll_rarity(rng: RandomNumberGenerator, gi: int) -> String:
    var r := rng.randf()
    if r < float(RARE_START[gi]):
        return "COMMON"
    if r < float(EPIC_START[gi]):
        return "RARE"
    return "EPIC"

static func _degrade(rarity: String) -> Array:
    match rarity:
        "EPIC": return ["EPIC", "RARE", "COMMON"]
        "RARE": return ["RARE", "COMMON"]
        _: return ["COMMON"]

# The weapon that sets the box's punch. Prefer a real ARM weapon (ARM_R>ARM_L) at the grade's
# rarity; only fall to an offensive HEAD if no arm weapon exists at that rarity. Degrade rarity last.
# A GUARANTEED hard-hitter: among the offensive bits at the rarity, keep only the top-power ones.
static func _pick_centerpiece(rng: RandomNumberGenerator, rarity: String) -> Dictionary:
    for rr in _degrade(rarity):
        var arms := _offensive_pool(rr, ["ARM_L", "ARM_R"])
        if not arms.is_empty():
            return {"slot": "ARM_R", "pd": _strongest(arms, rng)}
        var heads := _offensive_pool(rr, ["HEAD"])
        if not heads.is_empty():
            return {"slot": "HEAD", "pd": _strongest(heads, rng)}
    return {}

static func _strongest(pool: Array, rng: RandomNumberGenerator) -> PartData:
    var maxp := 0
    for pd in pool:
        maxp = maxi(maxp, pd.ability.power)
    var top := []
    for pd in pool:
        if pd.ability.power >= maxp - 1:      # the top tier, with a little variety
            top.append(pd)
    return top[rng.randi_range(0, top.size() - 1)]

static func _offensive_pool(rarity: String, slots: Array) -> Array:
    var pool := []
    for pd in Catalog.body_pool():
        if pd.rarity != rarity:
            continue
        var ab = pd.ability
        if ab == null or ab.archetype == "GUARD" or ab.archetype == "NONE":
            continue
        if pd.slot in slots:
            pool.append(pd)
    return pool

# A bit for a socket at rarity, degrading rarity until one exists (COMMON always does per slot).
static func _pick_slot(slot: String, rarity: String, rng: RandomNumberGenerator) -> PartData:
    for rr in _degrade(rarity):
        var pool := []
        for pd in Catalog.body_pool():
            if _fits(slot, pd) and pd.rarity == rr:
                pool.append(pd)
        if not pool.is_empty():
            return pool[rng.randi_range(0, pool.size() - 1)]
    return null

static func _fits(slot: String, pd: PartData) -> bool:
    if slot == "ARM_L" or slot == "ARM_R":
        return pd.slot == "ARM_L" or pd.slot == "ARM_R"
    return pd.slot == slot
