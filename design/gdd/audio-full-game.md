# MANABIT - FULL-GAME AUDIO DESIGN

STATUS: TEAM-RATIFIED audio plan. Owner-approved direction (music = The Wound Spring, decided 2026-07-19). Pipeline = team-audio (audio-director + sound-designer + technical-artist + accessibility + gameplay-programmer lanes; this document is the compiler assembly of all five).

Totals at a glance (from the Section 2 inventory): 80 distinct audio event/asset ids across groups 1-7 (wiring-only silence rows excluded); 109 files at full build-out = 14 shipped + 95 to produce; P0 tier = 53 files, of which 39 are new files to produce. Redundancy rule (accessibility R10, stated once here so no future seam gates a decision on hearing alone): every information-bearing audio ladder in this plan is reinforcement, never the sole channel.

Contents:
1. Audio direction (the sound bible, verbatim)
2. Complete asset inventory (verbatim)
3. Accessibility requirements
4. Technical plan (verbatim)
5. Implementation task plan
6. Open questions between team members

---

# SECTION 1 - AUDIO DIRECTION (verbatim, audio-direction-v1.md)

MANABIT AUDIO DIRECTION v1
Audio Director deliverable - design only. OWNER DECISION 2026-07-19: music direction = CANDIDATE B "The Wound Spring" (procedural music box, stems, existing Python pipeline). Candidate C "The Artificer's Waltz" is the named upgrade path post-playtest; Candidate A is fallback only.
Grounded in: DESIGN.md section 5, workshop-style-direction.md (ratified visual direction), calm_built_closed.png, tools/audio/make_sfx.py (existing seeded procedural pipeline, 14 wavs, -3 dBFS peak norm, mix gain in ui/sfx.gd)

---

1. SONIC IDENTITY

MANABIT sounds like a toymaker's bench under a warm lamp at night: small wooden objects handled by careful hands, brass instruments that tick and settle, paper that whispers, and underneath it all one soft amber hum - the soul in the core - that is the only sound in the room that is alive. The material palette is the visual token system made audible: walnut (dry modal toks, the pipeline's free-bar sines - already the house voice), brass (FM bells, ratchets, lever throws - the mechanism-and-celebration voice), parchment and ink (soft filtered noise, short and papery), felt (not a sound but a damper - it shortens every tail and catches every landing), and mana (pure warm sine and bell shimmer, always sourced from an event or a seated core, exactly as the visual glow is always sourced from a socket or seam). The register is intimate and mid-focused: fundamentals live 150-900 Hz, shimmer is lowpassed (nothing harsh above ~7 kHz), transients are rounded like Baloo 2 letterforms - chunky, never clicky. Dynamics are close-mic'd and small; this is a room you could fall asleep in. The emotional throughline from cozy bench to real-stakes fight is scale honesty: combat is the same toy materials struck harder - wood still toks, brass still rings - but the core's hum is a life, and when stakes rise the room gets QUIETER, not louder, so that when a soul is in peril you hear it beating, and when it is unmade you hear nothing at all. Danger is subtraction. The lamp never becomes a spotlight.

One more scoping call, mirroring "the bit is PS1, the chrome is native-res": the audio is the ROOM, not the render - so audio is warm and full-fidelity, never bitcrushed or sample-rate-crunched. The toy-scale reads through pitch, size, and material, not through lo-fi artifacts.

---

2. PALETTE RULES

Material-to-domain map (the audio token table):

| Sound material | Synthesis voice (existing pipeline) | Owns these domains |
|---|---|---|
| Walnut / wood | tok() modal sines, low f0 150-700 | Structure and furniture: drawers, tray, card lands, COMMON reveals (wood-tok), navigation, invalid_clunk, loss_settle. The default material - when unsure, it is wood. |
| Brass | bell() FM + brass() harmonic stacks, ratchet ticks | Mechanism and commitment: sockets, gauges, the Balance, switch_throw, seal_channel ratchet, gear_tick, medallion taps, BIND plate, victory. Brass is the only material allowed to CELEBRATE. |
| Mana / soul | pure sines, soft bell shimmer, slow beats | Life and magic: core_wake, the Binding, waking kindles, soul-glow hum, hit_core, core_peril, THE UNMAKING flare. Rule: mana sound is always SOURCED - it emanates from a core, a socket, or a ritual in progress, never free-floating decoration. |
| Parchment / ink | short bandpassed noise, very quiet | Information: ledger_open, work-order ink_wipe, tag untie, toasts, page-y UI slides. Paper is never louder than the thing it describes. |
| Felt | a damper, not a voice | Landings and tails: every object that touches the stand, tray, or drawer gets a felt-shortened decay. Felt is why MANABIT has no reverb - the room is soft-furnished; tails die politely. |
| Wax | lowpassed thump + soft squish noise | Seals and finality: wax_stamp, BIND press, SOLD. One thunk, no strobe - matches --stamp-thunk. |
| Glimmer (teal) | liquid: drip, glass-edge sine | still_drip, Glimmer transactions. Deliberately NOT brass, exactly as the teal token is deliberately not amber. |

Affinity accent (never carried by sound alone, always riding the visual tint): attack ember = slightly lower, harder attack; defense slate = rounder, longer sustain; mana teal = airier, liquid onset.

Pitch and rarity conventions:
- snap pitches UP with rarity (already canon).
- The reveal ladder ascends in SHIMMER and SIZE, not just pitch: COMMON = dry wood-tok (dies fast) / RARE = glass-cobalt chime (brighter, longer) / EPIC = deep bell + faint choral (LOWER fundamental, biggest body, longest tail). Epic goes down and wide, not up and shrill - that is what keeps it out of casino territory.
- UI micro-sounds sit an octave above furniture sounds and at least 10 dB below them.

Loudness discipline (the "gold is rationed" rule, in audio): full loudness is reserved for exactly the moments that are allowed brass-hi visually - snap (the hero sound), seal_crack, the EPIC bell, bound_chord, victory_chord, and THE UNMAKING's flare. Everything else lives 6-12 dB under. At most ONE hero-loud sound per interaction beat; if two qualify, the more soul-adjacent one wins and the other ducks. Ambient brass never rings unprompted (the anti-casino guard: no idle sparkle, no attract-mode chimes, ever).

Expanded banned list (extends "foil/plastic crinkle, casino chimes, harsh electronic beeps"):
- Slot-machine payout cascades, coin-shower loops, escalating jackpot arpeggios
- Sci-fi UI telemetry: blips, data chatter, hologram warbles, laser anything
- Trailer vocabulary: risers, braams, impacts-with-sub-drops, whoosh-hits
- Sidechain-pumped or four-on-the-floor anything
- Bitcrush, sample-rate crunch, vinyl static as an aesthetic (see scoping call above)
- Long cathedral/hall reverbs, detuned drone beds, reversed audio, whispering (the liminal-horror fence; core_peril's controlled 2 Hz beat is the ONE sanctioned unease device)
- Phone-notification sound-alikes (tri-tones, marimba pings)
- Human screams or spoken voice from Manabits; if constructs ever vocalize it is tiny bell-and-clockwork speak, decided separately
- Any sound above -12 dBFS from a pure UI control (taps never shout)

---

3. MUSIC DIRECTION - OWNER-DECIDED: "The Wound Spring" (Candidate B)

A music box the Artificer built and winds now and then - short hand-authored 8-16 bar motifs played on the SAME FM bells, brass pads, and felt-damped toks that already voice the game, sparse and patient: a phrase, a rest, another phrase. The score is not wall-to-wall; it is a companion object in the room that sometimes plays. Instrumentation: bell() as music-box tines, brass() as a soft pad underneath, low toks as heartbeat percussion, all rendered offline to stems. Adaptation: stems (melody / bells / pad / pulse) rendered separately, mixed live on Godot buses: bench = full quartet, shop = bells + pad, run = pulse + melody, combat = pulse only thinning further as stakes rise, death = hard stop. Motifs are authored note-data (composed by hand, rendered by machine) - minimal-composition INSIDE the procedural renderer, not random notes. Production path: extend make_sfx.py; seeded, byte-reproducible, zero installs, gates via the existing smoke_audio pattern, tiny OGG/WAV footprint for web. Risk: MEDIUM on musical ceiling; mitigated by sparsity and by motif note-data porting straight to the Waltz (Candidate C) if the ceiling needs raising post-playtest.

KEY LAW: the existing stingers define the home key - victory_chord is C major, mend is a C major arpeggio, loss_settle sits on A minor color, death_winddown descends to A (220 Hz), core_peril beats around A2. ALL music stays in C major / A minor so every stinger lands in-key. Any future stinger obeys the same key or bends the music, never both.

---

4. AMBIENCE DIRECTION

Principle: every room tone is felt, not heard (-35ish LUFS), built from 2-3 identifiable diegetic sources plus a near-silent air bed, with sparse randomized one-shot garnish (20-60s apart, never rhythmic). No weather drama, no drones.

- WORKSHOP: air bed (lowpassed brown noise, barely there) + a slow mantel-clock tick (~0.8 Hz, soft wood-brass, randomized micro-timing so it never metronomes) + THE SOUL: a seated awake core emits a soft amber breathing hum phase-locked to the same engine clock as the visual sleep-breath and cavity heartbeat (--invite-breath). Dormant stage (no core seated) = the hum is absent and the room is noticeably emptier - the player should feel the difference before they can name it. Garnish: wood settle, lamp filament ping (very rare), thread-spool roll.
- COFFER NOOK: the workshop bed pulled down 6 dB (same room, held breath) + the coffer itself: faint muffled shifting of sleeping scrap inside, a tiny interior rune hum that swells slightly as the press-hold channel charges. Expectancy through quiet, not through risers.
- BARROW / FETTLE'S CART: outdoor-adjacent market quiet - low wind over canvas, the cart's wooden creak, and Fettle's own body as the signature source: his forge-belly gives a soft bellows-and-ember loop and his wind-up key gives an occasional slow ratchet tick (his idle presence, like a cat purring). The Still contributes an intermittent condensation drip (the still_drip seam doubles as ambience garnish). The Melt = low warm ember wash near its panel only.
- THE RUN: travel quiet - low wind, satchel-leather creak between steps (route_step carries the footfall + jingle), a faint rail hum that rises only near junctions and dies on switch_throw. Node modifiers may tint the bed subtly (overgrown = leaves, rusted = drier creaks) but this is garnish-tier, deferred.
- COMBAT: the boldest call in this document - combat has almost NO room tone. The bed drops to the two cores' hums (yours and theirs, slightly detuned from each other, each dying with its core's HP) plus felt-silence. Toy-scale fights on a felt mat in a quiet room: every hit lands in clean air, which is why the modest procedural hits already feel chunky. No crowd, ever.

Deliberate silence (protect these):
- THE UNMAKING (canon, already engineered: death_winddown fully decayed by 900ms, stillness at t=1200): at the unmaking, a master stillness gate closes - music hard-stops (a hand lifted off, not a fade), ambience mutes, UI sounds are refused, both core hums are gone. Hold total stillness through the parts release and stillness beat (minimum 1.5s, gated by the beat system, not a timer race). The first sound after is the soft wood of parts settling. Nothing else is allowed inside this window - this is the game's most expensive sound and it costs nothing.
- The BIND ritual: as the seal press-hold begins, ambience and music dip 6 dB (the room holds its breath); bound_chord rings in the cleared space.
- The EPIC reveal's 600ms hold: ambience dips, the deep bell owns the air.
- Screen transitions get 150-300ms of ambience crossfade through near-silence rather than butt-spliced loops.

---

5. ADAPTIVE RULES

- Music ducks (-4 to -6 dB, 50ms attack / 400ms release, via bus volume tweens - deterministic, cheap, web-safe; not a compressor): under every hero-loud SFX (snap, seal_crack, epic bell, wax_stamp), under Fettle bark moments, under ritual channels (seal_channel, BIND hold).
- Music stops (hard): THE UNMAKING (see stillness gate). Music also does not play during the Waking's kindle sequence - the reveal ladder is the music there.
- Combat intensity = subtraction: entering combat, music reduces to the pulse stem only. Ordinary exchanges keep pulse + occasional melody fragment. As stakes climb (elite, boss, core exposed) the melody mutes first, then the pad, until at maximum tension only the pulse and the two core hums remain. Never add-a-drum-layer escalation - MANABIT's tension curve is the room going quiet.
- Core-peril treatment: the existing core_peril one-shot (108/110 Hz, 2 Hz beat) is promoted to a STATE: while your core is below threshold, a low sustained version of that beating pair runs as a bed, the music melody stem is muted, and the beat's 2 Hz pulse phase-locks to the visual heartbeat clock. The 2 Hz beat becomes the score. When peril ends (mend or kill), the bed releases over ~1s and the melody stem returns.
- Win: music cuts a half-beat BEFORE victory_chord so the stinger lands in clean air (it is in C, it IS the cadence); bench music resumes ~1.2s later. Survivable loss: loss_settle rings alone; music returns at -6 dB for the next ~10s (subdued, not punished). Death: full stillness protocol; music does NOT return on the death screen at all, and the Workshop reopens with ambience only for the first ~10s before the music box winds up again - the room mourns quietly, then life goes on.

---

6. MIX TARGETS

Bus layout: Master > Music / Ambience / SFX / UI (four buses; ducking and the stillness gate are bus tweens).

| Category | Loudness target | Peak discipline |
|---|---|---|
| Master (whole game) | about -16 LUFS integrated (mobile + web friendly) | -1 dBTP ceiling |
| SFX (gameplay) | -18 LUFS short-term typical; hero moments may reach -12 short-term | per-file -3 dBFS (pipeline norm, keep); bus leaves 3 dB headroom |
| Music | -22 LUFS integrated on its bus | never the loudest thing in any frame |
| Ambience | -35 LUFS (felt, not heard); combat bed lower still | garnish one-shots max -28 |
| UI | -24 LUFS, micro | any UI file peaking above -12 dBFS is a bug |

The four ducking relationships that matter:
1. Hero SFX duck Music -6 dB (50ms / 400ms release) - the snap always owns its moment.
2. Peril state mutes the Music melody stem and ducks Ambience -6 dB - danger empties the room.
3. Ritual channels (seal_channel, BIND hold, epic hold) duck Music and Ambience -6 dB - held breath.
4. THE UNMAKING closes the master stillness gate: everything except the death channel to silence, held through the stillness beat, released only by the parts-settle.

Web/mobile notes: OGG Vorbis for music/ambience streams, keep the existing WAV one-shots (tiny); first user tap unlocks the audio context (HTML5 autoplay policy) - the Workshop's first frame must not depend on sound; the existing 8-voice pool is the right size for mobile, hero sounds get pool priority.

---

7. PRIORITIES - if only half ships before the public playtest

