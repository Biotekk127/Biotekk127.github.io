--[[
	Tung Tung Tung Sahur (Rare)
	Canonical look: a tall, light-brown anthropomorphic wooden log (worn rounded base, grain
	lines, knots, cracks and a flat sawn top showing growth rings) with a simple, wide-eyed
	face: big round white eyes with tiny pupils, thin dark brows and a wide, unsettling
	grin. Stick-thin darker wooden arms and bare-footed legs; the right hand holds a plain
	wooden baseball bat raised beside the head, ready to knock "tung tung tung".

	Coordinates: feet on y = 0, faces -Z. Most parts are written in world coordinates by
	nesting an un-animated "offset" group inside each animated joint group.
]]

-- Palette ------------------------------------------------------------------------------
local WOOD = "#d6a56c" -- dominant: light-brown log
local WOOD_LIGHT = "#e2b980" -- sanded chamfer round the sawn top
local WOOD_SHADE = "#bd8850" -- worn base, eye sockets, peg holes, branch stub
local GRAIN = "#b47c45" -- grain lines
local GRAIN_SOFT = "#c4915a" -- softer grain on the beauty side
local END_LIGHT = "#efd3a2" -- sawn end grain
local END_DARK = "#c99460" -- growth rings
local PITH = "#8a5a30"
local KNOT = "#7a4a24"
local KNOT_RING = "#a06a37"
local CRACK = "#4a2c18"

local LIMB = "#a5713e" -- stick-thin darker wooden arms and legs
local LIMB_DARK = "#8a5a2f" -- joints
local BAT = "#b0682f" -- plain varnished baseball bat
local BAT_DARK = "#7a421c"
local BAT_LIGHT = "#cf8f52"
local BAT_END = "#e2b27a"

local EYE_WHITE = "#fff8ec"
local PUPIL = "#1b1b24"
local SHINE = "#fffdf6"
local BROW = "#3a2314"
local MOUTH = "#2a1610"
local TEETH = "#fff1d8"

local GLOW = "#ffbf73" -- Rare flair: warm glow + sawdust
local DUST = "#e9cc9c"

-- Layout (world studs) -------------------------------------------------------------------
local LOG_BOTTOM = 2.55
local LOG_TOP = 8.35
local RADIUS = 1.2 -- log radius
local EYE_Y = 7.08
local MOUTH_Y = 6.08 -- top edge of the grin at the centre
local SHOULDER_Y = 5.45

-- Log radius at height y (kept as a function so the surface helpers stay generic)
local function R(_y)
	return RADIUS
end

local function deg(r)
	return r * 180 / math.pi
end

local function norm(v)
	local l = math.sqrt(v[1] * v[1] + v[2] * v[2] + v[3] * v[3])
	return { v[1] / l, v[2] / l, v[3] / l }
end

local function add(a, b, s)
	s = s or 1
	return { a[1] + b[1] * s, a[2] + b[2] * s, a[3] + b[3] * s }
end

local function cross(a, b)
	return { a[2] * b[3] - a[3] * b[2], a[3] * b[1] - a[1] * b[3], a[1] * b[2] - a[2] * b[1] }
end

-- Rotation that points a Cylinder's (or Ellipsoid's) local X axis along vector v
local function axisRot(v)
	local n = norm(v)
	return { 0, deg(math.atan2(-n[3], n[1])), deg(math.asin(n[2])) }
end

-- Cylinder between two points (extra length lets joints overlap)
local function segment(k, name, a, b, d, color, material, extra)
	local v = { b[1] - a[1], b[2] - a[2], b[3] - a[3] }
	local len = math.sqrt(v[1] * v[1] + v[2] * v[2] + v[3] * v[3])
	k:Part({
		Name = name,
		Shape = "Cylinder",
		Size = { len + (extra or d * 0.5), d, d },
		Pos = { (a[1] + b[1]) / 2, (a[2] + b[2]) / 2, (a[3] + b[3]) / 2 },
		Rot = axisRot(v),
		Color = color,
		Material = material or "Wood",
	})
end

-- Point on the log surface: theta in degrees measured from the front (-Z) toward +X
local function logPoint(theta, y, out)
	local t = math.rad(theta)
	local r = R(y) + (out or 0)
	return { r * math.sin(t), y, -r * math.cos(t) }
end

