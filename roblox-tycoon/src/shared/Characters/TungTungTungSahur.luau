--[[
	Tung Tung Tung Sahur (Rare)
	Canonical look: a tall, light-brown anthropomorphic wooden log (worn rounded base, grain
	lines, knots, cracks and a flat sawn top showing growth rings) with a simple, wide-eyed
	face: big round white eyes with tiny pupils, thin dark brows and a wide, unsettling
	grin. Stick-thin darker wooden arms and legs; the right hand holds a wooden baseball bat
	raised beside the head, ready to knock "tung tung tung".

	Coordinates: feet on y = 0, faces -Z. Most parts are written in world coordinates by
	nesting an un-animated "offset" group inside each animated joint group.
]]

-- Palette ------------------------------------------------------------------------------
local WOOD = "#d6a56c" -- dominant: light-brown log
local WOOD_LIGHT = "#e4bd86" -- sanded top edge
local WOOD_SHADE = "#bf8a52" -- worn base, sockets, peg holes
local GRAIN = "#b47c45" -- grain lines
local END_LIGHT = "#efd3a2" -- sawn end grain
local END_DARK = "#c18c56" -- growth rings
local PITH = "#8a5a30"
local KNOT = "#7a4a24"
local KNOT_RING = "#a06a37"
local CRACK = "#4a2c18"

local LIMB = "#a5713e" -- stick-thin darker wooden arms and legs
local LIMB_DARK = "#8a5a2f" -- joints
local BAT = "#94592a"
local BAT_DARK = "#6b3e1d"
local BAT_LIGHT = "#b57b45"
local TAPE = "#3a2a22"

local EYE_WHITE = "#fff8ec"
local PUPIL = "#1b1b24"
local SHINE = "#fffdf6"
local BROW = "#3a2314"
local MOUTH = "#3b1f14"
local TEETH = "#fff1d8"

local GLOW = "#ffbf73" -- Rare flair: warm glow + sawdust
local DUST = "#e9cc9c"

-- Layout (world studs) -------------------------------------------------------------------
local LOG_BOTTOM = 2.3
local LOG_TOP = 8.2
local RADIUS = 1.27 -- log radius
local EYE_Y = 6.92
local MOUTH_Y = 5.88 -- top edge of the grin at the centre
local SHOULDER_Y = 5.25

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

-- Rotation that points a Cylinder's axis (local X) along vector v
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
		onLog(k, {
			Name = "Grain",
			Size = { 0.055, h[2] - h[1] + 0.03, 0.06 },
			Color = color or GRAIN,
		}, theta, (h[1] + h[2]) / 2, 0.0, h[3])
	end
end

local function knot(k, theta, y, s)
	onLog(k, { Name = "Knot", Shape = "Ellipsoid", Size = { 0.52 * s, 0.38 * s, 0.14 }, Color = KNOT_RING }, theta, y, 0.0)
	onLog(k, { Name = "KnotCore", Shape = "Ellipsoid", Size = { 0.34 * s, 0.24 * s, 0.14 }, Color = KNOT }, theta, y, 0.025)
	onLog(k, { Name = "KnotHeart", Shape = "Ellipsoid", Size = { 0.13 * s, 0.1 * s, 0.1 }, Color = CRACK }, theta, y, 0.06)
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
		}, theta + deg(((s + ns) / 2) / R(my)), my, 0.0, tl)
		s, cy = ns, ny
	end
end

