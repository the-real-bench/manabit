class_name RunState extends RefCounted
# A run: carry ONE Manabit down a fixed 5-step spine with two 2-way junctions. Damage PERSISTS
# across fights (no auto-heal); repair costs scrap at rests; extraction banks the survivor to the
# Menagerie; core-death ends the run and loses the carried construct (§5/§7/§12.5).
# THE ROAD (team-ratified branching map): steps are pos 0 FIGHT skirmish (always clean Rusty) ->
# pos 1 REST -> pos 2 JUNCTION elite -> pos 3 REST -> pos 4 JUNCTION boss. A JUNCTION collapses
# IN PLACE via choose(i) into its chosen lane's plain FIGHT node (modifier, lane_name, and
# road_not_taken stamped on). No procedural generation - exactly 2 hand-authored templates,
# deep-copied per run; the run seed picks one. Runs stay session-local; the map dies with this.

const REPAIR_PER_2HP := 1

# Hand-authored map templates. "ch" is an INDEX into Challengers.list() - ch[0..4] are frozen,
# the roster is append-only. Every route has exactly ONE fight of each tier (purse cap invariant);
# junction lanes never share a challenger, style family, or modifier id; second_wind never rides
# a boss lane; the boss junction is always Brassmore vs Gildfall with modifiers rotating.
# REST flavors (wave 3): pos1 carries the road's flavor beat - the Wayside Shrine (event) on
# The Old Road, Magpie's Heap (scrapyard) on The Quiet Spiral. The pos3 REST is ALWAYS
# "The Last Lantern", a plain camp, on every template, present and future - the final exit is
# a promise the map makes from node 0. A flavored rest still repairs and still extracts:
# node()/advance()/at_rest()/can_extract() are byte-identical code (frozen law).
const TEMPLATES := [
    {
        "name": "The Old Road",
        "steps": [
            {"type": "FIGHT", "label": "Skirmish", "tier": "skirmish", "ch": 0},
            {"type": "REST", "label": "Wayside Shrine", "flavor": "event"},
            {"type": "JUNCTION", "label": "The Road Forks", "tier": "elite", "paths": [
                {"lane_name": "Bramble Cut", "mod": "overgrown", "ch": 5},
                {"lane_name": "Wardens Wall", "mod": "second_wind", "ch": 3},
            ]},
            {"type": "REST", "label": "The Last Lantern", "flavor": "camp"},
            {"type": "JUNCTION", "label": "The Road Forks", "tier": "boss", "paths": [
                {"lane_name": "Gilded Gate", "mod": "tailwind", "ch": 4},
                {"lane_name": "Heralds Walk", "mod": "rusted", "ch": 8},
            ]},
        ],
    },
    {
        "name": "The Quiet Spiral",
        "steps": [
            {"type": "FIGHT", "label": "Skirmish", "tier": "skirmish", "ch": 0},
            {"type": "REST", "label": "Magpie's Heap", "flavor": "scrapyard"},
            {"type": "JUNCTION", "label": "The Road Forks", "tier": "elite", "paths": [
                {"lane_name": "Powder Row", "mod": "second_wind", "ch": 6},
                {"lane_name": "Silk Stair", "mod": "rusted", "ch": 7},
            ]},
            {"type": "REST", "label": "The Last Lantern", "flavor": "camp"},
            {"type": "JUNCTION", "label": "The Road Forks", "tier": "boss", "paths": [
                {"lane_name": "Gilded Gate", "mod": "rusted", "ch": 4},
                {"lane_name": "Heralds Walk", "mod": "tailwind", "ch": 8},
            ]},
        ],
    },
]

# THE BOX OF SCRAP - the free kit (team-ratified 2026-07-17). A ROLLED crate (economy/box_roller.gd):
# the grade sets a sliding scale of power (Dud→Gleaming). Built fresh each run from a seed; its
# gatherings ride the run-local satchel and only flush to the player at a safe run end.
const KIT_NAME := "Box of Scrap"

