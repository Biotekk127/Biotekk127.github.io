--[[
	Brr Brr Patapim (Uncommon)
	Canonical look: a forest creature that is half proboscis monkey, half tree. A bark-brown
	wooden head and trunk body wrapped in a robe of leaves and moss, a tan monkey face with
	tiny beady eyes and a HUGE drooping pink-orange nose, grey fur on the cheeks, long thin
	branch arms with twig fingers and leaves on the elbows, skinny twig legs rooted into
	ENORMOUS bare human feet, and a small hat on his leafy head
	("il mio cappello e' pieno di Slim").

	Coordinates: feet on y = 0, faces -Z. Parts are written in world coordinates; every
	animated joint is a group placed at the joint with an un-animated "space" group inside
	that shifts back to world space (see `joint`).
]]

-- Palette ------------------------------------------------------------------------------
local BARK = "#6b4a2f" -- dominant: wood
local BARK_DARK = "#4a3221" -- knots, roots
local BARK_LIGHT = "#8c6544" -- knot rims
local HOLE = "#2b1d14"
local MOSS = "#5f8f2c"
local MOSS_LIGHT = "#86b53a"
local LEAF = "#4c9a33" -- secondary: foliage
local LEAF_LIGHT = "#7cc24a"
local LEAF_DARK = "#2f6e25"
local SKIN = "#e7b08b" -- face + feet
local SKIN_DARK = "#cf8f6a"
local NAIL = "#f8e3d2"
local NOSE = "#e98767" -- accent: the famous nose
local NOSE_LIGHT = "#f6b096"
local NOSTRIL = "#7a3328"
local FUR = "#a39a90" -- grey hair
local EYE_WHITE = "#fff6e6"
local PUPIL = "#1e1612"
local SHINE = "#fff8ec"
local HAT = "#3b2d27"
local HAT_BAND = "#d9a23d"
local SLIME = "#9fe04a"
local SHROOM_CAP = "#c4552f"
local SHROOM_STEM = "#f3e6cc"

-- Helpers ------------------------------------------------------------------------------
local function deg(r)
	return r * 180 / math.pi
end

-- Rotation that points a part's local X axis along (vx, vy, vz); local Z stays horizontal.
local function axisRot(vx, vy, vz)
	local l = math.sqrt(vx * vx + vy * vy + vz * vz)
	vx, vy, vz = vx / l, vy / l, vz / l
	return { 0, deg(math.atan2(-vz, vx)), deg(math.asin(math.clamp(vy, -1, 1))) }
end

local function mid(a, b)
	return { (a[1] + b[1]) / 2, (a[2] + b[2]) / 2, (a[3] + b[3]) / 2 }
end

local function dist(a, b)
	local x, y, z = b[1] - a[1], b[2] - a[2], b[3] - a[3]
	return math.sqrt(x * x + y * y + z * z)
end

-- Cylinder branch from a to b (ends overlap a little so joints stay closed)
local function twig(k, name, a, b, d, color)
	k:Part({
		Name = name,
		Shape = "Cylinder",
		Size = { dist(a, b) + d * 0.5, d, d },
		Pos = mid(a, b),
		Rot = axisRot(b[1] - a[1], b[2] - a[2], b[3] - a[3]),
		Color = color or BARK,
		Material = "Wood",
	})
end

-- Ellipsoid stretched from a to b. w = local Y size, t = local Z size (Z stays horizontal).
local function blob(k, name, a, b, w, t, color, material, anim)
	k:Part({
		Name = name,
		Shape = "Ellipsoid",
		Size = { dist(a, b), w, t },
		Pos = mid(a, b),
		Rot = axisRot(b[1] - a[1], b[2] - a[2], b[3] - a[3]),
		Color = color,
		Material = material or "SmoothPlastic",
		Anim = anim,
	})
end

-- Leaf blade from stem a to tip b. `flat` turns the blade's face toward the horizontal axis.
local function leaf(k, name, a, b, w, color, anim, flat)
	if flat then
		blob(k, name, a, b, 0.07, w, color or LEAF, "SmoothPlastic", anim)
	else
		blob(k, name, a, b, w, 0.07, color or LEAF, "SmoothPlastic", anim)
	end
