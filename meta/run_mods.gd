class_name RunMods extends RefCounted
# Lane modifiers for the branching run map (team-ratified spec). Exactly one modifier per junction
# lane; spine nodes (Rusty, both rests) are always clean. Card text IS the rule, verbatim - the
# FTL lying-label anti-pattern is banned. Modifiers never touch purses, loot counts, or the
# satchel. All four hooks run OUTSIDE combat.gd:
#   tailwind / second_wind - player-side, applied here (run_screen + the sim driver call
#   these SAME helpers, so the gate exercises the shipped code path);
#   rusted / overgrown - foe-side, applied in Challengers.make(entry, mod_id).
# D12 (wave-3, measurement-gated): second_wind's after-the-bout mend was a DEAD rule (+0.0pp
# paired-seed effect - The Last Lantern repair erased it before it could matter). The
# measured-passing minimal rule is the CORE-PAD reading: win on the lane and the mend lands on
# the CORE at the NEXT bell, and may overheal by the printed amount (paired-seed
# +4.2/+6.9/+12.0/+4.3pp across all 4 tier-x-lane cells, gate band [+2pp, +12pp]).
# tailwind's twin fix measured 1/4 cells in band (mid boss baselines leave no room for a 4 HP
# pad) - HELD behind the boss-softening balance wave; its rule ships unchanged.

const MEND_PRE := 4        # tailwind: HP mended across worn bits before the bell
const MEND_POST := 3       # second_wind: core HP carried into the next bell after a WIN here
const WEAR := 2            # rusted: foe bits each start this many HP down (floor 1)

const TABLE := {
    "tailwind": {"id": "tailwind", "name": "Tail-Wind", "glyph": "»",
        "blurb": "Mended 4 HP before the bell"},
    "second_wind": {"id": "second_wind", "name": "Second Wind", "glyph": "✚",
        "blurb": "Win here: your core carries +3 HP into the next bell"},
    "rusted": {"id": "rusted", "name": "Rusted Through", "glyph": "▼",
        "blurb": "Foe bits each start 2 HP down"},
    "overgrown": {"id": "overgrown", "name": "Overgrown", "glyph": "▲",
        "blurb": "The foe fields heavier bits here"},
}

static func mod_id(run: RunState) -> String:
    var m: Dictionary = run.node().get("modifier", {})
    return String(m.get("id", ""))

# Tail-Wind: distribute MEND_PRE HP across the carried Manabit's worn bits (capped at each bit's
# max_hp, free) before fight_requested is emitted. No-op on any other lane.
static func pre_fight_mend(run: RunState) -> int:
    if mod_id(run) != "tailwind":
        return 0
    return _mend(run.carried, MEND_PRE)

# Second Wind (D12 core-pad rule): a WIN on this lane banks a MEND_POST core pad on the
# session-local RunState. Call BEFORE advance() so node() still reads the fought lane. Never
# authored onto a boss lane (validator-enforced), so the next bell is always the boss.
static func note_win(run: RunState) -> int:
    if mod_id(run) != "second_wind":
        return 0
    run.second_wind_pad = maxi(run.second_wind_pad, MEND_POST)
    return MEND_POST

# Consume the banked pad at the pre-bell seam (the same seam as pre_fight_mend): the pad lands
# on the CORE instance and may overheal past max_hp by the printed amount - that is the whole
# point, it survives The Last Lantern's full repair. Instance-only; PartData never mutates.
static func consume_core_pad(run: RunState) -> int:
    var pad: int = run.second_wind_pad
    if pad <= 0:
        return 0
    run.second_wind_pad = 0
    var core: PartInstance = run.carried.core() if run.carried != null else null
    if core == null:
        return 0
    core.current_hp += pad
    return pad

static func _mend(m: ManabitState, pool: int) -> int:
    var spent := 0
    for slot in ManabitState.SLOT_NAMES:
        if pool <= 0:
            break
        var pi: PartInstance = m.slots.get(slot)
        if pi == null or pi.disabled or pi.current_hp >= pi.data.max_hp:
            continue
        var heal: int = mini(pool, pi.data.max_hp - pi.current_hp)
        pi.current_hp += heal
        pool -= heal
        spent += heal
    return spent
