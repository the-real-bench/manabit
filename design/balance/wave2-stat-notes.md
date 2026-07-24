# WAVE 2 STAT NOTES - retro-hero families (balance-council stat pass)

STATUS: PRICED 2026-07-19 against the shipped budget model (design/equipment/balance-notes.md)
and the wave-1 measured roster (tools/sim/out/roster-post.json). Verify lane owns the roster re-run.

## Method

Every bit is priced on the authoring ruler (ATK/DEF/SPD 2 / EN 1 / part-HP 0.5 / core-HP 0.4 /
carry 0.4; weight rebate 0.2/pt capped at 40 percent of raw stat points; ability SINGLE p x1.5,
MULTI p x hits x1.0, GUARD DEF_BUFF x1.5, PART_RESTORE x1.0, minus 0.5 x mana_cost) AND against a
measured comparable from roster-post.json, because wave 1 proved paper price and measured value
diverge on two axes:

1. LIGHT/FAST IS STRUCTURALLY WEAK (speed only buys initiative): weefist -16.5 percent, windshear
   -9.9, slip greaves -10.6, zephyr -7.5 all priced "fairly" and measured dead. Consequence
   applied: every Larkabout bit ships a real part-HP floor (no body part below hp 7; feather arms
   at hp 11-12 per the D4 prescription) and honest weight; the sky identity is carried by
   initiative plus ability composition, never by paper-stat fragility.
2. DEF/HP STACKING OUTRUNS ITS PAPER PRICE (bedrock +34.0 at a paper 23): Steadfast deliberately
   prices its wall pieces at the BOTTOM of their bands and keeps every def/hp line below the
   measured bedrock (def 6 / hp 26) and girder (COMMON atk 4 / def 2) tiers, paying for bulk with
   weight 22-32 and SPD 0-2.
3. TARGET BAND: mean_delta -5 to +15 percent, hard cap +18. Rarity discipline: COMMON at or below
   the measured COMMON mean +2.1, RARE near +6.8, EPIC near +8.7. Wheel edges come from archetype
   interaction (big SINGLE vs DEF, initiative vs slow nukes, part-HP depth vs chip), not stat
   inflation.

Budget notation below: raw stats + ability - weight rebate = total (band).

## Stat-notes table