SHIP (in order):
1. Voice the silent seams via the existing pipeline. Priority inside the batch: snap (the hero sound, pitch-laddered) > core_wake > the Coffer set (seal_channel / seal_crack / lid_spring / reveal common-rare-epic) > the BIND set (wax press, bound_chord) > drawer slide/tuck + medallion taps + UI taps > Barrow transaction set (wax_stamp, coin_scrap, still_drip) > Run set (switch_throw, route_step, fork_reveal).
2. Bus architecture + the stillness gate + the four duckings + a LUFS pass - second, not last; THE UNMAKING's protection must be structural before playtesters see a death.
3. Workshop ambience (air + clock + soul-hum with its dormant/awake difference) and the combat core-hum bed.
4. ONE music piece: the Workshop bench loop in The Wound Spring stems.

CUT (safely deferred): shop/run/nook music variants, Barrow and Run ambience garnish, node-modifier ambience tints, full combat stem adaptivity beyond the peril rule, the post-death mourning-quiet timing polish, Fettle idle ratchet, and any Candidate C exploration.

Rationale: playtesters will forgive absent music in a cozy game with a living room tone and fully voiced hands-on interactions; they will not forgive a silent drawer, a silent snap, or a cheapened death. Interaction foley first, the sacred silence second, the room third, the song fourth.

---

# SECTION 2 - COMPLETE ASSET INVENTORY (verbatim, audio-sfx-spec.md)

# MANABIT - COMPLETE AUDIO ASSET INVENTORY (Sound Designer lane, 2026-07-19)

Design-only deliverable. Obeys audio-direction-v1.md (owner-signed music call: The Wound Spring).
Grounded in DESIGN.md section 5, tools/audio/make_sfx.py (seeded, byte-reproducible, -3 dBFS norm), ui/sfx.gd (8-voice pool, Sfx/SfxBig + pan sub-buses, ref-counted duck).

Conventions used below:
- Bus column uses the direction's four-bus layout (Master > Music / Ambience / SFX / UI). "SFX-hero" = routed via the existing SfxBig tier inside SFX (gets the -4 dB Sfx duck for free) AND triggers the Music duck.
- Vol = manifest gain_db suggestion (files stay -3 dBFS peak; all mix in the manifest). Jitter = pitch humanize range. Pan = L/C/R quantized (the three existing panner sub-buses).
- Production methods: PROC-1 = procedural one-shot via make_sfx.py; PROC-LOOP = procedural seamless loop (make_sfx.py extension, OGG for long beds); STEMS = authored note-data rendered offline by the pipeline; SOURCE = cannot be honestly synthesized with this stdlib pipeline, needs sourced/recorded audio.
- Priority: P0 = playtest-ship (direction section 7), P1 = post-playtest, DEFER = direction's CUT list.
- Wiring: WAV-EXISTS / SEAM-EXISTS-NEEDS-WAV / NEEDS-SEAM-AND-WAV. Special case REG-NEEDS-CALLSITE-AND-WAV = in KNOWN_SEAMS but no play() site (the three reveals).
- All pitched material lands in C major / A minor (the KEY LAW). All shimmer lowpassed at or under 7 kHz. Felt rule: every landing gets a shortened tail; no reverb anywhere.

BOOKKEEPING BUG FOUND (fix during wiring): `fettle_apologise` has a call site but is missing from KNOWN_SEAMS in ui/sfx.gd (only greet/appraise are registered) - it currently warns "unknown seam". Add it when its wav lands.

---

## GROUP 1 - THE 14 EXISTING COMBAT WAVS (11 seams) - respec flags only, no redos

| Asset id | Trigger | Sound (material / pitch / dur / envelope) | Bus | Vol / jitter / pan | Production | Pri | Wiring |
|---|---|---|---|---|---|---|---|
| hit (x3) | part takes damage | wood: tok f0 560/620/690, 140ms, fast decay + soft click | SFX | -6 dB / +-4% / combatant side | PROC-1 (shipped) | P0 | WAV-EXISTS |
| hit_core (x1) | damage reaches the core | mana: sine drop 130->72 + knock + beating 880/932 bell pair, 550ms | SFX-hero | -3 dB / +-4% / combatant side | PROC-1 (shipped) | P0 | WAV-EXISTS |
| part_break (x2) | part HP hits 0, tumbles off | wood: crack noise + body tok 190 + 3 clatter toks, 360ms | SFX-hero | -4 dB / +-4% / combatant side | PROC-1 (shipped) | P0 | WAV-EXISTS |
| attack_whoosh (x1) | attack lunge starts | air: bandpass sweep 350->1600, 240ms hump | SFX | -12 dB / +-4% / attacker side | PROC-1 (shipped) | P0 | WAV-EXISTS |
| guard_up (x1) | GUARD raised | brass: bell 1245 ratio 3.7 + swish, 420ms, lp 6k | SFX | -8 dB / +-4% / C | PROC-1 (shipped) | P0 | WAV-EXISTS |
| mend (x1) | repair / rest heal | mana: 4 bells C6 E6 G6 C7 arpeggio, 640ms, lp 7.5k | SFX | -8 dB / +-4% / C | PROC-1 (shipped) | P0 | WAV-EXISTS |
| core_peril (x1) | core drops below threshold (entry sting) | mana: 108+110 Hz pair, 2 Hz beat, 800ms | SFX | -18 dB / +-4% / C | PROC-1 (shipped) | P0 | WAV-EXISTS. FLAG: direction promotes peril to a STATE - this one-shot stays as the entry accent; the sustained peril_bed loop (group 7) carries the state. Do not redo the file. |
| victory_chord (x1) | fight won | brass: C4+E4+G4 stack + C6 bell, 1.5s | SFX-hero | -6 dB / 0% / C | PROC-1 (shipped) | P0 | WAV-EXISTS. FLAG: wiring rule only - music cuts a half-beat BEFORE it fires so the stinger lands in clean air; bench music resumes ~1.2s later. |
| loss_settle (x1) | survivable loss | wood: toks 240/185 + soft A3+C4 pad, 900ms | SFX-hero | -10 dB / 0% / C | PROC-1 (shipped) | P0 | WAV-EXISTS. FLAG: rings alone (music already out); music returns at -6 dB for ~10s after. |
| death_winddown (x1) | THE UNMAKING begins | mana: 5 drooping bells E5..D4, final glide to A 220 Hz, 895ms (decayed before t=1200 stillness) | SFX-hero | -6 dB / 0% / C | PROC-1 (shipped) | P0 | WAV-EXISTS. FLAG: the stillness gate around it must become STRUCTURAL (bus gate, ship item 2) - the file itself is already engineered for it. |
| invalid_clunk (x1) | invalid drop / refused action | wood: damped tok 150, modes 1+2 only, 120ms | SFX | -8 dB / +-4% / C | PROC-1 (shipped) | P0 | WAV-EXISTS |

Group 1 verdict: zero redos demanded by the direction. Two promotions (core_peril state, stillness gate) are new assets / new wiring, not file changes.

---

## GROUP 2 - WIRED-BUT-SILENT SEAMS (17 seams, call sites live, files missing)

### Workshop

| Asset id | Trigger | Sound (material / pitch / dur / envelope) | Bus | Vol / jitter / pan | Production | Pri | Wiring |
|---|---|---|---|---|---|---|---|
| core_wake (x1) | core seated, soul ignites (inert -> breathing) | mana: warm chord A3+C4+E4 pure sines, 150ms slow attack, C6 bell shimmer at -14 dB, 900ms felt-damped tail; the soul-hum bed (group 7) fades in under its tail | SFX | -8 dB / 0% (ritual, plays straight) / C | PROC-1 | P0 (ship order 2) | SEAM-EXISTS-NEEDS-WAV |
| snap (x2) | bit seats in a socket (the hero sound) | THE hero: 6ms plastic click transient + brass ding bell tuned A4 440 ratio 3.5 + mana shimmer sine cluster ~C7 at -16 dB lp 7k, 260ms, felt tail; 2 variants differ only in click grain | SFX-hero | -3 dB / 0% (ladder is the pitch, see SNAP LADDER) / socket side (ARM_L = L, ARM_R = R, else C) | PROC-1 | P0 (ship order 1) | SEAM-EXISTS-NEEDS-WAV |

### The Run

| Asset id | Trigger | Sound | Bus | Vol / jitter / pan | Production | Pri | Wiring |
|---|---|---|---|---|---|---|---|
| route_step (x2) | advance one node | wood+brass: low felt footfall tok 180 Hz + 2-3 tiny satchel jingle ticks 1.2-2k at -14 dB, 220ms | SFX | -10 dB / +-3% / C | PROC-1 | P0 (ship order 7) | SEAM-EXISTS-NEEDS-WAV |
| fork_reveal (x1) | junction fork panel opens | brass: soft double chime E5 then G5, 90ms apart, gentle attack, 500ms, quiet | SFX | -12 dB / +-2% / C | PROC-1 | P0 (ship order 7) | SEAM-EXISTS-NEEDS-WAV |
| switch_throw (x1) | junction commit (needle throws, 180ms motion) | brass: heavy lever - low brass thunk 260 Hz + metal tok 700 + wood rail clunk 150, 300ms, hard attack, felt stop | SFX | -6 dB / +-2% / C | PROC-1 | P0 (ship order 7) | SEAM-EXISTS-NEEDS-WAV |

### Coffer Nook

| Asset id | Trigger | Sound | Bus | Vol / jitter / pan | Production | Pri | Wiring |
|---|---|---|---|---|---|---|---|
| seal_channel (x1) | press-hold charge begins (~800ms ring) | brass+mana: accelerating ratchet ticks over 850ms + rising sine hum 220->440 at -10 dB under; ends open, cut by seal_crack or release | SFX | -8 dB / 0% (ritual) / C | PROC-1 | P0 (ship order 3) | SEAM-EXISTS-NEEDS-WAV. RITUAL duck member. |
| seal_crack (x1) | seal breaks, lid releases | brass hero: 20ms hp crack + warm G5 bell + small brass bloom, 500ms | SFX-hero | -4 dB / 0% / C | PROC-1 | P0 (ship order 3) | SEAM-EXISTS-NEEDS-WAV |
| lid_spring (x1) | lid springs open | brass: quick 2-tok flick 500->800 Hz + tiny sprung bell ratio 2.4, 250ms, playful | SFX | -10 dB / +-2% / C | PROC-1 | P0 (ship order 3) | SEAM-EXISTS-NEEDS-WAV |

### The Barrow

| Asset id | Trigger | Sound | Bus | Vol / jitter / pan | Production | Pri | Wiring |
|---|---|---|---|---|---|---|---|
| ledger_open (x1) | Barrow ledger opens | parchment: bandpass noise page slide 300ms + soft low flump, quiet | UI | -14 dB / +-5% / C | PROC-1 | P1 | SEAM-EXISTS-NEEDS-WAV |
| fettle_greet (x1) | Fettle greets on entry | brass automaton: 2 warm bell taps (C5, E5) + tiny bellows puff (lp noise), 600ms, friendly | SFX | -10 dB / +-2% / C | PROC-1 | P1 | SEAM-EXISTS-NEEDS-WAV. BARK duck member. |
| fettle_appraise (x1) | Fettle appraises a bit | brass: single mid bell G4 + short ratchet tick pair, thoughtful, 450ms | SFX | -12 dB / +-2% / C | PROC-1 | P1 | SEAM-EXISTS-NEEDS-WAV. BARK duck member. |
| fettle_apologise (x1) | warm refusal (cannot afford etc) | wood+air: descending soft tok pair E4 -> C4 + small bellows sigh, 500ms, round | SFX | -12 dB / +-2% / C | PROC-1 | P1 | SEAM-EXISTS-NEEDS-WAV + ADD TO KNOWN_SEAMS (currently unregistered - warns). BARK duck member. |
| wax_stamp (x1) | SOLD stamp lands (--stamp-thunk) | wax: lowpassed thump sine drop 180->90 + soft squish noise lp 600 80ms, 220ms, ONE thunk, zero ring | SFX-hero | -6 dB / 0% / C | PROC-1 | P0 (ship order 6) | SEAM-EXISTS-NEEDS-WAV. Direction names it a music-duck hero. |
| doorstep_untie (x1) | free daily coffer claimed | parchment+twine: 3 small bp noise pulls 2k + soft wood tok landing, 400ms | SFX | -10 dB / +-5% / C | PROC-1 | P1 | SEAM-EXISTS-NEEDS-WAV |
| forge_melt (x1) | bit melted to Scrap | ember+brass: lp noise swell 600ms + descending brass tone 330->220 + sparse crackle ticks, 800ms, warm not violent | SFX | -8 dB / +-3% / C | PROC-1 | P1 | SEAM-EXISTS-NEEDS-WAV |
| still_drip (x3) | Glimmer distilled (and doubles as Barrow ambience garnish) | glimmer/liquid: rising sine chirp 900->1400 40ms + tiny glass-edge bell 1.8k at -10 dB, 180ms; 3 f0 variants; deliberately NOT brass | SFX | -10 dB / +-6% / C | PROC-1 | P0 (ship order 6) | SEAM-EXISTS-NEEDS-WAV |
| coin_scrap (x2) | Scrap gained / spent (odometer roll) | brass filings: granular felt-damped noise ticks bp 3-5k in a little pour, 300ms; variant up = rising density (gain), variant down = falling (spend) | SFX | -12 dB / +-3% / C | PROC-1 | P0 (ship order 6) | SEAM-EXISTS-NEEDS-WAV |

---

## GROUP 3 - DESIGN.md SECTION 5 NAMED, NEVER WIRED (9 seams; ambience_workshop specced in group 5)