-- Part lying on the log surface. Its local -Z faces outward, local Y is up, and `tilt`
-- turns it inside the surface plane.
local function onLog(k, spec, theta, y, out, tilt)
	spec.Pos = logPoint(theta, y, out)
	spec.Rot = { 0, -theta, tilt or 0 }
	spec.Material = spec.Material or "Wood"
	k:Part(spec)
end

-- Group oriented to the log surface (local -Z = outward normal)
local function surfaceGroup(k, name, theta, y, out, anim, fn)
	k:Group({ Name = name, Pos = logPoint(theta, y, out), Rot = { 0, -theta, 0 }, Anim = anim }, fn)
end

local function thetaAt(x, y)
	return deg(math.asin(x / R(y)))
end

--------------------------------------------------------------------------------------------
-- The log (world coordinates)
--------------------------------------------------------------------------------------------
local function grainLine(k, theta, y0, y1, bend, color)
	local ym = (y0 + y1) / 2
	local halves = { { y0, ym, bend }, { ym, y1, -bend } }
	for _, h in halves do
		-- sunk into the surface so the lines never stand proud of the silhouette
		onLog(k, {
			Name = "Grain",
			Size = { 0.055, h[2] - h[1] + 0.03, 0.06 },
			Color = color or GRAIN,
		}, theta, (h[1] + h[2]) / 2, -0.02, h[3])
	end
end

local function knot(k, theta, y, s)
	onLog(k, { Name = "Knot", Shape = "Ellipsoid", Size = { 0.52 * s, 0.38 * s, 0.14 }, Color = KNOT_RING }, theta, y, -0.02)
	onLog(k, { Name = "KnotCore", Shape = "Ellipsoid", Size = { 0.34 * s, 0.24 * s, 0.14 }, Color = KNOT }, theta, y, 0.0)
	onLog(k, { Name = "KnotHeart", Shape = "Ellipsoid", Size = { 0.13 * s, 0.1 * s, 0.1 }, Color = CRACK }, theta, y, 0.03)
end

-- Zig-zag crack running down the surface from (theta, y)
local function crack(k, theta, y, tilts, len)
	local s, cy = 0, y -- s = tangential offset (studs)
	for _, tl in tilts do
		local a = math.rad(tl)
		local ns, ny = s + math.sin(a) * len, cy - math.cos(a) * len
		local my = (cy + ny) / 2
		onLog(k, {
			Name = "Crack",
			Size = { 0.05, len + 0.04, 0.06 },
			Color = CRACK,
		}, theta + deg(((s + ns) / 2) / R(my)), my, -0.02, tl)
		s, cy = ns, ny
	end
end

-- A sawn-off branch stub: breaks the "tin can" silhouette and says LOG instantly
local function branchStub(k, theta, y)
	local t = math.rad(theta)
	local dir = norm({ math.sin(t), 0.45, -math.cos(t) })
	local base = logPoint(theta, y, -0.08)
	k:Part({ Name = "BranchCollar", Shape = "Ellipsoid", Size = { 0.42, 0.66, 0.66 }, Pos = add(base, dir, 0.06), Rot = axisRot(dir), Color = WOOD, Material = "Wood" })
	segment(k, "BranchStub", base, add(base, dir, 0.46), 0.4, WOOD_SHADE, "Wood", 0)
	k:Part({ Name = "StubEnd", Shape = "Cylinder", Size = { 0.05, 0.32, 0.32 }, Pos = add(base, dir, 0.465), Rot = axisRot(dir), Color = END_LIGHT, Material = "Wood" })
	k:Part({ Name = "StubRing", Shape = "Cylinder", Size = { 0.05, 0.17, 0.17 }, Pos = add(base, dir, 0.48), Rot = axisRot(dir), Color = END_DARK, Material = "Wood" })
end

