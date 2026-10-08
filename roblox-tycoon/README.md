# 🧠 Brainrot Factory Tycoon 🏭

A complete Roblox tycoon game. Players build a factory where each dropper is topped by a
hyper-detailed, animated **Italian brainrot** (Tralalero Tralala, Tung Tung Tung Sahur,
Bombardiro Crocodilo, Ballerina Cappuccina, ...) standing on a rarity pedestal. Mini versions of
the brainrots ride the conveyor, and rare **Gold / Diamond / Rainbow** mutations are worth up to
50x. Every variant you spawn goes into your **Brainrot Index**. When the factory is finished,
players **rebirth** for a permanent cash multiplier and do it all again.

The whole game is built from code: the characters, plots, droppers, lobby and all the UI are
generated when the server starts. You don't have to build anything by hand in Studio.

## Features

| | |
|---|---|
| 🏭 **Tycoon core** | 8 auto-assigned plots, 24 purchasable items: 12 brainrot droppers, 3 upgraders, a golden collector, 8 decorations |
| 🧠 **12 brainrots** | Hand-built 3D replicas (75–390 parts each) with idle animations, in 7 rarity tiers: Common → Uncommon → Rare → Epic → Legendary → Mythic → Secret. Rarity pedestals add auras, lights, orbiting gems and light beams |
| ✨ **Mutations** | Gold (x3), Diamond (x10) and Rainbow (x50) drops recolour the brainrot, with server-wide shoutouts for Rainbows |
| 📖 **Brainrot Index** | Collect all 48 character × variant combos; each one adds +0.5% cash forever. 3D animated cards with lore |
| 🔁 **Rebirths** | +100% permanent cash per rebirth, with a rising cost curve |
| ⚡ **Server events** | Random Gold Rush / Cash Frenzy, plus paid Rainbow Rain / Cash Frenzy that boost everyone |
| 🎁 **Retention** | 7-day login streak, free gift every 8 min, offline earnings, promo codes |
| 👯 **Social** | +10% cash per friend in the server (max +40%), optional group bonus, global Top Earners board, chat tags |
| 💎 **Monetization** | 5 game passes + 5 developer products, idempotent receipts, free test purchases in Studio |
| 💾 **Saving** | DataStore with session locking, retries, autosave and shutdown save |
| 📱 **Mobile-ready UI** | Scales to any screen; guide arrow points to the next thing to buy |

## 1. Open it in Roblox Studio (2 minutes)

**Option A: open the place file (easiest)**
1. Download `BrainrotFactoryTycoon.rbxlx` from this folder.
2. Double-click it, or use Studio > File > Open from File.
3. Press **Play**. You spawn in the lobby, get teleported to your factory, and see a green **FREE** button.

**Option B: Rojo (for developers)**
```bash
rokit install            # or install Rojo 7.4+ any way you like
rojo serve               # then connect from the Rojo plugin in Studio
rojo build -o BrainrotFactoryTycoon.rbxlx   # rebuild the place file after editing src/
```

> In Studio, every Shop item is a **TEST FREE** button so you can try passes and products
> before creating them. This only works in Studio; real players can never get things free.

## 2. Publish

1. **File > Publish to Roblox**, then give it a name and description.
2. Go to **Game Settings**:
   - **Security**: turn on **Enable Studio Access to API Services** (lets saving work in Studio).
   - **Places > Max Players: set to `8`** to match the 8 plots. If more players join than there are plots, the extra ones are kicked with a "server full" message.
3. Set the game to **Public** when you're ready.

## 3. Turn on monetization

