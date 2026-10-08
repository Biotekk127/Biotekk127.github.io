--[[
	Ballerina Cappuccina (Legendary)
	The prima ballerina of the brainrot opera: a slender dancer whose head is a glossy
	warm-white ceramic cappuccino cup (handle on her left side, gold rim, brown crema with a
	white latte-art heart, steam curling up). A cute face is painted on the cup: big coffee-
	brown eyes with long lashes, rosy cheeks and a sweet smile. She wears a sparkly pink
	bodice, a huge layered pink tutu, pink tights and satin pointe shoes with crossed ribbons.

	Pose: en pointe on her right leg (toe on y = 0, on the spin axis) with the left leg in
	passe (knee out to the side, toe at the standing knee) and both arms en couronne
	(a graceful oval above the cup). Animation: the whole dancer slowly PIROUETTES, the tutu
	tiers flutter, the arms sway (port de bras), the cup tilts, steam rises, eyes blink.
	Legendary flair: orbiting sparkles, gold accents, a soft pink light and glitter.

	Faces -Z. Feet on y = 0. Built only through the CharacterKit builder `k`.
]]

-- Palette ------------------------------------------------------------------------------
local CUP = "#fff6ee" -- warm white glazed ceramic
local CUP_SHADE = "#efe1d6" -- foot ring, inner shading
local GOLD = "#f2c25a" -- rim bands, sequins
local CREMA = "#c48a5a" -- crema surface
local FOAM = "#fff3e4" -- milk foam / latte art
local STEAM = "#fffaf4"

local SKIN = "#f8cdb5" -- arms, shoulders, neck
local SKIN_D = "#e9b9a2" -- knuckles / shading
local TIGHTS = "#f6b4c6" -- ballet tights (pink)
local SHOE = "#ea6aa1" -- satin pointe shoes
local RIBBON = "#d9558f" -- shoe ribbons
local SOLE = "#c98f72" -- leather sole strip

local BODICE = "#ea5b96" -- sparkly leotard bodice
local BODICE_D = "#cf4682" -- waistband, trims
local TUTU_1 = "#f585b6" -- under layer
local TUTU_2 = "#ff98c8"
local TUTU_3 = "#ffa9d2"
local TUTU_4 = "#ffbadb" -- top, lightest layer
local SPARK = "#ffe3f1" -- sequins (neon)
local GEM = "#ff4fa3"

local EYE_W = "#fff8ec"
local IRIS = "#6a3b25" -- coffee-brown eyes
local INK = "#2a1a24"
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

-- Points on the cup (head-local): theta in degrees from the front (-Z) towards +X.
local CUP_R = 0.95
local function onCup(theta, y, out)
	local a = math.rad(theta)
	local r = CUP_R + (out or 0)
	return { r * math.sin(a), y, -r * math.cos(a) }
end

-- One tier of tutu petals: n flattened ellipsoids around the hips, tilted down at the rim.
local function tutuTier(k, n, r, size, tilt, color, offset)
	for i = 0, n - 1 do
		local a = offset + i * 360 / n
		local ra = math.rad(a)
		local ruffle = if i % 2 == 0 then 3 else -2 -- wavy tulle edge
		k:Part({
			Name = "TutuPetal",
			Shape = "Ellipsoid",
			Size = size,
			Pos = { r * math.cos(ra), (if i % 2 == 0 then -0.02 else 0.02), -r * math.sin(ra) },
			Rot = { 0, a, -(tilt + ruffle) },
			Color = color,
			Material = "SmoothPlastic",
		})
	end
end

-- n sequins sitting on a tilted tutu tier at radius r (alternating gold foil / neon).
local function tutuSequins(k, n, r, rCenter, tilt, y0, offset)
	for i = 0, n - 1 do
		local a = math.rad(offset + i * 360 / n)
		local y = y0 - math.sin(math.rad(tilt)) * (r - rCenter)
		local gold = i % 2 == 0
		k:Part({
			Name = "Sequin",
			Shape = "Ball",
			Size = { 0.09, 0.09, 0.09 },
			Pos = { r * math.cos(a), y, -r * math.sin(a) },
			Color = if gold then GOLD else SPARK,
			Material = if gold then "Foil" else "Neon",
		})
	end
end