local function buildLog(k)
	-- big forms: the trunk, a worn rounded base and a sanded top edge
	k:Part({ Name = "Trunk", Shape = "Cylinder", Size = { LOG_TOP - LOG_BOTTOM, RADIUS * 2, RADIUS * 2 }, Pos = { 0, (LOG_TOP + LOG_BOTTOM) / 2, 0 }, Rot = { 0, 0, 90 }, Color = WOOD, Material = "Wood" })
	k:Part({ Name = "BaseLip", Shape = "Ellipsoid", Size = { RADIUS * 2 + 0.1, 0.32, RADIUS * 2 + 0.1 }, Pos = { 0, LOG_BOTTOM + 0.03, 0 }, Color = WOOD_SHADE, Material = "Wood" })
	k:Part({ Name = "TopLip", Shape = "Ellipsoid", Size = { RADIUS * 2 + 0.02, 0.4, RADIUS * 2 + 0.02 }, Pos = { 0, LOG_TOP, 0 }, Color = WOOD_LIGHT, Material = "Wood" })

	-- sawn top: concentric growth rings (each disc slightly off-centre, like real wood)
	local rings = {
		{ 2.14, END_LIGHT }, { 1.96, END_DARK }, { 1.84, END_LIGHT }, { 1.56, END_DARK },
		{ 1.44, END_LIGHT }, { 1.16, END_DARK }, { 1.04, END_LIGHT }, { 0.78, END_DARK },
		{ 0.66, END_LIGHT }, { 0.4, END_DARK }, { 0.28, END_LIGHT }, { 0.12, PITH },
	}
	for i, r in rings do
		local top = LOG_TOP + 0.21 + (i - 1) * 0.006
		local off = (i - 1) * 0.008
		k:Part({
			Name = "EndGrain",
			Shape = "Cylinder",
			Size = { 0.08, r[1], r[1] },
			Pos = { off, top - 0.04, -off * 0.6 },
			Rot = { 0, 0, 90 },
			Color = r[2],
			Material = "Wood",
		})
	end
	-- radial checking cracks across the end grain
	k:Part({ Name = "TopCrack", Size = { 0.05, 0.06, 0.86 }, Pos = { 0.28, LOG_TOP + 0.22, 0.42 }, Rot = { 0, 34, 0 }, Color = CRACK })
	k:Part({ Name = "TopCrack", Size = { 0.05, 0.06, 0.5 }, Pos = { -0.5, LOG_TOP + 0.22, -0.12 }, Rot = { 0, -78, 0 }, Color = CRACK })

	-- medium: grain lines (front only below the grin, all around elsewhere)
	for _, th in { -30, 26 } do
		grainLine(k, th, LOG_BOTTOM + 0.35, MOUTH_Y - 0.75, 2.5, "#c4915a")
	end
	for _, th in { 62, 84, 108, 132, 156, 180, -62, -84, -108, -132, -156 } do
		grainLine(k, th, LOG_BOTTOM + 0.2, LOG_TOP - 0.2, (th % 48 < 24) and 2 or -2)
	end

	-- knots (between grain lines)
	knot(k, 96, 3.55, 1)
	knot(k, -120, 6.55, 1.1)
	knot(k, 144, 6.95, 0.9)
	knot(k, -168, 3.15, 0.8)
	knot(k, -13, 3.3, 0.65)

	-- cracks
	crack(k, 168, LOG_TOP - 0.1, { 12, -20, 16 }, 0.34)
	crack(k, -72, LOG_TOP - 0.12, { -14, 18, -10 }, 0.28)
	crack(k, 48, LOG_BOTTOM + 0.95, { 18, -16, 14 }, 0.28)

	-- old nail holes / worm holes
	for _, h in { { 118, 5.05 }, { 169, 2.95 }, { -96, 3.7 }, { -146, 7.2 } } do
		onLog(k, { Name = "NailHole", Shape = "Ellipsoid", Size = { 0.09, 0.09, 0.06 }, Color = CRACK }, h[1], h[2], 0.0)
	end

	-- the kentongan slit drum on his back
	onLog(k, { Name = "SlitRim", Size = { 0.38, 1.7, 0.08 }, Color = WOOD_SHADE }, 180, 4.55, 0.0)
	onLog(k, { Name = "Slit", Size = { 0.2, 1.46, 0.08 }, Color = CRACK }, 180, 4.55, 0.025)
	onLog(k, { Name = "SlitEnd", Shape = "Ellipsoid", Size = { 0.26, 0.2, 0.1 }, Color = CRACK }, 180, 5.28, 0.02)
	onLog(k, { Name = "SlitEnd", Shape = "Ellipsoid", Size = { 0.26, 0.2, 0.1 }, Color = CRACK }, 180, 3.82, 0.02)

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