end

-- Animated joint at world point p; children keep using world coordinates.
local function joint(k, name, p, anim, fn, rot)
	k:Group({ Name = name, Pos = p, Rot = rot, Anim = anim }, function()
		k:Group({ Name = name .. "Space", Pos = { -p[1], -p[2], -p[3] } }, fn)
	end)
end

local function mushroom(k, name, base, h, cap, lean)
	local top = { base[1] + (lean or 0), base[2] + h, base[3] }
	twig(k, name .. "Stem", base, top, cap * 0.32, SHROOM_STEM)
	k:Part({
		Name = name .. "Cap",
		Shape = "Ellipsoid",
		Size = { cap, cap * 0.5, cap },
		Pos = { top[1], top[2] + cap * 0.08, top[3] },
		Color = SHROOM_CAP,
	})
end

--------------------------------------------------------------------------------------------
-- Giant bare human foot. s = 1 for the right foot (+X), -1 for the left.
--------------------------------------------------------------------------------------------
local TOES = { -- x offset (toward outside), y, z, size x, y, z
	{ -0.4, 0.23, -1.78, 0.44, 0.42, 0.58 }, -- big toe (inner side)
	{ -0.04, 0.2, -1.75, 0.3, 0.34, 0.48 },
	{ 0.21, 0.18, -1.69, 0.27, 0.3, 0.44 },
	{ 0.43, 0.16, -1.6, 0.25, 0.27, 0.4 },
	{ 0.62, 0.14, -1.47, 0.22, 0.24, 0.34 },
}

local function buildFoot(k, s)
	local fx = 0.85 * s
	local function X(o)
		return fx + o * s
	end
	k:Part({ Name = "FootSole", Shape = "Ellipsoid", Size = { 1.38, 0.62, 2.7 }, Pos = { fx, 0.31, -0.55 }, Color = SKIN })
	local instep = { X(-0.02), 0.55, -0.1, 0.525, 0.525, 0.8 }
	k:Part({ Name = "FootInstep", Shape = "Ellipsoid", Size = { 1.05, 1.05, 1.6 }, Pos = { instep[1], instep[2], instep[3] }, Color = SKIN })
	k:Part({ Name = "Heel", Shape = "Ellipsoid", Size = { 1.0, 0.78, 0.9 }, Pos = { fx, 0.39, 0.48 }, Color = SKIN })
	for i, t in ipairs(TOES) do
		k:Part({ Name = "Toe" .. i, Shape = "Ellipsoid", Size = { t[4], t[5], t[6] }, Pos = { X(t[1]), t[2], t[3] }, Color = SKIN })
		if i <= 3 then
			k:Part({
				Name = "Toenail" .. i,
				Shape = "Ellipsoid",
				Size = { t[4] * 0.62, 0.07, t[6] * 0.42 },
				Pos = { X(t[1]), t[2] + t[5] * 0.43, t[3] - t[6] * 0.22 },
				Rot = { -15, 0, 0 },
				Color = NAIL,
			})
		end
	end
	-- the twig leg roots itself into the top of the foot
	-- height of the instep's top surface at (x, z)
	local function instepTop(x, z)
		local u, w = (x - instep[1]) / instep[4], (z - instep[3]) / instep[6]
		return instep[2] + instep[5] * math.sqrt(math.max(0, 1 - u * u - w * w))
	end
	k:Part({ Name = "AnkleRoots", Shape = "Ellipsoid", Size = { 0.64, 0.4, 0.64 }, Pos = { X(0), 1.07, 0.08 }, Color = BARK_DARK, Material = "Wood" })
	for _, r in ipairs({ { 0.36, -0.12 }, { -0.28, -0.3 } }) do
		local ex, ez = X(r[1]), r[2]
		twig(k, "Root", { X(r[1] * 0.25), 1.1, 0.08 + (ez - 0.08) * 0.25 }, { ex, instepTop(ex, ez) + 0.03, ez }, 0.13, BARK_DARK)
	end