var carried: ManabitState
var mname := "Manabit"
var map: Array = []
var pos: int = 0
var over := false
var banked := false
var is_kit := false                  # a Box outing: free repairs, no extract, satchel economy
var kit_seed := 0                    # the seed this box was rolled from (reveal/run parity)
var road_seed := 0                   # session-local map seed - shrine/heap draws derive from it
var satchel_scrap := 0               # purses gathered this run (spills on DEATH)
var satchel_bit_id := ""             # the one COMMON bit a run may tuck away (foe-looted only)
var next_fight_rider := 0            # shrine "next foe worn N" rider - session-local, one bell only
var second_wind_pad := 0             # D12 core pad banked by a second_wind lane WIN, next bell only
var heap_rummaged := false           # Magpie's Heap once-per-run latch (session-local)

func start(build: ManabitState, name: String) -> void:
    carried = _clone(build)          # the run owns a copy; the bench build is spent on venturing
    mname = name
    road_seed = randi()              # stored session-local (shrine parity) - runs die with the session
    map = _make_map(road_seed)       # fresh road each venture
    pos = 0
    over = false
    banked = false

func start_kit(seed: int) -> void:
    carried = kit_build(seed)        # a rolled box - consumes NO player core, touches NO bench
    mname = KIT_NAME
    is_kit = true
    kit_seed = seed
    road_seed = seed
    satchel_scrap = 0
    satchel_bit_id = ""
    map = _make_map(seed)            # crack parity: same nonce = same box = same road (anti-scum)
    pos = 0
    over = false
    banked = false

# A one-off Manabit cobbled from a rolled Box of Scrap. Fresh instances, NEVER appended to
# player.bits - its bits can't be melted, looted, banked, or cannibalized, by construction.
static func kit_build(seed: int) -> ManabitState:
    return BoxRoller.roll(seed)

# Expand one template into a live map. Deep-copies everything (Challengers.list() already returns
# fresh dicts per call; modifier dicts are duplicated from RunMods.TABLE) - consts never mutate.
func _make_map(map_seed: int) -> Array:
    var ch := Challengers.list()
    var t: Dictionary = TEMPLATES[abs(map_seed) % TEMPLATES.size()]
    var out: Array = []
    for step in t["steps"]:
        var s: Dictionary = step
        var stype := String(s["type"])
        if stype == "REST":
            # A flavored rest is still a REST - flavor payload is stamped at map-make, seeded
            # off the map seed (crack-and-see parity: same box = same road = same shrine/heap).
            var flavor := String(s.get("flavor", "camp"))
            var rest := {"type": "REST", "label": String(s["label"]), "flavor": flavor}
            if flavor == "event":
                var pick := RunEvents.pick(map_seed)
                rest["event_id"] = String(pick["event_id"])
                rest["roll"] = int(pick["roll"])       # hidden result, DECIDED here, revealed on choice
                rest["resolved"] = false
            elif flavor == "scrapyard":
                var dig := RunEvents.heap_dig(map_seed)
                rest["dig"] = int(dig["r1"])           # outcome band, decided here, revealed on commit
                rest["dig_pick"] = int(dig["r2"])      # lend pick within the discovered-first pool
                rest["rummaged"] = false
            out.append(rest)
        elif stype == "FIGHT":
            # spine fight = pos 0 skirmish: always clean, never aims the core, never branched
            var idx: int = s["ch"]
            out.append({"type": "FIGHT", "label": String(s["label"]), "tier": String(s["tier"]),
                "challenger": ch[idx], "aims_core": false, "boss": false, "modifier": {}})
        else:   # JUNCTION
            var tier := String(s["tier"])
            var paths: Array = []
            for lane in s["paths"]:
                var ln: Dictionary = lane
                var mod: Dictionary = RunMods.TABLE[String(ln["mod"])]
                var lidx: int = ln["ch"]
                paths.append({
                    "lane_name": String(ln["lane_name"]),
                    "modifier": mod.duplicate(true),
                    "node": {"type": "FIGHT", "label": String(ln["lane_name"]), "tier": tier,
                        "challenger": ch[lidx], "aims_core": true, "boss": tier == "boss",
                        "modifier": {}},
                })
            out.append({"type": "JUNCTION", "label": String(s["label"]), "tier": tier, "paths": paths})
    return out

func node() -> Dictionary:
    return map[pos] if pos < map.size() else {}

# --- The junction (collapse-in-place) ---------------------------------------------------------

func at_junction() -> bool:
    return String(node().get("type", "")) == "JUNCTION"