local function buildLog(k)
	-- big forms: the trunk, a worn rounded base and a sanded chamfer under the sawn top
	k:Part({ Name = "Trunk", Shape = "Cylinder", Size = { LOG_TOP - LOG_BOTTOM, RADIUS * 2, RADIUS * 2 }, Pos = { 0, (LOG_TOP + LOG_BOTTOM) / 2, 0 }, Rot = { 0, 0, 90 }, Color = WOOD, Material = "Wood" })
	k:Part({ Name = "BaseLip", Shape = "Ellipsoid", Size = { RADIUS * 2 + 0.08, 0.32, RADIUS * 2 + 0.08 }, Pos = { 0, LOG_BOTTOM + 0.04, 0 }, Color = WOOD_SHADE, Material = "Wood" })
	k:Part({ Name = "TopChamfer", Shape = "Cylinder", Size = { 0.12, RADIUS * 2 - 0.08, RADIUS * 2 - 0.08 }, Pos = { 0, LOG_TOP + 0.04, 0 }, Rot = { 0, 0, 90 }, Color = WOOD_LIGHT, Material = "Wood" })

	-- sawn top: concentric growth rings, flush with the chamfer (each disc slightly off-centre)
	local rings = {
		{ 2.2, END_LIGHT }, { 2.04, END_DARK }, { 1.9, END_LIGHT }, { 1.62, END_DARK },
		{ 1.5, END_LIGHT }, { 1.2, END_DARK }, { 1.08, END_LIGHT }, { 0.76, END_DARK },
		{ 0.64, END_LIGHT }, { 0.3, PITH },
	}
	for i, r in rings do
		local off = (i - 1) * 0.012
		k:Part({
			Name = "EndGrain",
			Shape = "Cylinder",
			Size = { 0.05, r[1], r[1] },
			Pos = { off, LOG_TOP + 0.09 + (i - 1) * 0.005, -off * 0.6 },
			Rot = { 0, 0, 90 },
			Color = r[2],
			Material = "Wood",
		})
	end
	-- radial checking cracks across the end grain
	local TOPY = LOG_TOP + 0.14
	k:Part({ Name = "TopCrack", Size = { 0.05, 0.05, 0.8 }, Pos = { 0.32, TOPY, 0.38 }, Rot = { 0, 34, 0 }, Color = CRACK })
	k:Part({ Name = "TopCrack", Size = { 0.05, 0.05, 0.46 }, Pos = { -0.55, TOPY, -0.08 }, Rot = { 0, -78, 0 }, Color = CRACK })

	-- medium: grain lines of varied length (soft and short on the front, all round elsewhere)
	local LB, LT = LOG_BOTTOM, LOG_TOP
	local grains = {
		{ -28, LB + 0.4, 4.85, 2.5, GRAIN_SOFT }, { 27, LB + 0.55, 4.6, -2.5, GRAIN_SOFT },
		{ 58, LB + 0.25, LT - 0.3, 2 }, { 80, LB + 0.2, 4.85, -2 },
		{ 120, LB + 0.3, LT - 0.25, 2 }, { 158, 4.3, LT - 0.2, -2 },
		{ -58, LB + 0.2, LT - 0.45, -2 }, { -82, LB + 0.6, LT - 0.2, 2 },
		{ -106, LB + 0.2, 5.9, -2 }, { -134, LB + 0.3, LT - 0.25, 2 },
		{ -156, 4.0, LT - 0.3, -2 },
	}
	for _, g in grains do
		grainLine(k, g[1], g[2], g[3], g[4], g[5])
	end

	-- knots (between grain lines)
	knot(k, -14, 3.45, 0.62)
	knot(k, -120, 6.7, 0.9)
	knot(k, 141, 7.0, 0.85)
	knot(k, -169, 3.15, 0.8)
	knot(k, 69, 4.25, 0.7)

	-- cracks
	crack(k, 166, LOG_TOP - 0.06, { 12, -20, 16 }, 0.34)
	crack(k, -70, LOG_TOP - 0.08, { -14, 18, -10 }, 0.28)
	crack(k, 44, LOG_BOTTOM + 0.95, { 18, -16, 14 }, 0.28)

	-- old nail holes / worm holes
	for _, h in { { 132, 5.5 }, { -94, 3.85 }, { -146, 7.3 }, { 104, 6.9 } } do
		onLog(k, { Name = "NailHole", Shape = "Ellipsoid", Size = { 0.09, 0.09, 0.06 }, Color = CRACK }, h[1], h[2], 0.0)
	end

	-- a sawn-off branch round the back of his right flank
	branchStub(k, 140, 3.45)

	-- open wood pores: tiny dark flecks that give the plain front some texture
	for _, f in { { -6, 3.0 }, { 13, 3.9 }, { 8, 2.95 }, { -20, 4.45 } } do
		onLog(k, { Name = "Pore", Shape = "Ellipsoid", Size = { 0.05, 0.12, 0.05 }, Color = GRAIN }, f[1], f[2], 0.0)
	end

	-- the kentongan slit drum on his back
	onLog(k, { Name = "SlitRim", Size = { 0.38, 1.7, 0.08 }, Color = WOOD_SHADE }, 180, 4.75, -0.02)
	onLog(k, { Name = "Slit", Size = { 0.2, 1.46, 0.08 }, Color = CRACK }, 180, 4.75, 0.0)
	onLog(k, { Name = "SlitEnd", Shape = "Ellipsoid", Size = { 0.26, 0.2, 0.1 }, Color = CRACK }, 180, 5.48, 0.0)
	onLog(k, { Name = "SlitEnd", Shape = "Ellipsoid", Size = { 0.26, 0.2, 0.1 }, Color = CRACK }, 180, 4.02, 0.0)

	-- peg holes where the stick limbs are plugged in
	k:Mirror(function()
		onLog(k, { Name = "ShoulderPeg", Shape = "Ellipsoid", Size = { 0.36, 0.36, 0.12 }, Color = WOOD_SHADE }, 90, SHOULDER_Y, 0.0)
		k:Part({ Name = "HipPeg", Shape = "Cylinder", Size = { 0.1, 0.36, 0.36 }, Pos = { 0.55, LOG_BOTTOM - 0.1, 0 }, Rot = { 0, 0, 90 }, Color = LIMB_DARK, Material = "Wood" })
	end)
