# Brainrot House Style Guide

This is the binding art direction for the 12 dropper characters in `src/shared/Characters/`.
It sits on top of `CHARACTER_GUIDE.md` (the file contract, builder API and validator limits).
Where this guide is stricter, this guide wins. Every rule below is measurable with the
charlab output or with the measurement snippet at the end of this file.

The rules come from the best-executed work already in the set:

| What | Reference character | Where in the file |
|---|---|---|
| Eyes on a curved head (layered, surface-projected) | Trippi Troppi | `buildEye` (headSurface + faceRot, liner/lid/white/iris ring/iris/pupil/2 Neon shines/brow) |
| Eyes with rim + lashes, shared BLINK table | La Vacca Saturno Saturnita | `buildEye` |
| Bulging spherical eyeball with iris/pupil mapped onto the ball | Boneca Ambalabu | `onEye` inside `buildHead` |
| Smooth organic limbs, no visible joints | La Vacca Saturno Saturnita | `loft()` (overlapping ellipsoid beads, length x2.6) |
| Tapered limb pieces | Trippi Troppi `spindle()`, Chimpanzini `limb()` | |
| Details lying on a curved surface | Cappuccino Assassino `cupFrame`, Tung `onLog`, La Vacca `capPatch`/`onSurface` | |
| One part doing two jobs (part-budget efficiency) | Lirili `spineRod` (one rod = two spines), Tung end-grain stacked discs | |
| Prop richness (hard-surface tertiary detail) | Frigo Camelo fridge, Bombardiro airframe | |
| Rarity flair that never touches the design | Tralalero splash ring + bubble orbit, La Vacca rings/moons/halo | |

---

## 1. Faces and eyes

Faces sell every character. Every eye in the set is built with this recipe (bottom of the
stack first). Offsets are along the surface normal of the head at the eye centre.

| Layer | Shape | Size (relative to EyeWhite) | Normal offset | Colour | Required |
|---|---|---|---|---|---|
| Rim / liner | Ellipsoid | 1.08-1.15x W and H | -0.04 | tinted dark (`#1b1b24`, or a hue-matched dark such as `#3b2318`) | yes on light heads (cups, cow, frog); optional on mid/dark skin |
| EyeWhite | Ellipsoid (Ball for bulging eyes) | base | 0 | warm white `#fff8ec` / `#fffaf0` | yes |
| Iris | Ellipsoid, flat (Z 0.08-0.12) | 60-75% of white height | +0.04 | character colour, V 0.30-0.70 | yes (see exceptions) |
| Pupil | Ellipsoid, flat | 45-60% of iris | +0.07 | `#1b1b24` / `#141218` | yes |
| Catch-light 1 | Ball, **Material = "Neon"** | 22-30% of white height | +0.10 | `#fffdf4` | yes |
| Catch-light 2 | Ball, **Material = "Neon"** | 40-55% of catch-light 1 | +0.10 | `#fffdf4` | yes |
| Upper lid | Ellipsoid in skin colour or one shade darker | covers top 10-40% of the white | -0.01 | skin / skin-dark | yes (sets the expression) |
| Lash line + 2-5 lashes | thin Ellipsoid / 0.05 blocks | | | tinted dark | female or droopy characters |
| Brow | Ellipsoid 0.6-0.9x eye width, 0.10-0.16 thick | | sits 0.25-0.45 above the eye centre | darkest hair/skin shade | yes |

Placement:
* Catch-light 1 sits in the upper-outer quadrant of the iris (toward the key light), catch-light 2
  in the lower-inner quadrant. Both must be visible from the front AND the 3/4 view.
* Pupils sit 5-10% low and slightly toward the nose so the character looks at a player
  standing in front of the pedestal.
* Gap between the inner eye corners: 0.2-0.6x the eye width.
* Eyes on a curved head are placed with a surface helper (point + normal) and oriented with
  `faceRot`. A flat disc floating in front of a curved surface is not allowed.

Size:
* EyeWhite height = **25-45% of the head height** (the face-bearing volume). Canonically bulging
  eyes (frog) may go to 55%.
