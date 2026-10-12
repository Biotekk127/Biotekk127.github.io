--[[
	Ballerina Cappuccina (Legendary)
	The prima ballerina of the brainrot opera: a slender dancer whose head is a glossy
	warm-white ceramic CAPPUCCINO CUP (rounded bowl, flared gold-banded rim, handle on her
	left side). The cup is brimming with a white milk-foam ring, a domed brown crema and a
	white latte-art heart, with steam curling up. A cute face is painted on the cup: big
	coffee-brown eyes with long lashes, rosy cheeks and a sweet open smile. She wears a
	fitted sparkly pink bodice with a sweetheart neckline, a fluffy layered pink tutu, pink
	tights and satin pointe shoes with crossed ribbons.

	Pose: en pointe on her right leg (toe on y = 0, on the spin axis) with the left leg in
	passe (knee out to the side, toe at the standing knee) and both arms en couronne
	(a rounded oval above the cup, hands almost touching). Animation: the whole dancer
	slowly PIROUETTES, the tutu tiers flutter, the arms sway (port de bras), the cup
	tilts, steam rises, eyes blink. Legendary flair: orbiting sparkles, gold accents,
	sequins, a soft pink light and glitter.

	Faces -Z. Feet on y = 0. Built only through the CharacterKit builder `k`.
]]

-- Palette ------------------------------------------------------------------------------
local CUP = "#fff8f2" -- warm white glazed ceramic
local CUP_SHADE = "#efe2d8" -- foot ring
local GOLD = "#f2c25a" -- rim bands, sequins
local CREMA = "#c98d5c" -- crema surface
local CREMA_D = "#a86a40" -- darker inner crema
local FOAM = "#fff4e6" -- milk foam / latte art
local STEAM = "#fffaf4"

local SKIN = "#ffdcc8" -- arms, shoulders, neck
local SKIN_D = "#f3c2aa" -- thumbs / shading
local TIGHTS = "#ffbdd3" -- ballet tights (pink)
local SHOE = "#f06fa8" -- satin pointe shoes
local RIBBON = "#dc5a93" -- shoe ribbons
local SOLE = "#c98f72" -- leather sole strip

local BODICE = "#ec5c9a" -- sparkly leotard bodice
local BODICE_D = "#c9437f" -- seams, trims
local TUTU_1 = "#f27fb2" -- under layer
local TUTU_2 = "#fb93c4"
local TUTU_3 = "#ffa6d0"
local TUTU_4 = "#ffb9db" -- top, lightest layer
local SPARK = "#ffe3f1" -- sequins (neon)
local GEM = "#ff4fa3"

local EYE_W = "#fff8ec"
local IRIS = "#6a3b25" -- coffee-brown eyes
local INK = "#2a1a24"
local BROW = "#7a4a36"
local BLUSH = "#ff9db8"
local MOUTH = "#7a2238"
local TONGUE = "#ff86a6"

local UP = { 0, 0, 90 } -- stands a Cylinder upright (axis along Y)

-- Helpers --------------------------------------------------------------------------------
local function lerp(a, b, t)
	return { a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t, a[3] + (b[3] - a[3]) * t }
end

-- Rotation that points a part's local X axis from a to b (rx = 0).
local function aim(a, b)
	local dx, dy, dz = b[1] - a[1], b[2] - a[2], b[3] - a[3]
	local len = math.sqrt(dx * dx + dy * dy + dz * dz)
	local rz = math.deg(math.asin(dy / len))
	local ry = math.deg(math.atan2(-dz, dx))
	return len, { 0, ry, rz }
end

-- A limb segment between two points: Cylinder (round) or Ellipsoid (tapered, organic).
local function limb(k, name, a, b, d, color, opt)
	opt = opt or {}
	local len, rot = aim(a, b)
	local shape = opt.shape or "Cylinder"
	k:Part({
		Name = name,
		Shape = shape,
		Size = { len * (opt.stretch or 1), d, opt.dz or d },
		Pos = lerp(a, b, 0.5),
		Rot = rot,
		Color = color,
		Material = opt.material,
		Reflectance = opt.reflectance,
		Transparency = opt.transparency,
	})
end

-- A smooth limb: a round cylinder core plus a tapered muscle bulge (no pinched joints).
local function softLimb(k, name, a, b, dCore, dBulge, at, span, color, back)
	limb(k, name, a, b, dCore, color)
	local m1 = lerp(a, b, at - span)
	local m2 = lerp(a, b, at + span)
	if back then
		m1[3] += back
		m2[3] += back
	end
	limb(k, name .. "Muscle", m1, m2, dBulge, color, { shape = "Ellipsoid", stretch = 1.15 })
end

-- Front (or back) surface z of a set of ellipsoids at (x, y).
local function surf(shapes, x, y, back)
	local best = 0
	local bz = 0
	for _, e in shapes do
		local u = (x - e.c[1]) / (e.s[1] / 2)
		local v = (y - e.c[2]) / (e.s[2] / 2)
		local q = 1 - u * u - v * v
		if q > 0 then
			local d = math.sqrt(q) * e.s[3] / 2
			local z = if back then e.c[3] + d else e.c[3] - d
			if math.abs(z) > best then
				best = math.abs(z)
				bz = z
			end
		end
	end
	return bz
