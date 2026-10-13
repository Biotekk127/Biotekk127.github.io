--[[
	La Vacca Saturno Saturnita (Secret)
	Canonical look: a black-and-white Holstein cow head (pink snout with nostrils, little
	ivory horns, floppy ears, big eyes) popping out of the top of the planet SATURN, which is
	its whole body: a big beige / tan / orange banded sphere wrapped in wide tilted rings
	(beige inner rings, pale-blue outer ring). It stands on two bare human legs with big feet.

	Secret flair (never changes the design): glowing ring rim, orbiting moons, twinkling
	stars, a ForceField aura, Glass inner ring, a Foil moon, 2 lights, 3 particle emitters.

	Coordinates: feet on y = 0, faces -Z. Most parts are written in world coordinates by
	nesting an un-animated "offset" group inside each animated joint group.
]]

-- Palette ------------------------------------------------------------------------------
local COW = "#fff8ec" -- warm white hide
local COW_SHADE = "#efe4d4"
local PATCH = "#211e27" -- Holstein black patches (tinted dark)
local PINK = "#f3a7b6" -- snout
local PINK_DARK = "#d97b93"
local PINK_LIGHT = "#fbc8d1"
local NOSTRIL = "#8a3550"
local NOSTRIL_IN = "#4a1626"
local MOUTH = "#44192a"
local TONGUE = "#e8687f"
local EYE_WHITE = "#fffaf0"
local EYE_RIM = "#2a2530"
local IRIS = "#5b3420"
local PUPIL = "#141218"
local SHINE = "#fffdf6"
local HORN = "#f1e4c6"
local HORN_MID = "#dcc497"
local HORN_TIP = "#9a7a55"

local SKIN = "#f4cbb0" -- bare human legs (warm pinkish skin, not wood)
local SKIN_DARK = "#e2ad91"
local SKIN_LIGHT = "#f9dcc8"
local NAIL = "#fde9df"

-- Saturn bands, pole -> equator: { latitude below which the band shows, colour }.
-- Alternating light zones and darker belts with thin brown pinstripes, so the planet reads
-- as banded Saturn (tan / orange / cream) even from across the plot.
local BANDS = {
	{ 90, "#c9bea4" }, -- polar cap (pale grey-beige, faintly cool)
	{ 66, "#d7ad78" }, -- tan
	{ 59, "#a9774c" }, -- thin brown pinstripe
	{ 56, "#f4e5c3" }, -- cream zone
	{ 47, "#df9c5d" }, -- orange belt
	{ 38, "#f8ecd2" }, -- light cream zone
	{ 30, "#cc8550" }, -- deep orange belt
	{ 24, "#efd6a6" }, -- sand zone
	{ 16, "#b27c52" }, -- thin brown pinstripe
	{ 13, "#e8c189" }, -- golden-beige equatorial belt
	{ 4, "#f6e4bd" }, -- bright equator line
}
local RING_C = { "#dccaa6", "#cfbb96" } -- beige inner ring (Glass)
local RING_B = { "#a9cff2", "#9dc4ec", "#b8d9f6" } -- the big pale-blue main ring
local RING_A = { "#7fa9dc", "#7299d0" } -- deeper blue outer ring (Ice)
local RING_GLOW = "#c8eeff"
local STAR = "#fff3b0"
local STAR_BLUE = "#cfe9ff"
local AURA = "#b9a8ff"

-- Layout (world studs) -------------------------------------------------------------------
local PC = { 0, 4.55, 0 } -- planet centre
local PR = 1.95 -- planet radius (polar)
local HIP = { 0, 2.85, 0 } -- body sway pivot
local NECK = { 0, 6.55, -0.25 } -- head nod pivot
local JAW_HINGE = { 0, 6.62, -0.72 }
local HEAD_SCALE = 1.18 -- head modelled at 1:1, built 18% bigger around the neck

-- Head volumes {cx, cy, cz, semiX, semiY, semiZ}
local SKULL = { 0, 7.5, -0.3, 1.02, 0.9, 0.95 }
local FACE = { 0, 7.08, -0.82, 0.86, 0.7, 0.76 }
local MUZZLE = { 0, 6.84, -1.36, 0.82, 0.5, 0.56 }
local JAW = { 0, 6.44, -1.1, 0.62, 0.26, 0.5 }
local NECKV = { 0, 6.42, -0.2, 0.86, 0.55, 0.82 }

