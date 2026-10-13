# Project status: where we left off

Last updated: 2026-10-13. Branch: `claude/busy-volta-8n680m`.

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

## In progress (2026-10-13)

* **Polish**: partial art-director passes landed on the 8 remaining characters (all 12 now
  pass validation with no errors or animation warnings).
* **Boss pass**: `tools/agents/boss-audit.js` is running. It writes `tools/charlab/STYLE_GUIDE.md`
  and a fix list per character. Next, run `boss-fix-one.js` once per character (in parallel),
  then `boss-signoff.js` (repeat fix + sign-off for anything not approved).
* **Phase 2**: the framework is done (RoomService, RoomsClient, scenes, title hook, WheelSpin
  product, contracts in [`PHASE2_CONTRACTS.md`](PHASE2_CONTRACTS.md)). Five workstreams are
  running with `tools/agents/phase2-stream.js`: WORLD (islands/rivers/portals/economy), TITLE,
  OBBY (NYC rooftop), FISHING (Alaska), WHEEL (Venice). After they finish, run a whole-game
  integration review, then rebuild the place file.

## Still to do afterwards

* Preview-tool polish (low): overlapping transparent parts can hide each other in charlab
  renders; `k:Mirror` doesn't mirror Text faces or particle Direction.

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
