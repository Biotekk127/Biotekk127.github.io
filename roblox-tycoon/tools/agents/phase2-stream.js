export const meta = {
  name: 'phase2-stream',
  description: 'Build one Phase 2 workstream, review it from two independent angles, then fix',
  phases: [
    { title: 'Build', detail: 'implement the workstream in its owned files' },
    { title: 'Review', detail: 'engine/security reviewer + design/spec reviewer' },
    { title: 'Fix', detail: 'apply confirmed review findings' },
  ],
}

const ROOT = '/home/user/Biotekk127.github.io/roblox-tycoon'
const SCRATCH = '/tmp/claude-0/-home-user-Biotekk127-github-io/4d08037e-7900-5ca9-9d94-2f5094d117f5/scratchpad'
const s = args.stream
const WORK = `${SCRATCH}/p2-${s.id}`

const COMMON = `You are working on "Brainrot Factory Tycoon", a Roblox tycoon (Luau, Rojo layout) in ${ROOT}. It features hand-built Italian brainrot characters. Phase 2 is being built by several agents IN PARALLEL, each owning specific files.

READ FIRST (mandatory):
- ${ROOT}/docs/PHASE2_PLAN.md   (what the player-facing features are)
- ${ROOT}/docs/PHASE2_CONTRACTS.md   (file ownership, APIs, tooling commands, scene format - binding)
- ${ROOT}/tools/charlab/CHARACTER_GUIDE.md   (builder API used for scenes)
- ${ROOT}/README.md and the existing code your files interact with.

YOUR WORKSTREAM: ${s.name}
FILES YOU OWN (edit only these): ${s.owns}
Use ${WORK}/ for scratch output (renders, sourcemaps, test builds) - create it. Never write the repo's BrainrotFactoryTycoon.rbxlx and never commit.

WORKSTREAM BRIEF:
${s.brief}`

const BUILD_SCHEMA = {
  type: 'object',
  properties: {
    summary: { type: 'string' },
    filesChanged: { type: 'array', items: { type: 'string' } },
    verification: { type: 'string' },
    frameworkRequests: { type: 'array', items: { type: 'string' } },
    knownLimitations: { type: 'array', items: { type: 'string' } },
  },
  required: ['summary', 'filesChanged', 'verification', 'frameworkRequests'],
}
const REVIEW_SCHEMA = {
  type: 'object',
  properties: {
    findings: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          file: { type: 'string' },
          severity: { type: 'string', enum: ['critical', 'high', 'medium', 'low'] },
          summary: { type: 'string' },
          evidence: { type: 'string' },
          fix: { type: 'string' },
        },
        required: ['file', 'severity', 'summary', 'evidence', 'fix'],
      },
    },
    overall: { type: 'string' },
  },
  required: ['findings', 'overall'],
}
const FIX_SCHEMA = {
  type: 'object',
  properties: {
    fixed: { type: 'array', items: { type: 'string' } },
    rejected: { type: 'array', items: { type: 'string' } },
    verification: { type: 'string' },
    frameworkRequests: { type: 'array', items: { type: 'string' } },
  },
  required: ['fixed', 'rejected', 'verification', 'frameworkRequests'],
}

phase('Build')
const built = await agent(`${COMMON}

YOUR JOB (builder): implement the whole workstream to a polished, shippable standard.
- Server-authoritative: the server decides rewards, validates every client request, rate-limits, and never trusts client timing or positions without checks.
- Visual quality matters as much as code: ${s.visual}
- Verify before finishing: luau-lsp type-check with zero new errors/warnings in your files, unit tests pass, rojo build succeeds, scenes render cleanly with charlab --scene (Read the PNGs and iterate on the look several times).
- If you need a change outside your files, do NOT make it; list it in frameworkRequests and work around it.
Return the structured summary.`, { label: `build:${s.id}`, phase: 'Build', schema: BUILD_SCHEMA })

phase('Review')
const builtNote = built ? `The builder reported: ${built.summary}\nFiles: ${built.filesChanged.join(', ')}\nKnown limitations: ${(built.knownLimitations || []).join('; ')}` : 'The builder failed to report; inspect the files directly.'
const lenses = [
  { key: 'engine', text: 'LENS: Roblox engine/API correctness and security. Check every API, property, enum and event exists and behaves as used; server/client boundaries; replication timing; exploits (client-trusted values, missing validation, rate limits, reward farming, teleport abuse); memory/connection leaks; performance (part counts, per-frame work); data persistence safety; interaction with the framework (RoomService/RoomsClient/PlayerService/PlotService contracts). Run the type-checker and build yourself.' },
  { key: 'design', text: 'LENS: player experience and fidelity to the brief/plan. Is every feature in the brief actually implemented and fun? Theme fidelity (render the scenes with charlab --scene and look - does it read as the intended place?), clarity of UI on desktop and mobile, feedback/juice, onboarding, rewards balanced against the economy (Economy.ScaledReward), edge cases a player will hit (rejoining, dying, leaving mid-action, multiple players at once).' },
]
const reviews = await parallel(lenses.map(l => () => agent(`${COMMON}

${builtNote}

You are an independent REVIEWER. Do not edit any files. ${l.text}
Report only real, specific problems with evidence (file, what happens, how you know) and a concrete fix. Be thorough and demanding.`, { label: `review:${s.id}:${l.key}`, phase: 'Review', schema: REVIEW_SCHEMA })))

const findings = reviews.filter(Boolean).flatMap(r => r.findings)
log(`${s.id}: ${findings.length} review findings`)

phase('Fix')
const fixed = findings.length === 0 ? { fixed: [], rejected: [], verification: 'no findings', frameworkRequests: [] } : await agent(`${COMMON}

${builtNote}

Two independent reviewers reported these findings on your workstream:
${findings.map((f, i) => `${i + 1}. [${f.severity}] ${f.file}: ${f.summary}\n   Evidence: ${f.evidence}\n   Suggested fix: ${f.fix}`).join('\n')}

YOUR JOB (fixer): verify each finding against the code. Fix every real one (critical/high first). Reject false positives with a one-line reason. Re-run the full verification (type-check, tests, rojo build, scene renders - Read them) and return the structured result.`, { label: `fix:${s.id}`, phase: 'Fix', schema: FIX_SCHEMA })

return { stream: s.id, built, findings, fixed }