-- Ring tilt (front edge dips toward the viewer, rises to the viewer's right)
local RING_ROT = { -24, 0, -15 }

------------------------------------------------------------------------------------------
-- Math helpers
------------------------------------------------------------------------------------------
local function deg(r)
	return r * 180 / math.pi
end

local function unit(x, y, z)
	local l = math.sqrt(x * x + y * y + z * z)
	return x / l, y / l, z / l
end

-- Rotation whose local -Z points along unit vector n (flat details lying on a surface)
local function faceRot(nx, ny, nz, spin)
	return { deg(math.atan2(ny, -nz)), deg(math.asin(-nx)), spin or 0 }
end

-- Rotation that points a Cylinder's axis (local X) along vector v
local function axisRot(vx, vy, vz)
	vx, vy, vz = unit(vx, vy, vz)
	return { 0, deg(math.atan2(-vz, vx)), deg(math.asin(vy)) }
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

-- Outer surface point of a union of ellipsoids, seen from p along d, pushed `out` studs.
local function surface(list, px, py, pz, dx, dy, dz, out)
	dx, dy, dz = unit(dx, dy, dz)
	local best, bt = list[1], -1
	for _, e in list do
		local t = exitT(e, px, py, pz, dx, dy, dz)
		if t > bt then
			best, bt = e, t
		end
	end
	local x, y, z = px + dx * bt, py + dy * bt, pz + dz * bt
	local nx, ny, nz = unit((x - best[1]) / (best[4] * best[4]), (y - best[2]) / (best[5] * best[5]), (z - best[3]) / (best[6] * best[6]))
	return { x + nx * out, y + ny * out, z + nz * out }, { nx, ny, nz }
end

-- A smooth "cap" patch that hugs ellipsoid e: a slightly shrunken copy of e pushed toward
-- direction u, so only a cap of angular radius `alpha` pokes out (follows the curvature).
local function capPatch(k, name, e, ux, uy, uz, alpha, s, color, material)
	ux, uy, uz = unit(ux, uy, uz)
	local ca = math.cos(math.rad(alpha))
	local o = ca - math.sqrt(ca * ca - 1 + s * s)
	k:Part({
		Name = name,
		Shape = "Ellipsoid",
		Size = { 2 * e[4] * s, 2 * e[5] * s, 2 * e[6] * s },
		Pos = { e[1] + ux * o * e[4], e[2] + uy * o * e[5], e[3] + uz * o * e[6] },
		Color = color,
		Material = material or "SmoothPlastic",
	})
end

-- Cylinder segment between two points
local function segment(k, name, a, b, diameter, color, material)
	local vx, vy, vz = b[1] - a[1], b[2] - a[2], b[3] - a[3]
	local len = math.sqrt(vx * vx + vy * vy + vz * vz)
	k:Part({
		Name = name,
		Shape = "Cylinder",
		Size = { len + diameter * 0.35, diameter, diameter },
		Pos = { (a[1] + b[1]) / 2, (a[2] + b[2]) / 2, (a[3] + b[3]) / 2 },
		Rot = axisRot(vx, vy, vz),
		Color = color,
		Material = material or "SmoothPlastic",
	})
end

-- Rotation that points an Ellipsoid's local Y along unit-ish vector u (limbs, tails)
local function upRot(ux, uy, uz)
	ux, uy, uz = unit(ux, uy, uz)
	return { deg(math.atan2(uz, uy)), 0, deg(-math.asin(ux)) }
end

-- Smooth organic limb: a chain of heavily overlapping round beads along a polyline.
-- pts = { {x, y, z, radius}, ... }. Overlap 2.6x hides every bead's tapering ends.
local function loft(k, name, pts, color, material)
	for i = 1, #pts - 1 do
		local a, b = pts[i], pts[i + 1]
		local vx, vy, vz = a[1] - b[1], a[2] - b[2], a[3] - b[3]
		local len = math.sqrt(vx * vx + vy * vy + vz * vz)
		local r = math.max(a[4], b[4])
		k:Part({
			Name = name,
			Shape = "Ellipsoid",
			Size = { r * 2, len * 2.6, r * 2 },
			Pos = { (a[1] + b[1]) / 2, (a[2] + b[2]) / 2, (a[3] + b[3]) / 2 },
			Rot = upRot(vx, vy, vz),
			Color = color,
			Material = material or "SmoothPlastic",
		})
	end
end

-- Animated joint whose children are written in world coordinates
local function joint(k, name, p, anim, fn, rot)
	k:Group({ Name = name, Pos = p, Rot = rot, Anim = anim }, function()
		k:Group({ Name = name .. "Offset", Pos = { -p[1], -p[2], -p[3] } }, fn)
	end)
end

-- A builder proxy that uniformly scales everything built through it (every Pos and Size,
-- relative to the frame it is used in). Lets the head be sized as one unit.
local function scaled(k, f)
	local proxy = {}
	local function sv(v)
		if v == nil then
			return nil
		end
		return { v[1] * f, v[2] * f, v[3] * f }
	end
	local function copy(spec)
		local c = {}
		for key, val in spec do
			c[key] = val
		end
		c.Pos = sv(spec.Pos)
		return c
	end
	function proxy:Part(spec)
		local c = copy(spec)
		c.Size = sv(spec.Size)
		k:Part(c)
	end
	function proxy:Group(spec, fn)
		k:Group(copy(spec), fn)
	end
	function proxy:Mirror(fn)
		k:Mirror(fn)
	end
	return proxy
end

-- 3D twinkle star: three crossed Neon bars that pulse
local function star(k, name, pos, size, color, phase, speed)
	for axis = 1, 3 do
		local sz = { size * 0.2, size * 0.2, size * 0.2 }
		sz[axis] = size
		k:Part({
			Name = name,
			Shape = "Ellipsoid",
			Size = sz,
			Pos = pos,
			Color = color,
			Material = "Neon",
			Anim = { Type = "Pulse", Amount = 0.35, Speed = speed or 0.8, Phase = phase },
		})
	end
end

------------------------------------------------------------------------------------------
-- Saturn: a sphere built from concentric stacked band layers. Layer i is a little wider and
-- flatter than the one below it, so it only shows in a band |latitude| < BANDS[i][1].
------------------------------------------------------------------------------------------
local BAND_STEP = 0.018

local function planetLayers()
	local layers = { { a = PR, b = PR, color = BANDS[1][2] } }
	for i = 2, #BANDS do
		local prev = layers[i - 1]
		local a = PR + (i - 1) * BAND_STEP
		local t = math.tan(math.rad(BANDS[i][1]))
		local invB2 = 1 / (prev.b * prev.b) + (1 / (prev.a * prev.a) - 1 / (a * a)) / (t * t)
		table.insert(layers, { a = a, b = 1 / math.sqrt(invB2), color = BANDS[i][2] })
	end
	return layers
end
local LAYERS = planetLayers()

-- Radius of the banded planet's outer surface at latitude `lat` (degrees)
local function planetRadius(lat)
	local c, s = math.cos(math.rad(lat)), math.sin(math.rad(lat))
	local best = 0
	for _, L in LAYERS do
		local d = 1 / math.sqrt(c * c / (L.a * L.a) + s * s / (L.b * L.b))
		best = math.max(best, d)
	end
	return best
end

-- Point + outward direction on the planet at latitude / azimuth (azimuth 0 = front, -Z)
local function onPlanet(lat, az, out)
	local r = planetRadius(lat) + (out or 0)
	local cl = math.cos(math.rad(lat))
	local nx, ny, nz = math.sin(math.rad(az)) * cl, math.sin(math.rad(lat)), -math.cos(math.rad(az)) * cl
	return { PC[1] + nx * r, PC[2] + ny * r, PC[3] + nz * r }, nx, ny, nz
end

-- Build parts lying flat on the planet surface at latitude / azimuth: inside `fn` the
-- origin is on the surface, local -Z points straight out and local X runs along the band.
local function onSurface(k, name, lat, az, out, fn)
	local r = planetRadius(lat) + (out or 0)
	k:Group({ Name = name, Pos = PC, Rot = { 0, -az, 0 } }, function()
		k:Group({ Name = name .. "Spot", Pos = { 0, r * math.sin(math.rad(lat)), -r * math.cos(math.rad(lat)) }, Rot = { lat, 0, 0 } }, function()
			fn(0)
		end)
	end)
end

local function buildPlanet(k)
	for i, L in LAYERS do
		k:Part({
			Name = if i == 1 then "Planet" else "Band" .. (i - 1),
			Shape = if i == 1 then "Ball" else "Ellipsoid",
			Size = { L.a * 2, L.b * 2, L.a * 2 },
			Pos = PC,
			Color = L.color,
			Material = "SmoothPlastic",
		})
	end

	-- festoons: long low-contrast wisps combed along the bands, plus Saturn's small white
	-- storms. Each lies flat on the surface, tangent to its latitude line.
	local wisps = {
		-- lat, azimuth, length, width, colour (a soft shade of the band it sits on), spin
		{ 43, -30, 1.2, 0.08, "#eab57e", 4 },
		{ 42, 120, 1.05, 0.07, "#eab57e", -5 },
		{ 34, 60, 1.1, 0.07, "#ecc99a", 3 },
		{ 34, -150, 1.15, 0.08, "#ecc99a", -3 },
		{ 27, 15, 1.0, 0.07, "#da9a62", -4 },
		{ -27, -45, 1.1, 0.07, "#da9a62", 4 },
		{ -34, 100, 1.15, 0.08, "#ecc99a", -4 },
		{ -43, -120, 1.05, 0.07, "#eab57e", 5 },
		{ -20, 170, 1.0, 0.07, "#f7e6c4", 2 },
		{ 20, -95, 0.95, 0.07, "#f7e6c4", -2 },
	}
	for _, w in wisps do
		onSurface(k, "Festoon", w[1], w[2], -0.02, function(spinBase)
			k:Part({ Name = "Festoon", Shape = "Ellipsoid", Size = { w[3], w[4], 0.1 }, Rot = { 0, 0, w[6] + spinBase }, Color = w[5] })
		end)
	end
	local storms = { { 42, -72, 0.3, 0.2 }, { -40, 48, 0.24, 0.16 }, { 41, -165, 0.26, 0.17 } }
	for _, st in storms do
		onSurface(k, "Storm", st[1], st[2], -0.015, function()
			k:Part({ Name = "Storm", Shape = "Ellipsoid", Size = { st[3], st[4], 0.09 }, Color = "#fff6e2" })
			k:Part({ Name = "StormEye", Shape = "Ellipsoid", Size = { st[3] * 0.45, st[4] * 0.45, 0.1 }, Pos = { st[3] * 0.08, 0, 0 }, Color = "#f1d7aa" })
		end)
	end

	-- cosmic aura shell
	k:Part({
		Name = "Aura",
		Shape = "Ball",
		Size = { 4.62, 4.62, 4.62 },
		Pos = PC,
		Color = AURA,
		Material = "ForceField",
		Transparency = 0.88,
		Anim = { Type = "Pulse", Amount = 0.025, Speed = 0.45 },
	})
end

------------------------------------------------------------------------------------------
-- Rings (built in the ring's own tilted frame; the ring plane is local y = 0)
------------------------------------------------------------------------------------------
local function ringBand(k, name, rIn, rOut, n, thick, colors, material, transparency)
	local rc = (rIn + rOut) / 2
	local L = 2 * rOut * math.tan(math.pi / n) + 0.004
	for i = 0, n - 1 do
		local a = (i + 0.5) / n * 2 * math.pi
		k:Part({
			Name = name,
			Size = { rOut - rIn, thick, L },
			Pos = { rc * math.cos(a), 0, rc * math.sin(a) },
			Rot = { 0, -deg(a), 0 },
			Color = colors[i % #colors + 1],
			Material = material or "SmoothPlastic",
			Transparency = transparency or 0,
		})
	end
end

local function buildRings(k)
	-- concentric bands, each one colour so the ring reads as smooth sheets (not tiles):
	-- beige glassy C ring, two-tone pale-blue B ring, Cassini gap, deeper-blue A ring, glow rim
	ringBand(k, "RingC", 2.2, 2.44, 24, 0.07, { RING_C[1] }, "Glass", 0.3)
	ringBand(k, "RingB", 2.44, 2.62, 28, 0.1, { RING_B[3] }, "SmoothPlastic", 0)
	ringBand(k, "RingB", 2.62, 2.82, 30, 0.1, { RING_B[1] }, "SmoothPlastic", 0)
	ringBand(k, "RingA", 2.89, 3.04, 32, 0.09, { RING_A[1] }, "Ice", 0)
	ringBand(k, "RingGlow", 3.04, 3.1, 32, 0.06, { RING_GLOW }, "Neon", 0)

	-- little ice boulders riding on the bright ring
	for i = 0, 7 do
		local a = math.rad(10 + i * 45 + (i % 3) * 7)
		local r = 2.56 + (i % 3) * 0.08
		local sz = 0.1 + (i % 4) * 0.025
		k:Part({
			Name = "RingRock",
			Size = { sz, sz * 0.8, sz * 1.1 },
			Pos = { r * math.cos(a), 0.06 + sz * 0.3, r * math.sin(a) },
			Rot = { i * 37, i * 53, i * 29 },
			Color = if i % 2 == 0 then "#eef3f8" else "#c3cdd9",
			Material = "Glacier",
		})
	end

	-- fine stardust specks glittering across the ring sheet
	for i = 0, 7 do
		local a = math.rad(55 + i * 45 + (i % 2) * 12)
		local r = 2.3 + (i % 4) * 0.2
		local sz = if i % 3 == 0 then 0.1 else 0.07
		k:Part({
			Name = "Stardust",
			Shape = "Ball",
			Size = { sz, sz, sz },
			Pos = { r * math.cos(a), 0.07, r * math.sin(a) },
			Color = if i % 2 == 0 then "#ffffff" else STAR,
			Material = "Neon",
			Anim = { Type = "Pulse", Amount = 0.4, Speed = 1.1, Phase = (i * 0.37) % 1 },
		})
	end

	-- twinkling stardust glints riding on the bright ring
	for i = 0, 3 do
		local a = math.rad(25 + i * 90)
		star(k, "RingStar", { 2.64 * math.cos(a), 0.1, 2.64 * math.sin(a) }, 0.34, if i % 2 == 0 then STAR else STAR_BLUE, i * 0.23, 0.9)
	end
end

------------------------------------------------------------------------------------------
-- Moons orbiting in (and just above / below) the ring plane
------------------------------------------------------------------------------------------
local function moon(k, name, r, off, d, color, material, craterColor, speed, phase)
	k:Group({ Name = name .. "Orbit", Anim = { Type = "Spin", Axis = "Y", Speed = speed, Phase = phase } }, function()
		k:Group({ Name = name, Pos = { r, off, 0 }, Rot = { 20, 0, 30 } }, function()
			k:Part({ Name = name .. "Body", Shape = "Ball", Size = { d, d, d }, Color = color, Material = material })
			local craters = { { 0.3, 0.4, -0.86, 0.32 }, { -0.5, -0.2, -0.84, 0.24 }, { 0.6, -0.5, 0.62, 0.28 } }
			for _, c in craters do
				local nx, ny, nz = unit(c[1], c[2], c[3])
				local cd = d * c[4]
				k:Part({
					Name = name .. "Crater",
					Shape = "Ellipsoid",
					Size = { cd, cd, math.max(0.05, cd * 0.3) },
					Pos = { nx * d * 0.47, ny * d * 0.47, nz * d * 0.47 },
					Rot = faceRot(nx, ny, nz),
					Color = craterColor,
					Material = material,
				})
			end
		end)
	end)
end

------------------------------------------------------------------------------------------
-- Cow head (world coordinates at 1:1; Build scales it up by HEAD_SCALE around the neck)
------------------------------------------------------------------------------------------
local HEAD_VOLS = { SKULL, FACE }
local BLINK = { Type = "Blink", Speed = 0.24, Phase = 0.15 }

local function buildEye(k, s)
	local p, n = surface(HEAD_VOLS, s * 0.4, 7.72, -0.4, s * 0.22, 0.04, -1, -0.02)
	k:Group({ Name = "Eye", Pos = p, Rot = faceRot(n[1], n[2], n[3]) }, function()
		k:Part({ Name = "EyeRim", Shape = "Ellipsoid", Size = { 0.7, 0.8, 0.26 }, Pos = { 0, 0, 0.05 }, Color = EYE_RIM })
		k:Part({ Name = "EyeWhite", Shape = "Ellipsoid", Size = { 0.6, 0.7, 0.3 }, Pos = { 0, 0, 0 }, Color = EYE_WHITE, Anim = BLINK })
		k:Part({ Name = "Iris", Shape = "Ellipsoid", Size = { 0.42, 0.5, 0.12 }, Pos = { -s * 0.03, -0.04, -0.12 }, Color = IRIS, Anim = BLINK })
		k:Part({ Name = "Pupil", Shape = "Ellipsoid", Size = { 0.24, 0.3, 0.08 }, Pos = { -s * 0.03, -0.04, -0.17 }, Color = PUPIL, Anim = BLINK })
		k:Part({ Name = "EyeShine", Shape = "Ball", Size = { 0.13, 0.13, 0.13 }, Pos = { -s * 0.1, 0.1, -0.2 }, Color = SHINE, Material = "Neon", Anim = BLINK })
		k:Part({ Name = "EyeShine2", Shape = "Ball", Size = { 0.07, 0.07, 0.07 }, Pos = { s * 0.06, -0.14, -0.19 }, Color = SHINE, Material = "Neon", Anim = BLINK })
		-- thin upper lid line keeps the eye wide open (the meme's dopey stare)
		k:Part({ Name = "EyeLid", Shape = "Ellipsoid", Size = { 0.6, 0.1, 0.3 }, Pos = { 0, 0.36, -0.02 }, Rot = { 0, 0, s * 4 }, Color = EYE_RIM, Anim = BLINK })
		-- three lashes flicking out of the outer corner of the lid
		for j = 0, 2 do
			local ad = -2 + j * 20
			local a = math.rad(ad)
			k:Part({
				Name = "Lash",
				Size = { 0.05, 0.17, 0.05 },
				Pos = { s * (0.3 + math.cos(a) * 0.06), 0.1 + math.sin(a) * 0.1, -0.1 },
				Rot = { 0, 0, s * (ad - 90) },
				Color = EYE_RIM,
				Anim = BLINK,
			})
		end
	end)
end

local function buildEar(k, s, phase, dark)
	local root = { s * 0.9, 7.66, -0.2 }
	k:Group({
		Name = if s > 0 then "RightEar" else "LeftEar",
		Pos = root,
		Rot = { 0, s * 14, 0 },
		Anim = { Type = "Wiggle", Axis = "Z", Amount = 12, Speed = 0.55, Phase = phase },
	}, function()
		k:Part({ Name = "EarRoot", Shape = "Ellipsoid", Size = { 0.42, 0.34, 0.42 }, Pos = { s * 0.08, 0, 0 }, Color = if dark then PATCH else COW })
		k:Part({ Name = "Ear", Shape = "Ellipsoid", Size = { 1.05, 0.44, 0.6 }, Pos = { s * 0.5, -0.08, 0 }, Rot = { 0, 0, s * -16 }, Color = if dark then PATCH else COW })
		k:Part({ Name = "EarInner", Shape = "Ellipsoid", Size = { 0.78, 0.27, 0.16 }, Pos = { s * 0.52, -0.1, -0.24 }, Rot = { 0, 0, s * -16 }, Color = PINK })
		-- fluffy fur tufts in the ear opening
		k:Part({ Name = "EarFluff", Shape = "Ellipsoid", Size = { 0.34, 0.08, 0.07 }, Pos = { s * 0.34, -0.05, -0.3 }, Rot = { 0, 0, s * 12 }, Color = COW_SHADE })
		k:Part({ Name = "EarFluff", Shape = "Ellipsoid", Size = { 0.28, 0.07, 0.07 }, Pos = { s * 0.36, -0.14, -0.3 }, Rot = { 0, 0, s * -16 }, Color = COW_SHADE })
		if not dark then
			-- black ear tip
			k:Part({ Name = "EarTip", Shape = "Ellipsoid", Size = { 0.34, 0.3, 0.5 }, Pos = { s * 0.88, -0.19, 0.02 }, Rot = { 0, 0, s * -16 }, Color = PATCH })
		end
	end)
end

local function buildHorn(k)
	-- short, stubby ivory cow horn: out to the side, then curling up and a touch forward.
	-- Overlapping tapered ellipsoid beads along a quadratic curve.
	local P0, C, P2 = { 0.56, 8.0, -0.3 }, { 1.02, 8.08, -0.32 }, { 1.12, 8.56, -0.48 }
	local function at(t)
		local a, b, c = (1 - t) * (1 - t), 2 * (1 - t) * t, t * t
		return { a * P0[1] + b * C[1] + c * P2[1], a * P0[2] + b * C[2] + c * P2[2], a * P0[3] + b * C[3] + c * P2[3] }
	end
	local N = 5
	local COLS = { HORN, HORN, "#ead9b2", HORN_MID, HORN_TIP }
	local function dia(t)
		return 0.42 - 0.26 * t
	end
	for i = 1, N do
		local t0, t1 = (i - 1) / N, i / N
		local a, b = at(t0), at(t1)
		local vx, vy, vz = b[1] - a[1], b[2] - a[2], b[3] - a[3]
		local len = math.sqrt(vx * vx + vy * vy + vz * vz)
		local d = dia((i - 1) / (N - 1))
		k:Part({
			Name = "Horn",
			Shape = "Ellipsoid",
			Size = { len * 2.4, d, d },
			Pos = { (a[1] + b[1]) / 2, (a[2] + b[2]) / 2, (a[3] + b[3]) / 2 },
			Rot = axisRot(vx, vy, vz),
			Color = COLS[i],
		})
	end
	-- growth ridges round the horn + a keratin collar where it meets the skull
	for _, t in { 0.22, 0.42 } do
		local a, b = at(t - 0.04), at(t + 0.04)
		k:Part({
			Name = "HornRidge",
			Shape = "Cylinder",
			Size = { 0.05, dia(t) * 0.92, dia(t) * 0.92 },
			Pos = at(t),
			Rot = axisRot(b[1] - a[1], b[2] - a[2], b[3] - a[3]),
			Color = HORN_MID,
		})
	end
	k:Part({ Name = "HornBase", Shape = "Ellipsoid", Size = { 0.2, 0.5, 0.5 }, Pos = { 0.6, 8.02, -0.3 }, Rot = axisRot(1, 0.35, 0), Color = HORN_MID })
end

local function buildHead(k)
	-- big forms
	k:Part({ Name = "Neck", Shape = "Ellipsoid", Size = { NECKV[4] * 2, NECKV[5] * 2, NECKV[6] * 2 }, Pos = { NECKV[1], NECKV[2], NECKV[3] }, Color = COW })
	k:Part({ Name = "Skull", Shape = "Ellipsoid", Size = { SKULL[4] * 2, SKULL[5] * 2, SKULL[6] * 2 }, Pos = { SKULL[1], SKULL[2], SKULL[3] }, Color = COW })
	k:Part({ Name = "Face", Shape = "Ellipsoid", Size = { FACE[4] * 2, FACE[5] * 2, FACE[6] * 2 }, Pos = { FACE[1], FACE[2], FACE[3] }, Color = COW })
	k:Part({ Name = "Muzzle", Shape = "Ellipsoid", Size = { MUZZLE[4] * 2, MUZZLE[5] * 2, MUZZLE[6] * 2 }, Pos = { MUZZLE[1], MUZZLE[2], MUZZLE[3] }, Color = PINK })
	capPatch(k, "MuzzleTop", MUZZLE, 0, 0.75, -0.65, 30, 0.9, PINK_LIGHT)

	-- Holstein patches (smooth caps hugging the head)
	capPatch(k, "EyePatch", SKULL, 0.52, 0.2, -0.83, 37, 0.86, PATCH)
	capPatch(k, "EyePatch2", SKULL, 0.85, 0.45, -0.35, 32, 0.86, PATCH)
	capPatch(k, "EyePatch3", FACE, 0.62, 0.45, -0.65, 22, 0.88, PATCH)
	capPatch(k, "CrownPatch", SKULL, -0.55, 0.62, 0.55, 30, 0.86, PATCH)
	capPatch(k, "BackPatch", SKULL, 0.35, 0.05, 1, 26, 0.86, PATCH)
	capPatch(k, "CheekSpot", FACE, -0.72, -0.1, -0.68, 17, 0.9, PATCH)
	capPatch(k, "ForeheadSpot", SKULL, -0.2, 0.7, -0.68, 11, 0.9, PATCH)
	capPatch(k, "NeckPatch", NECKV, 0.85, 0.15, 0.45, 30, 0.9, PATCH)
	capPatch(k, "NeckPatch2", NECKV, -0.55, 0.3, 0.8, 24, 0.9, PATCH)
	capPatch(k, "NeckSpot", NECKV, -0.95, 0.12, -0.15, 12, 0.92, PATCH)
	capPatch(k, "NeckSpot", NECKV, -0.9, -0.12, -0.38, 9, 0.93, PATCH)
	-- the black forelock carries on over the poll as a shaggy tuft between the horns
	for _, f in { { 0, 0.92, 0.3, 0.36, 0 }, { 0.2, 0.86, 0.42, 0.28, 28 }, { -0.2, 0.86, 0.42, 0.28, -28 } } do
		local fp, fn = surface(HEAD_VOLS, 0, 7.5, -0.3, f[1], f[2], f[3], -0.03)
		k:Part({ Name = "PollTuft", Shape = "Ellipsoid", Size = { f[4], f[4] * 1.3, 0.13 }, Pos = fp, Rot = faceRot(fn[1], fn[2], fn[3], f[5]), Color = PATCH })
	end

	-- forelock tuft between the horns
	local fringe = { { 0, 1, -0.42, 0.42, 0 }, { 0.3, 0.95, -0.3, 0.3, 35 }, { -0.28, 0.95, -0.34, 0.3, -30 }, { 0.08, 0.88, -0.62, 0.26, 12 } }
	for _, f in fringe do
		local fp, fn = surface(HEAD_VOLS, 0, 7.5, -0.3, f[1], f[2], f[3], -0.03)
		k:Part({ Name = "Fringe", Shape = "Ellipsoid", Size = { f[4], f[4] * 1.25, 0.13 }, Pos = fp, Rot = faceRot(fn[1], fn[2], fn[3], f[5]), Color = PATCH })
	end

	-- nostrils + muzzle freckles
	k:Mirror(function()
		local p, n = surface({ MUZZLE }, 0.3, 6.92, -1.3, 0.25, 0.12, -1, -0.025)
		k:Part({ Name = "Nostril", Shape = "Ellipsoid", Size = { 0.3, 0.19, 0.12 }, Pos = p, Rot = faceRot(n[1], n[2], n[3], -20), Color = NOSTRIL })
		local p2 = surface({ MUZZLE }, 0.3, 6.92, -1.3, 0.25, 0.12, -1, 0.0)
		k:Part({ Name = "NostrilHole", Shape = "Ellipsoid", Size = { 0.17, 0.1, 0.08 }, Pos = p2, Rot = faceRot(n[1], n[2], n[3], -20), Color = NOSTRIL_IN, Anim = { Type = "Pulse", Amount = 0.12, Speed = 0.5 } })
		local fr = { { 0.55, 0.05, -0.83 }, { 0.68, -0.2, -0.7 } }
		for _, f in fr do
			local fp, fn = surface({ MUZZLE }, 0, 6.84, -1.36, f[1], f[2], f[3], -0.012)
			k:Part({ Name = "Freckle", Shape = "Ellipsoid", Size = { 0.09, 0.09, 0.05 }, Pos = fp, Rot = faceRot(fn[1], fn[2], fn[3]), Color = PINK_DARK })
		end
		buildHorn(k)
	end)

	-- mouth seam + inside
	k:Part({ Name = "MouthInside", Shape = "Ellipsoid", Size = { 0.98, 0.2, 0.72 }, Pos = { 0, 6.52, -1.22 }, Color = MOUTH })
	-- content little smile wrapping round the bottom of the snout (corners curl up)
	local smile = {}
	for i = 0, 6 do
		local f = i / 3 - 1
		local phi = math.rad(f * 58)
		table.insert(smile, (surface({ MUZZLE }, 0, 6.62 + 0.1 * f * f, -1.3, math.sin(phi), -0.5 + 0.28 * f * f, -math.cos(phi), -0.015)))
	end
	for i = 1, 6 do
		segment(k, "Smile", smile[i], smile[i + 1], 0.06, MOUTH)
	end

	-- chewing jaw: hinge nods (X) while it grinds side to side (Y) like a real cow
	joint(k, "JawChew", JAW_HINGE, { Type = "Wiggle", Axis = "X", Amount = 6, Speed = 1.1 }, function()
		joint(k, "JawGrind", JAW_HINGE, { Type = "Wiggle", Axis = "Y", Amount = 5, Speed = 0.55, Phase = 0.3 }, function()
			k:Part({ Name = "Jaw", Shape = "Ellipsoid", Size = { JAW[4] * 2, JAW[5] * 2, JAW[6] * 2 }, Pos = { JAW[1], JAW[2], JAW[3] }, Color = PINK_LIGHT })
			-- tongue tip poking out of the corner of the chewing mouth
			k:Part({ Name = "Tongue", Shape = "Ellipsoid", Size = { 0.3, 0.11, 0.24 }, Pos = { 0.38, 6.43, -1.56 }, Rot = { 0, 25, -18 }, Color = TONGUE })
			k:Part({ Name = "ChinTuft", Shape = "Ellipsoid", Size = { 0.34, 0.14, 0.24 }, Pos = { 0, 6.21, -1.18 }, Color = COW_SHADE })
		end)
	end)

	-- eyes, raised fur brows (white on the black patch, black on the white side) and ears
	buildEye(k, 1)
	buildEye(k, -1)
	for _, s in { 1, -1 } do
		local col = if s > 0 then COW_SHADE else PATCH
		local brow = { { 0.3, 8.21, 14 }, { 0.62, 8.18, -16 } } -- arched: high in the middle
		for _, b in brow do
			local bp, bn = surface(HEAD_VOLS, s * b[1], b[2], -0.3, s * 0.15, 0, -1, 0.012)
			k:Part({ Name = "Brow", Shape = "Ellipsoid", Size = { 0.4, 0.12, 0.13 }, Pos = bp, Rot = faceRot(bn[1], bn[2], bn[3], s * b[3]), Color = col })
		end
	end
	buildEar(k, 1, 0, true)
	buildEar(k, -1, 0.37, false)

end

------------------------------------------------------------------------------------------
-- Tail (swishes from the back of the planet)
------------------------------------------------------------------------------------------
local function buildTail(k)
	-- a proper Holstein tail: thick white root high on the back of the planet, hanging in a
	-- lazy S close to the surface, a black band and a big shaggy black switch at the end
	local root = onPlanet(-2, 180, -0.1)
	local T1, T2 = { 0, 4.2, 2.36 }, { 0.04, 3.72, 2.42 }
	local T3 = { 0.08, 3.22, 2.3 }
	joint(k, "Tail", root, { Type = "Wiggle", Axis = "Z", Amount = 12, Speed = 0.6 }, function()
		k:Part({ Name = "TailRoot", Shape = "Ellipsoid", Size = { 0.42, 0.36, 0.3 }, Pos = root, Color = COW_SHADE })
		k:Part({ Name = "TailRootSpot", Shape = "Ellipsoid", Size = { 0.24, 0.2, 0.12 }, Pos = { root[1] + 0.12, root[2] + 0.06, root[3] + 0.12 }, Color = PATCH })
		loft(k, "Tail", { { root[1], root[2], root[3], 0.15 }, { 0, 4.5, 2.32, 0.13 }, { T1[1], T1[2], T1[3], 0.12 }, { T2[1], T2[2], T2[3], 0.11 } }, COW)
		joint(k, "TailTip", T2, { Type = "Wiggle", Axis = "Z", Amount = 18, Speed = 0.6, Phase = 0.2 }, function()
			loft(k, "Tail", { { T2[1], T2[2], T2[3], 0.11 }, { T3[1], T3[2], T3[3], 0.1 } }, COW)
			k:Part({ Name = "TailBand", Shape = "Ellipsoid", Size = { 0.23, 0.24, 0.23 }, Pos = { T3[1], T3[2] + 0.04, T3[3] }, Color = PATCH })
			-- shaggy switch: long hair locks fanning down and out from the tip
			local tuft = {
				{ 0, 0, 0, 0, 0, 0.62 },
				{ 0.09, 0.02, 0.03, 0, 16, 0.55 },
				{ -0.09, 0.02, 0.03, 0, -16, 0.55 },
				{ 0.02, 0.0, -0.09, -14, 4, 0.5 },
				{ -0.03, 0.01, 0.1, 14, -6, 0.52 },
				{ 0.07, 0.03, 0.08, 10, 22, 0.42 },
				{ -0.07, 0.03, -0.07, -10, -22, 0.42 },
			}
			for _, t in tuft do
				k:Part({
					Name = "TailTuft",
					Shape = "Ellipsoid",
					Size = { 0.19, t[6], 0.19 },
					Pos = { T3[1] + t[1], T3[2] - t[6] * 0.42 + t[2], T3[3] + t[3] },
					Rot = { t[4], 0, t[5] },
					Color = PATCH,
				})
			end
		end)
	end)
end

------------------------------------------------------------------------------------------
-- Bare human legs with big feet
------------------------------------------------------------------------------------------
local function buildFoot(k, s)
	local fx = s * 0.84
	k:Part({ Name = "Foot", Shape = "Ellipsoid", Size = { 0.86, 0.5, 1.62 }, Pos = { fx, 0.25, -0.33 }, Color = SKIN })
	k:Part({ Name = "Instep", Shape = "Ellipsoid", Size = { 0.62, 0.42, 0.95 }, Pos = { fx - s * 0.02, 0.4, -0.22 }, Color = SKIN })
	k:Part({ Name = "Heel", Shape = "Ellipsoid", Size = { 0.6, 0.42, 0.5 }, Pos = { fx - s * 0.02, 0.21, 0.28 }, Color = SKIN })
	-- inner (big) toe -> little toe: {dx, z, diameter}
	local toes = { { -0.27, -1.12, 0.32 }, { -0.09, -1.14, 0.24 }, { 0.06, -1.09, 0.22 }, { 0.2, -1.01, 0.2 }, { 0.32, -0.9, 0.17 } }
	for i, t in toes do
		local d = t[3]
		local x = fx + s * t[1]
		k:Part({ Name = "Toe", Shape = "Ball", Size = { d, d, d }, Pos = { x, d / 2, t[2] }, Color = if i == 1 then SKIN else SKIN_LIGHT })
		k:Part({ Name = "ToeNail", Shape = "Ellipsoid", Size = { d * 0.6, math.max(0.05, d * 0.22), d * 0.5 }, Pos = { x, d * 0.86, t[2] - d * 0.17 }, Rot = { 20, 0, 0 }, Color = NAIL })
	end
end

local function buildLeg(k, s)
	-- hip (hidden inside the planet) -> thigh -> knee -> calf -> ankle, slight knock-knee
	loft(k, "Leg", {
		{ s * 0.7, 3.25, 0.0, 0.37 },
		{ s * 0.75, 2.4, -0.02, 0.34 },
		{ s * 0.78, 1.6, -0.04, 0.25 },
		{ s * 0.8, 1.12, 0.0, 0.22 },
		{ s * 0.8, 0.8, 0.04, 0.17 },
		{ s * 0.8, 0.52, 0.05, 0.14 },
	}, SKIN)
	-- soft secondary forms (same skin tone so the leg stays one smooth piece)
	k:Part({ Name = "KneeCap", Shape = "Ellipsoid", Size = { 0.28, 0.32, 0.18 }, Pos = { s * 0.78, 1.56, -0.22 }, Color = SKIN })
	k:Part({ Name = "KneeCrease", Shape = "Ellipsoid", Size = { 0.28, 0.05, 0.08 }, Pos = { s * 0.78, 1.55, 0.2 }, Color = SKIN_DARK })
	k:Part({ Name = "Calf", Shape = "Ellipsoid", Size = { 0.44, 0.8, 0.4 }, Pos = { s * 0.8, 1.14, 0.07 }, Rot = { -4, 0, 0 }, Color = SKIN })
	k:Part({ Name = "Achilles", Shape = "Ellipsoid", Size = { 0.16, 0.5, 0.14 }, Pos = { s * 0.8, 0.66, 0.12 }, Color = SKIN })
	k:Part({ Name = "AnkleBone", Shape = "Ellipsoid", Size = { 0.08, 0.13, 0.13 }, Pos = { s * 0.95, 0.5, 0.05 }, Color = SKIN })
	k:Part({ Name = "AnkleBone", Shape = "Ellipsoid", Size = { 0.08, 0.13, 0.13 }, Pos = { s * 0.65, 0.54, 0.05 }, Color = SKIN })
	if s > 0 then
		-- the right foot taps along to the music of the spheres (pivot behind the heel,
		-- pre-tilted so the toes only ever lift, never dig into the ground)
		joint(k, "FootTap", { s * 0.84, 0.0, 0.56 }, { Type = "Wiggle", Axis = "X", Amount = 5, Speed = 0.9 }, function()
			buildFoot(k, s)
		end, { 5, 0, 0 })
	else
		buildFoot(k, s)
	end
end

return {
	Id = "LaVaccaSaturnoSaturnita",
	Name = "La Vacca Saturno Saturnita",
	Rarity = "Secret",
	Emoji = "🐄",
	Color = "#e29b5c",
	Tagline = "Half cow, half planet, fully in orbit. Mooo-n!",
	Lore = "One night a cow jumped over the moon, overshot, and landed on Saturn. Now she IS Saturn: rings, moons and all, chewing cud at the edge of the galaxy on two very human feet. Her milk comes from the Milky Way.",

	Build = function(k)
		buildLeg(k, 1)
		buildLeg(k, -1)

		-- the whole planet sways gently on the hips
		joint(k, "Body", HIP, { Type = "Wiggle", Axis = "Z", Amount = 1.6, Speed = 0.35 }, function()
			buildPlanet(k)
			buildTail(k)

			-- rings + moons in the tilted ring frame
			k:Group({ Name = "RingFrame", Pos = PC, Rot = RING_ROT }, function()
				-- the whole ring system wobbles a touch like a lazy hula hoop
				k:Group({ Name = "RingWobble", Anim = { Type = "Wiggle", Axis = "Z", Amount = 2.5, Speed = 0.25, Phase = 0.4 } }, function()
					k:Group({ Name = "RingSpin", Anim = { Type = "Spin", Axis = "Y", Speed = 0.1 } }, function()
						buildRings(k)
					end)
					moon(k, "MoonA", 2.55, 0.6, 0.56, "#c9c6cf", "Slate", "#9d98a6", 0.16, 0.1)
					moon(k, "MoonB", 2.65, -0.58, 0.46, "#e8c56a", "Foil", "#c79b3c", 0.11, 0.55)
					moon(k, "MoonC", 2.5, 0.45, 0.34, "#b7c9ff", "Glass", "#8aa0e0", 0.22, 0.8)
				end)
			end)

			-- head nods on the neck
			joint(k, "Head", NECK, { Type = "Wiggle", Axis = "X", Amount = 4, Speed = 0.45, Phase = 0.2 }, function()
				-- the head is modelled at 1:1 and scaled up around the neck as one unit
				k:Group({ Name = "HeadScale", Pos = { NECK[1] * (1 - HEAD_SCALE), NECK[2] * (1 - HEAD_SCALE), NECK[3] * (1 - HEAD_SCALE) } }, function()
					buildHead(scaled(k, HEAD_SCALE))
				end)
			end)

			-- slow halo of twinkling stars around the head
			k:Group({ Name = "StarHalo", Pos = { 0, 8.25, -0.2 }, Anim = { Type = "Spin", Axis = "Y", Speed = 0.07 } }, function()
				local halo = { { 30, 0.35, 0.5 }, { 90, -0.15, 0.32 }, { 150, 0.2, 0.42 }, { 210, 0.5, 0.45 }, { 270, -0.05, 0.3 }, { 330, 0.15, 0.4 } }
				for i, h in halo do
					local a = math.rad(h[1])
					star(k, "HaloStar", { 2.35 * math.cos(a), h[2], 2.35 * math.sin(a) }, h[3], if i % 2 == 0 then STAR_BLUE else STAR, i * 0.27, 0.7)
				end
			end)
		end)

		k:Light({ Pos = { 0, 7.6, -2.2 }, Color = "#ffe6c2", Range = 10, Brightness = 1 })
		k:Light({ Pos = { 0, 4.2, -2.9 }, Color = "#9fc8ff", Range = 9, Brightness = 0.9 })
		k:Particles({ Pos = PC, Color = "#ffffff", Color2 = "#a9d4ff", Rate = 6, Size = 0.16, Speed = 0.5, Lifetime = 2.5, Spread = 180 })
		k:Particles({ Pos = { 0, 8.9, -0.3 }, Color = "#fff3b0", Color2 = "#ffffff", Rate = 3, Size = 0.24, Speed = 0.8, Lifetime = 1.6, Spread = 60, Direction = "Top" })
		k:Particles({ Pos = { 0, 0.25, 0 }, Color = "#b9a8ff", Color2 = "#6fb6ff", Rate = 4, Size = 0.3, Speed = 0.6, Lifetime = 1.8, Spread = 90, Direction = "Top" })
	end,

	BuildMini = function(k)
		-- Saturn body: beige planet in a tilted pale-blue ring (the game's blue / beige / white)
		k:Part({ Name = "Planet", Shape = "Ball", Size = { 1.3, 1.3, 1.3 }, Pos = { 0, -0.2, 0 }, Color = "#e2ae72" })
		k:Part({ Name = "Ring", Shape = "Cylinder", Size = { 0.07, 2.6, 2.6 }, Pos = { 0, -0.2, 0 }, Rot = { -22, 0, 75 }, Color = RING_B[1] })
		-- Holstein cow head: white, black spot, pink snout, ears, two eyes, ivory horns
		k:Part({ Name = "Head", Shape = "Ellipsoid", Size = { 0.92, 0.78, 0.84 }, Pos = { 0, 0.68, -0.12 }, Color = COW })
		k:Part({ Name = "Ears", Shape = "Ellipsoid", Size = { 1.5, 0.24, 0.3 }, Pos = { 0, 0.8, -0.06 }, Color = COW_SHADE })
		k:Part({ Name = "Muzzle", Shape = "Ellipsoid", Size = { 0.7, 0.42, 0.42 }, Pos = { 0, 0.5, -0.5 }, Color = PINK })
		k:Part({ Name = "Patch", Shape = "Ellipsoid", Size = { 0.4, 0.36, 0.34 }, Pos = { 0.3, 0.94, -0.28 }, Color = PATCH })
		k:Mirror(function()
			k:Part({ Name = "Eye", Shape = "Ball", Size = { 0.17, 0.17, 0.17 }, Pos = { 0.19, 0.8, -0.48 }, Color = PUPIL })
			k:Part({ Name = "Horn", Shape = "Ellipsoid", Size = { 0.13, 0.38, 0.13 }, Pos = { 0.31, 1.1, -0.12 }, Rot = { 0, 0, -32 }, Color = HORN })
			k:Part({ Name = "Leg", Shape = "Cylinder", Size = { 0.62, 0.2, 0.2 }, Pos = { 0.25, -0.98, -0.04 }, Rot = { 0, 0, 90 }, Color = SKIN })
		end)
	end,
}