end

local function buildLeg(k, s)
	local ankle = { 0.85 * s, 0.72, 0.12 }
	local knee = { 0.95 * s, 1.85, -0.1 }
	local hip = { 0.48 * s, 3.0, 0.02 }
	twig(k, "Shin", ankle, knee, 0.3, BARK)
	k:Part({ Name = "KneeKnot", Shape = "Ellipsoid", Size = { 0.44, 0.46, 0.44 }, Pos = knee, Color = BARK_DARK, Material = "Wood" })
	twig(k, "Thigh", knee, hip, 0.34, BARK)
end

--------------------------------------------------------------------------------------------
-- Branch arm (right side, mirrored for the left)
--------------------------------------------------------------------------------------------
local SH = { 1.0, 4.85, 0.0 }
local EL = { 1.72, 3.9, -0.15 }
local WR = { 2.12, 2.9, -0.4 }

local function buildArm(k)
	joint(k, "Arm", SH, { Type = "Wiggle", Axis = "Z", Amount = 8, Speed = 0.45 }, function()
		k:Part({ Name = "ShoulderKnot", Shape = "Ball", Size = { 0.5, 0.5, 0.5 }, Pos = SH, Color = BARK_DARK, Material = "Wood" })
		twig(k, "UpperArm", SH, EL, 0.26, BARK)
		joint(k, "Forearm", EL, { Type = "Wiggle", Axis = "X", Amount = 9, Speed = 0.6, Phase = 0.3 }, function()
			k:Part({ Name = "ElbowKnot", Shape = "Ellipsoid", Size = { 0.38, 0.4, 0.38 }, Pos = EL, Color = BARK_DARK, Material = "Wood" })
			leaf(k, "ElbowLeaf", { 1.8, 3.95, -0.15 }, { 2.3, 4.25, -0.05 }, 0.3, LEAF, { Type = "Wiggle", Axis = "X", Amount = 25, Speed = 0.9 })
			leaf(k, "ElbowLeaf", { 1.78, 3.88, -0.05 }, { 2.15, 3.8, 0.35 }, 0.26, LEAF_LIGHT, { Type = "Wiggle", Axis = "X", Amount = 25, Speed = 0.8, Phase = 0.5 })
			twig(k, "LowerArm", EL, WR, 0.22, BARK)
			joint(k, "Hand", WR, { Type = "Wiggle", Axis = "Z", Amount = 10, Speed = 0.9, Phase = 0.6 }, function()
				twig(k, "Finger", WR, { 1.98, 2.36, -0.62 }, 0.1, BARK)
				twig(k, "Finger", WR, { 2.2, 2.3, -0.55 }, 0.1, BARK)
				twig(k, "Finger", WR, { 2.42, 2.42, -0.45 }, 0.09, BARK)
				twig(k, "Thumb", WR, { 1.95, 2.66, -0.8 }, 0.09, BARK)
			end)
		end)
	end)
end

--------------------------------------------------------------------------------------------
-- Head: tree-bark skull, tan monkey face, beady eyes, giant nose, leafy crown and hat
--------------------------------------------------------------------------------------------
local function buildNose(k)
	joint(k, "Nose", { 0, 6.78, -0.95 }, { Type = "Wiggle", Axis = "X", Amount = 5, Speed = 0.8 }, function()
		blob(k, "NoseBridge", { 0, 6.92, -0.92 }, { 0, 5.95, -1.25 }, 0.46, 0.46, NOSE)
		blob(k, "NoseMid", { 0, 6.45, -1.06 }, { 0, 5.5, -1.38 }, 0.7, 0.7, NOSE)
		joint(k, "NoseTip", { 0, 6.0, -1.25 }, { Type = "Wiggle", Axis = "Z", Amount = 6, Speed = 1.1, Phase = 0.3 }, function()
			k:Part({ Name = "NoseBulb", Shape = "Ellipsoid", Size = { 1.0, 1.1, 0.92 }, Pos = { 0, 5.38, -1.45 }, Color = NOSE })
			k:Part({ Name = "NoseShine", Shape = "Ellipsoid", Size = { 0.16, 0.26, 0.08 }, Pos = { 0.2, 5.7, -1.77 }, Rot = { 25, -18, 0 }, Color = NOSE_LIGHT })
			k:Mirror(function()
				k:Part({ Name = "Nostril", Shape = "Ellipsoid", Size = { 0.18, 0.08, 0.16 }, Pos = { 0.17, 4.9, -1.55 }, Color = NOSTRIL })
			end)
		end)
	end)
