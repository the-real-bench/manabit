extends SceneTree
# Stage plumbing gate (combat-juice push): sync() composition diff, update_damage identity,
# detach_part, tween safety, rebuild contract. HEADLESS QUIRKS: queue_free is deferred and the
# dummy renderer draws no pixels - every assertion here is a NODE-GRAPH fact checked ACROSS
# ticks (await timers/frames), never same-frame and never against pixels.

var _ok := true

func _initialize() -> void:
    _run()

func _run() -> void:
    await process_frame
    var stage := ManabitStage.new()
    stage.size = Vector2(320, 240)
    get_root().add_child(stage)
    await process_frame

    # 1. first sync builds; same-composition sync keeps node identity + rebuild count
    var m := _fighter("core_ember", [["ARM_R", "arm_hammer"], ["HEAD", "head_optic"]])
    stage.sync(m)
    await process_frame
    _c("first sync rebuilds once", stage.debug_rebuild_count == 1)
    var arm0 := stage.part_node("ARM_R")
    var head0 := stage.part_node("HEAD")
    _c("part_node returns visuals", arm0 != null and head0 != null)
    stage.sync(m)
    await process_frame
    _c("same-composition sync keeps identity", stage.part_node("ARM_R") == arm0 and stage.debug_rebuild_count == 1)

    # 2. HP-only damage keeps identity (per-hit updates never tear down)
    var arm_pi: PartInstance = m.slots.get("ARM_R")
    arm_pi.take_damage(2)
    stage.sync(m)
    await process_frame
    _c("HP-only damage keeps identity", stage.part_node("ARM_R") == arm0 and stage.debug_rebuild_count == 1)

    # 3. composition change rebuilds
    var cat := Catalog.by_id()
    m.slots["ARM_R"] = PartInstance.new(cat["arm_buckler"])
    stage.sync(m)
    await process_frame
    _c("composition change rebuilds", stage.debug_rebuild_count == 2)
    _c("rebuilt part is a new node", stage.part_node("ARM_R") != arm0)

    # 4. disabled flip detaches: part_node null NOW, siblings keep identity, node frees later
    var head1 := stage.part_node("HEAD")
    var arm1 := stage.part_node("ARM_R")
    var pi2: PartInstance = m.slots.get("ARM_R")
    pi2.take_damage(999)
    _c("fixture arm disabled", pi2.disabled)
    stage.sync(m)
    _c("detach: part_node null immediately", stage.part_node("ARM_R") == null)
    _c("detach: no rebuild (eager comp erase)", stage.debug_rebuild_count == 2)
    stage.sync(m)
    _c("aftermath sync never re-rebuilds mid-tumble", stage.debug_rebuild_count == 2)
    _c("detach: siblings keep identity", stage.part_node("HEAD") == head1)
    await create_timer(0.8).timeout      # tumble is 0.45s + free - wall clock, then a tick
    await process_frame
    await process_frame
    _c("detached node freed after tumble", not is_instance_valid(arm1))

    # 5. forced rebuild mid-tween completes; part_node never returns a freed object
    var m2 := _fighter("core_ember", [["ARM_R", "arm_hammer"], ["LEGS", "legs_light"]])
    stage.sync(m2)
    await process_frame
    stage.hit_react("ARM_R")
    stage.lunge(1)
    stage.rebuild(m2)                    # mid-tween teardown
    var pn := stage.part_node("ARM_R")
    _c("part_node valid after mid-tween rebuild", pn != null and is_instance_valid(pn))
    await create_timer(0.3).timeout
    await process_frame
    var pn2 := stage.part_node("ARM_R")
    _c("part_node never returns freed", pn2 != null and is_instance_valid(pn2))

    # 6. rebuild contract frozen: every call is a full teardown (workshop/menagerie/run fence)
    var rc := stage.debug_rebuild_count
    stage.rebuild(m2)
    stage.rebuild(m2)
    _c("rebuild always rebuilds (frozen behavior)", stage.debug_rebuild_count == rc + 2)

    # 7. core-only and empty states safe
    var core_only := _fighter("core_ember", [])
    stage.sync(core_only)
    await process_frame
    _c("core-only safe", stage.part_node("CORE") != null)
    var empty := ManabitState.new()
    stage.sync(empty)
    await process_frame
    _c("empty state safe", stage.part_node("CORE") == null)

    # 8. reduce-motion detach still departs (scale-pop) and frees
    Juice.reduce_motion = true
    var m3 := _fighter("core_ember", [["HEAD", "head_optic"]])
    stage.sync(m3)
    await process_frame
    var head3 := stage.part_node("HEAD")
    var pi3: PartInstance = m3.slots.get("HEAD")
    pi3.take_damage(999)
    stage.sync(m3)
    _c("rm detach: part_node null immediately", stage.part_node("HEAD") == null)
    await create_timer(0.4).timeout
    await process_frame
    await process_frame
    _c("rm detach: node freed after scale-pop", not is_instance_valid(head3))
    Juice.reduce_motion = false

    # 9. full scripted auto-fight, reduce-motion: completes headless, _fx layer drains
    Juice.reduce_motion = true
    var p := PlayerState.new()
    var cs := CombatScreen.new().setup(p)
    cs.size = Vector2(1280, 720)
    get_root().add_child(cs)
    await process_frame
    cs.debug_autostep()
    cs.begin_spar(_fighter("core_ember", [["ARM_R", "arm_hammer"], ["HEAD", "head_optic"], ["LEGS", "legs_light"]]))
    var waited := 0.0
    while cs._state != "over" and waited < 60.0:
        await create_timer(0.5).timeout
        waited += 0.5
    _c("rm auto-spar reaches an outcome (%.1fs)" % waited, cs._state == "over")
    _c("rm auto-spar outcome is WIN", cs.last_result == Combat.Result.WIN)
    await create_timer(2.0).timeout      # let transient fx labels/tweens drain
    await process_frame
    await process_frame
    _c("fx layer drains to 0 after settle", cs._fx.get_child_count() == 0)
    Juice.reduce_motion = false

    # 10. full scripted auto-fight, motion ON: the whole director runs headless without errors
    var cs2 := CombatScreen.new().setup(p)
    cs2.size = Vector2(1280, 720)
    get_root().add_child(cs2)
    await process_frame
    cs2.debug_autostep()
    cs2.begin_spar(_fighter("core_ember", [["ARM_R", "arm_hammer"], ["ARM_L", "arm_buckler"], ["LEGS", "legs_light"]]))
    var waited2 := 0.0
    while cs2._state != "over" and waited2 < 60.0:
        await create_timer(0.5).timeout
        waited2 += 0.5
    _c("auto-spar (motion on) reaches an outcome (%.1fs)" % waited2, cs2._state == "over")

    # 11. run-fight vs a core-hunting elite: telegraph + DEATH + THE UNMAKING execute headless
    var cs3 := CombatScreen.new().setup(p)
    cs3.size = Vector2(1280, 720)
    get_root().add_child(cs3)
    await process_frame
    cs3.debug_autostep()
    var brass: Dictionary = Challengers.list()[4]      # Sunking Brassmore
    cs3.begin_run_fight(_fighter("core_ember", [["ARM_R", "arm_hammer"]]), brass, true)
    var waited3 := 0.0
    while cs3._state != "over" and waited3 < 60.0:
        await create_timer(0.5).timeout
        waited3 += 0.5
    _c("core-hunt run fight reaches an outcome (%.1fs)" % waited3, cs3._state == "over")
    _c("weak build vs Brassmore = DEATH", cs3.last_result == Combat.Result.DEATH)
    await create_timer(2.5).timeout                    # the unmaking (~1.9s) + banner fade
    _c("unmaking ends at the death banner", cs3._banner.text != "")

    # 12. guard-only build: the SURVIVABLE_LOSS slump path executes
    var cs4 := CombatScreen.new().setup(p)
    cs4.size = Vector2(1280, 720)
    get_root().add_child(cs4)
    await process_frame
    cs4.begin_spar(_fighter("core_ember", [["ARM_R", "arm_buckler"]]))
    await create_timer(2.0).timeout
    _c("guard-only spar = SURVIVABLE_LOSS + slump", cs4.last_result == Combat.Result.SURVIVABLE_LOSS and cs4._state == "over")

    print("SMOKE PASS" if _ok else "SMOKE FAIL")
    quit(0 if _ok else 1)

func _fighter(core_id: String, specs: Array) -> ManabitState:
    var m := ManabitState.new()
    var cat := Catalog.by_id()
    m.slots["CORE"] = PartInstance.new(cat[core_id])
    for spec in specs:
        m.slots[spec[0]] = PartInstance.new(cat[spec[1]])
    m.start_fight()
    return m

func _c(name: String, cond: bool) -> void:
    print(("  [%s] " % ("PASS" if cond else "FAIL")) + name)
    _ok = _ok and cond
