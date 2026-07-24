class_name ManabitState extends RefCounted

const WEIGHT_BUDGET := 100
const OVERWEIGHT_SPD_COST := 1
const MANA_REGEN_PER_TURN := 2

const SLOT_NAMES := ["HEAD", "CORE", "ARM_L", "ARM_R", "LEGS", "BACK"]

var slots: Dictionary = {}
var mana: int = 0
var guard_bonus: int = 0

func core() -> PartInstance:
    return slots.get("CORE")

func alive() -> bool:
    var c := core()
    return c != null and not c.disabled and c.current_hp > 0

func active_parts() -> Array[PartInstance]:
    var out: Array[PartInstance] = []
    for pi in slots.values():
        if pi != null and not pi.disabled:
            out.append(pi)
    return out

func has_offensive_move() -> bool:
    for pi in active_parts():
        var a := pi.data.ability
        if a != null and a.archetype != "GUARD":
            return true
    return false

func derived() -> Dictionary:
    var s := {"attack": 0, "defense": 0, "speed": 0, "weight": 0, "energy": 0, "capacity": WEIGHT_BUDGET}
    for pi in active_parts():
        var d := pi.data
        s.attack  += d.attack
        s.defense += d.defense
        s.speed   += d.speed
        s.weight  += d.weight
        s.energy  += d.energy
    # CARRY rider (SS13 additive, TD-countersigned 2026-07-18): capacity = 100 + the SEATED core's
    # carry. Read via slots.get("CORE"), deliberately NOT active_parts(), so a disabled core does
    # not change capacity on result screens. carry on non-CORE bits is intentionally inert.
    var c: PartInstance = slots.get("CORE")
    s.capacity = WEIGHT_BUDGET + (maxi(0, c.data.carry) if c != null else 0)
    s.speed -= maxi(0, int(s.weight) - int(s.capacity)) * OVERWEIGHT_SPD_COST
    s.speed = maxi(1, s.speed)
    return s

func start_fight() -> void:
    mana = derived().energy
    guard_bonus = 0

func begin_turn() -> void:
    guard_bonus = 0
    mana = mini(derived().energy, mana + MANA_REGEN_PER_TURN)
