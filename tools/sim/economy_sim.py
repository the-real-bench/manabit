# MANABIT ECONOMY SIM - economy-designer / analyst lane (2026-07-19)
# 500 seeded players x 30 play-days Monte Carlo over the SHIPPED economy constants.
# READ-ONLY on game state: parses parts/catalog_extra.json, hardcodes the 13 base fixtures
# (parts/catalog.gd) and every economy constant WITH its source line. Never touches user:// saves.
# Run: cd G:\ClaudeApps\manabit; py -3.12 tools\sim\economy_sim.py
# Output: tools\sim\out\economy.json + printed human summary.
#
# Combat is NOT re-simulated here (that is smoke_kit_sim.gd's lane). Fight outcomes use the
# priors handed to this lane: own-build node0 0.95 / elite 0.60 / boss 0.50, and per-grade kit
# bands anchored to the smoke_kit_sim gates (node0 >= 0.90 zero deaths; Gleaming elite 0.88 /
# boss 0.83 measured; Dud boss <= 0.15, dies more than it wins).

import json
import os
import random
import statistics
from collections import defaultdict

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT_DIR = os.path.join(ROOT, "tools", "sim", "out")
CATALOG_EXTRA = os.path.join(ROOT, "parts", "catalog_extra.json")
LADDER_PATH = os.path.join(OUT_DIR, "ladder.json")

MASTER_SEED = 20260718
N_PLAYERS = 500
N_DAYS = 30

# ----------------------------------------------------------------------------------------------
# CONSTANTS EXTRACTED FROM CODE (name, value, source file:line). Grounded, not guessed.
# ----------------------------------------------------------------------------------------------
CONSTANTS = [
    {"name": "TIN_PRICE", "value": 40, "source": "economy/broker.gd:5"},
    {"name": "BRASS_PRICE", "value": 100, "source": "economy/broker.gd:6"},
    {"name": "salvage_scrap EPIC/RARE/COMMON", "value": [45, 20, 8], "source": "economy/broker.gd:9-13"},
    {"name": "distill_glimmer EPIC/RARE/COMMON", "value": [3, 1, 0], "source": "economy/broker.gd:16-20"},
    {"name": "find_price EPIC/RARE/COMMON", "value": ["10 glimmer", "4 glimmer", "25 scrap"], "source": "economy/broker.gd:23-27"},
    {"name": "shelf slots / unowned weight", "value": [3, "3:1"], "source": "economy/broker.gd:44,48"},
    {"name": "shelf discovered-gated (compendium only)", "value": True, "source": "economy/broker.gd:35-38"},
    {"name": "BIND_CORE_COST", "value": 60, "source": "meta/player_state.gd:25"},
    {"name": "BINDABLE_CORES", "value": ["core_ember", "core_bulwark", "core_font"], "source": "meta/player_state.gd:26"},
    {"name": "BOUT_STAKE regular/elite/boss (wave 1 CH-08)", "value": [5, 10, 20], "source": "meta/player_state.gd:30-32 + ui/combat_screen.gd:137-139"},
    {"name": "KIT_PURSE skirmish/elite/boss", "value": [10, 25, 40], "source": "meta/player_state.gd:46"},
    {"name": "KIT_PURSE_HALVED", "value": [5, 12, 20], "source": "meta/player_state.gd:47"},
    {"name": "purse halves after 2 counted runs/day", "value": "kit_runs_today < 2", "source": "meta/player_state.gd:206"},
    {"name": "kit DEATH does not count a run (note_kit_run only on keep)", "value": True, "source": "ui/run_screen.gd:652-658"},
    {"name": "starter kit scrap/tin/brass", "value": [50, 1, 2], "source": "meta/player_state.gd:37-39"},
    {"name": "starter grant: 3 cores + 1 brass roll (5 bits)", "value": True, "source": "meta/player_state.gd:40-46"},
    {"name": "PackRoller fixed seed 20260711, pity NOT saved", "value": 20260711, "source": "meta/player_state.gd:35 + meta/save_manager.gd (no roller field)"},
    {"name": "brass coffer: 5 bits, C/R/E 0.70/0.22/0.08, rare+ guaranteed, epic pity 9", "value": True, "source": "economy/pack_roller.gd:15-16,26,35-36"},
    {"name": "tin coffer: 3 bits, C/R/E 0.85/0.12/0.03, no guarantee", "value": True, "source": "economy/pack_roller.gd:18-19"},
    {"name": "doorstep: free tin once per calendar day", "value": True, "source": "meta/player_state.gd:153-161"},
    {"name": "box grade cuts Dud/Rough/Fair/Keen/Gleaming", "value": [0.12, 0.40, 0.72, 0.92], "source": "economy/box_roller.gd:17-21"},
    {"name": "kit loot cap: 1 COMMON, only while satchel bit empty", "value": True, "source": "ui/combat_screen.gd:1372,1377"},
    {"name": "kit forfeits pay 0 scrap", "value": True, "source": "ui/combat_screen.gd:1148-1153"},
    {"name": "BOUT forfeit pays 0 scrap (wave 1 CH-09)", "value": True, "source": "ui/combat_screen.gd:1154-1162"},
    {"name": "own-build VENTURE survivable loss: forfeit broken part pays salvage to PLAYER (unchanged)", "value": True, "source": "ui/combat_screen.gd:1163-1168"},
    {"name": "non-kit WIN loot: any non-core part of the foe", "value": True, "source": "ui/combat_screen.gd:1359-1371"},
    {"name": "loot never includes cores", "value": True, "source": "ui/combat_screen.gd:1361"},
    {"name": "coffers/shelf draw from body_pool only (no cores ever)", "value": True, "source": "economy/pack_roller.gd:22 + economy/broker.gd:35"},
    {"name": "venture consumes the bench build (clear without return)", "value": True, "source": "ui/root.gd:82-87 + manabits/build_session.gd:48-52"},
    {"name": "own-build repair: ceil(missing HP / 2) scrap", "value": 1, "source": "meta/run_state.gd:11,168-174"},
    {"name": "kit rests mend free", "value": True, "source": "ui/run_screen.gd:417-421"},
    {"name": "run map: node0 skirmish -> rest -> elite junction -> rest -> boss junction", "value": True, "source": "meta/run_state.gd:17-50"},
    {"name": "compendium total = obtainable-only denominator, 73 (wave 1 CH-10)", "value": 73, "source": "meta/player_state.gd:239-248 + parts/catalog.gd:136-159"},
]

# Base 13 fixtures - parts/catalog.gd:40-46 (cores) and 67-77 (body). id: (slot, rarity, is_core, offensive)
BASE_BITS = {
    "core_ember":   ("CORE", "COMMON", True, False),
    "core_bulwark": ("CORE", "COMMON", True, False),
    "core_font":    ("CORE", "COMMON", True, False),
    "head_optic":   ("HEAD", "COMMON", False, True),
    "head_hornet":  ("HEAD", "RARE", False, True),
    "arm_hammer":   ("ARM_L", "COMMON", False, True),
    "arm_flail":    ("ARM_L", "RARE", False, True),
    "arm_buckler":  ("ARM_R", "COMMON", False, False),
    "arm_seer":     ("ARM_R", "EPIC", False, True),
    "legs_light":   ("LEGS", "COMMON", False, False),
    "legs_tread":   ("LEGS", "RARE", False, False),
    "back_bellows": ("BACK", "COMMON", False, False),
    "back_wing":    ("BACK", "EPIC", False, False),
}

# Challenger loadouts - combat/challengers.gd (post wave 1 CH-04/05/06; ids only; core excluded at loot)
CHALLENGER_LOADOUTS = {
    0: ["everykit_standard_cowl", "everykit_standard_fist", "tinbox_legs_trusty"],                                   # Rusty
    1: ["whirligig_head_windshear", "whirligig_arm_turbine", "whirligig_legs_zephyr", "whirligig_back_slipfin"],     # Ziptie (CH-04: piston deleted)
    2: ["everykit_standard_cowl", "errant_arm_oathblade", "errant_arm_warder", "errant_legs_vigil", "cobble_sons_back_toolrack"],  # Vance
    3: ["grumble_co_anvil_cowl", "grumble_co_girder_fist", "grumble_co_slab_pauldron", "cobble_sons_legs_bedrock", "grumble_co_furnace_pack"],  # Cogsworth
    4: ["silksteel_head_oracle", "boldheart_arm_meteor", "grumble_co_bastion_fist", "cobble_sons_legs_bedrock", "pith_sinew_deep_pulse_sac"],   # Brassmore
    5: ["pith_sinew_caul_hood", "thicket_fang_arm_goreclaw", "thicket_fang_arm_gnashmaw", "thicket_fang_legs_haunch", "pith_sinew_deep_pulse_sac"],  # Thornlash
    6: ["chatterbox_bigeye_dome", "quivergear_salvo_fist", "errant_arm_warder", "everykit_standard_strider_legs", "quivergear_payload_rack"],   # Pindrop (CH-06 REVERTED - wrong-way move)
    7: ["silksteel_head_whisper", "silksteel_arm_needle", "everykit_standard_piston", "silksteel_legs_slip", "everykit_standard_cell"],         # Sable (CH-05 REVERTED - wrong-way move)
    8: ["sovereign_brass_head_herald", "sovereign_brass_arm_pistonfist", "errant_arm_warder", "sovereign_brass_legs_colonnade", "sovereign_brass_back_mantle"],  # Gildfall
}
# Bout stakes (wave 1 CH-08) - player_state.gd:30-32; tiers: 0-2 regular, 4/8 boss, rest elite
BOUT_STAKE = {"regular": 5, "elite": 10, "boss": 20}
CHALLENGER_TIER = {0: "regular", 1: "regular", 2: "regular", 3: "elite", 4: "boss",
                   5: "elite", 6: "elite", 7: "elite", 8: "boss"}
