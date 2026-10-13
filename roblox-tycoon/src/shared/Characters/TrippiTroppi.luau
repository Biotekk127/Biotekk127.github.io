--[[
	Trippi Troppi (Uncommon)
	Canonical look: a cute/cursed orange tabby CAT head (pointed ears with pink insides,
	tabby "M" stripes, huge eyes, whiskers, little pink nose, open mouth) fused onto the
	pink-orange body of a cooked SHRIMP: a red-backed, pale-bellied shell of overlapping
	plates curling into a C, a spread fan tail tucked underneath, little swimmerets and
	thin jointed walking legs underneath, and two long whip antennae sweeping back.

	Pose: the shrimp body is shown in profile (head end at +X, curled tail at -X) while the
	cat face looks straight at the viewer (-Z), exactly like the meme picture, so the front
	view shows the whole shrimp silhouette AND the cat face.

	Coordinates: feet on y = 0, face toward -Z. Animated joints use a pivot group with an
	un-animated offset group inside, so most parts are written in world coordinates.
]]

-- Palette ------------------------------------------------------------------------------
-- cat
local FUR = "#f39d3c" -- dominant ginger fur
local FUR_LIGHT = "#f9bc6a"
local FUR_DARK = "#c1621d" -- tabby stripes
local CREAM = "#fff0db" -- muzzle, chin, ear tufts
local EAR_PINK = "#f4a0ab"
local NOSE = "#e5707f"
local MOUTH = "#5a1d2b"
local TONGUE = "#f07a8c"
local TOOTH = "#fff8ec"
local EYE_WHITE = "#fff8ec"
local IRIS = "#8fcd3e"
local IRIS_DARK = "#5f9a24"
local PUPIL = "#1b1b24"
local SHINE = "#fff8ec"
local LINER = "#3b2318"
local WHISKER = "#fff6e6"
-- shrimp (cooked: red-orange back, pale belly, white seams)
local SHELL = "#f5765c" -- cooked shrimp coral
local SHELL_LIGHT = "#ffa98a"
local SHELL_DARK = "#d6493a" -- dorsal stripe
local SHELL_PALE = "#ffd8c4" -- pale belly plates / seams
local SHELL_RED = "#bf3a2e" -- tail tips
local LEG = "#f8906f"
local LEG_PALE = "#ffc4aa"
local ANTENNA = "#e0533f"
local ANTENNA_DARK = "#c94433"

-- Layout (world studs) -------------------------------------------------------------------
local HC = { 1.4, 3.15, -0.4 } -- head centre
local NECK = { 1.3, 2.15, -0.2 } -- head tilt pivot
local CARA = { 0.45, 1.95, 0.05 } -- carapace (shrimp head-shell) centre
local AC = { -1.0, 1.82 } -- abdomen curl centre (x, y) in the profile plane

-- Head volumes in HEAD-LOCAL space {cx, cy, cz, semiX, semiY, semiZ}
local SKULL = { 0, 0, 0, 1.42, 1.22, 1.18 }
local CHEEK_R = { 0.74, -0.42, -0.28, 0.84, 0.76, 0.88 }
local CHEEK_L = { -0.74, -0.42, -0.28, 0.84, 0.76, 0.88 }
local HEAD_VOLS = { SKULL, CHEEK_R, CHEEK_L }

-- Math helpers ---------------------------------------------------------------------------
local function deg(r)
	return r * 180 / math.pi
end

local function norm(v)
	local l = math.sqrt(v[1] * v[1] + v[2] * v[2] + v[3] * v[3])
	return { v[1] / l, v[2] / l, v[3] / l }
end

local function cross(a, b)
	return { a[2] * b[3] - a[3] * b[2], a[3] * b[1] - a[1] * b[3], a[1] * b[2] - a[2] * b[1] }
end

-- Distance along a ray (origin p, unit dir d) to where it leaves ellipsoid e (-1 = miss)
local function exitT(e, px, py, pz, dx, dy, dz)
	local ox, oy, oz = (px - e[1]) / e[4], (py - e[2]) / e[5], (pz - e[3]) / e[6]
	local vx, vy, vz = dx / e[4], dy / e[5], dz / e[6]
	local A = vx * vx + vy * vy + vz * vz
	local B = 2 * (ox * vx + oy * vy + oz * vz)
	local C = ox * ox + oy * oy + oz * oz - 1
	local disc = B * B - 4 * A * C
	if disc < 0 then
		return -1
	end
	return (-B + math.sqrt(disc)) / (2 * A)