| Bit | Slot/Rarity | Stat line (hp/atk/def/spd/w/en) | Ability | Budget | Priced like (measured comparable) | Expected delta |
|---|---|---|---|---|---|---|
| Ding Arm | ARM_R C | 10/3/0/2/18/0 | SINGLE p4 c1 | 15+5.5-3.6=16.9 (14-18) | everykit_standard_fist at +2.8: same p4 c1, trades 1 ATK + 1 DEF for SPD 2 and 6 lighter | +1 to +3 |
| Carol Arm | ARM_L C | 10/3/0/2/20/0 | MULTI p2 x3 c2 | 15+5-4=16 (14-18) | between everykit_standard_piston +7.9 (heavier, atk 4) and quivergear_salvo_fist -4.9 (lighter, hp 9); hp 10 floor honors lesson 1 | +1 to +4 |
| Peal Cannon | ARM_R R | 10/4/0/1/30/0 | SINGLE p7 c3, no core | 15+9-6=18 (18-22) | sovereign_brass_arm_pistonfist +16.5 (19.2) and boldheart_arm_sunder +14.75 (20.9), priced 1-3 pts under both, no core reach, mana 3 throttle - the anti-grumble big shot without their heat | +7 to +10 |
| Muffle Mitt | ARM_R R | 12/0/2/2/14/2 | GUARD DEF_BUFF g5 c2 | 16+6.5-2.8=19.7 (18-22) | grumble_co_slab_pauldron -11.6 (AI-lens floor) and errant_arm_warder -1.4; the light shelf fill - w14 spd2 vs slab w30 spd0 | 0 to +5 |
| Grand Peal | ARM_L E | 10/5/0/1/32/0 | SINGLE p9 c4, CORE | 17+11.5-6.4=22.1 (22-26) | boldheart_arm_meteor post-nerf +10.8 (23.5): 1.4 pts cheaper, mid-weight third lane vs meteor w50-slow and grinlet -12.3 feather glass | +8 to +11 |
| Bellows Pack | BACK R | 8/0/1/1/12/9 | GUARD DEF_BUFF g4 c2 | 17+5-2.4=19.6 (18-22) | everykit_standard_cell +3.2 one tier up; en 9 tops sovereign_brass_back_mantle +3.2 (en 8) with a smaller guard - funds the Peal charge cycle | +4 to +7 |
| Larkcrest Dome | HEAD C | 7/1/0/4/7/1 | SINGLE p3 c1 | 14.5+4-1.4=17.1 (14-18) | everykit_standard_cowl -1.6 (17.8): trades 1 ATK for SPD 4 + hp 7; NOT priced like windshear -9.9 (the dead glass-head shape it must not repeat) | -2 to +1 |
| Swoop-Crest Helm | HEAD R | 9/2/0/4/10/1 | SINGLE p5 c3, CORE | 17.5+6-2=21.5 (18-22) | silksteel_head_whisper -0.1 (20.3) with a real body (hp 9, atk 2, spd 4) bought by giving back en 5 - windshear one honest tier up | +4 to +8 |
| Catch-Hand Mitt | ARM_R C | 12/1/0/2/6/0 | SINGLE p4 c1 | 12+5.5-1.2=16.3 (14-18) | pocketful_arm_weefist -16.5 (16.2): SAME paper price, but hp 12 vs 8 is exactly the D4 light-axis floor - the feather ARM_R hole filled without the glass | -5 to 0 |
| Sunup Haymaker | ARM_L R | 10/5/0/1/28/0 | SINGLE p6 c2 | 17+8-5.6=19.4 (18-22) | boldheart_arm_sunder +14.75 (20.9) minus 3 raw ATK points, keeping SPD 1 - the hero swings before the wall braces | +6 to +9 |
| Rocketboot Striders | LEGS R | 16/1/1/6/24/0 | passive | 24+0-4.8=19.2 (18-22) | errant_legs_rampart +9.3 (19.4 paper), trading def 3 to def 1 for atk 1 + spd 6; NOT priced like whirligig_legs_zephyr -7.5 (identical 19.2 paper but def 0 glass) | +6 to +10 |
| Contrail Boots | LEGS E | 14/1/0/8/16/2 | passive | 27+0-3.2=23.8 (22-26) | chatterbox_skitter_legs_6 +2.8 one tier up; hp 14 stays above the dead slip-greaves hp 10 pattern; deliberately BELOW the EPIC mean because top SPD only buys initiative (lesson 1) - the anti-bedrock pole, not a power pick | 0 to +6 |
| Updraft Satchel | BACK R | 9/0/1/4/12/7 | passive | 21.5+0-2.4=19.1 (18-22) | whirligig_back_slipfin +3.5 one tier up (spd 4 vs 3, en 7 vs 5, hp 9 vs 8); the first RARE passive-mobility back | +3 to +6 |
| Guardian Dome | HEAD C | 9/0/2/1/12/2 | GUARD DEF_BUFF g3 c1 | 12.5+4-2.4=14.1 (14-18) | sovereign_brass_head_herald +14.9 (19.5) is the warning shot - the same shape two restraint tiers down (g3 vs g4, def 2 vs 3, cost 1); band floor keeps the COMMON at or below +2.1 | +1 to +4 |
| Beacon Brow | HEAD E | 16/0/3/0/26/4 | GUARD DEF_BUFF g8 c3 | 18+10.5-5.2=23.3 (22-26) | grumble_co_bastion_fist +7.3 (23.2, the same paper price): g8 at the EPIC cap paid for with w26 + spd 0; def 3 stays at herald tier, NOT bedrock tier (lesson 2) | +8 to +12 |
| Signal-Glove | ARM_R C | 11/1/0/1/5/4 | SINGLE p2 c1 | 13.5+2.5-1=15 (14-18) | pocketful_arm_weefist -16.5 as the cautionary comparable: feather weight kept, but hp 11 floor + en 4 utility line replace the glass-nuke shape | -4 to 0 |
| Twin Rocketfist | ARM_L R | 12/6/1/0/32/0 | MULTI p3 x2 c2 | 20+5-6.4=18.6 (18-22) | thicket_fang_arm_goreclaw +8.75 (18.9): same paper price, sturdier body (hp 12, def 1) buying half the hits - 2 hits at the RARE per-hit ceiling 3, inside shipped soft-caps | +5 to +9 |
| Gantry Greaves | LEGS R | 22/0/4/2/30/1 | passive | 24+0-6=18 (18-22) | between errant_legs_rampart +9.3 and cobble_sons_legs_bedrock +34.0: hp 22 / def 4 sits strictly below bedrock hp 26 / def 6, and the band-FLOOR price is deliberate headroom because def/hp outruns its paper price (lesson 2) | +8 to +13 |
| Windup Key | BACK C | 8/0/1/0/16/8 | GUARD PART_RESTORE g4 c1 | 14+3.5-3.2=14.3 (14-18) | cobble_sons_back_toolrack +0.5: +2 hp, +1 def, +1 restore for +2 weight and the spd 2 given back; PART_RESTORE spread to a fourth family | +1 to +3 |
| Gallant Core | CORE E | 40/4/1/1/22/8 carry 12 | none (core) | 40.8+0-4.4=36.4 | sovereign_brass_core_regalia post-nerf +17.4 (38.6) and boldheart_core_sunheart +10.1 (33.6): priced between them, 2.2 pts under Regalia; def 1 keeps it OFF the wall axis (attack lean 4), carry 12 sits between keystone 10 and lent heirloom 15 (capacity IS the giant fantasy), heaviest core in the game at w22 | +12 to +15 |