| Asset id | Trigger | Sound | Bus | Vol / jitter / pan | Production | Pri | Wiring |
|---|---|---|---|---|---|---|---|
| gear_tick (x3) | odometer / stat-delta roll ticks; also charge ratchet garnish | brass: single dry ratchet tick, metallic tok 900-1400 Hz, 60ms, felt stop | UI | -14 dB / +-2% / C | PROC-1 | P1 | NEEDS-SEAM-AND-WAV (named in DESIGN.md, no call site) |
| reveal_common (x1) | COMMON bit wakes in the Waking | wood: dry tok f0 330 (E4), decays [70,45,30,18], 220ms, dies fast, NO shimmer | SFX | -8 dB / +-3% / C | PROC-1 | P0 (ship order 3) | REG-NEEDS-CALLSITE-AND-WAV |
| reveal_rare (x1) | RARE kindle (cobalt ring) | glass: bell C6 1046.5 ratio 3.0 index 3.5 decay 380ms + E6 bell at -6 dB entering 60ms, 750ms, lp 7k - brighter AND longer than common | SFX | -6 dB / 0% / C | PROC-1 | P0 (ship order 3) | REG-NEEDS-CALLSITE-AND-WAV |
| reveal_epic (x1) | EPIC kindle (600ms hold + shockwave) | deep bell: G3 196 Hz big FM body decay 900ms + warm sub sine 98 at -10 dB + faux choral (4 detuned sines C4-G4, 300ms slow attack, -18 dB, lp 3k), 2.4s - LOWER and WIDER, never shrill | SFX-hero | -4 dB / 0% / C | PROC-1 | P0 (ship order 3) | REG-NEEDS-CALLSITE-AND-WAV. RITUAL duck during the 600ms hold (ambience dips, the bell owns the air). |
| new_stamp (x1) | NEW ribbon stamps a card on land | wood+brass ka-chunk: tok 400 then tok 700 40ms later + paper flap at -14 dB, 180ms, felt-damped | SFX | -10 dB / +-3% / C | PROC-1 | P1 | NEEDS-SEAM-AND-WAV |
| equip_whoosh (x1) | bit lifted from tray / socket (drag start, swap fly-back) | air: small bandpass sweep 200-900 Hz, 160ms, quiet | SFX | -14 dB / +-4% / C | PROC-1 | P1 | NEEDS-SEAM-AND-WAV |
| strain_creak (x1) | Balance tips overweight (beam tips, STRAIN tag) | wood groan: slow FM tok f0 120->150 bend over 400ms with 12 Hz AM stutter - an honest approximation of stick-slip; if it reads synthetic in playtest, falls back to SOURCE | SFX | -10 dB / +-3% / C | PROC-1 (sourcing fallback noted) | P1 | NEEDS-SEAM-AND-WAV |
| christen_chime (x1) | nameplate christened (engrave completes) | brass+glass: tiny bell pair C6+E6 over soft brass under-tone, 600ms, gentle - a small celebration, NOT hero-loud | SFX | -10 dB / 0% / C | PROC-1 | P1 | NEEDS-SEAM-AND-WAV |
| bound_chord (x1) | BIND succeeds - the Manabit is bound | brass hero: warm C4+E4+G4+C5 bloom, 120ms slow attack, C6 bell crown, 1.2s felt tail; rings in the space the ritual duck already cleared | SFX-hero | -4 dB / 0% / C | PROC-1 | P0 (ship order 4) | NEEDS-SEAM-AND-WAV |

(ambience_workshop - the tenth section-5 name - is the workshop bed composite; fully specced in group 5.)

---

## GROUP 4 - TIER-2 UNWIRED MOMENTS (new seams, named in the existing style)

| Asset id | Trigger | Sound | Bus | Vol / jitter / pan | Production | Pri | Wiring |
|---|---|---|---|---|---|---|---|
| drawer_slide (x1) | salvage drawer slides open (180ms motion) | wood-on-felt: lp noise slide 180ms + soft wooden stop tok 220 + faint card ruffle at -16 dB, 260ms | SFX | -10 dB / +-3% / C | PROC-1 | P0 (ship order 5) | NEEDS-SEAM-AND-WAV |
| drawer_tuck (x1) | drawer tucks closed | wood-on-felt: shorter slide + felt-damped clunk 180 + tiny brass bail clink at -16 dB, 220ms | SFX | -10 dB / +-3% / C | PROC-1 | P0 (ship order 5) | NEEDS-SEAM-AND-WAV |
| ink_wipe (x1) | work-order tag re-inks between states (250ms motion) | parchment: soft bp noise wipe 250ms, very quiet | UI | -16 dB / +-5% / C | PROC-1 | P1 | NEEDS-SEAM-AND-WAV |
| tag_untie (x1) | first bind - the tag unties and leaves FOREVER (400ms motion) | twine+parchment: 2 noise chirp pulls + paper slide-off + tiny felt landing, 450ms; plays exactly once per save, ever | SFX | -10 dB / 0% (one ceremonial play) / C | PROC-1 | P1 | NEEDS-SEAM-AND-WAV |
| bind_press (x1) | BIND wax press lands (seal press-hold completes) | wax: heavy soft thump sine drop 150->80 + wax squish + faint seal-ring bell at -12 dB, 300ms; the ritual duck is already holding the room | SFX | -6 dB / 0% / C | PROC-1 | P0 (ship order 4) | NEEDS-SEAM-AND-WAV. BOUND! toast makes NO sound of its own - bound_chord owns that beat (one hero per beat rule). |
| medallion_tap (x2) | socket medallion tapped (filters tray / focuses) | brass: small bell tap 880 ratio 2.5, 120ms, felt stop; hover-warm state stays silent | UI | -12 dB / +-2% / socket side | PROC-1 | P0 (ship order 5) | NEEDS-SEAM-AND-WAV |
| inspect_open (x1) | long-press inspect opens | parchment+brass: paper lift + one soft bell tick, 200ms, quiet | UI | -14 dB / +-5% / C | PROC-1 | P1 | NEEDS-SEAM-AND-WAV |
| inspect_close (x1) | inspect closes | parchment: paper settle + felt tok, 180ms | UI | -14 dB / +-5% / C | PROC-1 | P1 | NEEDS-SEAM-AND-WAV |
| ui_tap (x2) | generic UI control tap (buttons, chips, dropdowns) | wood micro: tiny tok an octave above furniture (~660-880 Hz), 60ms; the UI law: at least 10 dB under furniture, never peaks above -12 dBFS | UI | -16 dB / +-5% / C | PROC-1 | P0 (ship order 5) | NEEDS-SEAM-AND-WAV |
| screen_turn (x1) | screen transition (rides the 150-300ms ambience crossfade) | parchment: soft page turn bp noise 200ms, very quiet - the crossfade through near-silence does most of the work | UI | -16 dB / +-5% / C | PROC-1 | P1 | NEEDS-SEAM-AND-WAV |
| toast_pin (x1) | toast / banner arrives | parchment: tiny paper flick + soft tok pin, 150ms; SUPPRESSED whenever a hero sound owns the beat (EPIC!, BOUND! toasts are silent - the chord IS the toast) | UI | -14 dB / +-5% / C | PROC-1 | P1 | NEEDS-SEAM-AND-WAV |
| binding_channel (x1) | the Binding hold begins (craft a core, hold-to-bind) | mana: low hum swell 110->220 Hz with small bell shimmers accreting over ~1.1s; cut by binding_strike or release | SFX | -10 dB / 0% (ritual) / C | PROC-1 | P1 | NEEDS-SEAM-AND-WAV. RITUAL duck member. |
| binding_strike (x1) | the Binding succeeds - a core is born | mana: soft deep bell A3 + warm sine bloom + tiny shimmer, 900ms - kin to core_wake but lower and rounder (born, not woken) | SFX-hero | -6 dB / 0% / C | PROC-1 | P1 | NEEDS-SEAM-AND-WAV |
| box_crack (x1) | box of scrap cracks open | wood: 30ms hp crack + big warm crate tok 160 + 2 clatter toks, 400ms - kin to part_break but bigger, warmer, zero violence | SFX-hero | -6 dB / 0% / C | PROC-1 | P1 | NEEDS-SEAM-AND-WAV |
| grade_reveal (x3) | kit grade ribbon reveals (Dud/Rough/Fair/Keen/Gleaming) | wood-first ladder, deliberately SMALLER than the rarity ladder: low = dull damped tok 200 (Dud at pitch -2 st, Rough at 0) / mid = wood tok 330 + small chime (Fair at 0, Keen at +2 st) / high = warm bell G4 + modest brass bloom (Gleaming - warm, NOT epic-scale) | SFX | -8 dB / 0% / C | PROC-1 | P1 | NEEDS-SEAM-AND-WAV |
| ledger_fade (x1) | workshop Ledger panel fades in (160ms) | parchment: near-silent paper breath 200ms at -20 dB; honestly optional - the fade may stay silent | UI | -20 dB / +-5% / C | PROC-1 | DEFER | NEEDS-SEAM-AND-WAV |
| card_land (x2) | cards clack into the tray (Waking land beat, tray ops) | wood: tok 500-620 + felt catch, 120ms - the palette table explicitly gives wood the card-land domain; added beyond the gap list because PackOpen's land state names the clack | SFX | -10 dB / +-3% / C | PROC-1 | P1 | NEEDS-SEAM-AND-WAV |
| parts_settle (x2) | first sound AFTER the stillness beat - the unmade Manabit's parts settle | wood: 2-3 soft felt-damped toks 200-300 Hz spread over 400ms, very quiet - the ONLY sound allowed to end the stillness (direction section 4); added beyond the gap list because the stillness gate needs its exit sound | SFX | -12 dB / +-3% / C | PROC-1 | P0 (ships with the stillness gate, ship order item 2) | NEEDS-SEAM-AND-WAV |

---

## GROUP 5 - AMBIENCE BEDS + GARNISH (per direction section 4; all beds -35ish LUFS felt-not-heard, garnish max -28, garnish spacing 20-60s never rhythmic)

| Asset id | Trigger | Sound | Bus | Vol / jitter / pan | Production | Pri | Wiring |
|---|---|---|---|---|---|---|---|
| amb_workshop_air (loop) | Workshop screen (this + clock + soul_hum = the ambience_workshop composite from DESIGN.md s5) | air: lowpassed brown noise, barely there, 12s seamless loop | Ambience | bed -38 / 0% / C | PROC-LOOP | P0 (ship order item 3) | NEEDS-SEAM-AND-WAV |
| amb_clock_tick (x2) | mantel clock, runtime-scheduled ~0.8 Hz with +-60ms micro-jitter (never metronomes) | wood-brass: one soft tick, tok 700 with brass edge, 70ms; 2 variants alternate tick/tock | Ambience | -30 / +-2% / C | PROC-1 (scheduled by ambience controller) | P0 (ship order item 3) | NEEDS-SEAM-AND-WAV |
| amb_wood_settle (x2) | workshop garnish, rare | wood: one low soft settle tok 140-180 with tiny secondary, 350ms | Ambience | -28 max / +-3% / C | PROC-1 | P1 | NEEDS-SEAM-AND-WAV |
| amb_lamp_ping (x1) | workshop garnish, VERY rare (120s+) | glass: tiny filament ting bell 2.4k, 200ms, whisper | Ambience | -30 / +-2% / C | PROC-1 | P1 | NEEDS-SEAM-AND-WAV |
| amb_spool_roll (x1) | workshop garnish, rare | wood: small granular tok train (a spool rolls a few cm), 300ms | Ambience | -28 / +-3% / C | PROC-1 | P1 | NEEDS-SEAM-AND-WAV |
| (coffer nook bed) | Coffer Nook screen | NO NEW ASSET - the workshop bed reused at -6 dB (same room, held breath); mix rule only | Ambience | bed -44 / - / C | mix rule | P1 | wiring only |
| amb_coffer_shift (loop) | Coffer Nook - the coffer itself | muffled: lp granular noise + tiny tok cluster events baked sparse into a 16s loop (sleeping scrap shifts), very quiet | Ambience | -36 / 0% / C | PROC-LOOP | P1 | NEEDS-SEAM-AND-WAV |
| amb_coffer_rune (loop) | Coffer Nook - interior rune hum; volume swells with press-hold charge (runtime-driven) | mana: soft sine A3 + slow AM, 8s loop - expectancy through quiet, no riser | Ambience | -36 base, swells to -28 at full charge / 0% / C | PROC-LOOP | P1 | NEEDS-SEAM-AND-WAV |
| amb_barrow_wind (loop) | Barrow screen bed | air: low wind over canvas - filtered brown noise with slow LFO + occasional soft canvas flap, 20s loop | Ambience | bed -36 / 0% / C | PROC-LOOP | P1 | NEEDS-SEAM-AND-WAV |
| amb_cart_creak (x2) | Barrow garnish - the cart's wooden creak | wood stick-slip creak - genuinely beyond the stdlib pipeline; needs sourced/recorded audio | Ambience | -28 / +-3% / C | SOURCE | DEFER (cut list: Barrow garnish) | NEEDS-SEAM-AND-WAV |
| amb_fettle_forge (loop) | Barrow - Fettle's forge-belly (his idle presence) | bellows+ember: slow lp noise breathing at ~0.25 Hz + sparse crackle ticks, 12s loop | Ambience | -34 / 0% / C | PROC-LOOP | P1 | NEEDS-SEAM-AND-WAV |
| amb_fettle_key (x1) | Barrow garnish - Fettle's wind-up key, occasional slow ratchet | brass: slow 4-tick ratchet train, 600ms, soft | Ambience | -30 / +-2% / C | PROC-1 | DEFER (cut list: Fettle idle ratchet) | NEEDS-SEAM-AND-WAV |
| amb_melt_ember (loop) | Barrow - low warm ember wash near the Melt panel only (proximity/panel-focus volume) | ember: lp noise wash + sparse crackle, 10s loop | Ambience | -36 / 0% / C | PROC-LOOP | P1 | NEEDS-SEAM-AND-WAV |
| amb_run_wind (loop) | Run screen bed | air: low travel wind, drier than the Barrow's, 16s loop | Ambience | bed -36 / 0% / C | PROC-LOOP | P1 | NEEDS-SEAM-AND-WAV |
| amb_satchel_creak (x2) | Run garnish - leather creak between steps | leather stick-slip - beyond the pipeline; needs sourcing. Meanwhile route_step's jingle carries the satchel | Ambience | -28 / +-3% / C | SOURCE | DEFER (cut list: Run garnish) | NEEDS-SEAM-AND-WAV |
| amb_rail_hum (loop) | Run - faint rail hum, volume rises near junctions, dies on switch_throw (runtime-driven) | brass+mana: soft 110 Hz sine with 2 quiet partials, 8s loop | Ambience | -38 base, -32 near junction / 0% / C | PROC-LOOP | P1 | NEEDS-SEAM-AND-WAV |
| (combat bed) | Combat screens | NO ASSET - the boldest call: combat room tone is the two core hums (group 7) plus felt-silence. No crowd, ever. | Ambience | - | wiring only | P0 | wiring only |

Node-modifier ambience tints (overgrown leaves, rusted dry creaks): DEFER per the cut list - no assets enumerated until the tier is funded.

---

## GROUP 6 - THE WOUND SPRING (music; authored note-data, C major / A minor ONLY, rendered offline to OGG stems; 8-16 bar motifs, phrase-rest-phrase sparse; ~72 BPM suggested)

Stem-mix adaptation is LIVE remixing of ONE motif's stems (bench = full quartet, shop = bells+pad, run = pulse+melody, combat = pulse only, death = hard stop) - so the P0 bench motif alone covers every screen for the playtest. The deferred motifs are distinct compositions per screen, the named post-playtest upgrade path.