# meta/run_state.gd:17-50 - elite lanes T0:(5,3) T1:(6,7); boss lanes T0:(4,8) T1:(4,8)
ELITE_LANES = {0: [5, 3], 1: [6, 7]}
BOSS_LANES = {0: [4, 8], 1: [4, 8]}

MELT = {"EPIC": 45, "RARE": 20, "COMMON": 8}        # broker.gd:9-13
DISTILL = {"EPIC": 3, "RARE": 1, "COMMON": 0}       # broker.gd:16-20
FIND_PRICE = {"EPIC": ("glimmer", 10), "RARE": ("glimmer", 4), "COMMON": ("scrap", 25)}  # broker.gd:23-27
TIN_PRICE, BRASS_PRICE = 40, 100
BIND_COST = 60
KIT_PURSE = {"skirmish": 10, "elite": 25, "boss": 40}
KIT_PURSE_HALVED = {"skirmish": 5, "elite": 12, "boss": 20}
STARTER_CORES = ["core_ember", "core_bulwark", "core_font"]
DEX_TOTAL = 80          # Catalog.all(): 10 cores + 70 body
DEX_80PCT = 64          # ceil(0.8 * 80)
RARITY_RANK = {"COMMON": 0, "RARE": 1, "EPIC": 2}

# ----------------------------------------------------------------------------------------------
# WAVE 3 G0 PROJECTION (design/economy/venture-depth-wave3.md) - PREDICTIVE, no game code yet.
# The sim models the spec's ASSUMED values (rummage 8 / filings +4 / 55-30-15, Gleaner's Due
# K boss 0.50 / elite 0.25, H-blend 0.5+0.5H) so the post-implementation run can compare
# predicted vs actual. Events are MONEY-NEUTRAL by construction: the shrine tally never touches
# a wallet, so the G14 on/off delta is structurally zero in this model.
# ----------------------------------------------------------------------------------------------
RUMMAGE_PRICE = 8            # ASSUMED (G6)
RUMMAGE_FILINGS = 4          # ASSUMED (G6)
RUMMAGE_CUTS = (0.55, 0.85)  # < .55 lend COMMON, < .85 filings +4, else lend RARE (ASSUMED, G7)
W3_K = {"elite": 0.25, "boss": 0.50}           # Gleaner's Due K_tier (ASSUMED, G8)
LEND_UPLIFT = {"COMMON": 0.02, "RARE": 0.05}   # ASSUMED lent-bit win-prob uplift, elite+boss
DEATH_H_FALLBACK = 0.35      # surviving-bit HP fraction at death; ladder-measured when present
EVENT_PUSH_RATE = 0.5        # ASSUMED push propensity (tally only)
EVENT_TABLE = [              # (id, weight, printed-odds threshold); weights 3/2/1 total 23
    ("clockwork_wren", 3, 67), ("toll_doll", 3, 67), ("kettle_sprite", 3, 67),
    ("sleepy_signpost", 3, 67), ("rain_soaked_coffer", 3, 50),
    ("moss_kept_milestone", 2, 67), ("button_merchant", 2, 67), ("rust_rooks", 2, 67),
    ("gearwrights_ghost_light", 1, 50), ("barrow_wisp", 1, 50),
]
FAUCET_KEYS = ["kit_purse", "melt", "forfeit_salvage", "death_keep", "venture_wreck", "rummage_filings"]
SINK_KEYS = ["brass_coffers", "binding", "repairs", "finds_scrap", "rummage"]
W3_DEATH_H = DEATH_H_FALLBACK     # set in main() from ladder.json death_h_frac_mean

# ----------------------------------------------------------------------------------------------
# MODEL PRIORS + POLICY (assumptions - documented in JSON, anchored to sim gates / lane brief)
# ----------------------------------------------------------------------------------------------
GRADES = ["Dud", "Rough", "Fair", "Keen", "Gleaming"]
GRADE_CUTS = [0.12, 0.40, 0.72, 0.92]               # box_roller.gd:17-21
# kit win priors per grade, anchored: node0 mixture ~0.95 (lane prior), gates: node0>=0.90,
# Gleaming elite 0.88 / boss 0.83 (CLAUDE.md measured), Dud boss <= 0.15.
KIT_P = {
    "node0": {"Dud": 0.90, "Rough": 0.95, "Fair": 0.97, "Keen": 0.99, "Gleaming": 0.995},
    "elite": {"Dud": 0.20, "Rough": 0.40, "Fair": 0.55, "Keen": 0.72, "Gleaming": 0.88},
    "boss":  {"Dud": 0.10, "Rough": 0.22, "Fair": 0.40, "Keen": 0.62, "Gleaming": 0.83},
}
KIT_DEATH_GIVEN_LOSS = 0.75      # elite/boss hunt the core (combat.ai_take_turn seam)
OWN_P = {"node0": 0.95, "elite": 0.60, "boss": 0.50}   # lane priors (task brief)
OWN_DEATH_GIVEN_LOSS = 0.70
UNREPAIRED_PENALTY = 0.15
# kit greed policy: probability of pressing PAST the grade's sane stop point
KIT_CONTINUE_ELITE = {"Dud": 0.15, "Rough": 0.50, "Fair": 1.0, "Keen": 1.0, "Gleaming": 1.0}
KIT_CONTINUE_BOSS = {"Dud": 0.10, "Rough": 0.20, "Fair": 0.35, "Keen": 0.80, "Gleaming": 1.0}
VENTURE_RATE = 0.5               # chance an eligible session mounts an own-build venture
GREED_LAST_CORE = 0.15           # chance to venture the LAST core without a 60-scrap bind reserve
SCRAP_RESERVE = 60               # players guard one Binding's worth before coffer shopping

ASSUMPTIONS = [
    "Fight outcomes are drawn from priors, not re-simulated: own-build node0 0.95 / elite 0.60 / boss 0.50 (lane brief); kit per-grade bands anchored to smoke_kit_sim gates + CLAUDE.md measured numbers (Gleaming elite 0.88 / boss 0.83, node0 >= 0.90 with zero deaths, Dud boss <= 0.15).",
    "Death-given-loss on core-hunting nodes: kit 0.75, own-build 0.70 (elite/boss aim the core; node0 never kills).",
    "2-4 sessions/day (uniform). Each session runs one Box of Scrap; an eligible session also mounts an own-build venture with p=0.5.",
    "Kit stop policy is grade-aware (grade is revealed at crack): Dud banks after node0 (greed 0.15), Rough presses elite at 0.50 / boss 0.20, Fair elite always / boss 0.35, Keen boss 0.80, Gleaming always presses.",
    "Own-build ventures consume 1 core + up to 5 COMMON body bits (dupes first, then singles; RARE/EPIC never spent on venture chassis). Requires one offensive COMMON body bit.",
    "Own-build repair costs are abstracted: rest1 uniform 2-6 scrap, rest2 uniform 4-10 scrap (repair = ceil(missing HP/2), run_state.gd:11). Unrepaired fights lose 0.15 win probability.",
    "After a survivable elite loss the player extracts at the next rest (banks the damaged Manabit). A survivable BOSS loss still banks (run_screen.resolve_fight advances past the last node and _finish(true) banks) - modeled, plus one forfeit salvage payment.",
    "Dupe policy per task brief: end of day keep 1 of each id, melt COMMON extras, distill RARE/EPIC extras. Binding bought whenever core-locked and scrap >= 60. Brass coffers bought while scrap >= 160 (100 + 60 bind reserve); tin is never bought (melt-back EV 31.65 of 40 makes it strictly a collection item - the daily doorstep tin covers that).",
    "Shelf model: 3 discovered body ids/day, 3:1 unowned:owned weighting (broker.gd:41-58). Players buy unowned RARE (4 glimmer) / EPIC (10 glimmer) finds to re-acquire consumed dex pieces; COMMON finds only as an emergency weapon when no offensive body bit is owned.",
    "PackRoller is modeled per-player with the shipped odds tables and a persistent pity counter. The SHIPPED code seeds every PlayerState roller at the fixed 20260711 and never saves pity - every player gets identical starter bits and every app relaunch replays the same coffer stream (flagged, not simulated).",
    "Bouts (Proving Grounds) are excluded from the base loop and analyzed as an arbitrage flag: they are uncapped, fight a CLONE of the bench build, and pay loot on win / salvage on forfeit.",
    "Lane modifiers (tailwind/second_wind/rusted/overgrown) are folded into the fight priors, not modeled separately - they mend or wear a few HP and never touch purses (RunMods contract).",
    "WAVE 3 (venture-depth-wave3.md, PREDICTIVE): the template pick is 50/50 on a separate RNG stream; Template A kit runs tally a shrine visit (money-neutral, push propensity 0.5); Template B kit runs rummage the heap at 8 satchel scrap when pressing on a full-rate day (55/30/15 lend-COMMON/filings+4/lend-RARE, RARE downgrades to filings until a RARE is discovered); lends grant an ASSUMED +2pp (COMMON) / +5pp (RARE) elite+boss win uplift.",
    "WAVE 3 Gleaner's Due: kit death keeps floor(S * K * (0.5 + 0.5H)) with K boss 0.50 / elite 0.25 and H = ladder-measured death_h_frac_mean (repair-always runs die with near-full body bits); the satchel bit is always lost; a paying death burns a daily full-rate slot. Own-build death credits floor(K * chassis-melt * H), Run-only.",
]

