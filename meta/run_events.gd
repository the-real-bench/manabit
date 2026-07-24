class_name RunEvents extends RefCounted
# The Wayside Shrine - the Template A pos1 REST flavor (design/economy/venture-depth-wave3.md 2).
# A table + pure resolve, mirroring RunMods. Events are MONEY-NEUTRAL in v1: the only outcome
# verbs are mend / wear / next-foe-worn rider. NO scrap, NO satchel, NO loot, NO purse, NO
# Glimmer, NO bank, NO bench - smoke_run T4 asserts the absence structurally.
#
# Crack-and-see parity law: every draw derives from the map seed through mix(), a splitmix64
# finalizer masked to 63 bits (THE reference certified in tools/sim/sim_ladder.gd _w3_mix - the
# two must stay byte-identical). Same box = same road = same shrine = same heap. The push result
# is DECIDED at map-make (stamped roll) and only REVEALED on choice - no post-choice RNG feel-bad.
#   h  = mix(map_seed);  d2 = h % 23 (weighted pick);  d3 = (h / 100) % 100 (hidden outcome roll)
#   heap dig: g = mix2(map_seed) = mix(mix(seed));  r1 = g % 100;  r2 = g / 100 (lend pick)

# Printed odds in plain words, Barrow ethic: "2 in 3" = roll < 67, "1 in 2" = roll < 50.
# The stakes line IS the rule, verbatim, <= 72 chars. Choice titles <= 28 chars.
# Weights: COMMON 3, UNCOMMON 2, RARE 1 (5x3 + 3x2 + 2x1 = 23).
const WEIGHT_TOTAL := 23

# Wear rail: total <= 4 HP per event, floor 1 HP, NEVER CORE, never disables - events are
# never lethal by construction. Fixed slot order for the generic pool walker.
const WEAR_ORDER := ["ARM_R", "ARM_L", "LEGS", "BACK", "HEAD"]

# Honest mend copy at full HP (spec 2.1) - a hale box gets a pat, not a lie.
const FULL_HP_MEND_TEXT := "Already hale - it pats your hull and lets you by."

