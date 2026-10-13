export const meta = {
  name: 'brainrot-boss-signoff',
  description: 'Boss art director re-reviews all 12 brainrots together and approves or sends back',
  phases: [{ title: 'Boss sign-off', detail: 'side-by-side review against STYLE_GUIDE.md' }],
}

const ROOT = '/home/user/Biotekk127.github.io/roblox-tycoon'
const SCRATCH = '/tmp/claude-0/-home-user-Biotekk127-github-io/4d08037e-7900-5ca9-9d94-2f5094d117f5/scratchpad'
const LUAU = `${SCRATCH}/tools/luau`
const OUT = `${SCRATCH}/boss-signoff-${args.round}`

const SCHEMA = {
  type: 'object',
  properties: {
    approvedAll: { type: 'boolean' },
    summary: { type: 'string' },
    characters: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          id: { type: 'string' },
          approved: { type: 'boolean' },
          score: { type: 'number' },
          remainingFixes: { type: 'array', items: { type: 'string' } },
        },
        required: ['id', 'approved', 'score', 'remainingFixes'],
      },
    },
  },
  required: ['approvedAll', 'summary', 'characters'],
}

phase('Boss sign-off')
return await agent(`You are the BOSS ART DIRECTOR for "Brainrot Factory Tycoon" doing sign-off round ${args.round}. Earlier you wrote ${ROOT}/tools/charlab/STYLE_GUIDE.md and fixer agents applied your fix lists to the 12 Italian brainrot replicas in ${ROOT}/src/shared/Characters/. Do NOT edit any files.

Render everything:
  cd ${ROOT} && python3 tools/charlab/check_all.py --luau ${LUAU} --out ${OUT}
  python3 tools/charlab/lineup.py ${OUT} --out ${OUT}/lineup-34.png
  python3 tools/charlab/lineup.py ${OUT} --out ${OUT}/lineup-front.png --view front
  python3 tools/charlab/lineup.py ${OUT} --out ${OUT}/lineup-closeup.png --view closeup
Read the lineups and every contact sheet. Judge: does the set read as ONE consistent premium family at the same very high level of detail (scaled by rarity), is every character an instantly recognisable replica of its meme, are there zero validation errors and zero ANIM warnings?

Approve a character only if it meets the style guide. For anything not approved, give remainingFixes: specific, actionable instructions a fixer can execute without seeing your renders. approvedAll = true only if all 12 are approved.`, { label: `boss:signoff-${args.round}`, phase: 'Boss sign-off', schema: SCHEMA })
