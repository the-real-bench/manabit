export const meta = {
  name: 'manabit-bits',
  description: 'Procedurally generate spec-legal PS1 low-poly .glb bits for MANABIT from their manifest prompts (blender-mcp)',
  whenToUse: 'Generate one/many/all of the 77 MANABIT bits as art/bits/<id>.glb. args = an array of bit ids, or a string: a single id, a family name, or "all".',
  phases: [
    { title: 'Scope',  detail: 'resolve args -> ordered list of bit ids to build' },
    { title: 'Build',  detail: 'one builder agent per bit, SERIAL (shared Blender), lib + manifest -> glb' },
    { title: 'Verify', detail: 'per-bit render-vs-spec check (parallel, reads PNGs only)' },
    { title: 'Audit',  detail: 'headless Godot asset-audit over the whole catalog' },
  ],
}

const REPO = 'G:\\\\ClaudeAgents\\\\my-game\\\\.claude\\\\manabit'
const LIB = REPO + '\\\\tools\\\\art\\\\manabit_bit_lib.py'
const GUIDE = REPO + '\\\\tools\\\\art\\\\RECIPE_GUIDE.md'
const MANIFEST = REPO + '\\\\design\\\\art\\\\asset-manifest.md'
const SHOT = 'G:\\\\ClaudeData\\\\tmp\\\\claude\\\\manabit-bits'

const BUILD_SCHEMA = {
  type: 'object', additionalProperties: false,
  required: ['id', 'tris', 'materials', 'in_budget', 'render_path', 'ok', 'notes'],
  properties: {
    id: { type: 'string' },
    tris: { type: 'integer' },
    materials: { type: 'integer' },
    in_budget: { type: 'boolean' },
    render_path: { type: 'string', description: 'absolute path to the EEVEE 3/4 render saved for verify' },
    ok: { type: 'boolean', description: 'builder is confident it reads as the slot + matches the family/glow' },
    notes: { type: 'string' },
  },
}
const VERDICT_SCHEMA = {
  type: 'object', additionalProperties: false,
  required: ['id', 'reads_as_slot', 'hue_ok', 'glow_ok', 'verdict', 'issues'],
  properties: {
    id: { type: 'string' },
    reads_as_slot: { type: 'boolean' },
    hue_ok: { type: 'boolean' },
    glow_ok: { type: 'boolean' },
    verdict: { type: 'string', enum: ['PASS', 'REVISE'] },
    issues: { type: 'array', items: { type: 'string' } },
  },
}
const IDS_SCHEMA = {
  type: 'object', additionalProperties: false, required: ['ids'],
  properties: { ids: { type: 'array', items: { type: 'string' } } },
}

// ---- Scope: resolve args to an ordered id list --------------------------------
phase('Scope')
let ids = []
if (Array.isArray(args)) {
  ids = args.map(String)
} else {
  const raw = String(args == null ? 'all' : args)
  const scoped = await agent(
    `You are scoping a MANABIT art run. The requested target is: "${raw}".\n` +
    `Read ${MANIFEST} and ${REPO}\\\\parts\\\\catalog_extra.json. Return the ordered list of bit ids to build:\n` +
    `- if the target is "all": every bit id, in the manifest's 12-batch production-priority order.\n` +
    `- if the target names a family (e.g. "boldheart", "grumble_co", "whirligig"): that family's bit ids.\n` +
    `- if the target is a single id (e.g. "core_bulwark"): just that id.\n` +
    `Return ONLY ids that are real catalog bits.`,
    { label: 'scope', phase: 'Scope', schema: IDS_SCHEMA })
  ids = (scoped && scoped.ids) || []
}
if (!ids.length) { log('no bit ids resolved - nothing to build'); return { built: [], note: 'empty scope' } }
log(`building ${ids.length} bit(s): ${ids.slice(0, 12).join(', ')}${ids.length > 12 ? ' …' : ''}`)