const TABLE := [
    {
        "id": "clockwork_wren", "name": "The Clockwork Wren", "weight": 3,
        "vignette": [
            "A brass wren sits on the shrine rail, one wing ticking out of time.",
            "It looks at you. It looks at its wing. It looks at you again.",
        ],
        "safe": {"title": "Wind it gently", "stakes": "Sure: mend 2",
            "effect": {"mend": 2},
            "result": "It chirps twice and taps your hull where it hurts. Better."},
        "push": {"title": "Ask for the long song",
            "stakes": "2 in 3: mend 4 - else one arm wears 2", "thr": 67,
            "good": {"effect": {"mend": 4},
                "text": "The song winds through your seams and settles them. Mend 4."},
            "bad": {"effect": {"wear": 2, "at": "ARM"},
                "text": "The last note snags. Your arm buzzes wrong for miles. Wear 2."}},
    },
    {
        "id": "toll_doll", "name": "The Toll Doll", "weight": 3,
        "vignette": [
            "A porcelain doll minds a bridge no wider than a plank.",
            "It holds out a cup with great ceremony. The cup is empty. So is the toll.",
        ],
        "safe": {"title": "Bow and pass", "stakes": "Sure: next foe steps in worn 1",
            "effect": {"rider": 1},
            "result": "The doll bows back and whispers a weakness it once saw. Noted."},
        "push": {"title": "Juggle for the doll",
            "stakes": "2 in 3: next foe worn 2 - else LEGS wear 2", "thr": 67,
            "good": {"effect": {"rider": 2},
                "text": "Delighted, it tells you everything. The next foe is worn 2."},
            "bad": {"effect": {"wear": 2, "at": "LEGS"},
                "text": "You drop a bolt on your own foot. The doll pretends not to see."}},
    },
    {
        "id": "kettle_sprite", "name": "The Kettle Sprite", "weight": 3,
        "vignette": [
            "A copper kettle steams by the shrine, though no one lit a fire.",
            "Something small inside hums a tune with two wrong notes.",
        ],
        "safe": {"title": "Share a sit", "stakes": "Sure: mend 3",
            "effect": {"mend": 3},
            "result": "Warm steam finds the dents. You leave looser than you came."},
        "push": {"title": "Peek in the kettle",
            "stakes": "2 in 3: mend 5 - else wear 1", "thr": 67,
            "good": {"effect": {"mend": 5},
                "text": "The sprite beams and boils you a proper cure. Mend 5."},
            "bad": {"effect": {"wear": 1},
                "text": "It startles and spits a hot bead. Barely a mark. Wear 1."}},
    },
    {
        "id": "sleepy_signpost", "name": "The Sleepy Signpost", "weight": 3,
        "vignette": [
            "The signpost yawns. Its three arms point three ways to the same road.",
            "\"Shortcut,\" it mumbles. \"Or the truth. Pick one, I'm napping.\"",
        ],
        "safe": {"title": "Ask plainly", "stakes": "Sure: next foe steps in worn 1",
            "effect": {"rider": 1},
            "result": "It names the next brute and where its plating gaps. Worn 1."},
        "push": {"title": "Take the shortcut",
            "stakes": "2 in 3: next foe worn 1 + mend 3 - else wear 3", "thr": 67,
            "good": {"effect": {"rider": 1, "mend": 3},
                "text": "The cut path is soft moss and good news. Mend 3, foe worn 1."},
            "bad": {"effect": {"wear": 3},
                "text": "The shortcut was a hedge. The hedge disagreed. Wear 3."}},
    },
    {
        "id": "rain_soaked_coffer", "name": "The Rain-Soaked Coffer", "weight": 3,
        "vignette": [
            "A little coffer sits in the ditch, swollen with last night's rain.",
            "Something inside knocks, patient as a clock.",
        ],
        "safe": {"title": "Tip the water out", "stakes": "Sure: mend 2",
            "effect": {"mend": 2},
            "result": "Clean rainwater, good for rinsing grit from joints. Mend 2."},
        "push": {"title": "Wrench it open",
            "stakes": "1 in 2: mend 6 - else both arms wear 2", "thr": 50,
            "good": {"effect": {"mend": 6},
                "text": "Oil, wadding, and a tinker's kit, bone dry. Mend 6."},
            "bad": {"effect": {"wear": 2, "at": "ARMS"},
                "text": "The lid snaps back on both your hands. Each arm wears 2."}},
    },
    {
        "id": "moss_kept_milestone", "name": "The Moss-Kept Milestone", "weight": 2,
        "vignette": [
            "An old milestone wears a coat of moss like a favorite jumper.",
            "Under the green, carved marks - someone counted more than miles here.",
        ],
        "safe": {"title": "Read the old miles", "stakes": "Sure: next foe steps in worn 1",
            "effect": {"rider": 1},
            "result": "The marks tally every traveler's scrapes. You know its limp."},
        "push": {"title": "Dig at the base",
            "stakes": "2 in 3: next foe worn 2 + mend 2 - else LEGS wear 2", "thr": 67,
            "good": {"effect": {"rider": 2, "mend": 2},
                "text": "A watcher's cache: notes and balm. Foe worn 2, mend 2."},
            "bad": {"effect": {"wear": 2, "at": "LEGS"},
                "text": "The stone settles onto your foot. Politely. LEGS wear 2."}},
    },
    {
        "id": "button_merchant", "name": "The Button Merchant", "weight": 2,
        "vignette": [
            "A vole in a waistcoat has arranged nine buttons on a handkerchief.",
            "\"Plain button, fair trade. Mystery button - ah. The mystery.\"",
        ],
        "safe": {"title": "The plain button", "stakes": "Sure: mend 2",
            "effect": {"mend": 2},
            "result": "It fits a seam you did not know was loose. Solid trade."},
        "push": {"title": "The mystery button",
            "stakes": "2 in 3: next foe worn 2 - else nothing", "thr": 67,
            "good": {"effect": {"rider": 2},
                "text": "The button hums a warning about the road ahead. Foe worn 2."},
            "bad": {"effect": {},
                "text": "It is an acorn. The vole shrugs. You keep the acorn."}},
    },
    {
        "id": "rust_rooks", "name": "The Rust-Rooks", "weight": 2,
        "vignette": [
            "Three rooks with rusted beaks take turns polishing a kettle lid.",
            "They eye your seams the way jewelers eye a cracked ring.",
        ],
        "safe": {"title": "Watch them work", "stakes": "Sure: mend 2",
            "effect": {"mend": 2},
            "result": "You copy their trick on your own plating. Neat. Mend 2."},
        "push": {"title": "Borrow the polish rag",
            "stakes": "2 in 3: mend 4 - else wear 2", "thr": 67,
            "good": {"effect": {"mend": 4},
                "text": "The rag knows its business better than you do. Mend 4."},
            "bad": {"effect": {"wear": 2},
                "text": "The rooks want it back. All three of them. At once. Wear 2."}},
    },
    {
        "id": "gearwrights_ghost_light", "name": "The Gearwright's Ghost-Light", "weight": 1,
        "vignette": [
            "A lantern-glow drifts over the shrine with no lantern in it.",
            "It hums an old workshop song. It knows your maker's marks.",
        ],
        "safe": {"title": "Hum along", "stakes": "Sure: mend 3",
            "effect": {"mend": 3},
            "result": "The glow settles on your shoulder a while. Things sit right."},
        "push": {"title": "Follow it",
            "stakes": "1 in 2: mend 6 - else wear 4", "thr": 50,
            "good": {"effect": {"mend": 6},
                "text": "It leads you to a gearwright's forgotten bench. Mend 6."},
            "bad": {"effect": {"wear": 4},
                "text": "It leads you through a briar and is gone. Wear 4."}},
    },
    {
        "id": "barrow_wisp", "name": "The Barrow-Wisp", "weight": 1,
        "vignette": [
            "A pale wisp circles you twice, then tugs your arm toward the dark.",
            "It is either very lost or very sure. Possibly both.",
        ],
        "safe": {"title": "Carry it to the lamppost", "stakes": "Sure: next foe steps in worn 1",
            "effect": {"rider": 1},
            "result": "At the lamp it brightens and spills a secret about the road."},
        "push": {"title": "Let it ride",
            "stakes": "1 in 2: next foe worn 2 + mend 3 - else wear 2", "thr": 50,
            "good": {"effect": {"rider": 2, "mend": 3},
                "text": "It rides your shoulder, mending and muttering. Worth it."},
            "bad": {"effect": {"wear": 2},
                "text": "It slips into your seams, tickles, and leaves. Wear 2. It waves."}},
    },
]

