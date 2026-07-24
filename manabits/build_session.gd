class_name BuildSession extends RefCounted
# The in-progress build: a ManabitState being assembled + the Salvage Tray inventory.
# Move-semantics: a PartInstance lives in EITHER the tray OR exactly one slot, never both.
# Pure logic - no scene-tree references. The Workshop UI binds to this.

var manabit: ManabitState
var inventory: Array[PartInstance] = []          # the Salvage Tray

func _init() -> void:
    manabit = ManabitState.new()
    for s in ManabitState.SLOT_NAMES:
        manabit.slots[s] = null                  # all six sockets start empty

func slot_accepts(slot_name: String, pi: PartInstance) -> bool:
    if pi == null:
        return false
    var d := pi.data
    if slot_name == "CORE":
        return d.is_core                         # only a crafted core seats in CORE
    if d.is_core:
        return false                             # a core seats nowhere else
    if slot_name == "ARM_L" or slot_name == "ARM_R":
        return d.slot == "ARM_L" or d.slot == "ARM_R"   # arms interchangeable (§12.3)
    return d.slot == slot_name

func add_to_inventory(pi: PartInstance) -> void:
    inventory.append(pi)

# Equip pi into slot_name. Returns the displaced PartInstance (or null). Move-semantics:
# pi leaves the tray; any part already in the slot returns to the tray.
func equip(slot_name: String, pi: PartInstance) -> PartInstance:
    if not slot_accepts(slot_name, pi):
        return pi                                # rejected - caller leaves pi where it was
    inventory.erase(pi)
    var displaced: PartInstance = manabit.slots.get(slot_name)
    manabit.slots[slot_name] = pi
    if displaced != null:
        inventory.append(displaced)
    return displaced

func unequip(slot_name: String) -> PartInstance:
    var pi: PartInstance = manabit.slots.get(slot_name)
    if pi != null:
        manabit.slots[slot_name] = null
        inventory.append(pi)
    return pi

func clear() -> void:
    # Empty every socket WITHOUT returning bits to the tray (they were consumed on bind).
    for s in ManabitState.SLOT_NAMES:
        manabit.slots[s] = null
    manabit.mana = 0

func current_derived() -> Dictionary:
    return manabit.derived()

# Non-mutating projection: what derived() WOULD be if pi were seated in slot_name.
# Shares PartInstance refs (derived only reads) so it never touches live state.
func preview_derived_with(slot_name: String, pi: PartInstance) -> Dictionary:
    if not slot_accepts(slot_name, pi):
        return manabit.derived()
    var temp := ManabitState.new()
    for s in ManabitState.SLOT_NAMES:
        temp.slots[s] = manabit.slots.get(s)
    temp.slots[slot_name] = pi
    return temp.derived()

func is_deployable() -> bool:
    # §13.2 Garage invariant: a live core + at least one non-GUARD offensive part.
    return manabit.alive() and manabit.has_offensive_move()

func deploy_block_reason() -> String:
    if manabit.core() == null:
        return "Seat a mana core - it's the soul that wakes your Manabit."
    if not manabit.alive():
        return "This core is spent. Seat a live core."
    if not manabit.has_offensive_move():
        return "Give it a way to fight - attach a bit with an attack (an arm or head)."
    return ""