| Asset id | Trigger | Sound | Bus | Vol / jitter / pan | Production | Pri | Wiring |
|---|---|---|---|---|---|---|---|
| ws_bench_melody (loop stem) | Workshop bench music (motif 1 of 4 stems) | music-box tines: bell() bright, lead phrase in C major, 12 bars with baked rests (~40s loop), lp 7k | Music | -22 LUFS bus / 0% / C | STEMS | P0 (ship order item 4) | NEEDS-SEAM-AND-WAV (new music player, not Sfx pool) |
| ws_bench_bells (loop stem) | same motif, answer line | tines an octave up, sparser counter-phrases in the melody's rests | Music | rides bus / 0% / C | STEMS | P0 | NEEDS-SEAM-AND-WAV |
| ws_bench_pad (loop stem) | same motif, floor | brass() soft sustained I-vi-IV-V colors, lowpassed, -10 dB under the tines | Music | rides bus / 0% / C | STEMS | P0 | NEEDS-SEAM-AND-WAV |
| ws_bench_pulse (loop stem) | same motif, heartbeat | low felt-damped toks on A2/E3 at phrase downbeats - the stem that survives into combat | Music | rides bus / 0% / C | STEMS | P0 | NEEDS-SEAM-AND-WAV |
| ws_shop_* (x4 stems) | Barrow motif (deferred variant) | same quartet voicing, a slightly more mercantile lilt; stays in key | Music | - | STEMS | DEFER (cut list) | NEEDS-SEAM-AND-WAV |
| ws_run_* (x4 stems) | Run motif (deferred variant) | pulse-forward walking phrase; stays in key | Music | - | STEMS | DEFER (cut list) | NEEDS-SEAM-AND-WAV |
| ws_nook_* (x4 stems) | Coffer Nook motif (deferred variant) | quietest of the four; mostly bells+pad; stays in key | Music | - | STEMS | DEFER (cut list) | NEEDS-SEAM-AND-WAV |

Music wiring rules (restated for the implementer): melody stem mutes in peril; music hard-stops at THE UNMAKING and does not return on the death screen; workshop reopens with ambience only for ~10s after a death; music cuts a half-beat before victory_chord; music does not play during the Waking's kindle sequence (the reveal ladder is the music there).

---

## GROUP 7 - STATE SOUNDS (sustained, runtime-driven)

| Asset id | Trigger | Sound | Bus | Vol / jitter / pan | Production | Pri | Wiring |
|---|---|---|---|---|---|---|---|
| soul_hum (loop) | seated AWAKE core in the Workshop - the one living sound in the room | mana: sine A2 110 + partial A3 at -8 dB, slow AM breathing baked at 0.5 Hz (the 2s --invite-breath cycle), 8s loop (4 breaths); runtime phase-locks its start offset to the shared engine clock so hum, visual sleep-breath, and cavity heartbeat breathe together | Ambience | -30 / 0% / C | PROC-LOOP | P0 (ship order item 3) | NEEDS-SEAM-AND-WAV |
| (soul_hum dormant) | no core seated | NO ASSET - the dormant state is the ABSENCE of the hum (800ms release on unseat); the room is noticeably emptier before the player can name why. Deliberate silence, wiring only | - | - | wiring only | P0 | wiring only |
| core_hum (loop, played x2) | combat - each living core hums; the entire combat room tone | mana: sine 110 + 2 soft partials, 6s loop; ONE file, two players: yours at pitch 1.0 panned slightly L, theirs at pitch 1.01 (slight detune - two souls, not one) panned slightly R; each instance's volume follows its core's HP fraction and dies with its core | Ambience | -32 each / 0% (detune is fixed, not jitter) / L and R | PROC-LOOP | P0 (ship order item 3) | NEEDS-SEAM-AND-WAV |
| peril_bed (loop) | your core below peril threshold (state, promoted from the core_peril one-shot) | mana: sustained 108+110 Hz beating pair (2 Hz beat = the score now), 4s loop; 200ms attack on entry, ~1s release on mend/kill; the beat phase-locks to the visual heartbeat clock; while active: music melody stem muted, Ambience ducked -6 dB | Ambience | -26 / 0% / C | PROC-LOOP | P0 | NEEDS-SEAM-AND-WAV |

---

## THE SNAP RARITY PITCH LADDER (concrete)

Base snap file is tuned so the brass-ding fundamental = A4 (440 Hz). Ladder applied via pitch_scale at the call site, no extra files:

| Rarity | Semitones | pitch_scale | Resulting ding |
|---|---|---|---|
| COMMON | +0 | 1.0000 | A4 (440) |
| RARE | +3 | 1.1892 | C5 (523) |
| EPIC | +7 | 1.4983 | E5 (659) |

Why +0/+3/+7: A-C-E is the A minor home triad, so every snap ladder arpeggiates the game's key (the KEY LAW) and any snap heard against music lands in tune. The ladder rises without going shrill - E5 keeps the EPIC ding well under the 7 kHz shimmer ceiling. Snap takes ZERO humanize jitter; the ladder pitch IS the information.

## THE REVEAL LADDER (three sounds, ascending in SHIMMER and SIZE, not just pitch)

1. reveal_common - dry wood-tok, f0 330 Hz (E4), decays [70,45,30,18]ms, 220ms total, no shimmer. Dies fast: common is honest.
2. reveal_rare - glass-cobalt chime: bell C6 ratio 3.0 index 3.5, 380ms amp decay, second bell E6 at -6 dB entering at 60ms, 750ms, lp 7k. Brighter AND longer.
3. reveal_epic - deep bell: G3 fundamental (196 Hz), big FM body, 900ms decay, warm 98 Hz sub sine at -10 dB, faux choral of 4 detuned sines C4-G4 with 300ms slow attack at -18 dB (lp 3k), 2.4s total. Epic goes DOWN and WIDE, never up and shrill - that is the anti-casino geometry.

The kit grade_reveal ladder is the same shape one size smaller (dull tok / tok+chime / warm bell) so the two ladders rhyme without competing.

## PER-CATEGORY DEFAULT PITCH-JITTER RANGES

| Category | Jitter | Members (examples) |
|---|---|---|
| Combat foley | +-4% (existing, keep) | hit, hit_core, part_break, attack_whoosh, guard_up, mend |
| Wood furniture | +-3% | drawer_slide/tuck, card_land, route_step, new_stamp, parts_settle, amb garnish toks |
| Brass mechanism | +-2% | switch_throw, gear_tick, medallion_tap, lid_spring, fettle_greet/appraise, amb_clock_tick |
| Parchment / paper | +-5% | ledger_open, ink_wipe, inspect_open/close, toast_pin, screen_turn, doorstep_untie |
| UI micro | +-5% | ui_tap |
| Liquid / glimmer | +-6% | still_drip |
| Hero + ritual + outcome | 0% - plays straight | snap, seal_crack, seal_channel, reveal ladder, bound_chord, bind_press, wax_stamp, binding_*, box_crack, core_wake, tag_untie, christen_chime, victory_chord, loss_settle, death_winddown |
| Loops / stems / state | 0% | all ambience beds, all music stems, soul_hum, core_hum (fixed 1.01 detune is not jitter), peril_bed |

## DUCKING GROUP MEMBERSHIP (the four relationships + the existing SfxBig tier)

1. HERO -> Music duck -6 dB (50ms attack / 400ms release, bus tween): snap, seal_crack, reveal_epic, bound_chord, victory_chord, wax_stamp, binding_strike, box_crack. (All also route SfxBig, so they inherit the existing Sfx -4 dB ref-counted duck.)
2. SfxBig-only members (duck Sfx -4 dB, existing behavior, no Music duck needed beyond rule 1): hit_core, part_break, loss_settle, death_winddown.
3. BARK -> Music duck -4 dB while the ribbon shows: fettle_greet, fettle_appraise, fettle_apologise.
4. RITUAL -> Music AND Ambience -6 dB held for the whole window, released on completion or cancel: seal_channel window, bind_press hold, binding_channel, the reveal_epic 600ms hold.
5. PERIL (state) -> Music melody stem MUTED + Ambience -6 dB while peril_bed is active; ~1s release.
6. STILLNESS GATE (master) -> THE UNMAKING: everything except the death channel to silence - Music hard-stop (hand lifted, not a fade), Ambience muted, UI refused, both core_hum instances gone; held through the parts-release + stillness beat (minimum 1.5s, gated by the beat system, never a timer race); released only by parts_settle, which is the first sound allowed back.

Bus reality note: ui/sfx.gd today builds Sfx/SfxBig (+ pan sub-buses). The direction's Master > Music / Ambience / SFX / UI layout means adding Music, Ambience, and UI buses and treating SfxBig as the hero tier inside SFX. That is the technical-artist lane's build; every row above declares its target bus so the mapping is mechanical.

---

## TOTALS

Files (one wav/ogg = one file; variants counted individually):

| Tier | Existing | New | Total |
|---|---|---|---|
| P0 (playtest-ship) | 14 | 39 | 53 |
| P1 (post-playtest) | 0 | 38 | 38 |
| DEFER (cut list) | 0 | 18 | 18 |
| TOTAL | 14 | 95 | 109 |

By production method (new files only):

| Method | Files | Notes |
|---|---|---|
| PROC-1 (procedural one-shot, make_sfx.py) | 64 | the pipeline's home turf |
| PROC-LOOP (procedural seamless loop) | 11 | 8 ambience beds + 3 state hums; new loop-render support in the pipeline |
| STEMS (authored note-data, offline render) | 16 | 4 bench (P0) + 12 deferred motif variants |
| SOURCE (cannot honestly synthesize) | 4 | amb_cart_creak x2 + amb_satchel_creak x2 - stick-slip creaks; ALL are DEFER tier, so the playtest ships 100% from the pipeline with zero sourcing |

Other headline numbers:
- Seams: 30 registered today (11 with files, 19 silent incl. the unregistered fettle_apologise); this spec adds 27 new seam/asset ids (groups 3-5 garnish + group 4 + group 7) plus 3 ambience-controller loop ids and the music stem player - about 65 addressable audio ids at full build-out.
- P0 build order (direction section 7, restated over these assets): 1) snap -> core_wake -> coffer set (seal_channel, seal_crack, lid_spring, reveal x3) -> BIND set (bind_press, bound_chord) -> drawer_slide/tuck + medallion_tap + ui_tap -> barrow transactions (wax_stamp, coin_scrap, still_drip) -> run set (switch_throw, route_step, fork_reveal); 2) buses + stillness gate + parts_settle + the four duckings + LUFS pass; 3) amb_workshop_air + amb_clock_tick + soul_hum (with its dormant absence) + core_hum + peril_bed; 4) the four ws_bench stems.
- Deliberate no-asset rows (protected silences and mix rules, all wiring): soul-hum dormant absence, combat bed, coffer nook bed reuse, BOUND!/EPIC! toast silence, death-screen music absence, the stillness window itself.

---

# SECTION 3 - ACCESSIBILITY REQUIREMENTS (accessibility lane)

## Requirements