end

--------------------------------------------------------------------------------------------
-- Face
--------------------------------------------------------------------------------------------
local BLINK = { Type = "Blink", Speed = 0.3, Phase = 0.2 }
local EYE_X = 0.52

local function buildFace(k)
	k:Mirror(function()
		-- big round bulging eye in a thin carved socket
		surfaceGroup(k, "Eye", thetaAt(EYE_X, EYE_Y), EYE_Y, 0.0, nil, function()
			k:Part({ Name = "EyeSocket", Shape = "Ellipsoid", Size = { 0.99, 1.05, 0.2 }, Pos = { 0, 0, 0.01 }, Color = WOOD_SHADE, Material = "Wood" })
			k:Part({ Name = "EyeWhite", Shape = "Ellipsoid", Size = { 0.92, 0.98, 0.3 }, Pos = { 0, 0, 0.0 }, Color = EYE_WHITE, Anim = BLINK })
			k:Group({ Name = "Look", Anim = { Type = "Bob", Axis = "X", Amount = 0.05, Speed = 0.25, Phase = 0.1 } }, function()
				k:Part({ Name = "Pupil", Shape = "Ellipsoid", Size = { 0.22, 0.24, 0.1 }, Pos = { -0.02, 0.0, -0.13 }, Color = PUPIL, Anim = BLINK })
				k:Part({ Name = "EyeShine", Shape = "Ball", Size = { 0.08, 0.08, 0.08 }, Pos = { 0.045, 0.07, -0.18 }, Color = SHINE, Material = "Neon", Anim = BLINK })
				k:Part({ Name = "EyeShineSmall", Shape = "Ball", Size = { 0.05, 0.05, 0.05 }, Pos = { -0.08, -0.06, -0.17 }, Color = SHINE, Anim = BLINK })
			end)
		end)
		-- thin arched brow, raised a little high (unsettling); two overlapping ellipsoids
		-- give a smooth arch that hugs the curve of the log
		surfaceGroup(k, "Brow", thetaAt(0.5, EYE_Y + 0.74), EYE_Y + 0.74, -0.01, { Type = "Bob", Axis = "Y", Amount = 0.035, Speed = 0.45 }, function()
			k:Part({ Name = "BrowInner", Shape = "Ellipsoid", Size = { 0.4, 0.12, 0.07 }, Pos = { -0.15, -0.03, 0.01 }, Rot = { 0, 7, 15 }, Color = BROW })
			k:Part({ Name = "BrowOuter", Shape = "Ellipsoid", Size = { 0.4, 0.12, 0.07 }, Pos = { 0.17, -0.02, 0.012 }, Rot = { 0, -8, -13 }, Color = BROW })
		end)
	end)

	-- wide grin: a smooth crescent of overlapping ellipsoids, thick in the middle and thin at
	-- the up-turned corners, with a row of rounded upper teeth
	local N = 9
	local HALF = 0.84
	local CURVE = 0.27
	for i = 0, N - 1 do
		local u = -1 + (2 * i + 1) / N
		local x = HALF * u
		local yTop = MOUTH_Y + CURVE * u * u
		local h = 0.075 + 0.2 * (1 - u * u)
		local yc = yTop - h / 2
		local slope = (2 * CURVE + 0.2) * u / HALF
		onLog(k, { Name = "Mouth", Shape = "Ellipsoid", Size = { (2 * HALF / N) * 1.75, h + 0.03, 0.08 }, Color = MOUTH }, thetaAt(x, yc), yc, -0.015, deg(math.atan(slope)))
	end
	for _, u in { -0.52, -0.26, 0, 0.26, 0.52 } do
		local x = HALF * u
		local yt = MOUTH_Y + CURVE * u * u - 0.065
		local slope = 2 * CURVE * u / HALF
		onLog(k, { Name = "Tooth", Shape = "Ellipsoid", Size = { 0.25, 0.12, 0.07 }, Color = TEETH }, thetaAt(x, yt), yt, 0.0, deg(math.atan(slope)))
	end
	k:Mirror(function()
		local cx = HALF + 0.06
		onLog(k, { Name = "SmileCrease", Shape = "Ellipsoid", Size = { 0.06, 0.2, 0.06 }, Color = MOUTH }, thetaAt(cx, MOUTH_Y + 0.31), MOUTH_Y + 0.31, -0.01, -28)
	end)
