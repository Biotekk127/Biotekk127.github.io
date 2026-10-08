# Phase 2 plan: spawning, map, title screen, lobby mini-games

Queued to start **after** the 12 brainrot characters are finished, the boss consistency
pass is done, and the WIP commits are squashed.

## 1. Spawning: rarity portals

* Each dropper becomes a **rarity portal**: a swirling ring in the brainrot's rarity colour
  (Common grey → Secret rainbow). The showcase brainrot still stands on its pedestal
  above or next to the portal.
* Spawn sequence: the portal flares, then the mini brainrot slides out onto the river.
  Higher rarities get bigger effects (Legendary+ adds a flash and a sound; Secret adds a
  screen-shake shockwave and a server-wide shout-out).
* Mutations (Gold / Diamond / Rainbow) tint the portal flash, so a rare roll is visible
  before the brainrot even comes out.

## 2. Spawn speed: rarity-scaled

Rarer brainrots spawn less often but are worth proportionally more (draft, to be tuned
with `tools/economy_sim.py` so the current pacing of about 60 min to the first rebirth stays intact):

| Rarity | Spawn interval |
|---|---|
| Common | 1.5 s |
| Uncommon | 2 s |
| Rare | 3 s |
| Epic | 4 s |
| Legendary | 6 s |
| Mythic | 8 s |
| Secret | 12 s |

Value per drop gets re-scaled by interval so income per second follows the existing
curve. The Fast Droppers pass and Frenzy events still speed everything up.

## 3. Map: floating islands + personal brainrot rivers

* Every plot becomes a **floating sky island** connected to a central hub island by bridges.
* Each island has its **own brainrot river** (it replaces the conveyor): it starts at the
  island's portals, loops around the island, and passes the upgraders (now river
  gates/waterfalls) to the collector. Income stays automatic, so the tycoon loop and
  economy don't change.
* Below the islands: clouds, waterfalls spilling off the island edges, distant islands.
* The hub island holds the spawn, the leaderboards and the doors to the 3 mini-game rooms.

## 4. Title screen: cinematic flyover (under 3 seconds)

* On join the camera sweeps over the islands and rivers, with the logo and one big **PLAY**
  button. The player's data and plot load behind it.
* Never blocks: it auto-continues after about 3 seconds, or right away on click.
* Uses ReplicatedFirst for an instant custom loading screen.

## 5. Lobby: 3 themed mini-game rooms

Doors on the hub island. Stepping through a door plays a short transition, then
teleports you to a themed room built far away in the same server. Rewards feed back into
the tycoon (cash boosts, Index progress).

| Room | Theme | Gameplay | Rewards |
|---|---|---|---|
| 🏙️ **Brainrot Obby** | **Top of a New York City skyscraper**: rooftop at night, skyline, water towers, billboards, cranes, helipad, wind | Parkour course across rooftops, beams and billboards with brainrot obstacles (Tung Tung bat swings, Bombardiro bomb drops). Checkpoints, timer, finish line on the helipad | Cash boost + a daily first-clear bonus; best-time board |
| 🎣 **Brainrot Fishing** | **Alaska ice-fishing hole**: frozen lake, snow, pine forest, wooden fishing hut, northern lights, cold breath | Cast into ice holes and catch brainrots, with rarity and mutation odds. Catch-timing bar mini-game | Cash + chance at Index variants; rare-catch shout-outs |
| 🎡 **Spin the Wheel** | **Venice carnival**: Italian piazza at night, canals with gondolas, carnival masks, string lights, bridges | Giant prize wheel: 1 free spin per day plus paid extra spins (developer product) | Cash, boosts, Frenzy events, rare mutation charms |

## Build order (when Phase 2 starts)

1. Economy re-tune for rarity-scaled speed (simulator first).
2. Island + river world generator (replaces ring of plots / conveyor), portals.
3. Title flyover + loading screen.
4. Hub doors + room transition system.
5. The three rooms (theme build + gameplay), each built and reviewed separately.
6. Full review, tests, rebuild the place file, playtest checklist.
