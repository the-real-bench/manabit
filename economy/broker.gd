class_name Broker extends RefCounted
# Fettle's economy - pure pricing/roll logic, NO PlayerState writes.
# Scrap buys Coffers + COMMON Finds; Glimmer buys RARE/EPIC Finds. No conversion between them.

const TIN_PRICE := 40        # Scrap
const BRASS_PRICE := 100     # Scrap

# The Melt (forge-belly) -> Scrap
static func salvage_scrap(pd: PartData) -> int:
    match pd.rarity:
        "EPIC": return 45
        "RARE": return 20
        _: return 8

# The Still (back-still) -> Glimmer (commons hold no bound mana)
static func distill_glimmer(pd: PartData) -> int:
    match pd.rarity:
        "EPIC": return 3
        "RARE": return 1
        _: return 0

# Today's Finds price. Returns {currency: "scrap"|"glimmer", amount: int}.
static func find_price(pd: PartData) -> Dictionary:
    match pd.rarity:
        "EPIC": return {"currency": "glimmer", "amount": 10}
        "RARE": return {"currency": "glimmer", "amount": 4}
        _: return {"currency": "scrap", "amount": 25}

# Roll the 3-slot daily shelf: only DISCOVERED, non-core ids; prefer ones you own FEWER of
# (nudges toward completion). Seeded by the calendar day so it's stable all day.
static func roll_shelf(day_seed: int, compendium: Dictionary, owned_counts: Dictionary) -> Array:
    var rng := RandomNumberGenerator.new()
    rng.seed = day_seed * 2654435761
    var candidates := []
    for pd in Catalog.body_pool():
        var id := String(pd.id)
        if compendium.has(id):
            candidates.append(pd)
    if candidates.is_empty():
        return []
    # weighted pick without replacement: unowned weight 3, owned weight 1
    var out := []
    var pool := candidates.duplicate()
    var slots: int = min(3, pool.size())
    for s in slots:
        var total := 0.0
        for pd in pool:
            total += (3.0 if int(owned_counts.get(String(pd.id), 0)) == 0 else 1.0)
        var pick := rng.randf() * total
        var chosen: PartData = pool[0]
        for pd in pool:
            pick -= (3.0 if int(owned_counts.get(String(pd.id), 0)) == 0 else 1.0)
            if pick <= 0.0:
                chosen = pd
                break
        out.append({"id": String(chosen.id), "sold": false})
        pool.erase(chosen)
    return out
