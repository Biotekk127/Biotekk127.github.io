--[[
	Brr Brr Patapim (Uncommon)
	Canonical look: a forest creature that is half proboscis monkey, half tree. A bark-brown
	wooden head and trunk body covered in moss and leaves, a tan monkey face with tiny beady
	eyes and a HUGE drooping pink-orange nose, grey hair tufts, long thin branch arms with
	twig fingers and leaves on the elbows, skinny twig legs rooted into ENORMOUS bare human
	feet, and a small hat on his leafy head ("il mio cappello e' pieno di Slim").

	Coordinates: feet on y = 0, faces -Z. Parts are written in world coordinates; every
	animated joint is a group placed at the joint with an un-animated "space" group inside
	that shifts back to world space (see `joint`).
]]

-- Palette ------------------------------------------------------------------------------
local BARK = "#6b4a2f" -- dominant: wood
local BARK_DARK = "#4a3221" -- grooves, knots
local BARK_LIGHT = "#8c6544" -- ridges, knot rims
local HOLE = "#2b1d14"
local MOSS = "#5f8f2c"
local MOSS_LIGHT = "#86b53a"
local LEAF = "#4c9a33"
local LEAF_LIGHT = "#7cc24a"
local LEAF_DARK = "#2f6e25"
local SKIN = "#e7b08b" -- face + feet
local SKIN_DARK = "#cf8f6a"
local NAIL = "#f8e3d2"
local NOSE = "#e98767" -- accent: the famous nose
local NOSE_DARK = "#c5654c"
local NOSE_LIGHT = "#f6b096"
local NOSTRIL = "#7a3328"
local FUR = "#a39a90" -- grey hair
local EYE_WHITE = "#fff6e6"
local PUPIL = "#1e1612"
local SHINE = "#fff8ec"
local MOUTH = "#5a2620"
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

-- Leaf blade from stem a to tip b. `flat` lays the blade in the horizontal-ish plane.
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