- R1 PERIL-VIS (the one hard requirement): peril_bed may not ship without a SUSTAINED visual twin. Today's core-peril visuals are telegraph-beat-scoped (combat_screen.gd _beat_telegraph: log line + core-row brighten + vignette for JT_TELEGRAPH_MS only) and the vignette is dropped entirely under reduce-motion. When peril becomes a state, hold the existing edge vignette at low alpha (or pulse the core HP row) for the whole below-threshold window, phase-locked to the same 2 Hz clock as the bed; reduce-motion variant = static tinted edges or a steady PERIL chip on the core row - never nothing. This also creates the combat-side heartbeat clock the direction says the bed phase-locks to (the only such clock today is the Workshop --invite-breath).
- R2 PERIL-BEAT: make explicit in the spec that peril_bed's beat is FIXED at 2 Hz and its level capped at -26 - it never accelerates or rises as HP drops (nothing in the spec says it does, but nothing forbids it; escalating pulses are the classic anxiety device the direction's subtraction principle exists to avoid). Carriers stay 108+110 Hz (low-frequency, confirmed), release ~1s as specced.
- R3 CAPTION DISCIPLINE (if the owner adds a captions toggle): caption the MEANING, not onomatopoeia; cozy register; ONE caption per beat (mirror the one-hero-per-beat rule); sustained states get a persistent indicator chip, not repeating text; inside the stillness window suppress ALL captions except a single '[stillness]' card, then '[parts settle softly]'. Fettle barks need no captions - BarkRibbon text already IS their caption.
- R4 CAPTION LIST (deserve captions): core_wake '[a soft chord - the core wakes]'; snap '[snap - the bit seats]'; hit_core '[a deep knock - the core is struck]'; part_break '[crack - a part breaks away]'; guard_up '[a bell swish - guard raised]'; mend '[a rising arpeggio - mended]'; core_peril entry + peril_bed state chip '[a low beating hum - the core is in peril]'; victory_chord '[a warm chord - victory]'; loss_settle '[soft wood settles - the bout is lost]'; death_winddown '[five falling bells]' then '[stillness]' then parts_settle '[parts settle softly]'; invalid_clunk '[a dull clunk - that does not fit]'; seal_crack '[the seal cracks]'; reveal_common '[a dry wood tok]' / reveal_rare '[a glass chime]' / reveal_epic '[a deep bell swells]'; bound_chord '[a warm chord - bound]'; binding_strike '[a deep bell - a core is born]'; wax_stamp '[thunk - sold]'; box_crack '[the crate cracks open]'; strain_creak '[wood creaks - overweight]'; switch_throw '[the lever throws]'; christen_chime '[a small chime - christened]'; soul_hum on wake '[a soft hum breathes]' and on unseat '[the hum fades]'.
- R5 NO-CAPTION LIST (pure texture): ui_tap, medallion_tap, gear_tick, equip_whoosh, drawer_slide/tuck, ink_wipe, tag_untie, inspect_open/close, screen_turn, toast_pin, ledger_open/fade, new_stamp, card_land, route_step, fork_reveal, seal_channel (charge ring is visible), lid_spring, coin_scrap, still_drip, doorstep_untie, forge_melt, attack_whoosh, hit (the damage number is the caption), all ambience beds and garnish, all music stems, core_hum, amb_rail_hum.
- R6 PLAYTEST CONTROL = BUS SLIDERS, TOGGLE DEFERRED: do not build a bespoke reduce-audio-intensity toggle for the playtest. The four buses (Music / Ambience / SFX / UI) already exist in the plan - expose four volume sliders + master in settings; that is the practical accessibility control (a sensitive player can pull Ambience down to kill the peril bed and SFX down to soften transients). Defer the dedicated toggle to post-playtest.
- R7 TOGGLE SCOPE (post-playtest, if built): reduce-audio-intensity would soften, in priority order: peril_bed (swap to a steady non-beating hum, -6 further), the hp-crack transients (seal_crack 20ms, box_crack 30ms, part_break crack, snap's 6ms click - lowpass the click component), switch_throw's hard attack, wax_stamp + bind_press thumps, hit_core's knock, and seal_channel's accelerating ratchet (constant-rate variant - it is the plan's only accelerating pulse, acceptable today because quiet and player-held).
- R8 GUARANTEES, NOT JUST STYLE: promote three direction laws to accessibility guarantees in the spec - the 7 kHz shimmer ceiling, the -12 dBFS UI peak law, and the no-risers/no-braams ban. They are load-bearing for auditory sensitivity, so a future 'juice pass' may not waive them.
- R9 STILLNESS GATE SAFETY: UI sound refusal during the stillness window is safe ONLY because visual press states persist - add one line requiring that no control becomes visually unresponsive while the gate is closed.
- R10 REDUNDANCY RULE (blanket): every information-bearing ladder is reinforcement, never the sole channel - snap rarity pitch ladder rides the card frame/rune-rim, the reveal ladder rides RarityBurst tiers + banner, grade_reveal rides the grade ribbon + stat sheet, core_hum's HP-following volume rides the persistent HP rows, coin_scrap up/down rides the odometer + floating deltas. State this once in the spec header so no future seam gates a decision on hearing alone.
- R11 KEEP (already correct, no action): soul_hum dormant absence has full visual twins (ember-dimmed lamp ~0.55 key, soul off, half-amplitude sleep breath vs awake breathing idle + soul OmniLight, plus the empty CORE socket ghost + amber ! pip); amb_rail_hum junction proximity is visible on the RouteBed map (and the hum is P1 anyway); fettle_apologise's refusal meaning is carried by BarkRibbon text + the apologise() reaction, its KNOWN_SEAMS registration is bookkeeping already flagged in the spec.

## Gaps found

- PERIL BED - the only information gap in the plan: promoting core_peril to a sustained state creates a sustained audio signal whose visual twins are all momentary (telegraph-scoped vignette + one-shot row brighten) or static (the HP row number); under reduce-motion the vignette is dropped entirely (combat_screen.gd line 613), so a deaf or reduce-motion player loses the sustained 'in peril' salience the bed carries. Requires R1 before peril_bed ships.
- The 'visual heartbeat clock' the direction phase-locks peril_bed to does not exist in combat - only the Workshop --invite-breath cavity heartbeat exists. The combat-side clock must be built as part of R1.
- peril_bed spec does not forbid beat-rate or level escalation with falling HP - unstated, so an implementer could add it; R2 closes this.
- seal_channel's accelerating ratchet is the plan's only accelerating pulse (riser-adjacent device); acceptable as designed (quiet, -8 dB, 850ms, player-initiated hold) but flagged for the R7 toggle scope.
- No visual-alone inverses found (BOUND!/EPIC! toasts are silent but visible - correct direction of redundancy).

## Verdict

PASS WITH ONE REQUIRED ADDITION (R1 peril sustained visual + reduce-motion-safe variant). Full visual-twin verification against code and DESIGN.md: every gameplay-critical sound has an existing visual twin - hit -> floating damage numbers + part punch; hit_core -> core-row pulse + impact star + once-per-turn affinity core flash; part_break -> detach_part tumble + hex ring + pane flash + BROKEN! burst; attack_whoosh -> lunge/windup; guard_up -> dome-in burst; mend -> HP rows rise; core_peril one-shot -> 'lunges for your core!' log line + core-row brighten (survives reduce-motion) + vignette; victory/loss/death stingers -> outcome screens + THE UNMAKING sequence; invalid_clunk -> reject shake + barred ring; snap -> SnapFX spark-ring/pop/socket flare; core_wake -> inert-to-breathing + soul OmniLight; seal_channel -> charge ring; seal_crack -> bounded flash + lid spring; reveals -> RarityBurst tiers + EPIC banner/hold; bind_press/bound_chord -> wax press + BOUND! toast; wax_stamp -> SOLD stamp; coin_scrap/still_drip -> odometer + floating deltas; switch_throw -> 180ms needle; route_step -> node advance; strain_creak -> beam tips + STRAIN tag + hatched overflow. The four suspect state sounds check out three-for-four: soul-hum dormant/awake difference has full visual twins (dormant dressing spec), core_hum's dying-with-HP volume rides the persistent per-part HP rows, junction rail hum rides the visible RouteBed junction; the peril bed is the single partial twin and is gated by R1. Auditory-sensitivity review: the plan is unusually sensitivity-friendly by construction (danger = subtraction so tension never gets louder, 7 kHz shimmer ceiling, rounded transients, -1 dBTP ceiling, UI -12 dBFS law, no risers/braams, all crack transients player-initiated); the 2 Hz peril beat is confirmed low-frequency (108+110 Hz carriers) and low-level (-18 dB one-shot, -26 bed) and stays sanctioned with R2's never-accelerate rule; recommend shipping the four bus volume sliders as the playtest accessibility control and deferring a dedicated reduce-audio-intensity toggle (R6/R7). With R1 merged, no gameplay state anywhere in the plan is communicated by audio alone.

---

# SECTION 4 - TECHNICAL PLAN (verbatim, audio-tech-plan.md)

# MANABIT AUDIO TECHNICAL PLAN v1
Technical Artist + Godot Specialist lane. Design only - nothing here is written into the project.
Obeys audio-direction-v1.md (owner-signed 2026-07-19). Validated against Godot 4.7 stable
(interactive-music streams landed in 4.3 and are present and stable in 4.7).

Grounded in code as it exists today: ui/sfx.gd (static RefCounted, 8-voice pool, code-created
buses Sfx/SfxBig + panner sub-buses, ref-counted -4 dB duck, headless-inert), tools/audio/
make_sfx.py (stdlib synthesis, seed 7, -3 dBFS peak norm, 44100/16/mono WAV), tests/
smoke_audio.gd (stage A seam canon + stage B wav parse, never plays audio).

Design principles carried through every section:
- SINGLE WRITER: exactly two files may ever call AudioServer.set_bus_volume_db or
  set_bus_mute - ui/sfx.gd (its internal Sfx duck only) and the new ui/audio_director.gd.
  Everything else asks AudioDirector. This is grep-testable and the smoke gate enforces it.
- THREE ORTHOGONAL CONTROLS per category, never fighting: user volume = volume_db on the
  category bus (sliders), ducking = volume_db on a dedicated child duck bus (tweens), the
  stillness gate = the bus MUTE FLAG (boolean, instant, restores exactly). No composition
  math, no writer conflicts, no race.
- HEADLESS-INERT everywhere: every new module copies Sfx's exact pattern
  (DisplayServer.get_name() == "headless" checked once, then permanent no-op; no buses, no
  players, no nodes are ever created headless). Gates stay green untouched.
- Sfx.play(seam, pitch, pan) keeps its exact signature and no-op contract. All existing call
  sites compile untouched.

---

## 1. BUS ARCHITECTURE AND THE Sfx MIGRATION

### 1.1 Target bus tree (all code-created, no default_bus_layout.tres - same as today)

    Master
      Music            <- settings slider MUSIC; gate mute target
        MusicDuck      <- duck tween target; the stem player lives here
      Ambience         <- settings slider AMBIENCE; gate mute target
        AmbDuck        <- duck tween target; bed / hum / peril players live here
      SFX              <- settings slider SFX
        Sfx            <- existing; internal SfxBig->Sfx -4 dB duck target (unchanged)
          SfxPanL / SfxPanR          (existing panner sub-buses, unchanged)
        SfxBig         <- hero + outcome punctuation; the DEATH CHANNEL - never gate-muted
          SfxBigPanL / SfxBigPanR    (existing, unchanged)
        Ui             <- UI micro seams; gate mute target; rides the SFX slider for free

Why this shape and not "four flat buses under Master": the direction's mix table wants
Master > Music / Ambience / SFX / UI, and this tree honors it (Ui is a child of SFX purely so
the SFX slider covers taps without a fifth slider; it is still an independently mutable,
independently duckable bus, which is what the direction actually needs from "UI bus").
The Duck child buses exist so a duck tween never writes the same volume_db a slider owns.

### 1.2 Migration shape (keeps Sfx's API and inertness)

- ui/audio_director.gd (new, static RefCounted, mirrors sfx.gd house style): owns
  ensure_buses() with a declarative BUSES table (name, parent, trim_db, panner). Creation
  order = parents first (a bus send target must exist when set - same rule the current
  _make_bus already respects implicitly). Idempotent: get_bus_index(name) != -1 skips.
- ui/sfx.gd edits (surgical): _ensure_buses() delegates to AudioDirector.ensure_buses();
  the BUSES table re-parents Sfx and SfxBig to send to "SFX" instead of "Master". Nothing
  else in sfx.gd changes for the migration itself. Because buses are code-created fresh
  every run, re-parenting is a one-line table change, not a data migration.
- MANIFEST grows "bus": "Ui" entries for UI micro seams (taps, drawer, toasts). The pan
  quantize suffix logic stays; Ui seams simply never pass pan so no Ui panner buses needed.
- Sfx's internal ref-counted -4 dB duck keeps targeting the "Sfx" bus exactly as today.

### 1.3 Settings sliders (queued milestone) - where they attach

- Four sliders: MASTER, MUSIC, AMBIENCE, SFX. They call
  AudioDirector.set_user_volume(&"Master" | &"Music" | &"Ambience" | &"SFX", frac).
- Mapping: frac 0.0 = set_bus_mute(true) on that bus; else volume_db =
  linear_to_db(pow(frac, 1.5)) clamped to [-38.0, 0.0] (perceptual taper, no -80 crawl).
  NOTE the gate also uses mute flags - so slider mute state is remembered by AudioDirector
  (a per-bus user_muted flag) and gate release restores mute = user_muted, not blindly false.
- Persistence: a small settings dict in the SaveManager blob (additive, schema-safe);
  AudioDirector.apply_user_volumes() runs on first ensure() from the first UI frame - never
  headless, so save-load gates stay inert.

---

## 2. THE STILLNESS GATE AS A STRUCTURAL MECHANISM

The direction's law: at THE UNMAKING, music hard-stops (a hand lifted off, not a fade),
ambience mutes, UI sounds are REFUSED, both core hums are gone, held through the stillness
beat (min 1.5 s), released only by the parts-settle beat - never a timer race, and a stray
UI tap must not be able to poke a hole in it.

Mechanism (in AudioDirector, pure-logic core kept testable headless):

- Claim stack: gate_claim(token: StringName, priority: int) pushes {token, priority,
  t_claim}. gate_release(token) removes ONLY a matching token - a stray release from another
  system cannot open the UNMAKING's gate. Highest surviving priority rules. UNMAKING claims
  at priority 100 with token &"unmaking"; the API is generic so a future cutscene can claim
  lower without touching the mechanism.
- On first claim (stack empty -> active):
  1. Kill every live duck tween AudioDirector owns and clear duck refcounts to a frozen
     snapshot (prevents the one real race: a release tween started pre-claim restoring
     Music volume mid-stillness). Single-writer is what makes "kill every tween" possible.
  2. set_bus_mute(true) on Music, Ambience, Ui (instant - the hand lifted off).
  3. Music.stop_hard() (the player stops; music must not resume mid-phrase on release).
  4. Amb.set_combat_hums_active(false) (both core hums die with the gate, not with a fade).
  SfxBig is NOT muted - it is the death channel; death_winddown is already ringing on it.
- While active: Sfx.play() consults AudioDirector.gate_allows(seam) BEFORE the manifest
  lookup. Allowlist: GATE_ALLOW = [&"death_winddown", &"part_settle", &"loss_settle"].
  Everything else returns silently (one debug push_warning per seam, reusing _warn_once).
  This is synchronous and in the same call that would have played the sound - there is no
  frame gap for a tap to slip through. Muting Ui as well (step 2) also silences any tap
  TAIL that started just before the claim - belt and braces.
- Release: the combat beat planner calls gate_release(&"unmaking") on the parts-settle
  beat. AudioDirector enforces the floor structurally: effective open time =
  max(release_time, t_claim + 1500 ms). If the beat system releases early (a reduce-motion
  shortened timeline, say), the gate defers the open via a scene-tree timer on the pool
  node. The beat system remains the OWNER of release; the 1.5 s is a floor, not the driver.
- On open: restore mute flags to user_muted values, duck state recomputes from live
  refcounts (which are all zero post-combat), music does NOT auto-resume (direction: the
  Workshop reopens with ambience only for ~10 s - that timing belongs to the workshop
  screen calling Music.set_state, not to the gate).

Testable headless because the claim stack + allowlist + floor arithmetic live in static
functions over injected timestamps, with the AudioServer writes behind the inert check.

---

## 3. THE FOUR DUCKING RELATIONSHIPS AS DETERMINISTIC BUS TWEENS

Ownership rule: AudioDirector owns exactly ONE tween per duck bus (MusicDuck, AmbDuck).
Sfx keeps its one internal tween for the Sfx bus. No other tweens touch bus volumes, ever.

Duck model (generalizes Sfx's proven ref-counted pattern):

    DUCK_RULES = {
      &"hero":   {target = MusicDuck, depth = -6.0, attack_ms = 50,  release_ms = 400, timed_hold_ms = 250},
      &"peril":  {targets = [AmbDuck], depth = -6.0, attack_ms = 120, release_ms = 1000, state_held = true},
      &"ritual": {targets = [MusicDuck, AmbDuck], depth = -6.0, attack_ms = 80, release_ms = 400, state_held = true},
    }

- Relationship 1 (hero SFX duck music): triggered INSIDE Sfx.play() when the seam is in a
  new HERO_SEAMS set (&"snap", &"seal_crack", &"reveal_epic", &"wax_stamp", &"bound_chord",
  &"victory_chord", &"hit_core", &"part_break"). Timed: claim on play, auto-release after
  timed_hold_ms via the pool's scene-tree timer, ref-counted so flurries and MULTI break
  chains never stick the bus (the exact bug Sfx's refcount already solves - reuse the
  pattern verbatim: increment on claim, only the LAST release starts the recovery tween).
- Relationship 2 (peril empties the room): state-held. Combat calls
  AudioDirector.duck_claim(&"peril", token) on entering the peril state and duck_release on
  mend/kill. The melody-stem mute half of this relationship is NOT a bus duck - it is a
  stem target change inside Music (section 4) so it stays sample-locked and slider-safe.
- Relationship 3 (ritual held breath): state-held claims keyed by token (&"seal_channel",
  &"bind_hold", &"epic_hold") so overlapping rituals compose correctly.
- Relationship 4 is the gate (section 2), deliberately NOT a duck - different mechanism,
  different control (mute flag), different priority semantics.
- Compositing when rules overlap on one bus: DEEPEST WINS (min dB), never summed - two -6
  claims give -6, deterministic and safe. On any refcount change AudioDirector kills the
  bus's tween and retweens from the current volume toward the new deepest target at that
  rule's attack (deepening) or release (recovering) rate. tween_method stepping volume_db
  at frame rate = effectively ramped by the mixer per block; no zipper in practice.

---

## 4. MUSIC STEM PLAYBACK - The Wound Spring

### 4.1 What Godot 4.7 actually offers, and the pick

Options weighed:
- Four AudioStreamPlayers started the same frame on four sub-buses: REJECTED as primary.
  play() calls map onto mix blocks; under thread timing two players can land one mix block
  apart (~11 ms at 512 frames / 44.1 kHz) and stay offset forever; correcting via seek pops.
- AudioStreamInteractive: a clip-transition state machine - overkill for v1 (one bench loop,
  volume-thinned states). It is the named UPGRADE PATH for Candidate C bar-quantized
  bench-to-combat transitions; do not build against it now.
- AudioStreamSynchronized (4.3+, present in 4.7): one AudioStreamPlayer, one stream
  resource holding up to 32 member streams mixed SAMPLE-LOCKED inside a single playback
  instance, per-stem volume via set_sync_stream_volume(idx, db). CHOSEN. Sync is by
  construction, not by scheduling - the whole race class disappears.

Consequence honestly flagged: the direction says "stems mixed live on Godot buses". With
AudioStreamSynchronized all stems exit ONE player into MusicDuck; stem-level mix happens via
the stream's per-stem volumes (tweened by Music with a tween_method at frame rate), and
WHOLE-music ducking/slider/gate still happen on the bus exactly as directed. Same audible
result, sample-locked, one fewer failure mode. This is the one place the plan deviates from
the direction's letter to honor its intent.

### 4.2 Stem assets and loop points

- Stems: melody / bells / pad / pulse, rendered by make_sfx.py (extended) as 44100/16/mono
  WAV, all EXACTLY the same frame count. Author the loop at 80 BPM 4/4 so a beat = 0.75 s
  exactly: 16 bars = 48.000 s = 2,116,800 samples, integer, loop-clean. (Any BPM whose beat
  is an integer sample count works; 80 is inside the music-box tempo pocket and makes the
  victory half-beat a tidy 375 ms.)
- Format: the direction says OGG for music/ambience, but the pipeline is Python stdlib and
  the stdlib has NO OGG encoder - shipping OGG breaks the zero-install, byte-reproducible
  law. RESOLUTION: keep WAV out of the generator, import as AudioStreamWAV with
  compress/mode = QOA (Quite OK Audio, 4.3+, ~3.2 bits/sample, cheap decode, web-safe).
  48 s mono: 4.23 MB PCM -> ~0.85 MB QOA per stem. The .import overrides are one-time,
  checked in. Loop points: make_sfx.py writes a standard smpl chunk (pure struct.pack,
  byte-reproducible) with loop 0 -> end; Godot's WAV importer's "Detect From WAV" honors it.
  FALLBACK if QOA misbehaves on any target: plain PCM WAV (17 MB music - fat but works), or
  accept a single external encoder dependency (ffmpeg) and go OGG as directed.
- The four stems live in one AudioStreamSynchronized resource built IN CODE by Music at
  first use (no .tres to maintain, matches the code-created-bus house style).

### 4.3 Music module and the thinning table

ui/music_box.gd (new, static class Music, Sfx's lazy-node + inert pattern; player on
MusicDuck). API: set_state(state), stop_hard(), is_playing().

    STEM_TARGETS (dB; -60 = musically off)        melody  bells  pad   pulse
    BENCH   (workshop, full quartet)                 0      0     0     0
    SHOP    (barrow)                               -60      0     0   -60
    RUN     (route)                                  0    -60   -60     0
    COMBAT  (ordinary exchanges)                   -60*   -60   -60     0
    COMBAT_TENSE (elite / boss / core exposed)     -60    -60   -60     0
    WAKING  (kindle sequence - reveal ladder owns the air)  all -60, player keeps running
    SILENT  (post-death mourning, pre-first-input on web)   player stopped

    * COMBAT allows occasional melody fragments: Music.allow_fragment() opens the melody
      stem to 0 dB for one 2-bar window starting at the next bar boundary (position known
      exactly: get_playback_position() vs the 2.25 s bar length), then closes it. Never
      random-timed - bar-quantized, deterministic from the call.

- Transitions tween each stem over 800 ms (musical, not abrupt) - EXCEPT stop_hard() and
  the gate, which are instant.
- Peril overlay (relationship 2): Music.set_peril(true) forces melody to -60 regardless of
  state until released - implemented as a max-mute overlay on the target table, so state
  changes during peril cannot resurrect the melody.
- Victory timing: combat's beat planner calls Music.stop_hard(), schedules
  Sfx.play(&"victory_chord") 375 ms later (the half-beat), then Music.set_state(BENCH)
  after ~1.2 s. Orchestration belongs to the beat planner; Music just obeys.
- WAKING keeps the player RUNNING with all stems at -60 rather than stopping - so music
  re-enters at the right bar, still sample-locked, when the kindle ends.

---

## 5. PHASE-LOCKED SOUL-HUM AND PERIL-BED

The law: the workshop soul-hum breathes in phase with the visual sleep-breath, and the peril
bed's 2 Hz pulse locks to the visual heartbeat. The existing visual code samples
Time.get_ticks_msec() with fixed formulas (slot_field.gd invite ring: 2 s period;
manabit_stage.gd breath). Audio must sample the SAME clock with the SAME formula.

Chosen implementation: CODE-SIDE AMPLITUDE MODULATION, not baked beats.

- ui/ambience.gd (new, static class Amb, same lazy-node + inert pattern; players on
  AmbDuck). Loop players it owns: screen bed, clock garnish scheduler, soul hum, combat hum
  pair, peril bed.
- Soul hum: a steady 4.0 s seamless hum loop (constant amplitude in the FILE). Amb's pool
  node runs _process and writes the PLAYER's volume_db (player volume, not bus - so it
  never collides with AudioDirector's bus ownership):
      volume_db = base_db + depth_db * sin(float(Time.get_ticks_msec()) / 1000.0 * TAU / 2.0)
  Identical formula to the invite ring = phase-locked by construction, zero drift forever,
  because the modulation is evaluated on the shared engine clock every frame instead of
  depending on when a baked file started. Dormant stage: hum player stopped entirely (the
  direction's "noticeably emptier", not just quieter).
- Peril bed: bake a 1.000 s loop of the 108 + 110 Hz pair (both complete integer cycles in
  exactly 44100 samples - loop is sample-perfect) BUT at constant blended amplitude, and
  apply the 2 Hz pulse as AM from the shared clock (same _process, 2 Hz formula shared with
  the visual heartbeat). The two-sine timbre keeps the "beating soul" character; the AM
  enforces the phase. Purist fallback if the double-tremolo sounds wrong in the ear test:
  drop the AM and instead phase-align by starting the baked-beat loop with
  play(from_position) computed from fmod(ticks / 1000.0, 0.5) - accept slow audio-clock
  drift, re-seek only on peril ENTRY (peril states are short; drift within one is nil).
- Combat core-hum pair: two short hum loops slightly detuned from each other (yours vs
  theirs), player volume mapped from core HP fraction by the combat screen via
  Amb.set_core_hum(side, hp_frac) - player volumes are Amb's to write, bus volumes are not.
- Headless-inert: Amb's pool node is never created headless, so _process never runs, so the
  whole mechanism is structurally inert - same guarantee as Sfx, by the same means.

---

## 6. HTML5 EXPORT CONSTRAINTS

- Autoplay unlock: browsers suspend the AudioContext until a user gesture; Godot's web
  export resumes it automatically on first input. Flow: the Workshop's first frame is
  silent by design (direction already mandates it). Music and ambience DO NOT start on
  ready when OS.has_feature("web"); the first input event triggers
  AudioDirector.notify_first_input() -> Amb bed fades in, Music winds up - which happens to
  BE the fiction (the music box winds up when the player touches the bench). On desktop the
  same call fires on ready.
- Threads: enable thread support + COOP/COEP headers (itch.io has the SharedArrayBuffer
  toggle) for AudioWorklet-with-threads latency. FALLBACK: single-threaded web audio works
  but adds ~50-90 ms latency - acceptable for a cozy game, but the hero snap will feel
  late; flag in playtest notes if the host cannot set headers.
- Codec support: OGG Vorbis and WAV (PCM / QOA) both decode in-engine on web - no browser
  codec dependency. QOA and OGG stay COMPRESSED in memory and decode on the fly.
- Streaming vs preload per category (web has no disk streaming - everything ships in the
  pck; the real axis is decoded-PCM-in-RAM vs decode-on-play):
    - SFX one-shots + UI micro: PCM WAV (uncompressed import), lazy-cached as today; add
      Sfx.warm(seams) called on screen enter to pre-touch the cache so a first-play load
      hitch never lands on a hero snap.
    - Music stems: QOA, decode-on-play, loaded once at Music.ensure().
    - Ambience beds: QOA, decode-on-play, loaded per screen on demand.
- Worst-case asset budget (full plan, all waves, computed from realistic sizes):
    - SFX one-shots: existing 14 (~7.6 s audio) ~0.67 MB + wave-2 foley ~35 files at avg
      350 ms ~1.1 MB + UI micro ~8 files ~0.06 MB = ~1.8 MB PCM.
    - Music: 4 bench stems, 48 s mono QOA ~0.85 MB each = ~3.4 MB (PCM fallback: 16.9 MB).
      Deferred shop/run motif sets, if ever shipped, ~+2 MB each - not in v1.
    - Ambience: workshop air 12 s + coffer interior 8 s + barrow bed 12 s + bellows 6 s +
      run wind 12 s + hums + peril bed + garnish one-shots = ~1.4 MB QOA/PCM mix.
    - TOTAL v1 full plan: ~6.6 MB in the pck. HARD BUDGET: 12 MB audio. Runtime audio
      memory: compressed sources + decode state + PCM one-shots < 15 MB worst case -
      negligible against a web heap; the binding constraint is download size, and 6.6 MB
      is comfortable.

---

## 7. MOBILE

- Voice pool: KEEP 8 (direction agrees; it fits combat flurries today). Fixed loop players
  on top: 1 music (Synchronized counts as one player, 4 internal decodes) + up to 4
  ambience (bed, hum, garnish, screen-specific) + peril + 2 combat hums = worst case ~16
  active voices / ~19 decoded streams - trivial for the mixer even on old Android.
- Hero-sound pool priority (the direction's "hero sounds get pool priority"), implemented
  in _grab_voice with two rules on top of the existing longest-playing steal:
    1. A voice playing a HERO_SEAMS sound younger than 250 ms is UNSTEALABLE by non-hero
       seams (the snap always finishes its moment).
    2. Hero seams steal exactly as today (free -> per-seam poly steal -> oldest), so a
       hero sound can always find a voice.
  Mark via the existing set_meta pattern (meta "hero", meta "started" already exists).
- UI taps ride the same 8-pool on the Ui bus; if a flurry starves a tap, the tap loses -
  correct per the direction (taps never shout, and never matter more than the room).
- Android latency: leave audio/output_latency at default; do not chase low-latency paths -
  turn-based cozy tolerates 20-40 ms.

---

## 8. SMOKE_AUDIO GATE EXTENSION

Stage A (always, headless - pure parsing and pure-logic, never plays audio):
1. Bus canon: AudioDirector.BUSES table is well-formed - every parent named exists in the
   table (or is Master), no cycles, duck buses are children of their category.
2. Every MANIFEST "bus" value is in the bus canon; every HERO_SEAMS member is in
   KNOWN_SEAMS; hero seams route to SfxBig or Ui-never-hero (assert hero not on Ui).
3. DUCK_RULES sanity: every target bus exists, depth in [-12, 0), attack <= 200 ms,
   release <= 1200 ms, state_held XOR timed_hold_ms.
4. Gate logic simulation (pure functions over injected timestamps): claim -> gate_allows
   refuses a Ui seam and allows death_winddown; release with a WRONG token keeps the gate
   closed; early release defers to the 1500 ms floor; double-claim / single-release keeps
   it closed; GATE_ALLOW is a subset of KNOWN_SEAMS.
5. Single-writer scan (regex over ui/*.gd, the same technique the gate already uses on
   combat_screen.gd): AudioServer.set_bus_volume_db and set_bus_mute appear ONLY in
   ui/sfx.gd and ui/audio_director.gd.
6. Stem lock invariants: parse the 4 stem WAVs - identical data chunk frame counts
   (byte-equal lengths), 44100/16/mono, smpl loop chunk present; frame count equals
   bars * beats_per_bar * SR * 60 / bpm from a tools/audio/stems_manifest.json the
   generator emits (integer, exact).
7. Loop math: peril bed = exactly 44100 frames (108 and 110 Hz both integer-cycle); soul
   hum frame count gives integer cycles of its f0 within epsilon.
8. Level discipline (LUFS proxy - real LUFS is verified once, manually, with an external
   meter): per-file RMS bands per category from the wav parse; and the direction's
   directly-testable law: ANY Ui-bus file peaking above -12 dBFS FAILS. NOTE this forces a
   pipeline change: make_sfx.py write() grows a peak_db parameter (default -3.0, UI batch
   passes -12.0) - the current unconditional -3 dBFS norm would make every UI file an
   instant gate failure.
9. Stage B (armed, as today): duration bands extended for every new file; stream_for()
   loads for every newly-manifested seam.

---

## 9. NEW/EDITED FILES (for the implementation lane - none written by this lane)

- NEW ui/audio_director.gd - buses table + ensure, user volumes, duck rules + refcounts +
  the two duck tweens, stillness gate (claim stack, allowlist, floor), first-input notify.
- NEW ui/music_box.gd - AudioStreamSynchronized build, STEM_TARGETS, set_state/stop_hard/
  set_peril/allow_fragment.
- NEW ui/ambience.gd - beds, soul hum + peril AM phase lock, combat hum pair, garnish
  scheduler (randomized 20-60 s, never rhythmic).
- EDIT ui/sfx.gd - bus reparent via AudioDirector, "Ui" manifest entries, HERO_SEAMS +
  hero duck trigger + hero voice protection, gate_allows check, Sfx.warm().
- EDIT tools/audio/make_sfx.py - stems + beds + hums batches, smpl chunk writer, per-file
  peak_db, stems_manifest.json emitter (bpm/bars/frames/key), all under the same seed
  discipline (per-batch random.seed so adding a batch never shifts existing bytes - the
  current single seed(7) stream means ANY new synthesis call reshuffles every later file;
  batches must re-seed per file name to keep byte-reproducibility additive).
- EDIT tests/smoke_audio.gd - section 8 invariants.

## 10. RISK REGISTER (direction items that are technically risky in Godot 4.7 + fallbacks)

1. OGG stems vs zero-install pipeline: stdlib cannot encode OGG. MITIGATED: WAV + QOA
   import (4.3+ feature, web-safe). Fallbacks: PCM WAV (+13 MB), or accept ffmpeg.
2. AudioStreamSynchronized per-stem volume zipper: set_sync_stream_volume has no built-in
   ramp; we tween it at frame rate which is effectively block-ramped. VALIDATE with a
   2-minute listen scene toggling stems before committing. Fallback: 4 players on 4 stem
   sub-buses under MusicDuck, started the same frame, with a startup sync assert
   (get_playback_position deltas < 1 mix block) and resync-on-state-change only.
3. Baked 2 Hz beat cannot phase-lock to the engine clock: RESOLVED structurally by
   code-side AM on the shared clock; purist fallback = seek-on-entry with accepted drift.
4. "Stems mixed on buses" letter-vs-intent: Synchronized mixes at stream level; bus level
   keeps slider/duck/gate. Flagged as a deliberate deviation; owner sees it here.
5. Web latency without COOP/COEP headers: hero snap feels late in the no-threads fallback.
   Ship itch.io with SharedArrayBuffer enabled; note in playtest kit.
6. UI peak law vs the pipeline's blanket -3 dBFS norm: write(peak_db) change is REQUIRED
   before any UI file ships or the gate (rightly) fails it.
7. LUFS targets are not natively measurable in Godot: gate enforces RMS proxies; do one
   manual LUFS pass with an external meter on the mixed game before the playtest.
8. Seed discipline: naively appending synthesis calls to make_sfx.py silently changes every
   byte of files generated after the insertion point (single RNG stream). Per-file
   re-seeding (seed = hash of file name) is REQUIRED in the same change that adds stems,
   or byte-reproducibility becomes a lie the smoke gate cannot see.

---

# SECTION 5 - IMPLEMENTATION TASK PLAN

# MANABIT Audio - Gameplay Programmer Implementation Task List (plan only, no code written)

Grounded in: audio-direction-v1.md (owner-signed), audio-sfx-spec.md, audio-tech-plan.md, and the code as it exists (ui/sfx.gd, tools/audio/make_sfx.py, tests/smoke_audio.gd, all Sfx.play call sites, ui/workshop.gd, ui/slot_field.gd, ui/chest_screen.gd, ui/broker_screen.gd, ui/run_screen.gd, ui/combat_screen.gd).

Recommended execution order (dependency-safe, honors the direction's ship order): T1 -> T9 -> T2 -> T3 -> T4 -> T5 -> T10 -> T11 -> T6 -> T7 -> T8 -> T12 -> T13 -> T14 -> T15 -> T16 -> T17 -> T18 -> T19 -> T20 -> T21. T9 (bus foundation) is pulled ahead of the UI-micro foley batch because the Ui bus must exist before any manifest row can route to it; everything else follows the direction's priority order.

---

## PRIORITY 1 - Voice the silent seams (interaction foley)

**T1. Pipeline hardening: additive seed discipline + per-file peak_db** - S/M - deps: none (FIRST)
- Files: tools/audio/make_sfx.py; tests/smoke_audio.gd (reproducibility note only)
- Change: keep the existing main() body untouched under the single seed(7) stream (preserves the 14 shipped wavs byte-identical - no churn); every NEW batch re-seeds per file with a STABLE hash (zlib.crc32 of the file name - never built-in hash(), which is PYTHONHASHSEED-salted). write() grows a peak_db parameter (default -3.0 so existing calls are unchanged; UI batches will pass -12.0).
- Gate: run the generator twice, hash-compare all outputs byte-identical; smoke_audio stage B still green on the untouched 14.

**T2. New synth voices: ratchet + liquid drip + paper noise** - M - deps: T1
- Files: tools/audio/make_sfx.py
- Change: three new primitives: ratchet(tick trains, fixed or accelerating - feeds seal_channel, switch_throw garnish, later gear_tick/fettle ticks); drip(rising sine chirp + glass-edge bell - feeds still_drip); paper(short bandpassed noise shapes with slide envelopes - feeds ledger_open, doorstep_untie and all P1 parchment seams). Loop rendering and the stem renderer are separate tasks (T15, T19).
- Gate: double-run byte-compare; new files pass extended duration bands as batches land.

**T3. Foley batch A: snap (the hero) + core_wake + the snap rarity pitch ladder** - M - deps: T1
- Files: tools/audio/make_sfx.py (snap_0, snap_1, core_wake_0); ui/sfx.gd (MANIFEST rows); ui/workshop.gd (line 1916: pass pitch_scale from the rarity ladder +0/+3/+7 semitones = 1.0/1.1892/1.4983, and pan by socket ARM_L/-0.25, ARM_R/+0.25, else center; line 1230 core_wake plays straight)
- Change: base snap tuned A4 440; ladder applied at the call site, zero extra files; snap and core_wake take zero jitter (add both to a no-jitter set alongside OUTCOME_SEAMS, or extend that constant - spec says hero/ritual play straight).
- Gate: smoke_audio bands + stream_for loads; manual: seat COMMON/RARE/EPIC bits, hear A-C-E arpeggio.

**T4. Foley batch B: coffer set (seal_channel, seal_crack, lid_spring, reveal_common/rare/epic) + reveal call-site visibility fix** - M - deps: T1, T2
- Files: tools/audio/make_sfx.py (6 files); ui/sfx.gd (MANIFEST rows; seal_crack routes SfxBig); ui/chest_screen.gd (line 385: replace the dynamic `"reveal_" + r.to_lower()` with an explicit StringName match so the regex gate can see the seams - CORRECTION to the gap list: this call site already exists and fires)
- Change: seal_channel is the ratchet+hum ritual open-ended file cut by seal_crack; reveal ladder per spec (dry tok E4 / glass C6+E6 / deep G3 bell + sub + faux choral, DOWN and WIDE).
- Gate: smoke_audio bands; extend the director-scan regex to chest_screen.gd; manual coffer open at all three rarities.

**T5. Foley batch C: BIND set - bind_press + bound_chord (new seams)** - S/M - deps: T1
- Files: tools/audio/make_sfx.py (bind_press_0, bound_chord_0); ui/sfx.gd (KNOWN_SEAMS += &"bind_press", &"bound_chord"; MANIFEST; bound_chord routes SfxBig); ui/workshop.gd (_on_bank, ~line 955: bind_press when the wax press lands, bound_chord on success; the BOUND! toast at line 966 stays silent - one hero per beat)
- Gate: smoke_audio seam canon (new seams known); manual bind ceremony.

**T6. Foley batch D: furniture + UI micro - drawer_slide, drawer_tuck, medallion_tap, ui_tap (new seams, first Ui-bus rows)** - M - deps: T1, T9
- Files: tools/audio/make_sfx.py (drawer_slide_0, drawer_tuck_0, medallion_tap_0/1, ui_tap_0/1 - UI files written with peak_db=-12.0); ui/sfx.gd (KNOWN_SEAMS, MANIFEST with "bus": "Ui" for medallion_tap/ui_tap; Ui seams never pass pan); ui/workshop.gd (_set_drawer at line 534 plays slide/tuck on the open/close transitions); ui/slot_field.gd (tap handler plays medallion_tap with socket-side pan via the SFX-bus... NO - spec says Ui bus, so no pan; play it center); generic ui_tap wired at the central control-construction points (tray chips, dropdowns, nav buttons) - NOT a global input hook; keep scope surgical
- Gate: smoke_audio Ui peak law (any Ui file above -12 dBFS FAILS); manual drawer + tap pass.

**T7. Foley batch E: barrow transactions - wax_stamp, coin_scrap x2, still_drip x3 + the fettle_apologise bookkeeping fix** - M - deps: T1, T2
- Files: tools/audio/make_sfx.py (6 files); ui/sfx.gd (MANIFEST; wax_stamp routes SfxBig; add &"fettle_apologise" to KNOWN_SEAMS)
- Change: call sites already live in broker_screen.gd (381/396 wax_stamp, 459 coin_scrap, 434 still_drip). CAVEAT verified from grep: no `Sfx.play(&"fettle_apologise")` literal exists anywhere in ui/ - the spec's claimed call site is either dynamic or absent; verify during wiring and add the call in the broker warm-refusal path if missing (its wav is P1, the seam registration is now).
- Gate: smoke_audio; manual buy/sell/melt/distill pass with odometer rolls.

**T8. Foley batch F: run set - switch_throw, route_step x2, fork_reveal** - S - deps: T1
- Files: tools/audio/make_sfx.py (4 files); ui/sfx.gd (MANIFEST)
- Change: call sites already live (run_screen.gd 446/463/582). route_step gets 2 variants with +-3% jitter; switch_throw the heavy brass lever.
- Gate: smoke_audio; manual run advance + junction throw.

---

## PRIORITY 2 - Bus architecture + stillness gate + duckings + level pass

**T9. AudioDirector bus foundation + Sfx reparent** - M - deps: none (build right after T1)
- Files: NEW ui/audio_director.gd (static RefCounted, sfx.gd house style: declarative BUSES table per tech plan 1.1 - Master > Music/MusicDuck, Ambience/AmbDuck, SFX > Sfx(+PanL/R), SfxBig(+PanL/R), Ui; ensure_buses() idempotent, parents first, headless-inert); ui/sfx.gd (_ensure_buses delegates to AudioDirector; Sfx/SfxBig re-parent to send to "SFX" - a table change, buses are code-created fresh every run)
- Change: single-writer law starts here - only sfx.gd (its internal Sfx duck) and audio_director.gd may ever call AudioServer.set_bus_volume_db/set_bus_mute.
- Gate: NEW smoke_audio stage A checks - bus canon well-formed (parents exist, no cycles, duck buses children of category), single-writer regex scan over ui/*.gd; all 14 fast gates still green; manual: game sounds unchanged.

**T10. Duck engine: DUCK_RULES + refcounts + the hero duck + hero voice protection** - M - deps: T9
- Files: ui/audio_director.gd (DUCK_RULES table hero/peril/ritual per tech plan sec 3; duck_claim/duck_release ref-counted; exactly ONE tween per duck bus; deepest-wins compositing); ui/sfx.gd (new HERO_SEAMS set: snap, seal_crack, reveal_epic, wax_stamp, bound_chord, victory_chord, hit_core, part_break; hero duck triggered inside play() with timed 250ms hold; _grab_voice gains the two hero rules - a hero voice younger than 250ms is unstealable by non-hero seams, heroes steal as today)
- Gate: smoke_audio DUCK_RULES sanity (targets exist, depth in [-12,0), attack <= 200ms, release <= 1200ms, state_held XOR timed_hold_ms) + headless refcount simulation (claim/claim/release leaves ducked; final release recovers); manual flurry test - MULTI break chains never stick the bus.

**T11. The stillness gate (structural) + parts_settle + THE UNMAKING wiring** - L - deps: T9, T10 - RISK FLAG 1
- Files: ui/audio_director.gd (gate_claim(token, priority) claim stack, gate_release matching-token-only, gate_allows(seam) with GATE_ALLOW = [death_winddown, parts_settle, loss_settle], 1500ms structural floor over injected timestamps, tween-kill + refcount freeze on first claim, mute Music/Ambience/Ui, SfxBig never gated - it is the death channel); ui/sfx.gd (gate_allows consulted in play() BEFORE manifest lookup, synchronous, no frame gap); tools/audio/make_sfx.py (parts_settle_0/1); ui/sfx.gd (KNOWN_SEAMS/MANIFEST for parts_settle); ui/combat_screen.gd (beat planner claims &"unmaking" at priority 100 when death_winddown fires ~line 1039/1050, releases on the parts-settle beat and plays parts_settle - the beat system owns release, the floor is a floor)
- Gate: smoke_audio gate-logic simulation, pure functions headless: claim refuses a Ui seam + allows death_winddown; wrong-token release keeps it closed; early release defers to the floor; double-claim/single-release stays closed; GATE_ALLOW subset of KNOWN_SEAMS. Plus smoke_beats (59) must stay green - the beat planner is touched.

**T12. Ritual + bark duck claims at call sites** - S - deps: T10
- Files: ui/chest_screen.gd (seal_channel window: claim &"ritual" token seal_channel on press-hold start ~line 311, release on crack/cancel; reveal_epic 600ms hold claims too); ui/workshop.gd (BIND hold claim/release around _on_bank); ui/broker_screen.gd (bark claims around fettle_greet/appraise)
- Change: audibly near-no-op until music/ambience exist - lands the structure early so P3/P4 arrive pre-ducked.
- Gate: headless duck sim covers overlapping ritual tokens; manual once beds exist.

**T13. Settings-sliders seam (queued milestone - seam only, no UI)** - S/M - deps: T9
- Files: ui/audio_director.gd (set_user_volume(&"Master"|&"Music"|&"Ambience"|&"SFX", frac): frac 0 = set_bus_mute(true) + per-bus user_muted flag; else linear_to_db(pow(frac,1.5)) clamped [-38,0]; gate release restores mute = user_muted, never blindly false; apply_user_volumes() on first UI-frame ensure, never headless); SaveManager (additive settings dict, schema-safe)
- Gate: smoke_persist (7/7) still green; headless unit check of the taper math + the gate/user_muted interplay.

**T14. Level-discipline pass + consolidated smoke_audio extension** - M - deps: T3-T8 landed
- Files: tests/smoke_audio.gd (duration bands for every new file; per-category RMS proxy bands from the wav parse; the Ui -12 dBFS law; stage B stream_for loads for every newly-manifested seam); ui/sfx.gd (MANIFEST gain trims from listening)
- Change: one manual LUFS session with an external meter on the mixed game (LUFS is not natively measurable in Godot - the gate enforces RMS proxies, the meter verifies once, pre-playtest).
- Gate: is itself the gate; documents the meter reading in the playtest kit.

---

## PRIORITY 3 - Ambience (the room)

**T15. Loop-render support + ambience/state assets** - M/L - deps: T1
- Files: tools/audio/make_sfx.py (seamless-loop rendering: integer-cycle sine loops, endpoint-matched noise loops; assets: amb_workshop_air 12s, amb_clock_tick_0/1 one-shots, soul_hum 4.0s constant-amplitude loop, core_hum 6s loop, peril_bed exactly 1.000s = 44100 frames of the 108+110 Hz pair at constant blended amplitude - the 2 Hz pulse is applied in code, not baked)
- Gate: NEW smoke_audio loop-math checks: peril_bed exactly 44100 frames; hum f0 integer cycles within epsilon; double-run byte-compare.

**T16. ui/ambience.gd (Amb): beds, clock scheduler, phase-locked soul hum, dormant absence** - L - deps: T9, T15 - RISK FLAG 2 candidate (see risks)
- Files: NEW ui/ambience.gd (static class Amb, lazy pool node + headless-inert exactly like Sfx; players live on AmbDuck; clock tick scheduled ~0.8 Hz with +-60ms micro-jitter, never metronomes; soul hum PLAYER volume_db written every _process from the shared engine clock with the identical formula slot_field's invite ring uses - phase-locked by construction, zero drift; dormant = player stopped with 800ms release, the room noticeably emptier); ui/workshop.gd (notify Amb on core seat/unseat, screen enter/exit starts/stops the bed; 150-300ms crossfade through near-silence on screen transitions)
- Change: Amb writes PLAYER volumes only - bus volumes stay AudioDirector's; single-writer scan still passes untouched.
- Gate: single-writer regex scan; headless gates untouched (pool node never created headless so _process never runs); manual: dormant vs awake workshop difference; clock never metronomes over 5 minutes.

**T17. Combat core-hum pair + the peril state** - M - deps: T11, T16
- Files: ui/ambience.gd (set_combat_hums_active(bool); set_core_hum(side, hp_frac) maps player volume; one core_hum file, two players, yours pitch 1.0 slightly L, theirs 1.01 slightly R; peril_bed player with 2 Hz AM from the shared clock, 200ms attack, ~1s release); ui/combat_screen.gd (start hums on combat entry, feed HP fractions per beat, peril entry ~line 610 keeps the core_peril one-shot as the entry accent AND calls duck_claim(&"peril") + Amb peril start + Music.set_peril(true) (no-op until T21), peril exit on mend/kill releases all three); ui/audio_director.gd (gate kills both hums instantly on claim - already specced in T11)
- Gate: smoke_beats green; manual: hums die with their cores, peril empties the room, UNMAKING silences everything.

**T18. First-input unlock (web) + Sfx.warm()** - S - deps: T9, T16
- Files: ui/audio_director.gd (notify_first_input(): on web the AudioContext resumes on first gesture - Amb bed fades in, Music winds up, which IS the fiction; on desktop fires on ready); ui/sfx.gd (warm(seams) pre-touches the stream cache); screen scripts call warm on enter so a first-play load hitch never lands on a hero snap
- Gate: manual web export smoke (itch.io SharedArrayBuffer note in playtest kit); desktop parity check.

---

## PRIORITY 4 - Music (The Wound Spring)

**T19. Stem renderer: note-data -> 4 sample-locked stem WAVs + smpl loop chunk + stems_manifest.json** - L - deps: T1 - RISK FLAG 3
- Files: tools/audio/make_sfx.py (note-event tables for the bench motif - note data authored by the sound-designer lane, in C major/A minor per the KEY LAW; render melody/bells/pad/pulse via bell()/brass()/tok(); 80 BPM 4/4, 16 bars = 48.000s = 2,116,800 samples exact, all four stems byte-equal frame counts; smpl chunk written with pure struct.pack, loop 0 -> end; emit tools/audio/stems_manifest.json with bpm/bars/frames/key)
- Gate: NEW smoke_audio stem-lock invariants: identical data-chunk frame counts, 44100/16/mono, smpl present, frame count equals the manifest math exactly; double-run byte-compare.

**T20. QOA import setup for stems + long beds** - S - deps: T19, T15
- Files: .import overrides (AudioStreamWAV compress mode QOA, loop Detect From WAV), checked in
- Change: resolves the OGG-vs-stdlib conflict per the tech plan (no stdlib OGG encoder); ~0.85 MB per 48s stem. Fallback ladder documented: plain PCM WAV, then ffmpeg+OGG.
- Gate: headless --import clean; manual playback on desktop + web export.

**T21. ui/music_box.gd (Music): AudioStreamSynchronized player + state table + combat orchestration** - L - deps: T9, T10, T11, T19, T20 - RISK FLAG 2
- Files: NEW ui/music_box.gd (static class Music, Sfx's lazy-node + inert pattern, one player on MusicDuck; AudioStreamSynchronized built in code at first use; STEM_TARGETS table BENCH/SHOP/RUN/COMBAT/COMBAT_TENSE/WAKING/SILENT per tech plan 4.3; set_state tweens each stem 800ms; stop_hard instant; set_peril = max-mute overlay on melody so state changes cannot resurrect it; allow_fragment bar-quantized from get_playback_position); ui/workshop.gd + ui/broker_screen.gd + ui/run_screen.gd + ui/chest_screen.gd (set_state on screen enter; WAKING keeps the player running all-stems -60); ui/combat_screen.gd (victory: beat planner calls Music.stop_hard, schedules victory_chord 375ms later - the half-beat at 80 BPM - resumes BENCH ~1.2s after; survivable loss: music returns -6 dB for ~10s; death: no music on the death screen, workshop reopens ambience-only ~10s - that timing lives in workshop.gd, not the gate)
- Gate: single-writer scan; VALIDATION LISTEN SCENE first - 2 minutes toggling stems to check set_sync_stream_volume zipper before committing (fallback: 4 players on 4 stem sub-buses with startup sync assert); all 14 gates + smoke_beats green.

---

## DEFERRED BUCKET

**Post-playtest (P1 tier from the spec - real work, queued, not cut):**
- D1. Barrow P1 foley wavs: ledger_open, fettle_greet, fettle_appraise, fettle_apologise (+ its call-site verification), doorstep_untie, forge_melt (call sites all live; wav + MANIFEST only) - M
- D2. New-seam P1 foley + wiring: gear_tick (odometer hook in Juice.odometer), new_stamp (card land), equip_whoosh (drag start), strain_creak (Balance overweight transition in the WeightMeter/workshop strain path), christen_chime (nameplate), ink_wipe + tag_untie (workshop tag state machine _play_tag_untie ~line 1603 - tag_untie plays exactly once per save, ever), inspect_open/close (_open_inspect line 1264 / _close_inspect line 1318), screen_turn, toast_pin (with hero-beat suppression rule), binding_channel + binding_strike (the Binding hold in the BindCoreCard path), box_crack + grade_reveal x3 (_open_box_reveal line 1002), card_land x2 (PackOpen land beat) - L overall, each individually S
- D3. Ambience P1: coffer nook bed reuse (-6 dB mix rule) + amb_coffer_shift/rune loops (rune swells with press-hold charge), amb_barrow_wind + amb_fettle_forge + amb_melt_ember loops, amb_run_wind + amb_rail_hum (rises near junctions, dies on switch_throw), workshop garnish (wood_settle, lamp_ping, spool_roll) via Amb's 20-60s never-rhythmic scheduler - M/L
- D4. Music: shop/run/nook motif variants (12 stems), COMBAT melody fragments tuning, post-death mourning-quiet timing polish - M

**Cut list (direction's CUT + spec DEFER - do not build until funded):**
- ledger_fade (honestly optional, may stay silent); node-modifier ambience tints; amb_cart_creak + amb_satchel_creak (SOURCE tier - the only assets the pipeline cannot honestly synthesize; all DEFER, so the playtest ships 100% from the pipeline); Fettle idle key ratchet; Candidate C (The Artificer's Waltz) exploration and the AudioStreamInteractive upgrade path.

---

## Cross-cutting laws every task obeys
- Sfx.play(seam, pitch, pan) signature and silent no-op contract unchanged; all existing call sites compile untouched.
- Headless-inert everywhere: every new module copies Sfx's DisplayServer check-once pattern; no buses, players, or nodes exist headless; all 14 fast gates re-run after every task.
- No em/en dashes in any code, comment, or string - hyphens only. Cozy-craft, never casino.
- Single-writer: AudioServer bus writes only in ui/sfx.gd and ui/audio_director.gd, enforced by regex in smoke_audio.
- Every new wav lands with its smoke_audio duration band + stream_for check in the same change.

## Implementation risks (carried with the task list)

- RISK 1 - T11 stillness gate: it edits the Sfx.play hot path, the combat beat planner, and the game's most protected moment simultaneously. The 59-test smoke_beats gate and the UNMAKING timeline (death_winddown decayed by 900ms, stillness at t=1200) are both live dependencies; a wrong claim/release token or a reduce-motion shortened timeline releasing early would either poke a hole in the sacred silence or deadlock the mix open. Mitigation is built in: pure-logic claim stack tested headless over injected timestamps, matching-token release, the 1500ms structural floor, and SfxBig exempt as the death channel - but this is the task to review hardest.
- RISK 2 - T21 music stem player: AudioStreamSynchronized per-stem volume has no built-in ramp (zipper risk, unvalidated in this project), QOA import is a first use, and the victory half-beat orchestration touches the combat beat planner a second time. Mitigation: mandatory 2-minute validation listen scene BEFORE committing, documented fallback (4 players on stem sub-buses with a sync assert), and the fiction-friendly failure mode that music simply stays simpler. Schedule it last so nothing downstream stacks on it.
- RISK 3 - T1 seed discipline: the byte-reproducibility law dies silently if done wrong. Two traps verified from the code: the current single seed(7) stream means ANY synthesis call inserted before existing ones reshuffles every later file's bytes (so the legacy 14 must keep their exact generation order under seed(7), with per-file seeding applied only to new batches), and Python's built-in hash() is process-salted so per-file seeds MUST come from a stable hash (zlib.crc32 of the file name). The double-run byte-compare gate catches within-machine failure but not the hash() trap across processes - the double run must be two separate interpreter invocations.
- Secondary risk - T16 phase lock: the soul hum's code-side AM must use the exact formula and clock the visual invite ring uses (Time.get_ticks_msec, 2s period); a copied-but-drifted constant produces a subtle out-of-breath room that playtesters feel but cannot report. Pin both to one shared constant during implementation.
- Bookkeeping corrections to carry into implementation: the three reveal seams DO have a live call site (chest_screen.gd:385, dynamic string - invisible to the regex gate; fix visibility in T4), and fettle_apologise has NO literal call site anywhere in ui/ despite the spec's claim - verify and wire it in D1.

---

# SECTION 6 - OPEN QUESTIONS BETWEEN TEAM MEMBERS

Derived honestly by the compiler from conflicts found while assembling Sections 1-5. Each names the lanes in tension and what must be decided before (or during) the affected task.

**Q1. Who builds the R1 sustained peril visual? (accessibility vs task plan - BLOCKS a P0 asset)** Accessibility R1 is the plan's one hard requirement: peril_bed (P0) may not ship without a sustained visual twin plus a reduce-motion-safe variant, and the combat-side 2 Hz heartbeat clock the direction phase-locks the bed to does not exist yet. No task in Section 5 builds any of this - T17 wires the bed's audio only. A visual/combat-lane task must be added and sequenced before T17 closes, or peril_bed slips out of the playtest.

**Q2. GATE_ALLOW seam-name drift: part_settle vs parts_settle (tech plan vs spec + task plan).** Tech plan section 2 writes GATE_ALLOW = [death_winddown, part_settle, loss_settle]; the spec and T11 name the seam parts_settle. If the allowlist and the seam registration disagree by one letter, the stillness gate refuses its own exit sound and the UNMAKING deadlocks silent past the floor. Canonical name proposed: parts_settle (matches the spec's asset row). One StringName, pinned in T11, checked by the GATE_ALLOW-subset-of-KNOWN_SEAMS gate.

**Q3. HERO_SEAMS membership mismatch (sound designer vs technical artist).** The spec's hero music-duck list is snap, seal_crack, reveal_epic, bound_chord, victory_chord, wax_stamp, binding_strike, box_crack, with hit_core and part_break explicitly SfxBig-only (no music duck). The tech plan and T10 instead put hit_core and part_break IN the music-duck hero set and omit binding_strike and box_crack. The audible difference: whether every combat hit-to-core and part break ducks the pulse stem, and whether the two P1 heroes join the set when D2 lands. The direction's own duck list (section 5) names only snap, seal_crack, epic bell, wax_stamp plus barks and rituals. Needs one canonical set before T10; compiler note: the spec's split is closer to the direction's letter, the tech list is closer to combat feel - audio-director call.

**Q4. Music tempo and stem length: ~72 BPM / 12 bars / ~40s (spec group 6) vs 80 BPM / 16 bars / 48.000s (tech plan 4.2, T19, T21).** Both are integer-sample-clean at 44100, so the tech constraint does not force either. But the victory half-beat is hardcoded downstream as 375ms (80 BPM); at 72 BPM it is ~417ms. The sound-designer must author the bench note-data to ONE canonical tempo/length, stems_manifest.json must carry it, and the T21 victory orchestration must read the half-beat from the manifest rather than hardcoding 375ms - or the tempo is locked at 80 forever.

**Q5. Baked-breath vs constant-amplitude loops: the spec rows for soul_hum (8s loop, AM breathing BAKED at 0.5 Hz) and peril_bed (4s loop) conflict with the tech plan's phase-lock resolution (constant-amplitude files - soul_hum 4.0s, peril_bed exactly 1.000s / 44100 frames - with ALL modulation applied code-side from the shared engine clock).** T15 follows the tech plan. The tech resolution should be marked canonical and the two spec rows annotated stale, so a future asset pass does not regenerate baked-breath files that can never phase-lock.

**Q6. Does the slider set satisfy R6? (accessibility vs tech plan).** R6 asks for four bus volume sliders + master (naming Music / Ambience / SFX / UI). The tech plan ships four sliders total - MASTER, MUSIC, AMBIENCE, SFX - with Ui deliberately riding the SFX slider as a child bus. Practical effect: a player cannot soften UI taps independently of gameplay SFX. Likely acceptable (taps are capped at -12 dBFS by law), but accessibility should explicitly ratify the 4-slider set as meeting R6, or T13 grows a fifth mapping (the Ui bus is already independently addressable).

**Q7. Owner ratification of the three flagged letter-vs-intent deviations (tech plan risk register items 1 and 4, bus tree 1.1).** (a) Stems ship as WAV + QOA import, not OGG as the direction's web notes say (stdlib has no OGG encoder; fallback ladder documented). (b) Stems are mixed sample-locked inside one AudioStreamSynchronized player, not "mixed live on Godot buses" - bus level keeps slider/duck/gate. (c) Ui is a child of SFX, not a top-level fourth bus. All three are argued deviations that honor intent; the tech plan says "owner sees it here" - this document is where the owner sees it. Sign-off requested with the rest of the plan.

**Q8. fettle_apologise call site: spec vs code ground truth.** The spec's bookkeeping note claims a live call site missing only its KNOWN_SEAMS registration; the task plan's grep (re-verified by the compiler on 2026-07-19: zero matches for fettle_apologise anywhere in ui/) found no literal call site. T7 registers the seam now; D1 must verify whether a dynamic call path exists and, if not, wire the broker warm-refusal path when the wav lands. The spec's claim should not be trusted as-is.

**Q9. peril_bed's -26 sits above the Ambience mix ceiling (mix table: beds -35ish LUFS, garnish max -28).** The adaptive rules sanction it ("the 2 Hz beat becomes the score") and R2 caps it at -26, but the mix table carves no explicit exception, so the T14 level pass could "correct" the loudest thing on the Ambience bus downward - or a juice pass could push it up. Add one line to the mix table: peril_bed is the sanctioned exception, capped at -26, floor at taste, never rising with HP (R2).