end

--------------------------------------------------------------------------------------------
-- Arms
--------------------------------------------------------------------------------------------
local S_R = { 1.15, SHOULDER_Y, 0 }
local E_R = { 1.96, 5.02, 0.06 }
local H_R = { 2.14, 5.95, -0.08 }
local BAT_DIR = norm({ 0.16, 1, 0.2 })

local S_L = { -1.15, SHOULDER_Y, 0 }
local E_L = { -1.68, 4.55, -0.06 }
local H_L = { -1.86, 3.7, -0.12 }

local function batPoint(t)
	return add(H_R, BAT_DIR, t)
end

local function buildBat(k)
	-- two axes perpendicular to the bat, for grain lines and scuffs
	local u = norm(cross(BAT_DIR, { 0, 0, 1 }))
	local w = norm(cross(BAT_DIR, u))
	local function around(t, a, r)
		local ar = math.rad(a)
		local off = add({ u[1] * math.cos(ar), u[2] * math.cos(ar), u[3] * math.cos(ar) }, w, math.sin(ar))
		return add(batPoint(t), off, r)
	end
	local rot = axisRot(BAT_DIR)

	-- flared knob, plain wooden handle with two grip grooves
	k:Part({ Name = "BatKnob", Shape = "Ellipsoid", Size = { 0.16, 0.32, 0.32 }, Pos = batPoint(-0.6), Rot = rot, Color = BAT, Material = "Wood" })
	segment(k, "KnobNeck", batPoint(-0.62), batPoint(-0.5), 0.27, BAT_DARK, "Wood", 0)
	segment(k, "Handle", batPoint(-0.55), batPoint(1.25), 0.17, BAT, "Wood", 0)
	for _, t in { -0.4, 0.3 } do
		segment(k, "GripGroove", batPoint(t - 0.025), batPoint(t + 0.025), 0.185, BAT_DARK, "Wood", 0)
	end
	-- smooth taper into a fat barrel (two overlapping ellipsoids + a cylinder)
	k:Part({ Name = "BatTaper", Shape = "Ellipsoid", Size = { 2.0, 0.36, 0.36 }, Pos = batPoint(1.9), Rot = rot, Color = BAT, Material = "Wood" })
	k:Part({ Name = "BatSwell", Shape = "Ellipsoid", Size = { 1.6, 0.58, 0.58 }, Pos = batPoint(2.6), Rot = rot, Color = BAT, Material = "Wood" })
	segment(k, "Barrel", batPoint(2.6), batPoint(3.12), 0.58, BAT, "Wood", 0)
	k:Part({ Name = "BatTip", Shape = "Ellipsoid", Size = { 0.2, 0.58, 0.58 }, Pos = batPoint(3.12), Rot = rot, Color = BAT, Material = "Wood" })
	segment(k, "BatEndGrain", batPoint(3.19), batPoint(3.24), 0.34, BAT_END, "Wood", 0)

	-- varnish highlight streak and grain lines along the barrel
	segment(k, "BatShine", around(2.2, 135, 0.23), around(3.05, 135, 0.275), 0.06, BAT_LIGHT, "Wood", 0)
	for _, a in { 20, 250 } do
		segment(k, "BatGrain", around(2.15, a, 0.22), around(3.05, a, 0.275), 0.05, BAT_DARK, "Wood", 0)
	end
	-- worn dents on the hitting face from all that knocking
	for _, s in { { 2.75, 200 }, { 2.95, 228 } } do
		k:Part({ Name = "BatDent", Shape = "Ellipsoid", Size = { 0.14, 0.14, 0.14 }, Pos = around(s[1], s[2], 0.26), Color = BAT_DARK, Material = "Wood" })
	end

	-- sawdust shaken off with every knock
	k:Particles({ Pos = batPoint(3.0), Color = "#d9a86a", Color2 = "#f3dcae", Rate = 3, Size = 0.1, Speed = 0.8, Lifetime = 1.2, Spread = 70, Direction = "Top" })