end

-- Point on a union of ellipsoids seen from (o) along (d), pushed `out` along the normal.
local function surfaceOf(vols, o, dx, dy, dz, out)
	local d = norm({ dx, dy, dz })
	local best, bestT = vols[1], -1
	for _, e in vols do
		local t = exitT(e, o[1], o[2], o[3], d[1], d[2], d[3])
		if t > bestT then
			best, bestT = e, t
		end
	end
	local x, y, z = o[1] + d[1] * bestT, o[2] + d[2] * bestT, o[3] + d[3] * bestT
	local n = norm({
		(x - best[1]) / (best[4] * best[4]),
		(y - best[2]) / (best[5] * best[5]),
		(z - best[3]) / (best[6] * best[6]),
	})
	return { x + n[1] * out, y + n[2] * out, z + n[3] * out }, n
end

local function headSurface(dx, dy, dz, out)
	return surfaceOf(HEAD_VOLS, { 0, 0, 0 }, dx, dy, dz, out)
end

-- Rotation whose local -Z axis points along unit normal n (flat features on a surface),
-- with an optional in-plane roll.
local function faceRot(n, roll)
	return { deg(math.atan2(n[2], -n[3])), deg(math.asin(-n[1])), roll or 0 }
end

-- Rotation that points a Cylinder's axis (local X) along vector v
local function axisRot(vx, vy, vz)
	local l = math.sqrt(vx * vx + vy * vy + vz * vz)
	vx, vy, vz = vx / l, vy / l, vz / l
	return { 0, deg(math.atan2(-vz, vx)), deg(math.asin(vy)) }
end

-- Cylinder segment between two points
local function segment(k, name, a, b, diameter, color, material)
	local vx, vy, vz = b[1] - a[1], b[2] - a[2], b[3] - a[3]
	local len = math.sqrt(vx * vx + vy * vy + vz * vz)
	k:Part({
		Name = name,
		Shape = "Cylinder",
		Size = { len + diameter * 0.6, diameter, diameter },
		Pos = { (a[1] + b[1]) / 2, (a[2] + b[2]) / 2, (a[3] + b[3]) / 2 },
		Rot = axisRot(vx, vy, vz),
		Color = color,
		Material = material or "SmoothPlastic",
	})
end

-- Tapered limb piece between two points: an ellipsoid stretched along the bone
local function spindle(k, name, a, b, diameter, color)
	local vx, vy, vz = b[1] - a[1], b[2] - a[2], b[3] - a[3]
	local len = math.sqrt(vx * vx + vy * vy + vz * vz)
	k:Part({
		Name = name,
		Shape = "Ellipsoid",
		Size = { len + diameter * 0.5, diameter, diameter },
		Pos = { (a[1] + b[1]) / 2, (a[2] + b[2]) / 2, (a[3] + b[3]) / 2 },
		Rot = axisRot(vx, vy, vz),
		Color = color,
	})
end

-- Animated joint: rotates/bobs around `pivot` while the contents stay in world coordinates
local function joint(k, name, pivot, anim, fn)
	k:Group({ Name = name, Pos = pivot, Anim = anim }, function()
		k:Group({ Name = name .. "Offset", Pos = { -pivot[1], -pivot[2], -pivot[3] } }, fn)
	end)
end

-- Front-facing isosceles triangle (two wedges), apex up; pos = centre of its bounding box
local function triangle(k, name, w, h, thick, color, pos, material)
	k:Part({ Name = name, Shape = "Wedge", Size = { thick, h, w / 2 }, Pos = { pos[1] - w / 4, pos[2], pos[3] }, Rot = { 0, 90, 0 }, Color = color, Material = material })
	k:Part({ Name = name, Shape = "Wedge", Size = { thick, h, w / 2 }, Pos = { pos[1] + w / 4, pos[2], pos[3] }, Rot = { 0, -90, 0 }, Color = color, Material = material })
end

-- Abdomen curl: a gentle spiral (radius shrinks toward the tail so it tucks under the body).
-- th = degrees from straight up, sweeping toward -X and then under.
local function curlRadius(th)
	return 1.22 - (th + 12) * 0.0023
end

local function arcPoint(th)
	local a = math.rad(th)
	local r = curlRadius(th)
	return AC[1] - r * math.sin(a), AC[2] + r * math.cos(a)
end

