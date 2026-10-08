--[[
	Brr Brr Patapim (Uncommon)
	Canonical look: a forest creature that is half proboscis monkey, half tree. A bark-brown
	wooden head and trunk body wrapped in a dark-green robe of leaves, a tan monkey face with
	tiny beady eyes under heavy brows and a HUGE pendulous pink-orange nose that hangs below
	his chin, pale grey cheek fur, long thin branch arms with twig fingers and leaves on the
	elbows, short legs of entwined roots growing into ENORMOUS bare human feet, and a small
	hat on his leafy head ("il mio cappello e' pieno di Slim").

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
local LEAF = "#4c9a33" -- secondary: foliage
local LEAF_LIGHT = "#7cc24a"
local LEAF_DARK = "#2f6e25"
local SKIN = "#e7b08b" -- face + feet
local SKIN_DARK = "#cf8f6a"
local NAIL = "#f8e3d2"
local NOSE = "#e98767" -- accent: the famous nose
local NOSE_LIGHT = "#f6b096"
local NOSTRIL = "#7a3328"
local FUR = "#a39a90" -- grey cheek fur
local FUR_LIGHT = "#c4bcb1"
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

local function add(a, b, s)
	s = s or 1
	return { a[1] + b[1] * s, a[2] + b[2] * s, a[3] + b[3] * s }
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
		blob(k, name, a, b, 0.09, w, color or LEAF, "SmoothPlastic", anim)
	else
		blob(k, name, a, b, w, 0.09, color or LEAF, "SmoothPlastic", anim)
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
		Rot = { 0, 0, -(lean or 0) * 60 },
		Color = SHROOM_CAP,
	})
end

--------------------------------------------------------------------------------------------
-- Giant bare human foot (local to an ankle group; s = 1 right foot (+X), -1 left foot)
--------------------------------------------------------------------------------------------
local FOOT_X = 1.0
local FOOT_Z = 0.15
local TOES = { -- x offset (toward the outside of the foot), y, z, size x, y, z
	{ -0.47, 0.25, -2.12, 0.56, 0.5, 0.72 }, -- big toe (inner side)
	{ -0.06, 0.21, -2.1, 0.36, 0.4, 0.56 },
	{ 0.22, 0.19, -2.0, 0.32, 0.36, 0.5 },
	{ 0.46, 0.17, -1.88, 0.29, 0.32, 0.46 },
	{ 0.66, 0.15, -1.72, 0.26, 0.28, 0.4 },
}

local function buildFoot(k, s)
	k:Group({ Name = "Foot", Pos = { FOOT_X * s, 0, FOOT_Z }, Rot = { 0, -6 * s, 0 } }, function()
		local function X(o)
			return o * s
		end
		k:Part({ Name = "FootSole", Shape = "Ellipsoid", Size = { 1.6, 0.62, 3.15 }, Pos = { 0, 0.31, -0.72 }, Color = SKIN })
		local instep = { X(-0.03), 0.56, -0.2, 0.56, 0.56, 0.875 }
		k:Part({ Name = "FootInstep", Shape = "Ellipsoid", Size = { 1.12, 1.12, 1.75 }, Pos = { instep[1], instep[2], instep[3] }, Color = SKIN })
		k:Part({ Name = "Heel", Shape = "Ellipsoid", Size = { 1.05, 0.82, 1.0 }, Pos = { 0, 0.41, 0.5 }, Color = SKIN })
		for i, t in ipairs(TOES) do
			k:Part({ Name = "Toe" .. i, Shape = "Ellipsoid", Size = { t[4], t[5], t[6] }, Pos = { X(t[1]), t[2], t[3] }, Color = SKIN })
			if i <= 3 then
				k:Part({
					Name = "Toenail" .. i,
					Shape = "Ellipsoid",
					Size = { t[4] * 0.58, 0.06, t[6] * 0.4 },
					Pos = { X(t[1]), t[2] + t[5] * 0.42, t[3] - t[6] * 0.28 },
					Rot = { -26, 0, 0 },
					Color = NAIL,
				})
			end
		end
		-- the root-legs grow into the top of the foot
		local function instepTop(x, z)
			local u, w = (x - instep[1]) / instep[4], (z - instep[3]) / instep[6]
			return instep[2] + instep[5] * math.sqrt(math.max(0, 1 - u * u - w * w))
		end
		k:Part({ Name = "AnkleRoots", Shape = "Ellipsoid", Size = { 0.74, 0.42, 0.74 }, Pos = { 0, 1.08, 0.05 }, Color = BARK_DARK, Material = "Wood" })
		for _, r in ipairs({ { 0.4, -0.5 }, { -0.36, -0.7 } }) do
			local ex, ez = X(r[1]), r[2]
			twig(k, "Root", { X(r[1] * 0.3), 1.1, 0.05 + (ez - 0.05) * 0.25 }, { ex, instepTop(ex, ez) + 0.02, ez }, 0.15, BARK_DARK)
		end
	end)