end

local function buildHat(k)
	local P = { 0.12, 7.98, 0.12 }
	joint(k, "Hat", P, { Type = "Wiggle", Axis = "Z", Amount = 5, Speed = 0.7, Phase = 0.2 }, function()
		k:Part({ Name = "HatBrim", Shape = "Cylinder", Size = { 0.09, 1.45, 1.45 }, Pos = { P[1], 8.02, P[3] }, Rot = { 0, 0, 90 }, Color = HAT, Material = "Fabric" })
		k:Part({ Name = "HatCrown", Shape = "Cylinder", Size = { 0.6, 0.9, 0.9 }, Pos = { P[1], 8.34, P[3] }, Rot = { 0, 0, 90 }, Color = HAT, Material = "Fabric" })
		k:Part({ Name = "HatBand", Shape = "Cylinder", Size = { 0.15, 0.94, 0.94 }, Pos = { P[1], 8.13, P[3] }, Rot = { 0, 0, 90 }, Color = HAT_BAND, Material = "Fabric" })
		k:Part({ Name = "Slim", Shape = "Ellipsoid", Size = { 1.0, 0.34, 1.0 }, Pos = { P[1], 8.66, P[3] }, Color = SLIME, Material = "Glass" })
		leaf(k, "HatLeaf", { 0.5, 8.15, 0.25 }, { 0.78, 8.62, 0.4 }, 0.22, LEAF_LIGHT)
	end, { -5, 0, -9 })
end

