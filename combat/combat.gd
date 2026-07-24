class_name Combat extends RefCounted
# M1 combat resolver: turn-based, initiative-ordered, part-targeted.
# Implements §13.3 (three outcomes) + §13.4 (damage/mana) + the flagged fixes:
#   MULTI auto-targets lowest-HP non-core, redirecting to the CORE only when no non-core part remains;
#   SINGLE may aim the core iff ability.can_target_core; ordinary enemies never deliver the core kill.
# UI-drivable AND headless-testable (no scene refs).

enum Result { ONGOING, WIN, SURVIVABLE_LOSS, DEATH }

var player: ManabitState
var enemy: ManabitState
var enemy_can_aim_core: bool = false        # elites/bosses set true; ordinary dummies stay false
var order: Array[ManabitState] = []
var turn_index: int = 0
var battle_log: Array[String] = []
var last_events: Array = []          # per-hit events from the most recent perform(), for UI juice
var last_action := {}                # ADDITIVE presentation telemetry from the most recent perform():
                                     #   {attacker, archetype, [guard_kind, guard_amount, mend_slot, amount, actor_slot]}
                                     # UI-only side channel - last_events stays byte-identical.

func start(p: ManabitState, e: ManabitState, can_aim_core: bool = false) -> void:
    player = p
    enemy = e
    enemy_can_aim_core = can_aim_core
    player.start_fight()
    enemy.start_fight()
    _rebuild_order()
    turn_index = 0

func _rebuild_order() -> void:
    var ps := int(player.derived().speed)
    var es := int(enemy.derived().speed)
    order.assign([enemy, player] if es > ps else [player, enemy])   # tie -> player first

func current() -> ManabitState:
    return order[turn_index % order.size()] if not order.is_empty() else null

func advance_turn() -> void:
    turn_index += 1
    if turn_index % order.size() == 0:
        _rebuild_order()                     # re-evaluate initiative each round
    current().begin_turn()

# --- queries a UI (or the AI) uses ---
func moves_for(m: ManabitState) -> Array:
    var out := []
    for slot in ManabitState.SLOT_NAMES:
        var pi: PartInstance = m.slots.get(slot)
        if pi == null or pi.disabled or pi.data.ability == null:
            continue
        var a: AbilityData = pi.data.ability
        if a.mana_cost <= m.mana:
            out.append({"slot": slot, "ability": a, "part": pi})
    return out

func targets_for(defender: ManabitState, ability: AbilityData) -> Array:
    var out := []
    for slot in ManabitState.SLOT_NAMES:
        if slot == "CORE":
            continue
        var pi: PartInstance = defender.slots.get(slot)
        if pi != null and not pi.disabled:
            out.append(slot)
    if ability.can_target_core or out.is_empty():
        out.append("CORE")
    return out

# --- resolution ---
func perform(attacker: ManabitState, ability: AbilityData, defender: ManabitState, target_slot: String) -> void:
    last_events.clear()
    last_action = {"attacker": attacker, "archetype": ability.archetype}
    attacker.mana = maxi(0, attacker.mana - ability.mana_cost)
    match ability.archetype:
        "GUARD":
            last_action["guard_kind"] = ability.guard_kind
            last_action["guard_amount"] = ability.guard_amount
            if ability.guard_kind == "PART_RESTORE":
                var t := _lowest_wounded_part(attacker)
                if t != null:
                    t.restore(ability.guard_amount)
                    for slot in ManabitState.SLOT_NAMES:
                        if attacker.slots.get(slot) == t:
                            last_action["mend_slot"] = slot
                            break
                    last_action["amount"] = ability.guard_amount
                    _log("%s braces a part (+%d HP)" % [_who(attacker), ability.guard_amount])
                else:
                    _log("%s stands ready" % _who(attacker))
            else:
                attacker.guard_bonus += ability.guard_amount
                _log("%s guards (+%d DEF this turn)" % [_who(attacker), ability.guard_amount])
        "MULTI":
            for i in maxi(1, ability.hit_count):
                _hit(attacker, ability, defender, _multi_target(defender))
        _:
            _hit(attacker, ability, defender, target_slot)