func choices() -> Array:
    return node().get("paths", []) if at_junction() else []

# Commit to lane i: replace map[pos] IN PLACE with the chosen lane's plain FIGHT node, stamping
# modifier, lane_name, and road_not_taken (the other lane's name - render-only, honest history).
# No-op unless at a junction with a valid lane index; the choice is irreversible.
func choose(i: int) -> void:
    if not at_junction():
        return
    var paths: Array = node()["paths"]
    if i < 0 or i >= paths.size():
        return
    var pick: Dictionary = paths[i]
    var other: Dictionary = paths[(i + 1) % paths.size()]
    var nd: Dictionary = pick["node"]
    nd["modifier"] = pick["modifier"]
    nd["lane_name"] = String(pick["lane_name"])
    nd["road_not_taken"] = String(other["lane_name"])
    map[pos] = nd

func advance() -> void:
    pos += 1
    if pos >= map.size():
        over = true

func alive() -> bool:
    return carried != null and carried.alive()

func at_rest() -> bool:
    return node().get("type", "") == "REST"

func can_extract() -> bool:
    return not is_kit and not over and alive() and pos >= 1 and at_rest()   # Trundle is never yours to bank

func repair_cost() -> int:
    var miss := 0
    for slot in ManabitState.SLOT_NAMES:
        var pi: PartInstance = carried.slots.get(slot)
        if pi != null:
            miss += pi.data.max_hp - pi.current_hp
    return int(ceil(float(miss) / 2.0)) * REPAIR_PER_2HP

func is_damaged() -> bool:
    return repair_cost() > 0

func repair_all() -> void:
    for slot in ManabitState.SLOT_NAMES:
        var pi: PartInstance = carried.slots.get(slot)
        if pi != null:
            pi.current_hp = pi.data.max_hp
            pi.disabled = false

# --- The shrine rider (wave 3, spec 2.5) ------------------------------------------------------
# Consume the "next foe worn N" rider at the pre-bell seam. One fight only - reading it clears
# it, so it can never leak past the run or into bouts. Capped at RunMods.WEAR (2): a rider can
# never out-wear a rusted lane. MAX-NOT-SUM vs the lane modifier is applied in Challengers.make.

func take_fight_rider() -> int:
    var r: int = clampi(next_fight_rider, 0, RunMods.WEAR)
    next_fight_rider = 0
    return r

# --- The Gleaner's Due (wave 3, spec 4) -------------------------------------------------------
# HP-scaled death salvage. Ordering law: SAFE END > DEEP DEATH > SHALLOW DEATH, with a
# guaranteed sting - death never keeps more than floor(S/2) (the formula proves it: K <= 0.5
# and the H-blend <= 1). Run-death credit ONLY - bouts keep the CH-08/CH-09 forfeit-pays-zero
# law (resolve paths for The Run are the only callers, and must stay so).

const GLEAN_K := {"boss": 0.50, "elite": 0.25}       # kit satchel keep (G8; skirmish fail-safe 0)
const GLEAN_K_OWN := {"boss": 0.25, "elite": 0.125}  # own wreck - K halved (G9 out-of-band action)

static func gleaners_kept(satchel: int, tier: String, h: float) -> int:
    var k: float = float(GLEAN_K.get(tier, 0.0))
    return int(floor(float(satchel) * k * (0.5 + 0.5 * clampf(h, 0.0, 1.0))))

# H = remaining-HP fraction of the surviving non-core body bits at death. The core pays 0 -
# Fettle won't melt a bound soul (consistent with the Still/Melt rules).
static func death_h(m: ManabitState) -> float:
    var cur := 0
    var mx := 0
    for slot in ManabitState.SLOT_NAMES:
        var pi: PartInstance = m.slots.get(slot)
        if pi == null or pi.data.is_core or pi.disabled or pi.current_hp <= 0:
            continue
        cur += pi.current_hp
        mx += pi.data.max_hp
    return (float(cur) / float(mx)) if mx > 0 else 0.0