--------------------------------------------------------------------------------------------
-- Cat head (HEAD-LOCAL coordinates, origin = head centre)
--------------------------------------------------------------------------------------------
local BLINK = { Type = "Blink", Speed = 0.22, Phase = 0.15 }

local function buildEye(k)
	local p, n0 = headSurface(0.5, 0.2, -1, 0)
	-- bias toward facing the viewer so the big eyes read from the front
	local n = norm({ n0[1] * 0.55, n0[2] * 0.55, n0[3] * 0.55 - 0.45 })
	local u = norm({ -n[1] * n[2], 1 - n[2] * n[2], -n[3] * n[2] })
	local r = cross(n, u)
	local function at(dx, dy, out)
		return {
			p[1] + r[1] * dx + u[1] * dy + n[1] * out,
			p[2] + r[2] * dx + u[2] * dy + n[2] * out,
			p[3] + r[3] * dx + u[3] * dy + n[3] * out,
		}
	end
	local rot = faceRot(n, 0)
	k:Part({ Name = "EyeLiner", Shape = "Ellipsoid", Size = { 1.04, 1.1, 0.3 }, Pos = at(0, 0.02, -0.1), Rot = rot, Color = LINER })
	k:Part({ Name = "EyeLid", Shape = "Ellipsoid", Size = { 0.9, 0.98, 0.28 }, Pos = at(0, 0, -0.08), Rot = rot, Color = FUR })
	k:Part({ Name = "EyeWhite", Shape = "Ellipsoid", Size = { 0.94, 1.02, 0.34 }, Pos = at(0, 0, -0.05), Rot = rot, Color = EYE_WHITE, Anim = BLINK })
	k:Part({ Name = "IrisRing", Shape = "Ellipsoid", Size = { 0.8, 0.88, 0.3 }, Pos = at(-0.03, -0.02, -0.015), Rot = rot, Color = IRIS_DARK, Anim = BLINK })
	k:Part({ Name = "Iris", Shape = "Ellipsoid", Size = { 0.7, 0.78, 0.3 }, Pos = at(-0.03, -0.04, 0.0), Rot = rot, Color = IRIS, Anim = BLINK })
	k:Part({ Name = "Pupil", Shape = "Ellipsoid", Size = { 0.4, 0.64, 0.28 }, Pos = at(-0.04, -0.02, 0.035), Rot = rot, Color = PUPIL, Anim = BLINK })
	k:Part({ Name = "EyeShine", Shape = "Ball", Size = { 0.22, 0.22, 0.22 }, Pos = at(0.13, 0.2, 0.08), Color = SHINE, Material = "Neon", Anim = BLINK })
	k:Part({ Name = "EyeShineSmall", Shape = "Ball", Size = { 0.1, 0.1, 0.1 }, Pos = at(-0.16, -0.2, 0.08), Color = SHINE, Material = "Neon", Anim = BLINK })
	-- worried tabby brow: a dark fur arch whose inner end rides higher (the "cursed" stare)
	k:Part({ Name = "Brow", Shape = "Ellipsoid", Size = { 0.62, 0.13, 0.16 }, Pos = at(-0.04, 0.66, -0.02), Rot = faceRot(n, -16), Color = FUR_DARK })
end

local function buildEar(k, side, phase)
	local p = headSurface(0.6 * side, 1, -0.12, -0.18)
	k:Group({
		Name = if side > 0 then "RightEar" else "LeftEar",
		Pos = p,
		Rot = { 10, -14 * side, -16 * side },
		Anim = { Type = "Wiggle", Axis = "Z", Amount = 9, Speed = 0.5, Phase = phase },
	}, function()
		-- thick root blends the flat ear into the round skull
		k:Part({ Name = "EarRoot", Shape = "Ellipsoid", Size = { 1.05, 0.5, 0.5 }, Pos = { 0, 0.12, 0.04 }, Color = FUR })
		triangle(k, "Ear", 1.1, 1.35, 0.3, FUR, { 0, 0.675, 0 })
		triangle(k, "EarInner", 0.7, 0.95, 0.1, EAR_PINK, { 0, 0.52, -0.15 })
		-- cream fur tufts curling out of the ear
		k:Part({ Name = "EarTuft", Shape = "Wedge", Size = { 0.08, 0.55, 0.22 }, Pos = { 0.05 * side, 0.34, -0.21 }, Rot = { 0, 90, 0 }, Color = CREAM })
	end)
end

