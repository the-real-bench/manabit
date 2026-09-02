extends SceneTree
# Does the reward track the difficulty? Prints stake against lootable worth.
#
# IMPORTANT (iteration 7): the player CHOOSES which bit to loot on a win -
# ui/combat_screen.gd:1636 builds one button per non-core bit under "Loot a part:".
# So the range is a MENU, not a draw. What a player actually receives is the MAX.
# The min is printed only to show the spread; no rational player ever takes it.
func _initialize() -> void:
    var cat := Catalog.by_id()
    print("%-34s %5s %8s %10s" % ["CHALLENGER", "STAKE", "TAKEN", "(ignored)"])
    for entry in Challengers.list():
        var w := []
        for spec in entry["loadout"]:
            var pd: PartData = cat.get(spec[1])
            if pd != null and not pd.is_core:
                w.append(Broker.salvage_scrap(pd))
        var stake: int = PlayerState.bout_stake(entry)
        var lo: int = w.min() if not w.is_empty() else 0
        var hi: int = w.max() if not w.is_empty() else 0
        print("%-34s %5d %8d %10d" % [String(entry.get("name","?")), stake, hi, lo])
    quit(0)
