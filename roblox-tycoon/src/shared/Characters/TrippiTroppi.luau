--[[
	Trippi Troppi (Uncommon)
	Canonical look: a cute/cursed orange tabby CAT head (pointed ears with pink insides,
	tabby "M" stripes, huge eyes, whiskers, little pink nose, open mouth) fused onto the
	pink-orange body of a cooked SHRIMP: curved segmented shell plates, a curled abdomen
	ending in a fan tail, little swimmerets and spindly walking legs underneath, and two
	long antennae.

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
local PUPIL = "#1b1b24"
local SHINE = "#fff8ec"
local LINER = "#3b2318"
local WHISKER = "#fff6e6"
-- shrimp
local SHELL = "#f5765c" -- cooked shrimp coral
local SHELL_LIGHT = "#ffa98a"
local SHELL_DARK = "#d6493a" -- segment bands
local SHELL_PALE = "#ffcab2" -- pale lower plates / belly
local SHELL_RED = "#bf3a2e" -- tail tips
local LEG = "#f8906f"

-- Layout (world studs) -------------------------------------------------------------------
local HC = { 1.4, 3.5, -0.4 } -- head centre
local NECK = { 1.3, 2.5, -0.2 } -- head tilt pivot
local AC = { -1.05, 2.06 } -- abdomen arc centre (x, y) in the profile plane
local AR = 1.2 -- abdomen arc radius

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

-- Abdomen arc: centre of a segment at angle th (degrees from straight up, toward -X)
local function arcPoint(th, r)
	local a = math.rad(th)
	return AC[1] - (r or AR) * math.sin(a), AC[2] + (r or AR) * math.cos(a)
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
	k:Part({ Name = "Iris", Shape = "Ellipsoid", Size = { 0.8, 0.88, 0.3 }, Pos = at(-0.03, -0.02, -0.01), Rot = rot, Color = IRIS, Anim = BLINK })
	k:Part({ Name = "Pupil", Shape = "Ellipsoid", Size = { 0.42, 0.66, 0.28 }, Pos = at(-0.04, -0.02, 0.03), Rot = rot, Color = PUPIL, Anim = BLINK })
	k:Part({ Name = "EyeShine", Shape = "Ball", Size = { 0.22, 0.22, 0.22 }, Pos = at(0.13, 0.2, 0.08), Color = SHINE, Material = "Neon", Anim = BLINK })
end

local function buildEar(k, side, phase)
	local p = headSurface(0.6 * side, 1, -0.12, -0.18)
	k:Group({
		Name = if side > 0 then "RightEar" else "LeftEar",
		Pos = p,
		Rot = { 10, -14 * side, -16 * side },
		Anim = { Type = "Wiggle", Axis = "Z", Amount = 9, Speed = 0.5, Phase = phase },
	}, function()
		triangle(k, "Ear", 1.1, 1.35, 0.3, FUR, { 0, 0.675, 0 })
		triangle(k, "EarInner", 0.7, 0.95, 0.1, EAR_PINK, { 0, 0.52, -0.15 })
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
		-- cheek fluff tufts sticking out of the silhouette
		k:Group({ Name = "CheekFluff", Pos = { 1.22, -0.78, -0.5 }, Rot = { 0, -40, -118 } }, function()
			triangle(k, "Fluff", 0.5, 0.52, 0.14, FUR_LIGHT, { 0, 0.26, 0 })
		end)

		-- eyes
		buildEye(k)

		-- muzzle pads (axis aligned so dots can be placed on them)
		local pp = headSurface(0.26, -0.42, -1, -0.14)
		local muzzle = { pp[1], pp[2], pp[3], 0.36, 0.28, 0.26 }
		k:Part({ Name = "MuzzlePad", Shape = "Ellipsoid", Size = { 0.72, 0.56, 0.52 }, Pos = pp, Color = CREAM })
		for _, d in { { 0.25, 0.25 }, { 0.45, -0.05 } } do
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

		-- tabby stripes: forehead "M", cheeks, back of the head
		stripe(k, { 0.2, 0.72, -0.72 }, { 0.11, 0.46, 0.16 }, -12)
		stripe(k, { 0.44, 0.62, -0.7 }, { 0.1, 0.38, 0.16 }, -26)
		stripe(k, { 1, -0.08, -0.5 }, { 0.52, 0.1, 0.16 }, 8)
		stripe(k, { 1, -0.34, -0.42 }, { 0.46, 0.1, 0.16 }, -6)
		stripe(k, { 0.42, 0.55, 0.8 }, { 0.16, 0.7, 0.18 }, -14)
		stripe(k, { 0.85, 0.2, 0.6 }, { 0.16, 0.62, 0.18 }, -30)
	end)
	stripe(k, { 0, 0.78, -0.7 }, { 0.13, 0.55, 0.16 }, 0)
	stripe(k, { 0, 0.6, 0.82 }, { 0.18, 0.8, 0.18 }, 0)
	stripe(k, { 0, 1, 0.15 }, { 0.15, 0.7, 0.16 }, 0)

	-- nose, philtrum, open mouth, tongue, chin
	local np, nn = headSurface(0, -0.2, -1, 0.1)
	k:Part({ Name = "Nose", Shape = "Ellipsoid", Size = { 0.36, 0.22, 0.24 }, Pos = np, Rot = faceRot(nn, 0), Color = NOSE })
	local php = headSurface(0, -0.38, -1, 0.05)
	k:Part({ Name = "Philtrum", Size = { 0.05, 0.2, 0.06 }, Pos = php, Color = LINER })
	local mp, mn = headSurface(0, -0.7, -1, -0.12)
	k:Part({ Name = "Mouth", Shape = "Ellipsoid", Size = { 0.66, 0.44, 0.36 }, Pos = mp, Rot = faceRot(mn, 0), Color = MOUTH })
	local tp = headSurface(0, -0.8, -1, -0.07)
	k:Part({ Name = "Tongue", Shape = "Ellipsoid", Size = { 0.42, 0.2, 0.3 }, Pos = tp, Rot = faceRot(mn, 0), Color = TONGUE })
	local cp, cn = headSurface(0, -1, -0.75, -0.2)
	k:Part({ Name = "Chin", Shape = "Ellipsoid", Size = { 0.85, 0.5, 0.6 }, Pos = cp, Rot = faceRot(cn, 0), Color = CREAM })

	-- ears flick one at a time
	buildEar(k, 1, 0)
	buildEar(k, -1, 0.45)
end

-- Long antennae: a chain of nested groups so the wave travels down the whip
local function buildAntenna(k, name, pts, phase)
	k:Part({ Name = "AntennaSocket", Shape = "Ball", Size = { 0.26, 0.26, 0.26 }, Pos = pts[1], Color = SHELL_DARK })
	local function link(i)
		local a, b = pts[i], pts[i + 1]
		local d = 0.15 - (i - 1) * 0.014
		k:Group({
			Name = name .. i,
			Pos = if i == 1 then a else { a[1] - pts[i - 1][1], a[2] - pts[i - 1][2], a[3] - pts[i - 1][3] },
			Anim = { Type = "Wiggle", Axis = if i % 2 == 0 then "Z" else "X", Amount = 4, Speed = 0.55, Phase = phase + i * 0.07 },
		}, function()
			segment(k, "Antenna", { 0, 0, 0 }, { b[1] - a[1], b[2] - a[2], b[3] - a[3] }, d, if i % 2 == 0 then SHELL else SHELL_DARK)
			if i + 1 < #pts then
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
	k:Group({ Name = "Carapace", Pos = { 0.45, 2.3, 0.05 } }, function()
		k:Part({ Name = "Carapace", Shape = "Ellipsoid", Size = { 2.5, 1.7, 1.8 }, Color = SHELL, Reflectance = 0.05 })
		k:Part({ Name = "DorsalRidge", Shape = "Ellipsoid", Size = { 2.1, 0.24, 0.26 }, Pos = { -0.1, 0.84, 0 }, Color = SHELL_DARK })
		for _, x in { -0.55, -0.95 } do
			k:Part({ Name = "Spine", Shape = "Wedge", Size = { 0.12, 0.24, 0.26 }, Pos = { x, 0.98, 0 }, Rot = { 0, 90, 0 }, Color = SHELL_DARK })
		end
		k:Part({ Name = "Sternum", Shape = "Ellipsoid", Size = { 2.0, 0.4, 1.25 }, Pos = { 0, -0.74, 0 }, Color = SHELL_LIGHT })
	end)
end

local SEGMENTS = {
	{ th = -12, w = 1.78, h = 1.66, l = 1.05, swim = true },
	{ th = 17, w = 1.7, h = 1.58, l = 1.05, swim = true },
	{ th = 46, w = 1.6, h = 1.48, l = 1.02 },
	{ th = 75, w = 1.46, h = 1.34, l = 1.0 },
	{ th = 104, w = 1.3, h = 1.18, l = 0.98 },
	{ th = 132, w = 1.12, h = 1.02, l = 0.95, bare = true },
}
local FAN_TH = 163

local function buildSegment(k, i)
	local s = SEGMENTS[i]
	local cx, cy = arcPoint(s.th)
	-- local frame: +X = toward the head, +Y = back (dorsal), Z = sideways
	k:Group({ Name = "Segment" .. i, Pos = { cx, cy, 0 }, Rot = { 0, 0, s.th } }, function()
		k:Part({ Name = "Shell", Shape = "Ellipsoid", Size = { s.l, s.h, s.w }, Color = SHELL, Reflectance = 0.05 })
		k:Part({ Name = "Band", Shape = "Ellipsoid", Size = { 0.18, s.h * 0.86, s.w * 0.86 }, Pos = { -s.l / 2 + 0.24, 0.02, 0 }, Color = SHELL_DARK })
		for side = -1, 1, 2 do
			if s.bare then
				break -- the last segment is too tucked in to show side plates
			end
			k:Part({ Name = "Pleuron", Shape = "Ellipsoid", Size = { s.l * 0.86, s.h * 0.42, 0.12 }, Pos = { 0.02, -s.h * 0.3, side * (s.w * 0.4 + (7 - i) * 0.01) }, Color = SHELL_LIGHT })
			if s.swim then
				k:Group({ Name = "Swimmeret", Pos = { 0, -s.h / 2 + 0.12, side * 0.34 }, Anim = { Type = "Wiggle", Axis = "Z", Amount = 18, Speed = 1.1, Phase = i * 0.13 } }, function()
					k:Part({ Name = "Paddle", Shape = "Ellipsoid", Size = { 0.22, 0.5, 0.1 }, Pos = { 0, -0.2, 0 }, Color = SHELL_PALE })
				end)
			end
		end
	end)
end

local function buildTailFan(k)
	local px, py = arcPoint(FAN_TH)
	-- local frame: -X = toward the tail tip, fan spreads in the profile (XY) plane
	k:Group({ Name = "Fan", Pos = { px, py, 0 }, Rot = { 0, 0, FAN_TH } }, function()
		k:Part({ Name = "Telson", Shape = "Ellipsoid", Size = { 0.98, 0.3, 0.22 }, Pos = { -0.45, 0, 0 }, Color = SHELL_DARK })
		for _, u in { { 18, -0.07 }, { -13, -0.07 }, { 40, 0.07 }, { -31, 0.07 } } do
			k:Group({ Name = "Uropod", Rot = { 0, 0, u[1] } }, function()
				k:Part({ Name = "Blade", Shape = "Ellipsoid", Size = { 0.9, 0.5, 0.12 }, Pos = { -0.48, 0, u[2] }, Color = SHELL })
				k:Part({ Name = "BladeTip", Shape = "Ellipsoid", Size = { 0.26, 0.46, 0.14 }, Pos = { -0.84, 0, u[2] }, Color = SHELL_RED })
			end)
		end
	end)
end

local function buildLeg(k, x, side, reach, phase)
	local hip = { x, 1.6, 0.45 * side }
	local knee = { x + reach * 0.45, 1.5, 1.0 * side }
	local foot = { x + reach, 0.07, 1.38 * side }
	joint(k, "Leg", hip, { Type = "Wiggle", Axis = "Z", Amount = 6, Speed = 0.8, Phase = phase }, function()
		segment(k, "Thigh", hip, knee, 0.22, SHELL)
		segment(k, "Shin", knee, foot, 0.15, LEG)
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
		-- eight spindly walking legs (front pair reaches forward, back pair backward)
		local legs = { { 1.35, 0.6 }, { 0.85, 0.28 }, { 0.35, -0.04 }, { -0.15, -0.3 } }
		for i, l in legs do
			buildLeg(k, l[1], -1, l[2], i * 0.18)
			-- far-side legs sit a touch further forward so all eight read from the front
			buildLeg(k, l[1] + 0.16, 1, l[2], i * 0.18 + 0.5)
		end

		joint(k, "Body", { 0, 2.4, 0 }, { Type = "Bob", Axis = "Y", Amount = 0.05, Speed = 0.5 }, function()
			buildThorax(k)
			buildSegment(k, 1)
			buildSegment(k, 2)
			-- the abdomen curls and uncurls; the fan flicks at the very end
			local p3x, p3y = arcPoint(31)
			joint(k, "AbdomenCurl", { p3x, p3y, 0 }, { Type = "Wiggle", Axis = "Z", Amount = 2, Speed = 0.45 }, function()
				buildSegment(k, 3)
				buildSegment(k, 4)
				local p5x, p5y = arcPoint(90)
				joint(k, "TailCurl", { p5x, p5y, 0 }, { Type = "Wiggle", Axis = "Z", Amount = 3.5, Speed = 0.45, Phase = 0.12 }, function()
					buildSegment(k, 5)
					buildSegment(k, 6)
					local fx, fy = arcPoint(FAN_TH)
					joint(k, "TailFlick", { fx, fy, 0 }, { Type = "Wiggle", Axis = "Z", Amount = 9, Speed = 0.8, Phase = 0.3 }, function()
						buildTailFan(k)
					end)
				end)
			end)

			-- cat head tilts on the neck
			joint(k, "Head", NECK, { Type = "Wiggle", Axis = "Z", Amount = 5, Speed = 0.35 }, function()
				k:Group({ Name = "HeadFrame", Pos = HC }, function()
					buildHead(k)
					-- antennae sprout between the ears and arc back over the shrimp body
					local function rel(list)
						local out = {}
						for i, p in list do
							out[i] = { p[1] - HC[1], p[2] - HC[2], p[3] - HC[3] }
						end
						return out
					end
					buildAntenna(k, "AntennaA", rel({
						{ 1.64, 4.57, -0.9 },
						{ 1.74, 5.45, -1.12 },
						{ 1.45, 6.4, -1.18 },
						{ 0.75, 7.15, -1.0 },
						{ -0.3, 7.45, -0.82 },
						{ -1.45, 7.25, -0.62 },
						{ -2.4, 6.55, -0.45 },
					}), 0)
					buildAntenna(k, "AntennaB", rel({
						{ 1.16, 4.57, -0.9 },
						{ 1.08, 5.4, -0.92 },
						{ 0.7, 6.2, -0.7 },
						{ -0.1, 6.75, -0.35 },
						{ -1.05, 6.8, 0.0 },
						{ -1.95, 6.3, 0.35 },
					}), 0.35)
				end)
			end)
		end)

		-- rarity flair: a few bubbles drift up off the shell
		k:Particles({ Pos = { -1.4, 3.9, 0 }, Color = "#d8f3ff", Color2 = "#ffffff", Rate = 2, Size = 0.22, Speed = 0.9, Lifetime = 2.5, Spread = 35, Direction = "Top" })
	end,

	BuildMini = function(k)
		-- curled shrimp abdomen in profile (tail at -X), alternating shell bands
		k:Part({ Name = "Seg1", Shape = "Ellipsoid", Size = { 0.66, 0.78, 0.74 }, Pos = { -0.3, -0.05, 0.05 }, Rot = { 0, 0, -10 }, Color = SHELL })
		k:Part({ Name = "Seg2", Shape = "Ellipsoid", Size = { 0.58, 0.68, 0.66 }, Pos = { -0.78, -0.36, 0.05 }, Rot = { 0, 0, 40 }, Color = SHELL_DARK })
		k:Part({ Name = "Seg3", Shape = "Ellipsoid", Size = { 0.5, 0.58, 0.56 }, Pos = { -0.9, -0.8, 0.05 }, Rot = { 0, 0, 80 }, Color = SHELL })
		k:Part({ Name = "Fan", Shape = "Ellipsoid", Size = { 0.7, 0.4, 0.14 }, Pos = { -0.55, -1.0, 0.05 }, Rot = { 0, 0, -28 }, Color = SHELL_RED })
		-- ginger cat head facing front
		k:Part({ Name = "Head", Shape = "Ellipsoid", Size = { 1.3, 1.1, 1.05 }, Pos = { 0.42, 0.2, -0.15 }, Color = FUR })
		k:Part({ Name = "EarR", Shape = "Wedge", Size = { 0.16, 0.5, 0.36 }, Pos = { 0.8, 0.88, -0.1 }, Rot = { 0, -90, 0 }, Color = FUR })
		k:Part({ Name = "EarL", Shape = "Wedge", Size = { 0.16, 0.5, 0.36 }, Pos = { 0.04, 0.88, -0.1 }, Rot = { 0, 90, 0 }, Color = FUR })
		k:Part({ Name = "EyeR", Shape = "Ellipsoid", Size = { 0.34, 0.4, 0.2 }, Pos = { 0.67, 0.3, -0.6 }, Color = IRIS })
		k:Part({ Name = "EyeL", Shape = "Ellipsoid", Size = { 0.34, 0.4, 0.2 }, Pos = { 0.17, 0.3, -0.6 }, Color = IRIS })
		k:Part({ Name = "PupilR", Shape = "Ellipsoid", Size = { 0.16, 0.26, 0.1 }, Pos = { 0.66, 0.29, -0.69 }, Color = PUPIL })
		k:Part({ Name = "PupilL", Shape = "Ellipsoid", Size = { 0.16, 0.26, 0.1 }, Pos = { 0.18, 0.29, -0.69 }, Color = PUPIL })
		k:Part({ Name = "Muzzle", Shape = "Ellipsoid", Size = { 0.5, 0.3, 0.22 }, Pos = { 0.42, -0.02, -0.64 }, Color = CREAM })
	end,
}
