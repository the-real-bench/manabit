class_name PlayerState extends RefCounted
# Player-level collection + economy, shared across screens and persisted via SaveManager.
# A "bit" (code type PartInstance) is a piece. A "Manabit" is a whole assembled robot.
# IMPORTANT: mutate `bits` IN PLACE (append/erase) - never reassign it, screens hold the ref.

var bits: Array[PartInstance] = []       # loose owned bits - the Salvage Tray draws from this
var coffers: Dictionary = {"tin": 0, "brass": 0}
var scrap: int = 0
var glimmer: int = 0
var roller: PackRoller
var menagerie: Array = []                # banked whole Manabits (Array of Dictionary)
var compendium: Dictionary = {}          # discovered bit id (String) -> true
var broker_shelf: Array = []             # Today's Finds: [{id, sold}]
var last_gift_day: int = -1
var last_shelf_day: int = -1
var kit_runs_today: int = 0              # Box outings today (purse halves after 2 - HIDDEN, never shown)
var last_kit_run_day: int = -1
var kit_box_nonce: int = 0               # advances only on commit - the SAME nonce = the SAME box (no free re-roll)
var binds_total: int = 0                 # lifetime Manabits bound (kit-counter precedent, additive on save v4).
                                         # The Work-Order Tag lives ONLY while this is 0 - never gate on menagerie.is_empty()
                                         # (a wiped veteran keeps binds_total > 0 and never sees baby chrome)

# THE BINDING - the core faucet (team-ratified 2026-07-17). Cores are CRAFTED souls, bound at
# YOUR bench: Fettle never sells them, coffers never roll them. Deterministic Scrap sink, no RNG.
const BIND_CORE_COST := 60
const BINDABLE_CORES := ["core_ember", "core_bulwark", "core_font"]

# Proving bout entry stakes (wave 1 CH-08): non-refundable, charged when the bout begins.
# Closes the riskless-printer shape (clone fights, no core aim, zero entry cost, no cap).
const BOUT_STAKE_REGULAR := 5
const BOUT_STAKE_ELITE := 10
const BOUT_STAKE_BOSS := 20
# Bosses by roster identity (ch[4] Brassmore, ch[8] Gildfall - indices frozen in challengers.gd).
const BOUT_BOSS_NAMES := ["Sunking Brassmore, the Undethroned", "Prince Gildfall, the Heir-Apparent"]

static func bout_stake(entry: Dictionary) -> int:
    if BOUT_BOSS_NAMES.has(String(entry.get("name", ""))):
        return BOUT_STAKE_BOSS
    if bool(entry.get("elite", false)):
        return BOUT_STAKE_ELITE
    return BOUT_STAKE_REGULAR

# Trundle purse tables by fight TIER (skirmish/elite/boss); halved after 2 runs/day. Tier-keyed
# so the branching map pays by what you fought, not where it stood - purse = f(tier, runs_today)
# only, so equal-tier lanes always pay equal and modifiers can never touch the purse.
const KIT_PURSE := {"skirmish": 10, "elite": 25, "boss": 40}
const KIT_PURSE_HALVED := {"skirmish": 5, "elite": 12, "boss": 20}

func _init() -> void:
    roller = PackRoller.new(20260711)

func grant_starter_kit() -> void:
    scrap = 50
    coffers = {"tin": 1, "brass": 2}
    for pd in Catalog.starter_cores():
        var pi := PartInstance.new(pd)
        bits.append(pi)
        _discover(pi)
    for pi2 in roller.roll_brass():
        bits.append(pi2)
        _discover(pi2)

func coffer_count() -> int:
    return int(coffers.get("tin", 0)) + int(coffers.get("brass", 0))

func _discover(pi: PartInstance) -> void:
    compendium[String(pi.data.id)] = true

# Loot a part won in a bout (§6): a fresh bit enters the collection.
func loot_part(pd: PartData) -> void:
    var pi := PartInstance.new(pd)
    bits.append(pi)
    _discover(pi)

func owned_counts() -> Dictionary:
    var m := {}
    for pi in bits:
        var id := String(pi.data.id)
        m[id] = int(m.get(id, 0)) + 1
    return m

# --- Coffers ---
func buy_coffer(kind: String) -> bool:
    var cost := Broker.BRASS_PRICE if kind == "brass" else Broker.TIN_PRICE
    if scrap < cost:
        return false
    scrap -= cost
    coffers[kind] = int(coffers.get(kind, 0)) + 1
    return true

func open_coffer(kind: String) -> Array[PartInstance]:
    if int(coffers.get(kind, 0)) <= 0:
        return []
    coffers[kind] = int(coffers[kind]) - 1
    var rolled := roller.roll_brass() if kind == "brass" else roller.roll_tin()
    for pi in rolled:
        bits.append(pi)
        _discover(pi)
    return rolled

# --- The Melt (Scrap) / The Still (Glimmer) --- (cores are never salvageable)
func melt_bit(pi: PartInstance) -> int:
    if pi == null or pi.data.is_core or not bits.has(pi):
        return 0
    var gain := Broker.salvage_scrap(pi.data)
    bits.erase(pi)
    scrap += gain
    return gain