-- Front surface (most negative z) of a set of torso ellipsoids at (x, y).
local TORSO_SHAPES = {
	{ c = { 0, 4.22, 0 }, s = { 0.78, 0.9, 0.56 } },
	{ c = { 0, 4.75, 0 }, s = { 1.0, 1.15, 0.66 } },
}
local function torsoFront(x, y, back)
	local best = 0
	for _, e in TORSO_SHAPES do
		local u = (x - e.c[1]) / (e.s[1] / 2)
		local v = (y - e.c[2]) / (e.s[2] / 2)
		local q = 1 - u * u - v * v
		if q > 0 then
			local d = math.sqrt(q) * e.s[3] / 2
			if d > best then
				best = d
			end
		end
	end
	return if back then best else -best
end

-- Pointe shoe + crossed ribbons, built in ankle space (foot points along local -Y,
-- instep faces local -Z).
local function pointeShoe(k)
	k:Part({ Name = "Heel", Shape = "Ellipsoid", Size = { 0.24, 0.26, 0.22 }, Pos = { 0, -0.1, 0.09 }, Color = SHOE, Reflectance = 0.08 })
	k:Part({ Name = "ShoeBody", Shape = "Ellipsoid", Size = { 0.3, 0.68, 0.35 }, Pos = { 0, -0.36, -0.01 }, Color = SHOE, Reflectance = 0.08 })
	k:Part({ Name = "Instep", Shape = "Ellipsoid", Size = { 0.26, 0.44, 0.27 }, Pos = { 0, -0.27, -0.08 }, Color = SHOE, Reflectance = 0.08 })
	k:Part({ Name = "ToeBox", Shape = "Ellipsoid", Size = { 0.26, 0.3, 0.29 }, Pos = { 0, -0.59, -0.03 }, Color = SHOE, Reflectance = 0.08 })
	k:Part({ Name = "Platform", Shape = "Cylinder", Size = { 0.06, 0.15, 0.15 }, Pos = { 0, -0.72, -0.03 }, Rot = UP, Color = RIBBON })
	k:Part({ Name = "SoleStrip", Size = { 0.07, 0.42, 0.05 }, Pos = { 0, -0.38, 0.155 }, Color = SOLE, Material = "Leather" })
	k:Part({ Name = "Binding", Shape = "Cylinder", Size = { 0.05, 0.3, 0.3 }, Pos = { 0, -0.03, 0 }, Rot = UP, Color = RIBBON })
	-- ribbons wrapped around the ankle and crossed in front and behind
	k:Part({ Name = "RibbonWrap", Shape = "Cylinder", Size = { 0.05, 0.27, 0.27 }, Pos = { 0, 0.14, 0 }, Rot = UP, Color = RIBBON })
	k:Part({ Name = "RibbonWrap", Shape = "Cylinder", Size = { 0.05, 0.26, 0.26 }, Pos = { 0, 0.36, 0 }, Rot = UP, Color = RIBBON })
	for s = -1, 1, 2 do
		k:Part({ Name = "RibbonCross", Size = { 0.05, 0.3, 0.05 }, Pos = { 0, 0.25, -0.125 }, Rot = { 0, 0, 34 * s }, Color = RIBBON })
		k:Part({ Name = "RibbonCross", Size = { 0.05, 0.3, 0.05 }, Pos = { 0, 0.25, 0.125 }, Rot = { 0, 0, 34 * s }, Color = RIBBON })
	end
end