end

-- Short legs of two entwined roots, crossing at a knotted knee
local function buildLeg(k, s)
	local ankle = { FOOT_X * s, 1.12, FOOT_Z + 0.05 }
	local knee = { 0.9 * s, 2.08, 0.06 }
	local hip = { 0.5 * s, 3.1, 0.04 }
	local d = { 0.1 * s, 0, 0.09 }
	twig(k, "RootShin", add(ankle, d), add(knee, d, -1), 0.21, BARK)
	twig(k, "RootShin", add(ankle, d, -1), add(knee, d), 0.19, BARK_DARK)
	twig(k, "RootThigh", add(knee, d, -1), add(hip, d), 0.22, BARK)
	twig(k, "RootThigh", add(knee, d), add(hip, d, -1), 0.2, BARK_DARK)
	k:Part({ Name = "KneeKnot", Shape = "Ellipsoid", Size = { 0.44, 0.4, 0.44 }, Pos = knee, Color = BARK_DARK, Material = "Wood" })
end

--------------------------------------------------------------------------------------------
-- Branch arm (right side, mirrored for the left)
--------------------------------------------------------------------------------------------
local SH = { 1.04, 5.0, 0.02 }
local EL = { 1.74, 3.95, -0.15 }
local WR = { 2.18, 2.78, -0.38 }

local function buildArm(k)
	joint(k, "Arm", SH, { Type = "Wiggle", Axis = "Z", Amount = 8, Speed = 0.45 }, function()
		k:Part({ Name = "ShoulderKnot", Shape = "Ball", Size = { 0.48, 0.48, 0.48 }, Pos = SH, Color = BARK_DARK, Material = "Wood" })
		twig(k, "UpperArm", SH, EL, 0.26, BARK)
		joint(k, "Forearm", EL, { Type = "Wiggle", Axis = "X", Amount = 9, Speed = 0.6, Phase = 0.3 }, function()
			k:Part({ Name = "ElbowKnot", Shape = "Ellipsoid", Size = { 0.38, 0.4, 0.38 }, Pos = EL, Color = BARK_DARK, Material = "Wood" })
			leaf(k, "ElbowLeaf", { 1.82, 4.0, -0.15 }, { 2.35, 4.32, -0.05 }, 0.32, LEAF, { Type = "Wiggle", Axis = "X", Amount = 25, Speed = 0.9 })
			leaf(k, "ElbowLeaf", { 1.8, 3.92, -0.05 }, { 2.18, 3.85, 0.38 }, 0.28, LEAF_LIGHT, { Type = "Wiggle", Axis = "X", Amount = 25, Speed = 0.8, Phase = 0.5 })
			twig(k, "LowerArm", EL, WR, 0.21, BARK)
			joint(k, "Hand", WR, { Type = "Wiggle", Axis = "Z", Amount = 10, Speed = 0.9, Phase = 0.6 }, function()
				twig(k, "Finger", WR, { 2.0, 2.2, -0.66 }, 0.1, BARK)
				twig(k, "Finger", WR, { 2.3, 2.16, -0.52 }, 0.1, BARK)
				twig(k, "Thumb", WR, { 1.96, 2.56, -0.86 }, 0.09, BARK)
			end)
		end)
	end)
end