local function buildHead(k)
	joint(k, "Head", { 0, 5.45, 0.05 }, { Type = "Wiggle", Axis = "Z", Amount = 3, Speed = 0.45, Phase = 0.15 }, function()
		k:Part({ Name = "Neck", Shape = "Cylinder", Size = { 0.8, 0.95, 0.95 }, Pos = { 0, 5.45, 0.1 }, Rot = { 0, 0, 90 }, Color = BARK_DARK, Material = "Wood" })
		k:Part({ Name = "Skull", Shape = "Ellipsoid", Size = { 2.1, 2.05, 1.95 }, Pos = { 0, 6.65, 0.1 }, Color = BARK, Material = "Wood" })
		k:Part({ Name = "Face", Shape = "Ellipsoid", Size = { 1.6, 1.55, 0.8 }, Pos = { 0, 6.5, -0.6 }, Color = SKIN })
		k:Part({ Name = "Muzzle", Shape = "Ellipsoid", Size = { 1.25, 0.75, 0.75 }, Pos = { 0, 5.95, -0.72 }, Color = SKIN })
		k:Mirror(function()
			k:Part({ Name = "MossBeard", Shape = "Ellipsoid", Size = { 0.42, 0.38, 0.4 }, Pos = { 0.33, 5.56, -0.76 }, Color = MOSS_LIGHT, Material = "Grass" })
			k:Part({ Name = "Cheek", Shape = "Ellipsoid", Size = { 0.55, 0.6, 0.45 }, Pos = { 0.6, 6.12, -0.7 }, Color = SKIN })
			k:Part({ Name = "Ear", Shape = "Ellipsoid", Size = { 0.22, 0.46, 0.4 }, Pos = { 1.06, 6.62, 0.12 }, Color = SKIN_DARK })
			k:Part({ Name = "FurRuff", Shape = "Ellipsoid", Size = { 0.28, 0.9, 0.5 }, Pos = { 0.9, 6.08, -0.26 }, Rot = { 0, 35, 30 }, Color = FUR })
			k:Part({ Name = "Brow", Shape = "Ellipsoid", Size = { 0.62, 0.2, 0.32 }, Pos = { 0.42, 7.2, -0.76 }, Rot = { 0, -18, -12 }, Color = BARK_DARK, Material = "Wood" })
			-- tiny beady eyes
			k:Part({ Name = "EyeSocket", Shape = "Ellipsoid", Size = { 0.46, 0.4, 0.1 }, Pos = { 0.4, 6.92, -0.86 }, Rot = { 0, -20, 0 }, Color = SKIN_DARK })
			k:Part({ Name = "EyeWhite", Shape = "Ellipsoid", Size = { 0.3, 0.28, 0.14 }, Pos = { 0.4, 6.92, -0.9 }, Rot = { 0, -20, 0 }, Color = EYE_WHITE, Anim = { Type = "Blink", Speed = 0.3 } })
			k:Part({ Name = "Pupil", Shape = "Ellipsoid", Size = { 0.18, 0.2, 0.08 }, Pos = { 0.39, 6.91, -0.96 }, Rot = { 0, -20, 0 }, Color = PUPIL, Anim = { Type = "Blink", Speed = 0.3 } })
			k:Part({ Name = "EyeShine", Shape = "Ball", Size = { 0.07, 0.07, 0.07 }, Pos = { 0.42, 6.96, -1.0 }, Color = SHINE, Anim = { Type = "Blink", Speed = 0.3 } })
		end)
		k:Part({ Name = "HeadMoss", Shape = "Ellipsoid", Size = { 1.1, 0.8, 0.3 }, Pos = { -0.15, 6.85, 1.0 }, Rot = { -15, 0, 8 }, Color = MOSS, Material = "Grass" })
		buildNose(k)

		-- leafy crown
		k:Part({ Name = "CrownLeaves", Shape = "Ellipsoid", Size = { 1.7, 0.75, 1.6 }, Pos = { 0, 7.55, 0.15 }, Color = LEAF_DARK, Material = "Grass" })
		for i = 0, 5 do
			local a = i * 60 + 30
			local ra = math.rad(a)
			k:Part({
				Name = "LeafClump",
				Shape = "Ellipsoid",
				Size = { 0.8, 0.6, 0.7 },
				Pos = { 0.72 * math.sin(ra), 7.45 + 0.08 * (i % 2), 0.15 - 0.66 * math.cos(ra) },
				Rot = { 0, -a, 8 * ((i % 2) * 2 - 1) },
				Color = if i % 2 == 0 then LEAF else LEAF_LIGHT,
			})
		end
		leaf(k, "CrownLeaf", { 0.6, 7.7, 0.0 }, { 1.15, 8.1, -0.15 }, 0.3, LEAF_LIGHT, { Type = "Wiggle", Axis = "X", Amount = 20, Speed = 0.7 })
		leaf(k, "CrownLeaf", { -0.6, 7.75, 0.2 }, { -1.15, 8.05, 0.4 }, 0.3, LEAF, { Type = "Wiggle", Axis = "X", Amount = 20, Speed = 0.6, Phase = 0.4 })
		leaf(k, "CrownLeaf", { 0.0, 7.8, 0.65 }, { 0.1, 8.25, 1.15 }, 0.3, LEAF_LIGHT, { Type = "Wiggle", Axis = "X", Amount = 20, Speed = 0.8, Phase = 0.7 }, true)

		buildHat(k)
	end)
end

--------------------------------------------------------------------------------------------
-- Trunk body under an open robe of leaves (sways gently from the hips like a tree)
--------------------------------------------------------------------------------------------
-- right half of the leafy robe {cx, cy, cz, semiX, semiY, semiZ}; mirrored for the left
local ROBE = { 0.55, 4.3, 0.06, 0.65, 1.15, 0.95 }

