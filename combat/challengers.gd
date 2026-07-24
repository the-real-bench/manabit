class_name Challengers extends RefCounted
# Authored bout/run opponents with KNOWN loadouts (§12.1: you loot exactly what you beat).
# Team-designed roster, easy -> legend. Elites/bosses aim the core (DEATH) only in a run.

static func list() -> Array:
    return [
        {
            "name": "Scrap-Pup Rusty",
            "blurb": "A wobbly little Everykit somebody wound up and pointed at you. All heart, one fist, no plan.",
            "elite": false,
            "loadout": [["CORE", "core_ember"], ["HEAD", "everykit_standard_cowl"], ["ARM_R", "everykit_standard_fist"], ["LEGS", "tinbox_legs_trusty"]],
        },
        {
            "name": "Whirl-Kid Ziptie",
            "blurb": "A blur of loose bearings - moves first, hits in a flurry, races to snap your arms off. Brace early.",
            "elite": false,
            "loadout": [["CORE", "whirligig_core_quickstart"], ["HEAD", "whirligig_head_windshear"], ["ARM_R", "whirligig_arm_turbine"], ["LEGS", "whirligig_legs_zephyr"], ["BACK", "whirligig_back_slipfin"]],
        },
        {
            "name": "Sir Vance the Steadfast",
            "blurb": "A courtly errant-knit that guards, mends its own strained joints, and answers with a clean oathblade.",
            "elite": false,
            "loadout": [["CORE", "errant_core_pledge"], ["HEAD", "everykit_standard_cowl"], ["ARM_R", "errant_arm_oathblade"], ["ARM_L", "errant_arm_warder"], ["LEGS", "errant_legs_vigil"], ["BACK", "cobble_sons_back_toolrack"]],
        },
        {
            "name": "Grand Warden Cogsworth",
            "blurb": "A retired gate-guardian in solid Grumble girder - a 40-heart fortress that out-lasts your patience.",
            "elite": true,
            "loadout": [["CORE", "grumble_co_keystone_core"], ["HEAD", "grumble_co_anvil_cowl"], ["ARM_L", "grumble_co_girder_fist"], ["ARM_R", "grumble_co_slab_pauldron"], ["LEGS", "cobble_sons_legs_bedrock"], ["BACK", "grumble_co_furnace_pack"]],
        },
        {
            "name": "Sunking Brassmore, the Undethroned",
            "blurb": "The champion that never lost because it never wagered - five epic bits, an Oracle Lens that reads your core, and a Meteor Knuckle that ends the argument.",
            "elite": true,
            "loadout": [["CORE", "boldheart_core_sunheart"], ["HEAD", "silksteel_head_oracle"], ["ARM_R", "boldheart_arm_meteor"], ["ARM_L", "grumble_co_bastion_fist"], ["LEGS", "cobble_sons_legs_bedrock"], ["BACK", "pith_sinew_deep_pulse_sac"]],
        },
        # --- Branching-map lane residents (APPEND-ONLY: ch[0..4] indices are frozen - run
        # templates and the Proving Grounds depend on order). ---
        {
            "name": "Thornlash Briar",
            "blurb": "A hedge-thing of lashing claws - four cuts a swing, all briar and appetite. Guard wide or lose a limb.",
            "elite": true,
            "loadout": [["CORE", "pith_sinew_heartcore"], ["HEAD", "pith_sinew_caul_hood"], ["ARM_L", "thicket_fang_arm_goreclaw"], ["ARM_R", "thicket_fang_arm_gnashmaw"], ["LEGS", "thicket_fang_legs_haunch"], ["BACK", "pith_sinew_deep_pulse_sac"]],
            "mods": {"overgrown": [["ARM_R", "boldheart_arm_sunder"]]},
        },
        {
            "name": "Quartermaster Pindrop",
            "blurb": "A tidy little armory on legs. It counts its shots out loud - and it has counted out enough for you.",
            "elite": true,
            "loadout": [["CORE", "quivergear_magazine_core"], ["HEAD", "chatterbox_bigeye_dome"], ["ARM_R", "quivergear_salvo_fist"], ["ARM_L", "boldheart_arm_sunder"], ["LEGS", "everykit_standard_strider_legs"], ["BACK", "quivergear_payload_rack"]],
        },
        {
            "name": "Seamstress Sable",
            "blurb": "Silk-quiet and needle-precise. She stitches straight for the seam your core sits behind.",
            "elite": true,
            "loadout": [["CORE", "core_font"], ["HEAD", "silksteel_head_whisper"], ["ARM_R", "silksteel_arm_needle"], ["ARM_L", "boldheart_arm_sunder"], ["LEGS", "silksteel_legs_slip"], ["BACK", "everykit_standard_cell"]],
        },
        {
            "name": "Prince Gildfall, the Heir-Apparent",
            "blurb": "Brassmore's understudy in gleaming state brass - a crown not yet earned, swung hard enough to earn it on you.",
            "elite": true,
            "loadout": [["CORE", "sovereign_brass_core_regalia"], ["HEAD", "sovereign_brass_head_herald"], ["ARM_R", "sovereign_brass_arm_pistonfist"], ["ARM_L", "carillon_cadets_arm_grandpeal"], ["LEGS", "sovereign_brass_legs_colonnade"], ["BACK", "sovereign_brass_back_mantle"]],
        },
    ]

# Build a fresh ManabitState for a challenger entry. mod_id applies the lane's FOE-SIDE modifier:
#   "rusted"    - every PartInstance starts WEAR HP down, floor 1 (instance-only wear);
#   "overgrown" - the entry's authored mods.overgrown swap list replaces slots with heavier bits.
# rider is the shrine's "next foe worn N" (wave 3, spec 2.5): MAX-NOT-SUM vs the lane wear -
# rusted(2) + rider(2) = 2, never 4 (smoke_run T6). Capped at RunMods.WEAR by construction.
# Default ("", 0) is byte-identical to the unmodified build. NEVER mutates shared PartData (.tres).
static func make(entry: Dictionary, mod_id: String = "", rider: int = 0) -> ManabitState:
    var m := ManabitState.new()
    var cat := Catalog.by_id()
    for spec in entry["loadout"]:
        var pd = cat.get(spec[1])
        if pd != null:
            m.slots[spec[0]] = PartInstance.new(pd)
    if mod_id == "overgrown":
        var mods: Dictionary = entry.get("mods", {})
        var swaps: Array = mods.get("overgrown", [])
        for swap in swaps:
            var pd2 = cat.get(swap[1])
            if pd2 != null:
                m.slots[swap[0]] = PartInstance.new(pd2)
    var wear: int = RunMods.WEAR if mod_id == "rusted" else 0
    wear = maxi(wear, clampi(rider, 0, RunMods.WEAR))
    if wear > 0:
        for slot in ManabitState.SLOT_NAMES:
            var pi: PartInstance = m.slots.get(slot)
            if pi != null:
                pi.current_hp = maxi(1, pi.current_hp - wear)
    return m