# Own-build wreck: floor(K * sum(salvage * hp_frac)) over surviving non-core body bits.
# wreck <= half the home-melt of the same bits, so suiciding a build stays dominated by
# melting at home; extraction keeps everything and strictly dominates both.
static func gleaners_wreck(m: ManabitState, tier: String) -> int:
    var k: float = float(GLEAN_K_OWN.get(tier, 0.0))
    if k <= 0.0 or m == null:
        return 0
    var wsum := 0.0
    for slot in ManabitState.SLOT_NAMES:
        var pi: PartInstance = m.slots.get(slot)
        if pi == null or pi.data.is_core or pi.disabled or pi.current_hp <= 0:
            continue
        wsum += float(Broker.salvage_scrap(pi.data)) * float(pi.current_hp) / float(pi.data.max_hp)
    return int(floor(k * wsum))

# A kit DEATH: compute the kept scrap, spill the rest, forfeit the tucked bit (the bit NEVER
# survives the pickers). Returns kept - the caller pays the player via gleaners_pay, which
# burns a daily full-rate slot when kept > 0 (the halving-loophole closure, G10).
func kit_death_spill(tier: String) -> int:
    var kept := gleaners_kept(satchel_scrap, tier, death_h(carried))
    satchel_scrap = 0
    satchel_bit_id = ""
    return kept

# --- Magpie's Heap (wave 3, spec 3) -----------------------------------------------------------
# RUMMAGE the heap: kit runs only, once per run, 8 satchel scrap. The dig outcome and lend pick
# were stamped at map-make (seed-pure - leaving and returning shows the identical dig). Lent
# bits ride the carried box on the box_core precedent: fresh instances, never in player.bits,
# never compendium-marked, gone at run end. The heap never touches purses, Glimmer, the bank,
# the bench, or the loot slot - lends only.

const RUMMAGE_PRICE := 8
const RUMMAGE_FILINGS := 4

func can_rummage() -> bool:
    return is_kit and not over and at_rest() \
        and String(node().get("flavor", "")) == "scrapyard" and not heap_rummaged

func rummage(compendium: Dictionary) -> Dictionary:
    if not can_rummage() or satchel_scrap < RUMMAGE_PRICE:
        return {}
    var nd := node()
    heap_rummaged = true
    nd["rummaged"] = true
    satchel_scrap -= RUMMAGE_PRICE
    var r1: int = int(nd.get("dig", 0))
    var band := "lend_common" if r1 < 55 else ("filings" if r1 < 85 else "lend_rare")
    if band == "lend_rare" and _heap_pool("RARE", compendium).is_empty():
        band = "filings"                 # discovered-first: no RAREs known downgrades to filings
    if band == "filings":
        satchel_scrap += RUMMAGE_FILINGS
        return {"kind": "filings", "scrap": RUMMAGE_FILINGS}
    var rarity := "COMMON" if band == "lend_common" else "RARE"
    var pool := _heap_pool(rarity, compendium)
    if pool.is_empty():
        satchel_scrap += RUMMAGE_FILINGS # belt-and-braces: an empty pool still pays filings
        return {"kind": "filings", "scrap": RUMMAGE_FILINGS}
    var pd: PartData = pool[int(nd.get("dig_pick", 0)) % pool.size()]
    carried.slots[String(pd.slot)] = PartInstance.new(pd)   # fresh LENT instance - box precedent
    return {"kind": "lend", "rarity": rarity, "id": String(pd.id), "name": String(pd.display_name)}

# Draw pools are discovered-first: what you have met in the dex. Commons fall back to the base
# fixtures so a fresh player always digs SOMETHING. Sorted by id - the seeded pick is stable.
static func _heap_pool(rarity: String, compendium: Dictionary) -> Array:
    var pool := []
    for pd in Catalog.body_pool():
        if String(pd.rarity) == rarity and compendium.has(String(pd.id)):
            pool.append(pd)
    if pool.is_empty() and rarity == "COMMON":
        for pd2 in Catalog.body_pool():
            if String(pd2.rarity) == "COMMON" and String(pd2.family) == "baseline":
                pool.append(pd2)
    pool.sort_custom(func(a, b): return String(a.id) < String(b.id))
    return pool

func _clone(src: ManabitState) -> ManabitState:
    var m := ManabitState.new()
    for slot in ManabitState.SLOT_NAMES:
        var pi: PartInstance = src.slots.get(slot)
        m.slots[slot] = PartInstance.new(pi.data) if pi != null else null
    return m
