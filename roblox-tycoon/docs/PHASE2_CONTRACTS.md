# Phase 2 contracts (for parallel workstreams)

Read with [`PHASE2_PLAN.md`](PHASE2_PLAN.md). Five workstreams run **in parallel**, so each
one owns a fixed set of files. **Only edit the files you own.** If you need a change in a
file you don't own, don't make it: describe it under `frameworkRequests` in your result and
work around it.

Never edit `src/shared/Characters/*` (other agents are polishing them) or
`tools/charlab/STYLE_GUIDE.md`.

## File ownership

| Workstream | Owns |
|---|---|
| **WORLD**: floating islands, personal brainrot rivers, rarity portals, rarity-scaled spawn speed, economy re-tune | `src/server/Builders.luau`, `src/server/WorldBuilder.luau`, `src/server/PlotService.luau`, `src/server/DropService.luau`, `src/shared/Items.luau`, the economy/world settings in `src/shared/Config.luau` (nothing else in it), `tools/economy_sim.py`, `tests/run.luau`, new files under `src/server/Scenes/Island*` |
| **TITLE**: cinematic flyover under 3s | `src/first/*` (ReplicatedFirst), `src/client/TitleScreen.luau` |
| **OBBY**: NYC rooftop brainrot obby | `src/server/Rooms/Obby.luau`, `src/server/Scenes/ObbyScene.luau`, `src/client/Rooms/Obby.luau` |
| **FISHING**: Alaska ice-fishing hole | `src/server/Rooms/Fishing.luau`, `src/server/Scenes/FishingScene.luau`, `src/client/Rooms/Fishing.luau` |
| **WHEEL**: Venice carnival spin wheel | `src/server/Rooms/Wheel.luau`, `src/server/Scenes/WheelScene.luau`, `src/client/Rooms/Wheel.luau` |

Framework files (owned by the lead, read-only for workstreams): `RoomService.luau`,
`RoomsClient.luau`, `init.server.luau`, `init.client.luau`, `PlayerService.luau`,
`DataService.luau`, `MonetizationService.luau`, `Remotes.luau`, `CharacterKit.luau`,
`Animator.luau`, `Panels.luau`, the rest of `Config.luau`, `default.project.json`.

## Tooling

```bash
cd roblox-tycoon
LUAU=/tmp/claude-0/-home-user-Biotekk127-github-io/4d08037e-7900-5ca9-9d94-2f5094d117f5/scratchpad/tools/luau
T=/tmp/claude-0/-home-user-Biotekk127-github-io/4d08037e-7900-5ca9-9d94-2f5094d117f5/scratchpad/tools
# Type-check everything against the real Roblox API:
$T/rojo sourcemap default.project.json -o /tmp/sm-$RANDOM.json   # use your own unique path
$T/luau-lsp analyze --definitions=$T/globalTypes.d.luau --sourcemap=<that path> src
# Unit tests:
python3 tests/run_tests.py $LUAU
# Build the place file (to a scratch path, not the repo file):
$T/rojo build default.project.json -o /tmp/<unique>.rbxlx
# Render a scene file (see "Scenes"):
python3 tools/charlab/charlab.py src/server/Scenes/ObbyScene.luau --scene --out <png> --luau $LUAU [--focus x,y,z,r]
```

## Scenes (themed environments you can SEE before shipping)

Static scenery is written with the **same builder API as characters**
(`tools/charlab/CHARACTER_GUIDE.md`: `k:Part`, `k:Group`, `k:Mirror`, `k:Light`, `k:Particles`,
Anim) in a file that returns `{ Name = "...", Build = function(k) ... end }`. Render it with
`charlab.py --scene`, open the PNG and iterate. There are no size limits (keep it under 3000
parts and 24 lights).

Extra part fields for gameplay:
* `CanCollide = false` / `CanTouch = true` / `CanQuery = true` (scene parts default to
  collidable, not touchable, not queryable),
* `Role = "Checkpoint"` (+ optional `RoleIndex = 3`): stored as attributes so gameplay code can
  find parts: `for _, p in sceneModel:GetDescendants() do if p:GetAttribute("Role") == ... end`.
  The `--scene` render highlights Role parts in magenta.
* `Role = "Exit"` is handled by RoomService: touching it returns the player to the hub.

Scene local coordinates: the origin is the room origin. The scene can extend about
±300 studs. Animated scene groups play on the client (Animator) when the camera is within
170 studs of the scene origin.

## Rooms (OBBY / FISHING / WHEEL)

Server module (`src/server/Rooms/<Id>.luau`):

