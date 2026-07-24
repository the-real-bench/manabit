extends Control
# Screen manager + persistence boot. Holds the shared PlayerState; swaps between screens:
#   Workshop (assemble) · Coffer Nook (open chests) · Menagerie (bound Manabits) · Compendium (bit-dex)

var player: PlayerState
var workshop: WorkshopScreen
var chest: ChestScreen
var menagerie: MenagerieScreen
var compendium: CompendiumScreen
var broker: BrokerScreen
var proving: ProvingScreen
var combat: CombatScreen
var run_screen: RunScreen
var run: RunState = null
var _in_run_fight := false
var _screens: Array = []
var _current_screen: Control = null
var _music_mourning := false        # a DEATH this session: the Workshop reopens ambience-only ~10s, then the box winds up (session-local, never persisted)

func _ready() -> void:
    set_anchors_preset(Control.PRESET_FULL_RECT)
    get_window().min_size = Vector2i(640, 360)   # canvas_items+expand scales below this instead of clipping
    player = PlayerState.new()
    if not SaveManager.load_into(player):
        player.grant_starter_kit()
        player.save()

    workshop = WorkshopScreen.new().setup(player)
    workshop.open_chests_requested.connect(func(): _show(chest))
    workshop.open_menagerie_requested.connect(func(): _show(menagerie))
    workshop.open_compendium_requested.connect(func(): _show(compendium))
    workshop.open_broker_requested.connect(func(): _show(broker))
    workshop.spar_requested.connect(func(build): combat.begin_spar(build); _show(combat))
    workshop.open_proving_requested.connect(func(): _show(proving))
    workshop.venture_requested.connect(_on_venture)
    workshop.kit_venture_requested.connect(_on_kit_venture)

    chest = ChestScreen.new().setup(player)
    chest.done.connect(func(): _show(workshop))
    chest.open_broker_requested.connect(func(): _show(broker))

    menagerie = MenagerieScreen.new().setup(player)
    menagerie.done.connect(func(): _show(workshop))

    compendium = CompendiumScreen.new().setup(player)
    compendium.done.connect(func(): _show(workshop))

    broker = BrokerScreen.new().setup(player)
    broker.done.connect(func(): _show(workshop))

    proving = ProvingScreen.new().setup(player)
    proving.session = workshop.session   # so Proving can show YOUR fielded stats
    proving.done.connect(func(): _show(workshop))
    proving.fight_requested.connect(func(entry): combat.begin_bout(workshop.session.manabit, entry); _show(combat))

    combat = CombatScreen.new().setup(player)
    combat.done.connect(_on_combat_done)

    run_screen = RunScreen.new().setup(player)
    run_screen.done.connect(func(): _show(workshop))
    run_screen.fight_requested.connect(_on_run_fight)

    _screens = [workshop, chest, menagerie, compendium, broker, proving, combat, run_screen]
    for s in _screens:
        s.set_anchors_preset(Control.PRESET_FULL_RECT)
        add_child(s)
    _show(workshop)

    # THE WOUND SPRING music box. On desktop the box winds up on ready; on web the AudioContext
    # is suspended until the first user gesture, so we defer to notify_first_input() from _input().
    Music.ensure()
    if not OS.has_feature("web"):
        Music.notify_first_input()

func _input(event: InputEvent) -> void:
    # HTML5 autoplay unlock: wake the music box on the first real user gesture. We never consume
    # the event - just wind the box up once, then this early-returns forever.
    if Music.is_unlocked():
        return
    if (event is InputEventMouseButton and event.pressed) \
            or (event is InputEventScreenTouch and event.pressed) \
            or (event is InputEventKey and event.pressed):
        Music.notify_first_input()

func _show(screen: Control) -> void:
    for s in _screens:
        s.visible = (s == screen)
    _current_screen = screen
    _apply_music_for(screen)
    if screen.has_method("refresh_from_player"):
        screen.refresh_from_player()

# Per-screen stem mix (audio-full-game.md 4.3 STEM_TARGETS). Hooked here in the screen manager so
# no Wire lane has to edit each screen. bench = full quartet, shop/nook = bells + pad, run =
# pulse + melody, combat = pulse only. Death keeps the room silent; the workshop mourns then rewinds.
func _apply_music_for(screen: Control) -> void:
    if screen == combat:
        Music.set_state(Music.State.COMBAT)
    elif screen == chest or screen == broker:
        Music.set_state(Music.State.SHOP)
    elif screen == run_screen:
        if _music_mourning:
            Music.stop_hard()               # a run ended in DEATH - the death screen keeps its silence
        else:
            Music.set_state(Music.State.RUN)
    elif screen == workshop:
        if _music_mourning:
            _music_mourning = false
            Music.stop_hard()               # the room mourns quietly...
            get_tree().create_timer(10.0).timeout.connect(_wind_up_bench)   # ...then the box winds up ~10s later
        else:
            Music.set_state(Music.State.BENCH)
    else:
        Music.set_state(Music.State.BENCH)  # menagerie / compendium / proving = cozy bench-side

func _wind_up_bench() -> void:
    if _current_screen == workshop:
        Music.wind_up(Music.State.BENCH)

# harness / external nav
func goto_workshop() -> void: _show(workshop)
func goto_chest() -> void: _show(chest)
func goto_menagerie() -> void: _show(menagerie)
func goto_compendium() -> void: _show(compendium)
func goto_broker() -> void: _show(broker)
func goto_proving() -> void: _show(proving)
func goto_combat() -> void: _show(combat)

func _on_venture(mname: String) -> void:
    run = RunState.new()
    run.start(workshop.session.manabit, mname)   # clones the build
    workshop.clear_build()                        # the bench build is spent on venturing
    run_screen.begin(run)
    _show(run_screen)

func _on_kit_venture() -> void:
    # Box of Scrap: consumes NO core, never touches the bench build. Capture the previewed seed,
    # THEN advance the nonce, so the run matches the crack-reveal and this box is spent (win/lose/die).
    var seed := player.kit_box_seed()
    player.spend_kit_box()
    player.save()
    run = RunState.new()
    run.start_kit(seed)
    run_screen.begin(run)
    _show(run_screen)

func _on_run_fight(node: Dictionary) -> void:
    _in_run_fight = true
    var kit: RunState = run if run.is_kit else null
    var mod: Dictionary = node.get("modifier", {})
    var rider := run.take_fight_rider()   # shrine rider - consumed at the pre-bell seam, one bell only
    combat.begin_run_fight(run.carried, node.get("challenger", {}), bool(node.get("aims_core", false)), kit, String(mod.get("id", "")), rider)
    _show(combat)

func _on_combat_done() -> void:
    var res := combat.last_result
    if res == Combat.Result.DEATH:
        _music_mourning = true          # set BEFORE the show so _apply_music_for honors the silence
    if _in_run_fight:
        _in_run_fight = false
        run_screen.resolve_fight(combat.last_result)
        _show(run_screen)
    else:
        _show(workshop)
    if res == Combat.Result.SURVIVABLE_LOSS:
        Music.subdue(-6.0, 10.0)        # loss_settle rang alone; music returns subdued, not punished