func _hit(attacker: ManabitState, ability: AbilityData, defender: ManabitState, slot: String) -> void:
    var pi: PartInstance = defender.slots.get(slot)
    if pi == null or pi.disabled:
        slot = "CORE"
        pi = defender.slots.get("CORE")
    if pi == null:
        return
    var atk := int(attacker.derived().attack)
    var dfn := int(defender.derived().defense) + defender.guard_bonus
    var dmg := maxi(1, atk + ability.power - dfn)
    var was_alive := not pi.disabled
    pi.take_damage(dmg)
    var broke := was_alive and pi.disabled and slot != "CORE"
    last_events.append({"target": defender, "slot": slot, "damage": dmg, "broke": broke, "is_core": slot == "CORE"})
    _log("%s strikes %s's %s for %d" % [_who(attacker), _who(defender), slot, dmg])
    if broke:
        _log("  ↳ %s's %s breaks!" % [_who(defender), slot])

func _multi_target(defender: ManabitState) -> String:
    var best := ""
    var best_hp := 1 << 30
    for slot in ManabitState.SLOT_NAMES:
        if slot == "CORE":
            continue
        var pi: PartInstance = defender.slots.get(slot)
        if pi != null and not pi.disabled and pi.current_hp < best_hp:
            best_hp = pi.current_hp
            best = slot
    return best if best != "" else "CORE"     # redirect to core when nothing else remains

func _lowest_wounded_part(m: ManabitState) -> PartInstance:
    var best: PartInstance = null
    for slot in ManabitState.SLOT_NAMES:
        var pi: PartInstance = m.slots.get(slot)
        if pi != null and not pi.disabled and pi.current_hp < pi.data.max_hp:
            if best == null or pi.current_hp < best.current_hp:
                best = pi
    return best

# Enemy AI: prefer an offensive move; target the enemy's lowest-HP non-core part.
# An ordinary enemy (can_aim_core=false) will NOT deliver a killing blow to the core.
# An elite/boss (can_aim_core=true) HUNTS THE SOUL: it drives a single-target strike straight into
# the core - a race to the death (WIN or DEATH, no cozy limp-home). A weak build loses that race.
func ai_take_turn(attacker: ManabitState, defender: ManabitState) -> void:
    var moves := moves_for(attacker)
    if moves.is_empty():
        _log("%s has no move it can afford" % _who(attacker))
        return
    if attacker == enemy and enemy_can_aim_core:
        for mv in moves:
            if mv["ability"].archetype == "SINGLE":         # a strike we can drive into the soul
                _log("%s lunges for your core!" % _who(attacker))
                perform(attacker, mv["ability"], defender, "CORE")
                last_action["actor_slot"] = String(mv["slot"])
                return
    var chosen: Dictionary = moves[0]
    for mv in moves:
        if mv["ability"].archetype != "GUARD":
            chosen = mv
            break
    var ability: AbilityData = chosen["ability"]
    var target := _multi_target(defender)
    var only_core := (target == "CORE")
    if attacker == enemy and not enemy_can_aim_core and only_core:
        _log("%s hangs back - it won't strike the core" % _who(attacker))
        return
    perform(attacker, ability, defender, target)
    last_action["actor_slot"] = String(chosen["slot"])

func outcome() -> int:
    if not enemy.alive():
        return Result.WIN
    if not player.alive():
        return Result.DEATH
    if not player.has_offensive_move():
        return Result.SURVIVABLE_LOSS       # all weapon parts disabled but core alive
    return Result.ONGOING

func _who(m: ManabitState) -> String:
    return "You" if m == player else "Foe"

func _log(s: String) -> void:
    battle_log.append(s)