-- point on the robe surface at azimuth a (0 = front, 90 = outside) and height y, pushed out
local function robePoint(a, y, out)
	local e = ROBE
	local f = math.sqrt(math.max(0, 1 - ((y - e[2]) / e[5]) ^ 2))
	local ra = math.rad(a)
	return {
		e[1] + (e[4] * f + out) * math.sin(ra),
		y,
		e[3] - (e[6] * f + out) * math.cos(ra),
	}
end

local ROBE_LEAVES = { -- azimuth, height, size (width, length, thickness), colour, tilt in the robe plane
	{ 28, 4.7, { 0.5, 0.95, 0.22 }, LEAF, 18 },
	{ 62, 3.8, { 0.5, 0.9, 0.22 }, LEAF_LIGHT, -14 },
	{ 112, 4.55, { 0.52, 0.95, 0.22 }, LEAF, 22 },
	{ 160, 3.8, { 0.5, 0.92, 0.22 }, LEAF_LIGHT, -18 },
}

local function buildTrunk(k)
	joint(k, "Trunk", { 0, 2.95, 0 }, { Type = "Wiggle", Axis = "Z", Amount = 2.5, Speed = 0.35 }, function()
		k:Part({ Name = "RootFlare", Shape = "Ellipsoid", Size = { 1.75, 0.95, 1.5 }, Pos = { 0, 3.1, 0.02 }, Color = BARK_DARK, Material = "Wood" })
		k:Part({ Name = "TrunkCore", Shape = "Cylinder", Size = { 2.15, 1.6, 1.6 }, Pos = { 0, 4.02, 0 }, Rot = { 0, 0, 90 }, Color = BARK, Material = "Wood" })
		-- knot hole belly button on the bark showing between the robe halves
		k:Part({ Name = "KnotRim", Shape = "Ellipsoid", Size = { 0.46, 0.6, 0.2 }, Pos = { 0, 3.95, -0.78 }, Color = BARK_LIGHT, Material = "Wood" })
		k:Part({ Name = "KnotHole", Shape = "Ellipsoid", Size = { 0.24, 0.36, 0.08 }, Pos = { 0, 3.95, -0.86 }, Color = HOLE })

		k:Mirror(function()
			k:Part({ Name = "LeafRobe", Shape = "Ellipsoid", Size = { ROBE[4] * 2, ROBE[5] * 2, ROBE[6] * 2 }, Pos = { ROBE[1], ROBE[2], ROBE[3] }, Color = LEAF_DARK, Material = "Grass" })
			for _, c in ipairs(ROBE_LEAVES) do
				k:Part({ Name = "RobeLeaf", Shape = "Ellipsoid", Size = c[3], Pos = robePoint(c[1], c[2], 0.0), Rot = { 0, -c[1], c[5] }, Color = c[4] })
			end
			-- pointed leaves hanging from the robe's hem
			for i, a in ipairs({ 20, 70, 125 }) do
				local top = robePoint(a, 3.4, -0.08)
				local ra = math.rad(a)
				local tip = { top[1] + 0.22 * math.sin(ra), 2.88 - 0.06 * i, top[3] - 0.22 * math.cos(ra) }
				leaf(k, "HemLeaf", top, tip, 0.36, if i % 2 == 0 then LEAF_LIGHT else LEAF, nil, true)
			end
		end)

		-- leafy collar around the neck (open at the front for the beard and nose)
		for i = 0, 5 do
			local a = 55 + i * 50
			local ra = math.rad(a)
			k:Part({
				Name = "CollarLeaves",
				Shape = "Ellipsoid",
				Size = { 0.7, 0.5, 0.55 },
				Pos = { 0.7 * math.sin(ra), 5.32 + 0.05 * (i % 2), -0.62 * math.cos(ra) },
				Rot = { 0, -a, 10 * ((i % 2) * 2 - 1) },
				Color = ({ LEAF, LEAF_LIGHT, MOSS })[i % 3 + 1],
			})
		end

		-- mushrooms sprouting from the shoulders
		mushroom(k, "Mushroom", { 1.0, 5.05, 0.25 }, 0.4, 0.5, 0.05)
		mushroom(k, "Mushroom", { -0.95, 5.05, 0.3 }, 0.3, 0.36, -0.04)

		-- little branch growing out of the back
		twig(k, "BackBranch", { 0.2, 4.3, 0.75 }, { 0.6, 4.95, 1.3 }, 0.18, BARK)
		leaf(k, "BackLeaf", { 0.6, 4.95, 1.3 }, { 0.85, 5.35, 1.5 }, 0.3, LEAF_LIGHT, { Type = "Wiggle", Axis = "X", Amount = 20, Speed = 0.7, Phase = 0.2 })

		k:Mirror(function()
			buildArm(k)
		end)
		buildHead(k)
	end)