On [create.roblox.com](https://create.roblox.com) open your experience, then **Monetization**:

1. **Passes**: create these 5 and copy each ID:

   | Config key | Name | Suggested price |
   |---|---|---|
   | `DoubleCash` | 2x Cash | R$ 199 |
   | `AutoCollect` | Auto Collect | R$ 149 |
   | `LuckyMutations` | Lucky Mutations | R$ 249 |
   | `FastDroppers` | Fast Droppers | R$ 299 |
   | `VIP` | VIP | R$ 399 |

2. **Developer Products**: create these 5:

   | Config key | Name | Suggested price |
   |---|---|---|
   | `CashSmall` | Pile of Cash | R$ 49 |
   | `CashMedium` | Bag of Cash | R$ 149 |
   | `CashLarge` | Vault of Cash | R$ 499 |
   | `RainbowRain` | Rainbow Rain (server event) | R$ 99 |
   | `CashFrenzy` | Cash Frenzy (server event) | R$ 79 |

3. Paste each ID into `Id = 0` in **`src/shared/Config.luau`** (or in Studio:
   ReplicatedStorage > Shared > Config). Prices shown in the shop are read from Roblox automatically.

Cash packs scale with the player's income (e.g. "1 hour of income"), so they stay worth buying all game.

## 4. Things you'll want to customize

Everything is in **`src/shared/Config.luau`** and **`src/shared/Items.luau`**:

- **Promo codes**: `Config.Codes`. Post new ones on social media to bring players back.
- **Group bonus**: set `Config.GroupId` to your Roblox group ID. Members get +10% cash.
- **Creatures and prices**: edit `Items.List` (name, emoji, colour, value, price). Don't rename
  `Id`s after launch, because they're stored in player saves.
- **Economy pacing**: change prices, then run `python3 tools/economy_sim.py` to see how long each
  rebirth takes. Currently it's about 60 min to the first rebirth and about 30 min for the next few.
- **Wipe all progress** (e.g. after a big economy change): bump `Config.DataStoreName` to `_v2`.

## 5. Launch checklist

Code alone won't make a game popular. Clicks and retention do. These matter most:

- [ ] **Icon + thumbnails.** These matter more than anything else. Bright colours, a big
  close-up creature, a Rainbow mutation, big "$" numbers. Make 3 and swap between them to see which gets more clicks.
- [ ] **Title format** that trending games use: `[🌈 RAINBOW] Brainrot Factory Tycoon`. Change
  the bracket tag with each update.
- [ ] **Update weekly.** Add 2-3 new creatures (new rows in `Items.luau`) plus a new code, and say so in the title.
- [ ] **Short videos.** Post TikTok/YouTube Shorts of Rainbow pulls and rebirths with the game link.
- [ ] **Sponsor / ads** once day-1 retention looks good (Creator Hub > Analytics).
- [ ] **Group + Discord.** Set `Config.GroupId` and post codes there.
- [ ] Watch **Analytics > Retention and Monetization** and tune prices with the sim.

## The brainrots

| Dropper | Character | Rarity |
|---|---|---|
| D1 | Lirilì Larilà | Common |
| D2 | Boneca Ambalabu | Common |
| D3 | Brr Brr Patapim | Uncommon |
| D4 | Trippi Troppi | Uncommon |
| D5 | Tung Tung Tung Sahur | Rare |
| D6 | Cappuccino Assassino | Rare |
| D7 | Chimpanzini Bananini | Epic |
| D8 | Frigo Camelo | Epic |
| D9 | Ballerina Cappuccina | Legendary |
| D10 | Bombardiro Crocodilo | Legendary |
| D11 | Tralalero Tralala | Mythic |
| D12 | La Vacca Saturno Saturnita | Secret |

Each character is one file in `src/shared/Characters/`, written with a small builder API
(parts, groups, mirroring, animations, lights, particles). See
**`tools/charlab/CHARACTER_GUIDE.md`**. To add or edit a character, preview it without
opening Studio:

```bash
python3 tools/charlab/charlab.py src/shared/Characters/TralaleroTralala.luau --out preview.png --luau path/to/luau
python3 tools/charlab/check_all.py --out previews/ --luau path/to/luau    # validate + render all
```

The previewer validates the model (size limits, part counts, valid shapes, colours and
animations) and renders a contact sheet: front, 3/4, side, back, top, two animation poses,
a close-up and the conveyor mini. It needs `numpy` and `pillow`.

> **Heads-up about the meme characters:** the Italian brainrot characters are viral memes
> created by other people. Lots of Roblox games use them, but you don't own them, and a
> rights holder could file a takedown. Keep a plan B (for example, original characters)
> in case that ever happens.

## Project layout

```
roblox-tycoon/
├── BrainrotFactoryTycoon.rbxlx   ready-to-open place (built from src/ with Rojo)
├── default.project.json          Rojo project
├── src/
│   ├── shared/                   ReplicatedStorage.Shared
│   │   ├── Config.luau           ← game passes, products, codes, economy settings
│   │   ├── Items.luau            ← everything players can buy
│   │   ├── Economy.luau          formulas shared by server & client
│   │   ├── Format.luau           $1.23M / 2:05 formatting
│   │   ├── Rarity.luau           the 7 rarity tiers
│   │   ├── CharacterKit.luau     builds characters from their definitions, mutations
│   │   ├── CharacterRegistry.luau  loads all characters
│   │   └── Characters/           ← one file per brainrot
│   ├── server/                   ServerScriptService.Server
│   │   ├── init.server.luau      boots all services
│   │   ├── Builders.luau         procedural models (plots, droppers, decor, drops)
│   │   ├── RarityFX.luau         rarity pedestals, auras and nameplates
│   │   ├── WorldBuilder.luau     lobby, lighting, paths, boards
│   │   ├── PlotService.luau      plots, buy buttons, purchases, bank
│   │   ├── DropService.luau      spawning, mutations, upgraders, collector
│   │   ├── PlayerService.luau    cash, multipliers, rebirth, rewards, requests
│   │   ├── MonetizationService.luau  passes & dev products
│   │   ├── EventService.luau     server-wide boost events
│   │   ├── LeaderboardService.luau  global top earners
│   │   ├── DataService.luau      saving with session locks
│   │   └── Remotes.luau          client ↔ server remotes
│   └── client/                   StarterPlayerScripts.Client
│       ├── init.client.luau      HUD, guide arrow, banners, chat tags
│       ├── Panels.luau           Shop / Index / Rebirth / Daily / Codes
│       ├── Animator.luau         plays character animations locally
│       ├── Effects.luau          toasts, cash popups, celebrations
│       └── Ui.luau               UI helpers & theme
├── tests/                        offline unit tests for shared modules
└── tools/
    ├── economy_sim.py            pacing simulator
    └── charlab/                  character previewer, validator and guide
```

## Development

```bash
python3 tests/run_tests.py path/to/luau      # unit tests (luau CLI from github.com/luau-lang/luau)
python3 tools/economy_sim.py                 # economy pacing
```

Security notes: all cash, purchases and rewards are decided on the server. The client only sends
requests ("rebirth", "claim daily", ...), and they're rate-limited and validated. Drops use server
physics ownership, so they can't be spoofed.