end

-- The cappuccino cup profile (head-local): a rounded bowl below BOWL_Y, a straight glazed
-- wall above it and a slightly flared rim. cupR(y) is the outer radius at height y.
local WALL_R = 0.98
local BOWL_Y = 0.72
local BOWL_H = 0.65
local FLARE_Y = 1.5
local function cupR(y)
	if y >= FLARE_Y then
		return 1.0
	end
	if y >= BOWL_Y then
		return WALL_R
	end
	local v = (BOWL_Y - y) / BOWL_H
	return WALL_R * math.sqrt(math.max(0, 1 - v * v))
end
-- Points on the cup surface: theta in degrees from the front (-Z) towards +X.
local function onCup(theta, y, out)
	local a = math.rad(theta)
	local r = cupR(y) + (out or 0)
	return { r * math.sin(a), y, -r * math.cos(a) }
end

-- One tier of tutu ruffles: n wide, overlapping flattened ellipsoids around the hips,
-- tilted down at the rim, with a wavy (alternating) tulle edge.
local function tutuTier(k, n, r, size, tilt, color, offset)
	for i = 0, n - 1 do
		local a = offset + i * 360 / n
		local ra = math.rad(a)
		local ruffle = if i % 2 == 0 then 3 else -3
		k:Part({
			Name = "TutuRuffle",
			Shape = "Ellipsoid",
			Size = size,
			Pos = { r * math.cos(ra), (if i % 2 == 0 then -0.025 else 0.025), -r * math.sin(ra) },
			Rot = { 0, a, -(tilt + ruffle) },
			Color = color,
			Material = "SmoothPlastic",
		})
	end
end

-- Sequins on top of the ruffles of a tier (at every `step`-th ruffle, near the outer edge).
local function tutuSequins(k, n, r, size, tilt, offset, step)
	local A = size[1] / 2
	local T = size[2] / 2
	local u = A * 0.62
	for i = 0, n - 1, step do
		local ruffle = if i % 2 == 0 then 3 else -3
		local t = math.rad(tilt + ruffle)
		local h = T * math.sqrt(1 - (u / A) ^ 2)
		local rr = r + u * math.cos(t) + h * math.sin(t) * 0.3
		local y = (if i % 2 == 0 then -0.025 else 0.025) - u * math.sin(t) + h * math.cos(t)
		local a = math.rad(offset + i * 360 / n)
		local gold = (i / step) % 2 == 0
		k:Part({
			Name = "TutuSequin",
			Shape = "Ball",
			Size = { 0.1, 0.1, 0.1 },
			Pos = { rr * math.cos(a), y, -rr * math.sin(a) },
			Color = if gold then GOLD else SPARK,
			Material = if gold then "Foil" else "Neon",
		})
	end
end

-- Bodice (fitted corset: slim waist, ribcage, low bust) and the upper body shapes.
local TORSO_SHAPES = {
	{ c = { 0, 4.2, 0.01 }, s = { 0.66, 0.74, 0.48 } },
	{ c = { 0, 4.6, 0.01 }, s = { 0.84, 0.84, 0.56 } },
	{ c = { 0, 4.86, 0.0 }, s = { 0.9, 0.36, 0.6 } },
}
local BUST_CUP = { c = { 0.19, 5.0, -0.13 }, s = { 0.4, 0.34, 0.3 } }
local CHEST = { c = { 0, 5.1, 0.03 }, s = { 0.8, 0.5, 0.48 } }
local SHOULDERS = { c = { 0, 5.24, 0.03 }, s = { 1.02, 0.3, 0.44 } }
local BODY_SHAPES = {
	TORSO_SHAPES[1],
	TORSO_SHAPES[2],
	TORSO_SHAPES[3],
	BUST_CUP,
	{ c = { -0.19, 5.0, -0.13 }, s = BUST_CUP.s },
	CHEST,
	SHOULDERS,
}