--------------------------------------------------------------------------------------------
-- Head: tree-bark skull, tan monkey face, beady eyes, giant nose, leafy crown and hat
--------------------------------------------------------------------------------------------
local function buildNose(k)
	-- the whole nose swings like a pendulum from its root between the eyes
	joint(k, "Nose", { 0, 7.0, -1.05 }, { Type = "Wiggle", Axis = "Z", Amount = 5, Speed = 0.7 }, function()
		blob(k, "NoseBridge", { 0, 7.12, -0.98 }, { 0, 6.12, -1.42 }, 0.5, 0.48, NOSE)
		blob(k, "NoseBody", { 0, 6.82, -1.1 }, { 0, 5.2, -1.66 }, 0.82, 0.86, NOSE)
		joint(k, "NoseTip", { 0, 6.1, -1.45 }, { Type = "Wiggle", Axis = "X", Amount = 6, Speed = 1.1, Phase = 0.3 }, function()
			k:Part({ Name = "NoseBulb", Shape = "Ellipsoid", Size = { 1.22, 1.2, 1.06 }, Pos = { 0, 5.45, -1.7 }, Color = NOSE })
			k:Part({ Name = "NoseShine", Shape = "Ellipsoid", Size = { 0.18, 0.3, 0.08 }, Pos = { 0.24, 5.8, -2.08 }, Rot = { 33, -21, 0 }, Color = NOSE_LIGHT })
			k:Mirror(function()
				k:Part({ Name = "Nostril", Shape = "Ellipsoid", Size = { 0.2, 0.06, 0.14 }, Pos = { 0.22, 4.97, -1.94 }, Rot = { 33, 0, 20 }, Color = NOSTRIL })
			end)
		end)
	end)
end

local function buildHat(k)
	local P = { 0.12, 8.22, 0.14 }
	joint(k, "Hat", P, { Type = "Wiggle", Axis = "Z", Amount = 5, Speed = 0.7, Phase = 0.2 }, function()
		k:Part({ Name = "HatBrim", Shape = "Cylinder", Size = { 0.09, 1.5, 1.5 }, Pos = { P[1], 8.26, P[3] }, Rot = { 0, 0, 90 }, Color = HAT, Material = "Fabric" })
		k:Part({ Name = "HatCrown", Shape = "Cylinder", Size = { 0.62, 0.92, 0.92 }, Pos = { P[1], 8.6, P[3] }, Rot = { 0, 0, 90 }, Color = HAT, Material = "Fabric" })
		k:Part({ Name = "HatBand", Shape = "Cylinder", Size = { 0.15, 0.96, 0.96 }, Pos = { P[1], 8.38, P[3] }, Rot = { 0, 0, 90 }, Color = HAT_BAND, Material = "Fabric" })
		k:Part({ Name = "Slim", Shape = "Ellipsoid", Size = { 1.0, 0.4, 1.0 }, Pos = { P[1], 8.93, P[3] }, Color = SLIME, Material = "Glass", Anim = { Type = "Pulse", Amount = 0.06, Speed = 0.6 } })
		k:Part({ Name = "SlimDrip", Shape = "Ellipsoid", Size = { 0.17, 0.52, 0.13 }, Pos = { P[1] + 0.27, 8.72, P[3] - 0.37 }, Rot = { 0, 36, 0 }, Color = SLIME, Material = "Glass" })
	end, { -6, 0, -10 })
end

