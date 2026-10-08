# Brainrot Character Guide

Every brainrot is one file in `src/shared/Characters/<Id>.luau`. The file returns a table
and builds its model only through the `k` builder, so the **same file** runs in Roblox
(`src/shared/CharacterKit.luau`) and in the offline previewer (`tools/charlab`).

## File contract

```lua
-- No require()s, no Roblox globals (no Vector3/CFrame/Color3/Instance/game/workspace).
-- Only plain Lua: numbers, tables, strings, math.*, local helper functions.
local GREEN = "#7fd36b"

return {
	Id = "NoodleGoblin",          -- must equal the file name
	Name = "Noodle Goblin",
	Rarity = "Common",            -- Common | Uncommon | Rare | Epic | Legendary | Mythic | Secret
	Emoji = "🍜",
	Color = "#ffd66e",            -- signature colour (UI accents, fallback)
	Tagline = "Slurps first, asks questions never.",   -- <= 60 chars, shown on cards
	Lore = "Two or three funny sentences for the Brainrot Index.",

	Build = function(k) ... end,      -- the detailed display model
	BuildMini = function(k) ... end,  -- tiny version that rides the conveyor
}
```

## Coordinate system and limits (Build)

* Units are studs. **+Y is up. The character FACES -Z** (its front/face points toward -Z).
  Its right hand is at +X, its left hand at -X.
* **Feet (lowest point) sit on y = 0.** Lowest point must be between y = 0 and 0.35.
* Must fit inside **x and z in -3.2 .. 3.2** and **y in 0 .. 9.5**. Height at least 4.5.
  It stands on a pedestal on top of a dropper, with neighbours 8 studs away.
* Minimum part counts (detail is the whole point):
  Common 45 · Uncommon 60 · Rare 80 · Epic 100 · Legendary 130 · Mythic 160 · Secret 200.
  Max 400. Aim well above the minimum.
* At most **2** `k:Light` and **3** `k:Particles` (every plot in the server may show it).

## BuildMini (conveyor version)

* Centred on the origin (not feet), fits in a **2.7-stud cube** (every coordinate within ±1.35).
* **3–12 parts**, no Anim / Light / Particles / Text. Instantly recognisable silhouette and
  colours. Faces -Z like the full model.

## Builder API

All positions are relative to the current group. Rotations are in **degrees**, applied like
`CFrame.Angles(rx, ry, rz)` (X, then Y, then Z, about the part's own axes).

```lua
k:Part({
	Name = "Head",                 -- optional but please name important parts
	Shape = "Block",               -- Block | Ball | Ellipsoid | Cylinder | Wedge
	Size = { x, y, z },            -- every component >= 0.05
	Pos = { x, y, z },             -- centre of the part (default 0,0,0)
	Rot = { rx, ry, rz },          -- degrees (default 0,0,0)
	Color = "#rrggbb",
	Material = "SmoothPlastic",    -- see list below
	Transparency = 0,              -- 0..1
	Reflectance = 0,               -- 0..1
	Text = { Text = "$", Color = "#ffffff", Face = "Front" },  -- optional painted text
	Anim = { ... },                -- optional, see Animation
})

k:Group({ Name = "LeftArm", Pos = {..}, Rot = {..}, Anim = {..} }, function()
	-- parts here are positioned relative to the group origin.
	-- If the group has an Anim, it rotates/bobs around this origin -> put the origin at the JOINT.
end)

k:Mirror(function()
	-- Everything in here is built twice: as written, and mirrored across x = 0.
	-- Write the +X (right) side once; the -X side is created automatically.
	-- Mirrored animations play mirrored (a waving pair of arms waves symmetrically).
end)

k:Light({ Pos = {..}, Color = "#hex", Range = 10, Brightness = 1 })        -- PointLight
k:Particles({ Pos = {..}, Color = "#hex", Color2 = "#hex", Rate = 4, Size = 0.3,
              Speed = 1.5, Lifetime = 1.5, Spread = 30, Direction = "Top" })
```

### Shapes

| Shape | Notes |
|---|---|
| `Block` | box |
| `Ball` | sphere; give equal sizes |
| `Ellipsoid` | stretched sphere filling `Size` — the workhorse for organic shapes |
| `Cylinder` | **axis runs along X**; `Size = {length, diameter, diameter}`. Rotate `{0,0,90}` for an upright cylinder |
| `Wedge` | full bottom face and full back face (+Z); the slope rises from the bottom-front edge to the top-back edge, i.e. the slope faces -Z and up. Rotate to make ears, beaks, spikes, roofs |

There are no cones or tori: build cones from stacked cylinders of decreasing diameter, rings
from many short rotated blocks/cylinders around a circle (use a `for` loop with math.cos/sin).

### Materials

SmoothPlastic, Plastic, Neon (glows), Glass, Metal, Foil (shiny gold/chrome), Fabric, Wood,
WoodPlanks, Marble, Granite, Slate, Concrete, Brick, Cobblestone, Sand, Grass, Ice,
DiamondPlate, CorrodedMetal, Pebble, ForceField, Salt, Rubber, Leather, Cardboard, Carpet,
Plaster, Asphalt, Basalt, Rock, Snow, Mud, Limestone, Pavement, CeramicTiles, CrackedLava, Glacier.

### Animation (idle loop, played on the client)

```lua
Anim = { Type = "Wiggle", Axis = "Z", Amount = 20, Speed = 0.8, Phase = 0 }
```

| Type | Effect | Amount | Allowed on |
|---|---|---|---|
| `Spin` | continuous rotation about Axis, `Speed` revolutions/sec | — | parts, groups |
| `Wiggle` | rotate back and forth about Axis | degrees | parts, groups |
| `Bob` | move back and forth along Axis | studs | parts, groups |
| `Pulse` | grow/shrink uniformly | fraction (0.1 = ±10%) | parts only |
| `Blink` | squash Y to 10% for a moment every `1/Speed` seconds (eyes!) | — | parts only |

`Speed` is cycles per second (keep 0.2–2: calm and loopable). `Phase` (0..1) offsets the timing
so multiple parts don't move in sync. Animated groups can be nested (a wiggling hand inside a
waving arm inside a bobbing body). Rotations happen around the group/part ORIGIN, so place
group origins at joints (shoulder, neck, hip, hinge).