## Rulings and compliance notes

- RARITY MIX AS RATIFIED: the spec header line says 6 COMMON / 10 RARE / 4 EPIC but its three
  ratified bit tables sum to 7 COMMON / 9 RARE / 4 EPIC (Steadfast carries 3 COMMONs: Guardian
  Dome, Signal-Glove, Windup Key). The per-bit tables are the ratified artifact; this pass follows
  them. Flagging the header discrepancy for the council rather than silently changing a bit's
  rarity.
- GALLANT CORE SHIPS EPIC (no demote): at 36.4 it prices 2.2 points under the measured Regalia
  and its attack affinity means it inherits the cooler Sunheart curve, not the hot defense-core
  curve (Bulwark +15.0, Keystone +17.1, Regalia +17.4 vs Sunheart +10.1). Projected inside the
  +18 cap with margin. The RARE-demote fallback stays documented in the spec if the verify lane
  measures above +18.
- LARKCREST DOME SHIPS COMMON: at 17.1 vs the cowl's 17.8 it does not crowd the shelf upward;
  the council's demote option stays open but nothing measured argues for it.
- SOFT-CAPS ALL HONORED: SINGLE p4/p4/p3/p2 COMMON (cap 5), p7/p6/p5 RARE (cap 7), p9 EPIC
  (cap 9); MULTI 3 hits p2 COMMON (caps 3/3), 2 hits p3 RARE (caps 4/3); GUARD g3/g4 COMMON
  (cap 4), g5/g4 RARE (cap 6), g8 EPIC (cap 8). Carry priced 0.4/pt per balance-notes.
- NO STRICT DOMINANCE introduced in any slot+rarity cell (checked pairwise against the live
  catalog): every new bit trades on at least one axis against every same-cell peer (e.g. Ding vs
  Everykit Fist trades ATK/DEF for SPD/weight; Bellows vs Mantle trades guard 2 for en 1 + weight
  4; Windup vs Toolrack trades spd 2 + weight for hp/def/restore).
- WHEEL EDGES ARE ARCHETYPAL, not stat-bought: Carillon beats grumble_co because p7/p9 SINGLEs
  ignore the per-hit DEF blunting that walls tune against flurries, and loses to whirligig because
  its mana 3/4 cycle dies when tempo strips the cannon arm mid-charge. Larkabout beats boldheart
  on initiative (spd 4-8 lines vs spd 0 nukes, breaking the hp 9-10 drill arms first) and loses
  to thicket_fang because MULTI auto-lowest-HP finds its thinnest bits. Steadfast beats whirligig
  on part-HP depth (hp 12-22 bodies + two cheap braces + restore absorb the chip race) and loses
  to silksteel because spd 0-2 never denies the core-capable scalpel.
- SMOKE_CATALOG PINS EXTENDED HONESTLY: catalog size pin 70 -> 95 (merged catalog now 100), body
  pool pin 55 -> 85 (now 89). parts/catalog_extra.json 70 -> 90 entries; base fixtures untouched.

## VERIFY-LANE TUNING ITERATION 1 (2026-07-19, sim_roster run 1 on the 100-bit catalog)

