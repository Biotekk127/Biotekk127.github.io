# Project status: where we left off

Last updated: 2026-10-12. Branch: `claude/busy-volta-8n680m`.

To resume in a new session, say: **"Continue the Roblox tycoon from roblox-tycoon/docs/STATUS.md"**.

## Done and playable

* Complete tycoon: plots, droppers, upgraders, rebirths, events, daily/playtime rewards,
  codes, offline earnings, game passes and products, saving, leaderboard.
* Character system: `src/shared/CharacterKit.luau`, rarity pedestals (`server/RarityFX.luau`),
  client animator (`client/Animator.luau`), conveyor minis, Gold/Diamond/Rainbow mutations.
* **Brainrot Index** (📖 menu): 48 collectible character × variant combos, +0.5% cash each.
* **All 12 Italian brainrot characters built**, validated (0 errors) and wired into the game:

| Character | Rarity | Parts | Polish pass |
|---|---|---|---|
| Lirilì Larilà | Common | 100 | ✅ done |
| Boneca Ambalabu | Common | 100 | ✅ done |
| Brr Brr Patapim | Uncommon | 130 | ✅ done |
| Trippi Troppi | Uncommon | 129 | ❌ not started |
| Tung Tung Tung Sahur | Rare | 167 | ✅ done |
| Cappuccino Assassino | Rare | 176 | ⚠️ partial |
| Chimpanzini Bananini | Epic | 211 | ⚠️ partial |
| Frigo Camelo | Epic | 215 | ⚠️ partial |
| Ballerina Cappuccina | Legendary | 260 | ⚠️ partial |
| Bombardiro Crocodilo | Legendary | 260 | ❌ not started |
| Tralalero Tralala | Mythic | 272 | ❌ not started |
| La Vacca Saturno Saturnita | Secret | 356 | ⚠️ partial |

"Partial" = the polish agent was stopped by a usage limit mid-way; its edits were kept
because they render as good or better than the pre-polish version.

* Review fixes applied: Index viewports no longer animate while hidden, silhouettes stay
  still, pedestal aura particles rise correctly, particle Direction can't crash a build.

## Next steps (in order)

1. **Finish polish** for the 8 characters marked ❌/⚠️ above (one fresh-eyes art-director
   agent each, accuracy to the meme first). The workflow script that did this is described in
   the session; it is a create → polish pipeline per character.
2. **Boss consistency pass**: one art-director agent reviews all 12 side by side and writes a
   shared style guide (eyes/faces, colour saturation, material/glow use, animation feel,
   detail density per rarity) plus a fix list per character → fixers apply in parallel → boss
   signs off. Note: the Commons were capped at about 100 parts because agents treated the
   target as a maximum; lift them to match the detail of the others.
3. **Tooling fixes** from the review (preview tool only, not the game):
   * `mockkit.luau`: a Build with zero parts passes validation; bounds use box corners even for
     rotated round parts (false errors); bounds are only checked in the rest pose, not across
     the animation.
   * `charlab.py`: overlapping transparent parts can hide each other in previews.
   * `CharacterKit` Mirror: face-direction features (Text faces, particle Direction) aren't
     mirrored (low).
4. **Phase 2**: see [`PHASE2_PLAN.md`](PHASE2_PLAN.md): rarity portals with rarity-scaled
   spawn speed, floating islands with personal brainrot rivers, a cinematic title flyover under 3s,
   and 3 themed lobby rooms (NYC-rooftop obby, Alaska ice fishing, Venice carnival spin wheel).

## Tooling setup (fresh machine)

```bash
# Luau CLI + Rojo (Linux)
curl -sSL -o luau.zip https://github.com/luau-lang/luau/releases/latest/download/luau-ubuntu.zip && unzip luau.zip
curl -sSL -o rojo.zip https://github.com/rojo-rbx/rojo/releases/download/v7.4.4/rojo-7.4.4-linux-x86_64.zip && unzip rojo.zip
pip install numpy pillow

cd roblox-tycoon
python3 tests/run_tests.py ./luau                          # 108 unit tests
python3 tools/charlab/check_all.py --luau ./luau --out previews/   # validate + render all characters
./rojo build default.project.json -o BrainrotFactoryTycoon.rbxlx    # rebuild the place file
```