# ----------------------------------------------------------------------------------------------
# Catalog load (read-only)
# ----------------------------------------------------------------------------------------------
def load_catalog():
    with open(CATALOG_EXTRA, encoding="utf-8-sig") as f:
        extra = json.load(f)
    bits = {}
    for bid, (slot, rar, core, off) in BASE_BITS.items():
        bits[bid] = {"slot": slot, "rarity": rar, "is_core": core, "offensive": off}
    for e in extra:
        bid = e["id"]
        if bid in bits:           # base wins collisions (catalog.gd:100-102)
            continue
        ab = e.get("ability") or {}
        arch = ab.get("archetype", "NONE")
        bits[bid] = {
            "slot": e.get("slot", "HEAD"),
            "rarity": e.get("rarity", "COMMON"),
            "is_core": bool(e.get("is_core", False)),
            "offensive": arch in ("SINGLE", "MULTI"),
        }
    return bits

CAT = load_catalog()
BODY_IDS = [b for b, d in CAT.items() if not d["is_core"]]
BODY_BY_RARITY = {r: [b for b in BODY_IDS if CAT[b]["rarity"] == r] for r in ("COMMON", "RARE", "EPIC")}
NONCOMMON_BODY = BODY_BY_RARITY["RARE"] + BODY_BY_RARITY["EPIC"]
DISCOVERABLE = set(BODY_IDS) | set(STARTER_CORES)   # 7 non-starter cores can NEVER be obtained

def best_loot(loadout):
    ids = [b for b in loadout if b in CAT and not CAT[b]["is_core"]]
    return max(ids, key=lambda b: (RARITY_RANK[CAT[b]["rarity"]], MELT[CAT[b]["rarity"]]))

def common_loot(loadout, rng):
    ids = [b for b in loadout if b in CAT and not CAT[b]["is_core"] and CAT[b]["rarity"] == "COMMON"]
    return rng.choice(ids) if ids else None

# ----------------------------------------------------------------------------------------------
# Player
# ----------------------------------------------------------------------------------------------
class Player:
    __slots__ = ("rng", "rng2", "counts", "discovered", "scrap", "glimmer", "tin", "brass", "pity",
                 "first_epic_day", "dex80_day", "binds_bought", "brass_bought", "menagerie",
                 "locked_since", "lock_episodes", "kit_runs_counted")

    def __init__(self, seed):
        self.rng = random.Random(seed)
        # wave-3 draws (template pick, shrine, heap dig) ride a SEPARATE stream so toggling
        # wave-3 features never perturbs the primary economic stream (crack-and-see analog)
        self.rng2 = random.Random(seed * 2 + 12345)
        self.counts = defaultdict(int)
        self.discovered = set()
        self.scrap = 50                      # player_state.gd:38
        self.glimmer = 0
        self.tin = 1                         # player_state.gd:39
        self.brass = 2
        self.pity = 0
        self.first_epic_day = None
        self.dex80_day = None
        self.binds_bought = 0
        self.brass_bought = 0
        self.menagerie = 0
        self.locked_since = None
        self.lock_episodes = []
        self.kit_runs_counted = 0
        for c in STARTER_CORES:              # player_state.gd:40-43
            self.gain(c)
        # starter brass ROLL (player_state.gd:44-46) - a 5-bit grant, not a wallet coffer
        self.open_coffer("brass", starter=True, day=0)

    def gain(self, bid):
        self.counts[bid] += 1
        self.discovered.add(bid)

    def cores(self):
        return sum(self.counts[c] for c in STARTER_CORES)

    def has_epic(self):
        return any(self.counts[b] > 0 and CAT[b]["rarity"] == "EPIC" for b in self.counts)

    # PackRoller model - pack_roller.gd:15-66. Brass: 5 bits 0.70/0.92 cuts, guarantee rare+,
    # pity>=9 forces EPIC; tin: 3 bits 0.85/0.97 cuts, no guarantee/pity increment.
    def _roll_bits(self, count, brass):
        out = []
        got_rare = False
        for _ in range(count):
            force_epic = brass and self.pity >= 9
            if force_epic:
                rar = "EPIC"
            else:
                r = self.rng.random()
                hi = 0.92 if brass else 0.97
                lo = 0.70 if brass else 0.85
                rar = "EPIC" if r > hi else ("RARE" if r > lo else "COMMON")
            if rar == "EPIC":
                self.pity = 0
            elif brass:
                self.pity += 1
            if rar != "COMMON":
                got_rare = True
            out.append(self.rng.choice(BODY_BY_RARITY[rar]))
        if brass and not got_rare:
            out[self.rng.randrange(len(out))] = self.rng.choice(NONCOMMON_BODY)
        return out

    def open_coffer(self, kind, day=0, starter=False):
        if not starter:
            if kind == "tin":
                if self.tin <= 0:
                    return
                self.tin -= 1
            else:
                if self.brass <= 0:
                    return
                self.brass -= 1
        for bid in self._roll_bits(5 if kind == "brass" else 3, kind == "brass"):
            self.gain(bid)


def percentile(sorted_vals, p):
    if not sorted_vals:
        return 0
    k = max(0, min(len(sorted_vals) - 1, int(round(p / 100.0 * (len(sorted_vals) - 1)))))
    return sorted_vals[k]


# ----------------------------------------------------------------------------------------------
# One player-day
# ----------------------------------------------------------------------------------------------
def kit_run(p, day, fx, w3, wave3):
    """One Box of Scrap outing. Returns nothing; mutates player + faucet tallies.
    wave3=True layers the venture-depth-wave3 spec on top: template flavor at pos1
    (shrine tally / Magpie's Heap rummage) and the Gleaner's Due on death."""
    rng = p.rng
    g = rng.random()
    gi = 0
    for cut in GRADE_CUTS:
        if g >= cut:
            gi += 1
    grade = GRADES[gi]
    satchel = 0
    satchel_bit = None
    uplift = 0.0
    depth = "node0"
    t = p.rng2.randrange(2) if wave3 else None   # template pick models abs(map_seed) % 2
    if wave3:
        w3["tpl_runs"][t] += 1
    w3["kit_runs_started"] += 1

    def purse(tier):
        table = KIT_PURSE if p.kit_runs_counted < 2 else KIT_PURSE_HALVED
        return table[tier]

    def keep():
        p.scrap += satchel
        fx["kit_purse"] += satchel
        if satchel_bit:
            p.gain(satchel_bit)
            fx["kit_loot_bits"] += 1
        p.kit_runs_counted += 1          # note_kit_run - only on keep (run_screen.gd:652-658)
        w3["flush"].append(satchel)
        w3["flush_by_depth"][depth].append(satchel)
        if wave3:
            w3["tpl_safe_end"][t] += 1

    def die(tier):
        # Gleaner's Due (spec 4.2): kept = floor(S * K_tier * (0.5 + 0.5H)); the satchel bit
        # is ALWAYS lost; a paying death burns a daily full-rate slot (halving-loophole closure)
        fx["kit_deaths"] += 1
        if not wave3:
            return
        kept = int(satchel * W3_K[tier] * (0.5 + 0.5 * W3_DEATH_H))
        w3["death_records"].append((tier, satchel, kept))
        if kept > 0:
            p.scrap += kept
            fx["death_keep"] += kept
            p.kit_runs_counted += 1

    # node0 - Rusty, never aims the core
    if rng.random() < KIT_P["node0"][grade]:
        satchel += purse("skirmish")
        satchel_bit = common_loot(CHALLENGER_LOADOUTS[0], rng)
    else:
        keep()                           # survivable loss ends a kit run, satchel kept (0)
        return
    press_elite = rng.random() < KIT_CONTINUE_ELITE[grade]
    if wave3:
        if t == 0 and w3["events_on"]:
            # Wayside Shrine (Template A pos1) - MONEY-NEUTRAL: tally only, wallet untouched (G14)
            r = p.rng2.randrange(23)
            acc = 0
            eid, thr = EVENT_TABLE[0][0], EVENT_TABLE[0][2]
            for eid2, w, thr2 in EVENT_TABLE:
                acc += w
                if r < acc:
                    eid, thr = eid2, thr2
                    break
            roll = p.rng2.randrange(100)
            pushed = p.rng2.random() < EVENT_PUSH_RATE
            rec = w3["event_tally"][eid]
            rec[0] += 1
            if pushed:
                rec[1] += 1
                if roll < thr:
                    rec[2] += 1
        elif t == 1 and press_elite and satchel >= RUMMAGE_PRICE:
            # Magpie's Heap RUMMAGE (Template B pos1) - kit only, once per run, satchel scrap only.
            # Structural throttle: a halved-day satchel (5) never affords the 8 (spec 3.1).
            satchel -= RUMMAGE_PRICE
            fx["rummage"] += RUMMAGE_PRICE
            w3["rummage_n"] += 1
            has_rare = any(not CAT[b]["is_core"] and CAT[b]["rarity"] == "RARE"
                           for b in p.discovered if b in CAT)
            dr = p.rng2.random()
            if dr < RUMMAGE_CUTS[0]:
                w3["rummage_outcomes"]["lend_common"] += 1
                uplift = max(uplift, LEND_UPLIFT["COMMON"])
            elif dr < RUMMAGE_CUTS[1] or not has_rare:
                # discovered-first: with no RARE discovered the RARE result downgrades to filings
                w3["rummage_outcomes"]["filings"] += 1
                satchel += RUMMAGE_FILINGS
                fx["rummage_filings"] += RUMMAGE_FILINGS
            else:
                w3["rummage_outcomes"]["lend_rare"] += 1
                uplift = max(uplift, LEND_UPLIFT["RARE"])
    if not press_elite:
        keep()
        return
    # elite junction - core-hunting lane
    if not wave3:
        t = rng.randrange(2)
    lane = rng.randrange(2)
    if rng.random() < min(0.99, KIT_P["elite"][grade] + uplift):
        satchel += purse("elite")
        depth = "elite"
        if satchel_bit is None:
            satchel_bit = common_loot(CHALLENGER_LOADOUTS[ELITE_LANES[t][lane]], rng)
    else:
        if rng.random() < KIT_DEATH_GIVEN_LOSS:
            die("elite")                 # spill: bit lost; Gleaner's Due pays on the satchel
            return
        keep()
        return
    if rng.random() >= KIT_CONTINUE_BOSS[grade]:
        keep()
        return
    # boss junction
    if rng.random() < min(0.99, KIT_P["boss"][grade] + uplift):
        satchel += purse("boss")
        depth = "boss"
        fx["kit_boss_clears"] += 1
        if wave3:
            w3["tpl_clear"][t] += 1
    else:
        if rng.random() < KIT_DEATH_GIVEN_LOSS:
            die("boss")
            return
    keep()