-- flat stripe on the head surface
local function stripe(k, dir, size, roll, color)
	local p, n = headSurface(dir[1], dir[2], dir[3], -size[3] * 0.25)
	k:Part({ Name = "Stripe", Shape = "Ellipsoid", Size = size, Pos = p, Rot = faceRot(n, roll), Color = color or FUR_DARK })
end

local function buildHead(k)
	-- big forms
	k:Part({ Name = "Skull", Shape = "Ellipsoid", Size = { SKULL[4] * 2, SKULL[5] * 2, SKULL[6] * 2 }, Color = FUR })
	k:Mirror(function()
		k:Part({ Name = "Cheek", Shape = "Ellipsoid", Size = { CHEEK_R[4] * 2, CHEEK_R[5] * 2, CHEEK_R[6] * 2 }, Pos = { CHEEK_R[1], CHEEK_R[2], CHEEK_R[3] }, Color = FUR })
		-- fluffy jowl tufts that break the round cheek outline
		k:Part({ Name = "JowlFluff", Shape = "Ellipsoid", Size = { 0.66, 0.26, 0.56 }, Pos = { 1.5, -0.56, -0.24 }, Rot = { 0, 0, -24 }, Color = FUR })
		k:Part({ Name = "JowlFluff", Shape = "Ellipsoid", Size = { 0.56, 0.24, 0.5 }, Pos = { 1.36, -0.86, -0.3 }, Rot = { 0, 0, -46 }, Color = FUR })

		-- eyes and brows
		buildEye(k)

		-- puffy whisker pads (axis aligned so dots can be placed on them)
		local pp = headSurface(0.28, -0.44, -1, -0.15)
		local muzzle = { pp[1], pp[2], pp[3], 0.4, 0.3, 0.27 }
		k:Part({ Name = "MuzzlePad", Shape = "Ellipsoid", Size = { 0.8, 0.6, 0.54 }, Pos = pp, Color = CREAM })
		for _, d in { { 0.2, 0.3 }, { 0.48, 0.05 }, { 0.3, -0.2 } } do
			local dp = surfaceOf({ muzzle }, { muzzle[1], muzzle[2], muzzle[3] }, d[1], d[2], -1, -0.02)
			k:Part({ Name = "WhiskerDot", Shape = "Ball", Size = { 0.08, 0.08, 0.08 }, Pos = dp, Color = FUR_DARK })
		end

		-- fangs hanging from the upper lip
		local fp = headSurface(0.15, -0.66, -1, 0.0)
		k:Part({ Name = "Fang", Shape = "Wedge", Size = { 0.08, 0.2, 0.12 }, Pos = fp, Rot = { 0, 90, 180 }, Color = TOOTH })

		-- whiskers twitch around their root on the pad
		local wr = headSurface(0.5, -0.4, -1, -0.05)
		k:Group({ Name = "Whiskers", Pos = wr, Anim = { Type = "Wiggle", Axis = "Y", Amount = 6, Speed = 1.1, Phase = 0.3 } }, function()
			for _, w in { { 1.05, 0.24, -0.45 }, { 1.12, 0.02, -0.4 }, { 1.03, -0.2, -0.32 } } do
				segment(k, "Whisker", { 0, 0, 0 }, w, 0.05, WHISKER)
			end
		end)

		-- tabby stripes: forehead "M", temples, cheeks, back of the head
		stripe(k, { 0.2, 0.72, -0.72 }, { 0.11, 0.46, 0.16 }, -12)
		stripe(k, { 0.44, 0.62, -0.7 }, { 0.1, 0.38, 0.16 }, -26)
		stripe(k, { 1, 0.35, -0.3 }, { 0.42, 0.11, 0.16 }, 20)
		stripe(k, { 1, -0.08, -0.5 }, { 0.52, 0.1, 0.16 }, 8)
		stripe(k, { 1, -0.34, -0.42 }, { 0.46, 0.1, 0.16 }, -6)
		stripe(k, { 0.42, 0.55, 0.8 }, { 0.16, 0.7, 0.18 }, -14)
		stripe(k, { 0.85, 0.15, 0.6 }, { 0.14, 0.62, 0.18 }, -30)
	end)
	stripe(k, { 0, 0.78, -0.7 }, { 0.13, 0.55, 0.16 }, 0)
	stripe(k, { 0, 0.6, 0.82 }, { 0.18, 0.8, 0.18 }, 0)
	stripe(k, { 0, 1, 0.15 }, { 0.15, 0.7, 0.16 }, 0)

	-- nose, philtrum, open mouth, tongue, chin
	local np, nn = headSurface(0, -0.2, -1, 0.1)
	k:Part({ Name = "Nose", Shape = "Ellipsoid", Size = { 0.38, 0.23, 0.24 }, Pos = np, Rot = faceRot(nn, 0), Color = NOSE })
	local nh = headSurface(0.05, -0.12, -1, 0.2)
	k:Part({ Name = "NoseShine", Shape = "Ellipsoid", Size = { 0.12, 0.05, 0.06 }, Pos = nh, Rot = faceRot(nn, 0), Color = "#ffc2cb" })
	local php = headSurface(0, -0.38, -1, 0.05)
	k:Part({ Name = "Philtrum", Size = { 0.05, 0.2, 0.06 }, Pos = php, Color = LINER })
	local mp, mn = headSurface(0, -0.7, -1, -0.12)
	k:Part({ Name = "Mouth", Shape = "Ellipsoid", Size = { 0.74, 0.5, 0.36 }, Pos = mp, Rot = faceRot(mn, 0), Color = MOUTH })
	local tp = headSurface(0, -0.8, -1, -0.07)
	k:Part({ Name = "Tongue", Shape = "Ellipsoid", Size = { 0.48, 0.22, 0.3 }, Pos = tp, Rot = faceRot(mn, 0), Color = TONGUE })
	local cp, cn = headSurface(0, -1, -0.75, -0.2)
	k:Part({ Name = "Chin", Shape = "Ellipsoid", Size = { 0.85, 0.5, 0.6 }, Pos = cp, Rot = faceRot(cn, 0), Color = CREAM })

	-- ears flick one at a time
	buildEar(k, 1, 0)
	buildEar(k, -1, 0.45)