func melt_common_dupes() -> Dictionary:
    # Melt every COMMON bit beyond the first of each id (keeps 1 of each; never cores).
    var seen := {}
    var doomed := []
    for pi in bits:
        if pi.data.is_core or pi.data.rarity != "COMMON":
            continue
        var id := String(pi.data.id)
        if seen.has(id):
            doomed.append(pi)
        else:
            seen[id] = true
    var gain := 0
    for pi in doomed:
        gain += melt_bit(pi)
    return {"count": doomed.size(), "scrap": gain}

func distill_bit(pi: PartInstance) -> int:
    if pi == null or pi.data.is_core or not bits.has(pi):
        return 0
    var gain := Broker.distill_glimmer(pi.data)
    if gain <= 0:
        return 0
    bits.erase(pi)
    glimmer += gain
    return gain

# --- Today's Finds ---
func refresh_broker(today: int) -> void:
    if last_shelf_day != today or broker_shelf.is_empty():
        broker_shelf = Broker.roll_shelf(today, compendium, owned_counts())
        last_shelf_day = today

func buy_find(index: int) -> PartData:
    if index < 0 or index >= broker_shelf.size():
        return null
    var entry: Dictionary = broker_shelf[index]
    if bool(entry.get("sold", false)):
        return null
    var pd: PartData = Catalog.by_id().get(String(entry.get("id", "")))
    if pd == null:
        return null
    var price := Broker.find_price(pd)
    if price["currency"] == "glimmer":
        if glimmer < int(price["amount"]):
            return null
        glimmer -= int(price["amount"])
    else:
        if scrap < int(price["amount"]):
            return null
        scrap -= int(price["amount"])
    var pi := PartInstance.new(pd)
    bits.append(pi)
    _discover(pi)
    entry["sold"] = true
    return pd

# --- The Doorstep Coffer (free Tin, once per calendar day) ---
func doorstep_available(today: int) -> bool:
    return last_gift_day != today

func claim_doorstep(today: int) -> bool:
    if last_gift_day == today:
        return false
    last_gift_day = today
    coffers["tin"] = int(coffers.get("tin", 0)) + 1
    return true

# --- The Binding (bind a fresh COMMON starter core at your own bench) ---
func bind_core(core_id: String) -> bool:
    if not BINDABLE_CORES.has(core_id) or scrap < BIND_CORE_COST:
        return false
    var pd: PartData = Catalog.by_id().get(core_id)
    if pd == null:
        return false
    scrap -= BIND_CORE_COST
    var pi := PartInstance.new(pd)
    bits.append(pi)                      # in place - screens hold the ref
    _discover(pi)
    return true

# --- Box of Scrap seeding: the same nonce always rolls the same box; only committing a run advances it ---
func kit_box_seed() -> int:
    return (kit_box_nonce * 2654435761 + 1013904223) & 0x7FFFFFFF

func spend_kit_box() -> void:
    kit_box_nonce += 1               # caller saves; the old box is gone whether you won, lost, or died

# --- Box bookkeeping (satchel + hidden daily purse rate) ---
func _roll_kit_day(today: int) -> void:
    if last_kit_run_day != today:
        last_kit_run_day = today
        kit_runs_today = 0

func kit_purse(tier: String, today: int) -> int:
    _roll_kit_day(today)
    var table: Dictionary = KIT_PURSE if kit_runs_today < 2 else KIT_PURSE_HALVED
    return int(table.get(tier, 0))          # unknown tier pays 0 - same fail-safe as before

func note_kit_run(today: int) -> void:
    _roll_kit_day(today)
    kit_runs_today += 1

# The Gleaner's Due payout on a kit DEATH (wave 3, G10 halving-loophole closure): a death that
# pays burns a daily full-rate slot, so deliberate deep-death EV is strictly worse than Head
# home at every state - kept <= floor(S/2), the bit is forfeited, and the same slot burns.
func gleaners_pay(kept: int, today: int) -> void:
    if kept <= 0:
        return
    scrap += kept
    note_kit_run(today)

# Flush a kit run's satchel into the collection - ONLY called on a safe run end (never on DEATH).
func flush_satchel(r: RunState) -> void:
    scrap += r.satchel_scrap
    if r.satchel_bit_id != "":
        var pd: PartData = Catalog.by_id().get(r.satchel_bit_id)
        if pd != null:
            loot_part(pd)

# Bank a whole Manabit into the Menagerie. Its bits are consumed (they lived in the sockets).
func bank_manabit(mname: String, m: ManabitState) -> void:
    var entry := {"name": mname, "core_id": "", "parts": []}
    for slot in ManabitState.SLOT_NAMES:
        var pi: PartInstance = m.slots.get(slot)
        if pi == null:
            continue
        if pi.data.is_core:
            entry["core_id"] = String(pi.data.id)
        entry["parts"].append({"slot": slot, "id": String(pi.data.id), "current_hp": pi.current_hp})
    var d := m.derived()
    entry["atk"] = int(d.attack)
    entry["def"] = int(d.defense)
    entry["spd"] = int(d.speed)
    entry["mana"] = int(d.energy)
    menagerie.append(entry)
    binds_total += 1

func compendium_total() -> int:
    # Honest denominator (wave 1 CH-10): cores the player can never own do not count.
    # Fettle never sells cores and coffers never roll them, so the only obtainable cores
    # are the bindable ones. A filter, not a magic number, so future catalog growth stays honest.
    var n := 0
    for pd in Catalog.all():
        if pd.is_core and not BINDABLE_CORES.has(String(pd.id)):
            continue
        n += 1
    return n

func save() -> void:
    SaveManager.save(self)