-- Flattened patch lying on the trunk cylinder (radius r) at angle a (0 = front, + = right)
local TRUNK_R = 0.875
local function onTrunk(k, name, a, y, size, color, material, out)
	local r = TRUNK_R + (out or -0.02)
	local ra = math.rad(a)
	k:Part({
		Name = name,
		Shape = "Ellipsoid",
		Size = size,
		Pos = { r * math.sin(ra), y, -r * math.cos(ra) },
		Rot = { 0, -a, 0 },
		Color = color,
		Material = material or "Grass",
	})
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
	k:Part({ Name = "FootSole", Shape = "Ellipsoid", Size = { 1.25, 0.62, 2.5 }, Pos = { fx, 0.31, -0.5 }, Color = SKIN })
	k:Part({ Name = "FootInstep", Shape = "Ellipsoid", Size = { 1.0, 0.95, 1.55 }, Pos = { X(-0.02), 0.5, -0.1 }, Color = SKIN })
	k:Part({ Name = "Heel", Shape = "Ellipsoid", Size = { 1.0, 0.78, 0.9 }, Pos = { fx, 0.39, 0.48 }, Color = SKIN })
	k:Part({ Name = "FootBall", Shape = "Ellipsoid", Size = { 1.38, 0.56, 0.9 }, Pos = { fx, 0.29, -1.18 }, Color = SKIN })
	for i, t in ipairs(TOES) do
		k:Part({ Name = "Toe" .. i, Shape = "Ellipsoid", Size = { t[4], t[5], t[6] }, Pos = { X(t[1]), t[2], t[3] }, Color = SKIN })
		k:Part({
			Name = "Toenail" .. i,
			Shape = "Ellipsoid",
			Size = { t[4] * 0.62, 0.07, t[6] * 0.42 },
			Pos = { X(t[1]), t[2] + t[5] * 0.43, t[3] - t[6] * 0.22 },
			Rot = { -15, 0, 0 },
			Color = NAIL,
		})
	end
	-- the twig leg roots itself into the top of the foot
	twig(k, "Root", { X(0), 1.0, 0.1 }, { X(0.32), 0.76, -0.45 }, 0.12, BARK_DARK)
	twig(k, "Root", { X(0), 1.0, 0.1 }, { X(-0.3), 0.78, -0.4 }, 0.11, BARK_DARK)
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
				k:Part({ Name = "WristKnot", Shape = "Ball", Size = { 0.3, 0.3, 0.3 }, Pos = WR, Color = BARK_DARK, Material = "Wood" })
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
		blob(k, "NoseBridge", { 0, 6.9, -0.93 }, { 0, 6.05, -1.22 }, 0.42, 0.42, NOSE)
		blob(k, "NoseMid", { 0, 6.35, -1.1 }, { 0, 5.65, -1.34 }, 0.6, 0.6, NOSE)
		k:Part({ Name = "NoseWrinkle", Shape = "Ellipsoid", Size = { 0.46, 0.06, 0.14 }, Pos = { 0, 6.5, -1.23 }, Color = NOSE_DARK })
		k:Part({ Name = "NoseWrinkle", Shape = "Ellipsoid", Size = { 0.5, 0.06, 0.14 }, Pos = { 0, 6.3, -1.28 }, Color = NOSE_DARK })
		joint(k, "NoseTip", { 0, 6.0, -1.25 }, { Type = "Wiggle", Axis = "Z", Amount = 6, Speed = 1.1, Phase = 0.3 }, function()
			k:Part({ Name = "NoseBulb", Shape = "Ellipsoid", Size = { 0.86, 0.95, 0.8 }, Pos = { 0, 5.45, -1.4 }, Color = NOSE })
			k:Part({ Name = "NoseShine", Shape = "Ellipsoid", Size = { 0.2, 0.32, 0.1 }, Pos = { 0.16, 5.67, -1.72 }, Color = NOSE_LIGHT })
			k:Mirror(function()
				k:Part({ Name = "Nostril", Shape = "Ellipsoid", Size = { 0.15, 0.1, 0.12 }, Pos = { 0.15, 5.13, -1.67 }, Color = NOSTRIL })
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
		k:Part({ Name = "Slim", Shape = "Ellipsoid", Size = { 0.78, 0.36, 0.78 }, Pos = { P[1], 8.64, P[3] }, Color = SLIME, Material = "Glass" })
		for _, a in ipairs({ -35, 60 }) do
			local ra = math.rad(a)
			k:Part({
				Name = "SlimDrip",
				Shape = "Ellipsoid",
				Size = { 0.14, 0.42, 0.12 },
				Pos = { P[1] + 0.47 * math.sin(ra), 8.5, P[3] - 0.47 * math.cos(ra) },
				Rot = { 0, -a, 0 },
				Color = SLIME,
				Material = "Glass",
			})
		end
		leaf(k, "HatLeaf", { 0.5, 8.15, 0.25 }, { 0.78, 8.62, 0.4 }, 0.22, LEAF_LIGHT)
	end, { -5, 0, -9 })
end

local function buildHead(k)
	joint(k, "Head", { 0, 5.45, 0.05 }, { Type = "Wiggle", Axis = "Z", Amount = 3, Speed = 0.45, Phase = 0.15 }, function()
		k:Part({ Name = "Neck", Shape = "Cylinder", Size = { 0.8, 0.95, 0.95 }, Pos = { 0, 5.45, 0.1 }, Rot = { 0, 0, 90 }, Color = BARK_DARK, Material = "Wood" })
		k:Part({ Name = "Skull", Shape = "Ellipsoid", Size = { 2.1, 2.05, 1.95 }, Pos = { 0, 6.65, 0.1 }, Color = BARK, Material = "Wood" })
		k:Part({ Name = "Face", Shape = "Ellipsoid", Size = { 1.6, 1.55, 0.8 }, Pos = { 0, 6.5, -0.6 }, Color = SKIN })
		k:Part({ Name = "Muzzle", Shape = "Ellipsoid", Size = { 1.25, 0.75, 0.75 }, Pos = { 0, 5.95, -0.72 }, Color = SKIN })
		k:Part({ Name = "Mouth", Shape = "Ellipsoid", Size = { 0.95, 0.12, 0.2 }, Pos = { 0, 5.8, -1.03 }, Color = MOUTH })
		k:Part({ Name = "LowerLip", Shape = "Ellipsoid", Size = { 0.7, 0.14, 0.18 }, Pos = { 0, 5.7, -1.02 }, Color = SKIN_DARK })
		k:Part({ Name = "MossBeard", Shape = "Ellipsoid", Size = { 0.55, 0.45, 0.45 }, Pos = { 0, 5.5, -0.82 }, Color = MOSS, Material = "Grass" })
		k:Mirror(function()
			k:Part({ Name = "MossBeard", Shape = "Ellipsoid", Size = { 0.42, 0.38, 0.4 }, Pos = { 0.33, 5.56, -0.76 }, Color = MOSS_LIGHT, Material = "Grass" })
			k:Part({ Name = "Cheek", Shape = "Ellipsoid", Size = { 0.55, 0.6, 0.45 }, Pos = { 0.6, 6.12, -0.7 }, Color = SKIN })
			k:Part({ Name = "Ear", Shape = "Ellipsoid", Size = { 0.22, 0.46, 0.4 }, Pos = { 1.06, 6.62, 0.12 }, Color = SKIN_DARK })
			k:Part({ Name = "Sideburn", Shape = "Ellipsoid", Size = { 0.42, 0.78, 0.55 }, Pos = { 0.88, 6.18, -0.28 }, Rot = { 0, 0, 12 }, Color = FUR })
			k:Part({ Name = "Brow", Shape = "Ellipsoid", Size = { 0.62, 0.2, 0.32 }, Pos = { 0.42, 7.2, -0.76 }, Rot = { 0, -18, -12 }, Color = BARK_DARK, Material = "Wood" })
			-- tiny beady eyes
			k:Part({ Name = "EyeSocket", Shape = "Ellipsoid", Size = { 0.46, 0.4, 0.1 }, Pos = { 0.4, 6.92, -0.86 }, Rot = { 0, -20, 0 }, Color = SKIN_DARK })
			k:Part({ Name = "EyeWhite", Shape = "Ellipsoid", Size = { 0.3, 0.28, 0.14 }, Pos = { 0.4, 6.92, -0.9 }, Rot = { 0, -20, 0 }, Color = EYE_WHITE, Anim = { Type = "Blink", Speed = 0.3 } })
			k:Part({ Name = "Pupil", Shape = "Ellipsoid", Size = { 0.18, 0.2, 0.08 }, Pos = { 0.39, 6.91, -0.96 }, Rot = { 0, -20, 0 }, Color = PUPIL, Anim = { Type = "Blink", Speed = 0.3 } })
			k:Part({ Name = "EyeShine", Shape = "Ball", Size = { 0.07, 0.07, 0.07 }, Pos = { 0.42, 6.96, -1.0 }, Color = SHINE, Anim = { Type = "Blink", Speed = 0.3 } })
		end)
		buildNose(k)

		-- leafy crown
		k:Part({ Name = "CrownLeaves", Shape = "Ellipsoid", Size = { 1.7, 0.75, 1.6 }, Pos = { 0, 7.55, 0.15 }, Color = LEAF_DARK })
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
-- Trunk body (sways gently from the hips like a tree in the wind)
--------------------------------------------------------------------------------------------
local function buildTrunk(k)
	joint(k, "Trunk", { 0, 2.95, 0 }, { Type = "Wiggle", Axis = "Z", Amount = 2.5, Speed = 0.35 }, function()
		k:Part({ Name = "RootFlare", Shape = "Ellipsoid", Size = { 1.75, 0.95, 1.5 }, Pos = { 0, 3.1, 0.02 }, Color = BARK_DARK, Material = "Wood" })
		k:Part({ Name = "TrunkCore", Shape = "Cylinder", Size = { 1.9, 1.75, 1.75 }, Pos = { 0, 4.0, 0 }, Rot = { 0, 0, 90 }, Color = BARK, Material = "Wood" })
		k:Part({ Name = "Shoulders", Shape = "Ellipsoid", Size = { 2.3, 1.1, 1.75 }, Pos = { 0, 4.95, 0 }, Color = BARK, Material = "Wood" })

		-- vertical bark ridges all the way round
		for i = 0, 7 do
			local a = (i + 0.5) * 45
			local ra = math.rad(a)
			local len = 1.45 + 0.2 * ((i * 7) % 3)
			k:Part({
				Name = "BarkRidge",
				Shape = "Ellipsoid",
				Size = { 0.16, len, 0.16 },
				Pos = { 0.86 * math.sin(ra), 3.95 + 0.12 * ((i % 2) * 2 - 1), -0.86 * math.cos(ra) },
				Color = if i % 2 == 0 then BARK_DARK else BARK_LIGHT,
				Material = "Wood",
			})
		end

		-- knot hole belly button
		k:Part({ Name = "KnotRim", Shape = "Ellipsoid", Size = { 0.52, 0.66, 0.24 }, Pos = { 0, 3.75, -0.83 }, Color = BARK_LIGHT, Material = "Wood" })
		k:Part({ Name = "KnotHole", Shape = "Ellipsoid", Size = { 0.28, 0.4, 0.1 }, Pos = { 0, 3.75, -0.93 }, Color = HOLE })

		-- moss patches
		onTrunk(k, "Moss", -40, 4.35, { 0.75, 0.5, 0.22 }, MOSS)
		onTrunk(k, "Moss", 95, 3.55, { 0.7, 0.6, 0.22 }, MOSS_LIGHT)
		onTrunk(k, "Moss", 200, 3.6, { 0.85, 0.7, 0.22 }, MOSS)
		onTrunk(k, "Moss", 150, 4.5, { 0.6, 0.45, 0.2 }, MOSS_LIGHT)

		-- leafy collar around the neck (open at the front for the beard and nose)
		for i = 0, 6 do
			local a = 50 + i * (260 / 6)
			local ra = math.rad(a)
			k:Part({
				Name = "CollarLeaves",
				Shape = "Ellipsoid",
				Size = { 0.66, 0.5, 0.55 },
				Pos = { 0.68 * math.sin(ra), 5.32 + 0.05 * (i % 2), -0.62 * math.cos(ra) },
				Rot = { 0, -a, 10 * ((i % 2) * 2 - 1) },
				Color = ({ LEAF, LEAF_LIGHT, LEAF_DARK })[i % 3 + 1],
			})
		end

		-- mushrooms sprouting from the shoulders
		mushroom(k, "Mushroom", { 1.0, 5.12, 0.25 }, 0.35, 0.5, 0.05)
		mushroom(k, "Mushroom", { 0.78, 5.15, 0.5 }, 0.22, 0.32, -0.03)
		mushroom(k, "Mushroom", { -0.95, 5.12, 0.3 }, 0.25, 0.36, -0.04)
		k:Part({ Name = "CapSpot", Shape = "Ball", Size = { 0.09, 0.09, 0.09 }, Pos = { 1.12, 5.62, 0.18 }, Color = SHROOM_STEM })
		k:Part({ Name = "CapSpot", Shape = "Ball", Size = { 0.08, 0.08, 0.08 }, Pos = { 0.95, 5.63, 0.32 }, Color = SHROOM_STEM })

		-- little branch growing out of the back
		twig(k, "BackBranch", { 0.35, 4.3, 0.8 }, { 0.8, 4.95, 1.3 }, 0.18, BARK)
		leaf(k, "BackLeaf", { 0.8, 4.95, 1.3 }, { 1.05, 5.35, 1.5 }, 0.3, LEAF, { Type = "Wiggle", Axis = "X", Amount = 20, Speed = 0.7, Phase = 0.2 })

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
		-- a leafy sprig on the left shin
		twig(k, "ShinSprig", { -0.9, 1.35, -0.05 }, { -1.25, 1.65, -0.18 }, 0.08, BARK)
		leaf(k, "ShinLeaf", { -1.25, 1.65, -0.18 }, { -1.55, 1.95, -0.25 }, 0.26, LEAF_LIGHT, { Type = "Wiggle", Axis = "X", Amount = 25, Speed = 0.8, Phase = 0.1 })

		buildTrunk(k)

		-- a few leaves drift up off his crown
		k:Particles({ Pos = { 0, 7.9, 0.2 }, Color = LEAF_LIGHT, Color2 = MOSS, Rate = 3, Size = 0.22, Speed = 0.8, Lifetime = 1.8, Spread = 50, Direction = "Top" })
	end,

	BuildMini = function(k)
		k:Mirror(function()
			k:Part({ Name = "Foot", Shape = "Ellipsoid", Size = { 0.62, 0.36, 1.05 }, Pos = { 0.36, -1.12, -0.15 }, Color = SKIN })
			k:Part({ Name = "Arm", Shape = "Cylinder", Size = { 0.78, 0.13, 0.13 }, Pos = { 0.68, -0.52, -0.08 }, Rot = axisRot(0.53, -0.55, -0.15), Color = BARK, Material = "Wood" })
			k:Part({ Name = "Eye", Shape = "Ball", Size = { 0.16, 0.16, 0.16 }, Pos = { 0.2, 0.47, -0.48 }, Color = PUPIL })
		end)
		k:Part({ Name = "Body", Shape = "Ellipsoid", Size = { 0.9, 1.0, 0.8 }, Pos = { 0, -0.55, 0.05 }, Color = BARK, Material = "Wood" })
		k:Part({ Name = "Head", Shape = "Ellipsoid", Size = { 1.15, 1.05, 1.0 }, Pos = { 0, 0.35, 0.05 }, Color = SKIN })
		k:Part({ Name = "Nose", Shape = "Ellipsoid", Size = { 0.42, 0.75, 0.42 }, Pos = { 0, -0.02, -0.62 }, Color = NOSE })
		k:Part({ Name = "Leaves", Shape = "Ellipsoid", Size = { 1.2, 0.75, 1.15 }, Pos = { 0, 0.7, 0.18 }, Color = LEAF })
		k:Part({ Name = "HatBrim", Shape = "Cylinder", Size = { 0.06, 0.8, 0.8 }, Pos = { 0.05, 1.03, 0.1 }, Rot = { 0, 0, 90 }, Color = HAT })
		k:Part({ Name = "Hat", Shape = "Cylinder", Size = { 0.3, 0.5, 0.5 }, Pos = { 0.05, 1.18, 0.1 }, Rot = { 0, 0, 90 }, Color = HAT })
	end,
}