end

local function buildBatArm(k)
	k:Group({ Name = "BatArm", Pos = S_R, Anim = { Type = "Wiggle", Axis = "X", Amount = 20, Speed = 0.9 } }, function()
		k:Group({ Name = "BatArmOffset", Pos = { -S_R[1], -S_R[2], -S_R[3] } }, function()
			k:Part({ Name = "Shoulder", Shape = "Ball", Size = { 0.26, 0.26, 0.26 }, Pos = add(S_R, { 0.08, 0, 0 }), Color = LIMB_DARK, Material = "Wood" })
			segment(k, "UpperArm", S_R, E_R, 0.2, LIMB)
			k:Part({ Name = "Elbow", Shape = "Ball", Size = { 0.27, 0.27, 0.27 }, Pos = E_R, Color = LIMB_DARK, Material = "Wood" })
			segment(k, "Forearm", E_R, H_R, 0.19, LIMB)
			-- wrist snap lags the shoulder a little for a punchy knock
			k:Group({ Name = "Wrist", Pos = H_R, Anim = { Type = "Wiggle", Axis = "X", Amount = 10, Speed = 0.9, Phase = 0.12 } }, function()
				k:Group({ Name = "WristOffset", Pos = { -H_R[1], -H_R[2], -H_R[3] } }, function()
					-- fist wrapped around the handle
					local f = norm({ 0.3, -0.05, -1 })
					local q = cross(BAT_DIR, f)
					f = norm(cross(q, BAT_DIR))
					k:Part({ Name = "Fist", Shape = "Ellipsoid", Size = { 0.4, 0.42, 0.38 }, Pos = H_R, Rot = axisRot(BAT_DIR), Color = LIMB, Material = "Wood" })
					for i = 0, 3 do
						k:Part({ Name = "Knuckle", Shape = "Ball", Size = { 0.12, 0.12, 0.12 }, Pos = add(add(H_R, BAT_DIR, -0.15 + i * 0.1), f, 0.17), Color = LIMB, Material = "Wood" })
					end
					k:Part({ Name = "Thumb", Shape = "Ball", Size = { 0.13, 0.13, 0.13 }, Pos = add(add(H_R, BAT_DIR, 0.2), norm(q), -0.12), Color = LIMB, Material = "Wood" })
					buildBat(k)
				end)
			end)
		end)
	end)
end