```lua
Room.Id, Room.Name, Room.Emoji, Room.DoorColor   -- door label/colour on the hub
Room.Scene = require(script.Parent.Parent.Scenes.<Id>Scene)  -- built by RoomService at the origin
function Room.Build(origin: CFrame, sceneModel: Model?): { Spawn: CFrame }  -- wire gameplay; return spawn
function Room.Init(services, RoomService)     -- e.g. services.PlayerService.RegisterRequest("Obby.Finish", fn)
function Room.OnEnter(player) / Room.OnLeave(player)
function Room.GrantProduct(player, productKey)    -- WHEEL only: Config.Products.WheelSpin (Kind = "Room")
```

Room origins (world): Obby `(2600, 300, 0)`, Fishing `(0, 20, 2600)`, Wheel `(-2600, 20, 0)`.
The Obby origin is high so the NYC skyline can extend down to about y = 100. Workspace
FallenPartsDestroyHeight is -50 (a player who falls that far dies and respawns at their
plot). The Obby must catch falls itself, well before that, and return the player to the
last checkpoint.

Services available to rooms (`services` = the table of every server service):
* `services.PlayerService.AddCash(player, amount)`, `.GetCash`, `.SpendCash(player, amount) -> bool`,
  `.RegisterRequest(action, fn(player, payload) -> (ok, message?))`. Requests are rate-limited
  to 1 per 0.3s per player. Validate every payload: never trust the client.
* `services.PlayerService.Discover(player, def, variant)`: adds an Index entry
  (variant "Normal" / "Gold" / "Diamond" / "Rainbow"). Get `def` from `CharacterRegistry.Get(id)`.
* `RoomService.Data(player, roomId)`: a persistent table for your room (saved with the player;
  keep it small and JSON-safe). `RoomService.Fire(player, roomId, eventName, payload)`: an event to
  your client module. `RoomService.GetRoom(player)`: the room the player is in.
* `services.Remotes.NotifyPlayer(player, text, style)`, `.NotifyAll`, `.CashPopup:FireClient(...)`,
  `.Celebrate:FireClient(player, title, subtitle)`.
* Reward sizing: `Economy.ScaledReward(player:GetAttribute("IncomePerSec") or 0, seconds, minimum)`
  so rewards stay meaningful at every stage of the game.
* Shared modules: `ReplicatedStorage.Shared.{Config, Economy, Format, Items, Rarity, CharacterKit, CharacterRegistry}`.
  `CharacterKit.Build(def, "Full"|"Mini")` and `ApplyMutation(model, "Gold")` let you show real brainrots.

Client module (`src/client/Rooms/<Id>.luau`):

```lua
Room.Id
Room.Lighting = { ClockTime = 0, Ambient = Color3..., Atmosphere = { Density = 0.5 }, Bloom = {...}, ColorCorrection = {...}, SunRays = {...} }
function Room.Enter(ctx)   -- ctx.Screen (own ScreenGui), ctx.Model (scene), ctx.Request(action, payload) -> ok,
                           -- ctx.Notify, ctx.CashPopup, ctx.Celebrate, ctx.Player
function Room.Leave()      -- clean up connections; ctx.Screen is destroyed for you, lighting restored for you
function Room.OnEvent(eventName, payload)          -- RoomService.Fire while the player is inside
function Room.OnEventAnywhere(eventName, payload)  -- optional, events while outside the room
```

Use `require(script.Parent.Parent.Ui)` for the house UI style (FredokaOne, chunky buttons,
`Ui.Theme`). Keep UIs mobile-friendly (scale or anchor, big touch targets).

## WORLD workstream: compatibility it must keep

Other code depends on these; keep them working:
* `PlotService`: `Plots`, `GetPlot`, `Claim(player, ownedItems)`, `Release`, `ResetForRebirth`,
  `TryBuy`, `AddToBank`, `Collect(player, silent?)`, `IsOnCollectPad`, `SpawnCFrame`,
  `RefreshButtons`. Plots stay in `workspace.Plots` named `Plot<N>`, each with a `Buttons` folder
  of models that have a `Pad` part plus `ItemId`/`Price` attributes, a `BankAnchor` part,
  and the `Bank` attribute (the client uses all of these).
* `WorldBuilder.HubDoorSlots` (3 door CFrames, see WorldBuilder.luau), `WorldBuilder.LeaderboardFrame`,
  `WorldBuilder.BoardLine`. The hub keeps the spawn, the leaderboard, the how-to board and the 3 door slots.
* Drops: `DropService` must still call `Services.PlayerService.Discover(owner, def, variant)` on spawn
  and support upgraders, the collector, mutations, Lucky/Fast passes and events.
* `Items` Ids, `Character` fields and item order must not change (they're saved in player data).
  Values may be re-scaled.
* Economy pacing target: about 60 min to the first rebirth and about 25-35 min for the next few (verify with
  `tools/economy_sim.py`, updated for per-rarity spawn intervals).
