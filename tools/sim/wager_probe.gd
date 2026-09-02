extends SceneTree
# Does the reward track the difficulty? Prints stake against lootable worth for
# every challenger, so the wager gradient is a number instead of an impression.
func _initialize() -> void:
    var cat := Catalog.by_id()
    print("%-30s %6s %10s" % ["CHALLENGER", "STAKE", "SPOILS"])
    for entry in Challengers.list():
        var w := []
        for spec in entry["loadout"]:
            var pd: PartData = cat.get(spec[1])
            if pd != null and not pd.is_core:
                w.append(Broker.salvage_scrap(pd))
        var stake: int = PlayerState.bout_stake(entry)
        var lo: int = w.min() if not w.is_empty() else 0
        var hi: int = w.max() if not w.is_empty() else 0
        print("%-30s %6d %6d-%d" % [String(entry.get("name","?")), stake, lo, hi])
    quit(0)