end

return {
	Id = "BrrBrrPatapim",
	Name = "Brr Brr Patapim",
	Rarity = "Uncommon",
	Emoji = "🌳",
	Color = "#5f8f2c",
	Tagline = "Brr brr! His hat is full of Slim.",
	Lore = "Half proboscis monkey, half forest tree, all feet. Patapim stomps through the woods on his giant bare feet, wiggling his enormous nose at anyone who wanders by. Nobody knows what Slim is, but it is definitely in his hat.",

	Build = function(k)
		-- left foot plants, right foot taps along to the "brr brr"
		buildFoot(k, -1)
		joint(k, "TappingFoot", { 0.85, 0.02, 0.93 }, { Type = "Wiggle", Axis = "X", Amount = 3.5, Speed = 0.9 }, function()
			buildFoot(k, 1)
		end, { 3.5, 0, 0 })
		buildLeg(k, -1)
		buildLeg(k, 1)

		buildTrunk(k)

		-- a few leaves drift up off his crown
		k:Particles({ Pos = { 0, 7.9, 0.2 }, Color = LEAF_LIGHT, Color2 = MOSS, Rate = 3, Size = 0.22, Speed = 0.8, Lifetime = 1.8, Spread = 50, Direction = "Top" })
	end,

	BuildMini = function(k)
		k:Mirror(function()
			k:Part({ Name = "Foot", Shape = "Ellipsoid", Size = { 0.62, 0.38, 1.1 }, Pos = { 0.36, -1.11, -0.17 }, Color = SKIN })
			k:Part({ Name = "Arm", Shape = "Cylinder", Size = { 0.8, 0.13, 0.13 }, Pos = { 0.7, -0.5, -0.08 }, Rot = axisRot(0.53, -0.55, -0.15), Color = BARK, Material = "Wood" })
			k:Part({ Name = "Eye", Shape = "Ball", Size = { 0.15, 0.15, 0.15 }, Pos = { 0.19, 0.5, -0.5 }, Color = PUPIL })
		end)
		k:Part({ Name = "Body", Shape = "Ellipsoid", Size = { 0.95, 1.05, 0.85 }, Pos = { 0, -0.55, 0.05 }, Color = LEAF, Material = "Grass" })
		k:Part({ Name = "Head", Shape = "Ellipsoid", Size = { 1.15, 1.05, 1.0 }, Pos = { 0, 0.38, 0.06 }, Color = BARK, Material = "Wood" })
		k:Part({ Name = "Face", Shape = "Ellipsoid", Size = { 0.86, 0.82, 0.42 }, Pos = { 0, 0.33, -0.3 }, Color = SKIN })
		k:Part({ Name = "Nose", Shape = "Ellipsoid", Size = { 0.5, 0.95, 0.46 }, Pos = { 0, -0.08, -0.62 }, Rot = { -12, 0, 0 }, Color = NOSE })
		k:Part({ Name = "Leaves", Shape = "Ellipsoid", Size = { 1.15, 0.5, 1.05 }, Pos = { 0, 0.88, 0.1 }, Color = LEAF_LIGHT, Material = "Grass" })
		k:Part({ Name = "Hat", Shape = "Cylinder", Size = { 0.3, 0.62, 0.62 }, Pos = { 0.05, 1.18, 0.1 }, Rot = { 0, 0, 90 }, Color = HAT })
	end,
}
