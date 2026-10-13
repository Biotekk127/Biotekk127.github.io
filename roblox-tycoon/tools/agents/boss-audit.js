export const meta = {
  name: 'brainrot-boss-audit',
  description: 'Boss art director audits all 12 brainrots side by side, writes a shared style guide and per-character fix lists',
  phases: [{ title: 'Boss audit', detail: 'review all 12 together, write STYLE_GUIDE.md + fix lists' }],
}

const ROOT = '/home/user/Biotekk127.github.io/roblox-tycoon'
const SCRATCH = '/tmp/claude-0/-home-user-Biotekk127-github-io/4d08037e-7900-5ca9-9d94-2f5094d117f5/scratchpad'
const LUAU = `${SCRATCH}/tools/luau`
const OUT = `${SCRATCH}/boss`

const SCHEMA = {
  type: 'object',
  properties: {
    summary: { type: 'string' },
    characters: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          id: { type: 'string' },
          accuracy: { type: 'number' },
          detail: { type: 'number' },
          consistency: { type: 'number' },
          targetParts: { type: 'string' },
          mustFix: { type: 'array', items: { type: 'string' } },
          shouldFix: { type: 'array', items: { type: 'string' } },
        },
        required: ['id', 'accuracy', 'detail', 'consistency', 'targetParts', 'mustFix', 'shouldFix'],
      },
    },
  },
  required: ['summary', 'characters'],
}

phase('Boss audit')
return await agent(`You are the BOSS ART DIRECTOR for "Brainrot Factory Tycoon", a Roblox tycoon whose 12 droppers each show a hand-built replica of a famous Italian brainrot meme character on a rarity pedestal (Common -> Uncommon -> Rare -> Epic -> Legendary -> Mythic -> Secret). Each character was built and polished by a DIFFERENT agent, so styles and detail levels drifted. Your job: make the 12 read as ONE consistent, premium set at the same very high level of detail, while each stays an accurate replica of its meme.

FILES:
- Guide: ${ROOT}/tools/charlab/CHARACTER_GUIDE.md
- Characters: ${ROOT}/src/shared/Characters/*.luau (read them all - you are reviewing code AND renders)
- Do NOT edit any character file. The only file you create is ${ROOT}/tools/charlab/STYLE_GUIDE.md.

RENDER EVERYTHING:
  cd ${ROOT} && python3 tools/charlab/check_all.py --luau ${LUAU} --out ${OUT}
  python3 tools/charlab/lineup.py ${OUT} --out ${OUT}/lineup-34.png
  python3 tools/charlab/lineup.py ${OUT} --out ${OUT}/lineup-front.png --view front
  python3 tools/charlab/lineup.py ${OUT} --out ${OUT}/lineup-closeup.png --view closeup
Read the lineups and EVERY individual contact sheet in ${OUT}. Use WebSearch if you need to confirm a character's canonical look (image downloads are blocked).

STEP 1 - Write ${ROOT}/tools/charlab/STYLE_GUIDE.md: a concrete, measurable house style that all 12 must follow. Derive it from the BEST-executed characters in the set. Cover at least:
- Faces/eyes: construction recipe (eye white + iris + pupil + 1-2 Neon catch-lights, lids/lashes/brows, how eyes sit on curved surfaces), relative eye size to head, blink rules.
- Colour: saturation/brightness range, use of tinted darks instead of black, palette size (dominant/secondary/accent), outline/seam treatment.
- Materials: when to use SmoothPlastic vs Glass/Foil/Neon/ForceField; glow budget per rarity.
- Shape language: smooth organic forms from overlapping ellipsoids, no visible "segmented sausage" joins, how limbs blend at joints.
- Detail density: the required part ranges per rarity for THIS set (lift the Commons - they were wrongly capped at 100 and look sparser than the rest; every tier should feel excessively detailed, higher tiers more so), and what "tertiary detail" means (seams, rivets, freckles, stitches, scales, highlights).
- Animation: number of animated elements per rarity, speed ranges, required idle breathing/bob + blink + one signature motion, phase offsets, zero ANIM warnings.
- Rarity flair per tier (lights/particles/neon/orbiting elements) without altering the canonical design.
- Mini: readability rules for the 12-part conveyor version.
- Scale/proportion consistency: how much of the 9.5 x 6.4 x 6.4 volume a character should fill, so none looks tiny or cramped next to its neighbours.

STEP 2 - Audit each of the 12 against the style guide and against its meme. For each: scores 1-10 for accuracy, detail, consistency; a targetParts range; mustFix (specific, actionable, file-level instructions a fixer agent can execute without seeing your renders - name the parts/sections and what to change) and shouldFix. Be demanding: every character, including the best ones, should get concrete improvements that lift it to the house style.

Return the structured result.`, { label: 'boss:audit', phase: 'Boss audit', schema: SCHEMA })