local function buildFace(k)
	k:Mirror(function()
		-- big round eye with a darker carved socket
		surfaceGroup(k, "Eye", thetaAt(0.5, EYE_Y), EYE_Y, 0.0, nil, function()
			k:Part({ Name = "EyeSocket", Shape = "Ellipsoid", Size = { 1.0, 1.06, 0.22 }, Color = WOOD_SHADE, Material = "Wood" })
			k:Part({ Name = "EyeWhite", Shape = "Ellipsoid", Size = { 0.88, 0.94, 0.34 }, Pos = { 0, 0, -0.04 }, Color = EYE_WHITE, Anim = BLINK })
			k:Group({ Name = "Look", Anim = { Type = "Bob", Axis = "X", Amount = 0.05, Speed = 0.25, Phase = 0.1 } }, function()
				k:Part({ Name = "Pupil", Shape = "Ellipsoid", Size = { 0.27, 0.29, 0.14 }, Pos = { -0.02, 0.02, -0.19 }, Color = PUPIL, Anim = BLINK })
				k:Part({ Name = "EyeShine", Shape = "Ball", Size = { 0.09, 0.09, 0.09 }, Pos = { 0.05, 0.1, -0.25 }, Color = SHINE, Material = "Neon", Anim = BLINK })
				k:Part({ Name = "EyeShineSmall", Shape = "Ball", Size = { 0.05, 0.05, 0.05 }, Pos = { -0.09, -0.06, -0.24 }, Color = SHINE, Anim = BLINK })
			end)
		end)
		-- thin arched brow, raised a little high (unsettling)
		surfaceGroup(k, "Brow", thetaAt(0.52, EYE_Y + 0.72), EYE_Y + 0.72, 0.0, { Type = "Bob", Axis = "Y", Amount = 0.035, Speed = 0.45 }, function()
			k:Part({ Name = "BrowInner", Size = { 0.36, 0.12, 0.08 }, Pos = { -0.16, -0.01, -0.02 }, Rot = { 0, 8, 13 }, Color = BROW })
			k:Part({ Name = "BrowOuter", Size = { 0.34, 0.12, 0.08 }, Pos = { 0.17, 0.0, -0.02 }, Rot = { 0, -8, -11 }, Color = BROW })
		end)
	end)

	-- wide grin: a crescent, thick in the middle and thin at the up-turned corners
	local N = 11
	local HALF = 0.78
	for i = 0, N - 1 do
		local u = -1 + (2 * i + 1) / N
		local x = HALF * u
		local yTop = MOUTH_Y + 0.24 * u * u
		local h = 0.07 + 0.15 * (1 - u * u)
		local yc = yTop - h / 2
		local slope = 0.48 * u / HALF
		local segLen = (2 * HALF / N) * math.sqrt(1 + slope * slope) + 0.03
		onLog(k, { Name = "Grin", Size = { segLen, h, 0.08 }, Color = MOUTH }, thetaAt(x, yc), yc, 0.0, deg(math.atan(slope)))
		if math.abs(u) < 0.6 then
			onLog(k, { Name = "Tooth", Size = { segLen * 0.72, 0.065, 0.06 }, Color = TEETH }, thetaAt(x, yTop - 0.05), yTop - 0.05, 0.02, deg(math.atan(slope)))
		end
	end
	k:Mirror(function()
		local cx = HALF + 0.08
		onLog(k, { Name = "SmileCrease", Size = { 0.05, 0.17, 0.06 }, Color = MOUTH }, thetaAt(cx, MOUTH_Y + 0.27), MOUTH_Y + 0.27, 0.0, -28)
	end)
end

--------------------------------------------------------------------------------------------
-- Arms
--------------------------------------------------------------------------------------------
local S_R = { 1.2, SHOULDER_Y, 0 }
local E_R = { 1.98, 4.87, 0.06 }
local H_R = { 2.2, 6.1, -0.06 }
local BAT_DIR = norm({ 0.14, 1, 0.2 })

local S_L = { -1.2, SHOULDER_Y, 0 }
local E_L = { -1.72, 4.37, -0.06 }
local H_L = { -1.9, 3.53, -0.12 }

local function batPoint(t)
	return add(H_R, BAT_DIR, t)
end