local function buildSwayArm(k)
	k:Group({ Name = "SwayArm", Pos = S_L, Anim = { Type = "Wiggle", Axis = "X", Amount = 14, Speed = 0.45, Phase = 0.25 } }, function()
		k:Group({ Name = "SwayArmOffset", Pos = { -S_L[1], -S_L[2], -S_L[3] } }, function()
			k:Part({ Name = "Shoulder", Shape = "Ball", Size = { 0.26, 0.26, 0.26 }, Pos = add(S_L, { -0.08, 0, 0 }), Color = LIMB_DARK, Material = "Wood" })
			segment(k, "UpperArm", S_L, E_L, 0.2, LIMB)
			k:Part({ Name = "Elbow", Shape = "Ball", Size = { 0.27, 0.27, 0.27 }, Pos = E_L, Color = LIMB_DARK, Material = "Wood" })
			segment(k, "Forearm", E_L, H_L, 0.19, LIMB)
			k:Group({ Name = "Hand", Pos = H_L, Anim = { Type = "Wiggle", Axis = "Z", Amount = 8, Speed = 0.45, Phase = 0.4 } }, function()
				k:Group({ Name = "HandOffset", Pos = { -H_L[1], -H_L[2], -H_L[3] } }, function()
					local hx, hy, hz = H_L[1], H_L[2], H_L[3]
					k:Part({ Name = "Wrist", Shape = "Ball", Size = { 0.22, 0.22, 0.22 }, Pos = H_L, Color = LIMB_DARK, Material = "Wood" })
					k:Part({ Name = "Palm", Shape = "Ellipsoid", Size = { 0.18, 0.4, 0.34 }, Pos = { hx - 0.02, hy - 0.2, hz }, Color = LIMB, Material = "Wood" })
					-- relaxed fingers that drum along to the beat
					local knuck = { hx - 0.02, hy - 0.34, hz }
					k:Group({ Name = "Fingers", Pos = knuck, Anim = { Type = "Wiggle", Axis = "Z", Amount = 12, Speed = 0.9, Phase = 0.3 } }, function()
						for _, dz in { -0.11, -0.035, 0.04, 0.11 } do
							segment(k, "Finger", { 0, 0, dz }, { 0.02, -0.2, dz * 1.2 - 0.05 }, 0.07, LIMB)
						end
					end)
					segment(k, "Thumb", { hx - 0.01, hy - 0.14, hz - 0.13 }, { hx + 0.03, hy - 0.3, hz - 0.25 }, 0.08, LIMB)
				end)
			end)
		end)
	end)
end

--------------------------------------------------------------------------------------------
-- Legs (not in the bouncing body, so the feet stay planted)
--------------------------------------------------------------------------------------------
local function buildLeg(k, sx, tap)
	local hip = { sx * 0.55, LOG_BOTTOM - 0.02, 0 }
	local knee = { sx * 0.6, 1.34, -0.04 }
	local ankle = { sx * 0.6, 0.34, 0.04 }
	segment(k, "Thigh", hip, knee, 0.22, LIMB)
	k:Part({ Name = "Knee", Shape = "Ball", Size = { 0.28, 0.28, 0.28 }, Pos = knee, Color = LIMB_DARK, Material = "Wood" })
	segment(k, "Shin", knee, ankle, 0.2, LIMB)

	local pivot = { sx * 0.6, 0.0, 0.3 } -- heel
	k:Group({
		Name = "Foot",
		Pos = pivot,
		Rot = { tap and 5 or 0, 0, 0 },
		Anim = tap and { Type = "Wiggle", Axis = "X", Amount = 5, Speed = 0.9, Phase = 0.05 } or nil,
	}, function()
		k:Group({ Name = "FootOffset", Pos = { -pivot[1], 0, -pivot[3] } }, function()
			local fx = sx * 0.6
			k:Part({ Name = "Ankle", Shape = "Ball", Size = { 0.25, 0.25, 0.25 }, Pos = ankle, Color = LIMB_DARK, Material = "Wood" })
			-- bare wooden foot: flat sole with a heel, a raised instep and graded toes
			k:Part({ Name = "FootSole", Shape = "Ellipsoid", Size = { 0.46, 0.2, 0.92 }, Pos = { fx, 0.1, -0.14 }, Color = LIMB, Material = "Wood" })
			k:Part({ Name = "Instep", Shape = "Ellipsoid", Size = { 0.36, 0.26, 0.56 }, Pos = { fx, 0.19, -0.04 }, Color = LIMB, Material = "Wood" })
			-- big toe on the inside, smaller toes outward
			local toes = { { -0.13, 0.15, -0.56 }, { -0.01, 0.12, -0.58 }, { 0.1, 0.11, -0.55 }, { 0.19, 0.09, -0.49 } }
			-- toes of the planted foot wiggle gently about their own knuckle line
			k:Group({ Name = "Toes", Pos = { fx, 0.06, -0.5 }, Anim = (not tap) and { Type = "Wiggle", Axis = "X", Amount = 6, Speed = 0.6, Phase = 0.5 } or nil }, function()
				for _, t in toes do
					local d = t[2]
					k:Part({ Name = "Toe", Shape = "Ball", Size = { d, d, d }, Pos = { sx * t[1], d / 2 - 0.06, t[3] + 0.5 }, Color = LIMB, Material = "Wood" })
				end
			end)
		end)
	end)