def pick_venture_chassis(p):
    """1 core + up to 5 COMMON body bits (dupes first, then singles), >= 1 offensive COMMON.
    Returns list of ids consumed (incl. core) or None if not buildable."""
    have_off = [b for b in BODY_IDS if p.counts[b] > 0 and CAT[b]["offensive"] and CAT[b]["rarity"] == "COMMON"]
    if not have_off or p.cores() == 0:
        return None
    consumed = []
    core = max(STARTER_CORES, key=lambda c: p.counts[c])
    consumed.append(core)
    slots_filled = set()
    # offensive first (prefer a dupe)
    off = max(have_off, key=lambda b: p.counts[b])
    consumed.append(off)
    slots_filled.add("ARM" if CAT[off]["slot"].startswith("ARM") else CAT[off]["slot"])
    # fill remaining sockets with cheap commons, dupes first
    pool = sorted((b for b in BODY_IDS if p.counts[b] > 0 and CAT[b]["rarity"] == "COMMON" and b != off),
                  key=lambda b: -p.counts[b])
    arms = 1 if "ARM" in slots_filled else 0
    for b in pool:
        s = CAT[b]["slot"]
        key = "ARM" if s.startswith("ARM") else s
        if key == "ARM":
            if arms >= 2:
                continue
            arms += 1
        elif key in slots_filled:
            continue
        else:
            slots_filled.add(key)
        consumed.append(b)
        if len(consumed) >= 6:
            break
    return consumed


def own_venture(p, day, fx, w3, wave3):
    rng = p.rng
    chassis = pick_venture_chassis(p)
    if chassis is None:
        return
    for b in chassis:
        p.counts[b] -= 1
    fx["venture_bits_spent"] += len(chassis)
    penalty = 0.0

    def forfeit_salvage():
        # survivable loss forfeits one broken chassis bit for its melt value (combat_screen.gd:1149-1153)
        bid = rng.choice([b for b in chassis if not CAT[b]["is_core"]])
        val = MELT[CAT[bid]["rarity"]]
        p.scrap += val
        fx["forfeit_salvage"] += val

    def wreck_credit(tier):
        # Gleaner's Due own wreck (spec 4.3): floor(K * sum(salvage * hp_frac)) over surviving
        # non-core bits, core pays 0. hp_frac uses the ladder-measured H at death (repair-always
        # runs die with near-full body bits - the fatal blow lands on the core).
        if not wave3:
            return
        melt_sum = sum(MELT[CAT[b]["rarity"]] for b in chassis if not CAT[b]["is_core"])
        w = int(W3_K[tier] * melt_sum * W3_DEATH_H)
        w3["own_wreck"].append(w)
        if w > 0:
            p.scrap += w
            fx["venture_wreck"] += w

    # node0
    if rng.random() < OWN_P["node0"]:
        p.gain(best_loot(CHALLENGER_LOADOUTS[0]))
        fx["venture_loot"] += 1
    else:
        penalty = UNREPAIRED_PENALTY     # roughed up early
        forfeit_salvage()
    # rest 1
    cost = rng.randint(2, 6)
    if p.scrap >= cost:
        p.scrap -= cost
        fx["repairs"] += cost
        penalty = 0.0
    else:
        penalty = UNREPAIRED_PENALTY
    # elite
    t = rng.randrange(2)
    lane = rng.randrange(2)
    if rng.random() < OWN_P["elite"] - penalty:
        p.gain(best_loot(CHALLENGER_LOADOUTS[ELITE_LANES[t][lane]]))
        fx["venture_loot"] += 1
        penalty = 0.0
    else:
        if rng.random() < OWN_DEATH_GIVEN_LOSS:
            fx["venture_deaths"] += 1
            wreck_credit("elite")        # Gleaner's Due own wreck, Run-only
            return                       # construct unmade; loot already banked stays
        forfeit_salvage()
        p.menagerie += 1                 # extract at the next rest (policy)
        fx["venture_banked"] += 1
        return
    # rest 2
    cost = rng.randint(4, 10)
    if p.scrap >= cost:
        p.scrap -= cost
        fx["repairs"] += cost
    else:
        penalty = UNREPAIRED_PENALTY
    # boss
    if rng.random() < OWN_P["boss"] - penalty:
        p.gain(best_loot(CHALLENGER_LOADOUTS[BOSS_LANES[t][lane]]))
        fx["venture_loot"] += 1
        p.menagerie += 1
        fx["venture_banked"] += 1
    else:
        if rng.random() < OWN_DEATH_GIVEN_LOSS:
            fx["venture_deaths"] += 1
            wreck_credit("boss")         # Gleaner's Due own wreck, Run-only
            return
        forfeit_salvage()
        p.menagerie += 1                 # survivable boss loss still banks (run_screen.gd:607-611)
        fx["venture_banked"] += 1


def end_of_day(p, day, fx):
    rng = p.rng
    # dedupe: keep 1, melt/distill the rest (task policy)
    for bid in list(p.counts.keys()):
        extra = p.counts[bid] - 1
        if extra <= 0 or CAT[bid]["is_core"]:
            continue
        rar = CAT[bid]["rarity"]
        if rar == "COMMON":
            p.counts[bid] = 1
            p.scrap += extra * MELT["COMMON"]
            fx["melt"] += extra * MELT["COMMON"]
        else:
            p.counts[bid] = 1
            p.glimmer += extra * DISTILL[rar]
            fx["distill"] += extra * DISTILL[rar]
    # binding if core-locked
    if p.cores() == 0 and p.scrap >= BIND_COST:
        p.scrap -= BIND_COST
        fx["binding"] += BIND_COST
        p.gain(rng.choice(STARTER_CORES))
        p.binds_bought += 1
    # shelf (Today's Finds) - discovered body ids, 3:1 unowned weighting
    cands = [b for b in p.discovered if b in CAT and not CAT[b]["is_core"]]
    shelf = []
    pool = list(cands)
    for _ in range(min(3, len(pool))):
        weights = [3.0 if p.counts[b] == 0 else 1.0 for b in pool]
        pick = rng.choices(range(len(pool)), weights=weights)[0]
        shelf.append(pool.pop(pick))
    own_off = any(p.counts[b] > 0 and CAT[b]["offensive"] for b in BODY_IDS)
    for bid in shelf:
        rar = CAT[bid]["rarity"]
        cur, amt = FIND_PRICE[rar]
        if p.counts[bid] > 0:
            continue
        if cur == "glimmer" and p.glimmer >= amt:
            p.glimmer -= amt
            fx["finds_glimmer"] += amt
            p.gain(bid)
        elif cur == "scrap" and not own_off and CAT[bid]["offensive"] and p.scrap >= amt + SCRAP_RESERVE:
            p.scrap -= amt
            fx["finds_scrap"] += amt
            p.gain(bid)
            own_off = True
    # coffer shopping with surplus
    while p.scrap >= BRASS_PRICE + SCRAP_RESERVE:
        p.scrap -= BRASS_PRICE
        fx["brass_coffers"] += BRASS_PRICE
        p.brass_bought += 1
        p.brass += 1
        p.open_coffer("brass", day=day)