local function buildBat(k)
	-- two axes perpendicular to the bat, for grain lines and scuffs
	local u = norm(cross(BAT_DIR, { 0, 0, 1 }))
	local w = norm(cross(BAT_DIR, u))

	segment(k, "BatKnob", batPoint(-0.68), batPoint(-0.56), 0.28, BAT_DARK, "Wood", 0)
	k:Part({ Name = "KnobCap", Shape = "Ellipsoid", Size = { 0.1, 0.22, 0.22 }, Pos = batPoint(-0.69), Rot = axisRot(BAT_DIR), Color = BAT, Material = "Wood" })
	segment(k, "GripTape", batPoint(-0.58), batPoint(0.34), 0.165, TAPE, "Fabric", 0)
	for _, t in { -0.47, -0.34, 0.27 } do
		segment(k, "TapeWrap", batPoint(t - 0.03), batPoint(t + 0.03), 0.185, TAPE, "Fabric", 0)
	end
	segment(k, "Handle", batPoint(0.3), batPoint(1.0), 0.15, BAT, "Wood", 0)
	for i = 1, 5 do
		local t0 = 0.95 + (i - 1) * 0.28
		segment(k, "BatTaper", batPoint(t0), batPoint(t0 + 0.32), 0.15 + i * 0.045, BAT, "Wood", 0)
	end
	segment(k, "Barrel", batPoint(2.3), batPoint(3.05), 0.42, BAT, "Wood", 0)
	k:Part({ Name = "BatTip", Shape = "Ellipsoid", Size = { 0.22, 0.42, 0.42 }, Pos = batPoint(3.05), Rot = axisRot(BAT_DIR), Color = BAT, Material = "Wood" })
	segment(k, "BatEndGrain", batPoint(3.105), batPoint(3.165), 0.27, BAT_LIGHT, "Wood", 0)

	-- grain lines along the barrel
	for i = 0, 2 do
		local a = math.rad(30 + i * 120)
		local off = add({ u[1] * math.cos(a), u[2] * math.cos(a), u[3] * math.cos(a) }, w, math.sin(a))
		segment(k, "BatGrain", add(batPoint(2.15), off, 0.17), add(batPoint(3.0), off, 0.2), 0.05, BAT_DARK, "Wood", 0)
	end
	-- worn spots on the hitting face
	for _, s in { { 2.55, 200 }, { 2.85, 240 } } do
		local a = math.rad(s[2])
		local off = add({ u[1] * math.cos(a), u[2] * math.cos(a), u[3] * math.cos(a) }, w, math.sin(a))
		k:Part({ Name = "BatScuff", Shape = "Ball", Size = { 0.13, 0.13, 0.13 }, Pos = add(batPoint(s[1]), off, 0.18), Color = BAT_LIGHT, Material = "Wood" })
	end

	-- sawdust shaken off with every knock
	k:Particles({ Pos = batPoint(2.9), Color = "#d9a86a", Color2 = "#f3dcae", Rate = 3, Size = 0.1, Speed = 0.8, Lifetime = 1.2, Spread = 70, Direction = "Top" })
end