-- A leg in tights from hip to ankle, with a shaped thigh, knee, calf and shin.
local function leg(k, name, hip, knee, ankle, footRot)
	k:Group({ Name = name }, function()
		softLimb(k, "Thigh", hip, knee, 0.29, 0.42, 0.32, 0.34, TIGHTS)
		k:Part({ Name = "Knee", Shape = "Ball", Size = { 0.29, 0.29, 0.29 }, Pos = knee, Color = TIGHTS })
		softLimb(k, "Shin", knee, ankle, 0.2, 0.32, 0.3, 0.28, TIGHTS, 0.03)
		k:Part({ Name = "Ankle", Shape = "Ball", Size = { 0.21, 0.21, 0.21 }, Pos = ankle, Color = TIGHTS })
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
			leg(k, "StandingLeg", { 0.2, 3.62, 0.02 }, { 0.1, 2.2, -0.03 }, { 0.02, 0.75, 0.0 }, { 0, 0, 0 })
			-- left leg: passe, knee out to the side, pointed toe resting at the standing knee
			leg(k, "PasseLeg", { -0.2, 3.6, 0.0 }, { -1.58, 3.12, -0.3 }, { -0.45, 2.48, -0.33 }, { 0, 0, 60 })

			---------------------------------------------------------------- hips + waist
			k:Part({ Name = "Pelvis", Shape = "Ellipsoid", Size = { 0.92, 0.6, 0.64 }, Pos = { 0, 3.78, 0.02 }, Color = BODICE })
			k:Part({ Name = "Waistband", Shape = "Cylinder", Size = { 0.14, 0.9, 0.9 }, Pos = { 0, 3.96, 0.0 }, Rot = UP, Color = BODICE_D, Reflectance = 0.1 })
			k:Part({ Name = "WaistGem", Shape = "Ball", Size = { 0.12, 0.12, 0.12 }, Pos = { 0, 3.96, -0.45 }, Color = GEM, Material = "Neon" })

			-- satin bow at the back of the waist
			k:Group({ Name = "BackBow", Pos = { 0, 4.2, torsoFront(0, 4.2, true) + 0.04 } }, function()
				k:Part({ Name = "BowKnot", Shape = "Ball", Size = { 0.13, 0.13, 0.13 }, Color = BODICE_D, Reflectance = 0.1 })
				k:Mirror(function()
					k:Part({ Name = "BowLoop", Shape = "Ellipsoid", Size = { 0.3, 0.17, 0.08 }, Pos = { 0.15, 0.04, 0.0 }, Rot = { 0, 0, 18 }, Color = BODICE_D, Reflectance = 0.1 })
					k:Part({ Name = "BowTail", Shape = "Ellipsoid", Size = { 0.08, 0.34, 0.05 }, Pos = { 0.08, -0.2, 0.02 }, Rot = { 0, 0, 14 }, Color = BODICE_D, Reflectance = 0.1 })
				end)
			end)

			---------------------------------------------------------------- tutu (4 fluttering tiers)
			k:Group({ Name = "TutuUnder", Pos = { 0, 3.53, 0 }, Anim = { Type = "Wiggle", Axis = "Z", Amount = 2, Speed = 0.5, Phase = 0.6 } }, function()
				tutuTier(k, 16, 1.5, { 1.55, 0.22, 0.98 }, 21, TUTU_1, 0)
			end)
			k:Group({ Name = "TutuMid", Pos = { 0, 3.71, 0 }, Anim = { Type = "Wiggle", Axis = "X", Amount = 2.5, Speed = 0.5, Phase = 0 } }, function()
				tutuTier(k, 16, 1.5, { 1.55, 0.24, 0.98 }, 12, TUTU_2, 11.25)
				tutuSequins(k, 8, 1.95, 1.5, 12, 0.04, 11.25)
			end)
			k:Group({ Name = "TutuUpper", Pos = { 0, 3.88, 0 }, Anim = { Type = "Wiggle", Axis = "Z", Amount = 2.5, Speed = 0.5, Phase = 0.3 } }, function()
				tutuTier(k, 14, 1.2, { 1.4, 0.24, 0.92 }, 6, TUTU_3, 0)
				tutuSequins(k, 7, 1.62, 1.2, 6, 0.05, 25.7)
			end)
			k:Group({ Name = "TutuTop", Pos = { 0, 4.03, 0 }, Anim = { Type = "Bob", Axis = "Y", Amount = 0.025, Speed = 0.5, Phase = 0.15 } }, function()
				tutuTier(k, 10, 0.8, { 1.05, 0.22, 0.72 }, 3, TUTU_4, 18)
			end)

			---------------------------------------------------------------- torso
			for _, e in TORSO_SHAPES do
				k:Part({ Name = "Bodice", Shape = "Ellipsoid", Size = e.s, Pos = e.c, Color = BODICE, Reflectance = 0.05 })
			end
			k:Part({ Name = "Chest", Shape = "Ellipsoid", Size = { 0.88, 0.8, 0.54 }, Pos = { 0, 5.02, 0.01 }, Color = SKIN })
			k:Part({ Name = "Shoulders", Shape = "Ellipsoid", Size = { 1.08, 0.32, 0.46 }, Pos = { 0, 5.25, 0.02 }, Color = SKIN })
			k:Mirror(function()
				k:Part({ Name = "ShoulderCap", Shape = "Ball", Size = { 0.27, 0.27, 0.27 }, Pos = { 0.52, 5.23, 0.02 }, Color = SKIN })
				-- thin straps over the shoulders
				limb(k, "Strap", { 0.3, 5.1, -0.25 }, { 0.37, 5.36, -0.04 }, 0.06, BODICE_D)
				limb(k, "Strap", { 0.37, 5.36, 0.06 }, { 0.3, 5.1, 0.27 }, 0.06, BODICE_D)
			end)

			-- sparkly sequin V on the bodice front + pearl trim on the neckline
			for i = 0, 6 do
				local t = i / 6
				local x = 0.34 * (1 - t)
				local y = 4.95 - 0.68 * t
				for s = -1, 1, 2 do
					if not (i == 6 and s == 1) then
						k:Part({
							Name = "BodiceSequin",
							Shape = "Ball",
							Size = { 0.065, 0.065, 0.065 },
							Pos = { x * s, y, torsoFront(x * s, y) },
							Color = if i == 6 then GOLD else SPARK,
							Material = if i == 6 then "Foil" else "Neon",
						})
					end
				end
			end
			for i = -4, 4 do
				local x = i * 0.1
				local y = 5.04 - 0.05 * math.abs(i) / 4
				k:Part({ Name = "Pearl", Shape = "Ball", Size = { 0.07, 0.07, 0.07 }, Pos = { x, y, torsoFront(x, y) }, Color = EYE_W, Reflectance = 0.15 })
			end
			-- criss-cross lacing on the back of the bodice
			for j = 0, 2 do
				local y = 4.38 + j * 0.24
				for s = -1, 1, 2 do
					k:Part({ Name = "BackLace", Size = { 0.05, 0.3, 0.05 }, Pos = { 0, y, torsoFront(0, y, true) }, Rot = { 0, 0, 40 * s }, Color = BODICE_D })
				end
			end

			---------------------------------------------------------------- neck
			k:Part({ Name = "Neck", Shape = "Cylinder", Size = { 0.56, 0.32, 0.32 }, Pos = { 0, 5.58, 0.02 }, Rot = UP, Color = SKIN })
			k:Part({ Name = "Choker", Shape = "Cylinder", Size = { 0.07, 0.355, 0.355 }, Pos = { 0, 5.55, 0.02 }, Rot = UP, Color = BODICE_D, Reflectance = 0.1 })
			k:Part({ Name = "ChokerGem", Shape = "Ball", Size = { 0.1, 0.1, 0.1 }, Pos = { 0, 5.53, -0.17 }, Color = GEM, Material = "Neon" })

			---------------------------------------------------------------- arms en couronne
			k:Mirror(function()
				k:Group({ Name = "Arm", Pos = { 0.52, 5.23, 0.02 }, Anim = { Type = "Wiggle", Axis = "Z", Amount = 5, Speed = 0.4 } }, function()
					local E = { 0.9, 1.66, -0.42 }
					softLimb(k, "UpperArm", { 0.0, 0.0, 0.0 }, E, 0.19, 0.25, 0.36, 0.3, SKIN)
					k:Part({ Name = "Elbow", Shape = "Ball", Size = { 0.19, 0.19, 0.19 }, Pos = E, Color = SKIN })
					k:Group({ Name = "Forearm", Pos = E, Anim = { Type = "Wiggle", Axis = "Z", Amount = 6, Speed = 0.4, Phase = 0.12 } }, function()
						local W = { -0.7, 1.6, 0.12 }
						softLimb(k, "Forearm", { 0, 0, 0 }, W, 0.16, 0.21, 0.3, 0.26, SKIN)
						k:Part({ Name = "Wrist", Shape = "Ball", Size = { 0.15, 0.15, 0.15 }, Pos = W, Color = SKIN })
						limb(k, "WristRibbon", lerp({ 0, 0, 0 }, W, 0.84), lerp({ 0, 0, 0 }, W, 0.9), 0.185, RIBBON)
						k:Group({ Name = "Hand", Pos = W, Anim = { Type = "Wiggle", Axis = "Z", Amount = 8, Speed = 0.4, Phase = 0.25 } }, function()
							limb(k, "Palm", { 0.02, -0.01, 0 }, { -0.36, 0.1, 0.0 }, 0.13, SKIN, { shape = "Ellipsoid", dz = 0.2, stretch = 1.1 })
							limb(k, "Fingers", { -0.28, 0.08, 0 }, { -0.56, 0.2, 0.0 }, 0.09, SKIN, { shape = "Ellipsoid", dz = 0.18, stretch = 1.1 })
							limb(k, "Thumb", { -0.1, 0.0, -0.08 }, { -0.28, 0.06, -0.12 }, 0.07, SKIN_D, { shape = "Ellipsoid", stretch = 1.15 })
						end)
					end)
				end)
			end)

			---------------------------------------------------------------- the cappuccino cup head
			k:Group({ Name = "Head", Pos = { 0, 5.8, 0.02 }, Anim = { Type = "Wiggle", Axis = "Z", Amount = 3, Speed = 0.4, Phase = 0.4 } }, function()
				-- cup body
				k:Part({ Name = "CupBottom", Shape = "Ellipsoid", Size = { 1.86, 0.36, 1.86 }, Pos = { 0, 0.16, 0 }, Color = CUP, Reflectance = 0.1 })
				k:Part({ Name = "FootRing", Shape = "Cylinder", Size = { 0.06, 1.3, 1.3 }, Pos = { 0, 0.01, 0 }, Rot = UP, Color = CUP_SHADE })
				k:Part({ Name = "CupBody", Shape = "Cylinder", Size = { 1.46, CUP_R * 2, CUP_R * 2 }, Pos = { 0, 0.89, 0 }, Rot = UP, Color = CUP, Reflectance = 0.1 })
				k:Part({ Name = "GoldBand", Shape = "Cylinder", Size = { 0.05, 1.925, 1.925 }, Pos = { 0, 1.47, 0 }, Rot = UP, Color = GOLD, Material = "Foil" })
				k:Part({ Name = "GoldBand", Shape = "Cylinder", Size = { 0.05, 1.925, 1.925 }, Pos = { 0, 0.3, 0 }, Rot = UP, Color = GOLD, Material = "Foil" })
				-- lip band, then the cappuccino: white milk-foam rim, brown crema, latte-art heart
				k:Part({ Name = "Lip", Shape = "Cylinder", Size = { 0.09, 1.97, 1.97 }, Pos = { 0, 1.625, 0 }, Rot = UP, Color = CUP, Reflectance = 0.12 })
				k:Part({ Name = "FoamRim", Shape = "Ellipsoid", Size = { 1.84, 0.24, 1.84 }, Pos = { 0, 1.66, 0 }, Color = FOAM })
				k:Part({ Name = "Crema", Shape = "Ellipsoid", Size = { 1.42, 0.22, 1.42 }, Pos = { 0, 1.7, 0 }, Color = CREMA })
				k:Part({ Name = "CremaRing", Shape = "Ellipsoid", Size = { 1.18, 0.2, 1.18 }, Pos = { 0, 1.715, 0 }, Color = "#b0754a" })
				k:Mirror(function()
					k:Part({ Name = "HeartLobe", Shape = "Ellipsoid", Size = { 0.4, 0.06, 0.4 }, Pos = { 0.19, 1.81, 0.09 }, Color = FOAM })
				end)
				k:Part({ Name = "HeartPoint", Size = { 0.37, 0.06, 0.37 }, Pos = { 0, 1.81, -0.12 }, Rot = { 0, 45, 0 }, Color = FOAM })

				-- glossy highlight streak on the glaze
				k:Group({ Pos = onCup(62, 0.92, 0), Rot = { 0, -62, 0 } }, function()
					k:Part({ Name = "GlazeShine", Shape = "Ellipsoid", Size = { 0.08, 0.7, 0.05 }, Color = "#ffffff", Reflectance = 0.3, Transparency = 0.25 })
				end)

				-- handle on her left (-X) side: two bars + a semicircle of short cylinders
				local hc = { -1.2, 0.86, 0 }
				local hr = 0.34
				for s = -1, 1, 2 do
					limb(k, "HandleBar", { -0.88, hc[2] + hr * s, 0 }, { -1.22, hc[2] + hr * s, 0 }, 0.17, CUP, { reflectance = 0.1 })
				end
				for i = 0, 6 do
					local phi = -90 + i * 30
					local a = math.rad(phi)
					k:Part({
						Name = "Handle",
						Shape = "Cylinder",
						Size = { 0.2, 0.17, 0.17 },
						Pos = { hc[1] - math.cos(a) * hr, hc[2] + math.sin(a) * hr, 0 },
						Rot = { 0, 0, 90 - phi },
						Color = CUP,
						Reflectance = 0.1,
					})
				end

				-- little pink heart painted on the back of the cup
				k:Group({ Pos = onCup(180, 0.95, 0), Rot = { 0, 180, 0 } }, function()
					k:Mirror(function()
						k:Part({ Name = "BackHeartLobe", Shape = "Ellipsoid", Size = { 0.2, 0.2, 0.06 }, Pos = { 0.075, 0.04, 0 }, Color = TUTU_2 })
					end)
					k:Part({ Name = "BackHeartPoint", Size = { 0.19, 0.19, 0.05 }, Pos = { 0, -0.05, 0 }, Rot = { 0, 0, 45 }, Color = TUTU_2 })
				end)

				-- face ---------------------------------------------------------------
				k:Mirror(function()
					k:Group({ Name = "Eye", Pos = onCup(25, 0.98, 0), Rot = { 0, -25, 0 } }, function()
						local blink = { Type = "Blink", Speed = 0.22, Phase = 0.1 }
						k:Part({ Name = "EyeWhite", Shape = "Ellipsoid", Size = { 0.44, 0.56, 0.14 }, Color = EYE_W, Anim = blink })
						k:Part({ Name = "Iris", Shape = "Ellipsoid", Size = { 0.3, 0.4, 0.1 }, Pos = { -0.02, -0.03, -0.04 }, Color = IRIS, Anim = blink })
						k:Part({ Name = "Pupil", Shape = "Ellipsoid", Size = { 0.17, 0.23, 0.08 }, Pos = { -0.02, -0.03, -0.07 }, Color = INK, Anim = blink })
						k:Part({ Name = "Shine", Shape = "Ball", Size = { 0.1, 0.1, 0.1 }, Pos = { 0.04, 0.08, -0.1 }, Color = EYE_W, Anim = blink })
						k:Part({ Name = "Shine2", Shape = "Ball", Size = { 0.05, 0.05, 0.05 }, Pos = { -0.07, -0.1, -0.095 }, Color = EYE_W, Anim = blink })
						k:Part({ Name = "Lid", Shape = "Ellipsoid", Size = { 0.47, 0.12, 0.1 }, Pos = { 0, 0.235, -0.015 }, Color = INK })
						for j, phi in { 20, 45, 70 } do
							local a = math.rad(phi)
							k:Part({
								Name = "Lash",
								Size = { 0.05, 0.15 - j * 0.015, 0.05 },
								Pos = { 0.22 * math.cos(a) + 0.07 * math.cos(a), 0.28 * math.sin(a) + 0.07 * math.sin(a), -0.02 },
								Rot = { 0, 0, phi - 90 },
								Color = INK,
							})
						end
						for _, phi in { -22, -48 } do
							local a = math.rad(phi)
							k:Part({ Name = "LowerLash", Size = { 0.05, 0.09, 0.05 }, Pos = { 0.27 * math.cos(a), 0.32 * math.sin(a), -0.01 }, Rot = { 0, 0, phi - 90 }, Color = INK })
						end
						k:Part({ Name = "Brow", Shape = "Ellipsoid", Size = { 0.3, 0.06, 0.05 }, Pos = { 0.02, 0.45, -0.005 }, Rot = { 0, 0, -8 }, Color = "#6b4434" })
					end)
					k:Group({ Name = "Cheek", Pos = onCup(42, 0.62, 0), Rot = { 0, -42, 0 } }, function()
						k:Part({ Name = "Blush", Shape = "Ellipsoid", Size = { 0.27, 0.14, 0.05 }, Color = BLUSH })
					end)
				end)
				k:Group({ Name = "Mouth", Pos = onCup(0, 0.56, 0) }, function()
					k:Part({ Name = "MouthOpen", Shape = "Ellipsoid", Size = { 0.32, 0.18, 0.06 }, Pos = { 0, 0, -0.0 }, Color = MOUTH })
					k:Part({ Name = "Tongue", Shape = "Ellipsoid", Size = { 0.15, 0.06, 0.05 }, Pos = { 0, -0.045, -0.02 }, Color = TONGUE })
					k:Part({ Name = "UpperLipCover", Shape = "Ellipsoid", Size = { 0.38, 0.13, 0.07 }, Pos = { 0, 0.06, -0.002 }, Color = CUP })
				end)

				-- steam wisps curling up from the foam
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
								Transparency = 0.35 + j * 0.1,
								Anim = { Type = "Pulse", Amount = 0.12, Speed = 0.6, Phase = phase + j * 0.15 },
							})
						end
					end)
				end
				-- an S-curl: each puff leans the other way
				wisp("SteamMid", { 0, 1.9, 0.25 }, { { 0.05, 0.12, 0.17, 0.34, -28 }, { 0.07, 0.4, 0.16, 0.32, 28 }, { -0.02, 0.66, 0.14, 0.3, -28 }, { 0.0, 0.92, 0.11, 0.26, 24 } }, 0)
				k:Mirror(function()
					wisp("SteamSide", { 0.42, 1.84, 0.1 }, { { 0.04, 0.12, 0.15, 0.3, -28 }, { 0.06, 0.37, 0.13, 0.28, 28 }, { -0.01, 0.6, 0.1, 0.22, -24 } }, 0.35)
				end)
			end)
		end)

		---------------------------------------------------------------- legendary flair (static)
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
		k:Light({ Pos = { 0, 8.2, -0.6 }, Color = "#ffd9a0", Range = 8, Brightness = 0.8 })
		k:Particles({ Pos = { 0, 7.75, 0.1 }, Color = STEAM, Color2 = "#ffe6d6", Rate = 3, Size = 0.4, Speed = 0.7, Lifetime = 1.6, Spread = 18, Direction = "Top" })
		k:Particles({ Pos = { 0, 3.8, 0 }, Color = "#ff7fbf", Color2 = "#fff1a8", Rate = 5, Size = 0.18, Speed = 1.8, Lifetime = 1.1, Spread = 90, Direction = "Top" })
		k:Particles({ Pos = { 0, 0.12, 0 }, Color = GOLD, Color2 = "#ff9fd0", Rate = 4, Size = 0.16, Speed = 1.2, Lifetime = 1.0, Spread = 70, Direction = "Top" })
	end,

	BuildMini = function(k)
		-- one leg en pointe under a puffy tutu, slim neck, cup head with handle + cappuccino
		-- foam, and both arms raised in an open oval beside the cup
		k:Part({ Name = "Leg", Shape = "Ellipsoid", Size = { 0.15, 0.92, 0.15 }, Pos = { 0, -0.885, 0 }, Color = SHOE })
		k:Part({ Name = "Tutu", Shape = "Ellipsoid", Size = { 1.95, 0.34, 1.95 }, Pos = { 0, -0.42, 0 }, Color = TUTU_2 })
		k:Part({ Name = "Torso", Shape = "Ellipsoid", Size = { 0.34, 0.6, 0.26 }, Pos = { 0, -0.1, 0 }, Color = BODICE })
		k:Part({ Name = "Cup", Shape = "Cylinder", Size = { 0.64, 0.74, 0.74 }, Pos = { 0, 0.58, 0 }, Rot = UP, Color = CUP })
		k:Part({ Name = "Foam", Shape = "Ellipsoid", Size = { 0.68, 0.14, 0.68 }, Pos = { 0, 0.9, 0 }, Color = "#d9a877" })
		k:Part({ Name = "Handle", Shape = "Cylinder", Size = { 0.1, 0.38, 0.38 }, Pos = { -0.44, 0.6, 0 }, Rot = { 0, 90, 0 }, Color = CUP })
		k:Mirror(function()
			k:Part({ Name = "Eye", Shape = "Ball", Size = { 0.18, 0.18, 0.18 }, Pos = { 0.14, 0.62, -0.34 }, Color = INK })
			limb(k, "UpperArm", { 0.13, 0.04, -0.02 }, { 0.72, 0.5, -0.1 }, 0.12, SKIN, { shape = "Ellipsoid", stretch = 1.15 })
			limb(k, "Forearm", { 0.72, 0.5, -0.1 }, { 0.27, 1.27, -0.1 }, 0.11, SKIN, { shape = "Ellipsoid", stretch = 1.1 })
		end)
	end,
}