end

-- Long whip antenna: a chain of nested groups so the wave travels down to the tip.
-- pts are a smooth curve; the whip tapers from the shell socket to a fine tip.
local function bezier(p0, p1, p2, p3, n)
	local out = {}
	for i = 0, n do
		local t = i / n
		local a, b, c, d = (1 - t) ^ 3, 3 * (1 - t) ^ 2 * t, 3 * (1 - t) * t * t, t ^ 3
		out[i + 1] = {
			a * p0[1] + b * p1[1] + c * p2[1] + d * p3[1],
			a * p0[2] + b * p1[2] + c * p2[2] + d * p3[2],
			a * p0[3] + b * p1[3] + c * p2[3] + d * p3[3],
		}
	end
	return out
end

local function buildAntenna(k, name, pts, phase)
	k:Part({ Name = "AntennaSocket", Shape = "Ellipsoid", Size = { 0.34, 0.24, 0.34 }, Pos = pts[1], Color = SHELL_DARK })
	local n = #pts - 1
	local function link(i)
		local a, b = pts[i], pts[i + 1]
		local d = 0.14 - (i - 1) * (0.085 / math.max(1, n - 1))
		k:Group({
			Name = name .. i,
			Pos = if i == 1 then a else { a[1] - pts[i - 1][1], a[2] - pts[i - 1][2], a[3] - pts[i - 1][3] },
			Anim = { Type = "Wiggle", Axis = if i % 2 == 0 then "Z" else "X", Amount = 3, Speed = 0.55, Phase = phase + i * 0.07 },
		}, function()
			segment(k, "Antenna", { 0, 0, 0 }, { b[1] - a[1], b[2] - a[2], b[3] - a[3] }, d, if i <= 2 then ANTENNA_DARK else ANTENNA)
			if i < n then
				link(i + 1)
			end
		end)
	end
	link(1)
end

