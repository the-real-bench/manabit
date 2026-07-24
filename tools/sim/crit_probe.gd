extends SceneTree
# COMPLETENESS-CRITIC PROBE (read-only, no user:// touch). Fills the gap the panel missed:
# is the BOSS junction a meaningful decision? rusted rides a boss lane (RunState L34/L50).
# Controlled: same player build + seed, boss foe clean vs rusted, aims_core=true.
# Also: proving-bout loot/stake EV table (loot melt value vs entry stake per challenger).

func _initialize() -> void:
    var chs := Challengers.list()
    var bosses := {"Brassmore": 4, "Gildfall": 8}
    var N := 120
    print("=== RUSTED-ON-BOSS controlled probe (aims_core=true, N=%d/arm) ===" % N)
    for bname in bosses:
        var ci: int = bosses[bname]
        for arm in ["", "rusted"]:
            var wins := 0; var deaths := 0; var sloss := 0
            for s in range(N):
                var me := RunState.kit_build(700000 + s * 137 + ci * 9)
                var foe := Challengers.make(chs[ci], arm, 0)
                var c := Combat.new()
                c.start(me, foe, true)   # foe aims core
                var guard := 0
                while c.outcome() == Combat.Result.ONGOING and guard < 4000:
                    var actor: ManabitState = c.current()
                    if actor == me:
                        c.ai_take_turn(me, foe)
                    else:
                        c.ai_take_turn(foe, me)
                    if c.outcome() == Combat.Result.ONGOING:
                        c.advance_turn()
                    guard += 1
                var o: int = c.outcome()
                if o == Combat.Result.WIN: wins += 1
                elif o == Combat.Result.DEATH: deaths += 1
                else: sloss += 1
            print("  %-10s %-7s  win %.3f  death %.3f  sloss %.3f" % [
                bname, (arm if arm != "" else "clean"),
                float(wins)/N, float(deaths)/N, float(sloss)/N])

    print("\n=== PROVING-BOUT loot/stake EV (best-lootable melt vs entry stake) ===")
    var cat := Catalog.by_id()
    for i in range(chs.size()):
        var e = chs[i]
        var stake := PlayerState.bout_stake(e)
        var best_melt := 0
        var best_id := ""
        for spec in e["loadout"]:
            var pd = cat.get(spec[1])
            if pd == null or pd.is_core: continue   # cores never salvage
            var melt := Broker.salvage_scrap(pd)
            if melt > best_melt:
                best_melt = melt; best_id = String(pd.id)
        var tier := "boss" if PlayerState.BOUT_BOSS_NAMES.has(String(e.get("name",""))) else ("elite" if e.get("elite",false) else "reg")
        print("  ch[%d] %-32s tier=%-5s stake=%2d  best-loot melt=%2d (%s)" % [
            i, String(e["name"]).substr(0,32), tier, stake, best_melt, best_id])
    quit()
