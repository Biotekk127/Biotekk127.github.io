export const meta = {
  name: 'brainrot-polish',
  description: 'Fresh-eyes art-director polish of one Italian brainrot character (accuracy first, then detail)',
  phases: [{ title: 'Polish', detail: 'critique, then improve and re-render' }],
}

const ROOT = '/home/user/Biotekk127.github.io/roblox-tycoon'
const LUAU = '/tmp/claude-0/-home-user-Biotekk127-github-io/4d08037e-7900-5ca9-9d94-2f5094d117f5/scratchpad/tools/luau'
const PREVIEWS = '/tmp/claude-0/-home-user-Biotekk127-github-io/4d08037e-7900-5ca9-9d94-2f5094d117f5/scratchpad/previews'
const c = args.character
const file = `${ROOT}/src/shared/Characters/${c.id}.luau`

const POLISH_SCHEMA = {
  type: 'object',
  properties: {
    id: { type: 'string' },
    problemsFound: { type: 'array', items: { type: 'string' } },
    changesMade: { type: 'array', items: { type: 'string' } },
    partCount: { type: 'number' },
    miniParts: { type: 'number' },
    validationErrors: { type: 'number' },
    animWarnings: { type: 'number' },
    scoreBefore: { type: 'number' },
    scoreAfter: { type: 'number' },
    remainingConcerns: { type: 'array', items: { type: 'string' } },
  },
  required: ['id', 'problemsFound', 'changesMade', 'partCount', 'miniParts', 'validationErrors', 'animWarnings', 'scoreBefore', 'scoreAfter'],
}

phase('Polish')
const result = await agent(`You are the fresh-eyes ART DIRECTOR for one character in "Brainrot Factory Tycoon", a Roblox tycoon whose droppers are topped by showcase replicas of the famous Italian brainrot meme characters (each stands on a rarity pedestal; a 12-part "mini" rides the conveyor).

CHARACTER: ${c.name} (Id "${c.id}", Rarity ${c.rarity})
CANONICAL LOOK (from the original brief): ${c.brief}
STATE: ${c.state}

The file was built by another agent. You did not build it: judge it harshly, then make it great.

READ FIRST:
- ${ROOT}/tools/charlab/CHARACTER_GUIDE.md (contract, builder API, limits, art direction - follow exactly)
- ${file} (the file you own; edit only this file, keep it self-contained plain Luau with no require/Roblox globals)

PREVIEW + VALIDATE after every meaningful change:
  cd ${ROOT} && python3 tools/charlab/charlab.py ${file} --out ${PREVIEWS}/${c.id}.png --luau ${LUAU}
then open the PNG with the Read tool and look at every tile. The report now also sweeps the idle animation: ANIM warnings (sinking into the ground, growing above 9.5, swinging outside the -3.2..3.2 footprint) must be fixed too.

PART BUDGET: the ${c.rarity} target is ${c.target} parts in Build (the guide's minimum is a floor, not a cap; the hard maximum is 400). Mini: 6-12 parts.

YOUR JOB:
1. WebSearch the canonical look of "${c.name}" (italian brainrot / Steal a Brainrot; image downloads are blocked, text works) and list its defining features. Never add real brand logos.
2. Render the current file, score it 1-10 as a faithful premium Roblox showcase replica (scoreBefore), and write a critique of AT LEAST 8 concrete problems, in this priority order:
   a) ACCURACY to the meme: wrong anatomy, colours, outfit, props, proportions, missing signature features;
   b) face appeal (eye whites/pupils/highlights, brows, mouth) and silhouette readability from 40 studs;
   c) detail density and layering (is it truly EXCESSIVELY detailed for a ${c.rarity}?), back/side/top finish;
   d) rarity flair appropriate to ${c.rarity} without altering the canonical design;
   e) animation: enough animated elements, joints pivot correctly in the pose tiles, calm loopable speeds, phase offsets, and ZERO ANIM warnings;
   f) the mini's readability; technical issues (gaps, floating bits, parts poking through the face, wrong cylinder axis, wedge orientation).
3. Fix everything directly in the file, accuracy first. Re-render and Read the PNG after each batch. At least 3 render-review cycles.
4. Finish with 0 validation errors and 0 ANIM warnings. Score it again (scoreAfter) and list remaining concerns honestly.`,
  { label: `polish:${c.id}`, phase: 'Polish', schema: POLISH_SCHEMA })
return result