--------------------------------------------------------------------------------------------
-- Shrimp body (world coordinates)
--------------------------------------------------------------------------------------------
local function buildThorax(k)
	k:Group({ Name = "Carapace", Pos = CARA }, function()
		-- laterally compressed like a real shrimp's head-shell
		k:Part({ Name = "Carapace", Shape = "Ellipsoid", Size = { 2.5, 1.7, 1.6 }, Color = SHELL, Reflectance = 0.06 })
		k:Part({ Name = "DorsalRidge", Shape = "Ellipsoid", Size = { 2.1, 0.24, 0.3 }, Pos = { -0.1, 0.8, 0 }, Color = SHELL_DARK })
		k:Part({ Name = "ShellGloss", Shape = "Ellipsoid", Size = { 1.3, 0.16, 0.5 }, Pos = { -0.25, 0.74, -0.18 }, Color = SHELL_LIGHT })
		-- serrated rostrum crest along the back
		for i, x in { 0.05, -0.35, -0.75 } do
			k:Part({ Name = "Spine", Shape = "Wedge", Size = { 0.12, 0.3 - i * 0.03, 0.3 }, Pos = { x, 0.98 - i * 0.02, 0 }, Rot = { 0, 90, 0 }, Color = SHELL_DARK })
		end
		-- lighter gill-chamber plates low on each side
		for side = -1, 1, 2 do
			k:Part({ Name = "GillPlate", Shape = "Ellipsoid", Size = { 1.9, 0.8, 0.2 }, Pos = { -0.05, -0.32, side * 0.68 }, Color = SHELL_LIGHT })
		end
		k:Part({ Name = "Sternum", Shape = "Ellipsoid", Size = { 1.9, 0.36, 0.9 }, Pos = { 0, -0.68, 0 }, Color = SHELL_PALE })
	end)
end

-- Shrimp abdomen: laterally compressed (taller than wide), long overlapping shell plates
local SEGMENTS = {
	{ th = -12, w = 1.48, h = 1.62, l = 1.2, swim = true },
	{ th = 17, w = 1.42, h = 1.54, l = 1.18, swim = true },
	{ th = 46, w = 1.34, h = 1.44, l = 1.14, swim = true },
	{ th = 75, w = 1.22, h = 1.3, l = 1.08 },
	{ th = 100, w = 1.08, h = 1.14, l = 1.02 },
	{ th = 123, w = 0.92, h = 0.98, l = 0.96 },
}
local FAN_TH = 142

local function buildSegment(k, i)
	local s = SEGMENTS[i]
	local cx, cy = arcPoint(s.th)
	-- local frame: +X = toward the head, +Y = back (dorsal), Z = sideways
	k:Group({ Name = "Segment" .. i, Pos = { cx, cy, 0 }, Rot = { 0, 0, s.th } }, function()
		k:Part({ Name = "Shell", Shape = "Ellipsoid", Size = { s.l, s.h, s.w }, Color = SHELL, Reflectance = 0.06 })
		-- pale seam: the raised rear rim of each plate where it overlaps the next one
		k:Part({ Name = "Seam", Shape = "Ellipsoid", Size = { 0.15, s.h * 0.86, s.w * 0.86 }, Pos = { -s.l / 2 + 0.26, 0.0, 0 }, Color = SHELL_PALE })
		-- the cooked-red stripe down the middle of the back
		k:Part({ Name = "BackStripe", Shape = "Ellipsoid", Size = { s.l * 0.74, 0.2, s.w * 0.4 }, Pos = { 0.02, s.h / 2 - 0.1, 0 }, Color = SHELL_DARK })
		for side = -1, 1, 2 do
			-- pale pleuron flaps on the belly side
			k:Part({ Name = "Pleuron", Shape = "Ellipsoid", Size = { s.l * 0.8, s.h * 0.44, 0.14 }, Pos = { 0.02, -s.h * 0.27, side * (s.w * 0.4 + (7 - i) * 0.01) }, Color = SHELL_LIGHT })
			if s.swim then
				-- thin paddling swimmerets under the abdomen
				k:Group({ Name = "Swimmeret", Pos = { 0.05, -s.h / 2 + 0.12, side * 0.26 }, Rot = { side * 12, 0, -14 }, Anim = { Type = "Wiggle", Axis = "Z", Amount = 14, Speed = 1.0, Phase = i * 0.17 + (side + 1) * 0.1 } }, function()
					k:Part({ Name = "Paddle", Shape = "Ellipsoid", Size = { 0.14, 0.56, 0.08 }, Pos = { 0, -0.24, 0 }, Color = LEG_PALE })
				end)
			end
		end
	end)
end

