class_name FamilyPalette extends RefCounted
# Per-family plastic base + signature micro-glow, from the art bible (design/art/art-bible.md §1).
# Used to tint the procedural placeholder bits by family NOW; real .glb art carries its own atlas.

static var _base := {
    "baseline": Color("C9C3B4"),
    "artificer_first": Color("B08D57"),
    "everykit_standard": Color("C1443A"),
    "boldheart": Color("D8342E"),
    "grumble_co": Color("E0A82E"),
    "whirligig": Color("2FA7A0"),
    "thicket_fang": Color("5E7B3E"),
    "silksteel": Color("A98FD0"),
    "pith_sinew": Color("D98A6E"),
    "quivergear": Color("6E7346"),
    "errant": Color("3A5AA8"),
    "cobble_sons": Color("C57A3E"),
    "chatterbox": Color("8FC4E8"),
    "sovereign_brass": Color("B08D57"),
    "tinbox": Color("D8342E"),
    "pocketful": Color("E88AA0"),
    "carillon_cadets": Color("2E9FD9"),
    "larkabout_skyworks": Color("EAD9B0"),
    "steadfast_gallant": Color("55627A"),
}

# Signature emissive accents (5 families get a distinct one; the rest keep warm amber).
static var _micro := {
    "whirligig": Color("4FD6E8"),
    "thicket_fang": Color("8FD46B"),
    "silksteel": Color("D857C9"),
    "pith_sinew": Color("FF7DA0"),
    "chatterbox": Color("6FB8E8"),
}

static func base(fam: String) -> Color:
    return _base.get(fam, Color("C9C3B4"))

static func microglow(fam: String) -> Color:
    return _micro.get(fam, Tokens.GLOW_BASE)     # default warm amber
