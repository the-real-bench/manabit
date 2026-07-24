# BUILD_BRIEF.md - *MANABIT*

> **Game name:** MANABIT (locked). *Mana + bit* - where "bit" triple-loads: a computing bit, a small **piece** (the modular parts you snap together), and a little cute creature. A **Manabit** is one animated toy-construct.
> **You are an Artificer** - a maker-mage who binds a soul into scrap and animates it. Magic *is* the tech. You assemble a Manabit from stat-bearing parts, wager it in turn-based battles, and **loot a part off whoever loses**. Win and you keep your construct - and take a piece of theirs. Lose and the body is broken down for scrap. **You always survive; your creations don't.**

This document is the single source of truth for a Claude Code build. Build the **vertical slice** (M0-M4) first; everything after is content, tuning, and the overworld. All mechanical decisions from the prior brief still stand - the Artificer framing wraps around them, it doesn't replace them.

---

## 0. Fiction & framing (locked) - read this first

The magic layer isn't flavor paint; it earns two things the pure-builder version couldn't:

1. **Why a hunk of plastic has a soul.** The **mana core** is a soul the Artificer has *bound and animated*. Magic is the reason the "heart" persists through a fight while the body gets torn apart.
2. **A clean identity spine.** Split the persistent thing from the mortal thing:

| Concept | What it is | Persistence |
|---|---|---|
| **Artificer** (you) | The maker-mage. Account-level identity. Gains XP, unlocks affinities & blueprints. Your customizable overworld avatar. | **Always survives.** |
| **Manabit** | An animated toy-construct - the fighting unit you assemble from parts. | **Mortal.** Destroyed = gone. |
| **Mana core** | The bound soul you craft and install in a Manabit's CORE slot. Animates it; is its life bar. | Per-build; crafted, not permanent. |

This resolves the old awkwardness ("the core is your identity, but you can lose it on death"). Now the **Artificer** is the identity, and losing a Manabit is losing a *creation*, not losing *yourself*. A maker outliving their toys is thematically tighter and gives the overworld avatar a real reason to exist.