local function buildTailFan(k)
	local px, py = arcPoint(FAN_TH)
	-- local frame: -X = toward the tail tip. The fan flares out of the bottom of the curl,
	-- pointing down and forward, its blades spread in the profile plane so it reads from
	-- the front and splayed a little sideways so it has depth from above.
	k:Group({ Name = "Fan", Pos = { px, py, 0 }, Rot = { 0, 0, FAN_TH + 16 } }, function()
		k:Part({ Name = "FanBase", Shape = "Ellipsoid", Size = { 0.5, 0.6, 0.62 }, Pos = { -0.06, 0, 0 }, Color = SHELL })
		k:Part({ Name = "FanSeam", Shape = "Ellipsoid", Size = { 0.12, 0.52, 0.56 }, Pos = { -0.22, 0, 0 }, Color = SHELL_PALE })
		-- pointed central telson
		k:Part({ Name = "Telson", Shape = "Ellipsoid", Size = { 0.98, 0.24, 0.2 }, Pos = { -0.5, 0.05, -0.02 }, Rot = { 0, 0, 12 }, Color = SHELL_DARK })
		-- two pairs of paddle uropods radiating from the base
		for _, u in { { 52, 10, SHELL_LIGHT }, { 28, 5, SHELL }, { -2, -5, SHELL_LIGHT }, { -24, -10, SHELL } } do
			k:Group({ Name = "Uropod", Pos = { -0.18, 0, 0 }, Rot = { 0, u[2], u[1] } }, function()
				k:Part({ Name = "Blade", Shape = "Ellipsoid", Size = { 0.96, 0.4, 0.1 }, Pos = { -0.44, 0, 0 }, Color = u[3] })
				k:Part({ Name = "BladeTip", Shape = "Ellipsoid", Size = { 0.3, 0.36, 0.12 }, Pos = { -0.84, 0, 0 }, Color = SHELL_RED })
			end)
		end
	end)
end

-- Jointed walking leg: a thigh rises out to a raised knee, the shin drops toward the
-- ground and a pale pointed tip touches down. Legs fan forward (front pairs) and back.
local function buildLeg(k, x, side, reach, phase)
	local hip = { x, 1.22, 0.36 * side }
	local knee = { x + reach * 0.25, 1.46, 0.98 * side }
	local ankle = { x + reach * 0.72, 0.42, 1.2 * side }
	local foot = { x + reach, 0.04, 1.26 * side }
	joint(k, "Leg", hip, { Type = "Wiggle", Axis = "Y", Amount = 8, Speed = 0.8, Phase = phase }, function()
		spindle(k, "Thigh", hip, knee, 0.17, SHELL)
		spindle(k, "Shin", knee, ankle, 0.12, LEG)
		spindle(k, "Tip", ankle, foot, 0.08, LEG_PALE)
	end)
end