local function buildHead(k)
	joint(k, "Head", { 0, 5.45, 0.05 }, { Type = "Wiggle", Axis = "Z", Amount = 3, Speed = 0.45, Phase = 0.15 }, function()
		k:Part({ Name = "Neck", Shape = "Cylinder", Size = { 0.7, 1.0, 1.0 }, Pos = { 0, 5.5, 0.12 }, Rot = { 0, 0, 90 }, Color = BARK_DARK, Material = "Wood" })
		k:Part({ Name = "Skull", Shape = "Ellipsoid", Size = { 2.35, 2.25, 2.1 }, Pos = { 0, 6.75, 0.1 }, Color = BARK, Material = "Wood" })
		k:Part({ Name = "Face", Shape = "Ellipsoid", Size = { 1.8, 1.75, 0.85 }, Pos = { 0, 6.6, -0.72 }, Color = SKIN })
		k:Part({ Name = "Muzzle", Shape = "Ellipsoid", Size = { 1.45, 0.85, 0.8 }, Pos = { 0, 5.95, -0.82 }, Color = SKIN })
		k:Mirror(function()
			k:Part({ Name = "Cheek", Shape = "Ellipsoid", Size = { 0.55, 0.5, 0.36 }, Pos = { 0.64, 6.3, -0.92 }, Rot = { 0, -25, 0 }, Color = SKIN })
			k:Part({ Name = "Ear", Shape = "Ellipsoid", Size = { 0.24, 0.5, 0.42 }, Pos = { 1.18, 6.8, 0.1 }, Color = SKIN_DARK })
			-- pale grey proboscis-monkey fur framing the jaw
			blob(k, "FurTuft", { 1.0, 6.55, -0.32 }, { 1.24, 5.9, -0.5 }, 0.34, 0.24, FUR)
			blob(k, "FurTuft", { 0.8, 6.05, -0.72 }, { 0.98, 5.45, -0.86 }, 0.3, 0.22, FUR_LIGHT)
			k:Part({ Name = "Brow", Shape = "Ellipsoid", Size = { 0.7, 0.22, 0.34 }, Pos = { 0.44, 7.34, -0.98 }, Rot = { 0, -18, -12 }, Color = BARK_DARK, Material = "Wood" })
			-- tiny beady eyes
			k:Part({ Name = "EyeSocket", Shape = "Ellipsoid", Size = { 0.44, 0.38, 0.1 }, Pos = { 0.42, 7.02, -1.02 }, Rot = { 0, -20, 0 }, Color = SKIN_DARK })
			k:Part({ Name = "EyeWhite", Shape = "Ellipsoid", Size = { 0.3, 0.28, 0.14 }, Pos = { 0.42, 7.02, -1.06 }, Rot = { 0, -20, 0 }, Color = EYE_WHITE, Anim = { Type = "Blink", Speed = 0.3 } })
			k:Part({ Name = "Pupil", Shape = "Ellipsoid", Size = { 0.2, 0.22, 0.08 }, Pos = { 0.41, 7.01, -1.12 }, Rot = { 0, -20, 0 }, Color = PUPIL, Anim = { Type = "Blink", Speed = 0.3 } })
			k:Part({ Name = "EyeShine", Shape = "Ball", Size = { 0.07, 0.07, 0.07 }, Pos = { 0.44, 7.07, -1.16 }, Color = SHINE, Anim = { Type = "Blink", Speed = 0.3 } })
		end)
		k:Part({ Name = "HeadMoss", Shape = "Ellipsoid", Size = { 1.25, 0.95, 0.35 }, Pos = { -0.1, 7.25, 1.05 }, Rot = { -25, 0, 6 }, Color = MOSS, Material = "Grass" })
		buildNose(k)

		-- leafy crown
		k:Part({ Name = "CrownLeaves", Shape = "Ellipsoid", Size = { 2.05, 0.85, 1.95 }, Pos = { 0, 7.85, 0.15 }, Color = LEAF_DARK, Material = "Grass" })
		for i, a in ipairs({ 40, 110, 180, 250, 320 }) do
			local ra = math.rad(a)
			local sa, ca = math.sin(ra), math.cos(ra)
			leaf(k, "CrownLeaf", { 0.55 * sa, 7.98, 0.15 - 0.5 * ca }, { 1.22 * sa, 8.28, 0.15 - 1.12 * ca }, 0.5, if i % 2 == 0 then LEAF_LIGHT else LEAF, nil, true)
		end
		leaf(k, "CrownSprig", { -0.6, 8.05, 0.2 }, { -1.25, 8.5, 0.38 }, 0.32, LEAF_LIGHT, { Type = "Wiggle", Axis = "X", Amount = 20, Speed = 0.6, Phase = 0.4 })
		leaf(k, "CrownSprig", { 0.3, 8.1, 0.7 }, { 0.5, 8.55, 1.25 }, 0.32, LEAF, { Type = "Wiggle", Axis = "X", Amount = 20, Speed = 0.8, Phase = 0.7 }, true)

		buildHat(k)
	end)
end

--------------------------------------------------------------------------------------------
-- Trunk body under an open robe of leaves (sways gently from the hips like a tree)
--------------------------------------------------------------------------------------------
-- right half of the leafy robe {cx, cy, cz, semiX, semiY, semiZ}; mirrored for the left
local ROBE = { 0.54, 4.2, 0.1, 0.68, 1.2, 0.98 }

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

-- overlapping leaf "shingle" lying on the robe, its tip flared out from the surface
local function shingle(k, a, y, size, color, roll, flare)
	k:Group({ Name = "Shingle", Pos = robePoint(a, y, 0.02), Rot = { 0, -a, 0 } }, function()
		k:Part({ Name = "RobeLeaf", Shape = "Ellipsoid", Size = size, Rot = { flare or 14, 0, roll }, Color = color })
	end)
end

local ROBE_LEAVES = { -- azimuth, height, colour, roll in the robe plane
	{ 24, 4.75, LEAF, 14 },
	{ 80, 4.85, LEAF_LIGHT, -12 },
	{ 52, 3.85, LEAF_LIGHT, -16 },
	{ 118, 4.05, LEAF, 18 },
	{ 214, 4.2, LEAF_LIGHT, 10 },
}

