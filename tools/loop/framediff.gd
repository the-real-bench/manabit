extends SceneTree
# Compare two sets of rendered frames.
#
#   godot --headless --path . -s res://tools/loop/framediff.gd -- <dirA> <dirB> [pct]
#
# THIS IS AN INSTRUMENT, NOT A GATE. It reports how much two frame sets differ. It
# deliberately does NOT return a SAME/DIFFERENT verdict, because iteration 6 proved
# a whole-frame threshold cannot support one:
#
#     NOISE   animation-only   one-character label change
#        12       0.291%             0.376%
#        40       0.144%             0.195%
#        80       0.104%             0.137%
#       120       0.081%             0.109%
#
# Only ~1.3x separation at every amplitude cutoff. The Workshop's breathing bob
# moves a 3D model, so its drift is high-amplitude AND spread out - a one-word text
# change is genuinely the same order of magnitude. Any threshold that ignores the
# animation also ignores real edits. Amplitude filtering was tried and did not help.
#
# What it IS good for: the three static screens (compendium, menagerie, proving)
# measure 0.000% between runs, so on those a non-zero reading is a real change.
# Use the numbers; do not build a pass/fail on the animated three without solving
# the phase problem first.
var NOISE := 12            # per-channel 0-255 delta below which a pixel is "the same"

func _initialize() -> void:
    var args := OS.get_cmdline_user_args()
    if args.size() < 2:
        print("usage: framediff.gd -- <dirA> <dirB> [max_pct]")
        quit(2); return
    var a := String(args[0])
    var b := String(args[1])
    var max_pct := float(args[2]) if args.size() > 2 else 0.0
    if args.size() > 3: NOISE = int(args[3])

    var da := DirAccess.open(a)
    if da == null:
        print("FRAMEDIFF FAIL: cannot open %s" % a); quit(1); return
    var names: Array[String] = []
    for f in da.get_files():
        if f.ends_with(".png"):
            names.append(f)
    names.sort()
    if names.is_empty():
        print("FRAMEDIFF FAIL: no PNGs in %s" % a); quit(1); return

    var worst := 0.0
    var worst_name := ""
    var any_fail := false
    for n in names:
        var ia := Image.new()
        var ib := Image.new()
        if ia.load(a.path_join(n)) != OK or ib.load(b.path_join(n)) != OK:
            print("FRAMEDIFF FAIL: missing or unreadable pair for %s" % n)
            any_fail = true; continue
        if ia.get_width() != ib.get_width() or ia.get_height() != ib.get_height():
            print("  %-24s SIZE CHANGED %dx%d -> %dx%d" % [n, ia.get_width(), ia.get_height(), ib.get_width(), ib.get_height()])
            worst = 100.0; worst_name = n; any_fail = true; continue
        var w := ia.get_width()
        var h := ia.get_height()
        var changed := 0
        for y in range(0, h, 2):          # every other row: 4x faster, same verdict
            for x in range(0, w, 2):
                var ca := ia.get_pixel(x, y)
                var cb := ib.get_pixel(x, y)
                var d: float = maxf(maxf(absf(ca.r - cb.r), absf(ca.g - cb.g)), absf(ca.b - cb.b)) * 255.0
                if d > float(NOISE):
                    changed += 1
        var total := float(int((h + 1) / 2) * int((w + 1) / 2))
        var pct := 100.0 * float(changed) / total
        print("  %-24s %6.3f%% pixels changed" % [n, pct])
        if pct > worst:
            worst = pct
            worst_name = n

    print("WORST: %s at %.3f%%" % [worst_name, worst])
    if any_fail:
        print("FRAMEDIFF DIFFERENT"); quit(1); return
    # No verdict on purpose. See the header: a whole-frame threshold cannot tell
    # animation phase from a real edit, so returning SAME here would manufacture
    # exactly the false confidence this project keeps having to dig out.
    quit(0)