-- Pointe shoe + crossed ribbons, built in ankle space (foot points along local -Y,
-- instep faces local -Z).
local function pointeShoe(k)
	k:Part({ Name = "Heel", Shape = "Ellipsoid", Size = { 0.25, 0.27, 0.23 }, Pos = { 0, -0.1, 0.09 }, Color = SHOE, Reflectance = 0.08 })
	k:Part({ Name = "ShoeBody", Shape = "Ellipsoid", Size = { 0.31, 0.68, 0.36 }, Pos = { 0, -0.36, -0.01 }, Color = SHOE, Reflectance = 0.08 })
	k:Part({ Name = "Instep", Shape = "Ellipsoid", Size = { 0.27, 0.44, 0.28 }, Pos = { 0, -0.27, -0.08 }, Color = SHOE, Reflectance = 0.08 })
	k:Part({ Name = "ToeBox", Shape = "Ellipsoid", Size = { 0.27, 0.3, 0.3 }, Pos = { 0, -0.59, -0.03 }, Color = SHOE, Reflectance = 0.08 })
	k:Part({ Name = "Platform", Shape = "Cylinder", Size = { 0.06, 0.15, 0.15 }, Pos = { 0, -0.72, -0.03 }, Rot = UP, Color = RIBBON })
	k:Part({ Name = "SoleStrip", Size = { 0.07, 0.42, 0.05 }, Pos = { 0, -0.38, 0.16 }, Color = SOLE, Material = "Leather" })
	k:Part({ Name = "Binding", Shape = "Cylinder", Size = { 0.05, 0.31, 0.31 }, Pos = { 0, -0.03, 0 }, Rot = UP, Color = RIBBON })
	-- ribbons wrapped around the ankle and crossed in front and behind
	k:Part({ Name = "RibbonWrap", Shape = "Cylinder", Size = { 0.05, 0.28, 0.28 }, Pos = { 0, 0.14, 0 }, Rot = UP, Color = RIBBON })
	k:Part({ Name = "RibbonWrap", Shape = "Cylinder", Size = { 0.05, 0.27, 0.27 }, Pos = { 0, 0.36, 0 }, Rot = UP, Color = RIBBON })
	for s = -1, 1, 2 do
		k:Part({ Name = "RibbonCross", Size = { 0.05, 0.3, 0.05 }, Pos = { 0, 0.25, -0.13 }, Rot = { 0, 0, 34 * s }, Color = RIBBON })
		k:Part({ Name = "RibbonCross", Size = { 0.05, 0.3, 0.05 }, Pos = { 0, 0.25, 0.13 }, Rot = { 0, 0, 34 * s }, Color = RIBBON })
	end
end

-- A leg in tights from hip to ankle, with a shaped thigh, knee, calf and shin.
local function leg(k, name, hip, knee, ankle, footRot)
	k:Group({ Name = name }, function()
		softLimb(k, "Thigh", hip, knee, 0.31, 0.44, 0.32, 0.34, TIGHTS)
		k:Part({ Name = "Knee", Shape = "Ball", Size = { 0.29, 0.29, 0.29 }, Pos = knee, Color = TIGHTS })
		softLimb(k, "Shin", knee, ankle, 0.22, 0.33, 0.3, 0.28, TIGHTS, 0.03)
		k:Part({ Name = "Ankle", Shape = "Ball", Size = { 0.22, 0.22, 0.22 }, Pos = ankle, Color = TIGHTS })
		k:Group({ Name = "Foot", Pos = ankle, Rot = footRot }, function()
			pointeShoe(k)
		end)
	end)
end

-- A four-point sparkle (three crossed neon bars) that pulses.
local function sparkle(k, pos, size, color, phase)
	for i = 1, 3 do
		local s = { 0.07, 0.07, 0.07 }
		s[i] = size
		k:Part({
			Name = "Sparkle",
			Size = s,
			Pos = pos,
			Rot = { 0, 45, 0 },
			Color = color,
			Material = "Neon",
			Anim = { Type = "Pulse", Amount = 0.35, Speed = 0.9, Phase = phase },
		})
	end
end