end

return {
	Id = "TungTungTungSahur",
	Name = "Tung Tung Tung Sahur",
	Rarity = "Rare",
	Emoji = "🪵",
	Color = WOOD,
	Tagline = "Didn't answer the sahur call? Tung tung tung...",
	Lore = "A wooden log with a bat who walks the streets before dawn, knocking to wake everyone for sahur. Ignore his call three times and he comes to your door personally. Nobody has ever ignored it four times.",

	Build = function(k)
		buildLeg(k, 1, true)
		buildLeg(k, -1, false)

		-- body bounces in rhythm and sways a little around the base of the log
		k:Group({ Name = "Body", Pos = { 0, LOG_BOTTOM, 0 }, Anim = { Type = "Bob", Axis = "Y", Amount = 0.07, Speed = 1.8 } }, function()
			k:Group({ Name = "Sway", Anim = { Type = "Wiggle", Axis = "Z", Amount = 2.5, Speed = 0.45 } }, function()
				k:Group({ Name = "BodyOffset", Pos = { 0, -LOG_BOTTOM, 0 } }, function()
					buildLog(k)
					buildFace(k)
					buildBatArm(k)
					buildSwayArm(k)
				end)
			end)
		end)

		-- Rare flair: warm key glow on the face, a soft rim light behind, drifting wood dust
		k:Light({ Pos = { 0, 6.4, -2.1 }, Color = GLOW, Range = 10, Brightness = 0.9 })
		k:Light({ Pos = { 0, 9.0, 1.8 }, Color = "#ffd59a", Range = 8, Brightness = 0.6 })
		k:Particles({ Pos = { 0, 0.3, 0 }, Color = DUST, Color2 = "#fff1d6", Rate = 4, Size = 0.16, Speed = 0.5, Lifetime = 2.2, Spread = 180, Direction = "Top" })
	end,

	BuildMini = function(k)
		k:Part({ Name = "Log", Shape = "Cylinder", Size = { 1.6, 0.94, 0.94 }, Pos = { 0, 0.14, 0 }, Rot = { 0, 0, 90 }, Color = WOOD, Material = "Wood" })
		-- sawn end grain on top so it reads as a log, not a can
		k:Part({ Name = "EndGrain", Shape = "Cylinder", Size = { 0.05, 0.8, 0.8 }, Pos = { 0, 0.95, 0 }, Rot = { 0, 0, 90 }, Color = END_LIGHT, Material = "Wood" })
		k:Mirror(function()
			k:Part({ Name = "EyeWhite", Shape = "Ellipsoid", Size = { 0.32, 0.34, 0.2 }, Pos = { 0.19, 0.56, -0.41 }, Rot = { 0, -12, 0 }, Color = EYE_WHITE })
			k:Part({ Name = "Pupil", Shape = "Ball", Size = { 0.11, 0.11, 0.11 }, Pos = { 0.19, 0.56, -0.5 }, Color = PUPIL })
			k:Part({ Name = "Leg", Shape = "Cylinder", Size = { 0.62, 0.12, 0.12 }, Pos = { 0.22, -0.95, 0 }, Rot = { 0, 0, 90 }, Color = LIMB, Material = "Wood" })
		end)
		-- one dark ellipsoid tipped back into the log: only its lower half shows, so it
		-- reads as a wide D-shaped grin whose corners curl up round the log
		k:Part({ Name = "Grin", Shape = "Ellipsoid", Size = { 0.6, 0.3, 0.12 }, Pos = { 0, 0.33, -0.43 }, Rot = { 55, 0, 0 }, Color = MOUTH })
		segment(k, "Arm", { 0.42, 0.08, 0 }, { 0.68, 0.36, 0 }, 0.1, LIMB)
		-- bat: thin handle in the fist, long fat barrel on top
		local dir = norm({ 0.1, 1, 0 })
		local grip = { 0.68, 0.36, 0 }
		segment(k, "BatHandle", add(grip, dir, -0.06), add(grip, dir, 0.5), 0.09, BAT, "Wood", 0)
		segment(k, "BatBarrel", add(grip, dir, 0.42), add(grip, dir, 0.95), 0.19, BAT, "Wood", 0)
	end,
}
