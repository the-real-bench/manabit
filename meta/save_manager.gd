class_name SaveManager extends RefCounted
# §13.5 JSON persistence (boundary saves). Bits store id + current_hp; catalog looked up by id.
# v2 adds glimmer, typed coffers {tin,brass}, broker shelf/gift/shelf days. v1 migrates cleanly.
# v3 adds kit_runs_today / last_kit_run_day (the kit's hidden purse rate). Additive - v2 loads fine.
# v4 adds kit_box_nonce (the Box of Scrap seed-lock). Additive - v3/older default 0.
# v4 additive (2026-07-18): binds_total - lifetime binds. Absent field seeds from menagerie
# size on load so existing veterans (even later wiped to zero Manabits) never see the tag.

const PATH := "user://manabit_save.json"
const VERSION := 4

static func save(player: PlayerState) -> void:
    var data := {
        "version": VERSION,
        "scrap": player.scrap,
        "glimmer": player.glimmer,
        "coffers": player.coffers,                  # {tin, brass}
        "loose_bits": _bits_to_arr(player.bits),
        "garage": player.menagerie,                 # banked whole Manabits
        "compendium": player.compendium.keys(),
        "broker_shelf": player.broker_shelf,
        "last_gift_day": player.last_gift_day,
        "last_shelf_day": player.last_shelf_day,
        "kit_runs_today": player.kit_runs_today,
        "last_kit_run_day": player.last_kit_run_day,
        "kit_box_nonce": player.kit_box_nonce,
        "binds_total": player.binds_total,
    }
    var f := FileAccess.open(PATH, FileAccess.WRITE)
    if f == null:
        return
    f.store_string(JSON.stringify(data, "  "))
    f.close()

static func load_into(player: PlayerState) -> bool:
    if not FileAccess.file_exists(PATH):
        return false
    var raw := FileAccess.get_file_as_string(PATH)
    var data = JSON.parse_string(raw)
    if typeof(data) != TYPE_DICTIONARY:
        return false
    var ver := int(data.get("version", 1))
    player.scrap = int(data.get("scrap", 0))
    player.glimmer = int(data.get("glimmer", 0))
    player.coffers = _load_coffers(data.get("coffers", null), ver)
    player.bits = _bits_from_arr(data.get("loose_bits", []))
    player.menagerie = data.get("garage", [])
    player.compendium = {}
    for id in data.get("compendium", []):
        player.compendium[String(id)] = true
    player.broker_shelf = data.get("broker_shelf", [])
    player.last_gift_day = int(data.get("last_gift_day", -1))
    player.last_shelf_day = int(data.get("last_shelf_day", -1))
    player.kit_runs_today = int(data.get("kit_runs_today", 0))      # v3; defaults for v1/v2
    player.last_kit_run_day = int(data.get("last_kit_run_day", -1))
    player.kit_box_nonce = int(data.get("kit_box_nonce", 0))        # v4; default 0 (no free re-roll on relaunch)
    player.binds_total = int(data.get("binds_total", -1))           # v4 additive; -1 = absent
    if player.binds_total < 0:
        player.binds_total = player.menagerie.size()                # veteran seed - the tag never resurfaces
    return true

static func _load_coffers(raw, ver: int) -> Dictionary:
    # v1 stored coffers as a single int -> migrate to {tin:0, brass:N}.
    if ver < 2 or typeof(raw) != TYPE_DICTIONARY:
        return {"tin": 0, "brass": int(raw) if typeof(raw) == TYPE_FLOAT or typeof(raw) == TYPE_INT else 0}
    return {"tin": int(raw.get("tin", 0)), "brass": int(raw.get("brass", 0))}

static func _bits_to_arr(bits: Array) -> Array:
    var out := []
    for pi in bits:
        out.append({"id": String(pi.data.id), "current_hp": pi.current_hp})
    return out

static func _bits_from_arr(arr) -> Array[PartInstance]:
    var out: Array[PartInstance] = []
    var cat := Catalog.by_id()
    for e in arr:
        var pd: PartData = cat.get(String(e.get("id", "")))
        if pd == null:
            continue
        var pi := PartInstance.new(pd)
        pi.current_hp = int(e.get("current_hp", pd.max_hp))
        pi.disabled = pi.current_hp == 0
        out.append(pi)
    return out