* Absolute EyeWhite height on the full model **>= 0.6 studs**. Canonically "beady" eyes (Brr Brr
  Patapim) may go down to 0.42 studs but must then carry a dark rim and both Neon catch-lights.
* Exceptions to the iris rule: canonical solid-dark eyes (Tralalero's shark eye) use a dark
  navy/brown iris RING around the dark eye instead; canonical dot pupils (Tung Tung) use a thin
  dark-brown iris ring behind the pupil. Catch-lights are never optional.

Blink:
* `local BLINK = { Type = "Blink", Speed = 0.2-0.3, Phase = <unique per character> }` shared by
  every part that sits ON the eyeball (white, iris, pupil, both catch-lights, an on-eye lid line).
  Rims, lids, lashes and brows that sit on the head do not blink.
* Both eyes blink together (same table). No two characters use the same Speed + Phase pair.

Mouth: every character has a readable mouth with a tinted-dark interior (`#44192a`-`#5e1626`
family) and teeth and/or a tongue where the meme has them. Mouth corners get a crease or an
up/down hook so the expression reads from 40 studs.

---

## 2. Colour

* Palette = 1 dominant (40-65% of the visible surface) + 1-2 secondary (15-35%) + 1 accent
  (<= 10%, the most saturated colour) + neutrals (eye whites, tinted darks).
* Every base colour gets a shade family: `BASE`, `BASE_DARK` (V -20-30%, same hue) for seams,
  creases and panel lines, `BASE_LIGHT` (V +10-15%, S -10-20%) for highlights and gloss.
* Chromatic dominants: saturation 0.35-0.80, value 0.55-0.95. Canonical neutrals (elephant grey,
  tyre black, ninja black, fridge white) are allowed but must be hue-tinted and must be lifted
  by a contrasting secondary/accent so the silhouette does not read as one flat blob.
* Darks: nothing below HSV value 0.08. Use tinted darks (`#1b1b24`, `#25252f`, `#2a1610`,
  `#24364a`). Never `#000000`.
* Whites: warm whites (`#fff8ec`, `#fffaf0`, `#fffdf4`). **Never `#ffffff`** - not on parts, not
  on Neon, not on steam, not on particles (use `#fffaf2`).
* Outline / seam treatment: there are no black outlines. Seams, panel lines, stitches and
  grooves use `BASE_DARK`, 0.05 studs thick, sunk 0.01-0.02 into the surface so they never
  stand proud of the silhouette. Where two big forms meet (head on neck, head on cup, body in
  a peel), add a slightly darker contact ring or collar to hide the intersection.

## 3. Materials

| Material | Use for | Notes |
|---|---|---|
| SmoothPlastic | default: skin, fur bodies, organic forms, ceramics, painted metal | glossy subjects get `Reflectance` 0.05-0.12 (frog, banana, cup glaze, shark) |
| Fabric | cloth, ninja suit, fur where a matte read helps, nubuck boots | |
| Leather / Rubber | straps, soles, belts / tyres, soles, seals | |
| Metal | hardware, rims, blades, airframe | `Reflectance` <= 0.3 |
| Foil | small gold / chrome trims, buckles, hubcaps | <= 10% of parts |
| Wood, Ice, Snow, Glacier, Slate, Grass | only when the canonical subject is made of it | |
| Glass | transparent things only (bubbles, water, slime, canopies, moons) | Transparency 0.2-0.45 |
| Neon | catch-lights (mandatory), glints, sparkles, glowing trims, emissive props | never on surfaces larger than 1 stud in two dimensions; never as a body colour; no Neon within 0.4 studs of the eyes except the catch-lights |
| ForceField | Secret-tier aura shell only (one per model, Transparency >= 0.85) | Mythic may use it for one magic effect |

## 4. Shape language

* Organic forms (bodies, heads, limbs, tails, trunks, necks, fins, peels, leaves) are built from
  **overlapping Ellipsoids**. Consecutive pieces overlap by >= 30% of the shorter piece and their
  diameters differ by <= 15%, so no pinch, ring or step is visible.
* **No "segmented sausage" joins.** Limb chains use the `loft` bead pattern (ellipsoid length =
  segment length x 2.4-2.6) or tapered spindles. A Ball sitting between two Cylinders on an
  organic limb (doll / mannequin joint) is not allowed. Animated joints keep their group pivot;
  the beads on both sides of the pivot overlap it so the bend stays closed.
* Cylinders are for man-made or canonically cylindrical things: wheels, cups, pipes, bats,
  handles, logs, stick limbs of a wooden character (and those must taper: two overlapping
  pieces, thicker at the root).
* Blocks are for planar man-made things: panels, blades, straps, plates. **Never for soft or
  organic forms** (peel strips, cloth drapes are curved ellipsoid slabs).
* Wedges: teeth, fins, ears, spikes - always rooted in an ellipsoid so the base is soft.
* Every flat-topped cylinder that is not canonically flat gets a rounded or chamfered edge.

## 5. Detail density

Detail tiers: **big** forms (silhouette), **medium** forms (limbs, features, props, clothing),
**tertiary** detail = any part whose largest dimension is <= 0.35 studs that sits on a surface:
seams, stitches (rows of 0.05 blocks), rivets, bolts, freckles, pores, warts, scales, scutes,
nails and cuticles, wrinkles, laces, eyelets, crumbs, foam bubbles, gloss streaks, chips.

Required part ranges for THIS set (the validator hard cap is 400, so the ladder is compressed
at the top; the old Common ceiling of ~100 is retired):

| Tier | Parts (charlab "Full: N parts") | Tertiary share | Characters |
|---|---|---|---|
| Common | **170-210** | >= 30% | Lirili Larila, Boneca Ambalabu |
| Uncommon | **205-245** | >= 30% | Brr Brr Patapim, Trippi Troppi |
| Rare | **235-275** | >= 32% | Tung Tung Tung Sahur, Cappuccino Assassino |
| Epic | **280-325** | >= 33% | Chimpanzini Bananini, Frigo Camelo |
| Legendary | **320-355** | >= 35% | Ballerina Cappuccina, Bombardiro Crocodilo |
| Mythic | **350-380** | >= 35% | Tralalero Tralala |
| Secret | **380-400** | >= 35% | La Vacca Saturno Saturnita |

* A higher tier never has fewer parts than any character of a lower tier.
* No bald areas: every visible surface region larger than ~1.5 stud^2 (including the back and
  sides) carries at least one medium or tertiary element.
* Budget efficiency near the cap: one part may do two jobs (a rod through a body = two spines),
  concentric stacked discs replace rings of tiles, `k:Mirror` for symmetric detail. Spend the
  saved parts on the face and on tertiary detail, not on more tiles.

## 6. Animation

Every character has: (1) idle breathing or bob, (2) blink, (3) one signature motion from its
meme, plus secondary motions (ears, tails, cloth, props). Measured with charlab's
"N animated" count:

| Tier | Min animated (charlab) | Min distinct motion systems | Allowed lights / particles |
|---|---|---|---|
| Common | 20 | 5 | 0 lights, 0-1 particle emitter |
| Uncommon | 26 | 6 | 0-1 light, 1 emitter |
| Rare | 30 | 7 | 1-2 lights, 1-2 emitters |
| Epic | 36 | 8 | 2 lights, 2-3 emitters |
| Legendary | 45 | 9 | 2 lights, 3 emitters |
| Mythic | 55 | 10 | 2 lights, 3 emitters |
| Secret | 70 | 11 | 2 lights, 3 emitters |

Speed / amount ranges:

| Motion | Type | Amount | Speed |
|---|---|---|---|
| Breathing | Pulse on chest/throat/core, or Bob Y on the body group | Pulse 0.02-0.04, Bob 0.03-0.07 | 0.35-0.6 |
| Body sway | Wiggle Z at hips | 1.5-3 deg | 0.3-0.45 |
| Head tilt / nod | Wiggle | 3-7 deg | 0.3-0.5 |
| Ears, tails, cloth, leaves | Wiggle (chains: nested groups) | 8-18 deg | 0.45-0.8 |
| Signature action (wave, chew, knock, tap) | Wiggle / Bob | as needed | 0.7-1.2 (rhythmic props up to 1.8) |
| Propellers | Spin | | 1.2-1.8 |
| Orbits, halos, rings | Spin | | 0.07-0.2 |
| Glints, sparkles, LEDs | Pulse on Neon | 0.2-0.4 | 0.5-1.1 |
| Blink | Blink | | 0.2-0.3 |

* Phase offsets: no two independent motions share Speed AND Phase unless they are mirrored
  partners. Chains (antennae, tails, trunks) lag 0.05-0.15 phase per link. Walking pairs are
  built separately with Phase +0.5.
* The beauty side (-Z) must face within +-45 degrees of the viewer for >= 75% of the loop. A
  whole-body Spin is not allowed (spin orbit/flair groups instead).
* **Zero ANIM warnings** in charlab, and no part may leave the 6.4 x 9.5 x 6.4 box in any pose.

## 7. Rarity flair

Flair is added around the canonical design, never by changing it.

| Tier | Neon parts total (incl. 4 catch-lights) | Flair recipe |
|---|---|---|
| Common | 4-8 | catch-lights only; optional one small thematic emitter (Rate <= 2) |
| Uncommon | 6-12 | + 1 thematic emitter (Rate 2-3) and 2-6 Neon thematic accents (slime glow, droplets) |
| Rare | 8-20 | + warm key light on the face (Brightness 0.6-0.9) + 4-12 Neon glints on the signature prop, one pulsing |
| Epic | 12-30 | + rim light, 3+ pulsing star glints, 2-3 emitters |
| Legendary | 15-40 | + an ORBIT group (Spin Y 0.1-0.15, radius 2.4-2.8) of 4-6 sparkles or mini props with phase-offset Bob |
| Mythic | 25-55 | + a ground effect (spinning Neon-trimmed ring, radius <= 2.5) and an orbit |
| Secret | 40-80 | + ForceField/Glass aura shell, halo of stars above the head, orbiting bodies |

Lights: key light in front of the face (z -2 to -2.5, at eye height +-0.5), Brightness <= 1.2,
Range 8-12; second light (rim or thematic ground glow) Brightness <= 1.0. Particles: Rate <= 6
per emitter, Size 0.12-0.4, Lifetime <= 2.5, at most 3 emitters (a `k:Mirror`ed emitter counts
twice).

## 8. Mini (conveyor version)

* 10-12 parts, centred (bounding-box centre within +-0.15 of the origin), largest dimension
  2.3-2.7, second-largest >= 1.2 (no paper-thin minis), no plinths or base slabs.
* Must contain: the dominant + secondary colour, the single most iconic feature (tyre, nose,
  bat, katanas, peel, fridge, tutu, propellers, sneakers, Saturn ring, pocket watch...), and a
  face: either white eye + dark pupil pairs, or dark eye balls >= 0.16 on a light skin.
  Eyes must be visible in both the front and the 3/4 mini tile.
* Head occupies the top 35-50% of the mini's height for upright characters. Faces -Z.
* Only Block/Ball/Ellipsoid/Cylinder/Wedge, no Neon/Anim/Light/Particles/Text.

## 9. Scale and proportion

All 12 stand side by side 8 studs apart; none may look tiny or cramped.

* Height: upright characters top out at **8.6-9.3** (90-98% of 9.5). Horizontal characters
  (shrimp, shark, plane) top out at **>= 7.5** and must fill >= 85% of one horizontal axis.
* Silhouette coverage (body mass, excluding Neon/ForceField/transparent flair) of the 6.4 x 9.5
  box: **front view 30-45%, 3/4 view 20-30%** (measure with the snippet below).
* Head / face-bearing volume width **2.0-2.9 studs** for every character - the face must read
  at the same size across the lineup.
* Footprint: stable ground contact of at least ~1.2 x 1.0 studs (soles, feet, stand base);
  the body-mass centroid within +-0.4 studs of the pedestal centre in X and +-0.75 in Z.
* Never leave the 6.4 footprint in any animation pose; keep 0.1-0.2 studs of margin.

Current measurements (body-mass silhouette coverage, front / 3/4):

| Character | Tier | Parts | Animated | Top y | Front | 3/4 | Verdict |
|---|---|---|---|---|---|---|---|
| Lirili Larila | Common | 100 | 18 | 8.43 | 55% | 31% | big, sparse |
| Boneca Ambalabu | Common | 100 | 23 | 9.32 | 36% | 24% | ok size, sparse |
| Brr Brr Patapim | Uncommon | 130 | 26 | 9.15 | 33% | 24% | ok size, sparse |
| Trippi Troppi | Uncommon | 171 | 48 | 6.69 | 29% | 17% | too low/small |
| Tung Tung Tung Sahur | Rare | 167 | 21 | 9.25 | 30% | 20% | ok |
| Cappuccino Assassino | Rare | 204 | 36 | 9.02 | 28% | 18% | slightly slim |
| Chimpanzini Bananini | Epic | 236 | 37 | 8.77 | 41% | 25% | ok |
| Frigo Camelo | Epic | 322 | 31 | 9.22 | 28% | 23% | narrow (41% width), tiny head |
| Ballerina Cappuccina | Legendary | 313 | 61 | 8.53 | 17% | 11% | far too small |
| Bombardiro Crocodilo | Legendary | 318 | 35 | 4.65 | 13% | 13% | far too low/small |
| Tralalero Tralala | Mythic | 292 | 50 | 7.51 | 21% | 19% | slightly small; tier inversion |
| La Vacca Saturno Saturnita | Secret | 386 | 74 | 9.07 | 41% | 27% | reference |

## 10. Definition of done (per character)

1. `check_all.py`: OK, zero warnings, zero ANIM warnings.
2. Parts, animated count, lights, particles and Neon count inside this guide's tier ranges.
3. Eyes follow section 1 (both Neon catch-lights, iris or iris ring, lid, brow, shared BLINK).
4. No `#ffffff`, nothing below value 0.08, no Block-built organic forms, no ball-joint limbs.
5. Front 30-45% / 3/4 20-30% coverage, head width 2.0-2.9, height rule met.
6. Contact sheet checked: front, 3/4, side, back all finished; both pose tiles keep limbs
   attached at their joints; mini readable in both mini tiles.

## Measurement snippet

Run from `roblox-tycoon/` (set LUAU to your luau binary):

```python
import sys, numpy as np
sys.path.insert(0, "tools/charlab"); import charlab
LUAU = "path/to/luau"; path = "src/shared/Characters/<Id>.luau"
sc = charlab.run_mock(LUAU, path, "full", None)
body = dict(sc, lights=[], particles=[], parts=[p for p in sc["parts"]
            if p["material"] not in ("Neon", "ForceField") and p["transparency"] < 0.3])
fb = [(-3.4, -0.2, -3.4), (3.4, 9.7, 3.4)]
def area(scene, vd):
    img, _ = charlab.render(scene, vd, (0, 1, 0), 340, 442, bounds=fb)
    bg, _ = charlab.render({"parts": [], "lights": [], "particles": []}, vd, (0, 1, 0), 340, 442, bounds=fb)
    return (np.abs(np.asarray(img, int) - np.asarray(bg, int)).sum(axis=2) > 30).sum()
box = {"parts": [{"cf": [0, 4.75, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1], "name": "B", "transparency": 0,
       "color": "#ff0000", "material": "SmoothPlastic", "shape": "Block", "size": [6.4, 9.5, 6.4]}],
       "lights": [], "particles": []}
for name, vd in (("front", (0, 0, 1)), ("3/4", (0.62, -0.25, 0.74))):
    print(name, f"{area(body, vd) / area(box, vd):.0%}")
neon = sum(p["material"] == "Neon" for p in sc["parts"])
small = sum(max(p["size"]) <= 0.35 for p in sc["parts"])
print("neon", neon, "tertiary share", f"{small / len(sc['parts']):.0%}")
```