Run 1 measured all 20 new bits. In-band 15/20; the six wheel-edge numbers (family_matrix, own
win rate): carillon vs grumble_co 0.300 FAIL (need >= 0.55; 18/30 stalls, ZERO outright wins -
the greedy signature build seats Muffle Mitt rank 18 over Peal Cannon rank 15 in ARM_R, so the
anti-wall SINGLE never enters the build), carillon vs whirligig 0.500 FAIL (need <= 0.45),
larkabout vs boldheart 0.767 PASS, larkabout vs thicket_fang 0.167 PASS, steadfast vs whirligig
0.500 FAIL (need >= 0.55), steadfast vs silksteel 0.733 FAIL (need <= 0.45 - silksteel's own
family build is measured lens-floor dead, losing 0.00-0.27 to every wave-1 pole, so this edge
cannot be bought from the steadfast side without wrecking its BEATS edge; council item).

One bounded iteration, every change with the number that forced it:

| Bit | Change (old -> new) | Forced by |
|---|---|---|
| steadfast_gallant_arm_rocketfist | attack 6 -> 5 | mean_delta +24.1 over the +18 hard cap (Sniper +40.8 / Tempo +47.5 dead-template inflation, Nuke +1.7 / Wall +5.4 honest - same SUSPECT-magnitude shape as bedrock D2, but the cap binds). Budget 18.6 -> 16.6 (raw 20 -> 18; 18+5-6.4), 1.4 under the RARE floor - accepted as the deliberate price of the cap breach |
| carillon_cadets_arm_peal | max_hp 10 -> 14 | the 0.300 grumble edge: hp 14 lifts greedy rank 15 -> 19 past Muffle 18 so Peal seats in ARM_R of the signature build; also lesson-1 part-HP floor. Budget 18 -> 20 (RARE 18-22) |
| carillon_cadets_arm_muffle | guard_amount 5 -> 6 (RARE cap 6), mana_cost 2 -> 1 | mean_delta -17.8 below -5; ability-side only so greedy rank stays 18 and Muffle stops displacing Peal. Budget 19.7 -> 21.7 (RARE 18-22). Residual expected: GUARD arms sit at the measured AI-lens floor (slab_pauldron -11.6 precedent) |
| carillon_cadets_arm_ding | power 4 -> 5 (COMMON cap 5), weight 18 -> 20 | mean_delta -6.6 below -5. Budget 16.9 -> 18.0 (COMMON top). No strict dominance vs everykit fist (trades atk 4 / def 1 for spd 2 / p5 / lighter) |
| larkabout_skyworks_arm_catchhand | power 4 -> 5 (COMMON cap 5) | mean_delta -17.2. Budget 16.3 -> 17.8. Residual expected (weefist-shape light-arm floor, D11) |
| steadfast_gallant_arm_signalglove | max_hp 11 -> 13, power 2 -> 3 | mean_delta -20.2, the wave's deepest miss. Budget 15 -> 17.5. Residual expected (utility feather arm, D11) |

NOT touched, logged for the council: gantry greaves read exactly +18.0 at the cap (Sniper +31.7
floor-repair inflation, Wall +4.2 honest - the bedrock-D2 measurement shape); the steadfast
signature build rejects Twin Rocketfist on weight (needs w <= 13 to fit beside Beacon w26 +
Gallant Core w22 + Gantry w30 within capacity 112) so the volley identity never reaches the
family matrix; silksteel edge above.

## D1 APPLIED (coordinating lead, 2026-07-19, post-verify-lane)
The wave-1 pre-ratified thicket shave was executed after the verify lane's tripwire red (T0 Thornlash overgrown Gleaming 0.42 vs >= 0.50). Condition check: pentagon_v2 (200 seeds, core-aiming + GUARD policy) shows thicket >= 0.75 on exactly 3 edges (0.9775 grumble / 0.91 whirligig / 1.00 silksteel) - condition MET. Changes: thicket_fang_arm_goreclaw hit_count 4 -> 3; thicket_fang_arm_flenseclaw hit_count 5 -> 4. Result: smoke_kit_sim SMOKE PASS exit 0 (all 31 checks incl. the failed lane), smoke_catalog + smoke_combat green. Roster deltas for the two shaved bits should be re-read in the next council pass.