// ---- Build: SERIAL (one shared Blender instance) ------------------------------
phase('Build')
const built = []
for (let i = 0; i < ids.length; i++) {
  const id = ids[i]
  const r = await agent(
    `Author the MANABIT bit "${id}" as a GUNPLA-ESQUE enchanted-toy glb using blender-mcp (Blender is already open).\n` +
    `QUALITY BAR (non-negotiable): it must read as a detailed gundam-plastic-kit part - layered armor plates, ` +
    `panel lines, greebles (nozzles/bolts/fins/vents), a glowing sensor/lens, 3-5 colors, crisp beveled edges - ` +
    `NOT a flat color block. Read the guide's "GUNPLA DETAIL" section AND its reference images before building.\n\n` +
    `FIRST load these tools in ONE ToolSearch call:\n` +
    `  select:mcp__blender-mcp__execute_blender_code,mcp__blender-mcp__get_objects_summary\n` +
    `Then Read your two references:\n` +
    `  1. ${GUIDE}  (the lib API, the socket-origin-per-slot table, the core_ember golden example, the done checklist)\n` +
    `  2. the "${id}" entry in ${MANIFEST}  (its family, slot, rarity, silhouette, and which part glows)\n\n` +
    `Then, driving Blender via execute_blender_code:\n` +
    `  - exec the lib: exec(open(r"${LIB}").read())\n` +
    `  - SILHOUETTE FIRST (this is where agents fail): block out ONLY the major masses, finalize, render, and confirm the shape reads UNMISTAKABLY as the ${id} slot from a glance - an ARM reads as a limb+end-effector (NOT a monument/totem/pedestal), a BACK reads as a pack (NOT a figurine). If it reads wrong, fix proportions/orientation BEFORE any detail. A detailed bit with the wrong silhouette is a FAIL.\n` +
    `  - THEN build the Bit("${id}", family=…, rarity=…, slot=…) recipe of primitives; paint each region a palette ROLE; add greebles (panels/bolts/nozzles/fins) + b.socket_collar(...).\n` +
    `  - res = b.finalize(socket=<the slot's plug point>, cleanup=False)\n` +
    `  - INSPECT res: tris must be 300-2400, materials==1, warnings==[]. Detailed bits land ~1200-2200; if <300 add detail; if >2400 drop segment counts (not detail).\n` +
    `  - LOOK: render EEVEE 3/4 (per the guide's render snippet) to ${SHOT}\\\\${id}.png and Read it. Confirm the silhouette reads as the ${id} slot, the family hue is right, and the glowing part glows. Fix the worst issue and re-finalize. Iterate up to ~6 times.\n` +
    `  - The glb auto-exports to art/bits/${id}.glb on every finalize.\n\n` +
    `Build ONLY this one bit. Do not touch other scene objects (the lib isolates its own). ` +
    `Return the build result. render_path = the PNG you saved.`,
    { label: `build:${id}`, phase: 'Build', schema: BUILD_SCHEMA })
  if (r) { built.push(r); log(`  ${id}: ${r.tris} tris, ${r.materials} mat, ${r.ok ? 'reads ok' : 'NEEDS REVIEW'}`) }
  else { log(`  ${id}: builder returned nothing`) }
}

// ---- Verify: parallel, reads the saved PNGs only (no Blender) -----------------
phase('Verify')
const verdicts = (await parallel(built.map(bd => () =>
  agent(
    `Adversarially verify the MANABIT bit render at ${bd.render_path} against its spec.\n` +
    `Read the "${bd.id}" entry in ${MANIFEST} for the intended silhouette/family/rarity/glow, then Read the PNG.\n` +
    `Judge strictly: does the silhouette read as the correct SLOT (head/arm/legs/core/back) from a glance? ` +
    `Is the family hue right? Does the part that should glow actually glow? Is the tone cozy-craft toy (not horror/circuitry)?\n` +
    `Default reads_as_slot/hue_ok/glow_ok to false if you are not sure. verdict=REVISE if any core read is wrong.`,
    { label: `verify:${bd.id}`, phase: 'Verify', schema: VERDICT_SCHEMA })
))).filter(Boolean)

// ---- Audit: deterministic Godot gate over the whole catalog -------------------
phase('Audit')
const audit = await agent(
  `Run the MANABIT headless art audit and report the result verbatim.\n` +
  `Load Bash. Run, from ${REPO}:\n` +
  `  GODOT="/c/Users/Stream Boi/Downloads/Godot_v4.6.1-stable_win64.exe/Godot_v4.6.1-stable_win64.exe"\n` +
  `  "$GODOT" --headless --path . --import >/dev/null 2>&1; "$GODOT" --headless --path . --script res://tests/smoke_art.gd 2>&1 | tail -40\n` +
  `Return the coverage line, the PASS/FAIL line, and any per-bit FAIL rows.`,
  { label: 'audit', phase: 'Audit' })

const revise = verdicts.filter(v => v.verdict === 'REVISE').map(v => v.id)
log(`done. built ${built.length}, flagged for revise: ${revise.length ? revise.join(', ') : 'none'}`)
return { built, verdicts, audit, revise }