## Workflow

```bash
cd roblox-tycoon
python3 tools/charlab/charlab.py src/shared/Characters/<Id>.luau --out /path/preview.png --luau <path-to-luau>
```

Prints a validation report (fix every ERROR, consider every WARNING) and writes a contact
sheet: front, 3/4, side, back, top, two animation poses, a close-up and the mini. **Open the
PNG and look at it** after every significant change. Blue boxes show the allowed volume.
Iterate many times — look for gaps between parts, floating pieces, parts poking through the
face, unreadable silhouettes, muddy colours and broken animation pivots (check the two pose
tiles: limbs must rotate at joints, not fly off).

## Art direction

* **Faithful replicas** of the famous Italian brainrot meme characters: a kid who knows
  the memes (and games like Steal a Brainrot) must recognise each one instantly. Match the
  canonical anatomy, colours, outfit, props and pose; stylise only as far as building from
  primitives requires. Never use real brand logos (e.g. no shoe swoosh) - use generic stripes.
* **Silhouette first**: each brainrot must be recognisable as a black shape from 40 studs.
  Keep the canonical proportions that make it iconic.
* **Faces sell it**: big expressive eyes with whites + pupils + highlight dots, brows, a mouth
  with teeth/tongue where it fits. Eyes should usually `Blink`.
* **Excessive detail** = layered secondary forms: seams, stitches, rims, rivets, buttons,
  laces, freckles, crumbs, spines, scales, highlights, trims, little props and pockets. Detail
  should be readable, not noise: big forms first, then medium, then tiny.
* **Colour**: 1 dominant + 1–2 secondary + 1 accent. Use Neon sparingly for accents/eyes/magic.
  Avoid pure black/white; use tinted darks (#1b1b24) and warm whites (#fff8ec).
* **Motion**: 3+ animated elements (Common) up to 8+ (Secret): idle breathing/bob, blinking,
  and something characterful (ears flop, prop spins, cape sways, sparkles orbit).
* **Rarity must read at a glance**: the game adds a rarity pedestal, aura and nameplate
  around every character. On the model itself, higher tiers get more detail, more motion
  and more effects (lights, particles, glowing accents) - but never at the cost of the
  canonical look. Mythic and Secret should look like boss-level showpieces.
* Keep the front (-Z side) the "beauty side", but the back and sides must look finished too.