local function buildTrunk(k)
	joint(k, "Trunk", { 0, 2.95, 0 }, { Type = "Wiggle", Axis = "Z", Amount = 2.5, Speed = 0.35 }, function()
		k:Part({ Name = "RootFlare", Shape = "Ellipsoid", Size = { 1.8, 0.9, 1.55 }, Pos = { 0, 3.08, 0.03 }, Color = BARK_DARK, Material = "Wood" })
		k:Part({ Name = "TrunkCore", Shape = "Cylinder", Size = { 2.3, 1.6, 1.6 }, Pos = { 0, 4.05, 0 }, Rot = { 0, 0, 90 }, Color = BARK, Material = "Wood" })
		-- knot hole belly button on the bark showing between the robe halves
		k:Part({ Name = "KnotRim", Shape = "Ellipsoid", Size = { 0.42, 0.6, 0.2 }, Pos = { 0, 3.95, -0.78 }, Color = BARK_LIGHT, Material = "Wood" })
		k:Part({ Name = "KnotHole", Shape = "Ellipsoid", Size = { 0.22, 0.36, 0.08 }, Pos = { 0, 3.95, -0.86 }, Color = HOLE })

		k:Mirror(function()
			k:Part({ Name = "LeafRobe", Shape = "Ellipsoid", Size = { ROBE[4] * 2, ROBE[5] * 2, ROBE[6] * 2 }, Pos = { ROBE[1], ROBE[2], ROBE[3] }, Color = LEAF_DARK, Material = "Grass" })
			for _, c in ipairs(ROBE_LEAVES) do
				shingle(k, c[1], c[2], { 0.62, 1.05, 0.14 }, c[3], c[4])
			end
			-- pointed leaves hanging from the robe's hem
			for i, a in ipairs({ 22, 80, 140 }) do
				local top = robePoint(a, 3.35, -0.06)
				local ra = math.rad(a)
				local tip = { top[1] + 0.25 * math.sin(ra), 2.72 - 0.06 * i, top[3] - 0.25 * math.cos(ra) }
				leaf(k, "HemLeaf", top, tip, 0.42, if i % 2 == 0 then LEAF_LIGHT else LEAF, nil, true)
			end
		end)

		-- leafy collar around the neck (open at the front for the nose)
		for i, a in ipairs({ 70, 145, 215, 290 }) do
			local ra = math.rad(a)
			local sa, ca = math.sin(ra), math.cos(ra)
			leaf(k, "CollarLeaf", { 0.45 * sa, 5.3, 0.1 - 0.42 * ca }, { 1.0 * sa, 5.55, 0.1 - 0.92 * ca }, 0.62, if i % 2 == 0 then LEAF_LIGHT else LEAF, nil, true)
		end

		-- a cluster of mushrooms sprouting from his right shoulder
		mushroom(k, "Mushroom", { 1.0, 5.08, 0.3 }, 0.42, 0.52, 0.05)
		mushroom(k, "Mushroom", { 0.76, 5.12, 0.55 }, 0.28, 0.34, -0.06)

		-- little branch growing out of the back
		twig(k, "BackBranch", { 0.2, 4.4, 0.8 }, { 0.6, 5.05, 1.35 }, 0.18, BARK)
		leaf(k, "BackLeaf", { 0.6, 5.05, 1.35 }, { 0.85, 5.45, 1.55 }, 0.32, LEAF_LIGHT, { Type = "Wiggle", Axis = "X", Amount = 20, Speed = 0.7, Phase = 0.2 })

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
		-- left foot plants, right foot taps along to the "brr brr" (pivoting on its heel)
		buildFoot(k, -1)
		joint(k, "TappingFoot", { FOOT_X, 0.02, FOOT_Z + 0.95 }, { Type = "Wiggle", Axis = "X", Amount = 3.5, Speed = 0.9 }, function()
			buildFoot(k, 1)
		end, { 3.5, 0, 0 })
		buildLeg(k, -1)
		buildLeg(k, 1)

		buildTrunk(k)

		-- a few leaves drift up off his crown
		k:Particles({ Pos = { 0, 8.1, 0.2 }, Color = LEAF_LIGHT, Color2 = MOSS, Rate = 3, Size = 0.22, Speed = 0.8, Lifetime = 1.8, Spread = 50, Direction = "Top" })
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