local function buildBatArm(k)
	k:Group({ Name = "BatArm", Pos = S_R, Anim = { Type = "Wiggle", Axis = "X", Amount = 16, Speed = 0.9 } }, function()
		k:Group({ Name = "BatArmOffset", Pos = { -S_R[1], -S_R[2], -S_R[3] } }, function()
			segment(k, "UpperArm", S_R, E_R, 0.2, LIMB)
			k:Part({ Name = "Elbow", Shape = "Ball", Size = { 0.27, 0.27, 0.27 }, Pos = E_R, Color = LIMB_DARK, Material = "Wood" })
			segment(k, "Forearm", E_R, H_R, 0.19, LIMB)
			-- wrist snap lags the shoulder a little for a punchy knock
			k:Group({ Name = "Wrist", Pos = H_R, Anim = { Type = "Wiggle", Axis = "X", Amount = 9, Speed = 0.9, Phase = 0.1 } }, function()
				k:Group({ Name = "WristOffset", Pos = { -H_R[1], -H_R[2], -H_R[3] } }, function()
					-- fist wrapped around the handle
					local f = norm({ 0.3, -0.05, -1 })
					local q = cross(BAT_DIR, f)
					f = norm(cross(q, BAT_DIR))
					k:Part({ Name = "Fist", Shape = "Ellipsoid", Size = { 0.38, 0.42, 0.38 }, Pos = H_R, Rot = axisRot(BAT_DIR), Color = LIMB, Material = "Wood" })
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
			segment(k, "UpperArm", S_L, E_L, 0.2, LIMB)
			k:Part({ Name = "Elbow", Shape = "Ball", Size = { 0.27, 0.27, 0.27 }, Pos = E_L, Color = LIMB_DARK, Material = "Wood" })
			segment(k, "Forearm", E_L, H_L, 0.19, LIMB)
			k:Group({ Name = "Hand", Pos = H_L, Anim = { Type = "Wiggle", Axis = "Z", Amount = 8, Speed = 0.45, Phase = 0.4 } }, function()
				k:Group({ Name = "HandOffset", Pos = { -H_L[1], -H_L[2], -H_L[3] } }, function()
					local hx, hy, hz = H_L[1], H_L[2], H_L[3]
					k:Part({ Name = "Wrist", Shape = "Ball", Size = { 0.21, 0.21, 0.21 }, Pos = H_L, Color = LIMB_DARK, Material = "Wood" })
					k:Part({ Name = "Palm", Shape = "Ellipsoid", Size = { 0.17, 0.36, 0.3 }, Pos = { hx - 0.02, hy - 0.18, hz }, Color = LIMB, Material = "Wood" })
					for _, dz in { -0.09, 0, 0.09 } do
						segment(k, "Finger", { hx - 0.02, hy - 0.3, hz + dz }, { hx - 0.01, hy - 0.5, hz + dz - 0.06 }, 0.075, LIMB)
					end
					segment(k, "Thumb", { hx - 0.01, hy - 0.14, hz - 0.12 }, { hx + 0.02, hy - 0.3, hz - 0.24 }, 0.08, LIMB)
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
	local knee = { sx * 0.6, 1.22, -0.04 }
	local ankle = { sx * 0.6, 0.3, 0.02 }
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
			k:Part({ Name = "Ankle", Shape = "Ball", Size = { 0.24, 0.24, 0.24 }, Pos = ankle, Color = LIMB_DARK, Material = "Wood" })
			k:Part({ Name = "FootSole", Shape = "Ellipsoid", Size = { 0.48, 0.3, 0.86 }, Pos = { sx * 0.6, 0.15, -0.12 }, Color = LIMB, Material = "Wood" })
			for _, dx in { -0.13, 0, 0.13 } do
				k:Part({ Name = "Toe", Shape = "Ball", Size = { 0.14, 0.14, 0.14 }, Pos = { sx * 0.6 + dx, 0.07, -0.5 + math.abs(dx) * 0.3 }, Color = LIMB, Material = "Wood" })
			end
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

		-- Rare flair: warm glow and drifting wood dust
		k:Light({ Pos = { 0, 6.2, -2.0 }, Color = GLOW, Range = 10, Brightness = 0.9 })
		k:Particles({ Pos = { 0, 0.3, 0 }, Color = DUST, Color2 = "#fff1d6", Rate = 4, Size = 0.16, Speed = 0.5, Lifetime = 2.2, Spread = 180, Direction = "Top" })
	end,

	BuildMini = function(k)
		k:Part({ Name = "Log", Shape = "Cylinder", Size = { 1.7, 0.98, 0.98 }, Pos = { 0, 0.12, 0 }, Rot = { 0, 0, 90 }, Color = WOOD, Material = "Wood" })
		k:Mirror(function()
			k:Part({ Name = "EyeWhite", Shape = "Ball", Size = { 0.32, 0.32, 0.32 }, Pos = { 0.19, 0.55, -0.39 }, Color = EYE_WHITE })
			k:Part({ Name = "Pupil", Shape = "Ball", Size = { 0.12, 0.12, 0.12 }, Pos = { 0.19, 0.55, -0.52 }, Color = PUPIL })
			k:Part({ Name = "Leg", Shape = "Cylinder", Size = { 0.56, 0.12, 0.12 }, Pos = { 0.22, -0.98, 0 }, Rot = { 0, 0, 90 }, Color = LIMB, Material = "Wood" })
			-- grin: two slivers meeting low in the middle, corners turned up
			k:Part({ Name = "Grin", Size = { 0.3, 0.08, 0.08 }, Pos = { 0.13, 0.26, -0.475 }, Rot = { 0, -15, 20 }, Color = MOUTH })
		end)
		segment(k, "Arm", { 0.45, 0.1, 0 }, { 0.74, 0.42, 0 }, 0.1, LIMB)
		segment(k, "BatHandle", { 0.74, 0.3, 0 }, { 0.82, 0.88, 0 }, 0.12, BAT, "Wood", 0)
		segment(k, "BatBarrel", { 0.82, 0.85, 0 }, { 0.88, 1.2, 0 }, 0.22, BAT, "Wood", 0)
	end,
}