return {
	Id = "TrippiTroppi",
	Name = "Trippi Troppi",
	Rarity = "Uncommon",
	Emoji = "🦐",
	Color = FUR,
	Tagline = "Cat head. Shrimp body. Zero explanations.",
	Lore = "Half ginger cat, half cooked shrimp, fully confused. Trippi Troppi scuttles along the shore on eight tiny legs, meowing at seagulls and flicking its fan tail. Nobody knows if it wants the fish or is the fish.",

	Build = function(k)
		-- the whole model slides a little toward the tail so it sits centred on the pedestal
		k:Group({ Name = "Model", Pos = { -0.22, 0, 0 } }, function()
		-- eight thin walking legs (front pair reaches forward, back pair backward)
		local legs = { { 1.25, 0.7 }, { 0.8, 0.3 }, { 0.35, -0.12 }, { -0.1, -0.42 } }
		for i, l in legs do
			buildLeg(k, l[1], -1, l[2], i * 0.25)
			-- far-side legs sit a touch further forward so all eight read from the front
			buildLeg(k, l[1] + 0.16, 1, l[2], i * 0.25 + 0.5)
		end

		joint(k, "Body", { 0, 2.0, 0 }, { Type = "Bob", Axis = "Y", Amount = 0.04, Speed = 0.5 }, function()
			buildThorax(k)
			buildSegment(k, 1)
			buildSegment(k, 2)
			-- the abdomen curls and uncurls; the fan flicks at the very end
			local p3x, p3y = arcPoint(31)
			joint(k, "AbdomenCurl", { p3x, p3y, 0 }, { Type = "Wiggle", Axis = "Z", Amount = 2, Speed = 0.45 }, function()
				buildSegment(k, 3)
				buildSegment(k, 4)
				local p5x, p5y = arcPoint(90)
				joint(k, "TailCurl", { p5x, p5y, 0 }, { Type = "Wiggle", Axis = "Z", Amount = 3, Speed = 0.45, Phase = 0.12 }, function()
					buildSegment(k, 5)
					buildSegment(k, 6)
					local fx, fy = arcPoint(FAN_TH)
					joint(k, "TailFlick", { fx, fy, 0 }, { Type = "Wiggle", Axis = "Z", Amount = 7, Speed = 0.8, Phase = 0.3 }, function()
						buildTailFan(k)
					end)
				end)
			end)

			-- cat head tilts on the neck
			joint(k, "Head", NECK, { Type = "Wiggle", Axis = "Z", Amount = 5, Speed = 0.35 }, function()
				k:Group({ Name = "HeadFrame", Pos = HC }, function()
					buildHead(k)
					-- the shrimp's whip antennae grow from shell sockets behind the ears and
					-- sweep up and back over the curled body
					local function rel(list)
						local out = {}
						for i, p in list do
							out[i] = { p[1] - HC[1], p[2] - HC[2], p[3] - HC[3] }
						end
						return out
					end
					buildAntenna(k, "AntennaA", rel(bezier(
						{ 1.78, 4.2, 0.08 },
						{ 2.1, 6.1, -0.35 },
						{ 0.6, 7.4, -0.6 },
						{ -2.45, 6.2, -0.55 },
						7
					)), 0)
					buildAntenna(k, "AntennaB", rel(bezier(
						{ 1.02, 4.2, 0.08 },
						{ 1.1, 5.7, 0.1 },
						{ -0.2, 6.75, 0.3 },
						{ -2.2, 5.45, 0.7 },
						6
					)), 0.35)
				end)
			end)
		end)

		-- rarity flair: a few bubbles drift up off the shell
		k:Particles({ Pos = { -1.2, 3.6, 0 }, Color = "#d8f3ff", Color2 = "#ffffff", Rate = 2, Size = 0.22, Speed = 0.9, Lifetime = 2.5, Spread = 35, Direction = "Top" })
		end)
	end,

	BuildMini = function(k)
		-- curled cooked-shrimp body in profile (tail at -X) ending in a red fan tail
		k:Part({ Name = "Body", Shape = "Ellipsoid", Size = { 1.1, 1.0, 0.82 }, Pos = { -0.36, 0.04, 0.1 }, Rot = { 0, 0, -18 }, Color = SHELL })
		k:Part({ Name = "Tail", Shape = "Ellipsoid", Size = { 0.64, 0.72, 0.62 }, Pos = { -0.86, -0.5, 0.1 }, Rot = { 0, 0, 62 }, Color = SHELL_LIGHT })
		k:Part({ Name = "Fan", Shape = "Ellipsoid", Size = { 0.82, 0.5, 0.2 }, Pos = { -0.44, -0.98, 0.1 }, Rot = { 0, 0, -24 }, Color = SHELL_RED })
		-- ginger cat head facing front
		k:Part({ Name = "Head", Shape = "Ellipsoid", Size = { 1.3, 1.1, 1.05 }, Pos = { 0.42, 0.2, -0.15 }, Color = FUR })
		k:Part({ Name = "EarR", Shape = "Wedge", Size = { 0.16, 0.5, 0.36 }, Pos = { 0.8, 0.88, -0.1 }, Rot = { 0, -90, 0 }, Color = FUR })
		k:Part({ Name = "EarL", Shape = "Wedge", Size = { 0.16, 0.5, 0.36 }, Pos = { 0.04, 0.88, -0.1 }, Rot = { 0, 90, 0 }, Color = FUR })
		k:Part({ Name = "EyeR", Shape = "Ellipsoid", Size = { 0.36, 0.42, 0.2 }, Pos = { 0.67, 0.3, -0.6 }, Color = IRIS })
		k:Part({ Name = "EyeL", Shape = "Ellipsoid", Size = { 0.36, 0.42, 0.2 }, Pos = { 0.17, 0.3, -0.6 }, Color = IRIS })
		k:Part({ Name = "PupilR", Shape = "Ellipsoid", Size = { 0.16, 0.28, 0.1 }, Pos = { 0.66, 0.29, -0.69 }, Color = PUPIL })
		k:Part({ Name = "PupilL", Shape = "Ellipsoid", Size = { 0.16, 0.28, 0.1 }, Pos = { 0.18, 0.29, -0.69 }, Color = PUPIL })
		k:Part({ Name = "Muzzle", Shape = "Ellipsoid", Size = { 0.5, 0.3, 0.22 }, Pos = { 0.42, -0.04, -0.64 }, Color = CREAM })
		-- whip antenna rising from behind the ears and sweeping back over the shell
		k:Part({ Name = "Antenna", Shape = "Cylinder", Size = { 1.0, 0.07, 0.07 }, Pos = { -0.02, 1.02, 0.08 }, Rot = { 0, 0, -32 }, Color = ANTENNA })
	end,
}
