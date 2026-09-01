extends SceneTree
# Are the printed coffer odds what the coffer actually rolls?
# The printed C/R/E are PER-DRAW BASE RATES. Brass also carries a >=1 RARE+
# guarantee and an epic-pity at 9, both of which bend the realized mix away from
# those base rates. This probe measures the realized mix so the gap is a number
# rather than an assumption.
const N := 40000

func _initialize() -> void:
    for kind in ["tin", "brass"]:
        var r := PackRoller.new(20260711)
        var tally := {"COMMON": 0, "RARE": 0, "EPIC": 0}
        var bits := 0
        for i in range(N):
            var rolled: Array = r.roll_brass() if kind == "brass" else r.roll_tin()
            for pi in rolled:
                tally[pi.data.rarity] = int(tally[pi.data.rarity]) + 1
                bits += 1
        var line := PackRoller.odds_line(kind)
        print("%s  printed: %s" % [kind, line])
        print("   realized over %d coffers (%d bits): C %.1f%%  R %.1f%%  E %.1f%%" % [
            N, bits,
            100.0 * float(tally["COMMON"]) / float(bits),
            100.0 * float(tally["RARE"]) / float(bits),
            100.0 * float(tally["EPIC"]) / float(bits)])
    quit(0)
