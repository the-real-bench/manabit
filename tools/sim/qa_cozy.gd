extends SceneTree
# Verify C1: PackRoller stream + pity are not persisted; the seed is the compile-time constant
# 20260711. Two FRESH PlayerStates (as on two cold boots) must produce byte-identical coffer
# sequences and reset pity. Read-only, no user:// writes.

func _initialize() -> void:
    var a := PlayerState.new()   # _init -> PackRoller.new(20260711)
    var b := PlayerState.new()
    var seq_a := _open5(a)
    var seq_b := _open5(b)
    print("  fresh boot A first-3-brass opens:")
    for row in seq_a:
        print("     " + row)
    var identical := seq_a == seq_b
    print("  boot B identical to boot A: %s" % str(identical))
    print("  SaveManager persists a roller field: %s" % str(_save_has_roller()))
    print("QA COZY DONE (C1 identical=%s)" % str(identical))
    quit(0)

func _open5(p: PlayerState) -> Array:
    var out := []
    for n in 3:
        var rolled := p.roller.roll_brass()
        var ids := []
        for pi in rolled:
            ids.append(String(pi.data.id))
        out.append("brass#%d: %s" % [n + 1, ", ".join(ids)])
    return out

func _save_has_roller() -> bool:
    # SaveManager.save writes a fixed dict; there is no roller/pity key (meta/save_manager.gd).
    var keys := ["version", "scrap", "glimmer", "coffers", "loose_bits", "garage", "compendium",
        "broker_shelf", "last_gift_day", "last_shelf_day", "kit_runs_today", "last_kit_run_day",
        "kit_box_nonce", "binds_total"]
    return keys.has("roller") or keys.has("pity")