# ---------------------------------- the mix (parity law) ----------------------------------
# splitmix64 finalizer masked to 63 bits. MUST stay byte-identical to sim_ladder.gd _w3_mix -
# the certified pure-mix model (n=30000) is the G4 reference the shipped hash is judged against.

static func _ushr(z: int, n: int) -> int:
    return (z >> n) & ~((-1) << (64 - n))

static func mix(x: int) -> int:
    var z: int = x + -0x61C8864680B583EB                 # 0x9E3779B97F4A7C15 as signed int64
    z = (z ^ _ushr(z, 30)) * -0x40A7B892E31B1A47         # 0xBF58476D1CE4E5B9 as signed int64
    z = (z ^ _ushr(z, 27)) * -0x6B2FB644ECCEEE15         # 0x94D049BB133111EB as signed int64
    z = z ^ _ushr(z, 31)
    return z & 0x7FFFFFFFFFFFFFFF

static func mix2(x: int) -> int:
    return mix(mix(x))

# Static probe: the event pick + hidden roll for a map seed - tests pin seeds without a map.
@warning_ignore("integer_division")
static func pick(seed: int) -> Dictionary:
    var h := mix(seed)
    var d2: int = h % WEIGHT_TOTAL
    var d3: int = (h / 100) % 100
    var acc := 0
    for ev in TABLE:
        var e: Dictionary = ev
        acc += int(e["weight"])
        if d2 < acc:
            return {"event_id": String(e["id"]), "roll": d3}
    return {"event_id": String((TABLE[0] as Dictionary)["id"]), "roll": d3}