-- Character ------------------------------------------------------------------------------
return {
	Id = "BallerinaCappuccina",
	Name = "Ballerina Cappuccina",
	Rarity = "Legendary",
	Emoji = "🩰",
	Color = "#ff8fc3",
	Tagline = "Pirouettes on one toe and never spills a drop.",
	Lore = "The prima ballerina of the brainrot opera, she spins three hundred pirouettes a night without spilling a single drop of foam. Mi-mi-mi! Her heart (and her latte art) belongs to Cappuccino Assassino.",

	Build = function(k)
		-- The whole dancer pirouettes slowly around her standing toe (y axis).
		k:Group({ Name = "Dancer", Anim = { Type = "Spin", Axis = "Y", Speed = 0.2 } }, function()
			---------------------------------------------------------------- legs
			-- right leg: en pointe, straight, on the spin axis
			leg(k, "StandingLeg", { 0.19, 3.62, 0.02 }, { 0.1, 2.2, -0.03 }, { 0.02, 0.75, 0.0 }, { 0, 0, 0 })
			-- left leg: passe, knee out to the side, pointed toe resting at the standing knee
			leg(k, "PasseLeg", { -0.2, 3.6, 0.0 }, { -1.5, 3.1, -0.3 }, { -0.45, 2.5, -0.33 }, { 0, 0, 60 })

			---------------------------------------------------------------- hips + waist
			k:Part({ Name = "Pelvis", Shape = "Ellipsoid", Size = { 0.86, 0.56, 0.62 }, Pos = { 0, 3.8, 0.02 }, Color = BODICE })
			k:Part({ Name = "Waistband", Shape = "Ellipsoid", Size = { 0.69, 0.1, 0.52 }, Pos = { 0, 4.07, 0.01 }, Color = BODICE_D, Reflectance = 0.1 })
			k:Part({ Name = "WaistGem", Shape = "Ball", Size = { 0.11, 0.11, 0.11 }, Pos = { 0, 4.07, -0.25 }, Color = GEM, Material = "Neon" })

			-- satin bow at the back of the waist
			k:Group({ Name = "BackBow", Pos = { 0, 4.26, surf(TORSO_SHAPES, 0, 4.26, true) + 0.03 } }, function()
				k:Part({ Name = "BowKnot", Shape = "Ball", Size = { 0.13, 0.13, 0.13 }, Color = BODICE_D, Reflectance = 0.1 })
				k:Mirror(function()
					k:Part({ Name = "BowLoop", Shape = "Ellipsoid", Size = { 0.3, 0.17, 0.08 }, Pos = { 0.15, 0.04, 0.0 }, Rot = { 0, 0, 18 }, Color = BODICE_D, Reflectance = 0.1 })
					k:Part({ Name = "BowTail", Shape = "Ellipsoid", Size = { 0.08, 0.3, 0.05 }, Pos = { 0.08, -0.18, 0.02 }, Rot = { 0, 0, 14 }, Color = BODICE_D, Reflectance = 0.1 })
				end)
			end)

			---------------------------------------------------------------- tutu (fluffy, 4 fluttering tiers)
			-- a soft tulle core fills the gaps so the tutu reads as one fluffy mass
			k:Part({ Name = "TutuCore", Shape = "Ellipsoid", Size = { 2.9, 0.58, 2.9 }, Pos = { 0, 3.7, 0 }, Color = TUTU_1 })
			local UNDER = { 1.36, 0.24, 1.08 }
			local MID = { 1.38, 0.26, 1.08 }
			local UPPER = { 1.26, 0.26, 1.0 }
			k:Group({ Name = "TutuUnder", Pos = { 0, 3.5, 0 }, Anim = { Type = "Wiggle", Axis = "Z", Amount = 2, Speed = 0.5, Phase = 0.6 } }, function()
				tutuTier(k, 16, 1.28, UNDER, 24, TUTU_1, 0)
			end)
			k:Group({ Name = "TutuMid", Pos = { 0, 3.66, 0 }, Anim = { Type = "Wiggle", Axis = "X", Amount = 2.5, Speed = 0.5, Phase = 0 } }, function()
				tutuTier(k, 16, 1.24, MID, 14, TUTU_2, 11.25)
				tutuSequins(k, 16, 1.24, MID, 14, 11.25, 4)
			end)
			k:Group({ Name = "TutuUpper", Pos = { 0, 3.82, 0 }, Anim = { Type = "Wiggle", Axis = "Z", Amount = 2.5, Speed = 0.5, Phase = 0.3 } }, function()
				tutuTier(k, 14, 1.02, UPPER, 8, TUTU_3, 0)
				tutuSequins(k, 14, 1.02, UPPER, 8, 0, 4)
			end)
			k:Group({ Name = "TutuTop", Pos = { 0, 3.97, 0 }, Anim = { Type = "Bob", Axis = "Y", Amount = 0.025, Speed = 0.5, Phase = 0.15 } }, function()
				tutuTier(k, 10, 0.66, { 0.92, 0.24, 0.74 }, 4, TUTU_4, 18)
			end)

			---------------------------------------------------------------- torso
			for _, e in TORSO_SHAPES do
				k:Part({ Name = "Bodice", Shape = "Ellipsoid", Size = e.s, Pos = e.c, Color = BODICE, Reflectance = 0.05 })
			end
			k:Part({ Name = "Chest", Shape = "Ellipsoid", Size = CHEST.s, Pos = CHEST.c, Color = SKIN })
			k:Part({ Name = "Shoulders", Shape = "Ellipsoid", Size = SHOULDERS.s, Pos = SHOULDERS.c, Color = SKIN })
			k:Mirror(function()
				-- sweetheart neckline cups
				k:Part({ Name = "BustCup", Shape = "Ellipsoid", Size = BUST_CUP.s, Pos = BUST_CUP.c, Color = BODICE, Reflectance = 0.05 })
				k:Part({ Name = "ShoulderCap", Shape = "Ball", Size = { 0.28, 0.28, 0.28 }, Pos = { 0.5, 5.24, 0.03 }, Color = SKIN })
				-- thin straps over the shoulders
				local f = { 0.3, 5.12, surf(BODY_SHAPES, 0.3, 5.12) + 0.01 }
				local t = { 0.33, 5.36, 0.03 }
				local b = { 0.3, 5.12, surf(BODY_SHAPES, 0.3, 5.12, true) - 0.01 }
				limb(k, "Strap", f, t, 0.06, BODICE_D)
				limb(k, "Strap", t, b, 0.06, BODICE_D)
				-- princess seam (boning) running down the bodice
				local s1 = { 0.2, 4.88, surf(BODY_SHAPES, 0.2, 4.88) - 0.005 }
				local s2 = { 0.19, 4.46, surf(BODY_SHAPES, 0.19, 4.46) - 0.005 }
				local s3 = { 0.13, 4.1, surf(BODY_SHAPES, 0.13, 4.1) - 0.005 }
				limb(k, "Seam", s1, s2, 0.05, BODICE_D)
				limb(k, "Seam", s2, s3, 0.05, BODICE_D)
				-- a few neon sparkles sewn on the bodice
				for _, p in { { 0.16, 5.06 }, { 0.3, 4.62 }, { 0.09, 4.36 } } do
					k:Part({ Name = "BodiceSparkle", Shape = "Ball", Size = { 0.07, 0.07, 0.07 }, Pos = { p[1], p[2], surf(BODY_SHAPES, p[1], p[2]) }, Color = SPARK, Material = "Neon" })
				end
				-- pearl trim along the sweetheart neckline
				for _, x in { 0.06, 0.15, 0.24, 0.33 } do
					local u = (x - BUST_CUP.c[1]) / (BUST_CUP.s[1] / 2)
					local y = BUST_CUP.c[2] + BUST_CUP.s[2] / 2 * math.sqrt(math.max(0, 1 - u * u)) - 0.04
					k:Part({ Name = "Pearl", Shape = "Ball", Size = { 0.075, 0.075, 0.075 }, Pos = { x, y, surf(BODY_SHAPES, x, y) }, Color = EYE_W, Reflectance = 0.15 })
				end
			end)
			-- centre-front seam and a heart-shaped brooch at the neckline
			limb(k, "Seam", { 0, 4.9, surf(BODY_SHAPES, 0, 4.9) - 0.005 }, { 0, 4.12, surf(BODY_SHAPES, 0, 4.12) - 0.005 }, 0.05, BODICE_D)
			k:Part({ Name = "Brooch", Shape = "Ball", Size = { 0.13, 0.13, 0.13 }, Pos = { 0, 4.97, surf(BODY_SHAPES, 0, 4.97) - 0.01 }, Color = GEM, Material = "Neon" })
			-- criss-cross lacing on the back of the bodice
			for j = 0, 2 do
				local y = 4.46 + j * 0.2
				for s = -1, 1, 2 do
					k:Part({ Name = "BackLace", Size = { 0.05, 0.26, 0.05 }, Pos = { 0, y, surf(TORSO_SHAPES, 0, y, true) }, Rot = { 0, 0, 40 * s }, Color = BODICE_D })
				end
			end

			---------------------------------------------------------------- neck
			k:Part({ Name = "Neck", Shape = "Cylinder", Size = { 0.42, 0.3, 0.3 }, Pos = { 0, 5.45, 0.03 }, Rot = UP, Color = SKIN })
			k:Part({ Name = "Choker", Shape = "Cylinder", Size = { 0.07, 0.335, 0.335 }, Pos = { 0, 5.43, 0.03 }, Rot = UP, Color = BODICE_D, Reflectance = 0.1 })
			k:Part({ Name = "ChokerGem", Shape = "Ball", Size = { 0.1, 0.1, 0.1 }, Pos = { 0, 5.41, -0.14 }, Color = GEM, Material = "Neon" })

			---------------------------------------------------------------- arms en couronne
			k:Mirror(function()
				k:Group({ Name = "Arm", Pos = { 0.5, 5.24, 0.03 }, Anim = { Type = "Wiggle", Axis = "Z", Amount = 4, Speed = 0.4 } }, function()
					local E = { 1.1, 1.62, -0.34 }
					softLimb(k, "UpperArm", { 0.0, 0.0, 0.0 }, E, 0.21, 0.28, 0.34, 0.28, SKIN)
					k:Part({ Name = "Elbow", Shape = "Ball", Size = { 0.2, 0.2, 0.2 }, Pos = E, Color = SKIN })
					k:Group({ Name = "Forearm", Pos = E, Anim = { Type = "Wiggle", Axis = "Z", Amount = 5, Speed = 0.4, Phase = 0.12 } }, function()
						local W = { -1.0, 1.2, 0.14 }
						softLimb(k, "Forearm", { 0, 0, 0 }, W, 0.17, 0.23, 0.32, 0.26, SKIN)
						k:Part({ Name = "Wrist", Shape = "Ball", Size = { 0.155, 0.155, 0.155 }, Pos = W, Color = SKIN })
						limb(k, "WristRibbon", lerp({ 0, 0, 0 }, W, 0.85), lerp({ 0, 0, 0 }, W, 0.9), 0.19, RIBBON)
						k:Group({ Name = "Hand", Pos = W, Anim = { Type = "Wiggle", Axis = "Z", Amount = 7, Speed = 0.4, Phase = 0.25 } }, function()
							limb(k, "Palm", { 0.02, -0.01, 0 }, { -0.3, 0.08, 0.0 }, 0.13, SKIN, { shape = "Ellipsoid", dz = 0.2, stretch = 1.1 })
							limb(k, "Fingers", { -0.24, 0.07, 0 }, { -0.5, 0.06, 0.0 }, 0.09, SKIN, { shape = "Ellipsoid", dz = 0.17, stretch = 1.1 })
							limb(k, "Thumb", { -0.1, 0.0, -0.08 }, { -0.26, 0.05, -0.12 }, 0.07, SKIN_D, { shape = "Ellipsoid", stretch = 1.15 })
						end)
					end)
				end)
			end)

			---------------------------------------------------------------- the cappuccino cup head
			k:Group({ Name = "Head", Pos = { 0, 5.58, 0.03 }, Anim = { Type = "Wiggle", Axis = "Z", Amount = 3, Speed = 0.4, Phase = 0.4 } }, function()
				-- cup body: foot ring, rounded bowl, glazed wall, flared rim, rolled lip
				k:Part({ Name = "FootRing", Shape = "Cylinder", Size = { 0.08, 0.96, 0.96 }, Pos = { 0, 0.04, 0 }, Rot = UP, Color = CUP_SHADE })
				k:Part({ Name = "CupBowl", Shape = "Ellipsoid", Size = { WALL_R * 2, BOWL_H * 2, WALL_R * 2 }, Pos = { 0, BOWL_Y, 0 }, Color = CUP, Reflectance = 0.1 })
				k:Part({ Name = "CupWall", Shape = "Cylinder", Size = { FLARE_Y - BOWL_Y + 0.02, WALL_R * 2, WALL_R * 2 }, Pos = { 0, (BOWL_Y + FLARE_Y) / 2, 0 }, Rot = UP, Color = CUP, Reflectance = 0.1 })
				k:Part({ Name = "CupFlare", Shape = "Cylinder", Size = { 0.12, 2.0, 2.0 }, Pos = { 0, 1.55, 0 }, Rot = UP, Color = CUP, Reflectance = 0.1 })
				k:Part({ Name = "Lip", Shape = "Cylinder", Size = { 0.1, 2.06, 2.06 }, Pos = { 0, 1.63, 0 }, Rot = UP, Color = CUP, Reflectance = 0.12 })
				k:Part({ Name = "GoldBand", Shape = "Cylinder", Size = { 0.05, 2.03, 2.03 }, Pos = { 0, FLARE_Y, 0 }, Rot = UP, Color = GOLD, Material = "Foil" })
				k:Part({ Name = "GoldBand", Shape = "Cylinder", Size = { 0.05, 1.74, 1.74 }, Pos = { 0, 0.4, 0 }, Rot = UP, Color = GOLD, Material = "Foil" })

				-- the cappuccino: white milk-foam ring, domed crema, latte-art heart
				k:Part({ Name = "FoamRim", Shape = "Ellipsoid", Size = { 2.0, 0.26, 2.0 }, Pos = { 0, 1.67, 0 }, Color = FOAM })
				k:Part({ Name = "Crema", Shape = "Ellipsoid", Size = { 1.66, 0.34, 1.66 }, Pos = { 0, 1.69, 0 }, Color = CREMA })
				k:Part({ Name = "CremaInner", Shape = "Ellipsoid", Size = { 1.2, 0.34, 1.2 }, Pos = { 0, 1.7, 0 }, Color = CREMA_D })
				k:Mirror(function()
					k:Part({ Name = "HeartLobe", Shape = "Ellipsoid", Size = { 0.38, 0.07, 0.38 }, Pos = { 0.17, 1.855, 0.08 }, Color = FOAM })
				end)
				k:Part({ Name = "HeartPoint", Size = { 0.34, 0.07, 0.34 }, Pos = { 0, 1.855, -0.1 }, Rot = { 0, 45, 0 }, Color = FOAM })
				-- little foam bubbles around the rim (not over the heart)
				for i = 0, 5 do
					local a = math.rad(30 + i * 60)
					local s = if i % 2 == 0 then 0.12 else 0.09
					k:Part({ Name = "FoamBubble", Shape = "Ball", Size = { s, s, s }, Pos = { 0.86 * math.sin(a), 1.75, -0.86 * math.cos(a) }, Color = FOAM })
				end

				-- glossy highlight streak on the glaze (well to the side of the face)
				k:Group({ Pos = onCup(64, 1.05, 0), Rot = { 0, -64, 0 } }, function()
					k:Part({ Name = "GlazeShine", Shape = "Ellipsoid", Size = { 0.08, 0.62, 0.05 }, Color = "#ffffff", Reflectance = 0.3, Transparency = 0.3 })
				end)

				-- handle on her left (-X) side, turned slightly back: a smooth ear-shaped loop
				k:Group({ Name = "Handle", Rot = { 0, 15, 0 } }, function()
					local pts = {}
					for i = 0, 8 do
						local phi = math.rad(90 - i * 22.5)
						table.insert(pts, { -0.9 - 0.46 * math.cos(phi), 1.0 + 0.38 * math.sin(phi), 0 })
					end
					for i = 1, 8 do
						limb(k, "HandleLoop", pts[i], pts[i + 1], 0.17, CUP, { shape = "Ellipsoid", stretch = 1.45, dz = 0.15, reflectance = 0.1 })
					end
					k:Part({ Name = "ThumbRest", Shape = "Ellipsoid", Size = { 0.26, 0.09, 0.14 }, Pos = { -1.14, 1.42, 0 }, Rot = { 0, 0, -12 }, Color = CUP, Reflectance = 0.1 })
				end)

				-- little pink heart painted on the back of the cup
				k:Group({ Pos = onCup(180, 1.0, 0), Rot = { 0, 180, 0 } }, function()
					k:Mirror(function()
						k:Part({ Name = "BackHeartLobe", Shape = "Ellipsoid", Size = { 0.22, 0.22, 0.06 }, Pos = { 0.08, 0.04, 0 }, Color = TUTU_2 })
					end)
					k:Part({ Name = "BackHeartPoint", Size = { 0.21, 0.21, 0.05 }, Pos = { 0, -0.05, 0 }, Rot = { 0, 0, 45 }, Color = TUTU_2 })
				end)

				-- face ---------------------------------------------------------------
				k:Mirror(function()
					k:Group({ Name = "Eye", Pos = onCup(25, 1.03, 0), Rot = { 0, -25, 0 } }, function()
						local blink = { Type = "Blink", Speed = 0.22, Phase = 0.1 }
						k:Part({ Name = "EyeWhite", Shape = "Ellipsoid", Size = { 0.44, 0.54, 0.14 }, Color = EYE_W, Anim = blink })
						k:Part({ Name = "Iris", Shape = "Ellipsoid", Size = { 0.31, 0.39, 0.1 }, Pos = { -0.02, -0.03, -0.04 }, Color = IRIS, Anim = blink })
						k:Part({ Name = "Pupil", Shape = "Ellipsoid", Size = { 0.16, 0.22, 0.08 }, Pos = { -0.02, -0.04, -0.07 }, Color = INK, Anim = blink })
						k:Part({ Name = "Shine", Shape = "Ball", Size = { 0.11, 0.11, 0.11 }, Pos = { 0.04, 0.07, -0.1 }, Color = EYE_W, Anim = blink })
						k:Part({ Name = "Shine2", Shape = "Ball", Size = { 0.05, 0.05, 0.05 }, Pos = { -0.08, -0.1, -0.095 }, Color = EYE_W, Anim = blink })
						-- thin eyeliner that flicks out at the outer corner
						k:Part({ Name = "Liner", Shape = "Ellipsoid", Size = { 0.46, 0.055, 0.08 }, Pos = { 0.0, 0.255, -0.03 }, Rot = { 0, 0, -4 }, Color = INK })
						for j, phi in { 12, 36, 60 } do
							local a = math.rad(phi)
							local len = 0.15 - j * 0.017
							k:Part({
								Name = "Lash",
								Size = { 0.05, len, 0.05 },
								Pos = { (0.22 + len / 2) * math.cos(a), (0.27 + len / 2) * math.sin(a), -0.03 },
								Rot = { 0, 0, phi - 90 },
								Color = INK,
							})
						end
						for _, phi in { -24, -50 } do
							local a = math.rad(phi)
							k:Part({ Name = "LowerLash", Size = { 0.05, 0.08, 0.05 }, Pos = { 0.26 * math.cos(a), 0.31 * math.sin(a), -0.02 }, Rot = { 0, 0, phi - 90 }, Color = INK })
						end
						k:Part({ Name = "Brow", Shape = "Ellipsoid", Size = { 0.28, 0.05, 0.05 }, Pos = { 0.03, 0.4, -0.01 }, Rot = { 0, 0, -10 }, Color = BROW })
					end)
					k:Group({ Name = "Cheek", Pos = onCup(44, 0.8, 0), Rot = { 0, -44, 0 } }, function()
						k:Part({ Name = "Blush", Shape = "Ellipsoid", Size = { 0.28, 0.15, 0.05 }, Color = BLUSH })
					end)
				end)
				k:Group({ Name = "Mouth", Pos = onCup(0, 0.78, 0) }, function()
					k:Part({ Name = "MouthOpen", Shape = "Ellipsoid", Size = { 0.38, 0.22, 0.06 }, Color = MOUTH })
					k:Part({ Name = "Tongue", Shape = "Ellipsoid", Size = { 0.19, 0.08, 0.05 }, Pos = { 0, -0.055, -0.02 }, Color = TONGUE })
					k:Part({ Name = "Teeth", Shape = "Ellipsoid", Size = { 0.24, 0.05, 0.05 }, Pos = { 0, 0.03, -0.018 }, Color = EYE_W })
					k:Part({ Name = "UpperLipCover", Shape = "Ellipsoid", Size = { 0.46, 0.15, 0.07 }, Pos = { 0, 0.085, -0.002 }, Color = CUP })
				end)

				-- steam wisps curling up from the crema
				local function wisp(name, base, pts, phase)
					k:Group({ Name = name, Pos = base, Anim = { Type = "Bob", Axis = "Y", Amount = 0.08, Speed = 0.45, Phase = phase } }, function()
						for j, p in pts do
							k:Part({
								Name = "Steam",
								Shape = "Ellipsoid",
								Size = { p[3], p[4], p[3] },
								Pos = { p[1], p[2], 0 },
								Rot = { 0, 0, p[5] },
								Color = STEAM,
								Transparency = 0.42 + j * 0.1,
								Anim = { Type = "Pulse", Amount = 0.12, Speed = 0.6, Phase = phase + j * 0.15 },
							})
						end
					end)
				end
				-- an S-curl: each puff leans the other way and overlaps the last
				wisp("SteamMid", { 0, 1.92, 0.32 }, { { 0.04, 0.12, 0.13, 0.32, -30 }, { 0.06, 0.36, 0.12, 0.3, 30 }, { -0.02, 0.6, 0.11, 0.28, -30 }, { 0.0, 0.83, 0.09, 0.24, 26 } }, 0)
				k:Mirror(function()
					wisp("SteamSide", { 0.42, 1.88, 0.14 }, { { 0.03, 0.12, 0.12, 0.28, -30 }, { 0.05, 0.35, 0.1, 0.26, 30 }, { -0.01, 0.56, 0.08, 0.22, -26 } }, 0.35)
				end)
			end)
		end)

		---------------------------------------------------------------- legendary flair
		k:Group({ Name = "SparkleOrbit", Anim = { Type = "Spin", Axis = "Y", Speed = 0.3 } }, function()
			local orbit = {
				{ 0, 1.1, GEM }, { 72, 5.2, GOLD }, { 144, 2.4, SPARK }, { 216, 6.8, GEM }, { 288, 8.2, GOLD },
			}
			for i, o in orbit do
				local a = math.rad(o[1])
				sparkle(k, { 2.7 * math.sin(a), o[2], -2.7 * math.cos(a) }, 0.38, o[3], i * 0.2)
			end
		end)
		k:Light({ Pos = { 0, 4.6, -1.2 }, Color = "#ff8cc6", Range = 11, Brightness = 1.2 })
		k:Light({ Pos = { 0, 8.0, -0.6 }, Color = "#ffd9a0", Range = 8, Brightness = 0.8 })
		k:Particles({ Pos = { 0, 7.6, 0.1 }, Color = STEAM, Color2 = "#ffe6d6", Rate = 3, Size = 0.4, Speed = 0.7, Lifetime = 1.6, Spread = 18, Direction = "Top" })
		k:Particles({ Pos = { 0, 3.8, 0 }, Color = "#ff7fbf", Color2 = "#fff1a8", Rate = 5, Size = 0.18, Speed = 1.8, Lifetime = 1.1, Spread = 90, Direction = "Top" })
		k:Particles({ Pos = { 0, 0.12, 0 }, Color = GOLD, Color2 = "#ff9fd0", Rate = 4, Size = 0.16, Speed = 1.2, Lifetime = 1.0, Spread = 70, Direction = "Top" })
	end,

	BuildMini = function(k)
		-- one pink leg en pointe under a puffy two-layer tutu, pink bodice, a rounded cup
		-- head with handle, crema top and big eyes, and both arms raised beside the cup
		k:Part({ Name = "Leg", Shape = "Ellipsoid", Size = { 0.17, 0.92, 0.17 }, Pos = { 0, -0.86, 0 }, Color = SHOE })
		k:Part({ Name = "Tutu", Shape = "Ellipsoid", Size = { 1.95, 0.42, 1.95 }, Pos = { 0, -0.38, 0 }, Color = TUTU_1 })
		k:Part({ Name = "TutuTop", Shape = "Ellipsoid", Size = { 1.4, 0.38, 1.4 }, Pos = { 0, -0.24, 0 }, Color = TUTU_4 })
		k:Part({ Name = "Torso", Shape = "Ellipsoid", Size = { 0.38, 0.58, 0.3 }, Pos = { 0, 0.0, 0 }, Color = BODICE })
		k:Part({ Name = "CupBowl", Shape = "Ellipsoid", Size = { 0.92, 0.46, 0.92 }, Pos = { 0, 0.5, 0 }, Color = CUP })
		k:Part({ Name = "Cup", Shape = "Cylinder", Size = { 0.5, 0.92, 0.92 }, Pos = { 0, 0.77, 0 }, Rot = UP, Color = CUP })
		k:Part({ Name = "Crema", Shape = "Ellipsoid", Size = { 0.88, 0.2, 0.88 }, Pos = { 0, 1.03, 0 }, Color = CREMA })
		k:Part({ Name = "Handle", Shape = "Cylinder", Size = { 0.1, 0.42, 0.42 }, Pos = { -0.5, 0.74, 0.06 }, Rot = { 0, 90, 0 }, Color = CUP })
		k:Mirror(function()
			k:Part({ Name = "Eye", Shape = "Ellipsoid", Size = { 0.16, 0.21, 0.1 }, Pos = { 0.16, 0.78, -0.44 }, Color = INK })
			limb(k, "Arm", { 0.17, 0.16, -0.02 }, { 0.68, 1.2, -0.06 }, 0.13, SKIN, { shape = "Ellipsoid", stretch = 1.08 })
		end)
	end,
}
