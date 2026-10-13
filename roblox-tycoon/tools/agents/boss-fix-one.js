export const meta = {
  name: 'brainrot-boss-fix',
  description: 'Apply the boss style guide and fix list to one brainrot character',
  phases: [{ title: 'Boss fixes', detail: 'apply STYLE_GUIDE.md + fix list, render-verify' }],
}

const ROOT = '/home/user/Biotekk127.github.io/roblox-tycoon'
const SCRATCH = '/tmp/claude-0/-home-user-Biotekk127-github-io/4d08037e-7900-5ca9-9d94-2f5094d117f5/scratchpad'
const LUAU = `${SCRATCH}/tools/luau`
const c = args.character
const file = `${ROOT}/src/shared/Characters/${c.id}.luau`

const SCHEMA = {
  type: 'object',
  properties: {
    id: { type: 'string' },
    applied: { type: 'array', items: { type: 'string' } },
    skipped: { type: 'array', items: { type: 'string' } },
    partCount: { type: 'number' },
    miniParts: { type: 'number' },
    validationErrors: { type: 'number' },
    animWarnings: { type: 'number' },
    notes: { type: 'string' },
  },
  required: ['id', 'applied', 'skipped', 'partCount', 'miniParts', 'validationErrors', 'animWarnings'],
}

phase('Boss fixes')
return await agent(`You are a character fixer for "Brainrot Factory Tycoon". The boss art director reviewed all 12 Italian brainrot replicas side by side and wrote a house style guide plus a fix list for your character. Apply them.

CHARACTER: ${c.id} (${c.name || c.id})
YOUR BOSS FIX LIST: open ${SCRATCH}/boss-fixlists.json and find the entry whose "id" is "${c.id}". It has the boss's scores, "targetParts", "mustFix" and "shouldFix". Treat that entry as your assignment.
${c.extra ? '\nADDITIONAL NOTES FROM THE BOSS SIGN-OFF:\n' + c.extra : ''}

READ FIRST: ${ROOT}/tools/charlab/STYLE_GUIDE.md (binding house style), ${ROOT}/tools/charlab/CHARACTER_GUIDE.md (API + limits), then ${file} (the only file you may edit; keep it self-contained plain Luau).

Preview after every meaningful change and Read the PNG:
  cd ${ROOT} && python3 tools/charlab/charlab.py ${file} --out ${SCRATCH}/boss/fix-${c.id}.png --luau ${LUAU}

Rules: apply every must-fix; apply should-fixes unless they would hurt accuracy to the meme (then list them under skipped with the reason). Never drift from the canonical meme design. Do at least 3 render-review cycles. Finish with 0 validation errors and 0 ANIM warnings, and stay within the target part range (never above the validator's hard cap of 400).`, { label: `fix:${c.id}`, phase: 'Boss fixes', schema: SCHEMA })