# The Magpie's Heap dig for a map seed - second mix round, independent of the shrine draw.
# r1 is the outcome band (< 55 lend COMMON, < 85 filings, else lend RARE); r2 picks within
# the discovered-first pool. Decided at map-make, revealed on commit.
@warning_ignore("integer_division")
static func heap_dig(seed: int) -> Dictionary:
    var g := mix2(seed)
    return {"r1": g % 100, "r2": g / 100}

static func event(id: String) -> Dictionary:
    for ev in TABLE:
        var e: Dictionary = ev
        if String(e["id"]) == id:
            return e
    return {}

# ---------------------------------- resolution law (spec 2.3) ----------------------------------
# No-op unless the current node is a REST with flavor "event", unresolved, and choice_i in
# {0, 1}. Applies effects, then stamps the node IN PLACE - irreversible, idempotent on re-call.
# The safe choice (0) ignores the roll - deterministic by rule. node()/advance()/can_extract()
# are untouched; the UI gates the forward verb behind resolution.
static func resolve(run: RunState, choice_i: int) -> Dictionary:
    if run == null or run.over or run.carried == null:
        return {}
    var nd: Dictionary = run.node()
    if String(nd.get("type", "")) != "REST" or String(nd.get("flavor", "")) != "event":
        return {}
    if bool(nd.get("resolved", false)):
        return {}
    if choice_i != 0 and choice_i != 1:
        return {}
    var e := event(String(nd.get("event_id", "")))
    if e.is_empty():
        return {}
    var result_id := "safe"
    var eff: Dictionary = {}
    var text := ""
    if choice_i == 0:
        var safe: Dictionary = e["safe"]
        eff = safe["effect"]
        text = String(safe["result"])
    else:
        var push: Dictionary = e["push"]
        result_id = "good" if int(nd.get("roll", 0)) < int(push["thr"]) else "bad"
        var oc: Dictionary = push[result_id]
        eff = oc["effect"]
        text = String(oc["text"])
    var mended := 0
    if int(eff.get("mend", 0)) > 0:
        mended = RunMods._mend(run.carried, int(eff.get("mend", 0)))   # the shipped mend rail
    var wore := _apply_wear(run.carried, eff)
    var rider: int = int(eff.get("rider", 0))
    if rider > 0:
        run.next_fight_rider = maxi(run.next_fight_rider, mini(rider, RunMods.WEAR))
    if int(eff.get("mend", 0)) > 0 and mended == 0 and wore == 0 and rider == 0:
        text = FULL_HP_MEND_TEXT                       # honest at full HP (spec 2.1)
    nd["resolved"] = true
    nd["chose"] = choice_i
    nd["result_id"] = result_id
    nd["result_text"] = text
    return {"result_id": result_id, "text": text, "mended": mended, "wore": wore, "rider": rider}

# The wear rail (spec 2.4): total <= 4 HP, floor 1 HP per bit, never CORE, never disables.
# "at" targets: "ARM" = the first arm that can wear (one arm only), "ARMS" = each arm wears N,
# "LEGS" = the legs bit, "" = the generic fixed-order pool walker. Untargetable wear fizzles -
# events are never lethal and never disable, by construction.
static func _apply_wear(m: ManabitState, eff: Dictionary) -> int:
    var n: int = int(eff.get("wear", 0))
    if n <= 0:
        return 0
    match String(eff.get("at", "")):
        "ARM":
            return _wear_slots(m, ["ARM_R", "ARM_L"], n, true)
        "ARMS":
            return _wear_slots(m, ["ARM_R"], n, false) + _wear_slots(m, ["ARM_L"], n, false)
        "LEGS":
            return _wear_slots(m, ["LEGS"], n, false)
        _:
            return _wear_slots(m, WEAR_ORDER, n, false)

static func _wear_slots(m: ManabitState, slots: Array, pool: int, first_only: bool) -> int:
    var wore := 0
    for slot in slots:
        if pool <= 0:
            break
        var pi: PartInstance = m.slots.get(slot)
        if pi == null or pi.disabled:
            continue
        var cut: int = mini(pool, pi.current_hp - 1)   # floor 1 HP - never disables, never lethal
        if cut <= 0:
            continue
        pi.current_hp -= cut
        pool -= cut
        wore += cut
        if first_only:
            break
    return wore