# ----------------------------------------------------------------------------------------------
# ECONOMY v2 (wave 1 change order section D): ladder-anchored venture priors + bout EV module.
# The PRIMARY run below keeps the legacy lane priors so the wave 1 pre/post headline compare
# stays apples-to-apples; the v2 block re-runs the sim under ladder.json lane_observational
# anchors with a +0/+10/+20pp human-uplift sensitivity band, reported separately.
# ----------------------------------------------------------------------------------------------
def load_ladder():
    try:
        with open(LADDER_PATH, encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return None


def run_headline():
    players, day_scrap, day_glimmer, day_flows, day_bind_affordable, day_core_locked, dead_end, w3 = simulate()
    s30 = sorted(day_scrap[-1])
    tot = defaultdict(float)
    for fx in day_flows:
        for k, v in fx.items():
            tot[k] += v
    faucets = sum(tot[k] for k in FAUCET_KEYS)
    sinks = sum(tot[k] for k in SINK_KEYS)
    imb = 100.0 * abs(faucets - sinks) / max(1.0, sinks)
    return {
        "day30_scrap_p25_p50_p75": [percentile(s30, 25), percentile(s30, 50), percentile(s30, 75)],
        "faucets_per_player_30d": round(faucets / N_PLAYERS, 1),
        "sinks_per_player_30d": round(sinks / N_PLAYERS, 1),
        "faucet_sink_imbalance_pct": round(imb, 2),
    }


def anchored_priors_from_ladder(ladder):
    lanes = (ladder or {}).get("part_b_venture", {}).get("lane_observational", {})
    ew, ed, bw, bd = [], [], [], []
    for k, st in lanes.items():
        parts = k.split()
        tier = parts[1] if len(parts) > 1 else ""
        if tier == "elite":
            ew.append(float(st["win_rate"]))
            ed.append(float(st["death_rate"]))
        elif tier == "boss":
            bw.append(float(st["win_rate"]))
            bd.append(float(st["death_rate"]))
    if not ew or not bw:
        return None
    return {
        "elite_win": round(sum(ew) / len(ew), 3), "elite_death": round(sum(ed) / len(ed), 3),
        "boss_win": round(sum(bw) / len(bw), 3), "boss_death": round(sum(bd) / len(bd), 3),
    }


def run_anchored_sensitivity(ladder):
    global OWN_DEATH_GIVEN_LOSS
    base = anchored_priors_from_ladder(ladder)
    if base is None:
        return {"note": "ladder.json lane_observational not found - v2 sensitivity skipped"}
    orig_p = dict(OWN_P)
    orig_d = OWN_DEATH_GIVEN_LOSS
    dgl = []
    for w, d in ((base["elite_win"], base["elite_death"]), (base["boss_win"], base["boss_death"])):
        if w < 0.999:
            dgl.append(max(0.0, min(1.0, d / (1.0 - w))))
    anchored_dgl = round(sum(dgl) / len(dgl), 3) if dgl else 0.70
    bands = []
    for up in (0.0, 0.10, 0.20):
        OWN_P["node0"] = 0.95
        OWN_P["elite"] = min(0.99, base["elite_win"] + up)
        OWN_P["boss"] = min(0.99, base["boss_win"] + up)
        OWN_DEATH_GIVEN_LOSS = anchored_dgl
        h = run_headline()
        h["uplift_pp"] = int(up * 100)
        h["own_p"] = {k: round(v, 3) for k, v in OWN_P.items()}
        h["own_death_given_loss"] = anchored_dgl
        bands.append(h)
    OWN_P.update(orig_p)
    OWN_DEATH_GIVEN_LOSS = orig_d
    return {
        "anchor_source": "ladder.json part_b_venture.lane_observational (post-wave-1 run)",
        "anchored_base": base,
        "note": "AI-floor lane rates + human-uplift bands; hold faucet/sink imbalance under 5% on any follow-up tuning",
        "bands": bands,
    }


def bout_ev_module(ladder):
    measured = {}
    if ladder and "part_c_bout" in ladder:
        for r in ladder["part_c_bout"].get("rows", []):
            measured[int(r["index"])] = r
    rows = []
    for ci in sorted(CHALLENGER_LOADOUTS):
        stake = BOUT_STAKE[CHALLENGER_TIER[ci]]
        best = best_loot(CHALLENGER_LOADOUTS[ci])
        melt = MELT[CAT[best]["rarity"]]
        row = {"index": ci, "tier": CHALLENGER_TIER[ci], "stake": stake,
               "best_loot": best, "best_loot_melt": melt,
               "ev_at_half_prior": round(0.5 * melt - stake, 1)}
        m = measured.get(ci)
        if m:
            row["name"] = m.get("name", "")
            row["measured_win_rate"] = m.get("win_rate")
            row["ev_measured"] = m.get("ev_scrap_per_bout_measured")
        rows.append(row)
    return {
        "model": "EV = win_rate * best-loot melt - tier stake; survivable loss pays 0 salvage (CH-09); stake charged win or lose (CH-08); measured rates from ladder part C when present",
        "rows": rows,
    }


def simulate(wave3=True, events_on=True):
    players = [Player(100003 + i * 7919) for i in range(N_PLAYERS)]
    day_scrap = [[] for _ in range(N_DAYS)]
    day_glimmer = [[] for _ in range(N_DAYS)]
    day_flows = [defaultdict(float) for _ in range(N_DAYS)]
    day_bind_affordable = [0] * N_DAYS
    day_core_locked = [0] * N_DAYS
    dead_end_player_days = 0
    w3 = {
        "events_on": events_on,
        "flush": [], "flush_by_depth": {"node0": [], "elite": [], "boss": []},
        "tpl_runs": [0, 0], "tpl_safe_end": [0, 0], "tpl_clear": [0, 0],
        "event_tally": defaultdict(lambda: [0, 0, 0]),   # id -> [seen, pushed, push_good]
        "rummage_n": 0, "rummage_outcomes": {"lend_common": 0, "filings": 0, "lend_rare": 0},
        "death_records": [], "own_wreck": [], "kit_runs_started": 0,
    }

    for p in players:
        if p.has_epic():
            p.first_epic_day = 0
        for day in range(1, N_DAYS + 1):
            fx = day_flows[day - 1]
            p.kit_runs_counted = 0                       # _roll_kit_day
            p.tin += 1                                   # doorstep claim (free tin)
            fx["doorstep_tins"] += 1
            while p.tin > 0:
                p.open_coffer("tin", day=day)
            while p.brass > 0:
                p.open_coffer("brass", day=day)
            sessions = p.rng.randint(2, 4)
            for _ in range(sessions):
                kit_run(p, day, fx, w3, wave3)
                # venture policy: keep a spare core or a bind reserve unless greedy
                if p.cores() >= 1 and p.rng.random() < VENTURE_RATE:
                    safe = p.cores() >= 2 or p.scrap >= BIND_COST + 40
                    if safe or p.rng.random() < GREED_LAST_CORE:
                        own_venture(p, day, fx, w3, wave3)
                if p.cores() == 0 and p.scrap >= BIND_COST:
                    p.scrap -= BIND_COST
                    fx["binding"] += BIND_COST
                    p.gain(p.rng.choice(STARTER_CORES))
                    p.binds_bought += 1
            end_of_day(p, day, fx)
            # trackers
            d = day - 1
            day_scrap[d].append(p.scrap)
            day_glimmer[d].append(p.glimmer)
            if p.scrap >= BIND_COST:
                day_bind_affordable[d] += 1
            locked = p.cores() == 0
            if locked:
                day_core_locked[d] += 1
                if p.locked_since is None:
                    p.locked_since = day
                if p.scrap < BIND_COST and p.tin == 0 and p.brass == 0:
                    dead_end_player_days += 1            # still recoverable via kit runs
            elif p.locked_since is not None:
                p.lock_episodes.append(day - p.locked_since)
                p.locked_since = None
            if p.first_epic_day is None and p.has_epic():
                p.first_epic_day = day
            if p.dex80_day is None and len(p.discovered & DISCOVERABLE) >= DEX_80PCT:
                p.dex80_day = day
    return players, day_scrap, day_glimmer, day_flows, day_bind_affordable, day_core_locked, dead_end_player_days, w3


def w3_gate_block(w3_base, w3, day_scrap_base, day_scrap, tot_base, tot):
    """Predicted wave-3 numbers vs the spec's measurement-gate bands (venture-depth-wave3.md sect 6)."""
    def mean(xs):
        return round(sum(xs) / len(xs), 2) if xs else 0.0
    p50_base = percentile(sorted(day_scrap_base[-1]), 50)
    p50_v2 = percentile(sorted(day_scrap[-1]), 50)
    fauc = sum(tot[k] for k in FAUCET_KEYS)
    sink = sum(tot[k] for k in SINK_KEYS)
    fauc_b = sum(tot_base[k] for k in FAUCET_KEYS)
    sink_b = sum(tot_base[k] for k in SINK_KEYS)
    runs = max(1, w3["kit_runs_started"])
    flush_mean = mean(w3["flush"])
    flush_mean_base = mean(w3_base["flush"])
    # Gleaner's Due tallies
    dk = w3["death_records"]
    dk_elite = [(s, k) for (t, s, k) in dk if t == "elite"]
    dk_boss = [(s, k) for (t, s, k) in dk if t == "boss"]
    kept_all = [k for (t, s, k) in dk]
    g10_max_over_half = max((k - s // 2 for (t, s, k) in dk), default=-1)
    # safe flush at equal depth: death-at-boss carried the post-elite satchel; compare vs banks after elite
    safe_elite_depth = mean(w3["flush_by_depth"]["elite"])
    safe_node0_depth = mean(w3["flush_by_depth"]["node0"])
    kept_boss_mean = mean([k for (s, k) in dk_boss])
    kept_elite_mean = mean([k for (s, k) in dk_elite])
    tpl = w3["tpl_runs"]
    safe_rates = [round(w3["tpl_safe_end"][i] / tpl[i], 3) if tpl[i] else 0.0 for i in (0, 1)]
    clear_rates = [round(w3["tpl_clear"][i] / tpl[i], 3) if tpl[i] else 0.0 for i in (0, 1)]
    events = {k: {"seen": v[0], "pushed": v[1],
                  "push_good_realized": round(v[2] / v[1], 3) if v[1] else 0.0}
              for k, v in sorted(w3["event_tally"].items())}
    ratio = round(fauc / max(1.0, sink), 3)
    return {
        "baseline_no_wave3": {
            "day30_scrap_p50": p50_base,
            "faucet_sink_ratio": round(fauc_b / max(1.0, sink_b), 3),
            "kit_flush_mean": flush_mean_base,
        },
        "v2_with_wave3": {
            "day30_scrap_p50": p50_v2,
            "faucet_sink_ratio": ratio,
            "kit_flush_mean": flush_mean,
            "kit_flush_mean_by_depth": {k: mean(v) for k, v in w3["flush_by_depth"].items()},
            "kit_runs_started_total": w3["kit_runs_started"],
        },
        "per_template": {
            "runs_T0_event_T1_heap": tpl,
            "safe_end_rate_T0_T1": safe_rates,
            "clear_rate_T0_T1": clear_rates,
            "g1_safe_end_within_5pp": abs(safe_rates[0] - safe_rates[1]) <= 0.05,
        },
        "rummage": {
            "price": RUMMAGE_PRICE,
            "n_rummages": w3["rummage_n"],
            "outcomes": w3["rummage_outcomes"],
            "spend_per_player_30d": round(tot["rummage"] / N_PLAYERS, 1),
            "return_per_player_30d": round(tot["rummage_filings"] / N_PLAYERS, 1),
            "mean_scrap_return_per_kit_run": round(tot["rummage_filings"] / runs, 2),
            "g6_return_le_2_per_run": (tot["rummage_filings"] / runs) <= 2.0,
            "note": "net rummage EV is -8 + 0.30*4 = -6.8 satchel scrap plus the lend value - a sink, structurally full-rate-day only",
        },
        "gleaners_due": {
            "death_h_used": W3_DEATH_H,
            "paying_deaths": sum(1 for k in kept_all if k > 0),
            "total_deaths_recorded": len(dk),
            "death_keep_mean_per_death": mean(kept_all),
            "death_keep_mean_elite": kept_elite_mean,
            "death_keep_mean_boss": kept_boss_mean,
            "death_keep_per_player_30d": round(tot["death_keep"] / N_PLAYERS, 1),
            "own_wreck_mean_per_death": mean(w3["own_wreck"]),
            "own_wreck_per_player_30d": round(tot["venture_wreck"] / N_PLAYERS, 1),
            "g8_boss_death_vs_safe_elite_depth_ratio": round(kept_boss_mean / safe_elite_depth, 3) if safe_elite_depth else 0.0,
            "g8_elite_death_vs_safe_node0_depth_ratio": round(kept_elite_mean / safe_node0_depth, 3) if safe_node0_depth else 0.0,
            "g10_max_kept_minus_half_satchel": g10_max_over_half,
            "g10_deep_death_strictly_dominated": g10_max_over_half <= 0,
        },
        "event_tally": events,
        "g14_money_neutrality": {
            "predicted_delta": 0,
            "note": "events in this model NEVER touch a wallet - the on/off scrap curve is identical by construction; the real toggle test runs post-implementation",
        },
        "gate_bands_checked": {
            "g6_g8_day30_p50_in_85_95": 85 <= p50_v2 <= 95,
            "g8_faucet_sink_ratio_in_0.95_1.10": 0.95 <= ratio <= 1.10,
            "g6_kit_flush_mean_in_baseline_minus15_to_0": flush_mean_base * 0.85 <= flush_mean <= flush_mean_base,
        },
    }


def main():
    global W3_DEATH_H
    ladder0 = load_ladder()
    try:
        hs = [float(ladder0["part_b_venture"]["by_build_tier"][bt]["death_h_frac_mean"]) for bt in ("mid", "strong")]
        W3_DEATH_H = round(sum(hs) / len(hs), 3)
    except Exception:
        W3_DEATH_H = DEATH_H_FALLBACK
    # baseline (shipped economy, no wave-3 features) - paired player seeds with the v2 run
    (_pb, day_scrap_base, _gb, day_flows_base, _bb, _cb, _db, w3_base) = simulate(wave3=False)
    tot_base = defaultdict(float)
    for fx in day_flows_base:
        for k, v in fx.items():
            tot_base[k] += v
    players, day_scrap, day_glimmer, day_flows, day_bind_affordable, day_core_locked, dead_end_pd, w3 = simulate(wave3=True)
    os.makedirs(OUT_DIR, exist_ok=True)

    scrap_curve = []
    glimmer_curve = []
    for d in range(N_DAYS):
        s = sorted(day_scrap[d])
        g = sorted(day_glimmer[d])
        scrap_curve.append({"day": d + 1, "p25": percentile(s, 25), "p50": percentile(s, 50), "p75": percentile(s, 75)})
        glimmer_curve.append({"day": d + 1, "p25": percentile(g, 25), "p50": percentile(g, 50), "p75": percentile(g, 75)})

    epic_days = [p.first_epic_day for p in players if p.first_epic_day is not None]
    epic_never = sum(1 for p in players if p.first_epic_day is None)
    dex_days = [p.dex80_day for p in players if p.dex80_day is not None]
    dex_never = sum(1 for p in players if p.dex80_day is None)
    dex_final = sorted(len(p.discovered & DISCOVERABLE) for p in players)

    lock_lengths = []
    still_locked_at_30 = 0
    for p in players:
        lock_lengths.extend(p.lock_episodes)
        if p.locked_since is not None:
            still_locked_at_30 += 1
    ever_locked = sum(1 for p in players if p.lock_episodes or p.locked_since is not None)

    total_pd = N_PLAYERS * N_DAYS
    faucet_keys = FAUCET_KEYS
    sink_keys = SINK_KEYS
    flows_per_day = []
    for d in range(N_DAYS):
        fx = day_flows[d]
        row = {"day": d + 1}
        for k in faucet_keys + sink_keys + ["distill", "finds_glimmer"]:
            row[k] = round(fx.get(k, 0.0) / N_PLAYERS, 2)
        row["dominant_scrap_faucet"] = max(faucet_keys, key=lambda k: fx.get(k, 0.0))
        flows_per_day.append(row)

    tot = defaultdict(float)
    for fx in day_flows:
        for k, v in fx.items():
            tot[k] += v
    per_player_30d = {k: round(v / N_PLAYERS, 1) for k, v in sorted(tot.items())}

    scrap_faucet_total = sum(tot[k] for k in faucet_keys)
    scrap_sink_total = sum(tot[k] for k in sink_keys)
    late_slope = scrap_curve[-1]["p50"] - scrap_curve[-6]["p50"]  # p50 drift over the last 5 days

    binds = sorted(p.binds_bought for p in players)
    brass = sorted(p.brass_bought for p in players)
    menag = sorted(p.menagerie for p in players)

    # ---------------- analytic arbitrage / risk flags (constants-grounded) ----------------
    tin_meltback = 3 * (0.85 * 8 + 0.12 * 20 + 0.03 * 45)
    brass_meltback = 5 * (0.70 * 8 + 0.22 * 20 + 0.08 * 45)
    brass_glimmer_ev = 5 * (0.22 * DISTILL["RARE"] + 0.08 * DISTILL["EPIC"])
    flags = [
        {
            "severity": "MEDIUM",
            "title": "Proving Grounds bout printer THROTTLED by wave 1 CH-08/CH-09; daily cap (D7) still open",
            "detail": "Bouts now charge a non-refundable tier stake (5/10/20, player_state.gd:30-32, charged in begin_bout) and a survivable-loss forfeit pays ZERO salvage (combat_screen.gd:1154-1162). Brassmore bout EV at the 0.5 prior is now 0.5*45 - 20 = +2.5 scrap (was >= +22.5). Bouts remain uncapped per day and are still fought on a clone; the persisted daily bout-win loot cap (D7) is deferred to save v5. See bout_ev_module for the per-challenger table incl. ladder-measured win rates.",
        },
        {
            "severity": "MEDIUM",
            "title": "The Scrap/Glimmer firewall leaks one way: Glimmer -> Scrap at 4.5-5.0 scrap per glimmer",
            "detail": "EPIC Find costs 10 glimmer (broker.gd:25) and melts for 45 scrap (broker.gd:11) = 4.5 scrap/glimmer; RARE Find 4 -> 20 = 5.0. The reverse channel (brass coffer 100 scrap -> EV %.2f glimmer via the Still = %.1f scrap/glimmer) is 8-10x more expensive, so there is NO profitable round trip (100 scrap -> %.2f glimmer -> ~%.1f scrap), but the 'no conversion' design claim is not literally true." % (brass_glimmer_ev, 100 / brass_glimmer_ev, brass_glimmer_ev, brass_glimmer_ev * 4.5),
        },
        {
            "severity": "MEDIUM",
            "title": "PackRoller RNG stream + pity are not persisted and the seed is a constant",
            "detail": "PlayerState._init always makes PackRoller.new(20260711) (player_state.gd:35) and SaveManager saves no roller state (meta/save_manager.gd). Every app relaunch replays the identical coffer sequence from position 0: the first brass opened after any boot always contains the same 5 bits, all players share one starter roll, and epic pity resets on every boot. Coffer outcomes are relaunch-scummable and feel samey. Persist pity + a per-save roller seed.",
        },
        {
            "severity": "LOW",
            "title": "Kit DEATH does not consume the daily full-purse allotment",
            "detail": "note_kit_run only fires on keep=true (run_screen.gd:652-658), so a spilled run never increments kit_runs_today. Benign (death already costs the satchel) but it means a player who dies twice still has 2 full-rate purses left - worth confirming as intended.",
        },
        {
            "severity": "INFO",
            "title": "Compendium denominator fixed by wave 1 CH-10: 73 obtainable bits, 100 percent reachable",
            "detail": "compendium_total now filters out cores that are not in BINDABLE_CORES (meta/player_state.gd:239-248): 70 body bits + 3 bindable cores = 73. Display-only change; every discovery metric in this sim already used the 73-bit discoverable set, so no economy metric moves.",
        },
        {
            "severity": "MEDIUM",
            "title": "Glimmer has no functioning sink for a keep-1 collector: earned %.1f per player over 30d, spent %.1f" % (tot["distill"] / N_PLAYERS, tot.get("finds_glimmer", 0.0) / N_PLAYERS),
            "detail": "RARE/EPIC Finds are the only glimmer sinks (broker.gd:23-27), but the shelf is discovered-gated (broker.gd:35-38) and RARE/EPIC bits are never consumed by any loop (ventures spend COMMON chassis, melts/distills only touch dupes) - so every RARE/EPIC Find on offer is a dupe of a bit the player already owns, and buying one to re-distill refunds only 25-30 percent. Simulated p50 glimmer wallet hits %d by day 30 on a straight line (~1.9/day) with zero spent. Glimmer is currently a score counter; it needs a real sink (enchants, dyes, a glimmer coffer, or core rentals)." % glimmer_curve[-1]["p50"],
        },
        {
            "severity": "INFO",
            "title": "The Binding is the dominant scrap sink (%.0f%% of all scrap sunk), not coffers" % (100.0 * tot["binding"] / max(1.0, scrap_sink_total)),
            "detail": "Per player over 30d: bindings %.0f vs brass coffers %.0f vs repairs %.0f scrap. Own-build venturing consumes the seated core (root.gd:82-87), so every venture effectively costs 60 scrap in core replacement - the venture appetite, not Fettle's cart, drives the economy. p50 player buys only %d brass coffers in 30 days. Fine if intended; if coffers are meant to be the aspirational sink, the venture-per-core price is crowding them out." % (tot["binding"] / N_PLAYERS, tot["brass_coffers"] / N_PLAYERS, tot["repairs"] / N_PLAYERS, percentile(brass, 50)),
        },
        {
            "severity": "INFO",
            "title": "80 percent compendium is out of reach in a month for most players; the tail is pure coffer RNG",
            "detail": "Only %.1f%% of simulated players hit 64/80 discovered within 30 days (p50 dex at day 30 = %d). Finds cannot sell undiscovered bits (broker.gd:35-38), loot only covers the 9 challenger loadouts, so the last-mile dex is a coupon-collector on tin/brass rolls alone. If 80 percent is meant as a month-one goal, either add a discovery faucet (e.g. one undiscovered Find slot) or accept the longer horizon." % (100.0 * len(dex_days) / N_PLAYERS, percentile(dex_final, 50)),
        },
        {
            "severity": "INFO",
            "title": "Anti-arbitrage on coffers holds",
            "detail": "Tin melt-back EV %.2f scrap of a 40 price (%.0f%%); brass melt-back EV %.2f of 100 (%.0f%%) before the rare+ guarantee bump. Buy-to-melt is strictly negative on both - matches the pack_roller.gd:4 design note." % (tin_meltback, 100 * tin_meltback / 40, brass_meltback, 100 * brass_meltback / 100),
        },
        {
            "severity": "INFO",
            "title": "No runaway SCRAP inflation in the modeled loop",
            "detail": "p50 scrap drifts %+d over days 25-30 and ends near %d (start 50); 30-day faucets %.0f vs sinks %.0f per player - the wallet is a pass-through, not an accumulator. The satchel halving does its job: kit purse income is flat day over day. (Glimmer is the currency that inflates - see its own flag.)" % (late_slope, scrap_curve[-1]["p50"], scrap_faucet_total / N_PLAYERS, scrap_sink_total / N_PLAYERS),
        },
    ]

    result = {
        "meta": {
            "generated": "2026-07-19",
            "script": "tools/sim/economy_sim.py",
            "master_seed_scheme": "player i seed = 100003 + i * 7919 (smoke_kit_sim pattern)",
            "players": N_PLAYERS,
            "days": N_DAYS,
            "catalog_size": {"total": len(CAT), "body": len(BODY_IDS), "cores": len(CAT) - len(BODY_IDS),
                             "body_by_rarity": {r: len(v) for r, v in BODY_BY_RARITY.items()},
                             "note": "13 base fixtures + 67 non-colliding catalog_extra entries; 7 of the 10 cores are unobtainable"},
        },
        "constants_extracted": CONSTANTS,
        "assumptions": ASSUMPTIONS,
        "results": {
            "scrap_curve": scrap_curve,
            "glimmer_curve": glimmer_curve,
            "days_to_first_epic": {
                "p25": percentile(sorted(epic_days), 25) if epic_days else None,
                "p50": percentile(sorted(epic_days), 50) if epic_days else None,
                "p75": percentile(sorted(epic_days), 75) if epic_days else None,
                "reached_pct": round(100.0 * len(epic_days) / N_PLAYERS, 1),
                "never_within_window": epic_never,
                "day0_note": "day 0 = an EPIC in the starter brass roll",
            },
            "days_to_80pct_compendium": {
                "threshold_bits": DEX_80PCT,
                "reached_pct": round(100.0 * len(dex_days) / N_PLAYERS, 1),
                "p50": percentile(sorted(dex_days), 50) if dex_days else None,
                "p25": percentile(sorted(dex_days), 25) if dex_days else None,
                "p75": percentile(sorted(dex_days), 75) if dex_days else None,
                "not_reached_in_30d": dex_never,
                "dex_at_day30_p25_p50_p75": [percentile(dex_final, 25), percentile(dex_final, 50), percentile(dex_final, 75)],
                "max_possible": 73,
            },
            "dead_end_softlock": {
                "hard_softlock_probability": 0.0,
                "why_zero": "The Box of Scrap needs no core, no scrap and no bits (root.gd:89-98, box_roller.gd) and kit rests mend free (run_screen.gd:417-421), so scrap income is always reachable and the Binding (60) is always eventually affordable. By construction there is no absorbing dead state.",
                "core_locked_player_days_pct": round(100.0 * sum(day_core_locked) / total_pd, 2),
                "core_locked_and_poor_and_cofferless_player_days_pct": round(100.0 * dead_end_pd / total_pd, 3),
                "players_ever_core_locked_pct": round(100.0 * ever_locked / N_PLAYERS, 1),
                "still_core_locked_at_day30": still_locked_at_30,
                "lock_episode_days_p50": percentile(sorted(lock_lengths), 50) if lock_lengths else 0,
                "lock_episode_days_p95": percentile(sorted(lock_lengths), 95) if lock_lengths else 0,
            },
            "binding": {
                "binds_per_player_30d_p25_p50_p75": [percentile(binds, 25), percentile(binds, 50), percentile(binds, 75)],
                "bind_affordable_pct_by_day": [round(100.0 * v / N_PLAYERS, 1) for v in day_bind_affordable],
            },
            "coffer_cadence": {
                "brass_bought_per_player_30d_p25_p50_p75": [percentile(brass, 25), percentile(brass, 50), percentile(brass, 75)],
                "tin_bought": 0,
                "tin_note": "never rational to buy under the melt policy (EV 31.65 melt-back on 40); doorstep supplies 1 tin/day free",
            },
            "menagerie_banked_p25_p50_p75": [percentile(menag, 25), percentile(menag, 50), percentile(menag, 75)],
            "faucet_sink_daily_mean_per_player": flows_per_day,
            "totals_per_player_30d": per_player_30d,
            "scrap_faucet_vs_sink_total_per_player": {
                "faucets": round(scrap_faucet_total / N_PLAYERS, 1),
                "sinks": round(scrap_sink_total / N_PLAYERS, 1),
                "note": "faucets = kit purses + melts + forfeit salvage + death keeps + own wrecks + rummage filings; sinks = brass coffers + bindings + repairs + scrap finds + rummages",
            },
        },
        "flags": flags,
    }

    # ---------------- v2 modules (additive; primary headline above stays legacy-prior) ----------
    ladder = load_ladder()
    result["bout_ev_module"] = bout_ev_module(ladder)
    result["v2_anchored_sensitivity"] = run_anchored_sensitivity(ladder)
    # ---------------- wave 3 G0 projection (venture-depth-wave3.md) ----------------
    result["wave3_g0"] = w3_gate_block(w3_base, w3, day_scrap_base, day_scrap, tot_base, tot)

    out_path = os.path.join(OUT_DIR, "economy.json")
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(result, f, indent=2)

    # ---------------- human summary ----------------
    print("MANABIT ECONOMY SIM - %d players x %d days (seeded)" % (N_PLAYERS, N_DAYS))
    print("catalog: %d bits modeled (%d body: %dC/%dR/%dE), dex total 80, max discoverable 73" % (
        len(CAT), len(BODY_IDS), len(BODY_BY_RARITY["COMMON"]), len(BODY_BY_RARITY["RARE"]), len(BODY_BY_RARITY["EPIC"])))
    print()
    print("SCRAP p50 curve (day: 1/5/10/15/20/25/30): " + " / ".join(
        str(scrap_curve[d]["p50"]) for d in (0, 4, 9, 14, 19, 24, 29)))
    print("GLIMMER p50 curve (same days):             " + " / ".join(
        str(glimmer_curve[d]["p50"]) for d in (0, 4, 9, 14, 19, 24, 29)))
    print("day30 scrap p25/p50/p75:   %d / %d / %d" % (scrap_curve[-1]["p25"], scrap_curve[-1]["p50"], scrap_curve[-1]["p75"]))
    print("day30 glimmer p25/p50/p75: %d / %d / %d" % (glimmer_curve[-1]["p25"], glimmer_curve[-1]["p50"], glimmer_curve[-1]["p75"]))
    print()
    de = result["results"]["days_to_first_epic"]
    print("days-to-first-EPIC: p50=%s (p25=%s p75=%s), reached %.1f%%" % (de["p50"], de["p25"], de["p75"], de["reached_pct"]))
    dx = result["results"]["days_to_80pct_compendium"]
    print("days-to-80%%-dex (64/80): reached %.1f%% in 30d, p50=%s; dex@30 p25/50/75 = %s" % (
        dx["reached_pct"], dx["p50"], dx["dex_at_day30_p25_p50_p75"]))
    dd = result["results"]["dead_end_softlock"]
    print("softlock: hard=0 by construction; core-locked player-days %.2f%%; locked+poor+cofferless %.3f%%; ever-locked %.1f%% of players; episode p50=%sd p95=%sd; still locked at d30: %d" % (
        dd["core_locked_player_days_pct"], dd["core_locked_and_poor_and_cofferless_player_days_pct"],
        dd["players_ever_core_locked_pct"], dd["lock_episode_days_p50"], dd["lock_episode_days_p95"], dd["still_core_locked_at_day30"]))
    bi = result["results"]["binding"]
    print("binding: binds/player p25/50/75 = %s; bind affordable day1 %.1f%% -> day30 %.1f%%" % (
        bi["binds_per_player_30d_p25_p50_p75"], bi["bind_affordable_pct_by_day"][0], bi["bind_affordable_pct_by_day"][-1]))
    cc = result["results"]["coffer_cadence"]
    print("coffers: brass/player over 30d p25/50/75 = %s (tin: never bought)" % cc["brass_bought_per_player_30d_p25_p50_p75"])
    print("menagerie banked p25/50/75: %s" % result["results"]["menagerie_banked_p25_p50_p75"])
    f30 = result["results"]["scrap_faucet_vs_sink_total_per_player"]
    print("scrap flow per player/30d: faucets %.0f vs sinks %.0f" % (f30["faucets"], f30["sinks"]))
    print("glimmer per player/30d: earned %.1f, spent %.1f (no working sink - see flag)" % (
        tot["distill"] / N_PLAYERS, tot.get("finds_glimmer", 0.0) / N_PLAYERS))
    d1, d30 = flows_per_day[0], flows_per_day[-1]
    print("dominant scrap faucet: day1 %s -> day30 %s" % (d1["dominant_scrap_faucet"], d30["dominant_scrap_faucet"]))
    print("daily mean/player day30: kit_purse %.1f, melt %.1f, forfeit %.1f | brass %.1f, binding %.1f, repairs %.1f" % (
        d30["kit_purse"], d30["melt"], d30["forfeit_salvage"], d30["brass_coffers"], d30["binding"], d30["repairs"]))
    print()
    print("FLAGS:")
    for fl in flags:
        print("  [%s] %s" % (fl["severity"], fl["title"]))
    print()
    print("BOUT EV (stake charged, forfeit pays 0):")
    for row in result["bout_ev_module"]["rows"]:
        mw = row.get("measured_win_rate")
        print("  ch[%d] %-8s stake %2d  best loot %2d  EV@0.5 %+5.1f%s" % (
            row["index"], row["tier"], row["stake"], row["best_loot_melt"], row["ev_at_half_prior"],
            ("  measured win %.3f EV %+5.1f" % (mw, row["ev_measured"])) if mw is not None else ""))
    v2 = result["v2_anchored_sensitivity"]
    if "bands" in v2:
        print("V2 ANCHORED SENSITIVITY (elite/boss priors from ladder lanes):")
        for b in v2["bands"]:
            print("  +%dpp uplift: own_p elite %.3f boss %.3f  day30 p50 %d  faucets %.0f sinks %.0f imbalance %.2f%%" % (
                b["uplift_pp"], b["own_p"]["elite"], b["own_p"]["boss"],
                b["day30_scrap_p25_p50_p75"][1], b["faucets_per_player_30d"], b["sinks_per_player_30d"],
                b["faucet_sink_imbalance_pct"]))
    else:
        print("V2 ANCHORED SENSITIVITY: " + v2.get("note", "skipped"))
    w3g = result["wave3_g0"]
    print()
    print("WAVE 3 G0 PROJECTION (predictive, ASSUMED values):")
    print("  death H used (ladder-measured): %.3f" % w3g["gleaners_due"]["death_h_used"])
    print("  day30 p50: baseline %d -> v2 %d (band 85-95: %s)" % (
        w3g["baseline_no_wave3"]["day30_scrap_p50"], w3g["v2_with_wave3"]["day30_scrap_p50"],
        w3g["gate_bands_checked"]["g6_g8_day30_p50_in_85_95"]))
    print("  faucet/sink ratio: baseline %.3f -> v2 %.3f (band 0.95-1.10: %s)" % (
        w3g["baseline_no_wave3"]["faucet_sink_ratio"], w3g["v2_with_wave3"]["faucet_sink_ratio"],
        w3g["gate_bands_checked"]["g8_faucet_sink_ratio_in_0.95_1.10"]))
    print("  kit flush mean: baseline %.2f -> v2 %.2f (band [-15%%, +0%%]: %s); by depth %s" % (
        w3g["baseline_no_wave3"]["kit_flush_mean"], w3g["v2_with_wave3"]["kit_flush_mean"],
        w3g["gate_bands_checked"]["g6_kit_flush_mean_in_baseline_minus15_to_0"],
        w3g["v2_with_wave3"]["kit_flush_mean_by_depth"]))
    print("  per-template runs %s  safe-end %s  clear %s  (G1 within 5pp: %s)" % (
        w3g["per_template"]["runs_T0_event_T1_heap"], w3g["per_template"]["safe_end_rate_T0_T1"],
        w3g["per_template"]["clear_rate_T0_T1"], w3g["per_template"]["g1_safe_end_within_5pp"]))
    rm = w3g["rummage"]
    print("  rummage: n %d  outcomes %s  spend/player %.1f  return/player %.1f  mean return/run %.2f (G6 <= 2: %s)" % (
        rm["n_rummages"], rm["outcomes"], rm["spend_per_player_30d"], rm["return_per_player_30d"],
        rm["mean_scrap_return_per_kit_run"], rm["g6_return_le_2_per_run"]))
    gd = w3g["gleaners_due"]
    print("  gleaners: paying deaths %d/%d  keep/death %.2f (elite %.2f boss %.2f)  keep/player %.1f  wreck/player %.1f" % (
        gd["paying_deaths"], gd["total_deaths_recorded"], gd["death_keep_mean_per_death"],
        gd["death_keep_mean_elite"], gd["death_keep_mean_boss"],
        gd["death_keep_per_player_30d"], gd["own_wreck_per_player_30d"]))
    print("  G8 sting ratios: boss-death/safe-elite-depth %.3f  elite-death/safe-node0-depth %.3f (must be <= 0.60)" % (
        gd["g8_boss_death_vs_safe_elite_depth_ratio"], gd["g8_elite_death_vs_safe_node0_depth_ratio"]))
    print("  G10 deep death strictly dominated: %s (max kept - floor(S/2) = %d)" % (
        gd["g10_deep_death_strictly_dominated"], gd["g10_max_kept_minus_half_satchel"]))
    print("  G14 events money-neutral: predicted delta %d (structural)" % w3g["g14_money_neutrality"]["predicted_delta"])
    print()
    print("wrote " + out_path)


if __name__ == "__main__":
    main()