**⚠️ Design guardrail - magic as craft, fused not bolted-on.** Tone is **Artificer = cozy-craft**: warm tinkering, clockwork, runes *etched into* plastic, mana as the power source, soft glow at sockets and cores. Never write it as "a wizard who happens to own robots." Every system, every line of UI copy, every material should read as *magic and making are the same act*. (This tonal lock is also what keeps the sci-fi/fantasy register from going muddy - resist all glowing-circuitry / cyber-hacker styling; that's a different game.)

---

## 1. Engine & tech decisions (locked)

| Decision | Choice | Why |
|---|---|---|
| Engine | **Godot 4.x / GDScript** | Node/scene model is purpose-built for snap-together parts; `Resource` files make parts trivially data-driven. |
| Combat model | **Turn-based, initiative-ordered, part-targeted** | Makes the *stats the gameplay*. Sidesteps the animation explosion of real-time action with arbitrary limb combos. |
| Art | **PS1-style low-poly** - chunky pixel textures, vertex jitter, affine warp | ~300-800 tris/part rendered through a PS1 pipeline (§8). **PS1 *technique*, cozy *tone*** - warm/collectible palette, NOT liminal-horror. Faint etched glyphs + soft mana glow. |
| Targets | **PC first, mobile-friendly** | Turn-based + low-poly ports cleanly to touch. Design UI touch-first from day one. |
| Save | JSON for meta/garage; `.tres` for part definitions | Human-readable saves; part catalog editable in the Godot inspector. |

**Deferred (do NOT build in the slice):** real-time action combat, online/multiplayer, procedural part-mesh generation, and **the entire overworld/avatar-customization hub** (see §7).

---

## 2. The part & slot system (the easy, solved half)

Six slots. The **CORE holds the mana core** - the bound soul. It's non-lootable, and it's the Manabit's actual life bar. The other five parts are breakable and lootable. **ARM_L and ARM_R are interchangeable** - both accept any `slot == "ARM_*"` part; no handedness (§12.3).

```
SLOTS:  HEAD · CORE · ARM_L · ARM_R · LEGS · BACK
                 ▲ holds the mana core (bound soul) - non-lootable, is the Manabit's life + affinity
```

### PartData (Godot `Resource`, saved as `.tres`)
```gdscript
class_name PartData extends Resource

@export var id: StringName
@export var display_name: String
@export_enum("HEAD","CORE","ARM_L","ARM_R","LEGS","BACK") var slot: String
@export var mesh: Mesh                    # low-poly part mesh (etched-rune plastic)
@export var socket_offset: Transform3D    # local snap transform

# --- stats (see §3) ---
@export var max_hp: int          # LOCAL durability of THIS part (0 = disabled)
@export var attack: int
@export var defense: int
@export var speed: int
@export var weight: int
@export var energy: int          # mana pool contribution

# --- flavor / systems ---
@export var ability_id: StringName        # grants one move, archetype SINGLE|MULTI|GUARD (§12.2)
@export_enum("COMMON","RARE","EPIC") var rarity: String
@export var blueprint_unlockable: bool = true
```

> **Mana core note:** the CORE-slot part is a `PartData` like the others, but flagged as a core (carries `affinity` + is the life bar - see §3/§7). It's crafted by the Artificer, not looted.

### Manabit assembly (scene)
A Manabit is a scene with six `Marker3D` sockets (`head_socket`, `core_socket`, …). An **Assembler** script instances each equipped part's `mesh` at its socket and recomputes derived stats.

```gdscript
class_name Manabit extends Node3D

var core: PartData                         # the bound soul (mana core) - persistent within a run
var slots := {}                            # slot_name -> PartData
var part_hp := {}                          # slot_name -> current local HP (runtime)

func derived() -> Dictionary:
    var s := {"attack":0,"defense":0,"speed":0,"weight":0,"energy":0}
    for p in slots.values():
        if p == null: continue
        s.attack  += p.attack
        s.defense += p.defense
        s.speed   += p.speed
        s.weight  += p.weight
        s.energy  += p.energy
    # weight penalty: only OVERWEIGHT costs speed (soft-threshold model, §12.6)
    s.speed -= max(0, s.weight - WEIGHT_BUDGET) * OVERWEIGHT_SPD_COST
    return s
```

> **Why this is the low-risk half:** a part is literally a node you snap onto a socket node, and derived stats are just an aggregate over what's equipped. The "lose a part" mechanic falls out for free because each part already owns its own HP.

---

## 3. Stat model (locked)

| Stat | Lives on | Meaning |
|---|---|---|
| **HP** | each part (local) | Part durability. Hits 0 → part **disabled** for the rest of the fight and becomes the candidate to be lost. |
| **CORE HP** | mana core only | The Manabit's **life**. Hits 0 → the construct is **unmade** (defeated). |
| **ATK** | aggregate | Outgoing damage. |
| **DEF** | aggregate | Damage reduction. |
| **SPD** | aggregate | Turn order / initiative. Reduced only when **overweight** (§12.6). |
| **WEIGHT** | aggregate | Load. Heavier = slower. Soft build constraint (no hard cap in slice). |
| **ENERGY (Mana)** | aggregate | Resource pool for abilities. |

**Key separation:** *part HP = local durability that can break*; *core HP = the fight's win condition*. This distinguishes "an arm got blasted off" from "the construct was unmade," straight out of the Medabots playbook.

---

## 4. Combat (turn-based, part-targeted)

- Initiative ordered by SPD. Each Manabit acts on its turn.
- A Manabit's available **moves come from its equipped parts.** Each part grants **one move of one of three archetypes** (§12.2): **`SINGLE`** (one hard hit), **`MULTI`** (several weaker hits - good for breaking multiple parts), **`GUARD`** (raise DEF / brace a part / small part-HP restore, mana-gated). A disabled part's move is unavailable.
- On your turn: pick a move, then **pick a target part** on the enemy (or aim at the core).
- Damage = `max(1, attacker.ATK + move_power - target.DEF)`, applied to the **targeted part's local HP**; aimed shots can chip the core (tune overflow rules).
- **Part HP → 0:** that slot is disabled (its move & stat contribution drop for the rest of the fight).
- **Core HP → 0:** the Manabit is unmade - fight over.

**Slice AI:** dead-simple - target the enemy's lowest-HP non-core part until something opens, then swing at the core. Good enough to prove the loop; smarter AI is post-slice.

*Alternatives (documented, not chosen):* **auto-battler** = even lower effort; **real-time action** = high effort (needs one shared humanoid rig with parts as skinned attachments) - only revisit if the turn-based slice proves fun.

---

## 5. Run structure (roguelite loop)

A run is a walk across a branching node map (Slay-the-Spire-lite / FTL-lite).

**Node types:** `BATTLE` · `ELITE` · `WORKSHOP` (repair/craft) · `SCRAPYARD` (buy/sell) · `EVENT` · `BOSS`.

- **Slice:** 3-4 linear nodes ending in a mini-boss. **Full:** 8-12-node acts, branching.
- Between fights, part HP does **NOT** auto-heal - repair costs scrap at a Workshop. This pressure is what makes the economy matter.

---

## 6. The economy - *the hook that makes it sing* (locked)

The single most important system. Get it right and the meta-loop writes itself.

**Currencies & assets**
- **Scrap** - soft currency. From wins, salvage, and selling parts.
- **Parts** - the actual power. Won as loot, bought at Scrapyards, crafted at Workshops.

**On WIN → the Artificer loots a part.**
Pick **one** part from the **defeated Manabit's actual equipped loadout** (§12.1 - real parts, no generated drop table). You loot exactly what you just beat, so the wager is fully legible. *(Implication: enemy loadouts are authored/known, not randomly rolled.)*

**On LOSS → forfeit a part, but not necessarily the run.**
- A **broken (disabled) part is forfeited** - fiction: salvaged by the victor. You choose which disabled part to give up if several broke.
- You **salvage scrap** from the wreckage as consolation.
- If the mana core survived, the run continues - weaker, tenser.
- **Run ends when the mana core is depleted** (Manabit unmade) or you have no functional parts left. On run-end, **the Artificer persists** (XP + blueprints + banked garage); the construct you were carrying is lost.

**Workshop** - spend scrap to: **repair** part HP · **craft** parts (and mana cores) from unlocked blueprints · **fuse** two parts (post-slice).

> **Why not "lose the whole toy" on a loss:** straight total-wipe backfires - players hoard their good build and never touch the risk system, the opposite of what a roguelite wants. Per-part forfeiture keeps a loss stinging without wiping you, and creates the push-your-luck pull the genre runs on.

---

## 7. Progression & the overworld - the "keep your toy" payoff

Honor the *"I built this and I keep it"* fantasy at two scales, all hung off the **Artificer** as the persistent identity.

**Fight-scale:** win → keep your construct + take a part. Lose → lose a part.

**Run-scale (extraction - §12.5, LOCKED).** Extraction is **player-initiated at checkpoint nodes**: you may choose to **quit the run early and bank your surviving Manabit + parts** into the permanent Garage. This is the push-your-luck valve - *walk away now and keep your construct, or push deeper for better loot and risk losing it all.* Extraction is only offered at checkpoints (never mid-fight). Reaching the end of a run also banks. If you die instead, you lose the carried construct but keep:
- **The Artificer** - gains **XP** and unlocks **affinities** (attack / defense / mana / etc.) and **blueprints**.
- **Unlocked blueprints**, including mana-core recipes.

**Mana cores** are *crafted per build* by the Artificer, drawing on unlocked **affinities** (this is where the old "core personality" lives - an attack-affinity core vs. a defense core). Cores are consumable identity for a given Manabit, not account-permanent themselves.

**Overworld / avatar hub - POST-SLICE (do NOT build in M0-M4).**
The drippy customizable Artificer - hats, robes, cosmetic glam - is a genuine character-customization + hub system and a strong retention hook. It is explicitly deferred. The vertical slice must prove the **build → fight → wager** loop is fun *before* the avatar gets a wardrobe. Note it, scope it later, keep it out of the slice.

> **⚙️ Key tunable - flag for playtest:** how much survives death (§6/§7). Ship with **extraction on** (bank surviving construct) because the stated fantasy is keeping what you build; tune toward more-roguelike (Artificer + blueprints only) if stakes feel too soft.

---

## 8. Art direction (PS1-style low-poly)

**The one-line lock: PS1 *rendering technique*, cozy-craft *tone*.** Chunky pixels and vertex wobble, but warm, bright, and collectible - NOT the grimy liminal-horror mood. Same tech as a horror PS1 look, deliberately opposite palette and mood.

### The PS1 pipeline (Godot 4) - build this as a reusable render stack
- **Low internal resolution → nearest-neighbor upscale.** Render the 3D world to a `SubViewport` at a low res (start ~**320×240**, tune), then blit to the screen with **nearest** filtering. This is the source of the chunky-pixel look - do this first, it does most of the work.
- **Vertex snapping (the "jitter").** In a shared spatial vertex shader, snap each vertex to a coarse grid in clip/screen space (e.g. round to a low pixel granularity) so verts wobble as things move. Expose the snap amount as a shader uniform to dial intensity.
- **Affine texture warp.** Disable perspective-correct UVs so textures swim/warp on angled faces (the signature PS1 texture swim). Standard trick: multiply UVs by vertex `w` in the vertex shader and divide back in the fragment shader.
- **Textures:** low-res, **point (nearest) filtering**, limited palette, no/short mipmaps. Import all part textures with filter = Nearest. Small per-part atlases.
- **Lighting:** per-vertex / flat, not fancy per-pixel PBR. Cheap and period-correct.
- **Optional (keep light):** slight color-depth quantization and *very* mild dithering as a post pass. Go easy - heavy dither reads as horror. Skippable for the slice.

> This is a distinct, warmer cousin of the PS1 stack on the YouTube-channel project: reuse the *technique* (low-res + jitter + affine + point-filter), but **not** the crushed blacks / ~5-10% saturation / heavy Bayer dither. Here: brighter, more saturated, friendly.

### Look & content
- Chunky low-poly silhouettes, ~300-800 tris/part. Parts must read as **snap-together enchanted toy components** with obvious sockets.
- **Magic-as-craft, kept SUBTLE (per your call):** faint **etched glyphs baked into the low-res textures** (glyphs as texel detail, not extra geometry - very PS1-appropriate) + a soft **mana glow** (small emissive accents) at sockets and the core. It should read as a *toy that happens to be enchanted*, not a light show.
- **Explicitly NOT** cyber/glowing-circuitry, and **NOT** liminal-horror mood.
- Readable at mobile resolution (the low-res render actually helps here).
- Artificer avatar art (hats/robes) is **post-slice** - spec it with the overworld.

---

## 9. Godot project structure

```
res://
  parts/        # PartData .tres catalog (parts + mana cores) + meshes/materials
  manabits/     # Manabit assembler scene, Marker3D sockets
  combat/       # TurnManager, ActionResolver, targeting, simple AI
  run/          # Map graph (data-driven), node type handlers
  economy/      # Scrap, loot roll, Workshop, Scrapyard
  meta/         # Artificer progression (XP, affinities, blueprints), Garage, save/load (JSON)
  ui/           # Assembly screen, combat HUD, map, shop (touch-first)
  art/          # PS1 render stack (low-res SubViewport, vertex-snap/affine shader, point-filtered textures), glyph/mana-glow materials, low-poly meshes
  # overworld/  # POST-SLICE: avatar hub + customization. Not in the slice.
```

Autoloads: `GameState` (current run + garage + Artificer meta), `SaveManager`.

---

## 10. Milestones (build in order - slice = M0→M4)

- **M0 - Assembly & stats.** PartData model + Assembler. Snap parts on sockets, derive stats, swap parts in a Garage screen. *Proves the modular core.*
- **M1 - Combat.** Turn-based fight vs. one dummy Manabit: initiative, part-targeting, part-break (local HP→0 disables slot), core-death ends fight.
- **M2 - Consequences.** Win → loot one part from the defeated Manabit's real loadout. Loss → forfeit one broken part + gain scrap. *This is the loop.*
- **M3 - Run map.** 3-4 linear nodes + mini-boss. Add Workshop (repair/craft) and Scrapyard (buy/sell) nodes. No auto-heal between fights.
- **M4 - Artificer meta & save.** Artificer XP + one affinity, mana-core crafting, Garage extraction/banking, JSON save/load. **← Vertical slice complete.**
- **Post-slice:** overworld + avatar customization, more parts & cores, unique abilities, smarter AI, fusion, branching maps, balance pass, art polish.

**Definition of "slice done":** craft/assemble a Manabit → fight a turn-based battle → win/lose changes your parts → run of 3-4 nodes with drops → extract to a persistent garage as an Artificer who carries forward. Rough-playable target: a few focused weeks solo.

---

## 11. Work breakdown for parallel Claude Code sessions ("the team")

Clean seams - hand each to a separate session, integrate via the shared `PartData`/`Manabit` contracts in §2-3. **Freeze the data model in §2-3 first**; it's the interface every lane depends on.

| Lane | Owns | Depends on |
|---|---|---|
| **A · Parts & Assembly** | `parts/`, `manabits/`, Garage screen, derived-stat math | nothing - build first |
| **B · Combat** | `combat/` turn manager, targeting, break rules, dummy AI | Lane A's `Manabit` + `derived()` |
| **C · Economy & Run** | `economy/`, `run/` map + node handlers, loot roll, forfeiture | Lanes A & B (needs a resolvable fight) |
| **D · Artificer Meta & Save** | `meta/` Artificer XP/affinities/blueprints, mana-core crafting, Garage bank, JSON save/load | Lane A's `PartData` shape |
| **E · Art & PS1 render stack** | the reusable PS1 pipeline (§8: low-res SubViewport + vertex-snap/affine shader + point-filtered textures), low-poly part meshes, glyph/mana-glow materials, touch UI layout | Lane A sockets (for mesh fit) |

Suggested order to unblock everyone: **A → (B, D, E in parallel) → C** stitches the loop together. (Overworld/avatar is a later, separate lane - not part of the slice.)

---

## 12. Decisions locked (resolved)

All slice-level design questions are decided. Build to these - no judgment calls left open.

1. **Loot selection → REAL PARTS.** A win offers the defeated Manabit's *actual equipped parts*; pick one to take. No generated/rarity-rolled drop table in the slice - the wager is legible because you're looting exactly what you just beat. (Enemy loadouts are therefore authored/known so drops are predictable.)
2. **Ability depth → 3 ARCHETYPES.** Each part's `ability_id` resolves to one of three move archetypes so tactics are testable from day one:
   - **`SINGLE`** - one hard hit on a chosen target part.
   - **`MULTI`** - several weaker hits (spread across parts or a burst that chips multiple), good for breaking several parts / racing to disable.
   - **`GUARD`** - defensive: raise DEF, brace a part, or restore a little part HP (mana-cost gated).
   Parts are tagged with which archetype they grant. Balance the three against each other in the slice, expand the movepool later.
3. **Arms → INTERCHANGEABLE.** ARM_L and ARM_R both accept any `slot == "ARM_*"` part; no handedness in the slice.
4. **Mid-run re-animation → NO. Manabit unmade = RUN END.** If the mana core is depleted, the run is over and the Artificer returns to the hub with XP + blueprints (carried construct lost). Binding a fresh core mid-run is explicitly a post-slice idea, not in scope.
5. **Extraction → CHECKPOINT-BASED, PLAYER-INITIATED.** At each checkpoint node you may **extract: quit the run early to bank your surviving Manabit** into the permanent Garage. This is the push-your-luck valve - *walk away now and keep your construct, or push deeper for better loot and risk losing it.* Extraction is voluntary and only available at checkpoints (not mid-fight). Reaching the end of a run also banks. See §7.
6. **Weight → SPD curve → SOFT-THRESHOLD (build budget).** Weight under a budget is free; only *overweight* costs speed. Starting model:
   ```gdscript
   const WEIGHT_BUDGET      := 100   # tune - total weight you can carry "for free"
   const OVERWEIGHT_SPD_COST := 1    # tune - SPD lost per point of weight over budget
   # in derived():
   s.speed -= max(0, s.weight - WEIGHT_BUDGET) * OVERWEIGHT_SPD_COST
   ```
   This "feels best" because light/balanced builds pay nothing and there's a crisp, legible cost for overloading - a real choice, not a constant tax. Both constants are balance knobs; tune in playtest.
   *Optional post-slice refinement:* move `WEIGHT_BUDGET` onto the **LEGS** part as a `carry_capacity` stat, so choosing legs is meaningfully about mobility/load, not just a stat blob.
   *(SUPERSEDED by the Section 13 rider v1: capacity rides the CORE, not the legs.)*

---

*Ship few slots and ~a dozen parts, then expand. The Artificer, the mana core, and the wager are the spine - everything else is content and tuning. Balance is ongoing, not a one-time task; the combinatorial space is the whole point, and also the long tail.*


---

## 13. FROZEN CONTRACT (build this ONE thing before any lane fan-out) - locked

§11 says "freeze the data model (§2-3) first." §2-3 as written are **incomplete** - they define static part *definitions* but no runtime *instance* state, no ability numbers, and only two of the three fight outcomes the economy (§6) depends on. This section completes the interface. **No lane (A-E) may start until §13 is committed as `class_name` GDScript and the §13.7 smoke test is green.** Where §13 and §2-4/§12 disagree, **§13 wins** (noted inline).

### 13.1 Static definitions - `PartData`, `AbilityData` (Resources, `.tres`, immutable at runtime)

> **Supersedes §2:** the part's move is now a direct `AbilityData` reference (`ability`), not an `ability_id: StringName`. This closes the "`move_power` lives nowhere" hole - the numbers §4's formula needs live on `AbilityData`.

```gdscript
class_name AbilityData extends Resource
# The one move a part grants. Referenced by PartData.ability. Pure data.

@export_enum("SINGLE", "MULTI", "GUARD") var archetype: String = "SINGLE"
@export var display_name: String = ""
@export var power: int = 0            # bonus added to attacker ATK, per hit (SINGLE/MULTI)
@export var hit_count: int = 1        # MULTI: number of hits; SINGLE: always 1
@export var guard_amount: int = 0     # GUARD: DEF added for the turn, OR part-HP restored
@export_enum("DEF_BUFF", "PART_RESTORE") var guard_kind: String = "DEF_BUFF"
@export var mana_cost: int = 0        # ENERGY spent to use this move (all archetypes)
```

```gdscript
class_name PartData extends Resource
# STATIC part definition. Loaded once from res://parts/*.tres and CACHED by Godot:
# every Manabit that equips this part shares the SAME object. NEVER write fight
# state (current HP, disabled) onto it - do that on PartInstance (§13.2).

@export var id: StringName
@export var display_name: String
@export_enum("HEAD", "CORE", "ARM_L", "ARM_R", "LEGS", "BACK") var slot: String

@export_group("Presentation")
@export var mesh: Mesh
@export var socket_offset: Transform3D

@export_group("Stats")               # all AGGREGATE contributions except max_hp
@export var max_hp: int = 1          # LOCAL durability; also the starting current_hp
@export var attack: int = 0
@export var defense: int = 0
@export var speed: int = 0
@export var weight: int = 0
@export var energy: int = 0          # contribution to the fight mana pool

@export_group("Ability")
@export var ability: AbilityData     # the move this part grants; null = grants no move

@export_group("Core / meta")
@export var is_core: bool = false
@export var affinity: StringName = &""   # cores only: &"attack"/&"defense"/&"mana"
@export_enum("COMMON", "RARE", "EPIC") var rarity: String = "COMMON"
@export var blueprint_unlockable: bool = true
```

**LOCKED so cores never soft-lock a fight:** in the slice a **CORE's `ability` is `null`** - the core is life + affinity, never a weapon. This is what makes the "all weapon parts disabled, core alive" state (§13.3) *reachable and meaningful* rather than an accident.

### 13.2 Runtime state - `PartInstance`, `ManabitState` (`RefCounted`, never saved as `.tres`)

```gdscript
class_name PartInstance extends RefCounted
# One per equipped part per Manabit. Holds the MUTABLE fight state that must NOT
# touch the shared PartData resource. Cheap to make, discarded at fight end.

var data: PartData
var current_hp: int
var disabled: bool = false

func _init(p: PartData) -> void:
    data = p
    current_hp = p.max_hp

func take_damage(amount: int) -> void:
    if disabled:
        return
    current_hp = maxi(0, current_hp - amount)
    if current_hp == 0:
        disabled = true          # DISABLE IS PERMANENT for the fight (see lock below)

func restore(amount: int) -> void:
    # GUARD PART_RESTORE. LOCKED: never revives a part already at 0 (disabled).
    if disabled:
        return
    current_hp = mini(data.max_hp, current_hp + amount)
```

> **Resolves the §3-vs-§4 conflict on GUARD restore:** disable is **permanent for the fight** - `restore()` only heals a part still above 0. GUARD is for keeping a strained part *alive*, never for un-breaking one. (Re-enabling is a post-slice idea, same bucket as mid-run re-animation, §12.5.4.)

```gdscript
class_name ManabitState extends RefCounted
# The runtime fighting unit. Six slots keyed by slot name; CORE is the life bar.
# The equipped arrays/dicts hold PartInstances - NEVER PartData.

const WEIGHT_BUDGET := 100
const OVERWEIGHT_SPD_COST := 1
const MANA_REGEN_PER_TURN := 2       # tunable (see §13.4)

const SLOT_NAMES := ["HEAD", "CORE", "ARM_L", "ARM_R", "LEGS", "BACK"]

var slots: Dictionary = {}           # slot_name(String) -> PartInstance or null
var mana: int = 0                    # current ENERGY pool for this fight
var guard_bonus: int = 0             # transient DEF from GUARD, cleared each turn

func core() -> PartInstance:
    return slots.get("CORE")

func alive() -> bool:
    var c := core()
    return c != null and not c.disabled and c.current_hp > 0

func active_parts() -> Array[PartInstance]:
    var out: Array[PartInstance] = []
    for pi in slots.values():
        if pi != null and not pi.disabled:
            out.append(pi)
    return out

func has_offensive_move() -> bool:
    for pi in active_parts():
        var a := pi.data.ability
        if a != null and a.archetype != "GUARD":
            return true
    return false

func derived() -> Dictionary:
    # LIVE recompute over NON-disabled parts. Call after every disable.
    var s := {"attack": 0, "defense": 0, "speed": 0, "weight": 0, "energy": 0}
    for pi in active_parts():
        var d := pi.data
        s.attack  += d.attack
        s.defense += d.defense
        s.speed   += d.speed
        s.weight  += d.weight
        s.energy  += d.energy
    s.speed -= maxi(0, int(s.weight) - WEIGHT_BUDGET) * OVERWEIGHT_SPD_COST
    s.speed = maxi(1, s.speed)       # initiative never hits 0 / negative
    return s

func start_fight() -> void:
    mana = derived().energy          # pool starts FULL = sum of equipped energy
    guard_bonus = 0

func begin_turn() -> void:
    guard_bonus = 0
    mana = mini(derived().energy, mana + MANA_REGEN_PER_TURN)
```

**Garage build invariant (LOCKED):** the Garage (Lane A) may not let you deploy a Manabit with a live core but **zero offensive parts** (no non-CORE part whose `ability.archetype != "GUARD"`). This guarantees every genuine loss produces at least one disabled offensive part to forfeit (§13.3), so the forfeit path can never dead-end.

### 13.3 The three fight outcomes (the missing state - closes the M2 "THIS IS THE LOOP" hole)

§4 only ended a fight at core→0. §6/M2 depend on a **survivable** loss. Lock **three** outcomes, checked after every action:

```gdscript
enum FightResult { NONE, WIN, SURVIVABLE_LOSS, DEATH }

# Resolver checks, in this order, after each resolved action:
#   enemy.alive() == false                     -> WIN
#   player.alive() == false                    -> DEATH
#   player.has_offensive_move() == false       -> SURVIVABLE_LOSS  (forced concede)
#   player tapped CONCEDE while alive          -> SURVIVABLE_LOSS  (voluntary)
```

- **WIN** (enemy core HP → 0): you keep your Manabit; loot **one** part from the enemy's real equipped loadout (§6/§12.1).
- **DEATH** (your core HP → 0): the Manabit is unmade; **run ends** (§12.5.4); the Artificer keeps XP + blueprints + banked garage.
- **SURVIVABLE_LOSS** - the beat §6 calls the whole point. Fires when you still have a live core but **no offensive move left** (all weapon parts disabled), *or* you voluntarily **CONCEDE**. On it: the victor salvages **one of your disabled parts** (you choose if several broke); you gain salvage **scrap**; the **run continues, weaker** (§6).
  - **CONCEDE is a combat-HUD action** (Lane B/E) - this is the reachable code path §4 lacked.
  - **Voluntary CONCEDE requires ≥1 already-disabled part** (you can't rage-quit a fight for free before anything breaks). The sanctioned no-cost "walk away" is **checkpoint extraction** (§12.5.5), not concede. This cleanly separates the two: *concede = mid-fight, costs a broken part; extract = at checkpoint, costs nothing.*
- **Slice AI gate (LOCKED):** ordinary `BATTLE` nodes must resolve as `WIN` or `SURVIVABLE_LOSS` - the AI targets your non-core parts and only an **ELITE / mini-boss** may aim your core. This keeps `DEATH` (full run loss) rare and legible, exactly as §6 intends.

### 13.4 Damage & mana (locks the numbers §4/§3 referenced but never defined)

- **Per-hit damage:** `per_hit = maxi(1, attacker_ATK + ability.power - target_owner_DEF_incl_guard)` where `attacker_ATK = attacker.derived().attack` (aggregate) and `ability.power` is the per-hit move bonus - **no double-count**. `DEF = defender.derived().defense + defender.guard_bonus`.
- **SINGLE:** one hit on the player-chosen target part (or the core, if `ability.can_target` allows - cores are hittable per §4; overflow past a part does **not** splash to the core in the slice - a shot hits exactly what you aimed at).
- **MULTI:** `hit_count` separate hits; **each hit auto-targets the enemy's current lowest-HP non-core part** (so it naturally spreads and races to disable - its whole identity). No extra targeting UI.
- **GUARD:** no enemy target. `DEF_BUFF` → `guard_bonus += guard_amount` for this turn; `PART_RESTORE` → `restore(guard_amount)` on a chosen still-alive part.
- **Mana (ENERGY), LOCKED for the slice:** pool starts full at `derived().energy` and regens `+MANA_REGEN_PER_TURN` each turn (capped at the pool max). **Every** move costs `ability.mana_cost`; a move whose cost exceeds current `mana` is greyed out. This makes GUARD-spam self-limiting and makes energy a real build stat rather than dead flavor. (Numbers are balance knobs; the *rule* is frozen.)

### 13.5 SaveManager schema (JSON, boundary-only - matches §1 "JSON for meta/garage")

**LOCKED: save only at rest boundaries** (garage / post-extraction / run-end) - never mid-fight. There is no combat state to serialize, so §1's "JSON save/load" stays a one-file job (closes the "resumable-mid-run save is a hidden subsystem" worry). A saved Manabit is a list of **part ids** (+ per-part current_hp so a banked damaged build stays damaged); the live catalog is looked up by id on load - parts are never embedded.

```jsonc
{
  "version": 1,
  "artificer": {
    "xp": 0,
    "affinities": ["attack"],            // unlocked affinity ids
    "blueprints": ["core_basic", "arm_hammer"]  // unlocked craftable ids
  },
  "garage": [                            // banked Manabits
    {
      "core_id": "core_basic",
      "parts": [                         // equipped non-core parts
        { "id": "arm_hammer", "current_hp": 12 },
        { "id": "legs_light", "current_hp": 20 }
      ]
    }
  ],
  "scrap": 0,
  "run": null                            // null unless a run is banked at a checkpoint
}
```

`GameState` (autoload) holds the live run + garage + Artificer meta; `SaveManager` (autoload) owns serialize/deserialize against **this** schema. Lane D freezes this shape before B/C/D fan out.

### 13.6 What each lane freezes on

`AbilityData` · `PartData` · `PartInstance` · `ManabitState` (incl. `derived()`) · `FightResult` + the three-outcome resolver · the §13.4 damage/mana rules · the §13.5 save schema. Commit all of it as `class_name` GDScript (text - merges cleanly; `.tres` does not). Only *then* fan out A → (B, D, E) → C.

### 13.7 The gate - one headless smoke test (must be green before fan-out; re-run after every merge)

It exercises the **whole loop** end to end (assemble → win+loot → survivable-loss+forfeit → death → save → reload → assert), using code-built fixtures so it needs no `.tres` or scene. **Re-run it yourself after each lane merge** - do not trust a lane's "green" (see the owner's `verify-subagent-test-claims` note).

Run (Windows; the `--import` step is **required once on a fresh checkout** - without it Godot hasn't registered the `class_name` globals yet and the script fails to parse):
```powershell
cd "G:\ClaudeApps\manabit"   # project root once it exists
& "G:\Godot\Godot_v4.7-stable_win64_console.exe" --headless --path . --import
& "G:\Godot\Godot_v4.7-stable_win64_console.exe" --headless --path . -s "res://tests/smoke_contract.gd"
```
Exit 0 + `SMOKE PASS` = green. (Verified against Godot v4.7.stable on 2026-07-11: all five cases pass.)

```gdscript
extends SceneTree
# res://tests/smoke_contract.gd - frozen-contract gate.

func _initialize() -> void:
    var ok := true
    ok = _run("assemble + derived", _t_assemble) and ok
    ok = _run("win -> loot enemy part", _t_win_loot) and ok
    ok = _run("survivable loss -> forfeit disabled part", _t_survivable_loss) and ok
    ok = _run("death ends run", _t_death) and ok
    ok = _run("save -> reload roundtrip", _t_save_reload) and ok
    print("SMOKE PASS" if ok else "SMOKE FAIL")
    quit(0 if ok else 1)

# --- fixtures -------------------------------------------------------------
func _mk_ability(arch: String, power: int, hits: int, cost: int) -> AbilityData:
    var a := AbilityData.new()
    a.archetype = arch; a.power = power; a.hit_count = hits; a.mana_cost = cost
    return a

func _mk_part(id: String, slot: String, hp: int, atk: int, df: int, spd: int, wt: int, en: int, ab: AbilityData) -> PartData:
    var p := PartData.new()
    p.id = id; p.slot = slot; p.max_hp = hp
    p.attack = atk; p.defense = df; p.speed = spd; p.weight = wt; p.energy = en
    p.ability = ab; p.is_core = (slot == "CORE")
    return p

func _mk_manabit(core_hp: int) -> ManabitState:
    var m := ManabitState.new()
    m.slots["CORE"]  = PartInstance.new(_mk_part("core", "CORE", core_hp, 0, 2, 2, 10, 6, null))
    m.slots["ARM_R"] = PartInstance.new(_mk_part("hammer", "ARM_R", 8, 5, 0, 3, 40, 0, _mk_ability("SINGLE", 4, 1, 1)))
    m.slots["ARM_L"] = PartInstance.new(_mk_part("flail", "ARM_L", 6, 3, 0, 3, 30, 0, _mk_ability("MULTI", 2, 3, 2)))
    m.slots["LEGS"]  = PartInstance.new(_mk_part("legs", "LEGS", 10, 0, 1, 6, 30, 0, null))
    m.start_fight()
    return m

# --- cases ----------------------------------------------------------------
func _t_assemble() -> bool:
    var m := _mk_manabit(30)
    var d := m.derived()
    # weight 110 > budget 100 -> -10 speed; base speed 14 -> 4, clamped >=1
    return m.alive() and m.has_offensive_move() and d.attack == 8 and d.speed == 4

func _t_win_loot() -> bool:
    var enemy := _mk_manabit(1)
    enemy.core().take_damage(5)                      # core -> 0
    if enemy.alive():
        return false
    # loot: pick any real equipped part from the defeated loadout
    var lootable := []
    for pi in enemy.slots.values():
        if pi != null and not pi.data.is_core:
            lootable.append(pi.data.id)
    return lootable.has(&"hammer")

func _t_survivable_loss() -> bool:
    var me := _mk_manabit(30)
    me.slots["ARM_R"].take_damage(99)                # both weapon parts disabled
    me.slots["ARM_L"].take_damage(99)
    var forced := (not me.has_offensive_move()) and me.alive()   # -> SURVIVABLE_LOSS
    var disabled := []
    for pi in me.slots.values():
        if pi != null and pi.disabled:
            disabled.append(pi.data.id)
    return forced and disabled.size() >= 1           # a disabled part exists to forfeit

func _t_death() -> bool:
    var me := _mk_manabit(4)
    me.core().take_damage(4)                         # core -> 0 -> DEATH / run end
    return not me.alive()

func _t_save_reload() -> bool:
    var save := {
        "version": 1,
        "garage": [{ "core_id": "core", "parts": [{ "id": "hammer", "current_hp": 3 }] }],
        "scrap": 7,
    }
    var path := "user://smoke_save.json"
    var f := FileAccess.open(path, FileAccess.WRITE)
    f.store_string(JSON.stringify(save)); f.close()
    var raw := FileAccess.get_file_as_string(path)
    var back = JSON.parse_string(raw)
    return back != null and int(back["scrap"]) == 7 \
        and back["garage"][0]["parts"][0]["id"] == "hammer" \
        and int(back["garage"][0]["parts"][0]["current_hp"]) == 3

# --- harness --------------------------------------------------------------
func _run(name: String, fn: Callable) -> bool:
    var res = fn.call()
    var pass_ok: bool = (res == true)   # explicit bool: can't infer := off a Variant
    print(("  [%s] " % ("PASS" if pass_ok else "FAIL")) + name)
    return pass_ok
```

> **Definition of "contract frozen":** the five `class_name` files above exist and `smoke_contract.gd` prints `SMOKE PASS` (exit 0). That is the single gate every lane branches from - and the thing you re-run, yourself, after every integration.

### Section 13 rider v1 (2026-07-18) - CARRY capacity (additive, TD-countersigned)

- `derived()` now also returns a `"capacity"` key: `capacity = WEIGHT_BUDGET (100) + max(0, carry)` of the **SEATED** core (`slots.get("CORE")`); a disabled or absent core means capacity = 100.
- Strain and the SPD clamp now compute against `capacity` (not the flat `WEIGHT_BUDGET`).
- `PartData` gains an additive `carry` int export (default 0); it is inert on non-CORE bits.
- No save-schema change.
